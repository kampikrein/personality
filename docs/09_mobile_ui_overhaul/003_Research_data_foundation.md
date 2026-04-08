---
id: "003"
type: research
title: "Cycle 1 데이터 기반 — 기술 조사"
created: 2026-03-22
traces_scope: "002"
cycle: 1
area: "데이터 기반 (Data Foundation)"
status: complete
summary: >
  ShuffleResult→Reading 데이터 플로우, Drift migration v2, SpreadType 확장,
  GoRouter async redirect — 4개 핵심 질문에 대한 코드 기반 조사 결과 및 구현 추천.
keywords: [shuffle-result, drift-migration, spread-type, gorouter-redirect, user-settings]
---

# Cycle 1 데이터 기반 — 기술 조사

## Q1. ShuffleResult → Reading 데이터 플로우 ("+1 한 장 더" 기술 기반)

### 현재 구조 분석

**ShuffleResult는 전체 덱을 셔플한 결과를 보유한다.**

`FisherYatesShuffleStrategy.shuffle()`은 전달받은 `cards` 리스트(타로 78장 / I Ching 64장) 전체를 Fisher-Yates로 셔플한 후, **모든 카드**를 `ShuffledCard` 리스트로 반환한다:

```dart
// fisher_yates_shuffle_strategy.dart:31-35
final shuffledCards = deck.map((card) {
  final isReversed = config.useReversals &&
      random.nextDouble() < config.reversalProbability;
  return ShuffledCard(card: card, isReversed: isReversed);
}).toList();
```

즉 `ShuffleResult.cards`는 **78장(또는 64장) 전체의 셔플된 순서**를 갖고 있다.

**ReadingPage는 SpreadType.cardCount만큼만 사용한다.**

```dart
// reading_page.dart:57-58
final drawnCards = shuffleResult.cards.take(_spreadType.cardCount).toList();
```

`single`이면 1장, `threeCard`이면 3장만 꺼내 쓰고, **나머지 75~77장은 ShuffleResult 안에 그대로 남아 있다.**

**ShuffleState(Riverpod `keepAlive: true`)가 전체 셔플 결과를 유지한다.**

```dart
// shuffle_providers.dart:51-62
@Riverpod(keepAlive: true)
class ShuffleState extends _$ShuffleState {
  @override
  ShuffleResult? build() => null;
  void setResult(ShuffleResult result) { ... state = result; }
  void clear() => state = null;
}
```

`keepAlive: true`이므로 앱 생존 기간 동안 셔플 결과가 메모리에 유지된다.

### "+1 한 장 더" 기술 기반 판단

**결론: 기존 구조에서 "+1" 기능을 구현하기 위한 데이터 기반이 이미 충분하다.**

- `ShuffleResult.cards`는 전체 덱 순서를 보유하므로, `cards[cardCount]`, `cards[cardCount+1]`, ... 으로 다음 카드를 가져올 수 있다.
- `ShuffleState`가 `keepAlive: true`이므로 ReadingPage에서 셔플 결과에 접근 가능.
- 남은 카드 수 = `shuffleResult.cards.length - currentDrawnCount`.

### 추천 접근법

1. **ReadingPage에 `_currentCardCount` 상태 추가**: 초기값은 `widget.spreadType.cardCount`, "+1" 탭 시 `setState(() => _currentCardCount++)`.
2. **drawnCards를 동적으로 계산**: `shuffleResult.cards.take(_currentCardCount).toList()`.
3. **버튼 비활성화 조건**: `_currentCardCount >= shuffleResult.cards.length`.
4. **자동 저장 갱신**: 카드 추가 시 기존 Reading DB 레코드의 `DrawnCards`에 새 행 INSERT + Reading `updatedAt` 갱신.
5. **SpreadLayout 수정 필요**: 현재 `switch (spreadType)` 패턴이 `single`/`threeCard`만 처리하므로, 동적 카드 수를 처리하는 generic 레이아웃 분기 추가 필요.

### 주의사항

