---
id: "012"
type: plan
title: "Phase 3 — 프레젠테이션 + 라우팅 통합"
created: 2026-03-15
phase: 3
parent: "009"
depends_on: ["010", "011"]
parallel_with: []
traces_scope: "001"
traces_research: "008"
summary: >
  go_router 라우팅, 홈/덱선택/셔플/리딩 4개 페이지, CardPainter(CustomPainter),
  리플 애니메이션, 엔트로피 진행률, 1장/3장 스프레드 레이아웃, Riverpod providers.
  이원화 상태 관리(Riverpod + Ticker/CustomPainter) 구현.
keywords: [presentation, routing, card-painter, animation, spread, riverpod, go-router]
---

# 012 — Phase 3: 프레젠테이션 + 라우팅 통합

## Goal

Phase 1(데이터) + Phase 2(엔진)를 UI로 통합하여 완전한 MVP 흐름을 완성한다: 홈 → 덱 선택 → 셔플(센서 수집 + 리플 애니메이션) → 리딩(카드 뒤집기 + 스프레드 배치). Research(008-F1)의 이원화 상태 관리 패턴을 적용.

## Scope

### Included
| # | Item | Description |
|---|------|-------------|
| 1 | go_router | 4개 화면 라우팅 (/, /deck, /shuffle, /reading) |
| 2 | HomePage | 네비게이션 허브, 최근 리딩 목록 |
| 3 | DeckSelectionPage | 덱 목록 + 선택 |
| 4 | ShufflePage | 엔트로피 수집 → 셔플 애니메이션 → 드로우 |
| 5 | CardPainter | CustomPainter 기반 카드 렌더링 (60fps) |
| 6 | RiffleAnimationController | 리플 셔플 애니메이션 상태 (Ticker 기반) |
| 7 | EntropyProgressIndicator | 센서 엔트로피 수집 진행률 시각화 |
| 8 | ReadingPage | 스프레드 배치 + 카드 뒤집기 |
| 9 | SpreadLayout | 1장/3장 스프레드 배치 위젯 |
| 10 | CardRevealWidget | 카드 뒤집기 3D 애니메이션 |
| 11 | Riverpod Providers | Deck, Shuffle, Reading 각 feature의 상태 관리 |
| 12 | main.dart 라우터 연결 | MaterialApp → MaterialApp.router |

### Excluded
| Item | Reason/Timeline |
|------|-----------------|
| 워시 셔플 GameWidget | Phase 2+ (Flame 도입) |
| 켈틱 크로스 레이아웃 | Phase 2+ |
| 실제 카드 이미지 | 저작권 확인 후 |
| 설정 페이지 | Phase 2+ |

## Structural Decisions

> No additional structural decisions required — all resolved in checkpoint (009).

---

## File Change Summary

### Modified Files
| # | File Path | Change Description |
|---|-----------|-------------------|
| 1 | mobile/lib/main.dart | MaterialApp → MaterialApp.router, 라우터 연결 |

### New Files
| # | File Path | Description |
|---|-----------|-------------|
| 1 | mobile/lib/core/router/app_router.dart | go_router 라우트 정의 |
| 2 | mobile/lib/features/home/presentation/pages/home_page.dart | 홈 화면 |
| 3 | mobile/lib/features/deck/presentation/pages/deck_selection_page.dart | 덱 선택 화면 |
| 4 | mobile/lib/features/deck/presentation/providers/deck_providers.dart | Deck @riverpod |
| 5 | mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart | 셔플 화면 (메인) |
| 6 | mobile/lib/features/shuffle/presentation/widgets/card_painter.dart | CustomPainter |
| 7 | mobile/lib/features/shuffle/presentation/widgets/riffle_animation_controller.dart | 애니메이션 상태 |
| 8 | mobile/lib/features/shuffle/presentation/widgets/entropy_progress_indicator.dart | 엔트로피 진행률 |
| 9 | mobile/lib/features/shuffle/presentation/providers/shuffle_providers.dart | Shuffle @riverpod |
| 10 | mobile/lib/features/reading/presentation/pages/reading_page.dart | 리딩 화면 |
| 11 | mobile/lib/features/reading/presentation/widgets/spread_layout.dart | 스프레드 배치 |
| 12 | mobile/lib/features/reading/presentation/widgets/card_reveal_widget.dart | 카드 뒤집기 |
| 13 | mobile/lib/features/reading/presentation/providers/reading_providers.dart | Reading @riverpod |

---

## Step 1 — go_router 라우팅

