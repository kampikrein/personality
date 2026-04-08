---
id: "006"
title: "Flutter 앱 아키텍처 & 프로젝트 구조 조사"
category: agent
status: archived
created: 2026-03-15
summary: >
  Flutter Clean Architecture, 상태 관리, 프로젝트 구조, 테스트 전략 비교 조사.
  Riverpod 3.0 + Clean Architecture(feature-first hybrid) + get_it/injectable DI를 권장.
  카드 애니메이션은 게임 루프(Ticker/CustomPainter) 방식, 앱 상태는 Riverpod 이원화 전략.
keywords: [agent-report, architecture, clean-architecture, riverpod, bloc, flutter, testing]
modules: [mobile]
---

# Flutter 앱 아키텍처 & 프로젝트 구조 조사

## Progress
### Completed
- [x] Clean Architecture 구현 패턴 조사
- [x] 상태 관리 비교 (Riverpod vs BLoC vs GetX)
- [x] 프로젝트 폴더 구조 조사
- [x] 테스트 전략 조사
### Remaining
(없음)
### Current Status
조사 완료. 전 항목 아카이브.

---

## Summary

본 프로젝트(타로 셔플 앱)에 적합한 Flutter 아키텍처 스택을 종합 조사했다.

| 영역 | 권장안 | 근거 |
|------|--------|------|
| 아키텍처 패턴 | Clean Architecture 3계층 | PRD 명시, 관심사 분리, 테스트 용이성 |
| 상태 관리 | **Riverpod 3.0** (앱 상태) + **Ticker/CustomPainter** (애니메이션) | 78장 카드 개별 상태의 60fps 렌더링에는 리액티브 스트림이 아닌 게임 루프 필요 |
| 프로젝트 구조 | **Feature-first hybrid** (feature 내부에 data/domain/presentation) | 대규모 앱에서의 확장성, 모듈 독립성 |
| DI | **get_it + injectable** | 코드 생성 기반 자동 등록, 환경별 설정 |
| 라우팅 | **go_router** | Google 공식 지원, 딥링크, 웹 호환 |
| 테스트 | 단위(mocktail) + 위젯 + Golden(Alchemist) + 통합 | 테스트 피라미드 원칙 |
| 모듈화 | Dart 패키지 분리 (셔플 엔진, 덱 빌더, 리딩 뷰어) + Melos | 독립 빌드/테스트, 팀 확장 대비 |

---

## Details

### 1. Clean Architecture 구현

#### 1.1 3계층 구조

```
┌─────────────────────────────────┐
│     Presentation Layer          │  ← Flutter Widgets, ViewModels
│  (UI, 제스처 입력, 카드 렌더링)     │
├─────────────────────────────────┤
│       Domain Layer              │  ← Use Cases, Entities, Repository 인터페이스
│  (셔플 엔진, 드로우 매니저, 덱 빌더) │
├─────────────────────────────────┤
│         Data Layer              │  ← Repository 구현체, Data Sources, Models
│  (로컬 DB, JSON 직렬화, 파일 I/O)  │
└─────────────────────────────────┘
```

**의존성 규칙**: 안쪽 계층은 바깥 계층을 모른다.
- Domain Layer는 Data/Presentation을 import하지 않는다.
- Data Layer는 Domain의 Repository 인터페이스를 구현하되, Domain의 Entity를 반환한다.
- Presentation Layer는 Domain의 Use Case를 호출하되, Data Layer를 직접 참조하지 않는다.

#### 1.2 Use Case 패턴

각 비즈니스 동작을 단일 책임의 Use Case 클래스로 캡슐화한다.

```dart
// domain/usecases/shuffle_deck_usecase.dart
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class ShuffleDeckUseCase implements UseCase<Deck, ShuffleParams> {
  final DeckRepository _repository;
  final ShuffleStrategy _strategy;

  ShuffleDeckUseCase(this._repository, this._strategy);

  @override
  Future<Either<Failure, Deck>> call(ShuffleParams params) async {
    final deck = await _repository.getDeck(params.deckId);
    return deck.map((d) => _strategy.shuffle(d, params.seed));
  }
}
```

PRD 기반 핵심 Use Case 목록:
- `ShuffleDeckUseCase` — 선택된 전략으로 덱 셔플
- `DrawCardUseCase` — 셔플된 덱에서 N장 드로우
- `CreateDeckUseCase` — 커스텀 덱 생성/저장
- `LoadSpreadUseCase` — 스프레드 레이아웃 로딩
- `SaveReadingUseCase` — 리딩 결과 스냅샷 저장

#### 1.3 Repository 패턴

```dart
// domain/repositories/deck_repository.dart (Domain Layer — 추상화)
abstract class DeckRepository {
  Future<Either<Failure, Deck>> getDeck(String deckId);
  Future<Either<Failure, List<Deck>>> getAllDecks();
  Future<Either<Failure, void>> saveDeck(Deck deck);
  Future<Either<Failure, void>> deleteDeck(String deckId);
}

// data/repositories/deck_repository_impl.dart (Data Layer — 구현체)
class DeckRepositoryImpl implements DeckRepository {
  final DeckLocalDataSource _localDataSource;

  DeckRepositoryImpl(this._localDataSource);

  @override
  Future<Either<Failure, Deck>> getDeck(String deckId) async {
    try {
      final model = await _localDataSource.getDeckById(deckId);
      return Right(model.toEntity()); // Model → Entity 변환
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
```

#### 1.4 Entity vs Model 분리