- Level 1/2 즉시 뽑기 경로에서도 셔플 로직을 실행하고 `ShuffleState`에 결과를 세팅해야 "+1"이 동작한다. 현재 `_quickDraw()`는 이미 이 패턴을 사용하므로 호환.
- `readingQuestionProvider`는 `keepAlive: true`로 별도 관리되므로, "+1" 시 질문 데이터는 보존됨.

---

## Q2. Drift Migration v2 — UserSettings 테이블 추가

### 현재 스키마 구조

```dart
// app_database.dart
@DriftDatabase(
  tables: [Decks, Cards, Readings, DrawnCards],
  daos: [DeckDao, CardDao, ReadingDao],
)
class AppDatabase extends _$AppDatabase {
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => m.createAll(),
  );
}
```

- 현재 `schemaVersion = 1`, migration은 `onCreate`만 정의.
- `onUpgrade` 콜백이 없으므로, 기존 사용자의 v1 → v2 업그레이드 시 **수동으로 마이그레이션을 정의해야 한다.**

### 기존 테이블 패턴

4개 테이블 모두 동일 패턴:
- `TextColumn id` (PK), 타임스탬프, `SyncStatus` intEnum, `version` int.
- 외래키 참조 관계: `DrawnCards → Readings`, `DrawnCards → Cards`, `Cards → Decks`, `Readings → Decks`.

### Drift v2 마이그레이션 방법

Drift 2.28.x에서 `onUpgrade`를 사용한 표준 마이그레이션:

```dart
@override
int get schemaVersion => 2;

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (Migrator m) => m.createAll(),
  onUpgrade: (Migrator m, int from, int to) async {
    if (from < 2) {
      await m.createTable(userSettings);
    }
  },
);
```

### 추천 접근법

1. **`UserSettings` 테이블 정의** (`tables/user_settings_table.dart`):

| Column | Type | Default | 설명 |
|--------|------|---------|------|
| `id` | `IntColumn` | autoIncrement PK | 단일 행 패턴 (항상 id=1) |
| `selectedDeckId` | `TextColumn` | `'rws-standard'` | 선택된 덱 |
| `experienceLevel` | `IntColumn` | `1` | 체험 레벨 (1/2/3) |
| `defaultCardCount` | `IntColumn` | `3` | 기본 카드 수 |
| `showFaceUp` | `BoolColumn` | `false` | 앞면 표시 여부 |
| `quickDrawEnabled` | `BoolColumn` | `false` | 즉시 뽑기 모드 |
| `defaultSpreadType` | `TextColumn` | `'threeCard'` | 기본 스프레드 |
| `updatedAt` | `DateTimeColumn` | — | 마지막 수정 시각 |

2. **`schemaVersion`을 2로 올리고 `onUpgrade` 추가**: 위 패턴 사용.
3. **기존 데이터 보존**: `onUpgrade`는 새 테이블만 CREATE하므로 기존 4개 테이블(Decks, Cards, Readings, DrawnCards)의 데이터는 영향 없음. `createTable`은 IF NOT EXISTS 시맨틱.
4. **초기 행 삽입**: 마이그레이션 후 또는 DAO에서 "없으면 기본값 INSERT" 패턴 사용.
5. **DAO 패턴**: 기존 `ReadingDao` 패턴을 따라 `UserSettingsDao` 구현. `watchSettings()` Stream 제공.

### 주의사항

- Drift 2.x에서 `m.createTable()`은 테이블 선언의 `@DriftDatabase(tables: [...])`에 등록된 테이블 참조를 사용. `userSettings`를 `tables` 리스트에 추가해야 함.
- 단일 행 패턴(`id=1`)은 `SELECT * FROM user_settings LIMIT 1` + 없으면 INSERT DEFAULT. Riverpod Stream으로 reactive.
- Drift의 `stepByStep` migration API도 있으나, v1→v2 단일 변경이므로 `from < 2` 조건문이면 충분.

---

## Q3. SpreadType 확장 가능성 — enum 유지 vs 데이터 클래스

### 현재 구조

