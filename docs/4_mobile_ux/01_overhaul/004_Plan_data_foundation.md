---
id: "004"
type: plan
title: "Cycle 1 데이터 기반 — 구현 계획"
created: 2026-03-22
traces_scope: "002"
traces_research: "003"
cycle: 1
area: "데이터 기반 (Data Foundation)"
status: complete
summary: >
  UserSettings Drift 테이블 + DAO + migration v2, SpreadType custom variant 추가,
  DeckMetadata supportedDrawModes 확장, UserSettings Freezed 엔티티 + repository + Riverpod providers.
  4단계, 9개 파일(신규 7 + 수정 2), 코드 생성 재실행 포함.
keywords: [user-settings, drift-migration, spread-type, deck-metadata, riverpod, freezed]
---

# Cycle 1 데이터 기반 — 구현 계획

## 실행 개요

| 항목 | 값 |
|------|---|
| 사이클 | 1 / 3 |
| 영역 | 데이터 기반 (Data Foundation) |
| Brief 앵커 | MA-3 (카드 수 & 스프레드 확장), MA-4 (UserSettings 테이블) |
| 신규 파일 | 7개 |
| 수정 파일 | 2개 |
| 코드 생성 | `build_runner build` 필수 (Drift, Freezed, Riverpod codegen) |

## Step 1: UserSettings Drift 테이블 + DAO + Migration v2

### 1-1. UserSettings 테이블 정의

**신규 파일**: `mobile/lib/core/database/tables/user_settings_table.dart`

```dart
import 'package:drift/drift.dart';

class UserSettingsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get selectedDeckId =>
      text().withDefault(const Constant('rws-standard'))();
  IntColumn get experienceLevel =>
      integer().withDefault(const Constant(1))();
  IntColumn get defaultCardCount =>
      integer().withDefault(const Constant(3))();
  BoolColumn get showFaceUp =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get quickDrawEnabled =>
      boolean().withDefault(const Constant(false))();
  TextColumn get defaultSpreadType =>
      text().withDefault(const Constant('threeCard'))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  String get tableName => 'user_settings';
}
```

**MA-4 매핑:**
- `selectedDeckId` → 기본 `'rws-standard'` (현재 앱의 기본 덱)
- `experienceLevel` → 기본 `1` (Level 1 즉시 결과)
- `defaultCardCount` → 기본 `3` (기존 threeCard 호환)
- `showFaceUp` → 기본 `false` (뒷면부터)
- `quickDrawEnabled` → 기본 `false` (첫 사용자는 메인 메뉴 허브)
- `defaultSpreadType` → 기본 `'threeCard'` (기존 동작 호환)
- `updatedAt` → 매 수정 시 갱신

**테이블명 주의**: 클래스명을 `UserSettingsTable`로 지정하여 Drift 생성 코드에서 `UserSettingsTableData` 형태가 되는 것을 방지. `tableName` getter로 `'user_settings'`를 명시.

### 1-2. UserSettings DAO

**신규 파일**: `mobile/lib/core/database/daos/user_settings_dao.dart`

```dart
import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/user_settings_table.dart';

part 'user_settings_dao.g.dart';

@DriftAccessor(tables: [UserSettingsTable])
class UserSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$UserSettingsDaoMixin {
  UserSettingsDao(super.db);

  /// 설정을 Stream으로 제공. 단일 행(id=1) 패턴.
  /// 행이 없으면 기본값으로 INSERT 후 반환.
  Stream<UserSettingsTableData> watchSettings() {
    return (select(userSettingsTable)
          ..where((s) => s.id.equals(1)))
        .watchSingleOrNull()
        .asyncMap((row) async {
      if (row != null) return row;
      await _ensureDefaultRow();
      return await (select(userSettingsTable)
            ..where((s) => s.id.equals(1)))
          .getSingle();
    });
  }

  /// 동기 조회용. 캐시 초기화에 사용.
  Future<UserSettingsTableData> getSettings() async {
    final row = await (select(userSettingsTable)
          ..where((s) => s.id.equals(1)))
        .getSingleOrNull();
    if (row != null) return row;
    await _ensureDefaultRow();
    return (select(userSettingsTable)
          ..where((s) => s.id.equals(1)))
        .getSingle();
  }

  /// 설정 업데이트. 단일 행(id=1)만 대상.
  Future<void> updateSettings(UserSettingsTableCompanion companion) async {
    await (update(userSettingsTable)
          ..where((s) => s.id.equals(1)))
        .write(companion.copyWith(
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> _ensureDefaultRow() async {
    final exists = await (select(userSettingsTable)
          ..where((s) => s.id.equals(1)))
        .getSingleOrNull();
    if (exists != null) return;
    await into(userSettingsTable).insert(
      UserSettingsTableCompanion.insert(updatedAt: DateTime.now()),
    );
  }
}
```

