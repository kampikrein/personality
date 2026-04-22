---
id: "026"
type: verify
title: "Verify: cycle 3 — Drift v7→v8 migration impl (commit a37a2e9)"
created: 2026-04-20
cycle: 3
traces_plan: "025"
traces_tdd_red: "024"
status: completed
verdict: PASS
test_attribution: migration-green-phantom-recovery-verified
summary: >
  Independent verification of cycle 3 impl (commit `a37a2e9`) — 4/4 migration
  tests green (T1 readings 값 변환, T2 user_settings rename+변환, T3 멱등성,
  T4 phantom v7.5 복구), 26/26 cycle 1·2 회귀 테스트 green, 7 grep/파일 gate
  모두 통과, Brief Decision 5/16/19/20 compliance 전항목 만족. cycle 4-6
  deferred 영역 (`animated_draw_page.dart`, `draw_result_page.dart`, `home_page.dart`)
  의 `defaultSpreadType` 3 참조는 Plan 025 경계 내 허용. 이전 6개 마이그레이션
  블록 (v1→v2 … v6→v7) 온전히 유지. v7 snapshot 재 dump 없음 (Decision 17),
  v8 snapshot + schema_v8.dart + GeneratedHelper versions=[7,8] 신규 생성.
keywords: [verify, cycle3, drift-migration, v7-to-v8, phantom-recovery, brief-decision-compliance, green]
---

# Verify: cycle 3 — Drift v7→v8 migration impl

## Scope

Plan 025 / TDD Red 024 가 명시한 cycle 3 impl (commit `a37a2e9`) 의 독립 검증.
`flutter analyze` / `flutter build apk` 는 cycles 4-6 잔여 SpreadType UI 마이그레이션
때문에 여전히 깨지므로 Plan 025 §7 정책 그대로 **deferred**. 마이그레이션 테스트
재실행 + 회귀 재실행 + grep gate + Decision compliance 에 집중.

## Test Results

### 1. Migration tests — `test/database/migration_v7_to_v8_test.dart`

독립 재실행 결과 4/4 PASS:

```
00:00 +4: All tests passed!
00:00 +1: v7 → v8 migration T1: readings.spread_type values converted to linear
00:00 +2: v7 → v8 migration T2: user_settings.default_spread_type renamed to default_layout_type with value conversion
00:00 +3: v7 → v8 migration T3: idempotency — re-running migrateAndValidate(db, 8) is no-op
00:00 +4: v7 → v8 migration T4: phantom v7.5 crash recovery — schema=v8, user_version=7
```

`test_attribution: migration-green-phantom-recovery-verified`.

### 2. Regression tests — cycle 1·2

```
cd mobile && flutter test \
  test/features/reading/domain/entities/layout_type_mapping_test.dart \
  test/features/settings/data/repositories/user_settings_repository_layout_type_test.dart
→ 00:00 +26: All tests passed!
```

26/26 green. (commit 메시지 "26/26" 과 일치. 교차 세션 플랜 025 에는 "27/27" 로 적힌
부분이 있으나 실제 러너 집계는 26 — 경미한 문서 불일치, 실행 기준으로 26.)

## Decision Compliance Grid

