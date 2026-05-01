---
id: "054"
type: plan
title: "Cycle 8 Compliance GDPR/PIPA GREEN Plan"
created: 2026-05-01
traces_brief: "021"
traces_scope: "026"
traces_red: "053"
traces_cycle6_impl: "051"
cycle: 8
phase_scope: "phase-1-conversion"
status: completed
confidence: high
summary: >
  Cycle 8 Compliance GREEN plan. 5 flow GDPR/PIPA (consent / deletion / audit log / cross-border / age verification)
  구현 + admin compliance dashboard. 0 fail / 783 pass 목표.
keywords: [plan, compliance, gdpr, pipa, audit-log, deletion, consent, age, cross-border, cycle8]
---

## Goal

**수치 목표**: `npx vitest run` 전체 0 fail / **783 pass** (cycle 1-6 기존 742 + cycle 8 신규 41).

**Brief 021 Ideal Criteria 매핑**:

| Criterion | 내용 | 본 Cycle 관련 |
|-----------|------|--------------|
| **#23** | GDPR/PIPA 5 흐름(consent/deletion/audit/국외 이전/14세 미만)이 모두 구현됐는가 | 핵심 — 5 flow 전체 GREEN |
| **#24** | consent / deletion_request / audit_log / alert 모델이 R4 user 모델과 정합하게 작동하는가 | consent + deletion + audit_log 통합 검증 |

현재 상태: cycle 1-6 742 pass 유지 + cycle 8 추가 후 **742 pass + 41 fail** (의도적 RED).  
GREEN 전환: 41개 fail → 0 fail, 742 pass → **783 pass**.

---

## Scope

### Included

| 항목 | 설명 |
|------|------|
| **auditLogger 구현** | `auditLog()` / `getAuditLogs()` stub → 실 D1 INSERT/SELECT 구현 |
| **consent flow integration** | consents POST/DELETE에 auditLogger 호출 추가 |
| **deletion flow integration** | deletion_requests POST + deletionProcessor에 auditLogger 연동 + `deletion_processed` action 통일 + SLA `completed` 반환 |
| **cross_border_consent** | crossBorderConsent.ts 서비스 구현 + cross_border_consents route 실 구현 |
| **age_verification** | ageVerification.ts 순수 함수 구현 + accounts/signup 연동 |
| **admin compliance routes** | admin/consents (통계), admin/deletion_requests (SLA 대기 목록), admin/audit_logs (filter/pagination 보강) |

### Excluded

| 항목 | 이유 | 시점 |
|------|------|------|
| 보호자 동의 흐름 (14세 미만 실 승인 처리) | `initiateParentalConsentFlow` — Phase 2 carryover. 본 Cycle은 14세 미만 **차단**까지. | Phase 2 |
| audit_log immutability schema 강제 (SQLite trigger) | Application layer 보호로 충분. SQLite trigger / D1 RW token 분리는 Phase 2. | Phase 2 |
| SLA monitoring 자동 cron | 자동 cron 실행은 외부 자원(CF Cron Trigger). 본 Cycle은 조회 API까지. | Phase 2 |
| admin compliance dashboard SSR | cycle 6 SSR routes와 결합하는 UI. 본 Cycle은 JSON routes만. | Phase 2 |
| cross_border_consents SSR 고지 페이지 | cycle 6 SSR 범주. 본 Cycle은 API routes만 노출. | Phase 2 |

---

## Structural Decisions