**패턴 근거:**
- 기존 `ReadingDao`, `DeckDao`와 동일한 `@DriftAccessor` + `part` 패턴
- `watchSettings()` — Stream 기반 reactive (Riverpod provider에서 사용)
- `getSettings()` — 동기 조회 (GoRouter redirect 캐시 초기화용)
- `_ensureDefaultRow()` — 첫 실행 시 기본값 자동 생성 (단일 행 패턴의 핵심)

### 1-3. AppDatabase 수정 (Migration v2)

**수정 파일**: `mobile/lib/core/database/app_database.dart`

변경 내용:
1. `tables` 리스트에 `UserSettingsTable` 추가
2. `daos` 리스트에 `UserSettingsDao` 추가
3. `schemaVersion` → `2`
4. `MigrationStrategy`에 `onUpgrade` 추가

```dart
import 'package:drift/drift.dart';

import '../../features/deck/domain/entities/card_meanings.dart';
import 'converters/card_meanings_converter.dart';
import 'tables/decks_table.dart';
import 'tables/cards_table.dart';
import 'tables/readings_table.dart';
import 'tables/drawn_cards_table.dart';
import 'tables/user_settings_table.dart';  // 추가
import 'daos/deck_dao.dart';
import 'daos/card_dao.dart';
import 'daos/reading_dao.dart';
import 'daos/user_settings_dao.dart';  // 추가

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Decks, Cards, Readings, DrawnCards, UserSettingsTable],  // 추가
  daos: [DeckDao, CardDao, ReadingDao, UserSettingsDao],  // 추가
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;  // 1 → 2

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) => m.createAll(),
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(userSettingsTable);
          }
        },
      );
}
```

**Research Q2 반영:**
- `onUpgrade`의 `from < 2` 조건문으로 v1→v2 마이그레이션
- `m.createTable(userSettingsTable)` — 기존 4개 테이블에 영향 없음
- Drift의 `createTable`은 테이블 선언의 `@DriftDatabase(tables: [...])`에 등록된 참조를 사용

## Step 2: SpreadType 확장 — custom variant 추가

**수정 파일**: `mobile/lib/features/reading/domain/entities/spread_type.dart`

**Research Q3 결론 반영**: enum 유지 + `custom` variant 추가 (Option C)

```dart
enum SpreadType {
  single(
    displayName: '한 장 뽑기',
    cardCount: 1,
    positions: ['현재'],
    guidances: ['지금 이 순간 당신에게 가장 필요한 메시지입니다.'],
  ),
  threeCard(
    displayName: '쓰리 카드',
    cardCount: 3,
    positions: ['지나온 길', '현재', '가능성'],
    guidances: [
      '지금까지 당신에게 영향을 준 에너지입니다.',
      '현재 당신을 둘러싼 흐름입니다.',
      '이 방향으로 에너지가 흐르고 있습니다. 가능성이지 운명이 아닙니다.',
    ],
  ),
  custom(
    displayName: '자유 선택',
    cardCount: 0,
    positions: [],
    guidances: [],
  );

  const SpreadType({
    required this.displayName,
    required this.cardCount,
    required this.positions,
    required this.guidances,
  });

  final String displayName;
  final int cardCount;
  final List<String> positions;
  final List<String> guidances;

  /// custom 스프레드에서 동적 positions 생성.
  /// named 스프레드(single, threeCard)는 정적 positions 반환.
  List<String> resolvePositions(int actualCardCount) {
    if (this != SpreadType.custom) return positions;
    return List.generate(actualCardCount, (i) => '카드 ${i + 1}');
  }

  /// custom 스프레드에서 동적 guidances 생성.
  List<String> resolveGuidances(int actualCardCount) {
    if (this != SpreadType.custom) return guidances;
    return List.generate(
      actualCardCount,
      (i) => '${i + 1}번째 카드가 전하는 메시지입니다.',
    );
  }
}
```