| 구분 | Entity (Domain Layer) | Model (Data Layer) |
|------|----------------------|-------------------|
| 위치 | `domain/entities/` | `data/models/` |
| 역할 | 비즈니스 규칙 표현 | 직렬화/역직렬화 담당 |
| 의존성 | 순수 Dart, 외부 패키지 없음 | json_serializable, freezed 등 |
| 예시 | `Card` (id, name, meanings) | `CardModel` (fromJson, toJson, toEntity) |

```dart
// domain/entities/card.dart
class Card {
  final String id;
  final String name;
  final String? imageUrl;
  final CardMeanings meanings;
  final bool isReversed;

  const Card({...});
}

// data/models/card_model.dart
@freezed
class CardModel with _$CardModel {
  const factory CardModel({
    required String id,
    required String name,
    String? imageUrl,
    CardMeaningsModel? meanings,
  }) = _CardModel;

  factory CardModel.fromJson(Map<String, dynamic> json) =>
      _$CardModelFromJson(json);
}

extension CardModelX on CardModel {
  Card toEntity() => Card(
        id: id,
        name: name,
        imageUrl: imageUrl,
        meanings: meanings?.toEntity() ?? CardMeanings.empty(),
        isReversed: false,
      );
}
```

#### 1.5 Strategy Pattern — 셔플 알고리즘

PRD가 명시한 3가지 셔플 방식을 Strategy Pattern으로 구현한다.

```dart
// domain/strategies/shuffle_strategy.dart
abstract class ShuffleStrategy {
  /// 덱의 카드 목록을 셔플하여 새 순서를 반환한다.
  /// [seed]는 CSPRNG + 센서 엔트로피에서 생성된 시드.
  List<Card> shuffle(List<Card> cards, int seed);

  /// 셔플 유형 식별자
  String get strategyName;
}

// domain/strategies/riffle_shuffle_strategy.dart
class RiffleShuffleStrategy implements ShuffleStrategy {
  @override
  String get strategyName => 'riffle';

  @override
  List<Card> shuffle(List<Card> cards, int seed) {
    final rng = Random(seed);
    final mid = cards.length ~/ 2;
    final left = cards.sublist(0, mid);
    final right = cards.sublist(mid);
    final result = <Card>[];

    int l = 0, r = 0;
    while (l < left.length && r < right.length) {
      // 리플 셔플: 양쪽에서 1~3장씩 교대로 끼워 넣음
      final takeLeft = rng.nextInt(3) + 1;
      final takeRight = rng.nextInt(3) + 1;
      result.addAll(left.skip(l).take(takeLeft));
      l += takeLeft;
      result.addAll(right.skip(r).take(takeRight));
      r += takeRight;
    }
    result.addAll(left.skip(l));
    result.addAll(right.skip(r));
    return result;
  }
}

// domain/strategies/overhand_shuffle_strategy.dart
class OverhandShuffleStrategy implements ShuffleStrategy {
  @override
  String get strategyName => 'overhand';

  @override
  List<Card> shuffle(List<Card> cards, int seed) {
    final rng = Random(seed);
    final result = List<Card>.from(cards);
    // 5~10회 반복: 상단에서 랜덤 청크를 떼어 하단에 쌓음
    final iterations = rng.nextInt(6) + 5;
    for (int i = 0; i < iterations; i++) {
      final chunkSize = rng.nextInt(cards.length ~/ 4) + 1;
      final chunk = result.sublist(0, chunkSize);
      result.removeRange(0, chunkSize);
      result.addAll(chunk);
    }
    return result;
  }
}

// domain/strategies/wash_shuffle_strategy.dart
class WashShuffleStrategy implements ShuffleStrategy {
  @override
  String get strategyName => 'wash';

  @override
  List<Card> shuffle(List<Card> cards, int seed) {
    // Fisher-Yates 완전 무작위 셔플 (워시/메시 파일)
    final rng = Random(seed);
    final result = List<Card>.from(cards);
    for (int i = result.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final temp = result[i];
      result[i] = result[j];
      result[j] = temp;
    }
    return result;
  }
}
```

**런타임 교체 메커니즘**:
```dart
// domain/services/shuffle_service.dart
class ShuffleService {
  ShuffleStrategy _currentStrategy;

  ShuffleService(this._currentStrategy);

  void setStrategy(ShuffleStrategy strategy) {
    _currentStrategy = strategy;
  }

  List<Card> executeShuffle(List<Card> cards, int seed) {
    return _currentStrategy.shuffle(cards, seed);
  }
}
```

#### 1.6 Factory Pattern — 카드 다형성

PRD 요구사항: `BaseCard -> TarotCard, OracleCard, CustomCard` 다형성.

```dart
// domain/entities/base_card.dart
sealed class BaseCard {
  final String id;
  final String name;
  final String imageUrl;
  final double x;
  final double y;
  final int zIndex;
  final double rotation;
  final bool isFaceUp;
  final bool isReversed;

  const BaseCard({...});
}

// domain/entities/tarot_card.dart
class TarotCard extends BaseCard {
  final Arcana arcana;       // major / minor
  final Suit? suit;          // wands, cups, swords, pentacles
  final int? number;         // 0-21 (major), 1-14 (minor)
  final CardMeanings meanings;

  const TarotCard({...});
}

// domain/entities/oracle_card.dart
class OracleCard extends BaseCard {
  final String? category;
  final List<String> keywords;
  final String? customNotes;

  const OracleCard({...});
}

// domain/entities/custom_card.dart
class CustomCard extends BaseCard {
  final Map<String, dynamic> metadata;  // 자유 형식

  const CustomCard({...});
}
```