| # | 항목 | 결정 | 근거 |
|---|------|------|------|
| SD-1 | cross_border_consent 저장소 | 별도 테이블 없음. `consents` 테이블 재사용 (`consent_type = 'cross_border_transfer'`) | RED 053 § Schema 확인 |
| SD-2 | consent 활성 여부 판단 | `status` 컬럼 없음. `revoked_at IS NOT NULL` 패턴 사용 | cycle 2 schema: consents 테이블에 `revoked_at` 컬럼, `status` 컬럼 없음 확인 |
| SD-3 | auditLogger 시그니처 | `await auditLog(db, { resourceType, resourceId, action, actorType, actorId, metadata })` — D1Database 직접 수신, service 전체에서 import 가능한 helper | RED 053 § Implementation Hints #1 |
| SD-4 | audit_log immutability | Application layer (write-only API + service contract: UPDATE/DELETE 금지). SQLite trigger는 Phase 2 carryover | Risks R5 |
| SD-5 | age_verification 구현 형태 | 순수 함수 (`calculateAgeFromBirthdate` + `verifyAge`) + accounts route signup hook. Phase 1은 14세 미만 즉시 차단. | ageVerification.ts 기존 타입 설계 준수 |
| SD-6 | admin compliance routes | 기존 admin 디렉토리에 consents.ts / deletion_requests.ts 신규 파일. adminAuditLogsRouter는 filter/pagination 보강 | admin/ 디렉토리 현황: alerts, audit_logs, dashboard, question_sets 확인 |
| SD-7 | 0002 migration 불필요 | schema 변경 없음. cross_border_consent는 consents 재사용, age_verification은 순수 함수. 기존 컬럼 범위 내 처리. | schema.ts 현황 확인 |

---

## File Change Summary

### Modified (stub → 실 구현)

| 파일 | 변경 내용 | Step |
|------|----------|------|
| `src/services/compliance/auditLogger.ts` | `auditLog()` D1 INSERT 실 구현 + `getAuditLogs()` filter/pagination 구현 | Step 1 |
| `src/services/compliance/crossBorderConsent.ts` | `recordCrossBorderConsent` / `revokeCrossBorderConsent` / `checkCrossBorderConsent` — consents 재사용 실 구현 | Step 3 |
| `src/services/compliance/ageVerification.ts` | `calculateAgeFromBirthdate()` + `verifyAge()` 순수 함수 구현 (`MINIMUM_AGE_YEARS = 14` 상수 활용) | Step 4 |
| `src/services/compliance/deletionProcessor.ts` | audit_action 값 `deletion_processed`로 통일 + SLA `completed` status 반환 보정 | Step 2 |
| `src/api/routes/public/consents.ts` | POST / DELETE /:id 핸들러에 `auditLog()` 호출 추가 (`consent_granted` / `consent_revoked`) | Step 2 |
| `src/api/routes/public/cross_border_consents.ts` | POST / GET /:id / DELETE /:id stub → 실 구현 (crossBorderConsent service 사용) | Step 3 |
| `src/api/routes/public/accounts.ts` | signup POST — `birthdate` 파라미터 처리 + `verifyAge()` 호출 + 14세 미만 400 차단 | Step 4 |
| `src/api/routes/public/deletion_requests.ts` | POST 핸들러에 `auditLog()` 호출 추가 + 201 반환 정합 | Step 2 |
| `src/api/routes/admin/audit_logs.ts` | GET / — filter (`action`, `actorType`, `resourceType`) + pagination (`page`, `limit`) 보강 | Step 5 |

### 신규 생성

| 파일 | 내용 | Step |
|------|------|------|
| `src/api/routes/admin/consents.ts` | GET / — active/revoked counts + consent_type별 통계 | Step 5 |
| `src/api/routes/admin/deletion_requests.ts` | GET / — 처리 대기(pending) 목록 + SLA 경과 시간 표시 | Step 5 |

### Reviewed (코드 확인, 변경 없거나 최소)

| 파일 | 확인 목적 |
|------|----------|
| `src/db/schema.ts` | consents/audit_logs/deletion_requests 컬럼 정합 최종 확인 |
| cycle 3 `deletionProcessor.ts` cascade 흐름 | 기존 cascade 삭제 로직 보존 확인 |

---

## Step별 절차

### Step 1 — auditLogger 구현 (의존 leaf, 최우선)

모든 compliance flow가 `auditLog()` 에 의존하므로 첫 번째로 구현한다.

**구현 대상**:

