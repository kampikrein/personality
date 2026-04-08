---
title: "UserSettings 데이터 모델 & 초기화 흐름 조사"
type: Agent
date: 2026-04-01
author: flutter-expert
summary: "UserSettings entity, Drift 테이블 스키마, lazy init 패턴, 필드별 기본값, fallback 일치 여부를 코드 레벨로 검증"
key_findings:
  - "experienceLevel 기본값: entity(@Default(1)), DB(Constant(1)), fallback(?? 1) — 3계층 모두 일치"
  - "quickDrawEnabled=true이면 앱 루트(/)에서 experienceLevel에 따라 즉시 뽑기 화면으로 redirect"
  - "초기화 패턴: lazy init (최초 watchSettings/getSettings 호출 시 id=1 행 없으면 INSERT)"
  - "migration v2에서 user_settings 테이블 생성 — onCreate도 createAll()로 커버"
  - "defaultSpreadType fallback 불일치: instant/animated_draw_page에서 ?? SpreadType.threeCard, DB 기본값도 'threeCard' — 일치하나 entity @Default(SpreadType.threeCard)와도 정렬됨"
confidence: high
---

# UserSettings 데이터 모델 & 초기화 흐름 조사

## 1. UserSettings Entity 필드 목록

파일: `mobile/lib/features/settings/domain/entities/user_settings.dart`

```dart
// L10-18
@freezed
class UserSettings with _$UserSettings {
  const factory UserSettings({
    @Default('rws-standard') String selectedDeckId,    // L11
    @Default(1) int experienceLevel,                   // L12
    @Default(3) int defaultCardCount,                  // L13
    @Default(false) bool showFaceUp,                   // L14
    @Default(false) bool quickDrawEnabled,             // L15
    @Default(SpreadType.threeCard) SpreadType defaultSpreadType, // L16
    required DateTime updatedAt,                       // L17
  }) = _UserSettings;
  ...
}
```

| 필드 | 타입 | Entity @Default |
|------|------|----------------|
| selectedDeckId | String | `'rws-standard'` |
| experienceLevel | int | `1` |
| defaultCardCount | int | `3` |
| showFaceUp | bool | `false` |
| quickDrawEnabled | bool | `false` |
| defaultSpreadType | SpreadType | `SpreadType.threeCard` |
| updatedAt | DateTime | (required, 기본값 없음) |

---

## 2. DB 테이블 스키마 (Drift)

파일: `mobile/lib/core/database/tables/user_settings_table.dart`

```dart
// L1-21
class UserSettingsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get selectedDeckId =>
      text().withDefault(const Constant('rws-standard'))();  // L6
  IntColumn get experienceLevel =>
      integer().withDefault(const Constant(1))();            // L8-9
  IntColumn get defaultCardCount =>
      integer().withDefault(const Constant(3))();            // L10-11
  BoolColumn get showFaceUp =>
      boolean().withDefault(const Constant(false))();        // L12-13
  BoolColumn get quickDrawEnabled =>
      boolean().withDefault(const Constant(false))();        // L14-15
  TextColumn get defaultSpreadType =>
      text().withDefault(const Constant('threeCard'))();     // L16-17
  DateTimeColumn get updatedAt => dateTime()();              // L18 — DB 레벨 기본값 없음

  @override
  String get tableName => 'user_settings';                   // L20
}
```

**DB 레벨 기본값 정의 여부**:
- `selectedDeckId`, `experienceLevel`, `defaultCardCount`, `showFaceUp`, `quickDrawEnabled`, `defaultSpreadType` — DB 레벨(`withDefault`)에서 정의됨
- `updatedAt` — DB 기본값 없음. INSERT 시 앱 레벨에서 `DateTime.now()` 주입

**앱 레벨 기본값 정의 여부**:
- Entity `@Default(...)` 애노테이션으로 freezed/json 역직렬화 fallback도 별도 정의

---

## 3. 최초 실행 시드 — Lazy Init 패턴

파일: `mobile/lib/core/database/daos/user_settings_dao.dart`

초기화 전략: **lazy init** — seed 함수나 migration INSERT 없이, 최초 `watchSettings()` 또는 `getSettings()` 호출 시점에 행이 없으면 `_ensureDefaultRow()`를 통해 id=1 행을 INSERT한다.