| Decision | 요구 사항 | 실제 구현 (`app_database.dart`) | 결과 |
|---|---|---|---|
| **D5** | Transaction wrap + `PRAGMA user_version` 트랜잭션 **내부** commit (phantom v7.5 방지) | L72-102: `m.database.transaction(() async { ... await m.database.customStatement('PRAGMA user_version = 8'); })` — PRAGMA 가 트랜잭션 클로저 **내부** 마지막 문장 | PASS |
| **D16** | `m.database.transaction(() async { ... })` explicit wrap | L72: `await m.database.transaction(() async {` — Migrator.transaction 이 아닌 **database.transaction** 사용 확인 | PASS |
| **D19** | onUpgrade 내부는 오직 `m.database.customStatement` / `customSelect` — DAO/Repository/freezed 호출 금지 | L69-106 블록 전체 `m.database.customStatement(...)` + 1건 `m.database.customSelect(...)` (컬럼 존재 검사) 만 사용. DAO/Repository/freezed import 0건 | PASS |
| **D20** | `readings.spread_type` 컬럼명 유지 (값만 `'linear'` 로 UPDATE, `ALTER RENAME` 금지) | L74-77: `UPDATE readings SET spread_type = 'linear' WHERE spread_type IN ('single','threeCard','custom')` — ALTER 문 없음. v8 snapshot diff 에서 `readings.spread_type` 컬럼명 그대로 유지 확인 | PASS |
| **PRAGMA FK toggle** | `PRAGMA foreign_keys = OFF` → `try/finally` → `ON` | L70: OFF, L103-105: `finally { await m.database.customStatement('PRAGMA foreign_keys = ON'); }` | PASS |
| **재진입성 (T4)** | `pragma_table_info` 존재 검사가 **UPDATE + ALTER RENAME 둘을 함께** 감싸야 함 (phantom 재진입 시 컬럼이 이미 rename 된 상태에서 UPDATE 가 throw 하는 회귀 차단) | L82-99: `hasOldCol` 검사가 `if (hasOldCol) { UPDATE user_settings ...; ALTER TABLE user_settings RENAME COLUMN ... }` 블록 전체를 감쌈. impl 이 iteration 에서 추가한 부분 — Plan 025 §4.1 본문은 ALTER 만 감쌌으나 impl 이 더 안전한 형태로 확장함. T4 가 이 확장을 요구 | PASS |

## File / Grep Gates

| Gate | 기대 | 실제 | 결과 |
|---|---|---|---|
| Commit 구조 (`git show --stat a37a2e9`) | 3 source + app_database.g.dart + v8 snapshot + schema_v8.dart + schema.dart + 2 test | 정확히 일치: `app_database.dart`, `tables/user_settings_table.dart`, `repositories/user_settings_repository_impl.dart`, `app_database.g.dart`, `drift_schemas/drift_schema_v8.json`, `test/generated_migrations/schema.dart`, `test/generated_migrations/schema_v8.dart`, `test/database/migration_v7_to_v8_test.dart`, `test/features/settings/data/repositories/user_settings_repository_layout_type_test.dart` | PASS |
| `grep default_spread_type mobile/lib/` | 오직 `app_database.dart` 내 마이그레이션 SQL 리터럴 + 기존 v3 블록만 허용 | 6 matches 모두 `app_database.dart`: L36 (v3 레거시 UPDATE), L79 (주석), L86 (pragma_table_info 비교), L91-92 (v8 UPDATE SQL), L96 (ALTER RENAME SQL). 다른 Dart 파일 0건 | PASS |
| `grep defaultSpreadType mobile/lib/` | `animated_draw_page.dart`, `draw_result_page.dart`, `home_page.dart` 만 허용 (cycles 4-6) | 정확히 3 matches: `animated_draw_page.dart:53`, `draw_result_page.dart:53`, `home_page.dart:462`. settings / reading 영역 0건 | PASS |
| `grep _$SpreadTypeEnumMap mobile/lib/` | 0 matches | 0 matches | PASS |
| `drift_schemas/drift_schema_v7.json` 존재 + 미변경 | 존재, mtime = 이전 | 존재 (mtime `Apr 20 00:43` — cycle 3 작업 전). Decision 17 ("v7 재 dump 금지") 준수 | PASS |
| `drift_schemas/drift_schema_v8.json` 신규 | 존재 | 존재 (mtime `Apr 20 12:20`). diff vs v7: `user_settings.default_spread_type`/`defaultSpreadType` → `default_layout_type`/`defaultLayoutType` 딱 1 컬럼만 변경. `readings.spread_type` 컬럼명 유지 (Decision 20 재확인) | PASS |
| `test/generated_migrations/schema_v8.dart` 신규 | 존재 | 존재, 82262 bytes | PASS |
| `GeneratedHelper.versions` in `schema.dart` | `[7, 8]` 포함 | `static const versions = const [7, 8];` + `case 7: return v7.DatabaseAtV7(db); case 8: return v8.DatabaseAtV8(db);` | PASS |
| `schemaVersion` 값 | 8 | `app_database.dart:25` → `int get schemaVersion => 8;` | PASS |
| 이전 6개 마이그레이션 블록 (v1→v2 … v6→v7) | 온전 보존 | `if (from < 2)` … `if (from < 7)` L31-68 전부 유지. `if (from < 8)` 블록만 L69-106 신규 추가 | PASS |