```dart
// spread_type.dart
enum SpreadType {
  single(displayName: '한 장 뽑기', cardCount: 1, positions: ['현재'], guidances: [...]),
  threeCard(displayName: '쓰리 카드', cardCount: 3, positions: [...], guidances: [...]);

  const SpreadType({ required this.displayName, ... });
  final String displayName;
  final int cardCount;
  final List<String> positions;
  final List<String> guidances;
}
```

### SpreadType 참조 지점 (영향 범위)

| 파일 | 사용 방식 | 영향도 |
|------|----------|--------|
| `reading_page.dart` | `_spreadType.cardCount`, `.displayName`, `.positions[i]`, `.guidances[i]` | 높음 |
| `spread_layout.dart` | `switch (spreadType) { SpreadType.single => ..., SpreadType.threeCard => ... }` | **높음 — exhaustive switch** |
| `reading_repository_impl.dart` | `SpreadType.values.byName(row.spreadType)` — DB에서 역직렬화 | **높음 — byName 깨짐 위험** |
| `reading.g.dart` (생성 코드) | `$enumDecode(_$SpreadTypeEnumMap, json['spreadType'])` | 자동 생성, enum 변경 시 재생성 |
| `home_page.dart` | `SpreadType.threeCard` 리터럴 참조 | 낮음 |
| `app_router.dart` | `state.extra as SpreadType?` | 낮음 |

### 선택지 분석

#### Option A: enum 유지 + custom(N) 추가

```dart
enum SpreadType {
  single(...),
  threeCard(...),
  custom; // cardCount, positions, guidances를 동적으로 제공

  const SpreadType({ this.displayName, this.cardCount, ... });
}
```

**문제점:**
- Dart enum은 각 variant가 **동일한 생성자 시그니처**를 공유해야 함. `custom`에 동적 `cardCount`를 주려면 모든 enum 값에 nullable 파라미터를 도입해야 함.
- `custom.cardCount`가 null이면 모든 사용처에서 null 체크 필요.
- DB 저장 시 `SpreadType.values.byName('custom')`은 되지만, `cardCount`를 복원할 수 없음 — DB에 별도 컬럼 필요.
- **exhaustive switch**가 깨짐: `SpreadType.custom`에 대한 레이아웃 분기를 추가해야 함. 이는 실제로 원하는 동작(generic layout).

#### Option B: sealed class 전환

```dart
sealed class SpreadType {
  String get displayName;
  int get cardCount;
  List<String> get positions;
  List<String> get guidances;
}

class SingleSpread extends SpreadType { ... }
class ThreeCardSpread extends SpreadType { ... }
class CustomSpread extends SpreadType {
  final int count;
  // positions/guidances를 generic으로 생성
}
class NamedSpread extends SpreadType {
  final String name;
  // positions/guidances를 데이터로 보유
}
```

**장점:**
- 타입 안전한 패턴 매칭 유지 (`switch` exhaustive).
- `CustomSpread(count: 5)` 처럼 동적 값 자연스러움.
- 향후 `NamedSpread` (켈틱 크로스 등)도 자연스럽게 추가.
- JSON/DB 직렬화: `type` discriminator + 데이터 필드.

**단점:**
- **Breaking change**: 모든 참조 지점 수정 필요 (6개 파일).
- Freezed 통합: sealed class + Freezed는 가능하지만 코드 생성 패턴이 복잡해짐.
- DB 저장: `SpreadType.values.byName()` 패턴을 커스텀 역직렬화로 교체 필요.

#### Option C: enum 유지 + factory 확장 (추천)

```dart
enum SpreadType {
  single(displayName: '한 장 뽑기', cardCount: 1, ...),
  threeCard(displayName: '쓰리 카드', cardCount: 3, ...),
  fiveCard(displayName: '다섯 장', cardCount: 5, ...),
  // 향후 전통 스프레드 추가 시에도 enum에 추가
  ;

  // custom(N)용 팩토리 — SpreadType 자체가 아닌 별도 wrapper
}
```

**핵심 아이디어:** 자유 선택(1~10장)을 위한 `custom(N)`은 **enum의 variant로 추가하지 않고**, `ReadingPage`에서 동적 `cardCount`를 별도 상태로 관리.