**설계 판단:**

1. **`cardCount: 0`은 sentinel 값**: custom의 실제 카드 수는 `DrawnCards` 행 수(DB 복원 시) 또는 `UserSettings.defaultCardCount`(뽑기 시)로 결정됨.

2. **`resolvePositions()` / `resolveGuidances()` 추가**: `custom`일 때 `positions[i]` 접근 시 IndexError를 방지하는 안전 장치. Research에서 식별한 리스크(positions/guidances 빈 리스트 → IndexError) 해결.

3. **DB 호환성**: `SpreadType.values.byName('custom')` 정상 동작 → `reading_repository_impl.dart`의 `SpreadType.values.byName(row.spreadType)` 변경 불필요.

4. **exhaustive switch**: `SpreadLayout`의 `switch (spreadType)` 구문에 `SpreadType.custom` 분기를 추가해야 컴파일 통과 → 아래 Step 2-1에서 처리.

### Step 2-1: SpreadLayout에 custom 분기 추가

**수정 파일**: `mobile/lib/features/reading/presentation/widgets/spread_layout.dart`

`build()` 메서드의 switch에 `SpreadType.custom` 케이스 추가:

```dart
@override
Widget build(BuildContext context) {
  return switch (spreadType) {
    SpreadType.single => _buildSingleLayout(),
    SpreadType.threeCard => _buildThreeCardLayout(),
    SpreadType.custom => _buildGenericGridLayout(),
  };
}

Widget _buildGenericGridLayout() {
  if (cards.length == 1) return _buildSingleLayout();

  return LayoutBuilder(
    builder: (context, constraints) {
      // 3장 이하: 가로 나열, 4장 이상: 2열 그리드
      final crossAxisCount = cards.length <= 3 ? cards.length : 2;

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.65,
        ),
        itemCount: cards.length,
        itemBuilder: (context, i) {
          return CardRevealWidget(
            card: cards[i],
            deckId: deckId,
            position: i,
            label: spreadType.resolvePositions(cards.length)[i],
            isRevealed: revealedPositions.contains(i),
            onTap: () => onCardTap(i),
          );
        },
      );
    },
  );
}
```

**주의**: 이 변경을 하지 않으면 `SpreadType.custom` 추가 시 Dart analyzer가 exhaustive switch 오류를 발생시켜 **빌드 실패**. 따라서 Step 2와 Step 2-1은 반드시 함께 실행.

### Step 2-2: ReadingPage positions/guidances 접근 수정

**수정 파일**: `mobile/lib/features/reading/presentation/pages/reading_page.dart`

`_spreadType.positions[i]` 및 `_spreadType.guidances[i]` 접근을 `resolvePositions()`/`resolveGuidances()`로 교체:

```dart
// 기존 (133행 부근):
// '${_spreadType.positions[i]}: ${drawnCards[i].card.name}',
// _spreadType.guidances[i],

// 변경:
final resolvedPositions = _spreadType.resolvePositions(drawnCards.length);
final resolvedGuidances = _spreadType.resolveGuidances(drawnCards.length);

// ... 루프 내에서:
// '${resolvedPositions[i]}: ${drawnCards[i].card.name}',
// resolvedGuidances[i],
```

이 변경은 `single`/`threeCard`에서는 기존 동작과 동일 (정적 리스트 그대로 반환). `custom`에서만 동적 생성.

