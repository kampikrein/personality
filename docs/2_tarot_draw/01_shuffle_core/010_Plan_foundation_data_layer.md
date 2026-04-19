---
id: "010"
type: plan
title: "Phase 1 — 프로젝트 기반 + 데이터 계층"
created: 2026-03-15
phase: 1
parent: "009"
depends_on: []
parallel_with: []
traces_scope: "001"
traces_research: "008"
summary: >
  Flutter 프로젝트 초기화, 전체 의존성 설정, Drift DB 스키마(덱/카드/리딩/드로운카드),
  freezed 도메인 모델, RWS 78장 시드 데이터, ProviderScope 부트스트랩.
keywords: [flutter-init, drift, freezed, rws-seed, database, foundation]
---

# 010 — Phase 1: 프로젝트 기반 + 데이터 계층

## Goal

빈 Flutter 스켈레톤을 완전한 프로젝트로 초기화하고, 앱의 데이터 기반을 구축한다. Drift DB 스키마, freezed 도메인 모델, RWS 78장 시드 데이터를 설정하여 Phase 2(셔플 엔진)와 Phase 3(UI)의 토대를 마련한다.

## Scope

### Included
| # | Item | Description |
|---|------|-------------|
| 1 | Flutter 프로젝트 초기화 | Android/iOS 플랫폼 파일 생성 (flutter create) |
| 2 | pubspec.yaml | 전체 의존성 추가 |
| 3 | analysis_options.yaml | Lint + 코드 생성 파일 제외 |
| 4 | Failure sealed class | 앱 전역 에러 타입 |
| 5 | AppTheme | 미스틱 다크 테마 |
| 6 | Drift 테이블 | Decks, Cards, Readings, DrawnCards |
| 7 | Drift TypeConverter | CardMeanings JSON 변환 |
| 8 | Drift AppDatabase + setup | DB 초기화, WAL, FK |
| 9 | Drift DAOs | DeckDao, CardDao, ReadingDao |
| 10 | freezed 엔티티 | DeckMetadata, TarotCard, CardMeanings, Reading, SpreadType |
| 11 | RWS 시드 데이터 | 78장 카드 메타데이터 JSON |
| 12 | main.dart 부트스트랩 | ProviderScope + DB 초기화 |

### Excluded
| Item | Reason/Timeline |
|------|-----------------|
| Repository 인터페이스/구현 | Phase 2 |
| 센서/셔플 로직 | Phase 2 |
| UI 페이지/라우팅 | Phase 3 |

## Structural Decisions

> No additional structural decisions required — all resolved in checkpoint (009).

---

## File Change Summary

### Modified Files
| # | File Path | Change Description |
|---|-----------|-------------------|
| 1 | mobile/pubspec.yaml | 전체 의존성 추가 (Riverpod, Drift, sensors_plus 등) |
| 2 | mobile/lib/main.dart | ProviderScope 래핑, DB 초기화, 테마 적용 |

### New Files
| # | File Path | Description |
|---|-----------|-------------|
| 1 | mobile/analysis_options.yaml | Lint 규칙 + 생성 파일 제외 |
| 2 | mobile/lib/core/error/failures.dart | Failure sealed class |
| 3 | mobile/lib/core/theme/app_theme.dart | 미스틱 다크 테마 |
| 4 | mobile/lib/core/database/tables/decks_table.dart | Decks 테이블 |
| 5 | mobile/lib/core/database/tables/cards_table.dart | Cards 테이블 |
| 6 | mobile/lib/core/database/tables/readings_table.dart | Readings 테이블 |
| 7 | mobile/lib/core/database/tables/drawn_cards_table.dart | DrawnCards 테이블 |
| 8 | mobile/lib/core/database/converters/card_meanings_converter.dart | TypeConverter |
| 9 | mobile/lib/core/database/app_database.dart | Drift AppDatabase |
| 10 | mobile/lib/core/database/database_setup.dart | DB 초기화 헬퍼 |
| 11 | mobile/lib/core/database/daos/deck_dao.dart | Deck DAO |
| 12 | mobile/lib/core/database/daos/card_dao.dart | Card DAO |
| 13 | mobile/lib/core/database/daos/reading_dao.dart | Reading DAO |
| 14 | mobile/lib/features/deck/domain/entities/deck_metadata.dart | DeckMetadata freezed |
| 15 | mobile/lib/features/deck/domain/entities/tarot_card.dart | TarotCard freezed |
| 16 | mobile/lib/features/deck/domain/entities/card_meanings.dart | CardMeanings freezed |
| 17 | mobile/lib/features/reading/domain/entities/reading.dart | Reading freezed |
| 18 | mobile/lib/features/reading/domain/entities/spread_type.dart | SpreadType enum |
| 19 | mobile/assets/data/rws_deck.json | RWS 78장 시드 데이터 |