## Phantom v7.5 시나리오 검증 (T4 근거 재확인)

impl 의 `if (hasOldCol)` 가드가 `UPDATE user_settings` + `ALTER RENAME` 을 **하나의
단위로** 감싸는 것이 핵심. Plan 025 §4.1 의 원안은 ALTER 만 가드했지만, 그대로
옮기면 phantom 재진입 시:

- `default_spread_type` 컬럼이 이미 `default_layout_type` 으로 rename 된 상태
- `[B]` UPDATE 가 "no such column: default_spread_type" 로 throw
- 하지만 ALTER 는 이미 rename 되었으므로 guard 에 의해 skip
- 결과: UPDATE 만 throw → T4 실패

impl 은 이 회귀를 `hasOldCol` 한 검사로 UPDATE+ALTER 둘 다 skip 하도록 확장.
T4 PASS 결과가 이 확장이 의도대로 작동함을 실증. `app_database.dart:82-99`
코드가 실제 이 구조를 가짐을 Read 로 재확인.

## Cycle 3 경계 확인

- Plan 025 "Out of bounds" 명시 파일 (`spread_layout.dart`, `home_page.dart`,
  `draw_result_page.dart`, `animated_draw_page.dart`, `reading_list_page.dart`)
  커밋 diff 에 포함 안 됨. `git show --stat` 9 변경 파일 모두 Plan 025 허용 범위.
- cycle 2 repo 테스트 retargeting (default_spread_type → default_layout_type via
  raw SQL) 은 Plan 025 §3 M3 "cycle 2 잔여 cleanup" 범위. 회귀 26/26 green 이
  retargeting 유효성 실증.

## Findings

**없음.** 모든 check PASS. impl 이 Plan 025 §4.1 가드 범위를 확장한 것은
TDD Red 024 T4 가 요구한 정확한 조치였고 cycle 3 내부에서 완결됨 (plan 초안보다
안전한 해석이며 Plan 025 §4.1 §3 M3 모두에 부합).

**경미한 문서 불일치**: Plan 025 §7 의 regression 기대치 "27/27" vs 실제 러너
집계 26. verdict 에 영향 없음 (cycle 2 cycle docs 에서 테스트 count 를 집계한
방식 차이로 추정). 별도 보정 불필요 — 실행 기준으로 26/26 green 만 유지.

## Cycle 4 Readiness

- cycle 3 impl 이 DB 계층 rename 을 완료 + `defaultLayoutType` getter 가 Drift 에
  노출됨 → cycle 4 에서 `home_page.dart`, `draw_result_page.dart`,
  `animated_draw_page.dart` 의 `settings?.defaultSpreadType` 3 참조를
  `settings?.defaultLayoutType` + `SpreadType → LayoutType` 로 교체 가능.
- 저장된 사용자 설정이 이미 `'linear'` 로 통합되었으므로 UI 계층은 `LayoutType`
  enum 하나만 다루면 된다.
- snapshot 계약 (`drift_schema_v8.json`) 이 확정됨 → cycle 4-6 에서 DB 재수정
  불필요.
- **Ready for cycle 4** (presentation layer migration).

## Verdict

**PASS**

근거: 4/4 migration + 26/26 regression + 10/10 grep-file gate + Decision
5/16/19/20 + PRAGMA FK toggle + re-entrancy expansion 모두 충족.

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 56s | 217814 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 56s |
| Total Tokens | 217814 |
| Input Tokens | 10 |
| Output Tokens | 3434 |
| Cache Read | 160671 |
| Cache Creation | 53699 |