```
src/services/compliance/auditLogger.ts
```

- `auditLog(db: D1Database, params: AuditLogParams): Promise<void>`
  - D1 `INSERT INTO audit_logs (resource_type, resource_id, action, actor_type, actor_id, metadata, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
  - params에 `actorId` / `actorType` 없을 경우 `NULL` 처리 허용
  - `metadata`는 `JSON.stringify(params.metadata ?? {})` 직렬화
  - 실패 시 throw (audit 누락 = 심각 오류이므로 silent fail 금지)

- `getAuditLogs(db: D1Database, filter: AuditLogFilter): Promise<AuditLogEntry[]>`
  - filter: `{ action?, actorType?, resourceType?, limit?, offset? }`
  - WHERE 절 동적 구성 (filter 없으면 전체)
  - `ORDER BY created_at DESC LIMIT ? OFFSET ?`
  - 결과 JSON parse: `metadata` 컬럼 역직렬화

**검증**:
```bash
cd /Users/kampikrein/A/personality/apps/workers
npx vitest run test/compliance/audit_log_integrity.test.ts
# 목표: 11 tests — 0 fail
```

---

### Step 2 — consent flow + deletion flow integration

**2-A. consents route audit 연동** (`src/api/routes/public/consents.ts`):

```
POST /consents    → auditLog({ action: 'consent_granted', resourceType: 'consent', ... })
DELETE /consents/:id → auditLog({ action: 'consent_revoked', resourceType: 'consent', ... })
```

- `auditLog`는 D1 응답 성공 후 호출 (consent INSERT 완료 후 audit)
- actorType: `'user'` (userId 있을 때) / `'anonymous_session'` (session만 있을 때)

**2-B. deletion_requests route audit 연동** (`src/api/routes/public/deletion_requests.ts`):

```
POST /deletion_requests → auditLog({ action: 'deletion_requested', resourceType: 'deletion_request', ... })
```
- 현재 POST 핸들러가 201 대신 다른 코드 반환 — 201 정합 수정 포함

**2-C. deletionProcessor audit action 통일** (`src/services/compliance/deletionProcessor.ts`):

- 현재: `'deletion_started'` (line 85 확인됨)
- 변경: 처리 완료 시점 action → `'deletion_processed'`
- `deletion_requests.status` → `'completed'` 업데이트 확인 (SLA 검증 통과 조건)

**검증**:
```bash
npx vitest run test/compliance/consent_flow.test.ts test/compliance/deletion_flow.test.ts
# 목표: 14 tests — 0 fail
```

---

### Step 3 — cross_border_consent 구현

**3-A. service** (`src/services/compliance/crossBorderConsent.ts`):

consents 테이블 재사용 — `consent_type = 'cross_border_transfer'`.

- `recordCrossBorderConsent(db, { userId?, sessionId?, consentVersion })`:
  - INSERT INTO consents (`consent_type='cross_border_transfer'`, `granted=1`, `granted_at=CURRENT_TIMESTAMP`, `consent_version`)
  - return: `{ consentId, status: 'granted' }`

- `revokeCrossBorderConsent(db, { consentId })`:
  - UPDATE consents SET `revoked_at = CURRENT_TIMESTAMP` WHERE id = consentId AND `consent_type = 'cross_border_transfer'`

- `checkCrossBorderConsent(db, { userId?, sessionId? })`:
  - SELECT WHERE `consent_type = 'cross_border_transfer' AND revoked_at IS NULL`
  - return: `{ active: boolean, consentId?, grantedAt? }`

**3-B. route** (`src/api/routes/public/cross_border_consents.ts`):

```
POST   /cross_border_consents       → recordCrossBorderConsent → 201 { success, data: { id, consentType, status } }
GET    /cross_border_consents/:id   → SELECT consents WHERE id AND consent_type='cross_border_transfer' → 200
DELETE /cross_border_consents/:id   → revokeCrossBorderConsent → 200 { success, data: { revokedAt } }
```

**검증**:
```bash
npx vitest run test/compliance/cross_border_consent.test.ts
# 목표: 14 tests — 0 fail
```

---

### Step 4 — age_verification 구현

**4-A. 순수 함수** (`src/services/compliance/ageVerification.ts`):

상수 `MINIMUM_AGE_YEARS = 14` 이미 정의됨 — 활용.

- `calculateAgeFromBirthdate(birthdate: string): number`
  - ISO 8601 문자열 파싱 (YYYY-MM-DD)
  - `Math.floor((today - birthdate) / ms_per_year)`
  - 오늘 날짜 기준 만 나이 계산

- `verifyAge(birthdate: string | undefined | null, threshold = MINIMUM_AGE_YEARS): AgeVerificationResult`
  - birthdate 없거나 파싱 실패 → `{ allowed: false, reason: 'birthdate_required' }`
  - age < threshold → `{ allowed: false, reason: 'underage', age }`
  - age >= threshold → `{ allowed: true, age }`

**4-B. accounts route signup 연동** (`src/api/routes/public/accounts.ts`):

```
POST /accounts (signup):
  const { email, password, birthdate } = body
  const ageResult = verifyAge(birthdate)
  if (!ageResult.allowed) return c.json({ success: false, error: { code: 'AGE_RESTRICTED', ... } }, 400)
  // 이후 기존 user INSERT 흐름
