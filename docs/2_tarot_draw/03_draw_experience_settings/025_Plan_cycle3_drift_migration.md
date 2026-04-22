---
id: "025"
type: plan
title: "Plan: cycle 3 — Drift schema v7→v8 migration (re-entrant onUpgrade + v8 snapshot)"
created: 2026-04-20
cycle: 3
traces_scope: "017"
traces_tdd_red: "024"
status: ready
summary: >
  Cycle 3 impl 계획. Drift schemaVersion 7→8 승격 + 재진입 가능한 `if (from < 8)`
  onUpgrade 블록 (트랜잭션 내부 `PRAGMA user_version = 8` commit, ALTER TABLE 는
  `pragma_table_info` 존재 검사로 가드) + v8 snapshot 생성 (`drift_dev schema dump`
  → `schema generate`) → 024 의 T1–T4 통과. 코드 수정 → snapshot dump → generate
  순서 엄수. 컬럼 rename 은 Drift camelCase 자동 변환에 의존 (`named()` 불요).
keywords: [plan, cycle3, drift, migration, v7-to-v8, re-entrant, schema-snapshot, phantom-recovery]
---

# Plan: cycle 3 — Drift schema v7→v8 migration

## 1. Goal

Schema v8 을 활성화하고 024 가 정의한 4 테스트(T1 readings 값 변환, T2
user_settings 컬럼 rename + 값 변환, T3 멱등성, T4 phantom v7.5 복구) 가 모두
green 이 되도록 한다. 재진입 가능한 `if (from < 8)` onUpgrade 블록을 작성하고
트랜잭션 **내부에서** `PRAGMA user_version = 8` 을 commit 하여 phantom v7.5
상태(스키마는 v8, user_version=7)에서 두 번째 onUpgrade 호출이 throw 없이
완료되도록 한다.

## 2. Prerequisite: drift v8 snapshot

Brief Decision 17 ("schema snapshot 관리: dump 후 commit") + 017 Out of Scope #5
("v7 snapshot 재 dump 금지") 해석: **v7 snapshot 재생성은 금지**, **v8
snapshot 신규 생성은 허용·필수**. 두 규칙은 충돌 없이 양립한다.

순서가 중요하다. snapshot dump 는 컴파일 가능한 `app_database.dart` (schemaVersion
== 8 + table getter rename 반영) 를 입력으로 받기 때문에 **코드 수정이 선행**되어야
한다.

### Step-by-step

1. **§3 의 코드 수정 먼저 적용** — 특히 `app_database.dart` `schemaVersion 7 → 8`
   + onUpgrade `if (from < 8)` 블록 (§4) + `user_settings_table.dart`
   `defaultSpreadType → defaultLayoutType` 게터 rename. (이 시점 `flutter test`
   는 generated_migrations 가 아직 v7 만 알고 있으므로 fail — 정상.)
2. **build_runner 1차 재생성**:
   ```
   cd /Users/kampikrein/A/personality/mobile
   dart run build_runner build --delete-conflicting-outputs
   ```
   → `app_database.g.dart` 가 v8 스키마 구조 (`default_layout_type` 컬럼 포함) 로
   재생성. 컴파일 통과해야 다음 단계 가능.