Dart 3의 `sealed class`를 사용하면 패턴 매칭에서 exhaustive check가 가능하다:

```dart
String getCardDescription(BaseCard card) => switch (card) {
  TarotCard(:final arcana, :final suit) =>
    '${arcana.name} ${suit?.name ?? ""} tarot card',
  OracleCard(:final category) =>
    'Oracle card: ${category ?? "uncategorized"}',
  CustomCard(:final metadata) =>
    'Custom card: ${metadata["title"] ?? "unnamed"}',
};
```

**Factory 구현**:
```dart
class CardFactory {
  static BaseCard create(Map<String, dynamic> json, DeckType deckType) {
    return switch (deckType) {
      DeckType.tarot => TarotCard.fromMap(json),
      DeckType.oracle => OracleCard.fromMap(json),
      DeckType.custom => CustomCard.fromMap(json),
    };
  }
}
```

---

### 2. 상태 관리 비교

#### 2.1 Riverpod 3.0

**장점**:
- 위젯 트리 독립: Provider가 글로벌하게 선언되어 어디서든 접근 가능
- 컴파일 타임 안전성: 존재하지 않는 Provider 참조 시 컴파일 에러
- `@riverpod` 코드 생성으로 보일러플레이트 최소화
- 뛰어난 테스트 용이성: `ProviderContainer`로 격리 테스트
- **Riverpod 3.0 신기능 (2025.09)**: 오프라인 퍼시스턴스, Pause/Resume 리스너, 제네릭 타입, Mutation 지원, 통합 Ref API

**사용 적합 영역**: 앱 레벨 상태 (현재 선택된 덱, 셔플 전략, 리딩 히스토리, 사용자 설정)

```dart
@riverpod
class CurrentDeck extends _$CurrentDeck {
  @override
  Future<Deck> build() => ref.read(deckRepositoryProvider).getDefaultDeck();

  Future<void> selectDeck(String deckId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(deckRepositoryProvider).getDeck(deckId),
    );
  }
}

@riverpod
ShuffleStrategy currentShuffleStrategy(Ref ref) {
  final type = ref.watch(shuffleTypeProvider);
  return switch (type) {
    ShuffleType.riffle => RiffleShuffleStrategy(),
    ShuffleType.overhand => OverhandShuffleStrategy(),
    ShuffleType.wash => WashShuffleStrategy(),
  };
}
```

#### 2.2 flutter_bloc

**장점**:
- 엄격한 이벤트 → 상태 단방향 흐름: 상태 변이 추적 용이
- DevTools 지원 우수: 시간 여행 디버깅
- 대규모 팀에서의 일관성 보장
- 감사 추적(audit trail) 필요 시 유리

**단점**:
- 보일러플레이트가 Riverpod 대비 상당히 많음 (Event 클래스, State 클래스, Bloc 클래스)
- 78장 카드 각각의 미세 상태 변경에 대해 이벤트를 발행하면 오버헤드 발생
- 카드 애니메이션(60fps)에는 부적합 — 매 프레임마다 이벤트를 발행하는 것은 비현실적

**적합 영역**: 규제 산업(금융, 의료) 앱, 엄격한 상태 추적이 필요한 엔터프라이즈 앱

#### 2.3 GetX — 비추천 근거

| 문제 | 상세 |
|------|------|
| 아키텍처 강제력 부재 | 구조를 강제하지 않아 API 호출이 컨트롤러나 위젯에 침투 |
| 유지보수 위기 | 메인 레포지토리 장기 비활성, GetX 5.0이 2023년부터 RC 단계 정체 |
| 테스트 어려움 | `Get.find()` + 글로벌 싱글톤 = 테스트 격리 곤란 |
| 메모리 누수 | 컨트롤러의 예기치 않은 dispose, cleanup 실패 시 메모리 누수 |
| 생태계 분열 | "Refreshed" 등 커뮤니티 포크가 생태계를 분열시킴 |
| 버스 팩터 | 단일 주 메인테이너 의존 → 프로젝트 지속성 위험 |

**결론**: 2026년 기준 신규 프로젝트에 GetX를 채택해서는 안 된다.

#### 2.4 핵심 질문: 78장 카드 개별 상태 60fps 관리

**답변: 이원화 전략 (Dual-layer state management)**

리액티브 상태 관리(Riverpod/BLoC)는 매 프레임(16.67ms) 간격으로 78개 객체의 위치/회전/Z-index를 업데이트하는 데 적합하지 않다. 리액티브 스트림은 노티파이 → 빌드 → 레이아웃 → 페인트의 전체 파이프라인을 타기 때문이다.

```
┌──────────────────────────────────────────────────────────┐
│                    앱 상태 (Riverpod)                      │
│  현재 덱, 셔플 전략, 사용자 설정, 리딩 히스토리              │
│  → 변경 빈도 낮음, 리액티브 스트림 적합                      │
├──────────────────────────────────────────────────────────┤
│                 애니메이션 상태 (Game Loop)                  │
│  78장 카드의 x, y, z, rotation, faceUp, reversed          │
│  → 60fps(16.67ms/frame), Ticker + CustomPainter 직접 제어 │
│  → Riverpod/BLoC를 경유하지 않음                            │
└──────────────────────────────────────────────────────────┘
```

