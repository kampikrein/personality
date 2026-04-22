---
id: "043"
type: plan
title: "Cycle 1 구현 플랜 — data layer (IntentPlacement enum + UserSettings 필드 + Drift v9 + Dao + Repository)"
created: 2026-04-21
cycle: 1
status: completed
traces_scope: "041"
traces_brief: "040"
summary: >
  IntentPlacement enum 신규 생성, UserSettings freezed 필드 추가, Drift v8→v9 마이그레이션
  (intent_placement TEXT 컬럼), UserSettingsDao.updateIntentPlacement, Repository 추상/구현
  메서드 추가. 코드 생성 후 13개 TDD Red 테스트 전부 Green으로 전환.
keywords: [intent-placement, drift-migration, user-settings, freezed, data-layer, tdd]
---

# 043 — Cycle 1 구현 플랜: data layer

## Goal

TDD Red 문서(042)에서 확인된 13개 컴파일/런타임 실패 테스트를
`mobile/test/features/settings/intent_placement_test.dart` 에서 전부 GREEN으로 전환한다.

변경은 data layer에 국한되며 Cycle 2(Settings UI), Cycle 3(Flow integration)의
선행 조건이 된다.

**Model Anchor 정렬 (Brief 040)**:
- MA-1: `IntentPlacement` enum `beforeShuffle / afterDraw / disabled`, JSON serializable
- MA-2: `UserSettings.intentPlacement` 기본값 `beforeShuffle`, Freezed 재생성 필수
- MA-3: Drift v8→v9, `intent_placement TEXT NOT NULL DEFAULT 'beforeShuffle'`
- MA-4: Dao `updateIntentPlacement`, Repository 추상 + 구현

---

## Scope

### Included
| # | Item | 설명 |
|---|------|------|
| 1 | `intent_placement.dart` 신규 생성 | `enum IntentPlacement` 3값 + `@JsonEnum` |
| 2 | `user_settings.dart` 필드 추가 | `@Default(IntentPlacement.beforeShuffle) IntentPlacement intentPlacement` |
| 3 | `user_settings_table.dart` 컬럼 추가 | `TextColumn get intentPlacement` |
| 4 | `app_database.dart` schemaVersion 8→9 + onUpgrade | `ALTER TABLE … ADD COLUMN intent_placement` |
| 5 | `user_settings_dao.dart` 메서드 추가 | `updateIntentPlacement(String value)` |
| 6 | `user_settings_repository.dart` 시그니처 추가 | `Future<void> updateIntentPlacement(IntentPlacement)` |
| 7 | `user_settings_repository_impl.dart` 구현 추가 | `updateIntentPlacement` 구현 + `_toDomain` 매핑 |
| 8 | 코드 생성 실행 | `dart run build_runner build --delete-conflicting-outputs` |
| 9 | 테스트 검증 | 13개 모두 GREEN |

### Excluded
| Item | 이유 |
|------|------|
| Settings UI 페이지 | Cycle 2 담당 |
| 라우팅 분기, 페이지 조건부 | Cycle 3 담당 |
| `readingQuestionProvider` 정비 | Cycle 3 담당 |
| 빌드 APK 검증 | Cycle 1 impl 범위 밖 (전체 사이클 완료 후 수행) |

---

## Structural Decisions

No structural decisions required — 패턴이 기존 코드(`CardSizePreset`, `LayoutType`, Drift v7→v8 마이그레이션)에 이미 확립되어 있으며, Brief 040이 모든 아키텍처 결정을 완료함.

---

## File Change Summary

### New Files
| # | File Path | 설명 |
|---|-----------|------|
| 1 | `mobile/lib/features/settings/domain/entities/intent_placement.dart` | `IntentPlacement` enum |

### Modified Files
| # | File Path | 변경 내용 |
|---|-----------|---------|
| 2 | `mobile/lib/features/settings/domain/entities/user_settings.dart` | `intentPlacement` 필드 + import 추가 |
| 3 | `mobile/lib/core/database/tables/user_settings_table.dart` | `intentPlacement` TextColumn 추가 |
| 4 | `mobile/lib/core/database/app_database.dart` | schemaVersion 9, `from < 9` 마이그레이션 블록 추가 |
| 5 | `mobile/lib/core/database/daos/user_settings_dao.dart` | `updateIntentPlacement(String value)` 메서드 추가 |
| 6 | `mobile/lib/features/settings/domain/repositories/user_settings_repository.dart` | `updateIntentPlacement` 추상 메서드 추가 |
| 7 | `mobile/lib/features/settings/data/repositories/user_settings_repository_impl.dart` | `updateIntentPlacement` 구현 + `_toDomain` 매핑 |