---

## Step 1 — Flutter 프로젝트 플랫폼 초기화

### Approach

현재 `mobile/`에 android/, ios/ 디렉토리가 없다. `flutter create`로 플랫폼 파일을 생성한다. 기존 `pubspec.yaml`과 `lib/main.dart`는 보존.

### Command
```bash
cd mobile && flutter create --org com.personality --project-name personality_mobile --platforms android,ios .
```

### Considerations
- `--platforms android,ios`로 웹은 제외 (Phase 4)
- `--org com.personality`로 패키지명 설정
- 기존 파일은 덮어쓰지 않음 (flutter create은 기존 파일 보존)
- 생성 후 `android/`, `ios/`, `test/` 디렉토리 확인

---

## Step 2 — pubspec.yaml 의존성 추가

### Approach
전체 MVP 의존성을 한 번에 추가. Phase 2/3에서 필요한 패키지도 미리 포함하여 반복 설치를 방지.

### Current Code
```yaml
# mobile/pubspec.yaml:1-20
name: personality_mobile
description: "Personality + Tarot mobile app"
version: 0.1.0

environment:
  sdk: ^3.0.0
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true
```

### After Code
```yaml
# mobile/pubspec.yaml
name: personality_mobile
description: "Personality + Tarot mobile app"
version: 0.1.0

environment:
  sdk: ^3.6.0
  flutter: ">=3.29.0"

dependencies:
  flutter:
    sdk: flutter

  # State Management + DI
  flutter_riverpod: ^2.6.0
  riverpod_annotation: ^2.6.0

  # Sensors & Entropy
  sensors_plus: ^5.0.0
  pointycastle: ^3.7.0
  crypto: ^3.0.0

  # Database
  drift: ^2.22.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0
  path: ^1.9.0

  # Serialization
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0

  # Routing
  go_router: ^14.6.0

  # Utilities
  uuid: ^4.5.0
  collection: ^1.18.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

  # Code Generation
  build_runner: ^2.4.0
  riverpod_generator: ^2.6.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  drift_dev: ^2.22.0

  # Testing
  mocktail: ^1.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/data/
```

### Considerations
- SDK 제약을 `^3.6.0` / `>=3.29.0`으로 상향 (Dart 3 sealed class, 최신 패키지 호환)
- `uuid`: 엔티티 ID 생성용
- `collection`: 리스트 유틸리티 (groupBy 등)
- `flutter_image_compress`는 커스텀 덱(Phase 2)에서 추가. MVP에서는 placeholder 이미지만 사용
- `assets/data/` 경로를 flutter assets에 등록

---

## Step 3 — analysis_options.yaml

### Approach
코드 생성 파일(`*.g.dart`, `*.freezed.dart`)을 분석에서 제외. 엄격한 타입 검사 활성화.

### After Code
```yaml
# mobile/analysis_options.yaml (new)
include: package:flutter_lints/flutter.yaml

analyzer:
  errors:
    missing_required_param: error
    missing_return: error
    todo: ignore
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true

linter:
  rules:
    - prefer_single_quotes
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - prefer_final_locals
    - avoid_print
    - unawaited_futures
    - sort_child_properties_last
    - use_key_in_widget_constructors
```

### Considerations
- 최소한의 lint 규칙만 추가. 과도한 규칙은 개발 속도 저하
- `strict-casts/inference/raw-types`: Dart 3의 타입 안전성 극대화

---

## Step 4 — Core: Failure sealed class