**게임 루프 방식 구현**:
```dart
class CardAnimationController with TickerProviderStateMixin {
  late final Ticker _ticker;
  final List<CardState> cardStates; // 78장 개별 상태

  void start() {
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    for (final card in cardStates) {
      card.updatePosition(elapsed); // 물리 연산
    }
    // CustomPainter에 repaint 시그널 → build/layout 스킵
    _repaintNotifier.notifyListeners();
  }
}
```

**CustomPainter + Listenable 패턴**:
```dart
class CardTablePainter extends CustomPainter {
  final List<CardState> cardStates;

  CardTablePainter(this.cardStates, {required Listenable repaint})
      : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    // Z-index 순으로 정렬 후 각 카드 직접 렌더링
    final sorted = [...cardStates]..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    for (final card in sorted) {
      canvas.save();
      canvas.translate(card.x, card.y);
      canvas.rotate(card.rotation);
      // 카드 이미지 그리기 (캐싱된 ui.Image 사용)
      canvas.drawImage(card.cachedImage, Offset.zero, Paint());
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CardTablePainter old) => true;
  // repaint Listenable이 트리거하므로 shouldRepaint는 항상 true
}
```

이 방식이 리액티브 스트림 대비 우월한 이유:
1. **build/layout 스킵**: CustomPainter의 `repaint` Listenable은 위젯 트리 재빌드 없이 paint만 호출
2. **배치 업데이트**: 78장을 한 번의 paint 호출에서 모두 처리
3. **GC 압력 최소화**: 매 프레임마다 새 State 객체를 생성하지 않음 (mutable state)
4. **Vsync 동기화**: Ticker가 디스플레이 vsync에 자동 동기화 → 정확한 60fps

**Flame 엔진 고려사항**:
- Flame은 게임 루프, 컴포넌트 시스템, 충돌 감지를 내장한 2D 게임 엔진
- 워시 셔플(카드 충돌 물리)에는 Forge2D(Box2D 포트)가 유용
- 단, Flame은 Flutter 위젯 생태계와의 통합이 제한적
- **권장**: 셔플 애니메이션 영역만 Flame의 `GameWidget`으로 임베드하고, 나머지 UI는 일반 Flutter 위젯으로 구성하는 하이브리드 접근

---

### 3. 프로젝트 폴더 구조

#### 3.1 Feature-first vs Layer-first

| 기준 | Layer-first | Feature-first |
|------|------------|---------------|
| 구조 | `lib/data/`, `lib/domain/`, `lib/presentation/` 하위에 모든 feature | `lib/features/shuffle/`, `lib/features/deck/` 하위에 각 layer |
| 장점 | 소규모 프로젝트에서 직관적 | 기능 단위 작업 가능, 파일 간 이동 최소 |
| 단점 | 기능 많아지면 layer 간 점프 빈번 | 초기 설정 비용, core/ 공유 코드 관리 필요 |
| 대규모 적합성 | 낮음 | 높음 |

**2025-2026 업계 합의**: Feature-first가 표준. 단, 각 feature 내부에 data/domain/presentation 서브디렉토리를 두는 **하이브리드 접근**이 최선.

#### 3.2 권장 폴더 구조

```
mobile/
├── lib/
│   ├── main.dart
│   ├── app.dart                          # MaterialApp 설정
│   ├── injection.dart                    # get_it DI 설정
│   │
│   ├── core/                             # 전역 공유 코드
│   │   ├── error/                        # Failure, Exception 클래스
│   │   │   ├── failures.dart
│   │   │   └── exceptions.dart
│   │   ├── usecases/                     # UseCase 베이스 클래스
│   │   │   └── usecase.dart
│   │   ├── theme/                        # 다크 모드 테마, 색상, 타이포그래피
│   │   │   ├── app_theme.dart
│   │   │   └── app_colors.dart
│   │   ├── constants/                    # 매직 넘버, 문자열 상수
│   │   ├── extensions/                   # Dart 확장 메서드
│   │   ├── utils/                        # 유틸리티 함수
│   │   └── widgets/                      # 공통 위젯 (카드 프레임 등)
│   │
│   ├── features/                         # 기능별 모듈
│   │   ├── shuffle/                      # 셔플 엔진 feature
│   │   │   ├── data/
│   │   │   │   ├── datasources/          # 센서, 난수 데이터 소스
│   │   │   │   ├── models/               # 셔플 결과 모델
│   │   │   │   └── repositories/         # ShuffleRepository 구현체
│   │   │   ├── domain/
│   │   │   │   ├── entities/             # ShuffleResult, Seed
│   │   │   │   ├── repositories/         # ShuffleRepository 인터페이스
│   │   │   │   ├── strategies/           # ShuffleStrategy + 3가지 구현체
│   │   │   │   └── usecases/             # ShuffleDeckUseCase
│   │   │   └── presentation/
│   │   │       ├── providers/            # Riverpod providers
│   │   │       ├── widgets/              # 셔플 UI 위젯
│   │   │       ├── painters/             # CardTablePainter (CustomPainter)
│   │   │       └── pages/               # ShufflePage
│   │   │
│   │   ├── deck/                         # 덱 관리 feature
│   │   │   ├── data/
│   │   │   │   ├── datasources/          # DeckLocalDataSource (DB)
│   │   │   │   ├── models/               # DeckModel, CardModel (JSON)
│   │   │   │   └── repositories/         # DeckRepository 구현체
│   │   │   ├── domain/
│   │   │   │   ├── entities/             # Deck, BaseCard, TarotCard...
│   │   │   │   ├── repositories/         # DeckRepository 인터페이스
│   │   │   │   ├── factories/            # CardFactory
│   │   │   │   └── usecases/             # CreateDeckUseCase, LoadDeckUseCase
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       ├── widgets/              # DeckGrid, CardTile, BulkUpload
│   │   │       └── pages/               # DeckListPage, DeckEditorPage
│   │   │
│   │   ├── reading/                      # 리딩/스프레드 feature
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   │   ├── entities/             # Spread, Reading, SpreadLayout
│   │   │   │   └── usecases/             # DrawCardUseCase, SaveReadingUseCase
│   │   │   └── presentation/
│   │   │       ├── widgets/              # SpreadView, CardFlip
│   │   │       └── pages/               # ReadingPage, HistoryPage
│   │   │
│   │   └── settings/                     # 설정 feature
│   │       ├── data/
│   │       ├── domain/
│   │       └── presentation/
│   │
│   └── routing/                          # go_router 설정
│       └── app_router.dart
│
├── test/                                 # 테스트 (lib/ 구조 미러링)
│   ├── features/
│   │   ├── shuffle/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── deck/
│   │   └── reading/
│   └── goldens/                          # Golden 테스트 이미지
│
├── integration_test/                     # 통합 테스트
│   └── shuffle_to_reading_test.dart
│
└── pubspec.yaml
```