## Step 3: DeckMetadata 확장 — supportedDrawModes

**수정 파일**: `mobile/lib/features/deck/domain/entities/deck_metadata.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'deck_metadata.freezed.dart';
part 'deck_metadata.g.dart';

/// 덱이 지원하는 뽑기 방식.
/// - freeform: 1~10장 자유 선택 (타로 기본)
/// - namedSpread: 전통 스프레드 유형 선택 (켈틱 크로스 등)
/// - hexagram: I Ching 6효 뽑기
enum DrawMode { freeform, namedSpread, hexagram }

@freezed
class DeckMetadata with _$DeckMetadata {
  const factory DeckMetadata({
    required String id,
    required String name,
    @Default(true) bool isStandardTarot,
    required int totalCards,
    String? creator,
    @Default([DrawMode.freeform, DrawMode.namedSpread])
    List<DrawMode> supportedDrawModes,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _DeckMetadata;

  factory DeckMetadata.fromJson(Map<String, dynamic> json) =>
      _$DeckMetadataFromJson(json);
}
```

**MA-3 매핑:**
- 타로 덱 기본: `[DrawMode.freeform, DrawMode.namedSpread]`
- I Ching 덱: `[DrawMode.hexagram]` (덱 초기화 시 명시적 지정)
- `DrawMode` enum을 같은 파일에 선언 — 현재 단계에서는 구조 준비만, 실제 hexagram 로직은 Out of Scope

**DeckRepositoryImpl 영향:**
- `_toDeckMetadata()` 매퍼에 `supportedDrawModes` 필드 추가 불필요 — DB의 `Decks` 테이블에 이 컬럼이 없으므로, DeckMetadata의 `@Default` 값이 사용됨.
- 향후 DB에 `supportedDrawModes` 컬럼을 추가하려면 별도 마이그레이션이 필요하나, **현 사이클에서는 Freezed 엔티티 레벨의 확장만** 수행. Decks 테이블 스키마는 건드리지 않음.
- **I Ching 덱 구분**: `isStandardTarot == false`인 덱은 DeckRepositoryImpl에서 매핑 시 `supportedDrawModes: [DrawMode.hexagram]`을 명시적으로 할당하는 로직을 `_toDeckMetadata()`에 추가.

```dart
DeckMetadata _toDeckMetadata(Deck row) => DeckMetadata(
      id: row.id,
      name: row.name,
      isStandardTarot: row.isStandardTarot,
      totalCards: row.totalCards,
      creator: row.creator,
      supportedDrawModes: row.isStandardTarot
          ? [DrawMode.freeform, DrawMode.namedSpread]
          : [DrawMode.hexagram],
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
```

## Step 4: UserSettings Freezed 엔티티 + Repository + Riverpod Providers

### 4-1. UserSettings 도메인 엔티티 (Freezed)

**신규 파일**: `mobile/lib/features/settings/domain/entities/user_settings.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../reading/domain/entities/spread_type.dart';

part 'user_settings.freezed.dart';
part 'user_settings.g.dart';

@freezed
class UserSettings with _$UserSettings {
  const factory UserSettings({
    @Default('rws-standard') String selectedDeckId,
    @Default(1) int experienceLevel,
    @Default(3) int defaultCardCount,
    @Default(false) bool showFaceUp,
    @Default(false) bool quickDrawEnabled,
    @Default(SpreadType.threeCard) SpreadType defaultSpreadType,
    required DateTime updatedAt,
  }) = _UserSettings;

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
}
```

**MA-4 매핑 대조:**
- Brief 명시 필드 8개 중 `id`는 DB 내부용이므로 도메인 엔티티에서 제외
- `defaultSpreadType`은 DB에서는 `TextColumn`(`'threeCard'`)으로 저장, 엔티티에서는 `SpreadType` enum으로 변환

### 4-2. UserSettings Repository 인터페이스

**신규 파일**: `mobile/lib/features/settings/domain/repositories/user_settings_repository.dart`