### Approach
Dart 3 sealed class로 앱 전역 에러 타입 정의. exhaustive pattern matching 활용.

### After Code
```dart
// mobile/lib/core/error/failures.dart (new)
sealed class Failure {
  const Failure(this.message);
  final String message;
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Database error occurred']);
}

class SensorFailure extends Failure {
  const SensorFailure([super.message = 'Sensor not available']);
}

class ShuffleFailure extends Failure {
  const ShuffleFailure([super.message = 'Shuffle failed']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation error']);
}
```

### Considerations
- sealed class → switch exhaustive check 보장
- 각 도메인(DB, 센서, 셔플, 검증)별 구체 타입
- message 필드로 디버깅 컨텍스트 제공

---

## Step 5 — Core: AppTheme (미스틱 다크 테마)

### Approach
타로 앱에 적합한 다크 테마. 딥 퍼플/골드 포인트 컬러. Material 3 기반.

### After Code
```dart
// mobile/lib/core/theme/app_theme.dart (new)
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const _deepPurple = Color(0xFF1A1028);
  static const _darkSurface = Color(0xFF0D0A14);
  static const _gold = Color(0xFFD4A84B);
  static const _softPurple = Color(0xFF6B5B95);
  static const _textPrimary = Color(0xFFE8E0F0);
  static const _textSecondary = Color(0xFF9B8FB8);

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _darkSurface,
        colorScheme: const ColorScheme.dark(
          primary: _gold,
          secondary: _softPurple,
          surface: _deepPurple,
          onPrimary: _darkSurface,
          onSecondary: _textPrimary,
          onSurface: _textPrimary,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: _gold,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(color: _textPrimary, fontSize: 16),
          bodyMedium: TextStyle(color: _textSecondary, fontSize: 14),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _darkSurface,
          foregroundColor: _textPrimary,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: _deepPurple,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _gold,
            foregroundColor: _darkSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
}
```

---

## Step 6 — Drift 테이블 정의

### Approach
4개 테이블: Decks, Cards, Readings, DrawnCards. Research(008-F5)에 따라 syncStatus, version 필드를 초기 스키마에 포함. 각 테이블을 별도 파일로 분리하여 가독성 확보.

### After Code — Decks
```dart
// mobile/lib/core/database/tables/decks_table.dart (new)
import 'package:drift/drift.dart';

enum SyncStatus { pending, synced, conflict }

class Decks extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  BoolColumn get isStandardTarot => boolean().withDefault(const Constant(true))();
  IntColumn get totalCards => integer()();
  TextColumn get creator => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus => intEnum<SyncStatus>().withDefault(Constant(SyncStatus.pending.index))();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
```

### After Code — Cards
```dart
// mobile/lib/core/database/tables/cards_table.dart (new)
import 'package:drift/drift.dart';
import 'decks_table.dart';

class Cards extends Table {
  TextColumn get id => text()();
  TextColumn get deckId => text().references(Decks, #id)();
  TextColumn get cardId => text()();
  TextColumn get name => text()();
  TextColumn get arcana => text()();          // major / minor
  TextColumn get suit => text().nullable()(); // wands, cups, swords, pentacles
  IntColumn get number => integer()();        // 0-21 (major) or 1-14 (minor)
  TextColumn get imagePath => text()();
  TextColumn get meanings => text().map(const CardMeaningsConverter())();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus => intEnum<SyncStatus>().withDefault(Constant(SyncStatus.pending.index))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {deckId, cardId},
  ];
}
```

### After Code — Readings
```dart
// mobile/lib/core/database/tables/readings_table.dart (new)
import 'package:drift/drift.dart';
import 'decks_table.dart';

class Readings extends Table {
  TextColumn get id => text()();
  TextColumn get deckId => text().references(Decks, #id)();
  TextColumn get spreadType => text()();    // single, three_card
  TextColumn get question => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus => intEnum<SyncStatus>().withDefault(Constant(SyncStatus.pending.index))();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
```

