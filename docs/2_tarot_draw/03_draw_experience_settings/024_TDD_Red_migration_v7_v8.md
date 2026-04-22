---
id: "024"
type: tdd-red
title: "TDD Red: Drift migration v7→v8 (4 cases incl. phantom v7.5)"
created: 2026-04-20
cycle: 3
traces_scope: "017"
status: completed
test_count: 4
framework: "flutter_test + drift/native + drift_dev/api/migrations_native"
test_files:
  - mobile/test/database/migration_v7_to_v8_test.dart
summary: >
  4 failing SchemaVerifier-based tests for schema v7→v8 migration:
  (T1) readings value conversion, (T2) user_settings column rename + value conversion,
  (T3) idempotency, (T4) phantom v7.5 crash recovery (Brief Decision 5/16 + 014 Critique C2).
keywords: [tdd-red, drift, migration, schema-verifier, phantom-recovery]
---

# TDD Red: Drift migration v7 → v8

## Test Strategy

4 SchemaVerifier-based tests covering Brief 011 Constraints § 테스트의 4 cases.
Pattern은 Doc 008 Research Finding D를 그대로 따른다 (drift_dev codegen +
`migrateAndValidate(db, 8)`). 모든 테스트는 동일한 `setUp` 에서 `SchemaVerifier`
인스턴스를 생성하고 `verifier.schemaAt(7)` → v7 fixture 데이터 삽입 → 실제
`AppDatabase` 로 v8 마이그레이션 실행 → 변환 결과 검증 시퀀스를 따른다.

## Test Specifications

### T1 — readings.spread_type 값 변환
v7 schema에 `spreadType: 'single' / 'threeCard' / 'custom'` 3건 삽입 →
`migrateAndValidate(db, 8)` 후 `readings.spread_type` 전 행이 `'linear'` 인지
검증. (Brief Decision 16: 위치 의미 손실 수용, 모든 enum 값을 linear 로 매핑.)

### T2 — user_settings.default_spread_type → default_layout_type rename + 값 변환
v7 schema에 `defaultSpreadType: 'threeCard'` 1행 삽입 → v8 마이그레이션 후
(a) `default_layout_type` 컬럼이 존재하고 값이 `'linear'`, (b) 옛 컬럼명
`default_spread_type` 조회는 throw 되는지 검증. (Brief Decision 6: DB 컬럼명
변경.)

### T3 — 멱등성 (idempotency)
v7 → v8 마이그레이션을 두 번 연속 실행해도 두 번째 호출이 throw 되지 않음을
검증. drift `migrateAndValidate` 가 두 번째에는 schemaVersion 매치이므로 no-op
로 동작해야 한다.

### T4 — phantom v7.5 충돌 복구 (Brief Decision 5 + Doc 014 Critique C2)
시뮬레이션: 첫 마이그레이션이 DDL 일부(RENAME, UPDATE) 적용 후 `user_version`
업데이트 직전에 충돌. 다음 실행 시 Drift 는 `user_version = 7` 을 보고
`onUpgrade(from=7, to=8)` 을 다시 호출. 시퀀스: `migrateAndValidate(db, 8)` →
`PRAGMA user_version = 7` 강제 → 새 `AppDatabase` 인스턴스로 다시
`migrateAndValidate(db2, 8)` 호출이 `completes` (예외 없이) 하고 최종
`user_version == 8` 인지 검증. impl 는 `if (from < 8)` 블록을 재진입 가능하게
작성해야 한다 (이미 변환된 컬럼에 ALTER RENAME 재시도 시 throw 회피, UPDATE 는
0행 매칭이라 자동 안전).

## Red State Verification

실행 명령:
```
cd mobile && flutter test test/database/migration_v7_to_v8_test.dart
```

실행 결과 (4 tests, 4 failures):
```
00:00 +0 -1: T1: readings.spread_type values converted to linear [E]
  Unknown schema version 8. Known are 7.
  test/generated_migrations/schema.dart 15:9   GeneratedHelper.databaseForVersion
  package:drift_dev/.../verifier_common.dart   VerifierImplementation.schemaAt
  test/database/migration_v7_to_v8_test.dart 70:24
00:00 +0 -2: T2: ... [E]  Unknown schema version 8. Known are 7.
00:00 +0 -3: T3: idempotency ... [E]  Unknown schema version 8. Known are 7.
00:00 +0 -4: T4: phantom v7.5 crash recovery ... [E]
                Unknown schema version 8. Known are 7.
00:00 +0 -4: Some tests failed.
```

Red 진단: `app_database.dart:25` `schemaVersion => 7` + onUpgrade 에 `if (from < 8)`
블록 부재 + drift_dev codegen 이 v8 snapshot 미생성 (`schema.dart` `versions = [7]`).
impl 단계는 (1) `dart run drift_dev schema dump` 로 v8 snapshot 생성, (2)
`schemaVersion 8` 으로 변경, (3) `if (from < 8)` 블록 작성 (재진입 가능), (4)
`drift_dev schema generate` 재실행하여 `GeneratedHelper` 가 v8 도 인스턴스화하도록
업데이트한다.

## Adjustments from Doc 008 Pattern

- T2: 도메인 코드 `db.userSettingsTable` 대신 raw `customSelect` 사용 — 컬럼
  rename 검증을 도메인 모델 의존 없이 SQL 레벨에서 직접 수행 (테스트가 generated
  코드 갱신 순서에 결합되지 않도록).
- T1: 동일하게 raw `customSelect('SELECT spread_type FROM readings')` 사용.
- T4: Doc 008 패턴에 없던 신규 테스트. Brief Decision 5/16 + Doc 014 Critique C2
  대응.

## Companion Signature Verification

`schema_v7.dart:1143` `ReadingsCompanion.insert` 시그니처: `id`, `deckId`,
`spreadType`, `createdAt`, `updatedAt` required. 사용 그대로 통과.
`schema_v7.dart:1995` `UserSettingsCompanion.insert` 시그니처: `updatedAt` 만
required, 나머지는 모두 `Value.absent()` default. `defaultSpreadType: const
Value('threeCard')` 사용 그대로 통과.

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