### Auto-generated (build_runner)
| # | File Path | 트리거 |
|---|-----------|-------|
| 8 | `mobile/lib/features/settings/domain/entities/user_settings.freezed.dart` | `user_settings.dart` 변경 |
| 9 | `mobile/lib/features/settings/domain/entities/user_settings.g.dart` | `user_settings.dart` 변경 |
| 10 | `mobile/lib/core/database/app_database.g.dart` | `user_settings_table.dart` 변경 |
| 11 | `mobile/lib/core/database/daos/user_settings_dao.g.dart` | `user_settings_dao.dart` 변경 |

---

## Step 1 — `intent_placement.dart` 신규 생성

### Approach

`CardSizePreset`(열거형 필드 없음)과 달리 `IntentPlacement`는 UI 텍스트 없이 DB 저장 및
JSON 직렬화만 필요하다. `@JsonEnum`을 사용해 `fieldRename: FieldRename.none`을 명시하면
enum 값 이름 그대로(camelCase) 직렬화된다.
이 방식은 `LayoutType` enum(user_settings.dart에서 이미 `.name` 기반 직렬화 사용)과
일관된다.

**파일 위치**: `mobile/lib/features/settings/domain/entities/` — 동일 도메인 엔티티 폴더.

**Depends on**: 없음 (독립 신규 파일).

### Current Code

해당 파일 미존재.

### After Code

```dart
// mobile/lib/features/settings/domain/entities/intent_placement.dart (NEW)
import 'package:json_annotation/json_annotation.dart';

/// 뽑기 플로우에서 의도(질문) 입력이 나타나는 시점.
///
/// - [beforeShuffle]: 셔플 전 IntentionPage를 통과 (기존 동작, 기본값).
/// - [afterDraw]: deck 선택 후 shuffle로 직행, 결과 화면에서 입력.
/// - [disabled]: 의도 입력 없이 진행, reading.question = null.
///
/// JSON 직렬화 key는 enum 이름 그대로 (camelCase): "beforeShuffle", "afterDraw", "disabled".
@JsonEnum()
enum IntentPlacement {
  beforeShuffle,
  afterDraw,
  disabled;
}
```

### Considerations

- `@JsonEnum(fieldRename: FieldRename.none)`가 기본값이므로 명시 생략 가능.
  단, 향후 필드명 변경 시 혼선 방지를 위해 주석에 직렬화 형식을 문서화함.
- `CardSizePreset`은 생성자 파라미터(label, subtitle 등)를 가지지만
  `IntentPlacement`는 저장 시점 외 UI 텍스트가 없어 simple enum으로 구현.
  UI 텍스트(label, description)는 Cycle 2 UI 페이지에서 직접 switch/map으로 처리.

**Impact Analysis**:
- 이 파일을 import하는 코드: Step 2(`user_settings.dart`)가 최초 import.

---

## Step 2 — `user_settings.dart` 필드 추가

### Approach

기존 freezed factory에 `@Default(IntentPlacement.beforeShuffle) IntentPlacement intentPlacement`
필드를 추가한다.

**위치**: `updatedAt` 바로 앞. `updatedAt`은 `required`이므로 마지막에 유지.

**JSON 직렬화**: freezed + json_serializable이 `IntentPlacement.name` 기반으로
자동 처리. `@JsonEnum()`이 붙은 enum은 `json_serializable`이 이름 그대로
직렬화하므로 별도 `JsonConverter` 불필요.

**Depends on**: Step 1 (IntentPlacement 타입).

### Current Code

```dart
// mobile/lib/features/settings/domain/entities/user_settings.dart:1-37
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../reading/domain/entities/layout_type.dart';
import 'card_size_preset.dart';

part 'user_settings.freezed.dart';
part 'user_settings.g.dart';

@freezed
class UserSettings with _$UserSettings {
  const UserSettings._();

  const factory UserSettings({
    @Default('rws-standard') String selectedDeckId,
    @Default(4) int experienceLevel,
    @Default(3) int defaultCardCount,
    @Default(false) bool showFaceUp,
    @Default(false) bool quickDrawEnabled,
    @Default(LayoutType.linear) LayoutType defaultLayoutType,
    @Default(true) bool showCardName,
    @Default(true) bool allowReversed,
    @Default(3) int cardsPerRow,
    @Default(CardSizePreset.standardTarot) CardSizePreset cardSizePreset,
    @Default(70.0) double customCardWidthMm,
    @Default(120.0) double customCardHeightMm,
    required DateTime updatedAt,
  }) = _UserSettings;

  /// The effective card aspect ratio (width / height) based on preset or custom values.
  double get cardAspectRatio => cardSizePreset == CardSizePreset.custom
      ? customCardWidthMm / customCardHeightMm
      : cardSizePreset.aspectRatio;

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
}
```

### After Code