```dart
import '../entities/user_settings.dart';

abstract class UserSettingsRepository {
  Stream<UserSettings> watchSettings();
  Future<UserSettings> getSettings();
  Future<void> updateSelectedDeckId(String deckId);
  Future<void> updateExperienceLevel(int level);
  Future<void> updateDefaultCardCount(int count);
  Future<void> updateShowFaceUp(bool showFaceUp);
  Future<void> updateQuickDrawEnabled(bool enabled);
  Future<void> updateDefaultSpreadType(String spreadTypeName);
}
```

**설계 판단**: 개별 필드 업데이트 메서드를 분리. 설정 페이지(Cycle 2)에서 토글/드롭다운 하나를 변경할 때 전체 객체를 재구성할 필요 없이 해당 필드만 업데이트.

### 4-3. UserSettings Repository 구현

**신규 파일**: `mobile/lib/features/settings/data/repositories/user_settings_repository_impl.dart`

```dart
import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../reading/domain/entities/spread_type.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/user_settings_repository.dart';

class UserSettingsRepositoryImpl implements UserSettingsRepository {
  UserSettingsRepositoryImpl({required this.db});

  final AppDatabase db;

  @override
  Stream<UserSettings> watchSettings() {
    return db.userSettingsDao.watchSettings().map(_toDomain);
  }

  @override
  Future<UserSettings> getSettings() async {
    final row = await db.userSettingsDao.getSettings();
    return _toDomain(row);
  }

  @override
  Future<void> updateSelectedDeckId(String deckId) async {
    await db.userSettingsDao.updateSettings(
      UserSettingsTableCompanion(selectedDeckId: Value(deckId)),
    );
  }

  @override
  Future<void> updateExperienceLevel(int level) async {
    await db.userSettingsDao.updateSettings(
      UserSettingsTableCompanion(experienceLevel: Value(level)),
    );
  }

  @override
  Future<void> updateDefaultCardCount(int count) async {
    await db.userSettingsDao.updateSettings(
      UserSettingsTableCompanion(defaultCardCount: Value(count)),
    );
  }

  @override
  Future<void> updateShowFaceUp(bool showFaceUp) async {
    await db.userSettingsDao.updateSettings(
      UserSettingsTableCompanion(showFaceUp: Value(showFaceUp)),
    );
  }

  @override
  Future<void> updateQuickDrawEnabled(bool enabled) async {
    await db.userSettingsDao.updateSettings(
      UserSettingsTableCompanion(quickDrawEnabled: Value(enabled)),
    );
  }

  @override
  Future<void> updateDefaultSpreadType(String spreadTypeName) async {
    await db.userSettingsDao.updateSettings(
      UserSettingsTableCompanion(defaultSpreadType: Value(spreadTypeName)),
    );
  }

  UserSettings _toDomain(UserSettingsTableData row) {
    return UserSettings(
      selectedDeckId: row.selectedDeckId,
      experienceLevel: row.experienceLevel,
      defaultCardCount: row.defaultCardCount,
      showFaceUp: row.showFaceUp,
      quickDrawEnabled: row.quickDrawEnabled,
      defaultSpreadType: SpreadType.values.byName(row.defaultSpreadType),
      updatedAt: row.updatedAt,
    );
  }
}
```

**패턴 근거**: `ReadingRepositoryImpl`과 동일한 `db` 주입 + `_toDomain()` 매퍼 패턴.

### 4-4. Riverpod Providers

**신규 파일**: `mobile/lib/features/settings/presentation/providers/settings_providers.dart`

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/repositories/user_settings_repository_impl.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/user_settings_repository.dart';

part 'settings_providers.g.dart';

@Riverpod(keepAlive: true)
UserSettingsRepository userSettingsRepository(UserSettingsRepositoryRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return UserSettingsRepositoryImpl(db: db);
}