```dart
// L15-26 watchSettings()
Stream<UserSettingsTableData> watchSettings() {
  return (select(userSettingsTable)
        ..where((s) => s.id.equals(1)))
      .watchSingleOrNull()
      .asyncMap((row) async {
    if (row != null) return row;
    await _ensureDefaultRow();          // 행 없으면 INSERT
    return await (select(userSettingsTable)
          ..where((s) => s.id.equals(1)))
        .getSingle();
  });
}

// L49-57 _ensureDefaultRow()
Future<void> _ensureDefaultRow() async {
  final exists = await (select(userSettingsTable)
        ..where((s) => s.id.equals(1)))
      .getSingleOrNull();
  if (exists != null) return;
  await into(userSettingsTable).insert(
    UserSettingsTableCompanion.insert(updatedAt: DateTime.now()),
    // selectedDeckId, experienceLevel 등은 DB withDefault()가 채움
  );
}
```

**INSERT 시 명시적으로 전달하는 필드**: `updatedAt`만. 나머지 6개 필드는 SQLite `withDefault` 값이 적용된다.

**Migration 전략** (`mobile/lib/core/database/app_database.dart`):
- `schemaVersion = 2` (L25)
- `onCreate`: `m.createAll()` — 최초 설치 시 모든 테이블 생성 (L29)
- `onUpgrade from < 2`: `m.createTable(userSettingsTable)` — 기존 앱 업그레이드 시 user_settings 테이블 추가 (L31-33)
- user_settings 행 사전 INSERT는 없음. 테이블 생성만.

---

## 4. experienceLevel 기본값

| 계층 | 정의 위치 | 값 |
|------|----------|-----|
| Entity @Default | `user_settings.dart:12` | `1` |
| DB withDefault | `user_settings_table.dart:8` | `Constant(1)` |
| JSON fallback | `user_settings.g.dart:12` | `?? 1` |
| 앱 fallback (홈) | `home_page.dart:54` | `?? 1` |
| 앱 fallback (라우터) | 없음 — `settings?.experienceLevel` (null이면 redirect 스킵) | — |

**일치 여부**: 모든 계층에서 `1` — **완전 일치**. 불일치 없음.

---

## 5. quickDrawEnabled 기본값 및 true일 때 의미

| 계층 | 정의 위치 | 값 |
|------|----------|-----|
| Entity @Default | `user_settings.dart:15` | `false` |
| DB withDefault | `user_settings_table.dart:14` | `Constant(false)` |
| JSON fallback | `user_settings.g.dart:15` | `?? false` |

**true일 때 동작** (`app_router.dart:44-53`):

```dart
// L44-53
if (settings.quickDrawEnabled) {
  return switch (settings.experienceLevel) {
    1 => '/draw/instant',   // 즉시 뽑기 화면으로 즉시 redirect
    2 => '/draw/animated',  // 간단 연출 뽑기로 즉시 redirect
    3 => '/shuffle/${settings.selectedDeckId}', // 풀셔플로 즉시 redirect
    _ => null,
  };
}
```

앱이 루트(`/`)에 진입하는 순간 홈 화면을 보여주지 않고 설정된 뽑기 화면으로 직행한다. 설정 페이지의 레이블도 "앱 시작 시 바로 뽑기" (`settings_page.dart:91`).

**일치 여부**: 3계층 모두 `false` — **완전 일치**.

---

## 6. 기타 필드 기본값 요약

### defaultCardCount

| 계층 | 값 | 위치 |
|------|----|------|
| Entity | `3` | `user_settings.dart:13` |
| DB | `Constant(3)` | `user_settings_table.dart:10` |
| JSON fallback | `?? 3` (미확인, freezed default로 커버) | `user_settings.g.dart` |
| 앱 fallback | `?? 3` | `home_page.dart:56`, `instant_draw_page.dart:49`, `animated_draw_page.dart:56` |

**일치 여부**: 모두 `3` — **완전 일치**.

### selectedDeckId

| 계층 | 값 | 위치 |
|------|----|------|
| Entity | `'rws-standard'` | `user_settings.dart:11` |
| DB | `Constant('rws-standard')` | `user_settings_table.dart:6` |
| 앱 fallback | `?? 'rws-standard'` | `home_page.dart:55`, `instant_draw_page.dart:51`, `animated_draw_page.dart:58` |

**일치 여부**: 모두 `'rws-standard'` — **완전 일치**.

### showFaceUp

| 계층 | 값 | 위치 |
|------|----|------|
| Entity | `false` | `user_settings.dart:14` |
| DB | `Constant(false)` | `user_settings_table.dart:12` |
| 앱 fallback | `?? false` | `animated_draw_page.dart:59` |

`instant_draw_page.dart`에는 `showFaceUp` fallback 코드가 없다. `_initSettings()`에서 `showFaceUp`를 읽지 않는다. 즉시 뽑기 화면은 이 설정을 사용하지 않는 것으로 보임.

**일치 여부**: 값 자체는 일치. `instant_draw_page`의 미사용은 설계 의도일 수 있으나 확인 필요.

### defaultSpreadType