```dart
// mobile/lib/features/settings/domain/entities/user_settings.dart (MODIFIED)
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../reading/domain/entities/layout_type.dart';
import 'card_size_preset.dart';
import 'intent_placement.dart'; // ← NEW

part 'user_settings.freezed.dart';
part 'user_settings.g.dart';

@freezed
class UserSettings with _$UserSettings {
  const UserSettings._();

  const factory UserSettings({
    @Default('rws-standard') String selectedDeckId,
    @Default(4) int experienceLevel,
    @Default(3) int defaultCardCount,
    @Default(false) bool showFaceUp,
    @Default(false) bool quickDrawEnabled,
    @Default(LayoutType.linear) LayoutType defaultLayoutType,
    @Default(true) bool showCardName,
    @Default(true) bool allowReversed,
    @Default(3) int cardsPerRow,
    @Default(CardSizePreset.standardTarot) CardSizePreset cardSizePreset,
    @Default(70.0) double customCardWidthMm,
    @Default(120.0) double customCardHeightMm,
    @Default(IntentPlacement.beforeShuffle) IntentPlacement intentPlacement, // ← NEW
    required DateTime updatedAt,
  }) = _UserSettings;

  /// The effective card aspect ratio (width / height) based on preset or custom values.
  double get cardAspectRatio => cardSizePreset == CardSizePreset.custom
      ? customCardWidthMm / customCardHeightMm
      : cardSizePreset.aspectRatio;

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
}
```

### Considerations

- `@Default(IntentPlacement.beforeShuffle)`: Brief Decision 3 — 기본값이 `beforeShuffle`이면
  기존 사용자 플로우(IntentionPage 강제 통과)와 동일하게 유지되어 회귀 없음.
- JSON key는 `"intentPlacement"` (camelCase). T3 테스트의 `containsPair('intentPlacement', 'beforeShuffle')` 검증과 일치.
- build_runner 재생성 전까지 이 파일은 컴파일 불가 상태임 — Step 8에서 해결.

**Impact Analysis**:
- `user_settings.freezed.dart`, `user_settings.g.dart` 자동 재생성 필요.
- Cycle 2/3에서 `UserSettings.intentPlacement`를 읽는 코드들은 재생성 후 자동으로 타입 인식.

---

## Step 3 — `user_settings_table.dart` 컬럼 추가

### Approach

Drift 테이블 정의에 `intentPlacement` TextColumn을 추가한다.
기본값 `'beforeShuffle'`은 `withDefault(const Constant('beforeShuffle'))`.

Drift는 `camelCase` getter 이름을 `snake_case` SQL 컬럼명으로 자동 변환하므로
`intentPlacement` → `intent_placement` 매핑이 자동 처리된다.

**Depends on**: 없음 (테이블 정의 변경은 독립).

### Current Code

```dart
// mobile/lib/core/database/tables/user_settings_table.dart:1-33
import 'package:drift/drift.dart';

class UserSettingsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get selectedDeckId =>
      text().withDefault(const Constant('rws-standard'))();
  IntColumn get experienceLevel =>
      integer().withDefault(const Constant(4))();
  IntColumn get defaultCardCount =>
      integer().withDefault(const Constant(3))();
  BoolColumn get showFaceUp =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get quickDrawEnabled =>
      boolean().withDefault(const Constant(false))();
  TextColumn get defaultLayoutType =>
      text().withDefault(const Constant('custom'))();
  BoolColumn get showCardName =>
      boolean().nullable().withDefault(const Constant(true))();
  BoolColumn get allowReversed =>
      boolean().nullable().withDefault(const Constant(true))();
  TextColumn get cardSizePreset =>
      text().withDefault(const Constant('standardTarot'))();
  RealColumn get customCardWidthMm =>
      real().withDefault(const Constant(70.0))();
  RealColumn get customCardHeightMm =>
      real().withDefault(const Constant(120.0))();
  IntColumn get cardsPerRow =>
      integer().nullable().withDefault(const Constant(3))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  String get tableName => 'user_settings';
}
```

### After Code

```dart
// mobile/lib/core/database/tables/user_settings_table.dart (MODIFIED)
import 'package:drift/drift.dart';

class UserSettingsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get selectedDeckId =>
      text().withDefault(const Constant('rws-standard'))();
  IntColumn get experienceLevel =>
      integer().withDefault(const Constant(4))();
  IntColumn get defaultCardCount =>
      integer().withDefault(const Constant(3))();
  BoolColumn get showFaceUp =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get quickDrawEnabled =>
      boolean().withDefault(const Constant(false))();
  TextColumn get defaultLayoutType =>
      text().withDefault(const Constant('custom'))();
  BoolColumn get showCardName =>
      boolean().nullable().withDefault(const Constant(true))();
  BoolColumn get allowReversed =>
      boolean().nullable().withDefault(const Constant(true))();
  TextColumn get cardSizePreset =>
      text().withDefault(const Constant('standardTarot'))();
  RealColumn get customCardWidthMm =>
      real().withDefault(const Constant(70.0))();
  RealColumn get customCardHeightMm =>
      real().withDefault(const Constant(120.0))();
  IntColumn get cardsPerRow =>
      integer().nullable().withDefault(const Constant(3))();
  TextColumn get intentPlacement =>                           // ← NEW
      text().withDefault(const Constant('beforeShuffle'))();  // ← NEW
  DateTimeColumn get updatedAt => dateTime()();

  @override
  String get tableName => 'user_settings';
}
```