### Approach
4개 화면을 선언적 라우트로 정의. Riverpod Provider로 라우터를 제공하여 앱 전역에서 접근 가능.

### After Code
```dart
// mobile/lib/core/router/app_router.dart (new)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/deck/presentation/pages/deck_selection_page.dart';
import '../../features/shuffle/presentation/pages/shuffle_page.dart';
import '../../features/reading/presentation/pages/reading_page.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/deck',
        name: 'deck',
        builder: (context, state) => const DeckSelectionPage(),
      ),
      GoRoute(
        path: '/shuffle/:deckId',
        name: 'shuffle',
        builder: (context, state) {
          final deckId = state.pathParameters['deckId']!;
          return ShufflePage(deckId: deckId);
        },
      ),
      GoRoute(
        path: '/reading/:deckId',
        name: 'reading',
        builder: (context, state) {
          final deckId = state.pathParameters['deckId']!;
          return ReadingPage(deckId: deckId);
        },
      ),
    ],
  );
}
```

### Considerations
- `shuffle/:deckId`: 덱 ID를 path parameter로 전달
- reading도 deckId를 받아 어떤 덱에서 뽑았는지 추적
- ShuffleResult는 Riverpod Provider를 통해 전달 (라우트 파라미터가 아닌)

---

## Step 2 — Riverpod Providers

### Approach
각 feature별 Provider 정의. @riverpod 코드 생성 사용. DB Provider(Phase 1)와 연결.

### After Code — Deck Providers
```dart
// mobile/lib/features/deck/presentation/providers/deck_providers.dart (new)
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/repositories/deck_repository_impl.dart';
import '../../domain/entities/deck_metadata.dart';
import '../../domain/entities/tarot_card.dart';
import '../../domain/repositories/deck_repository.dart';

part 'deck_providers.g.dart';

@Riverpod(keepAlive: true)
DeckRepository deckRepository(DeckRepositoryRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return DeckRepositoryImpl(db: db);
}

@riverpod
Stream<List<DeckMetadata>> watchDecks(WatchDecksRef ref) {
  final repo = ref.watch(deckRepositoryProvider);
  return repo.watchAllDecks();
}

@riverpod
Future<List<TarotCard>> deckCards(DeckCardsRef ref, String deckId) async {
  final repo = ref.watch(deckRepositoryProvider);
  return repo.getCardsByDeckId(deckId);
}

@riverpod
class SelectedDeck extends _$SelectedDeck {
  @override
  DeckMetadata? build() => null;

  void select(DeckMetadata deck) => state = deck;
  void clear() => state = null;
}
```

### After Code — Shuffle Providers
```dart
// mobile/lib/features/shuffle/presentation/providers/shuffle_providers.dart (new)
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/entropy_pool.dart';
import '../../data/datasources/sensor_data_collector.dart';
import '../../data/repositories/shuffle_repository_impl.dart';
import '../../data/services/haptic_service.dart';
import '../../domain/entities/shuffle_config.dart';
import '../../domain/entities/shuffle_result.dart';
import '../../domain/repositories/shuffle_repository.dart';
import '../../domain/strategies/riffle_shuffle_strategy.dart';
import '../../domain/strategies/shuffle_strategy.dart';
import '../../domain/usecases/shuffle_deck_usecase.dart';
import '../../../deck/presentation/providers/deck_providers.dart';

part 'shuffle_providers.g.dart';

@Riverpod(keepAlive: true)
SensorDataCollector sensorDataCollector(SensorDataCollectorRef ref) {
  final collector = SensorDataCollector();
  ref.onDispose(() => collector.dispose());
  return collector;
}

@Riverpod(keepAlive: true)
EntropyPool entropyPool(EntropyPoolRef ref) {
  return EntropyPool();
}

@Riverpod(keepAlive: true)
HapticService hapticService(HapticServiceRef ref) {
  return HapticService();
}

@riverpod
ShuffleStrategy shuffleStrategy(ShuffleStrategyRef ref) {
  return RiffleShuffleStrategy();
}

@riverpod
ShuffleDeckUseCase shuffleDeckUseCase(ShuffleDeckUseCaseRef ref) {
  return ShuffleDeckUseCase(
    sensorCollector: ref.watch(sensorDataCollectorProvider),
    entropyPool: ref.watch(entropyPoolProvider),
  );
}

@Riverpod(keepAlive: true)
ShuffleRepository shuffleRepository(ShuffleRepositoryRef ref) {
  return ShuffleRepositoryImpl();
}

@riverpod
class ShuffleState extends _$ShuffleState {
  @override
  ShuffleResult? build() => null;

  void setResult(ShuffleResult result) {
    ref.read(shuffleRepositoryProvider).cacheLastResult(result);
    state = result;
  }

  void clear() => state = null;
}

@riverpod
class ShuffleConfigNotifier extends _$ShuffleConfigNotifier {
  @override
  ShuffleConfig build() => const ShuffleConfig();

  void update(ShuffleConfig config) => state = config;
}
```