### After Code — DrawnCards
```dart
// mobile/lib/core/database/tables/drawn_cards_table.dart (new)
import 'package:drift/drift.dart';
import 'cards_table.dart';
import 'readings_table.dart';

class DrawnCards extends Table {
  TextColumn get id => text()();
  TextColumn get readingId => text().references(Readings, #id)();
  TextColumn get cardId => text().references(Cards, #id)();
  IntColumn get position => integer()();
  BoolColumn get isReversed => boolean()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

### Considerations
- `SyncStatus` enum은 decks_table.dart에 정의, 다른 테이블에서 import
- `intEnum<SyncStatus>()`로 enum을 정수로 저장 (효율적, 쿼리 가능)
- Cards 테이블의 `meanings` 컬럼에 `CardMeaningsConverter` 적용 (Step 7)
- DrawnCards: 리딩과 카드의 N:M 관계를 조인 테이블로 해결
- FK `.references()`로 참조 무결성 보장

---

## Step 7 — Drift TypeConverter (CardMeanings)

### Approach
CardMeanings freezed 객체를 JSON 문자열로 변환하는 TypeConverter. Drift의 `.map()` 메서드와 연결.

### After Code
```dart
// mobile/lib/core/database/converters/card_meanings_converter.dart (new)
import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../features/deck/domain/entities/card_meanings.dart';

class CardMeaningsConverter extends TypeConverter<CardMeanings, String> {
  const CardMeaningsConverter();

  @override
  CardMeanings fromSql(String fromDb) {
    final json = jsonDecode(fromDb) as Map<String, dynamic>;
    return CardMeanings.fromJson(json);
  }

  @override
  String toSql(CardMeanings value) {
    return jsonEncode(value.toJson());
  }
}
```

### Considerations
- `const` 생성자로 테이블 정의에서 인스턴스 재사용
- fromSql에서 null 처리는 Drift가 nullable 여부에 따라 관리
- CardMeanings.fromJson은 freezed가 생성 (Step 10)

---

## Step 8 — Drift AppDatabase + Setup

### Approach
AppDatabase 클래스에 4개 테이블과 3개 DAO 등록. database_setup.dart에서 플랫폼별 SQLite 초기화.

### After Code — AppDatabase
```dart
// mobile/lib/core/database/app_database.dart (new)
import 'package:drift/drift.dart';

import 'tables/decks_table.dart';
import 'tables/cards_table.dart';
import 'tables/readings_table.dart';
import 'tables/drawn_cards_table.dart';
import 'converters/card_meanings_converter.dart';
import 'daos/deck_dao.dart';
import 'daos/card_dao.dart';
import 'daos/reading_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Decks, Cards, Readings, DrawnCards],
  daos: [DeckDao, CardDao, ReadingDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) => m.createAll(),
      );
}
```

### After Code — Database Setup
```dart
// mobile/lib/core/database/database_setup.dart (new)
import 'dart:io';

import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'app_database.dart';

Future<AppDatabase> constructDb() async {
  if (Platform.isAndroid) {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
  }

  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, 'personality_tarot.db'));

  return AppDatabase(
    NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        rawDb.execute('PRAGMA journal_mode = WAL');
        rawDb.execute('PRAGMA foreign_keys = ON');
        rawDb.execute('PRAGMA synchronous = NORMAL');
      },
    ),
  );
}
```

### Considerations
- `NativeDatabase.createInBackground`: DB 작업을 별도 isolate에서 실행 → UI 스레드 블로킹 방지
- WAL 모드: 읽기/쓰기 동시성 향상
- FK ON: 참조 무결성 런타임 강제
- `applyWorkaroundToOpenSqlite3OnOldAndroidVersions()`: Android API 16-23 호환성

---

## Step 9 — Drift DAOs

### Approach
각 도메인별 DAO. CRUD + 리액티브 스트림(watch). 시드 데이터 삽입 메서드 포함.

### After Code — DeckDao
```dart
// mobile/lib/core/database/daos/deck_dao.dart (new)
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/decks_table.dart';
import '../tables/cards_table.dart';

part 'deck_dao.g.dart';

@DriftAccessor(tables: [Decks, Cards])
class DeckDao extends DatabaseAccessor<AppDatabase> with _$DeckDaoMixin {
  DeckDao(super.db);

  Future<List<Deck>> getAllDecks() => select(decks).get();

  Stream<List<Deck>> watchAllDecks() => select(decks).watch();