#### 3.3 모듈화 전략: 독립 Dart 패키지

프로젝트가 성장하면 핵심 모듈을 독립 패키지로 분리할 수 있다.

```
mobile/
├── packages/
│   ├── shuffle_engine/               # 순수 Dart, Flutter 의존성 없음
│   │   ├── lib/
│   │   │   ├── src/
│   │   │   │   ├── strategies/
│   │   │   │   ├── models/
│   │   │   │   └── shuffle_engine.dart
│   │   │   └── shuffle_engine.dart   # public API
│   │   ├── test/
│   │   └── pubspec.yaml
│   │
│   ├── deck_core/                    # 덱/카드 도메인 모델
│   │   ├── lib/
│   │   └── pubspec.yaml
│   │
│   └── tarot_ui/                     # 공유 UI 컴포넌트
│       ├── lib/
│       └── pubspec.yaml
│
├── lib/                              # 메인 앱 (패키지들을 조합)
└── melos.yaml                        # Melos 모노레포 관리
```

**Melos** 도구를 사용하면 다중 패키지의 의존성 관리, 일괄 테스트, 버전 관리가 용이하다:
```yaml
# melos.yaml
name: tarot_app
packages:
  - packages/**
  - .
scripts:
  analyze: melos exec -- dart analyze
  test: melos exec -- flutter test
  coverage: melos exec -- flutter test --coverage
```

#### 3.4 의존성 주입 (DI): get_it + injectable

```dart
// injection.dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
void configureDependencies() => getIt.init();

// 사용 예시: 어노테이션으로 자동 등록
@lazySingleton
class DeckRepositoryImpl implements DeckRepository {
  final DeckLocalDataSource _dataSource;

  DeckRepositoryImpl(this._dataSource);
  // ...
}

@injectable
class ShuffleDeckUseCase {
  final DeckRepository _repository;

  ShuffleDeckUseCase(this._repository);
  // ...
}
```

`@Environment` 어노테이션으로 테스트/개발/프로덕션 환경별 다른 구현체를 주입할 수 있다.

#### 3.5 라우팅: go_router

```dart
final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomePage()),
    GoRoute(path: '/deck/:deckId', builder: (_, state) =>
      DeckDetailPage(deckId: state.pathParameters['deckId']!)),
    GoRoute(path: '/shuffle', builder: (_, __) => const ShufflePage()),
    GoRoute(path: '/reading', builder: (_, __) => const ReadingPage()),
    GoRoute(path: '/history', builder: (_, __) => const HistoryPage()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
  ],
);
```

go_router 선택 근거:
- Google Flutter 팀 공식 지원 패키지
- 선언적 라우팅, 딥링크 지원
- 향후 Flutter Web 전환 시 URL 기반 라우팅 호환
- auto_route도 타입 안전성이 우수하나, go_router의 커뮤니티/문서 규모가 압도적

---

### 4. 테스트 전략

#### 4.1 테스트 피라미드

```
           /\
          /  \
         / 통합 \         ← 셔플→드로우→스프레드 전체 흐름 (적음)
        /──────\
       / 위젯    \        ← 카드 플립, 스프레드 레이아웃 렌더링 (중간)
      /──────────\
     / Golden      \      ← 카드 이미지, UI 시각적 회귀 방지 (중간)
    /──────────────\
   /     단위         \    ← 셔플 알고리즘, 덱 빌더, Use Case (많음)
  /────────────────────\
```

#### 4.2 단위 테스트