```

- `birthdate` 없으면 `verifyAge(undefined)` → 400 반환 (birthdate 필수 정책 — Phase 1)
- Phase 2: 보호자 동의 흐름 (현재는 `initiateParentalConsentFlow` throw 유지)

**검증**:
```bash
npx vitest run test/compliance/age_verification.test.ts
# 목표: 11 tests — 0 fail
```

---

### Step 5 — admin compliance routes

**5-A. admin/audit_logs.ts 보강** (filter / pagination):

현재: GET / 기본 목록만. 추가:
- query params: `?action=&actorType=&resourceType=&page=1&limit=20`
- `getAuditLogs(db, filter)` 호출로 위임 (Step 1 구현 활용)
- response: `{ success, data: { items, total, page, limit } }`

**5-B. admin/consents.ts 신규**:

```
GET /admin/consents
→ SELECT consent_type, COUNT(*) total,
         SUM(CASE WHEN revoked_at IS NULL THEN 1 ELSE 0 END) active,
         SUM(CASE WHEN revoked_at IS NOT NULL THEN 1 ELSE 0 END) revoked
   FROM consents GROUP BY consent_type
response: { success, data: { stats: [{ consentType, total, active, revoked }] } }
```

**5-C. admin/deletion_requests.ts 신규**:

```
GET /admin/deletion_requests
→ SELECT id, anonymous_session_id, request_token, status, created_at,
         (julianday('now') - julianday(created_at)) * 24 as hours_elapsed
   FROM deletion_requests
   WHERE status = 'pending'
   ORDER BY created_at ASC
response: { success, data: { items: [...], pendingCount } }
```

SLA 기준: `hours_elapsed > 720` (30일) → `sla_overdue: true` 표시.

**5-D. index 등록**: admin router에 `consents.ts` / `deletion_requests.ts` 신규 route 마운트.

**검증**:
```bash
npx vitest run test/compliance/admin_compliance.test.ts
# 목표: 11 tests — 0 fail
```

---

### Step 6 — 통합 검증

```bash
cd /Users/kampikrein/A/personality/apps/workers
npx vitest run
```

**합격 기준**:
- Tests: **0 fail / 783 pass** (783 = 742 existing + 41 new)
- Test Files: 0 failed / 전체 passed (현재 RED: 5 failed | 79 passed)
- cycle 1-6 (742) 회귀 없음 확인

---

## Implementation 분할 권장

| 옵션 | 방식 | 파일 수 | 평가 |
|------|------|---------|------|
| **옵션 A — 단일 (권장)** | Step 1~6 순차 단일 agent | 11 파일 (9 수정 + 2 신규) | cycle 6 (14 파일) 보다 가벼움. auditLogger 의존성이 leaf이므로 순차가 자연스러움 |
| 옵션 B — 분할 | Step 1~2 / Step 3~5 분리 | — | 불필요. 컨텍스트 여유 충분 |

**권장: 옵션 A**. 단일 implementation agent가 Step 1 → 2 → 3 → 4 → 5 → 6 순서 실행.

의존 순서:
```
auditLogger (Step 1)
  ├─ consent flow (Step 2-A)
  ├─ deletion flow (Step 2-B, 2-C)
  ├─ cross_border route (Step 3-B)
  └─ admin/audit_logs (Step 5-A)