- DB의 `spreadType` 컬럼에는 `'custom'`을 저장하고, 별도 `cardCount` 컬럼(또는 기존 `DrawnCards` 행 수)으로 실제 장수를 복원.
- enum에 `custom` 하나만 추가하되, `cardCount = 0` (sentinel) + getter override로 처리.

### 추천: Option C 변형 — enum에 custom 추가 + cardCount 분리

```dart
enum SpreadType {
  single(displayName: '한 장 뽑기', cardCount: 1, ...),
  threeCard(displayName: '쓰리 카드', cardCount: 3, ...),
  custom(displayName: '자유 선택', cardCount: 0, positions: [], guidances: []);
  // cardCount: 0은 sentinel — 실제 값은 Reading.drawnCards.length 또는 별도 전달
}
```

**이유:**
1. **최소 파괴**: enum 유지, 기존 `single`/`threeCard` 변경 없음.
2. **DB 호환**: `SpreadType.values.byName('custom')` 정상 동작. 실제 카드 수는 `DrawnCards` 행 수로 복원.
3. **SpreadLayout**: `custom` 분기 추가 → generic grid/list 레이아웃.
4. **향후 확장**: 전통 스프레드(`celticCross` 등)도 enum에 추가 가능. 10개 이하의 variant라면 enum이 적절.
5. **Sealed class는 과도**: 현 단계에서 `NamedSpread` 같은 복합 데이터 모델은 불필요 (스프레드 콘텐츠 설계는 Out of Scope).

### SpreadLayout 수정 전략

`spread_layout.dart`의 exhaustive switch를 업데이트:

```dart
return switch (spreadType) {
  SpreadType.single => _buildSingleLayout(),
  SpreadType.threeCard => _buildThreeCardLayout(),
  SpreadType.custom => _buildGenericGridLayout(), // 새로 추가
};
```

generic 레이아웃은 `cards.length`를 기반으로 동적 배치 (Wrap, GridView 등).

---

## Q4. GoRouter redirect + async DB (UserSettings)

### 현재 GoRouter 구조

```dart
// app_router.dart
@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [ ... ],
  );
}
```

- `redirect` 미사용.
- GoRouter 14.8.1 (pubspec.lock 확인).

### GoRouter redirect의 async 제약

**GoRouter의 `redirect` 콜백은 동기(synchronous) 반환이 기본이다.**

```dart
// GoRouter API (v14.x)
GoRouter(
  redirect: (BuildContext context, GoRouterState state) {
    // 반환: String? (redirect 대상) 또는 null (그대로 진행)
    // 이 함수는 synchronous — Future를 반환할 수 없음
  },
);
```

그러나 **GoRouter 14.x는 `redirect`에서 `FutureOr<String?>`를 지원한다** — 즉 async redirect가 가능하다:

```dart
redirect: (context, state) async {
  final settings = await db.getUserSettings();
  if (settings.quickDrawEnabled) return '/draw';
  return null;
},
```

### 문제: 매 네비게이션마다 DB 쿼리

`redirect`는 **모든 라우트 전환 시** 호출된다. 매번 DB 쿼리를 실행하면:
- 라우트 전환 시 미세 지연 (Drift SQLite는 빠르지만, 여전히 async).
- 불필요한 반복 쿼리.

### 추천 접근법: Riverpod 캐시 + refreshListenable

**핵심 전략: UserSettings를 Riverpod provider로 캐싱하고, GoRouter에서는 캐시된 값만 읽는다.**

```dart
@riverpod
GoRouter appRouter(AppRouterRef ref) {
  // UserSettings provider를 watch — 값 변경 시 GoRouter 재평가
  final settings = ref.watch(userSettingsProvider).valueOrNull;

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // settings가 아직 로딩 중이면 redirect 안 함 (홈으로)
      if (settings == null) return null;

      // 루트 경로 접근 시에만 redirect 판단
      if (state.matchedLocation == '/') {
        if (settings.quickDrawEnabled) {
          return switch (settings.experienceLevel) {
            1 || 2 => '/draw',
            3 => '/shuffle/${settings.selectedDeckId}',
            _ => null,
          };
        }
      }
      return null;
    },
    routes: [ ... ],
  );
}
```