**셔플 알고리즘 무작위성 검증**:
```dart
group('RiffleShuffleStrategy', () {
  test('같은 시드로 같은 결과를 반환한다 (결정론적 재현)', () {
    final strategy = RiffleShuffleStrategy();
    final cards = generateTestDeck(78);

    final result1 = strategy.shuffle(cards, 42);
    final result2 = strategy.shuffle(cards, 42);

    expect(result1, equals(result2));
  });

  test('다른 시드로 다른 결과를 반환한다', () {
    final strategy = RiffleShuffleStrategy();
    final cards = generateTestDeck(78);

    final result1 = strategy.shuffle(cards, 42);
    final result2 = strategy.shuffle(cards, 99);

    expect(result1, isNot(equals(result2)));
  });

  test('셔플 후 모든 카드가 보존된다 (카드 손실/중복 없음)', () {
    final strategy = RiffleShuffleStrategy();
    final cards = generateTestDeck(78);

    final result = strategy.shuffle(cards, 42);

    expect(result.length, equals(78));
    expect(result.toSet().length, equals(78));
  });

  test('통계적 균등 분포 검증 (chi-squared)', () {
    final strategy = RiffleShuffleStrategy();
    final cards = generateTestDeck(10);
    final positionCounts = List.generate(10, (_) => List.filled(10, 0));

    // 10,000회 셔플하여 각 카드가 각 위치에 오는 빈도 측정
    for (int seed = 0; seed < 10000; seed++) {
      final result = strategy.shuffle(cards, seed);
      for (int i = 0; i < result.length; i++) {
        positionCounts[cards.indexOf(result[i])][i]++;
      }
    }

    // 각 위치에 약 1,000회씩 출현해야 함 (허용 오차 +-15%)
    for (final row in positionCounts) {
      for (final count in row) {
        expect(count, greaterThan(850));
        expect(count, lessThan(1150));
      }
    }
  });
});
```

**Use Case 테스트** (mocktail 사용):
```dart
class MockDeckRepository extends Mock implements DeckRepository {}

group('ShuffleDeckUseCase', () {
  late ShuffleDeckUseCase useCase;
  late MockDeckRepository mockRepo;

  setUp(() {
    mockRepo = MockDeckRepository();
    useCase = ShuffleDeckUseCase(mockRepo, RiffleShuffleStrategy());
  });

  test('정상 셔플 시 Right(Deck)를 반환한다', () async {
    when(() => mockRepo.getDeck('deck-1'))
        .thenAnswer((_) async => Right(testDeck));

    final result = await useCase(ShuffleParams(deckId: 'deck-1', seed: 42));

    expect(result.isRight(), isTrue);
    verify(() => mockRepo.getDeck('deck-1')).called(1);
  });
});
```

#### 4.3 위젯 테스트

```dart
testWidgets('카드 플립 애니메이션이 올바르게 동작한다', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: CardFlipWidget(card: testTarotCard),
    ),
  );

  // 초기 상태: 뒷면
  expect(find.byKey(const Key('card-back')), findsOneWidget);
  expect(find.byKey(const Key('card-front')), findsNothing);

  // 탭하여 플립
  await tester.tap(find.byType(CardFlipWidget));
  await tester.pumpAndSettle(); // 애니메이션 완료 대기

  // 플립 후: 앞면
  expect(find.byKey(const Key('card-front')), findsOneWidget);
});

testWidgets('스프레드 레이아웃이 올바른 위치에 카드를 배치한다', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SpreadView(
        layout: SpreadLayout.celticCross,
        cards: generateTestCards(10),
      ),
    ),
  );

  // 10장의 카드가 모두 렌더링되었는지 확인
  expect(find.byType(CardWidget), findsNWidgets(10));
});
```

#### 4.4 Golden 테스트 (Alchemist)

```dart
// test/goldens/card_golden_test.dart
void main() {
  goldenTest(
    'TarotCard 렌더링 시각적 검증',
    fileName: 'tarot_card',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'face up - upright',
          child: TarotCardWidget(
            card: testCard.copyWith(isFaceUp: true, isReversed: false),
          ),
        ),
        GoldenTestScenario(
          name: 'face up - reversed',
          child: TarotCardWidget(
            card: testCard.copyWith(isFaceUp: true, isReversed: true),
          ),
        ),
        GoldenTestScenario(
          name: 'face down',
          child: TarotCardWidget(
            card: testCard.copyWith(isFaceUp: false),
          ),
        ),
      ],
    ),
  );
}
```

Alchemist는 플랫폼별(macOS/Linux/Windows) + CI용 두 세트의 골든 파일을 생성하여, 폰트 렌더링 차이로 인한 CI 실패를 방지한다.

#### 4.5 통합 테스트

```dart
// integration_test/shuffle_to_reading_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('셔플 → 드로우 → 스프레드 전체 흐름', (tester) async {
    await tester.pumpWidget(const MyApp());

    // 1. 덱 선택
    await tester.tap(find.text('Classic RWS'));
    await tester.pumpAndSettle();

    // 2. 셔플 방식 선택 (리플)
    await tester.tap(find.text('Riffle Shuffle'));
    await tester.pumpAndSettle();

    // 3. 셔플 실행
    await tester.tap(find.text('Start Shuffle'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // 4. 3장 드로우
    await tester.tap(find.text('Draw 3 Cards'));
    await tester.pumpAndSettle();

    // 5. 스프레드 확인
    expect(find.byType(CardFlipWidget), findsNWidgets(3));
    expect(find.text('Past'), findsOneWidget);
    expect(find.text('Present'), findsOneWidget);
    expect(find.text('Future'), findsOneWidget);
  });
}
```

#### 4.6 물리 엔진 테스트: 결정론적 재현

물리 시뮬레이션 테스트의 핵심은 **결정론적 재현 가능성**이다:
- 시드 고정: 모든 난수 생성기에 고정 시드 주입
- 시간 제어: `FakeAsync`로 시간 진행을 제어하여 물리 연산의 dt를 정확히 통제
- 센서 목업: 테스트 시 실제 센서 대신 `FakeSensorDataSource`를 DI로 주입