### After Code — Reading Providers
```dart
// mobile/lib/features/reading/presentation/providers/reading_providers.dart (new)
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/repositories/reading_repository_impl.dart';
import '../../domain/entities/reading.dart';
import '../../domain/repositories/reading_repository.dart';

part 'reading_providers.g.dart';

@Riverpod(keepAlive: true)
ReadingRepository readingRepository(ReadingRepositoryRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return ReadingRepositoryImpl(db: db);
}

@riverpod
Stream<List<Reading>> watchReadings(WatchReadingsRef ref) {
  final repo = ref.watch(readingRepositoryProvider);
  return repo.watchAllReadings();
}
```

---

## Step 3 — HomePage

### Approach
네비게이션 허브: 셔플 시작 버튼 + 최근 리딩 목록. 첫 실행 시 RWS 덱 시드.

### After Code
```dart
// mobile/lib/features/home/presentation/pages/home_page.dart (new)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../deck/presentation/providers/deck_providers.dart';
import '../../../reading/presentation/providers/reading_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (_initialized) return;
    final repo = ref.read(deckRepositoryProvider);
    await repo.seedRwsDeck();
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final readingsAsync = ref.watch(watchReadingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Personality Tarot', style: theme.textTheme.headlineLarge),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),

            // 셔플 시작 버튼
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () => context.pushNamed('deck'),
                child: const Text('셔플 시작', style: TextStyle(fontSize: 18)),
              ),
            ),

            const SizedBox(height: 32),

            // 최근 리딩
            Text('최근 리딩', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            Expanded(
              child: readingsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('오류: $err')),
                data: (readings) => readings.isEmpty
                    ? Center(
                        child: Text(
                          '아직 리딩이 없습니다.\n셔플을 시작해보세요.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                    : ListView.builder(
                        itemCount: readings.length,
                        itemBuilder: (context, index) {
                          final reading = readings[index];
                          return Card(
                            child: ListTile(
                              title: Text(reading.spreadType.displayName),
                              subtitle: Text(reading.question ?? '질문 없음'),
                              trailing: Text(
                                _formatDate(reading.createdAt),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
```

---

## Step 4 — DeckSelectionPage

### After Code
```dart
// mobile/lib/features/deck/presentation/pages/deck_selection_page.dart (new)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/deck_providers.dart';

class DeckSelectionPage extends ConsumerWidget {
  const DeckSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(watchDecksProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('덱 선택')),
      body: decksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('오류: $err')),
        data: (decks) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: decks.length,
          itemBuilder: (context, index) {
            final deck = decks[index];
            return Card(
              child: ListTile(
                title: Text(deck.name, style: theme.textTheme.bodyLarge),
                subtitle: Text('${deck.totalCards}장'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ref.read(selectedDeckProvider.notifier).select(deck);
                  context.pushNamed('shuffle',
                      pathParameters: {'deckId': deck.id});
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
```

---

## Step 5 — ShufflePage (핵심 화면)

### Approach
셔플의 전체 흐름을 관리하는 메인 화면. 3단계: (1) 엔트로피 수집 → (2) 셔플 애니메이션 → (3) 카드 드로우. 이원화 상태 관리의 핵심 구현점.