@riverpod
Stream<UserSettings> userSettings(UserSettingsRef ref) {
  final repo = ref.watch(userSettingsRepositoryProvider);
  return repo.watchSettings();
}
```

**설계 판단:**
- `userSettingsRepositoryProvider` — `keepAlive: true` (앱 생존 기간 동안 유지)
- `userSettingsProvider` — Stream 기반 reactive. `ref.watch(userSettingsProvider).valueOrNull`로 동기 캐시 접근 가능 (Research Q4 결론 — GoRouter redirect에서 사용 예정, Cycle 3).
- `readingRepositoryProvider`와 동일한 패턴 (`@Riverpod(keepAlive: true)` + `@riverpod Stream<>`)

## Step 5: 코드 생성 재실행

```bash
cd mobile && dart run build_runner build --delete-conflicting-outputs
```

영향 받는 생성 파일:
- `app_database.g.dart` — UserSettingsTable + UserSettingsDao 등록
- `user_settings_dao.g.dart` — DAO mixin 생성
- `deck_metadata.freezed.dart` / `deck_metadata.g.dart` — DrawMode + supportedDrawModes
- `user_settings.freezed.dart` / `user_settings.g.dart` — UserSettings Freezed
- `settings_providers.g.dart` — Riverpod codegen
- `reading.g.dart` — SpreadType enum map에 `custom` 추가
- `spread_type` 관련 generated 코드는 없음 (plain enum, no codegen)

## 파일 변경 요약

| # | 파일 경로 | 작업 | Step |
|---|----------|------|------|
| 1 | `mobile/lib/core/database/tables/user_settings_table.dart` | **NEW** | 1-1 |
| 2 | `mobile/lib/core/database/daos/user_settings_dao.dart` | **NEW** | 1-2 |
| 3 | `mobile/lib/core/database/app_database.dart` | **MODIFY** — table/DAO 등록, schemaVersion 2, onUpgrade | 1-3 |
| 4 | `mobile/lib/features/reading/domain/entities/spread_type.dart` | **MODIFY** — custom variant + resolvePositions/Guidances | 2 |
| 5 | `mobile/lib/features/reading/presentation/widgets/spread_layout.dart` | **MODIFY** — custom 분기 + generic grid | 2-1 |
| 6 | `mobile/lib/features/reading/presentation/pages/reading_page.dart` | **MODIFY** — resolvePositions/Guidances 호출 | 2-2 |
| 7 | `mobile/lib/features/deck/domain/entities/deck_metadata.dart` | **MODIFY** — DrawMode enum + supportedDrawModes 필드 | 3 |
| 8 | `mobile/lib/features/deck/data/repositories/deck_repository_impl.dart` | **MODIFY** — _toDeckMetadata에 supportedDrawModes 매핑 | 3 |
| 9 | `mobile/lib/features/settings/domain/entities/user_settings.dart` | **NEW** | 4-1 |
| 10 | `mobile/lib/features/settings/domain/repositories/user_settings_repository.dart` | **NEW** | 4-2 |
| 11 | `mobile/lib/features/settings/data/repositories/user_settings_repository_impl.dart` | **NEW** | 4-3 |
| 12 | `mobile/lib/features/settings/presentation/providers/settings_providers.dart` | **NEW** | 4-4 |

## 실행 순서 체크리스트

구현 에이전트가 아래 순서대로 실행한다. 각 항목은 이전 항목의 완료를 전제로 한다.

- [ ] **1-1**: `user_settings_table.dart` 생성
- [ ] **1-2**: `user_settings_dao.dart` 생성
- [ ] **1-3**: `app_database.dart` 수정 (table + DAO + schemaVersion 2 + onUpgrade)
- [ ] **2**: `spread_type.dart` 수정 (custom variant + resolve 메서드)
- [ ] **2-1**: `spread_layout.dart` 수정 (custom 분기 + generic grid) — Step 2와 반드시 함께
- [ ] **2-2**: `reading_page.dart` 수정 (resolvePositions/Guidances)
- [ ] **3**: `deck_metadata.dart` 수정 (DrawMode enum + supportedDrawModes)
- [ ] **3+**: `deck_repository_impl.dart` 수정 (supportedDrawModes 매핑)
- [ ] **4-1**: `user_settings.dart` 생성 (Freezed 엔티티)
- [ ] **4-2**: `user_settings_repository.dart` 생성 (인터페이스)
- [ ] **4-3**: `user_settings_repository_impl.dart` 생성 (구현)
- [ ] **4-4**: `settings_providers.dart` 생성 (Riverpod providers)
- [ ] **5**: `dart run build_runner build --delete-conflicting-outputs`
- [ ] **6**: 빌드 검증 (`flutter analyze` + `flutter build apk --debug` 또는 핫 리로드)

## 검증 기준

| # | 기준 | 검증 방법 |
|---|------|----------|
| 1 | DB 마이그레이션 v1→v2 성공 | 기존 앱 데이터가 보존되고 user_settings 테이블이 생성됨 |
| 2 | UserSettings 기본 행 자동 생성 | 앱 첫 실행 시 id=1 행이 기본값으로 INSERT |
| 3 | SpreadType.custom exhaustive switch 통과 | `flutter analyze` 에러 없음 |
| 4 | SpreadType.values.byName('custom') 정상 | DB에서 'custom' 문자열로 SpreadType 복원 가능 |
| 5 | DeckMetadata.supportedDrawModes 접근 가능 | 타로 덱 → [freeform, namedSpread], I Ching 덱 → [hexagram] |
| 6 | userSettingsProvider Stream 동작 | provider watch 시 UserSettings 엔티티 수신 |
| 7 | 코드 생성 성공 | `build_runner build` 에러 없음 |
| 8 | 기존 테스트 통과 | 기존 reading/deck 관련 테스트가 깨지지 않음 |

## Cycle 2 인계 사항

이 사이클에서 생성한 산출물 중 Cycle 2(설정 + 리딩 기능)가 직접 사용할 항목:

1. **`userSettingsProvider`** — 설정 페이지에서 watch/update
2. **`userSettingsRepositoryProvider`** — 설정 변경 시 개별 update 메서드 호출
3. **`SpreadType.custom` + `resolvePositions/Guidances`** — 리딩 목록 필터, "+1" 뽑기 시 동적 positions
4. **`DrawMode` enum** — 덱 선택 UI에서 지원 뽑기 방식 표시
5. **`UserSettings.defaultCardCount`** — 즉시 뽑기 시 카드 수 결정
6. **`ShuffleResult.cards[currentCount]`** — "+1" 기능에서 다음 카드 접근 (Research Q1 확인 완료, 구현은 Cycle 2)

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 0s | 0 |
| 2 | user-ai-exchange | 19s | 76045 |
| 3 | user-ai-exchange | 11s | 40778 |
| 4 | user-ai-exchange | 10s | 42195 |
| 5 | user-ai-exchange | 9s | 44183 |
| 6 | user-ai-exchange | 14s | 46529 |
| 7 | user-ai-exchange | 5s | 48356 |
| 8 | user-ai-exchange | 9s | 50568 |
| 9 | user-ai-exchange | 13s | 105037 |
| 10 | user-ai-exchange | 12s | 54453 |
| 11 | user-ai-exchange | 11s | 55874 |
| 12 | user-ai-exchange | 12s | 57359 |
| 13 | user-ai-exchange | 14s | 58996 |
| 14 | user-ai-exchange | 13s | 60582 |
| 15 | user-ai-exchange | 8s | 61831 |
| 16 | user-ai-exchange | 11s | 63033 |
| 17 | user-ai-exchange | 29s | 202688 |
| 18 | user-ai-exchange | 11s | 140060 |
| 19 | user-ai-exchange | 11s | 71985 |
| 20 | user-ai-exchange | 9s | 147944 |
| 21 | user-ai-exchange | 14s | 76148 |
| 22 | user-ai-exchange | 19s | 0 |
| 23 | user-ai-exchange | 10s | 41780 |
| 24 | user-ai-exchange | 13s | 45110 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 341150s |
| Total Tokens | 1591534 |
| Input Tokens | 71 |
| Output Tokens | 8834 |
| Cache Read | 1202235 |
| Cache Creation | 380394 |