```dart
test('워시 셔플 물리 시뮬레이션이 결정론적으로 재현된다', () {
  fakeAsync((async) {
    final engine = WashShufflePhysicsEngine(seed: 42);
    engine.initCards(generateTestCards(78));

    // 1초간 시뮬레이션 (60 프레임)
    for (int i = 0; i < 60; i++) {
      engine.step(const Duration(milliseconds: 16));
      async.elapse(const Duration(milliseconds: 16));
    }

    final positions1 = engine.cardPositions;

    // 동일 시드로 재실행
    final engine2 = WashShufflePhysicsEngine(seed: 42);
    engine2.initCards(generateTestCards(78));
    for (int i = 0; i < 60; i++) {
      engine2.step(const Duration(milliseconds: 16));
    }

    expect(engine2.cardPositions, equals(positions1));
  });
});
```

#### 4.7 mocktail vs mockito 비교

| 기준 | mocktail | mockito |
|------|----------|---------|
| 코드 생성 | 불필요 | 필요 (`@GenerateMocks`) |
| Null Safety | 네이티브 지원 | 추가 설정 필요 |
| 문법 | 간결, 캐스케이드 연산자 활용 | 전통적 `when/thenReturn` |
| 인기도 | 258만+ 다운로드 (2026) | 178만+ 다운로드 |
| 작성자 | Felix Angelov (BLoC 작성자) | Dart 팀 |

**권장**: **mocktail**. 코드 생성 불필요, null-safety-first 설계, 간결한 문법.

---

## Key Findings

1. **이원화 상태 관리가 핵심**: 앱 상태(Riverpod)와 애니메이션 상태(Ticker/CustomPainter)를 분리해야 78장 카드의 60fps 렌더링이 가능하다. Riverpod/BLoC만으로 매 프레임 상태를 전파하면 심각한 성능 저하가 발생한다.

2. **Feature-first 하이브리드 구조가 업계 표준**: 2025-2026 기준 대규모 Flutter 앱의 사실상 표준. 각 feature(shuffle, deck, reading) 내부에 data/domain/presentation 계층을 두는 방식.

3. **Riverpod 3.0이 최적 선택**: 오프라인 퍼시스턴스, 컴파일 타임 안전성, 코드 생성, 테스트 용이성에서 BLoC보다 유리. GetX는 유지보수 위기로 배제.

4. **sealed class가 Factory Pattern을 강화**: Dart 3의 sealed class + 패턴 매칭으로 `BaseCard` 계층을 구현하면 exhaustive check가 가능하여 런타임 에러를 컴파일 타임에 잡을 수 있다.

5. **Golden 테스트가 카드 렌더링 QA에 필수**: 78장 카드 이미지의 시각적 회귀를 자동 감지. Alchemist 패키지가 CI 호환성 문제를 해결.

6. **독립 패키지 분리 시 Melos 필수**: shuffle_engine, deck_core를 독립 Dart 패키지로 분리하면 단독 테스트/빌드가 가능하고 팀 확장에 유리.

---

## Recommendations

### 즉시 적용 (MVP Phase 1)

| 결정 | 채택 | 비고 |
|------|------|------|
| 아키텍처 | Clean Architecture 3계층 | feature-first hybrid |
| 상태 관리 | Riverpod 3.0 | `@riverpod` 코드 생성 활용 |
| 애니메이션 상태 | Ticker + CustomPainter | Riverpod과 분리 |
| DI | get_it + injectable | `@lazySingleton`, `@injectable` |
| 라우팅 | go_router | 딥링크, 웹 호환 |
| 직렬화 | freezed + json_serializable | Model 클래스 코드 생성 |
| 카드 다형성 | sealed class + Factory | Dart 3 패턴 매칭 |
| 테스트 모킹 | mocktail | 코드 생성 불필요 |
| Golden 테스트 | Alchemist | CI 호환성 보장 |

### 향후 고려 (Phase 2+)

| 결정 | 시점 | 비고 |
|------|------|------|
| 패키지 분리 | 코드 3,000줄+ 시 | shuffle_engine, deck_core 독립 패키지화 |
| Melos 도입 | 패키지 2개+ 시 | 다중 패키지 일괄 관리 |
| Flame 임베딩 | 워시 셔플 구현 시 | Forge2D 물리 충돌 처리 전용 |
| BLoC 부분 도입 | 커뮤니티/바운티 시스템 구현 시 | 트랜잭션 추적이 중요한 영역 |

### pubspec.yaml 핵심 의존성 (권장)

```yaml
dependencies:
  flutter:
    sdk: flutter
  # State Management
  flutter_riverpod: ^3.0.0
  riverpod_annotation: ^3.0.0
  # DI
  get_it: ^8.0.0
  injectable: ^2.5.0
  # Routing
  go_router: ^14.0.0
  # Serialization
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0
  # Functional Programming
  fpdart: ^1.1.0           # Either, Option 타입
  # UI
  flutter_animate: ^4.5.0  # 선언적 애니메이션 유틸

dev_dependencies:
  flutter_test:
    sdk: flutter
  # Code Generation
  build_runner: ^2.4.0
  riverpod_generator: ^3.0.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  injectable_generator: ^2.6.0
  # Testing
  mocktail: ^1.0.0
  alchemist: ^0.10.0       # Golden 테스트
```

---

## References