### After Code
```dart
// mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart (new)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../deck/presentation/providers/deck_providers.dart';
import '../../../reading/domain/entities/spread_type.dart';
import '../providers/shuffle_providers.dart';
import '../widgets/card_painter.dart';
import '../widgets/entropy_progress_indicator.dart';
import '../widgets/riffle_animation_controller.dart';

enum ShufflePhase { collecting, shuffling, drawing, complete }

class ShufflePage extends ConsumerStatefulWidget {
  const ShufflePage({super.key, required this.deckId});
  final String deckId;

  @override
  ConsumerState<ShufflePage> createState() => _ShufflePageState();
}

class _ShufflePageState extends ConsumerState<ShufflePage>
    with TickerProviderStateMixin {
  ShufflePhase _phase = ShufflePhase.collecting;
  late RiffleAnimationState _animState;
  SpreadType _selectedSpread = SpreadType.single;

  @override
  void initState() {
    super.initState();
    _animState = RiffleAnimationState(vsync: this);
    // 센서 수집 시작
    ref.read(sensorDataCollectorProvider).startCollecting();
  }

  @override
  void dispose() {
    ref.read(sensorDataCollectorProvider).stopCollecting();
    _animState.dispose();
    super.dispose();
  }

  Future<void> _startShuffle() async {
    setState(() => _phase = ShufflePhase.shuffling);

    final cards = await ref.read(deckCardsProvider(widget.deckId).future);
    final useCase = ref.read(shuffleDeckUseCaseProvider);
    final strategy = ref.read(shuffleStrategyProvider);
    final config = ref.read(shuffleConfigNotifierProvider);

    // 리플 애니메이션 실행
    await _animState.playRiffle(
      cardCount: cards.length,
      shuffleCount: config.shuffleCount,
    );

    // 엔진 셔플 실행
    final result = useCase.execute(
      cards: cards,
      strategy: strategy,
      config: config,
    );

    ref.read(shuffleStateProvider.notifier).setResult(result);
    ref.read(hapticServiceProvider).mediumImpact();

    setState(() => _phase = ShufflePhase.drawing);
  }

  void _goToReading() {
    context.pushNamed('reading',
        pathParameters: {'deckId': widget.deckId});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entropy = ref.watch(entropyPoolProvider);
    final sensor = ref.watch(sensorDataCollectorProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('셔플')),
      body: Column(
        children: [
          // 카드 렌더링 영역
          Expanded(
            flex: 3,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: CardPainter(animationState: _animState),
                size: Size.infinite,
              ),
            ),
          ),

          // 하단 컨트롤 영역
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: switch (_phase) {
                ShufflePhase.collecting => _buildCollectingUI(
                    theme, entropy, sensor),
                ShufflePhase.shuffling => const Center(
                    child: Text('셔플 중...')),
                ShufflePhase.drawing => _buildDrawingUI(theme),
                ShufflePhase.complete => const SizedBox.shrink(),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectingUI(
    ThemeData theme,
    EntropyPool entropy,
    SensorDataCollector sensor,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        EntropyProgressIndicator(
          progress: entropy.progress,
          sensorsAvailable: sensor.sensorsAvailable,
        ),
        const SizedBox(height: 8),
        Text(
          sensor.sensorsAvailable
              ? '디바이스를 흔들어 셔플 에너지를 모으세요'
              : '센서를 사용할 수 없습니다. 시스템 난수로 진행합니다.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // 스프레드 선택
        SegmentedButton<SpreadType>(
          segments: SpreadType.values.map((s) {
            return ButtonSegment(value: s, label: Text(s.displayName));
          }).toList(),
          selected: {_selectedSpread},
          onSelectionChanged: (selected) {
            setState(() => _selectedSpread = selected.first);
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: (entropy.isReady || !sensor.sensorsAvailable)
              ? _startShuffle
              : null,
          child: const Text('셔플 시작'),
        ),
      ],
    );
  }

  Widget _buildDrawingUI(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('셔플 완료! 카드를 뽑아보세요.',
            style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _goToReading,
          child: Text('${_selectedSpread.displayName} 리딩'),
        ),
      ],
    );
  }
}
```

### Considerations
- `TickerProviderStateMixin`: 리플 애니메이션에 Ticker 제공
- `RepaintBoundary`: CardPainter 영역을 분리하여 하단 UI rebuild가 카드 렌더링에 영향 없음
- `switch (_phase)`: Dart 3 switch expression으로 UI 상태 분기
- 센서 폴백: `!sensor.sensorsAvailable` 시 즉시 셔플 가능

---

## Step 6 — CardPainter (CustomPainter)

### Approach
R-008-F1 이원화 상태 관리의 핵심. 78장 카드를 Canvas에 직접 렌더링. 위젯 트리 rebuild를 스킵하고 paint()만 호출.