**장점:**
1. **redirect가 동기**: `ref.watch()`는 이미 캐시된 값을 반환하므로 async 불필요.
2. **reactive**: UserSettings가 변경되면 `ref.watch`가 provider를 invalidate → GoRouter 재생성 → 새 redirect 규칙 적용.
3. **refreshListenable 불필요**: Riverpod의 `ref.watch` 패턴이 GoRouter 재생성을 처리하므로 `GoRouter.refreshListenable` 패턴이 필요 없음.
4. **초기 로딩 처리**: `settings == null` (DB 로딩 중)이면 홈 표시 → 로딩 완료 시 GoRouter가 재생성되면서 redirect 재평가.

### 대안: refreshListenable 패턴 (불필요)

```dart
final notifier = ref.watch(userSettingsChangeNotifierProvider);
GoRouter(
  refreshListenable: notifier,
  redirect: ...,
);
```

이 패턴은 GoRouter가 Riverpod 바깥에서 생성될 때 유용하지만, 현재 코드에서는 GoRouter 자체가 `@riverpod` provider이므로 `ref.watch`만으로 충분하다.

### 주의사항

- **앱 첫 실행 시**: UserSettings 테이블이 비어있으므로, provider는 기본값(quickDrawEnabled=false)을 반환해야 함. 이는 DAO의 "없으면 기본값 INSERT" 패턴으로 처리.
- **redirect 범위 한정**: `state.matchedLocation == '/'`일 때만 redirect 판단. 다른 경로에서는 redirect하지 않음 (무한 redirect 방지).
- **GoRouter 재생성 비용**: `ref.watch`로 GoRouter가 재생성되면 현재 라우트 스택이 초기화될 수 있음. 이를 방지하려면 `GoRouter`를 `@Riverpod(keepAlive: true)`로 유지하고, redirect 로직만 업데이트하는 방식 고려. 또는 설정 변경 시 명시적 `context.go('/')`로 홈 경유를 유도.

---

## 종합 요약 및 Plan 가이드

| 질문 | 판단 | 핵심 근거 |
|------|------|----------|
| Q1. "+1" 기술 기반 | **충분** | `ShuffleResult.cards`가 전체 덱(78/64장)을 보유, `ShuffleState`가 keepAlive |
| Q2. Drift migration v2 | **표준 패턴** | `onUpgrade` + `createTable` — 기존 데이터 영향 없음 |
| Q3. SpreadType 확장 | **enum 유지 + custom 추가** | 최소 파괴, DB 호환, sealed class는 과도 |
| Q4. GoRouter async redirect | **Riverpod 캐시 패턴** | `ref.watch(userSettingsProvider)` → 동기 redirect, refreshListenable 불필요 |

### Cycle 1 Plan 권고 사항

1. **UserSettings 테이블 + DAO + migration v2** 먼저 구현 (다른 모든 것의 기반).
2. **SpreadType에 `custom` variant 추가** — SpreadLayout에 generic 레이아웃 분기.
3. **DeckMetadata에 `supportedDrawModes` 추가** — Brief MA-3 대응.
4. **UserSettings 엔티티(Freezed) + Repository + Riverpod Provider** — reactive Stream.
5. **코드 생성 재실행** 필수 (`build_runner`): Freezed, Riverpod codegen, Drift codegen.

### 리스크

- **SpreadType `custom`의 positions/guidances**: 빈 리스트로 두면 ReadingPage의 `_spreadType.positions[i]` 접근 시 IndexError. → `custom`일 때는 generic 텍스트를 동적 생성하는 getter 또는 별도 로직 필요.
- **GoRouter 재생성 시 라우트 스택 초기화**: 설정 변경 빈도가 낮으므로 실질적 문제는 아니지만, 설정 페이지 내부에서 변경 후 뒤로 가기 시 스택이 사라질 수 있음. 설정 변경 후 명시적 홈 이동으로 완화.

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