3. **v8 snapshot dump** (v7 파일은 건드리지 않음):
   ```
   cd /Users/kampikrein/A/personality/mobile
   dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/
   ```
   → `mobile/drift_schemas/drift_schema_v8.json` 신규 생성.
   `drift_schema_v7.json` 은 기존 그대로 (017 Out of Scope #5 준수).
4. **generated_migrations 재생성**:
   ```
   cd /Users/kampikrein/A/personality/mobile
   dart run drift_dev schema generate --data-classes --companions drift_schemas/ test/generated_migrations/
   ```
   → `test/generated_migrations/schema.dart` 의 `GeneratedHelper` 가
   `case 8: return v8.DatabaseAtV8(db)` 분기 + `versions = [7, 8]` 로 갱신.
   `schema_v8.dart` 신규 파일 생성.
5. **커밋**: `drift_schemas/drift_schema_v8.json` + `test/generated_migrations/schema_v8.dart`
   + `test/generated_migrations/schema.dart` 변경분을 함께 커밋 (Brief Decision 17
   "git commit schema snapshots").

## 3. File-by-file changes

### Modified (3 source files)

#### M1. `mobile/lib/core/database/app_database.dart`

- L25: `int get schemaVersion => 7;` → `int get schemaVersion => 8;`
- onUpgrade 끝 (현재 L68 `if (from < 7)` 블록 다음) 에 `if (from < 8)` 블록 추가.
  본문은 §4 참조 (Brief Model Anchors § DB 마이그레이션 정책 의 코드 + 재진입성
  가드).

#### M2. `mobile/lib/core/database/tables/user_settings_table.dart`

- L15-16: 게터 rename
  ```dart
  TextColumn get defaultSpreadType =>
      text().withDefault(const Constant('custom'))();
  ```
  →
  ```dart
  TextColumn get defaultLayoutType =>
      text().withDefault(const Constant('custom'))();
  ```
  Drift 는 camelCase getter 를 snake_case 컬럼명으로 자동 변환한다 (확인:
  `experienceLevel` → `experience_level`, `cardsPerRow` → `cards_per_row` —
  `app_database.g.dart:1929,2017`). 따라서 **`named('default_layout_type')` 호출
  불필요**. 새 게터 이름이 자동으로 `default_layout_type` 컬럼에 매핑되며, 이
  컬럼은 §4 의 ALTER TABLE RENAME 으로 v8 마이그레이션 시 생성된다.

#### M3. `mobile/lib/features/settings/data/repositories/user_settings_repository_impl.dart`

기존 cycle 2 (Option B) 잔여 cleanup. 도메인 모델 (`UserSettings.defaultLayoutType`)
은 이미 cycle 2 에서 rename 되었지만 Drift 행/companion 은 아직 옛 이름 (`defaultSpreadType`)
을 사용 중이므로 함께 rename 한다.

- L63: `UserSettingsTableCompanion(defaultSpreadType: Value(layoutTypeName))`
  → `UserSettingsTableCompanion(defaultLayoutType: Value(layoutTypeName))`
- L114: `(e) => e.name == row.defaultSpreadType,`
  → `(e) => e.name == row.defaultLayoutType,`
- L113-116 의 `firstWhere + orElse: LayoutType.linear` fallback 패턴은 **그대로
  유지** (Brief Decision 18 영구 정책).

### Regenerated (build_runner 자동, 직접 편집 금지)

- `mobile/lib/core/database/app_database.g.dart` — Drift 가 v8 스키마 구조
  반영 (UserSettingsTable 의 `defaultLayoutType` GeneratedColumn).
- `mobile/lib/features/settings/domain/entities/user_settings.freezed.dart`
  + `user_settings.g.dart` — **변동 없음**. 도메인 entity 의 `defaultLayoutType`
  필드는 cycle 2 에서 이미 rename 완료.

### Created (drift_dev codegen)

- `mobile/drift_schemas/drift_schema_v8.json`
- `mobile/test/generated_migrations/schema_v8.dart`
- `mobile/test/generated_migrations/schema.dart` (regenerated, not new)

### Out of bounds (cycle 4-6, 절대 건드리지 않음)

- `mobile/lib/features/reading/domain/entities/spread_layout.dart`
- `mobile/lib/features/home/presentation/pages/home_page.dart`
- `mobile/lib/features/draw/presentation/pages/draw_result_page.dart`
- `mobile/lib/features/draw/presentation/pages/animated_draw_page.dart`
- `mobile/lib/features/reading/presentation/pages/reading_list_page.dart`

## 4. onUpgrade Block Template

Brief 011 Model Anchors § DB 마이그레이션 정책 의 정식 코드 + 재진입성 가드 추가.
Plan 은 코드를 그대로 옮겨 적지 않고 **참조 + 차이점만 명시**한다 (impl 에이전트가
Brief 의 정식 anchor 를 1차 출처로 사용).

### Base (Brief Model Anchors L348-369 그대로)

```dart
if (from < 8) {
  await m.database.customStatement('PRAGMA foreign_keys = OFF');
  try {
    await m.database.transaction(() async {
      // [A] readings 값 변환 — 멱등 (legacy 값 매칭 0행이면 no-op)
      await m.database.customStatement(
        "UPDATE readings SET spread_type = 'linear' "
        "WHERE spread_type IN ('single', 'threeCard', 'custom')",
      );
      // [B] user_settings 값 변환 — 멱등
      await m.database.customStatement(
        "UPDATE user_settings SET default_spread_type = 'linear' "
        "WHERE default_spread_type IN ('single', 'threeCard', 'custom')",
      );
      // [C] user_settings 컬럼 rename — 비-멱등, §4.1 가드 필수
      await m.database.customStatement(
        'ALTER TABLE user_settings RENAME COLUMN default_spread_type '
        'TO default_layout_type',
      );
      // ⚠ Decision 5 — phantom v7.5 방지: user_version 도 트랜잭션 내부 commit
      await m.database.customStatement('PRAGMA user_version = 8');
    });
  } finally {
    await m.database.customStatement('PRAGMA foreign_keys = ON');
  }
}
```

### 4.1 재진입성 추가 (T4 통과를 위한 diff)

ALTER TABLE RENAME COLUMN 은 두 번째 실행 시 "no such column: default_spread_type"
으로 throw 한다. T4 의 phantom v7.5 시뮬레이션은 정확히 이 상황 (스키마는 v8, user_version=7)
을 만든다. [C] 블록을 `pragma_table_info` 검사로 감싼다.

```dart
// [C] (재진입 가드 적용 버전)
final cols = await m.database.customSelect(
  "SELECT name FROM pragma_table_info('user_settings')"
).get();
final names = cols.map((r) => r.data['name'] as String).toSet();
if (names.contains('default_spread_type')) {
  await m.database.customStatement(
    'ALTER TABLE user_settings RENAME COLUMN default_spread_type '
    'TO default_layout_type',
  );
}
```

[A], [B] 의 UPDATE 는 본질적으로 멱등 (WHERE IN 절 매칭 0행 → no-op) 이므로
별도 가드 불필요.

[B] 는 [C] 보다 **반드시 먼저** 실행되어야 한다 ([C] 가 컬럼명을 바꾼 뒤에
[B] 가 옛 컬럼명으로 UPDATE 시도하면 첫 마이그레이션에서도 throw). 위 순서를
반드시 보존한다.

## 5. Test → code mapping

| Test | 검증 대상 | 통과시키는 변경 |
|------|----------|----------------|
| **T1** readings.spread_type 값 변환 | UPDATE `readings` 3행 → `'linear'` | §4 [A] 블록 |
| **T2** user_settings 컬럼 rename + 값 변환 | (a) `default_layout_type` 컬럼 존재 + 값 `'linear'`, (b) `default_spread_type` 조회 throw | §4 [B] (값 변환) + [C] (컬럼 rename) |
| **T3** 멱등성 | `migrateAndValidate(db, 8)` 두 번 호출 throw 없음 | §4 전체 — 두 번째 호출은 schemaVersion 매치이므로 onUpgrade 자체가 호출되지 않음 (Drift 동작) |
| **T4** phantom v7.5 복구 | `PRAGMA user_version = 7` 강제 후 재마이그레이션 throw 없음 + 최종 user_version=8 | §4.1 [C] 재진입 가드 + §4 트랜잭션 내부 `PRAGMA user_version = 8` |

T3 와 T4 는 다른 시나리오: T3 은 Drift 가 schemaVersion 일치를 감지하여 onUpgrade
호출 자체를 건너뛰므로 통과 (block 코드와 무관), T4 는 실제로 onUpgrade 가
재호출되므로 §4.1 가드가 결정적이다.

## 6. Risks

### R1. Snapshot dump 와 코드 수정의 순환 의존

`drift_dev schema dump` 는 컴파일 가능한 `app_database.dart` 를 요구한다.
한편 024 테스트는 v8 snapshot (`schema_v8.dart`) 가 존재해야 컴파일된다. 따라서
**코드 수정 → build_runner → dump → generate → flutter test** 순서를 절대 어기지
않는다. 중간 단계에서 `flutter test` 실행 금지 (시간 낭비).

§2 Step-by-step 의 5단계가 정답이며, impl 에이전트는 이 순서를 그대로 따른다.

### R2. 기존 마이그레이션 테스트와의 충돌

조사 결과 (`find mobile/test -name "*migration*"`): `migration_v7_to_v8_test.dart`
1개만 존재 (024 의 새 테스트). 기존 마이그레이션 테스트 없음 → 회귀 리스크 없음.

cycle 1·2 에서 추가된 테스트 (`layout_type_mapping_test.dart`,
`user_settings_repository_layout_type_test.dart`) 는 도메인 enum + repository
fallback 만 검증하므로 schemaVersion 변경에 영향받지 않음 (확인 필요).

### R3. Drift 컬럼명 자동 변환 동작 확인

`named('default_layout_type')` 호출 없이 `defaultLayoutType` getter 만으로
컬럼명이 `default_layout_type` 이 되는지: **확인 완료**. 같은 파일 내 기존
camelCase getter 들 (`experienceLevel` → `experience_level`,
`cardsPerRow` → `cards_per_row`, `selectedDeckId` → `selected_deck_id`,
`customCardWidthMm` → `custom_card_width_mm`) 모두 snake_case 자동 변환 (출처:
`app_database.g.dart:1929,2017`). 따라서 §3 M2 의 게터 rename 만으로 충분.

### R4. cycle 2 잔여 column 이름과의 충돌

cycle 2 시점에는 도메인 entity (`UserSettings.defaultLayoutType`) 만 rename
하고 Drift companion 은 옛 이름 (`defaultSpreadType`) 을 그대로 사용했다 (Option B).
cycle 3 의 §3 M2 + M3 가 이를 정리한다. cycle 2 의 fallback 패턴 (Decision 18) 은
영구이므로 유지.

## 7. Verification plan (verify seq=12 가 실행)

순서대로 실행. 각 단계가 PASS 해야 다음으로 진행.

```
# 1. build_runner 클린
cd /Users/kampikrein/A/personality/mobile
dart run build_runner build --delete-conflicting-outputs
# 기대: Succeeded after Xs (no errors)

# 2. 024 의 T1-T4 통과 확인
cd /Users/kampikrein/A/personality/mobile
flutter test test/database/migration_v7_to_v8_test.dart
# 기대: +4 (4 passed)

# 3. cycle 1·2 회귀 없음 확인
cd /Users/kampikrein/A/personality/mobile
flutter test test/features/reading/domain/entities/layout_type_mapping_test.dart \
             test/features/settings/data/repositories/user_settings_repository_layout_type_test.dart
# 기대: 27/27 green (변경 없음)

# 4. lib 코드에서 옛 컬럼명 잔존 0건 (마이그레이션 SQL 리터럴 제외)
grep -r "default_spread_type" /Users/kampikrein/A/personality/mobile/lib/
# 허용: app_database.dart 내 UPDATE/ALTER SQL 리터럴
# 그 외 잔존 0건이어야 함
```

`flutter analyze` 는 cycle 4-6 에서 SpreadType → LayoutType UI 마이그레이션이
아직 진행 중이므로 **deferred** (017 Verification Plan 정책). cycle 3 verify 에서는
실행하지 않는다.

## Cycle Boundary Guards

- **DO NOT** touch: `spread_layout.dart`, `home_page.dart`, `draw_result_page.dart`,
  `animated_draw_page.dart`, `reading_list_page.dart` — cycles 4–6 영역.
- **DO NOT** run `flutter analyze` 광역. SpreadType 잔존 경고는 cycle 4-6 에서
  해소.
- **DO NOT** re-dump v7 snapshot (`drift_schemas/drift_schema_v7.json`).
  v8 신규 생성만 허용.
- **DO NOT** drift entity (`UserSettings`) 도메인 필드 추가 변경. cycle 2 가
  완료한 `defaultLayoutType` 그대로 사용.

## Cycle Complete Definition

- §3 의 3 source 파일 수정 + build_runner 재생성 + v8 snapshot 2 파일 신규 +
  `schema.dart` 갱신.
- §7 의 4 단계 verify 모두 PASS.
- 단일 logical commit: "feat(db): migrate Drift schema v7→v8 (LayoutType rename
  + re-entrant onUpgrade)".

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