| 계층 | 값 | 위치 |
|------|----|------|
| Entity | `SpreadType.threeCard` | `user_settings.dart:16` |
| DB | `Constant('threeCard')` | `user_settings_table.dart:16` |
| 앱 fallback (instant) | `?? SpreadType.threeCard` | `instant_draw_page.dart:47` |
| 앱 fallback (animated) | `?? SpreadType.threeCard` | `animated_draw_page.dart:54` |

**일치 여부**: DB의 `'threeCard'`는 `SpreadType.threeCard.name`과 동일. `_toDomain()`에서 `SpreadType.values.byName(row.defaultSpreadType)`로 변환되므로 일치.

---

## 7. 설정 읽기 패턴 — Fallback 분석

### Provider 체인

```
userSettingsProvider (Stream<UserSettings>, @riverpod)
  └── userSettingsRepositoryProvider (keepAlive: true)
        └── AppDatabase.userSettingsDao.watchSettings()
              └── _ensureDefaultRow() [lazy init]
```

파일: `settings_providers.dart:10-20`

### Presentation 레이어 fallback 패턴

```dart
// home_page.dart:53-56 — settings가 null(로딩 중)일 때 fallback
final settings = settingsAsync.valueOrNull;
final experienceLevel = settings?.experienceLevel ?? 1;
final selectedDeckId = settings?.selectedDeckId ?? 'rws-standard';
final defaultCardCount = settings?.defaultCardCount ?? 3;
```

```dart
// instant_draw_page.dart:45-52 — initState에서 ref.read (한 번만)
void _initSettings() {
  final settings = ref.read(userSettingsProvider).valueOrNull;
  _spreadType = settings?.defaultSpreadType ?? SpreadType.threeCard;
  _currentCardCount = _spreadType == SpreadType.custom
      ? settings?.defaultCardCount ?? 3
      : _spreadType.cardCount;
  _deckId = settings?.selectedDeckId ?? 'rws-standard';
}
```

**모든 fallback 값이 DB/Entity 기본값과 일치**. 기본값 불일치 없음.

### router의 null 처리

```dart
// app_router.dart:41-43
if (settings == null) return null;  // 로딩 중이면 redirect 없음
if (state.matchedLocation != '/') return null;  // 루트 외 무한 redirect 방지
```

settings가 null이면 redirect를 수행하지 않아 홈 화면에 머문다. DB가 초기화되어 Stream이 첫 값을 emit하면 GoRouter가 재평가한다.

---

## 8. 기본값 불일치 요약

| 항목 | 불일치 여부 | 비고 |
|------|-----------|------|
| experienceLevel | 없음 | entity/DB/fallback 모두 1 |
| quickDrawEnabled | 없음 | entity/DB/fallback 모두 false |
| defaultCardCount | 없음 | entity/DB/fallback 모두 3 |
| selectedDeckId | 없음 | entity/DB/fallback 모두 'rws-standard' |
| showFaceUp | 없음 (값 일치) | instant_draw_page에서 이 필드 미사용 — 의도 확인 권고 |
| defaultSpreadType | 없음 | 'threeCard' == SpreadType.threeCard.name |

**발견된 주요 불일치: 없음.**

**주목할 설계 특이점**:
1. `instant_draw_page._initSettings()`에서 `showFaceUp`를 읽지 않음 — 즉시 뽑기는 항상 뒷면으로 시작하는 것인지, 아니면 누락인지 확인 필요.
2. lazy init의 이중 체크: `watchSettings()`와 `_ensureDefaultRow()` 모두 `getSingleOrNull()`로 존재 여부를 확인하므로, 동시 호출 시 race condition 이론상 가능. 실제로는 단일 Isolate Flutter 앱에서 문제되지 않으나 Future chain 사이 await 지점에 주의.

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
| 25 | user-ai-exchange | 29s | 234056 |
| 26 | user-ai-exchange | 3s | 48718 |
| 27 | user-ai-exchange | 13s | 54002 |
| 28 | user-ai-exchange | 9s | 55309 |
| 29 | user-ai-exchange | 10s | 58339 |
| 30 | user-ai-exchange | 11s | 61129 |
| 31 | user-ai-exchange | 7s | 62416 |
| 32 | user-ai-exchange | 0s | 0 |
| 33 | user-ai-exchange | 10s | 63892 |
| 34 | user-ai-exchange | 22s | 67713 |
| 35 | user-ai-exchange | 9s | 69028 |
| 36 | user-ai-exchange | 21s | 215578 |
| 37 | user-ai-exchange | 174s | 517468 |
| 38 | user-ai-exchange | 418s | 1153988 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 385871s |
| Total Tokens | 4253170 |
| Input Tokens | 135 |
| Output Tokens | 31938 |
| Cache Read | 3624819 |
| Cache Creation | 596278 |