  Future<Deck?> getDeckById(String id) =>
      (select(decks)..where((d) => d.id.equals(id))).getSingleOrNull();

  Future<void> insertDeck(DecksCompanion deck) =>
      into(decks).insert(deck);

  Future<void> insertDeckWithCards(
    DecksCompanion deck,
    List<CardsCompanion> cardList,
  ) async {
    await transaction(() async {
      await into(decks).insert(deck);
      await batch((b) => b.insertAll(cards, cardList));
    });
  }

  Future<bool> updateDeck(DecksCompanion deck) =>
      update(decks).replace(deck);

  Future<int> deleteDeck(String id) =>
      (delete(decks)..where((d) => d.id.equals(id))).go();
}
```

### After Code — CardDao
```dart
// mobile/lib/core/database/daos/card_dao.dart (new)
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/cards_table.dart';

part 'card_dao.g.dart';

@DriftAccessor(tables: [Cards])
class CardDao extends DatabaseAccessor<AppDatabase> with _$CardDaoMixin {
  CardDao(super.db);

  Future<List<Card>> getCardsByDeckId(String deckId) =>
      (select(cards)..where((c) => c.deckId.equals(deckId))).get();

  Stream<List<Card>> watchCardsByDeckId(String deckId) =>
      (select(cards)..where((c) => c.deckId.equals(deckId))).watch();

  Future<Card?> getCardById(String id) =>
      (select(cards)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<void> insertCard(CardsCompanion card) =>
      into(cards).insert(card);

  Future<void> insertCards(List<CardsCompanion> cardList) =>
      batch((b) => b.insertAll(cards, cardList));
}
```

### After Code — ReadingDao
```dart
// mobile/lib/core/database/daos/reading_dao.dart (new)
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/readings_table.dart';
import '../tables/drawn_cards_table.dart';

part 'reading_dao.g.dart';

@DriftAccessor(tables: [Readings, DrawnCards])
class ReadingDao extends DatabaseAccessor<AppDatabase> with _$ReadingDaoMixin {
  ReadingDao(super.db);

  Future<List<Reading>> getAllReadings() =>
      (select(readings)..orderBy([(r) => OrderingTerm.desc(r.createdAt)])).get();

  Stream<List<Reading>> watchAllReadings() =>
      (select(readings)..orderBy([(r) => OrderingTerm.desc(r.createdAt)])).watch();

  Future<void> insertReading(
    ReadingsCompanion reading,
    List<DrawnCardsCompanion> cards,
  ) async {
    await transaction(() async {
      await into(readings).insert(reading);
      await batch((b) => b.insertAll(drawnCards, cards));
    });
  }

  Future<List<DrawnCard>> getDrawnCardsForReading(String readingId) =>
      (select(drawnCards)
            ..where((dc) => dc.readingId.equals(readingId))
            ..orderBy([(dc) => OrderingTerm.asc(dc.position)]))
          .get();

  Future<int> deleteReading(String id) async {
    await (delete(drawnCards)..where((dc) => dc.readingId.equals(id))).go();
    return (delete(readings)..where((r) => r.id.equals(id))).go();
  }
}
```

---

## Step 10 — freezed 도메인 엔티티

### Approach
Drift 테이블 모델과 별개로 도메인 엔티티를 freezed로 정의. DB 모델 ↔ 도메인 엔티티 변환은 Phase 2 Repository에서 담당.

### After Code — CardMeanings
```dart
// mobile/lib/features/deck/domain/entities/card_meanings.dart (new)
import 'package:freezed_annotation/freezed_annotation.dart';

part 'card_meanings.freezed.dart';
part 'card_meanings.g.dart';

@freezed
class CardMeanings with _$CardMeanings {
  const factory CardMeanings({
    @Default([]) List<String> upright,
    @Default([]) List<String> reversed,
    String? customNotes,
  }) = _CardMeanings;