### After Code
```dart
// mobile/lib/features/shuffle/presentation/widgets/card_painter.dart (new)
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'riffle_animation_controller.dart';

class CardPainter extends CustomPainter {
  CardPainter({required this.animationState})
      : super(repaint: animationState);

  final RiffleAnimationState animationState;

  static const _cardAspectRatio = 2.5 / 3.5; // 포커 카드 비율
  static const _cardColor = Color(0xFF2D1B4E);
  static const _cardBorderColor = Color(0xFFD4A84B);
  static const _backPatternColor = Color(0xFF6B5B95);

  @override
  void paint(Canvas canvas, Size size) {
    final cardWidth = size.width * 0.15;
    final cardHeight = cardWidth / _cardAspectRatio;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final positions = animationState.cardPositions;
    if (positions.isEmpty) {
      // 초기 상태: 덱을 중앙에 쌓아서 표시
      _drawDeckStack(canvas, centerX, centerY, cardWidth, cardHeight);
      return;
    }

    // 애니메이션 중: 각 카드를 개별 위치에 렌더링
    for (var i = 0; i < positions.length; i++) {
      final pos = positions[i];
      _drawCard(
        canvas,
        centerX + pos.dx * size.width,
        centerY + pos.dy * size.height,
        cardWidth,
        cardHeight,
        pos.rotation,
      );
    }
  }

  void _drawDeckStack(
    Canvas canvas,
    double cx,
    double cy,
    double w,
    double h,
  ) {
    final paint = Paint()..color = _cardColor;
    final borderPaint = Paint()
      ..color = _cardBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 5장 스택 시각 효과
    for (var i = 4; i >= 0; i--) {
      final offset = i * 1.5;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + offset, cy - offset),
          width: w,
          height: h,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, paint);
      canvas.drawRRect(rect, borderPaint);
    }

    // 뒷면 패턴
    _drawBackPattern(canvas, cx, cy, w * 0.6, h * 0.6);
  }

  void _drawCard(
    Canvas canvas,
    double cx,
    double cy,
    double w,
    double h,
    double rotation,
  ) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(rotation);

    final paint = Paint()..color = _cardColor;
    final borderPaint = Paint()
      ..color = _cardBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: w, height: h),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, paint);
    canvas.drawRRect(rect, borderPaint);

    canvas.restore();
  }

  void _drawBackPattern(
    Canvas canvas,
    double cx,
    double cy,
    double w,
    double h,
  ) {
    final patternPaint = Paint()
      ..color = _backPatternColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // 다이아몬드 패턴
    final path = Path()
      ..moveTo(cx, cy - h / 2)
      ..lineTo(cx + w / 2, cy)
      ..lineTo(cx, cy + h / 2)
      ..lineTo(cx - w / 2, cy)
      ..close();
    canvas.drawPath(path, patternPaint);
  }

  @override
  bool shouldRepaint(CardPainter oldDelegate) => true;
}
```

---

## Step 7 — RiffleAnimationState

### Approach
Ticker 기반 애니메이션 상태. ChangeNotifier를 구현하여 CustomPainter의 repaint Listenable으로 사용. Riverpod를 통하지 않고 직접 프레임 단위 업데이트.

### After Code
```dart
// mobile/lib/features/shuffle/presentation/widgets/riffle_animation_controller.dart (new)
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class CardPosition {
  const CardPosition({this.dx = 0, this.dy = 0, this.rotation = 0});
  final double dx; // -0.5 ~ 0.5 (화면 비율)
  final double dy; // -0.5 ~ 0.5
  final double rotation; // 라디안
}

class RiffleAnimationState extends ChangeNotifier {
  RiffleAnimationState({required TickerProvider vsync}) : _vsync = vsync;

  final TickerProvider _vsync;
  AnimationController? _controller;
  List<CardPosition> _cardPositions = [];
  int _cardCount = 0;

  List<CardPosition> get cardPositions => _cardPositions;

  /// 리플 셔플 애니메이션 재생
  Future<void> playRiffle({
    required int cardCount,
    required int shuffleCount,
  }) async {
    _cardCount = cardCount;

    for (var round = 0; round < shuffleCount; round++) {
      await _playOneRiffle(round);
    }

    // 애니메이션 끝: 카드를 다시 중앙으로 모으기
    await _gatherCards();
  }

  Future<void> _playOneRiffle(int round) async {
    _controller?.dispose();
    _controller = AnimationController(
      vsync: _vsync,
      duration: const Duration(milliseconds: 800),
    );

    _controller!.addListener(() {
      final t = _controller!.value;
      _cardPositions = _generateRifflePositions(t, round);
      notifyListeners();
    });

    await _controller!.forward();
  }

  List<CardPosition> _generateRifflePositions(double t, int round) {
    final positions = <CardPosition>[];
    final mid = _cardCount ~/ 2;
    final rng = math.Random(round); // 라운드별 결정론적 랜덤

    for (var i = 0; i < _cardCount; i++) {
      final isLeft = i < mid;
      final normalizedIndex = isLeft ? i / mid : (i - mid) / (_cardCount - mid);

      // 페이즈: 분리 → 인터리빙
      double dx, dy, rotation;

      if (t < 0.3) {
        // 분리 페이즈: 양쪽으로 벌어짐
        final spread = t / 0.3;
        dx = isLeft ? -0.15 * spread : 0.15 * spread;
        dy = normalizedIndex * 0.01 - 0.005;
        rotation = 0;
      } else if (t < 0.8) {
        // 인터리빙 페이즈: 카드가 번갈아 떨어짐
        final interleave = (t - 0.3) / 0.5;
        final dropProgress = (interleave * _cardCount - i).clamp(0.0, 1.0);

        dx = isLeft
            ? -0.15 * (1 - dropProgress)
            : 0.15 * (1 - dropProgress);
        dy = (normalizedIndex * 0.3 - 0.15) * dropProgress;
        rotation = (rng.nextDouble() - 0.5) * 0.05 * dropProgress;
      } else {
        // 수렴 페이즈: 중앙으로 모임
        final gather = (t - 0.8) / 0.2;
        dx = 0;
        dy = normalizedIndex * 0.01 * (1 - gather);
        rotation = 0;
      }

      positions.add(CardPosition(dx: dx, dy: dy, rotation: rotation));
    }

    return positions;
  }

  Future<void> _gatherCards() async {
    _controller?.dispose();
    _controller = AnimationController(
      vsync: _vsync,
      duration: const Duration(milliseconds: 400),
    );

    _controller!.addListener(() {
      final t = _controller!.value;
      _cardPositions = List.generate(
        _cardCount,
        (i) => CardPosition(
          dx: _cardPositions[i].dx * (1 - t),
          dy: _cardPositions[i].dy * (1 - t),
          rotation: _cardPositions[i].rotation * (1 - t),
        ),
      );
      notifyListeners();
    });

    await _controller!.forward();
    _cardPositions = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
```