### Clean Architecture
- [Clean Architecture in Flutter - Complete Guide 2025](https://coding-studio.com/clean-architecture-in-flutter-a-complete-guide-with-code-examples-2025-edition/)
- [Flutter Clean Architecture 2025 - Beginner to Pro](https://medium.com/@notesapp555/mastering-flutter-clean-architecture-in-2025-a-beginner-to-pro-guide-for-scalable-app-development-d87a3995408e)
- [Clean Architecture Explored - Codemagic](https://blog.codemagic.io/clean-architecture-explored/)
- [Entity vs Model in Clean Architecture](https://dev.to/yusufhnf/understanding-clean-architecture-models-vs-entities-in-flutter-applications-1pm5)
- [Repository Pattern in Flutter](https://medium.com/ayt-technologies/flutter-clean-architecture-repository-pattern-df418968c731)
- [Flutter Official Architecture Recommendations](https://docs.flutter.dev/app-architecture/recommendations)

### 상태 관리
- [Riverpod 3.0 What's New](https://riverpod.dev/docs/whats_new)
- [Riverpod vs BLoC 2026 Comparison](https://medium.com/@flutter-app/state-management-in-2026-is-riverpod-replacing-bloc-40e58adcb70f)
- [Flutter State Management 2026 Complete Guide](https://foresightmobile.com/blog/best-flutter-state-management)
- [Riverpod vs BLoC vs Signals 2025](https://nurobyte.medium.com/flutter-state-management-in-2025-riverpod-vs-bloc-vs-signals-8569cbbef26f)
- [Riverpod 2.0 Ultimate Guide - Andrea Bizzotto](https://codewithandrea.com/articles/flutter-state-management-riverpod/)
- [GetX Scalability Problems](https://medium.com/@mdriazofficial/building-scalable-flutter-apps-with-getx-lessons-pitfalls-and-fixes-f426c8eda11a)

### 프로젝트 구조
- [Feature-first vs Layer-first - Andrea Bizzotto](https://codewithandrea.com/articles/flutter-project-structure/)
- [Flutter Folder Structure Best Practices 2025](https://www.pravux.com/best-practices-for-folder-structure-in-large-flutter-projects-2025-guide/)
- [Feature-first Architecture for Scalable Development](https://dev.to/princetomarappdev/mastering-flutter-architecture-from-clean-to-feature-first-for-faster-scalable-development-4605)
- [Modularization with Packages](https://thiele.dev/blog/modularization-of-flutter-apps-with-packages-for-growing-teams/)
- [Multi-package Architecture in Flutter](https://rodrigolmti.medium.com/building-a-multi-package-project-with-flutter-6c547d18abd5)

### Design Patterns
- [Strategy Pattern in Dart - Flutter Community](https://medium.com/flutter-community/design-patterns-strategy-pattern-in-dart-7c833812d58d)
- [Strategy Pattern in Dart - Detailed Guide](https://medium.com/@shouaibmoha247/mastering-design-patterns-in-dart-strategy-design-pattern-6d022579d54f)
- [Factory Pattern in Flutter - freeCodeCamp](https://www.freecodecamp.org/news/how-the-factory-and-abstract-factory-design-patterns-work-in-flutter/)
- [Sealed Classes in Dart](https://medium.com/@d3xvn/using-sealed-classes-and-pattern-matching-in-dart-89c2fe22901c)
- [Flutter Architecture Design Patterns - Official](https://docs.flutter.dev/app-architecture/design-patterns)

### DI & 라우팅
- [get_it + injectable Setup](https://blog.logrocket.com/dependency-injection-flutter-using-getit-injectable/)
- [injectable Package](https://pub.dev/packages/injectable)
- [Flutter DI - Official Docs](https://docs.flutter.dev/app-architecture/case-study/dependency-injection)
- [go_router vs auto_route](https://8thlight.com/insights/flutter-navigation-is-gorouter-still-the-best-choice)

### 테스트
- [Flutter Testing Overview - Official](https://docs.flutter.dev/testing/overview)
- [Flutter App Testing Guide 2025](https://solguruz.com/blog/flutter-app-testing/)
- [Golden Testing with Alchemist](https://www.verygood.ventures/blog/alchemist-golden-tests-tutorial)
- [Alchemist GitHub](https://github.com/Betterment/alchemist)
- [mocktail GitHub](https://github.com/felangel/mocktail)
- [Navigating Hard Parts of Testing in Flutter](https://dcm.dev/blog/2025/07/30/navigating-hard-parts-testing-flutter-developers)

### 성능 & 게임 아키텍처
- [Flutter Performance Best Practices - Official](https://docs.flutter.dev/perf/best-practices)
- [Achieving 60fps in Flutter](https://www.dectac.com/blog/how-to-optimize-performance-in-flutter-apps-tips-for-60fps)
- [Flame Engine](https://docs.flame-engine.org/)
- [Benchmarking Flutter, Flame, Unity, Godot](https://filiph.net/text/benchmarking-flutter-flame-unity-godot.html)
- [High-Performance Canvas Rendering](https://plugfox.dev/high-performance-canvas-rendering/)
- [Flutter Casual Games Toolkit](https://docs.flutter.dev/resources/games-toolkit)
- [Flutter Card Game Development](https://medium.com/@krishanvijaybr/why-flutter-is-a-smart-choice-for-card-game-development-3bd363ad0e29)

### PRD & 프로젝트 문서
- `docs/003_gemini_deep_research.md` — 타로 앱 PRD (제품 요구사항 정의서)
- `docs/11_tarot_shuffle/001_Scope_platform_strategy.md` — 플랫폼 전략
- `docs/11_tarot_shuffle/002_Research_tarot_shuffle_tech.md` — 기술 스택 연구 개요

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