### Considerations

- `nullable()` 없이 `NOT NULL`로 정의. 기본값 `'beforeShuffle'`이 있으므로
  기존 행에 값이 없어도 마이그레이션 시 DEFAULT가 채워진다.
- Drift가 `intentPlacement` → `intent_placement` 자동 변환하므로
  Step 4 마이그레이션 SQL의 컬럼명 `intent_placement`와 일치.

**Impact Analysis**:
- `app_database.g.dart` 자동 재생성 (Drift가 `UserSettingsTableData` 데이터 클래스 재생성).
- `user_settings_dao.g.dart`도 `UserSettingsTableCompanion`이 갱신됨.

---

## Step 4 — `app_database.dart` schemaVersion 9 + 마이그레이션

### Approach

`schemaVersion`을 `8 → 9`로 증가하고, `from < 9` 블록에서
`ALTER TABLE user_settings ADD COLUMN intent_placement TEXT NOT NULL DEFAULT 'beforeShuffle'`
를 실행한다.

v8 마이그레이션(PRAGMA foreign_keys, 트랜잭션 패턴)과 달리 v9는 단순 컬럼 추가이므로
트랜잭션/PRAGMA 래핑 불필요. 멱등성은 테이블에 이미 컬럼이 없는 경우에만
ALTER가 실행되어야 하나, SQLite의 `ADD COLUMN`은 컬럼이 이미 있으면 오류를
반환하므로 실제 배포에서 from < 9 조건이 정확히 한 번 실행됨을 보장.

**Depends on**: Step 3 (컬럼명 일치).

### Current Code

```dart
// mobile/lib/core/database/app_database.dart:25-26
  @override
  int get schemaVersion => 8;
```

```dart
// mobile/lib/core/database/app_database.dart:97-108 (마지막 from < 8 블록 이후)
          } // end if (from < 8)
        },
      );
}
```

### After Code

schemaVersion 변경:

```dart
// mobile/lib/core/database/app_database.dart — schemaVersion (CHANGED)
  @override
  int get schemaVersion => 9; // ← CHANGED from 8
```

onUpgrade 끝에 `from < 9` 블록 추가 (기존 `from < 8` 블록 닫는 `}` 바로 뒤):

```dart
          // ... 기존 from < 8 블록 ...
          if (from < 9) {
            await m.database.customStatement(
              "ALTER TABLE user_settings ADD COLUMN intent_placement TEXT NOT NULL DEFAULT 'beforeShuffle'",
            );
          }
        },
      );
}
```

전체 마이그레이션 컨텍스트 (app_database.dart:28-109, after):

```dart
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) => m.createAll(),
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(userSettingsTable);
          }
          if (from < 3) {
            await m.database.customStatement(
              "UPDATE user_settings SET experience_level = 3, default_spread_type = 'custom'",
            );
          }
          if (from < 4) {
            await m.database.customStatement(
              'ALTER TABLE user_settings ADD COLUMN show_card_name INTEGER DEFAULT 1',
            );
            await m.database.customStatement(
              'ALTER TABLE user_settings ADD COLUMN allow_reversed INTEGER DEFAULT 1',
            );
          }
          if (from < 5) {
            await m.database.customStatement(
              "ALTER TABLE user_settings ADD COLUMN card_size_preset TEXT DEFAULT 'standardTarot'",
            );
            await m.database.customStatement(
              'ALTER TABLE user_settings ADD COLUMN custom_card_width_mm REAL DEFAULT 70.0',
            );
            await m.database.customStatement(
              'ALTER TABLE user_settings ADD COLUMN custom_card_height_mm REAL DEFAULT 120.0',
            );
          }
          if (from < 6) {
            await m.database.customStatement(
              'ALTER TABLE user_settings ADD COLUMN cards_per_row INTEGER DEFAULT 3',
            );
          }
          if (from < 7) {
            await m.database.customStatement(
              'UPDATE user_settings SET experience_level = 4 WHERE experience_level = 3',
            );
          }
          if (from < 8) {
            await m.database.customStatement('PRAGMA foreign_keys = OFF');
            try {
              await m.database.transaction(() async {
                await m.database.customStatement(
                  "UPDATE readings SET spread_type = 'linear' "
                  "WHERE spread_type IN ('single', 'threeCard', 'custom')",
                );
                final cols = await m.database.customSelect(
                  "SELECT name FROM pragma_table_info('user_settings')",
                ).get();
                final hasOldCol = cols.any(
                  (r) => r.data['name'] == 'default_spread_type',
                );
                if (hasOldCol) {
                  await m.database.customStatement(
                    "UPDATE user_settings SET default_spread_type = 'linear' "
                    "WHERE default_spread_type IN ('single', 'threeCard', 'custom')",
                  );
                  await m.database.customStatement(
                    'ALTER TABLE user_settings RENAME COLUMN default_spread_type '
                    'TO default_layout_type',
                  );
                }
                await m.database.customStatement('PRAGMA user_version = 8');
              });
            } finally {
              await m.database.customStatement('PRAGMA foreign_keys = ON');
            }
          }
          if (from < 9) {                                                   // ← NEW
            await m.database.customStatement(                               // ← NEW
              "ALTER TABLE user_settings ADD COLUMN intent_placement TEXT NOT NULL DEFAULT 'beforeShuffle'", // ← NEW
            );                                                              // ← NEW
          }                                                                 // ← NEW
        },
      );
```