### Considerations
- `ChangeNotifier`를 `repaint` Listenable으로 사용 → `notifyListeners()` 시 paint()만 호출
- Riverpod 경유 없음 → 매 프레임 위젯 트리 rebuild 없이 Canvas만 갱신
- 3단계 애니메이션: 분리(0-0.3) → 인터리빙(0.3-0.8) → 수렴(0.8-1.0)
- `math.Random(round)`: 라운드별 결정론적이지만 라운드마다 다른 패턴

---

## Step 8 — EntropyProgressIndicator

### After Code
```dart
// mobile/lib/features/shuffle/presentation/widgets/entropy_progress_indicator.dart (new)
import 'package:flutter/material.dart';

class EntropyProgressIndicator extends StatelessWidget {
  const EntropyProgressIndicator({
    super.key,
    required this.progress,
    required this.sensorsAvailable,
  });

  final double progress;
  final bool sensorsAvailable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!sensorsAvailable) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.secondary, size: 20),
          const SizedBox(width: 8),
          Text('시스템 난수 사용', style: theme.textTheme.bodyMedium),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.surface,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0
                  ? theme.colorScheme.primary
                  : theme.colorScheme.secondary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          progress >= 1.0
              ? '에너지 충전 완료!'
              : '${(progress * 100).toInt()}% 수집 중...',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
```

---

## Step 9 — ReadingPage + SpreadLayout

### Approach
셔플 결과에서 SpreadType에 따라 카드를 배치. 각 카드 터치 시 뒤집기 애니메이션.

### After Code — ReadingPage
```dart
// mobile/lib/features/reading/presentation/pages/reading_page.dart (new)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../shuffle/presentation/providers/shuffle_providers.dart';
import '../../domain/entities/reading.dart';
import '../../domain/entities/spread_type.dart';
import '../providers/reading_providers.dart';
import '../widgets/spread_layout.dart';

class ReadingPage extends ConsumerStatefulWidget {
  const ReadingPage({super.key, required this.deckId});
  final String deckId;

  @override
  ConsumerState<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends ConsumerState<ReadingPage> {
  SpreadType _spreadType = SpreadType.single;
  final Set<int> _revealedPositions = {};

  @override
  void initState() {
    super.initState();
    // TODO: ShufflePage에서 선택한 spreadType을 전달받도록 개선
  }

  @override
  Widget build(BuildContext context) {
    final shuffleResult = ref.watch(shuffleStateProvider);
    final theme = Theme.of(context);

    if (shuffleResult == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('리딩')),
        body: const Center(child: Text('셔플을 먼저 진행해주세요.')),
      );
    }

    final drawnCards = shuffleResult.cards.take(_spreadType.cardCount).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_spreadType.displayName),
        actions: [
          if (_revealedPositions.length == _spreadType.cardCount)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () => _saveReading(drawnCards),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SpreadLayout(
          spreadType: _spreadType,
          cards: drawnCards,
          revealedPositions: _revealedPositions,
          onCardTap: (position) {
            setState(() => _revealedPositions.add(position));
          },
        ),
      ),
    );
  }

  Future<void> _saveReading(List<dynamic> drawnCards) async {
    final reading = Reading(
      id: const Uuid().v4(),
      deckId: widget.deckId,
      spreadType: _spreadType,
      drawnCards: List.generate(
        drawnCards.length,
        (i) => DrawnCardInfo(
          cardId: drawnCards[i].card.id,
          position: i,
          isReversed: drawnCards[i].isReversed,
        ),
      ),
      createdAt: DateTime.now(),
    );

    await ref.read(readingRepositoryProvider).saveReading(reading);
    if (mounted) context.go('/');
  }
}
```