crossBorderConsent (Step 3-A) ← Step 3-B
ageVerification (Step 4-A) ← accounts route (Step 4-B)
admin/consents, admin/deletion_requests (Step 5-B, 5-C) — 독립
```

---

## Cross-Reference Table

| Flow | Test File | 테스트 수 (RED fail) | Service 파일 | Route 파일 | Step |
|------|-----------|---------------------|-------------|-----------|------|
| audit log | `test/compliance/audit_log_integrity.test.ts` | 11 tests (9 fail) | `auditLogger.ts` | `admin/audit_logs.ts` (보강) | 1, 5 |
| consent | `test/compliance/consent_flow.test.ts` | 7 tests (5 fail) | `auditLogger.ts` | `public/consents.ts` | 1, 2 |
| deletion | `test/compliance/deletion_flow.test.ts` | 7 tests (4 fail) | `deletionProcessor.ts` | `public/deletion_requests.ts` | 2 |
| cross-border | `test/compliance/cross_border_consent.test.ts` | 14 tests (12 fail) | `crossBorderConsent.ts` | `public/cross_border_consents.ts` | 3 |
| age verification | `test/compliance/age_verification.test.ts` | 11 tests (9 fail) | `ageVerification.ts` | `public/accounts.ts` | 4 |
| admin compliance | `test/compliance/admin_compliance.test.ts` | 11 tests (2 fail) | — | `admin/consents.ts`, `admin/deletion_requests.ts` | 5 |
| **합계** | **6 files** | **61 tests (41 fail)** | | | |

---

## Verification Plan

### 단계별 검증

| 단계 | 명령 | 합격 기준 |
|------|------|----------|
| Step 1 단위 | `npx vitest run test/compliance/audit_log_integrity.test.ts` | 11/11 pass |
| Step 2 단위 | `npx vitest run test/compliance/consent_flow.test.ts test/compliance/deletion_flow.test.ts` | 14/14 pass |
| Step 3 단위 | `npx vitest run test/compliance/cross_border_consent.test.ts` | 14/14 pass |
| Step 4 단위 | `npx vitest run test/compliance/age_verification.test.ts` | 11/11 pass |
| Step 5 단위 | `npx vitest run test/compliance/admin_compliance.test.ts` | 11/11 pass |
| **Step 6 통합** | `npx vitest run` (전체) | **0 fail / 783 pass** |

### 특수 검증 항목

1. **audit_log integrity**: 민감 작업 (consent_granted / consent_revoked / deletion_requested / deletion_processed) 수행 후 audit_logs 테이블에 행이 생성됐는지 확인.

2. **cross_border schema 재사용 정합**: `consents.consent_type = 'cross_border_transfer'` 조회 결과가 recordCrossBorderConsent → checkCrossBorderConsent → revokeCrossBorderConsent 3단 흐름에서 일관되는지 확인.

3. **cycle 1-6 회귀**: 통합 테스트 742 pass 유지 확인. 신규 auditLogger import가 기존 route 동작을 깨지 않는지 검증.

4. **age_verification threshold**: `MINIMUM_AGE_YEARS = 14` 상수 기준. 정확히 14세 = allowed, 13세 11개월 = blocked 경계값 테스트 확인.

---

## Risks & Mitigations

| # | Risk | 영향 | Mitigation |
|---|------|------|-----------|
| R1 | auditLogger 호출 누락 시 audit_log integrity 깨짐 | audit 미기록 → GDPR 위반 가능 | 모든 sensitive route (consent POST/DELETE, deletion POST)에 명시적 호출. 구현 후 `grep -r "auditLog" src/api/routes/public/` 로 커버리지 검증 |
| R2 | `consent_type='cross_border_transfer'` enum 일관성 | 다른 값 사용 시 checkCrossBorderConsent 누락 | crossBorderConsent.ts에서 상수 `CROSS_BORDER_CONSENT_TYPE = 'cross_border_transfer'` export. route와 service 동일 상수 참조 |
| R3 | age_verification 14 threshold 하드코딩 | 규제 변경 시 코드 수정 필요 | `MINIMUM_AGE_YEARS` 상수 이미 정의됨. Phase 2에서 env 변수 또는 D1 config 테이블로 동적화 carryover |
| R4 | 보호자 동의 흐름 미구현 | 14세 미만 사용자 완전 차단 (단순 400) | Phase 2 carryover 명시. `initiateParentalConsentFlow` throw 유지로 Phase 2 hook point 보존. 본 Phase 기준 14세 미만 차단이 PIPA 준수 최소 요건 충족 |
| R5 | audit_log immutability schema 강제 부재 (application layer만) | 직접 D1 UPDATE/DELETE 가능 | Application layer: audit_logs route에 POST만 노출 (현재 405 이미 설정됨). Phase 2 carryover: SQLite trigger 또는 D1 RW token 분리로 schema level 강제 |
| R6 | admin compliance dashboard SSR 미연동 | admin UI에서 compliance 현황 미가시 | 본 Cycle은 JSON API만. Phase 2 carryover: cycle 6 SSR와 결합. Phase 1 완료 기준(Ideal Criteria #23) 충족에 SSR 불필요 — assertion 통과 가능 |
| R7 | deletionProcessor `deletion_started` → `deletion_processed` action 변경 시 기존 테스트 영향 | cycle 3 테스트가 `deletion_started` 기대 가능 | Step 2-C 실행 전 cycle 3 `deletion_flow` 관련 테스트 grep 확인. 변경이 의도적이므로 cycle 3 테스트도 `deletion_processed` 로 일관 업데이트 |

---

## References

| 문서 | 경로 | 관련 내용 |
|------|------|----------|
| RED 053 | `docs/6_backend/02_cf_workers_rebuild/053_TDDRed_cycle8_compliance.md` | Compliance Flow Inventory, Test Files, Implementation Hints, Risks |
| Brief 021 | `docs/6_backend/02_cf_workers_rebuild/021_Brief_conversion_phase1.md` | Ideal Criteria #23/#24 (In Scope 8, compliance 5 flows) |
| Scope 026 | `docs/6_backend/02_cf_workers_rebuild/026_Scope_conversion_phase1.md` | Phase 1 scope boundary |
| DB Schema | `apps/workers/src/db/schema.ts` | consents (granted/revoked_at), audit_logs (action/metadata), deletion_requests (request_token/status) 컬럼 |
| auditLogger stub | `apps/workers/src/services/compliance/auditLogger.ts` | AuditAction 타입, AuditLogParams 인터페이스 (Step 1 구현 입력) |
| crossBorderConsent stub | `apps/workers/src/services/compliance/crossBorderConsent.ts` | CrossBorderConsentResult, CrossBorderConsentRecord 타입 |
| ageVerification stub | `apps/workers/src/services/compliance/ageVerification.ts` | MINIMUM_AGE_YEARS = 14, AgeVerificationResult 타입, ParentalConsentRequest (Phase 2) |
| deletionProcessor | `apps/workers/src/services/compliance/deletionProcessor.ts` | 현재 `deletion_started` action (line 85) — Step 2-C에서 `deletion_processed`로 통일 |