### Considerations

- `NOT NULL DEFAULT 'beforeShuffle'`: SQLite에서 DEFAULT가 있는 NOT NULL 컬럼은
  기존 행에 자동으로 DEFAULT 값이 채워진다. 기존 사용자 마이그레이션 회귀 없음.
- v8 블록에 `PRAGMA user_version = 8` 명시가 있으나, Drift 자체도 schemaVersion을
  관리하므로 v9에서 재선언 불필요 (Drift가 v9로 bump).
- `onCreate: (Migrator m) => m.createAll()`: 신규 설치 시 `userSettingsTable`의
  `intentPlacement` 컬럼이 포함된 상태로 테이블 생성 → 마이그레이션 불필요.

**Impact Analysis**:
- `app_database.g.dart` 자동 재생성.
- T5 테스트(PRAGMA table_info 컬럼 확인)가 이 변경에 의존.

---

## Step 5 — `user_settings_dao.dart` 메서드 추가

### Approach

기존 `updateSettings(UserSettingsTableCompanion)` 패턴을 따라
`updateIntentPlacement(String value)` 특화 메서드를 추가한다.

String 파라미터를 받는 이유: Dao는 도메인 enum을 모르고 DB 레이어만 담당.
enum → String 변환(`value.name`)은 Repository Impl(Step 7)에서 처리.

**Depends on**: Step 3, Step 4 (Companion 필드 `intentPlacement` 존재).

### Current Code

```dart
// mobile/lib/core/database/daos/user_settings_dao.dart:40-47
  /// 설정 업데이트. 단일 행(id=1)만 대상.
  Future<void> updateSettings(UserSettingsTableCompanion companion) async {
    await (update(userSettingsTable)
          ..where((s) => s.id.equals(1)))
        .write(companion.copyWith(
      updatedAt: Value(DateTime.now()),
    ));
  }
```

### After Code

```dart
// mobile/lib/core/database/daos/user_settings_dao.dart (MODIFIED — 추가 부분)

  /// 설정 업데이트. 단일 행(id=1)만 대상.
  Future<void> updateSettings(UserSettingsTableCompanion companion) async {
    await (update(userSettingsTable)
          ..where((s) => s.id.equals(1)))
        .write(companion.copyWith(
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// 의도 입력 배치 설정 업데이트. [value]는 IntentPlacement.name (e.g. 'beforeShuffle'). // ← NEW
  Future<void> updateIntentPlacement(String value) async {                                  // ← NEW
    await (update(userSettingsTable)                                                        // ← NEW
          ..where((s) => s.id.equals(1)))                                                  // ← NEW
        .write(UserSettingsTableCompanion(                                                  // ← NEW
      intentPlacement: Value(value),                                                       // ← NEW
      updatedAt: Value(DateTime.now()),                                                    // ← NEW
    ));                                                                                    // ← NEW
  }                                                                                        // ← NEW
```

### Considerations

- `updateSettings`와 동일한 단일 행(id=1) 패턴 사용.
- `updatedAt: Value(DateTime.now())` 포함 — 설정 변경 시점 항상 갱신.
- `_ensureDefaultRow`를 별도 호출하지 않는 이유: Repository Impl의
  `getSettings()` 진입 시 이미 행이 생성되므로, updateIntentPlacement 호출 전
  반드시 행이 존재한다고 가정 (T4 테스트 setUp에서 db 초기화 후 첫 write 전
  `_ensureDefaultRow`가 필요한지 확인 필요 — `updateSettings`도 동일 패턴임).

  실제로 T4 테스트는 `repo.updateIntentPlacement()` 직전에
  `repo.getSettings()`를 거치지 않으므로, `updateIntentPlacement`가 행이
  없는 상태에서 호출될 수 있다. 이 경우 UPDATE는 0행에 영향을 주고 이후
  `getSettings()`에서 기본 행이 생성되어 `beforeShuffle`을 반환하게 된다.

  **해결**: `updateIntentPlacement` 내부에서 `await _ensureDefaultRow()` 선행.

최종 구현:

```dart
  /// 의도 입력 배치 설정 업데이트. [value]는 IntentPlacement.name (e.g. 'beforeShuffle').
  Future<void> updateIntentPlacement(String value) async {
    await _ensureDefaultRow(); // ← 행 없을 시 기본 행 생성
    await (update(userSettingsTable)
          ..where((s) => s.id.equals(1)))
        .write(UserSettingsTableCompanion(
      intentPlacement: Value(value),
      updatedAt: Value(DateTime.now()),
    ));
  }
```