### After Code — SpreadLayout
```dart
// mobile/lib/features/reading/presentation/widgets/spread_layout.dart (new)
import 'package:flutter/material.dart';
import '../../../shuffle/domain/entities/shuffle_result.dart';
import '../../domain/entities/spread_type.dart';
import 'card_reveal_widget.dart';

class SpreadLayout extends StatelessWidget {
  const SpreadLayout({
    super.key,
    required this.spreadType,
    required this.cards,
    required this.revealedPositions,
    required this.onCardTap,
  });

  final SpreadType spreadType;
  final List<ShuffledCard> cards;
  final Set<int> revealedPositions;
  final ValueChanged<int> onCardTap;

  @override
  Widget build(BuildContext context) {
    return switch (spreadType) {
      SpreadType.single => _buildSingleLayout(context),
      SpreadType.threeCard => _buildThreeCardLayout(context),
    };
  }

  Widget _buildSingleLayout(BuildContext context) {
    return Center(
      child: CardRevealWidget(
        card: cards[0],
        position: 0,
        label: spreadType.positions[0],
        isRevealed: revealedPositions.contains(0),
        onTap: () => onCardTap(0),
      ),
    );
  }

  Widget _buildThreeCardLayout(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (i) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CardRevealWidget(
              card: cards[i],
              position: i,
              label: spreadType.positions[i],
              isRevealed: revealedPositions.contains(i),
              onTap: () => onCardTap(i),
            ),
          ),
        );
      }),
    );
  }
}
```

---

## Step 10 — CardRevealWidget (카드 뒤집기)

### Approach
400ms Y축 3D 회전. 전반부(0-0.5)는 뒷면, 후반부(0.5-1.0)는 앞면 + 좌우 반전 보정. Research(008) Perspective 1 참조.

### After Code
```dart
// mobile/lib/features/reading/presentation/widgets/card_reveal_widget.dart (new)
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../shuffle/domain/entities/shuffle_result.dart';

class CardRevealWidget extends StatefulWidget {
  const CardRevealWidget({
    super.key,
    required this.card,
    required this.position,
    required this.label,
    required this.isRevealed,
    required this.onTap,
  });

  final ShuffledCard card;
  final int position;
  final String label;
  final bool isRevealed;
  final VoidCallback onTap;

  @override
  State<CardRevealWidget> createState() => _CardRevealWidgetState();
}

class _CardRevealWidgetState extends State<CardRevealWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFront = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _animation.addListener(() {
      if (_animation.value >= 0.5 && !_showFront) {
        setState(() => _showFront = true);
      }
    });
  }

  @override
  void didUpdateWidget(CardRevealWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRevealed && !oldWidget.isRevealed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: widget.isRevealed ? null : widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.label, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final angle = _animation.value * math.pi;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // perspective
                  ..rotateY(angle),
                child: _showFront ? _buildFront(theme) : _buildBack(theme),
              );
            },
          ),
          if (widget.isRevealed && widget.card.isReversed)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('역방향',
                  style: TextStyle(color: theme.colorScheme.secondary)),
            ),
        ],
      ),
    );
  }

  Widget _buildBack(ThemeData theme) {
    return AspectRatio(
      aspectRatio: 2.5 / 3.5,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2D1B4E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.primary, width: 1.5),
        ),
        child: Center(
          child: Icon(Icons.auto_awesome,
              color: theme.colorScheme.primary, size: 32),
        ),
      ),
    );
  }

  Widget _buildFront(ThemeData theme) {
    // 좌우 반전 보정 (Y축 회전 후반부이므로 미러링 필요)
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(math.pi),
      child: AspectRatio(
        aspectRatio: 2.5 / 3.5,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1028),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.primary, width: 1.5),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.card.card.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.card.card.meanings.upright.take(2).join(', '),
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Step 11 — main.dart 라우터 연결

### Approach
MaterialApp → MaterialApp.router로 변경. go_router Provider 연결.

### Current Code (Phase 1 이후)
```dart
// mobile/lib/main.dart (Phase 1 after)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/database/database_setup.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await constructDb();
  runApp(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
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
        body: Center(child: Text('Personality + Tarot')),
      ),
    );
  }
}
```

### After Code
```dart
// mobile/lib/main.dart (Phase 3 final)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/database/database_provider.dart';
import 'core/database/database_setup.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await constructDb();
  runApp(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const PersonalityApp(),
    ),
  );
}

