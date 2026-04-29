# D1 Backup & Restore Runbook

D1 자동 export → R2 cron 동작 설명 + 분기 1회 복원 dry-run 절차.
Brief Constraint M14: "주 1회 cron + 분기 1회 복원 dry-run".

---

## 자동 backup 동작

| 항목 | 값 |
|------|-----|
| Cron expression | `0 17 * * 0` (UTC) |
| KST 변환 | 일요일 02:00 KST |
| Source | D1 `personality-d1-prod` (production) |
| Sink | R2 `personality-d1-backup` |
| Object key pattern | `production/d1-backup-YYYY-MM-DDTHH-MM-SS-sssZ.sql` |
| Handler | `apps/workers/src/scheduled/d1-backup.ts` |

### 동작 원리

1. CF Cron Trigger가 Worker `scheduled` export를 호출 (`0 17 * * 0` UTC).
2. `d1-backup.ts`의 `performBackup()`:
   - `sqlite_master`에서 테이블 목록 조회
   - 각 테이블 CREATE TABLE + INSERT 구문 생성
   - R2에 `.sql` 파일 put

> Cycle 1 Foundation 시점에서는 D1 schema가 없어 빈 SQL 헤더만 백업됨. Cycle 2(DB Layer) 이후부터 실제 데이터 포함.

---

## Phase 2 — cron 활성화

Phase 2 cutover 후 production deploy 완료 시:

```bash
# 수동 트리거 테스트 (deploy 후 첫 1회)
# CF Dashboard → Workers → personality-workers → Triggers → Cron Triggers → Run
# 또는 CLI (wrangler 버전에 따라 지원 여부 상이)

# 결과 확인
wrangler r2 object list personality-d1-backup --env production
# production/d1-backup-... 파일 노출
```

---

## 분기 1회 복원 dry-run 절차

> Phase 2 Cycle 9 (Cutover Safety)에서 실행. Phase 1에서는 절차 문서화만.
> 완료 후 결과를 `docs/runbook/restore-drill-YYYY-Q.md`로 기록.

### 절차

**Step 1: 최신 backup 다운로드**

```bash
# 최신 object key 확인
wrangler r2 object list personality-d1-backup --env production

# 다운로드 (최신 파일명으로 교체)
wrangler r2 object get \
  personality-d1-backup/production/d1-backup-LATEST.sql \
  --file /tmp/d1-backup-restore-drill.sql \
  --env production
```

**Step 2: staging D1에 임시 namespace 생성**

```bash
wrangler d1 create personality-d1-restore-drill
# database_id 기록 → wrangler d1 execute에서 사용
```

**Step 3: SQL import (dry-run)**

```bash
wrangler d1 execute personality-d1-restore-drill \
  --file /tmp/d1-backup-restore-drill.sql \
  --env staging
```

**Step 4: row count 비교**

```bash
# production row count 확인
wrangler d1 execute personality-d1-prod --env production \
  --command "SELECT count(*) FROM users;"

# restored row count 확인
wrangler d1 execute personality-d1-restore-drill --env staging \
  --command "SELECT count(*) FROM users;"

# 결과가 일치해야 drill 통과
```

**Step 5: 임시 DB 삭제**

```bash
wrangler d1 delete personality-d1-restore-drill
```

**Step 6: 결과 기록**

`docs/runbook/restore-drill-YYYY-Q.md` 파일 생성:
- 실행 날짜
- backup object key
- 원본 / 복원 row count
- 이상 없음 / 이상 항목 기록

---

## 용량 제한 참고사항

현재 구현(`d1-backup.ts`)은 단일 스레드 SQL dump:
- Workers CPU time 30s 한도 내: row 수 수천~수만 단위까지 안전.
- 수십만 row 이상이 되면:
  - D1 Export REST API (`/client/v4/accounts/{id}/d1/database/{db_id}/export`) 로 전환 권장
  - 또는 R2 multipart upload (Synthesis 018 Phase 2 Carryover § 2.3 M10)
  - Cycle 10(Cutover Safety)에서 재검토.