**Impact Analysis**:
- `user_settings_dao.g.dart` 재생성 (Companion 클래스에 `intentPlacement` Value 필드 추가).

---

## Step 6 — `user_settings_repository.dart` 추상 메서드 추가

### Approach

abstract class에 `Future<void> updateIntentPlacement(IntentPlacement value)` 추가.
타입은 `IntentPlacement` — Repository는 도메인 레이어이므로 enum 사용.

**Depends on**: Step 1 (IntentPlacement 타입).

### Current Code

```dart
// mobile/lib/features/settings/domain/repositories/user_settings_repository.dart:1-17
import '../entities/user_settings.dart';

abstract class UserSettingsRepository {
  Stream<UserSettings> watchSettings();
  Future<UserSettings> getSettings();
  Future<void> updateSelectedDeckId(String deckId);
  // ... (생략) ...
  Future<void> updateCardsPerRow(int count);
}
```

### After Code

```dart
// mobile/lib/features/settings/domain/repositories/user_settings_repository.dart (MODIFIED)
import '../entities/intent_placement.dart'; // ← NEW
import '../entities/user_settings.dart';

abstract class UserSettingsRepository {
  Stream<UserSettings> watchSettings();
  Future<UserSettings> getSettings();
  Future<void> updateSelectedDeckId(String deckId);
  Future<void> updateExperienceLevel(int level);
  Future<void> updateDefaultCardCount(int count);
  Future<void> updateShowFaceUp(bool showFaceUp);
  Future<void> updateQuickDrawEnabled(bool enabled);
  Future<void> updateDefaultLayoutType(String layoutTypeName);
  Future<void> updateShowCardName(bool showCardName);
  Future<void> updateAllowReversed(bool allowReversed);
  Future<void> updateCardSizePreset(String presetName);
  Future<void> updateCustomCardSize(double widthMm, double heightMm);
  Future<void> updateCardsPerRow(int count);
  Future<void> updateIntentPlacement(IntentPlacement value); // ← NEW
}
```

### Considerations

- 추상 메서드이므로 `UserSettingsRepositoryImpl`에서 반드시 구현해야 함 (Step 7).
- Cycle 2 Settings UI 에서 `ref.read(userSettingsRepositoryProvider).updateIntentPlacement(...)` 형태로 호출.

**Impact Analysis**:
- `UserSettingsRepositoryImpl`이 이 인터페이스를 구현 → Step 7에서 메서드 추가 필요.

---

## Step 7 — `user_settings_repository_impl.dart` 구현 + `_toDomain` 매핑

### Approach

두 가지 변경:
1. `updateIntentPlacement(IntentPlacement value)` 구현 → dao에 `value.name` 전달.
2. `_toDomain(UserSettingsTableData row)`에 `intentPlacement` 매핑 추가.

`_toDomain`의 `intentPlacement` 매핑은 `LayoutType` 패턴과 동일:
```dart
IntentPlacement.values.firstWhere(
  (e) => e.name == row.intentPlacement,
  orElse: () => IntentPlacement.beforeShuffle,
)
```

**Depends on**: Step 1, 5, 6.

### Current Code

```dart
// mobile/lib/features/settings/data/repositories/user_settings_repository_impl.dart:99-128
  @override
  Future<void> updateCardsPerRow(int count) async {
    await db.userSettingsDao.updateSettings(
      UserSettingsTableCompanion(cardsPerRow: Value(count)),
    );
  }

  UserSettings _toDomain(UserSettingsTableData row) {
    return UserSettings(
      selectedDeckId: row.selectedDeckId,
      experienceLevel: row.experienceLevel,
      defaultCardCount: row.defaultCardCount,
      showFaceUp: row.showFaceUp,
      quickDrawEnabled: row.quickDrawEnabled,
      defaultLayoutType: LayoutType.values.firstWhere(
        (e) => e.name == row.defaultLayoutType,
        orElse: () => LayoutType.linear,
      ),
      showCardName: row.showCardName ?? true,
      allowReversed: row.allowReversed ?? true,
      cardSizePreset: CardSizePreset.values.firstWhere(
        (p) => p.name == row.cardSizePreset,
        orElse: () => CardSizePreset.standardTarot,
      ),
      customCardWidthMm: row.customCardWidthMm,
      customCardHeightMm: row.customCardHeightMm,
      updatedAt: row.updatedAt,
    );
  }
}
```

### After Code