class PersonalityApp extends ConsumerWidget {
  const PersonalityApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Personality Tarot',
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
```

### Considerations
- `StatelessWidget` → `ConsumerWidget`: router Provider 접근 위해
- `MaterialApp` → `MaterialApp.router`: go_router 연결
- `routerConfig: router`: GoRouter 인스턴스 직접 전달

---

## Considerations & Trade-offs

### Alternative Approaches
| Approach | 불채택 이유 |
|----------|-----------|
| Navigator 2.0 직접 사용 | go_router가 추상화 제공, 보일러플레이트 감소 |
| BLoC으로 셔플 상태 관리 | Riverpod이 더 간결하고 이미 DI 역할 수행 중 |
| Rive로 카드 애니메이션 | 동적 물리 제어 불가. CustomPainter가 유연 |
| 위젯 기반 카드 렌더링 | 78장 Stack → 400+ 위젯 rebuild → 60fps 불가 |

### Potential Risks
| Risk | Mitigation |
|------|-----------|
| CardPainter 성능 (구형 기기) | RepaintBoundary 분리, Impeller AOT |
| Provider 의존성 복잡도 | keepAlive를 최소화, 순환 의존 방지 |
| 3D 플립 시 flicker | AnimatedBuilder + perspective 검증 |

### Backward Compatibility
- Phase 1 main.dart 수정 (MaterialApp → MaterialApp.router)
- Phase 2 코드는 수정 없이 사용

## Implementation Checklist

- [ ] Step 1: go_router 라우팅 (app_router.dart)
- [ ] Step 2: Riverpod Providers (Deck, Shuffle, Reading)
- [ ] Step 3: HomePage (네비게이션 허브)
- [ ] Step 4: DeckSelectionPage
- [ ] Step 5: ShufflePage (핵심 — 3단계 흐름)
- [ ] Step 6: CardPainter (CustomPainter — 60fps)
- [ ] Step 7: RiffleAnimationState (Ticker 기반)
- [ ] Step 8: EntropyProgressIndicator
- [ ] Step 9: ReadingPage + SpreadLayout (1장/3장)
- [ ] Step 10: CardRevealWidget (3D 뒤집기)
- [ ] Step 11: main.dart 라우터 연결
- [ ] build_runner 코드 생성 확인
- [ ] Final verification

## Verification Assertions

| Level | Assertion | Verification Method | Expected Result |
|-------|-----------|-------------------|-----------------|
| L1-Build | build_runner 성공 | `dart run build_runner build` | Provider 생성 파일들 |
| L1-Build | flutter analyze 통과 | `flutter analyze` | 에러 0 |
| L2-CLI | 라우팅 동작 | 위젯 테스트: pushNamed('shuffle') | ShufflePage 렌더 |
| L3-Browser | 홈 화면 렌더링 | flutter test (widget) | '셔플 시작' 버튼 존재 |
| L3-Browser | 셔플 → 리딩 흐름 | integration test | 전체 흐름 통과 |
| L3-Browser | 카드 뒤집기 애니메이션 | 시각 확인 | 400ms Y축 3D 회전 |
| L4-Trace | R-008-F1 이원화 상태 | 코드 검증 | CustomPainter + ChangeNotifier, Riverpod 경유 없음 |
| L4-Trace | R-008-F6 Feature-first | 구조 검증 | features/{shuffle,deck,reading}/ |

## References

| Resource | Path/URL | Related Content |
|----------|---------|-----------------|
| Research | docs/11_tarot_shuffle/008_Research_tarot_shuffle_tech.md | 이원화 상태, 카드 플립 |
| Architecture Agent | docs/11_tarot_shuffle/006_Agent_architecture.md | Riverpod, Feature-first |
| Shuffle Agent | docs/11_tarot_shuffle/003_Agent_shuffle_engine.md | CustomPainter, 애니메이션 |
| Checkpoint | docs/11_tarot_shuffle/009_Plan_flutter_mvp_checkpoint.md | 플랜 마스터 |