  factory CardMeanings.fromJson(Map<String, dynamic> json) =>
      _$CardMeaningsFromJson(json);
}
```

### After Code — TarotCard
```dart
// mobile/lib/features/deck/domain/entities/tarot_card.dart (new)
import 'package:freezed_annotation/freezed_annotation.dart';
import 'card_meanings.dart';

part 'tarot_card.freezed.dart';
part 'tarot_card.g.dart';

@freezed
class TarotCard with _$TarotCard {
  const factory TarotCard({
    required String id,
    required String deckId,
    required String cardId,
    required String name,
    required String arcana,     // major / minor
    String? suit,               // wands, cups, swords, pentacles
    required int number,
    required String imagePath,
    required CardMeanings meanings,
  }) = _TarotCard;

  factory TarotCard.fromJson(Map<String, dynamic> json) =>
      _$TarotCardFromJson(json);
}
```

### After Code — DeckMetadata
```dart
// mobile/lib/features/deck/domain/entities/deck_metadata.dart (new)
import 'package:freezed_annotation/freezed_annotation.dart';

part 'deck_metadata.freezed.dart';
part 'deck_metadata.g.dart';

@freezed
class DeckMetadata with _$DeckMetadata {
  const factory DeckMetadata({
    required String id,
    required String name,
    @Default(true) bool isStandardTarot,
    required int totalCards,
    String? creator,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _DeckMetadata;

  factory DeckMetadata.fromJson(Map<String, dynamic> json) =>
      _$DeckMetadataFromJson(json);
}
```

### After Code — Reading
```dart
// mobile/lib/features/reading/domain/entities/reading.dart (new)
import 'package:freezed_annotation/freezed_annotation.dart';
import 'spread_type.dart';

part 'reading.freezed.dart';
part 'reading.g.dart';

@freezed
class Reading with _$Reading {
  const factory Reading({
    required String id,
    required String deckId,
    required SpreadType spreadType,
    String? question,
    String? notes,
    required List<DrawnCardInfo> drawnCards,
    required DateTime createdAt,
  }) = _Reading;

  factory Reading.fromJson(Map<String, dynamic> json) =>
      _$ReadingFromJson(json);
}

@freezed
class DrawnCardInfo with _$DrawnCardInfo {
  const factory DrawnCardInfo({
    required String cardId,
    required int position,
    required bool isReversed,
  }) = _DrawnCardInfo;

  factory DrawnCardInfo.fromJson(Map<String, dynamic> json) =>
      _$DrawnCardInfoFromJson(json);
}
```

### After Code — SpreadType
```dart
// mobile/lib/features/reading/domain/entities/spread_type.dart (new)
enum SpreadType {
  single(
    displayName: '한 장 뽑기',
    cardCount: 1,
    positions: ['현재'],
  ),
  threeCard(
    displayName: '쓰리 카드',
    cardCount: 3,
    positions: ['과거', '현재', '미래'],
  );

  const SpreadType({
    required this.displayName,
    required this.cardCount,
    required this.positions,
  });

  final String displayName;
  final int cardCount;
  final List<String> positions;
}
```

### Considerations
- 도메인 엔티티는 DB 모델(Drift Companion/DataClass)과 분리. 이유: DB 스키마 변경이 도메인 로직에 전파되지 않도록
- SpreadType은 enum + enhanced enum (Dart 3). 위치 라벨까지 내장하여 UI에서 바로 사용
- DrawnCardInfo: 리딩에 포함된 뽑힌 카드 정보. Reading에 인라인

---

## Step 11 — RWS 78장 시드 데이터

### Approach
Rider-Waite-Smith 78장의 메타데이터를 JSON으로 작성. Major Arcana 22장 + Minor Arcana 56장(4벌 × 14장). 이미지 경로는 placeholder. meanings는 대표적인 키워드.

### After Code
```json
// mobile/assets/data/rws_deck.json (new)
// 구조 예시 — 실제 파일에는 전체 78장 포함
{
  "deck": {
    "id": "rws-standard",
    "name": "Rider-Waite-Smith",
    "isStandardTarot": true,
    "totalCards": 78,
    "creator": "A.E. Waite & Pamela Colman Smith"
  },
  "cards": [
    {
      "cardId": "major-00",
      "name": "The Fool",
      "arcana": "major",
      "suit": null,
      "number": 0,
      "imagePath": "assets/images/placeholder.png",
      "meanings": {
        "upright": ["new beginnings", "innocence", "adventure", "free spirit"],
        "reversed": ["recklessness", "fear of unknown", "poor judgment"]
      }
    },
    {
      "cardId": "major-01",
      "name": "The Magician",
      "arcana": "major",
      "suit": null,
      "number": 1,
      "imagePath": "assets/images/placeholder.png",
      "meanings": {
        "upright": ["willpower", "creation", "manifestation", "resourcefulness"],
        "reversed": ["manipulation", "untapped talents", "trickery"]
      }
    },
    // ... major-02 through major-21 ...
    {
      "cardId": "wands-01",
      "name": "Ace of Wands",
      "arcana": "minor",
      "suit": "wands",
      "number": 1,
      "imagePath": "assets/images/placeholder.png",
      "meanings": {
        "upright": ["inspiration", "creative spark", "new initiative"],
        "reversed": ["delays", "lack of motivation", "hesitation"]
      }
    }
    // ... wands-02 through wands-14 (King) ...
    // ... cups-01 through cups-14 ...
    // ... swords-01 through swords-14 ...
    // ... pentacles-01 through pentacles-14 ...
  ]
}
```

### Considerations
- 전체 78장의 cardId 패턴: `major-NN` (00-21), `{suit}-NN` (01-14)
- Minor suit 14장: Ace(1), 2-10, Page(11), Knight(12), Queen(13), King(14)
- meanings는 실제 RWS 전통 해석의 핵심 키워드 (퍼블릭 도메인 해석)
- imagePath는 모두 placeholder — 실제 이미지는 저작권 확인 후 별도 작업
- 이 JSON을 앱 최초 실행 시 Drift DB에 시드하는 로직은 Phase 2 Repository에서 구현

---

## Step 12 — main.dart 부트스트랩

### Approach
ProviderScope로 앱 래핑, DB 초기화를 앱 시작 시 수행. Phase 3에서 라우터 연결 시 추가 수정.

### Current Code
```dart
// mobile/lib/main.dart:1-21
import 'package:flutter/material.dart';

void main() {
  runApp(const PersonalityApp());
}

class PersonalityApp extends StatelessWidget {
  const PersonalityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personality',
      home: const Scaffold(
        body: Center(
          child: Text('Personality + Tarot'),
        ),
      ),
    );
  }
}
```

### After Code
```dart
// mobile/lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/database/database_setup.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = await constructDb();

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
      child: const PersonalityApp(),
    ),
  );
}