```dart
// mobile/lib/features/settings/data/repositories/user_settings_repository_impl.dart (MODIFIED)

// import 추가 (파일 상단)
import '../../domain/entities/intent_placement.dart'; // ← NEW

// ... (기존 코드 유지) ...

  @override
  Future<void> updateCardsPerRow(int count) async {
    await db.userSettingsDao.updateSettings(
      UserSettingsTableCompanion(cardsPerRow: Value(count)),
    );
  }

  @override                                                              // ← NEW
  Future<void> updateIntentPlacement(IntentPlacement value) async {     // ← NEW
    await db.userSettingsDao.updateIntentPlacement(value.name);         // ← NEW
  }                                                                     // ← NEW

  UserSettings _toDomain(UserSettingsTableData row) {
    return UserSettings(
      selectedDeckId: row.selectedDeckId,
      experienceLevel: row.experienceLevel,
      defaultCardCount: row.defaultCardCount,
      showFaceUp: row.showFaceUp,
      quickDrawEnabled: row.quickDrawEnabled,
      defaultLayoutType: LayoutType.values.firstWhere(
        (e) => e.name == row.defaultLayoutType,
        orElse: () => LayoutType.linear,
      ),
      showCardName: row.showCardName ?? true,
      allowReversed: row.allowReversed ?? true,
      cardSizePreset: CardSizePreset.values.firstWhere(
        (p) => p.name == row.cardSizePreset,
        orElse: () => CardSizePreset.standardTarot,
      ),
      customCardWidthMm: row.customCardWidthMm,
      customCardHeightMm: row.customCardHeightMm,
      intentPlacement: IntentPlacement.values.firstWhere(    // ← NEW
        (e) => e.name == row.intentPlacement,                // ← NEW
        orElse: () => IntentPlacement.beforeShuffle,         // ← NEW
      ),                                                     // ← NEW
      updatedAt: row.updatedAt,
    );
  }
}
```

### Considerations

- `orElse: () => IntentPlacement.beforeShuffle`: DB에 알 수 없는 값이 저장되어 있을 때
  안전한 기본값으로 fallback. 마이그레이션 데이터 오염 방어.
- `value.name` 변환: Dart enum의 `.name` property는 열거형 선언의 식별자 이름을 반환.
  `IntentPlacement.afterDraw.name == 'afterDraw'` — JSON 직렬화 키와 동일.

**Impact Analysis**:
- 이 변경 후 `UserSettingsRepositoryImpl`이 `UserSettingsRepository` 인터페이스를
  완전히 구현하므로 컴파일 통과.
- `_toDomain` 에 `intentPlacement` 추가로 `UserSettings(updatedAt: ...)` 호출 시
  build_runner 재생성된 freezed 생성자와 일치.

---

## Step 8 — 코드 생성 실행

### Approach

Steps 2-7 완료 후 build_runner를 실행해 freezed/json_serializable/Drift 코드를 재생성.

```bash
cd /Users/kampikrein/A/personality/mobile
dart run build_runner build --delete-conflicting-outputs
```

**실행 시점**: 모든 소스 파일 변경 완료 후 단 1회 실행.

**예상 재생성 파일**:
- `user_settings.freezed.dart`
- `user_settings.g.dart`
- `app_database.g.dart`
- `user_settings_dao.g.dart`

### Considerations

- `--delete-conflicting-outputs`: 기존 생성 파일과 충돌 시 삭제 후 재생성.
  이전 cycle에서 동일 플래그를 사용하여 안전이 검증됨.
- 생성 중 오류 발생 시 먼저 `dart run build_runner clean` 실행 후 재시도.

---

## Step 9 — 테스트 검증

### Approach

```bash
cd /Users/kampikrein/A/personality/mobile
flutter test test/features/settings/intent_placement_test.dart
```

**기대 결과**: `+13: All tests passed!`

**T-별 검증 포인트**:
- T1 (enum 3값): Step 1 완료로 해결
- T2 (기본값): Step 2 `@Default(IntentPlacement.beforeShuffle)` + Step 8 재생성으로 해결
- T3 (JSON round-trip): Step 2 + Step 8 (`user_settings.g.dart` 재생성)으로 해결
- T4 (updateIntentPlacement DB 업데이트): Step 5, 7로 해결
- T5 (intent_placement 컬럼 존재): Step 3, 4로 해결

---

## Considerations & Trade-offs

### Structural Decisions Log

Brief 040에서 모든 아키텍처 결정 완료. 이 플랜에서 추가 결정 없음.

| # | 결정 | 선택 | 근거 |
|---|------|------|------|
| 1 | JSON 직렬화 방식 | `@JsonEnum()` (이름 기반) | Freezed + json_serializable 자동 처리. LayoutType 기존 패턴 일치. |
| 2 | Dao 파라미터 타입 | `String` (enum.name) | Dao는 도메인 enum을 몰라야 함 (레이어 분리). |
| 3 | updateIntentPlacement에서 _ensureDefaultRow 호출 | 필요 | 테스트에서 getSettings 없이 바로 update를 호출할 수 있음 |

### Alternative Approaches