class PersonalityApp extends StatelessWidget {
  const PersonalityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personality Tarot',
      theme: AppTheme.darkTheme,
      home: const Scaffold(
        body: Center(
          child: Text('Personality + Tarot'),
        ),
      ),
    );
  }
}
```

### Considerations
- `WidgetsFlutterBinding.ensureInitialized()`: 비동기 초기화(DB) 전 필수
- `appDatabaseProvider`는 별도 provider 파일에서 정의 (아래 추가 파일)
- DB를 Provider에 override로 주입 → 테스트에서 in-memory DB로 교체 가능
- Phase 3에서 MaterialApp → MaterialApp.router로 변경

### 추가 파일 — DB Provider
```dart
// mobile/lib/core/database/database_provider.dart (new)
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'app_database.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(AppDatabaseRef ref) {
  throw UnimplementedError('Must be overridden in main.dart');
}
```

### Considerations
- `@Riverpod(keepAlive: true)`: DB 인스턴스는 앱 수명과 동일
- `throw UnimplementedError`: main.dart에서 반드시 override 필요 → 실수 방지
- 이 패턴으로 get_it 없이 Riverpod만으로 DI 달성

---

## Step 13 — build_runner 코드 생성 실행

### Approach
모든 파일 작성 후 build_runner로 코드 생성 파일 확인.

### Command
```bash
cd mobile && flutter pub get && dart run build_runner build --delete-conflicting-outputs
```

### Expected Generated Files
- `lib/core/database/app_database.g.dart`
- `lib/core/database/daos/deck_dao.g.dart`
- `lib/core/database/daos/card_dao.g.dart`
- `lib/core/database/daos/reading_dao.g.dart`
- `lib/core/database/database_provider.g.dart`
- `lib/features/deck/domain/entities/card_meanings.freezed.dart`
- `lib/features/deck/domain/entities/card_meanings.g.dart`
- `lib/features/deck/domain/entities/tarot_card.freezed.dart`
- `lib/features/deck/domain/entities/tarot_card.g.dart`
- `lib/features/deck/domain/entities/deck_metadata.freezed.dart`
- `lib/features/deck/domain/entities/deck_metadata.g.dart`
- `lib/features/reading/domain/entities/reading.freezed.dart`
- `lib/features/reading/domain/entities/reading.g.dart`

---

## Considerations & Trade-offs

### Alternative Approaches
| Approach | 불채택 이유 |
|----------|-----------|
| Hive로 시작 → Drift 전환 | 마이그레이션 비용. 처음부터 Drift가 장기적으로 유리 |
| Entity와 DB 모델 통합 | 결합도 증가. 스키마 변경이 도메인 전파 |
| 시드 데이터를 Dart 코드로 | JSON이 비개발자 편집 가능 + 향후 서버 API 포맷과 일치 |

### Potential Risks
| Risk | Mitigation |
|------|-----------|
| build_runner 실행 실패 | import 순환 확인, part 지시문 검증 |
| flutter create가 기존 파일 덮어씀 | flutter create은 기존 파일 보존 (확인됨) |
| Drift와 freezed 간 버전 충돌 | 검증된 버전 조합 사용 |

### Backward Compatibility
- 기존 `mobile/pubspec.yaml`과 `main.dart`만 수정. 새 파일 추가가 대부분
- 빈 스켈레톤이므로 호환성 이슈 없음

## Implementation Checklist

- [ ] Step 1: Flutter 프로젝트 플랫폼 초기화 (`flutter create`)
- [ ] Step 2: pubspec.yaml 의존성 추가
- [ ] Step 3: analysis_options.yaml 생성
- [ ] Step 4: Core: Failure sealed class
- [ ] Step 5: Core: AppTheme 다크 테마
- [ ] Step 6: Drift 테이블 4개 (Decks, Cards, Readings, DrawnCards)
- [ ] Step 7: CardMeaningsConverter TypeConverter
- [ ] Step 8: AppDatabase + database_setup.dart
- [ ] Step 9: DAOs 3개 (DeckDao, CardDao, ReadingDao)
- [ ] Step 10: freezed 도메인 엔티티 5개
- [ ] Step 11: RWS 78장 시드 데이터 JSON
- [ ] Step 12: main.dart 부트스트랩 + database_provider.dart
- [ ] Step 13: build_runner 코드 생성 확인
- [ ] Final verification

## Verification Assertions

| Level | Assertion | Verification Method | Expected Result |
|-------|-----------|-------------------|-----------------|
| L1-Build | flutter pub get 성공 | `cd mobile && flutter pub get` | 에러 없음 |
| L1-Build | build_runner 코드 생성 성공 | `dart run build_runner build` | 13개 생성 파일 |
| L1-Build | flutter analyze 통과 | `flutter analyze` | 에러 0 |
| L2-CLI | DB 테이블 생성 확인 | 유닛 테스트 (in-memory DB) | 4개 테이블 CREATE |
| L2-CLI | freezed JSON 직렬화 | 유닛 테스트 | fromJson/toJson 왕복 |
| L4-Trace | R-008-F4 Drift DB | DB 스키마 검증 | FK, JSON1, 리액티브 |
| L4-Trace | R-008-F5 동기화 필드 | 스키마 검증 | syncStatus, version 존재 |

## References

| Resource | Path/URL | Related Content |
|----------|---------|-----------------|
| Scope | docs/11_tarot_shuffle/001_Scope_platform_strategy.md | 플랫폼 전략, 개발 순서 |
| Research | docs/11_tarot_shuffle/008_Research_tarot_shuffle_tech.md | 기술 스택 전체 |
| Synthesis | docs/11_tarot_shuffle/007_Synthesis_tarot_shuffle_tech.md | 관점 종합 |
| Checkpoint | docs/11_tarot_shuffle/009_Plan_flutter_mvp_checkpoint.md | 플랜 마스터 |

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