| 대안 | 기각 이유 |
|------|---------|
| `IntentPlacement`에 label 필드 추가 (CardSizePreset 방식) | Cycle 2 UI에서 switch로 처리 가능. 불필요한 복잡도. |
| `JsonConverter` 수동 작성 | `@JsonEnum()`으로 자동 처리 가능. 보일러플레이트 증가. |
| `updateSettings(companion)` 범용 사용 (특화 메서드 없음) | Repository 인터페이스가 enum 타입을 노출해야 하는 요건 충족 불가. |

### Potential Risks

| 위험 | 완화 |
|------|------|
| build_runner 재생성 실패 (의존성 버전 충돌) | `dart run build_runner clean` 후 재시도. Cycle 3 마이그레이션 시 동일 패턴 성공 이력 있음. |
| Drift Companion에 `intentPlacement` 필드가 없는 상태에서 Step 5 컴파일 시도 | Steps를 순서대로 실행 후 단 1회 build_runner 실행. 중간 컴파일 시도 금지. |
| `_ensureDefaultRow` 누락으로 T4 0-row UPDATE 발생 | Step 5에서 `_ensureDefaultRow()` 선행 호출로 해결. |

### Backward Compatibility

- 기존 사용자(schemaVersion 8): `from < 9` 마이그레이션으로 `intent_placement = 'beforeShuffle'` 자동 추가 → 기존 플로우 동일.
- `UserSettings.intentPlacement` 기본값 `beforeShuffle` → 기존 캐시/직렬화 데이터에 필드 없어도 안전 fallback.

---

## Implementation Checklist

- [ ] Step 1: `intent_placement.dart` 신규 생성 (`@JsonEnum` enum 3값)
- [ ] Step 2: `user_settings.dart` — `intentPlacement` 필드 + import 추가
- [ ] Step 3: `user_settings_table.dart` — `intentPlacement` TextColumn 추가
- [ ] Step 4: `app_database.dart` — schemaVersion 9, `from < 9` 마이그레이션 블록
- [ ] Step 5: `user_settings_dao.dart` — `updateIntentPlacement(String)` 추가 (_ensureDefaultRow 포함)
- [ ] Step 6: `user_settings_repository.dart` — `updateIntentPlacement(IntentPlacement)` 추상 메서드 + import
- [ ] Step 7: `user_settings_repository_impl.dart` — 구현 + `_toDomain` 매핑 + import
- [ ] Step 8: `dart run build_runner build --delete-conflicting-outputs`
- [ ] Step 9: `flutter test test/features/settings/intent_placement_test.dart` → +13: All tests passed!

---

## Verification Assertions

| Level | Assertion | 검증 방법 | 기대 결과 |
|-------|-----------|---------|--------|
| L1-Build | Dart 컴파일 통과 | `flutter test` (컴파일 포함) | 컴파일 에러 0 |
| L2-CLI | 13개 테스트 전부 Green | `cd mobile && flutter test test/features/settings/intent_placement_test.dart` | `+13: All tests passed!` |
| L2-CLI | DB 컬럼 존재 (T5) | 테스트 내 `PRAGMA table_info(user_settings)` | `intent_placement` 포함 |
| L2-CLI | JSON round-trip (T3) | 테스트 내 `toJson → fromJson` | `intentPlacement` 키 보존 |
| L4-Trace | Brief MA-1~MA-4 충족 | 테스트 Green + 코드 리뷰 | 모든 Model Anchor 이행 |

---

## References

| Resource | Path | 관련 내용 |
|----------|------|---------|
| Brief | `docs/2_tarot_draw/03_draw_experience_settings/040_Brief_intent_placement_setting.md` | Model Anchors, Decisions |
| Scope | `docs/2_tarot_draw/03_draw_experience_settings/041_Scope_intent_placement_setting.md` | Cycle 1 영역 정의 |
| TDD Red | `docs/2_tarot_draw/03_draw_experience_settings/042_TDD_Red_cycle1_data_layer.md` | Red 원인 + Green 전환 조건 |
| 기존 마이그레이션 | `mobile/lib/core/database/app_database.dart` | v8 마이그레이션 패턴 |
| Enum 패턴 참조 | `mobile/lib/features/settings/domain/entities/card_size_preset.dart` | enum 구조 |
| LayoutType 패턴 | `mobile/lib/features/reading/domain/entities/layout_type.dart` | `_toDomain` firstWhere 패턴 |

---

## 미비점 및 확장 필요 영역

### Plan 미비점 (makeplan 기록)

| # | 항목 | 심각도 | 설명 |
|---|------|--------|------|
| 1 | `cardsPerRow` 누락 in `_toDomain` | Low | 현재 `user_settings_repository_impl.dart`의 `_toDomain`에 `cardsPerRow` 필드가 없음. 기존 버그이므로 Cycle 1 범위 밖이지만 impl 시 주목 필요. |

### Implementation 미비점 (implementation 기록)

| # | 항목 | 심각도 | 설명 |
|---|------|--------|------|

### Verification 미비점 (verify 기록)

| # | 항목 | 심각도 | 설명 |
|---|------|--------|------|
