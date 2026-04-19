---
id: "046"
type: plan
title: "셔플 엔진 Cycle 3 — UI Integration (ShufflePage GameWidget 교체 + 햅틱)"
created: 2026-03-16
traces_scope: "043"
traces_research: "042"
summary: >
  ShufflePage의 CustomPainter/RiffleAnimationState를 Flame GameWidget으로 교체.
  CardBodyComponent에 ContactCallbacks 믹스인 추가로 카드 충돌 시 경량 햅틱 발생.
  엔트로피 수집/셔플 비즈니스 로직은 유지하며 물리 기반 애니메이션 레이어로 전환.
keywords: [GameWidget, FlameGame, ShufflePage, ContactCallbacks, haptic, flutter, riffle-remove]
---

# 046 — 셔플 엔진 Cycle 3: UI Integration

## Goal

Cycle 1–2에서 구축한 TarotGame/forge2d 물리 레이어를 ShufflePage에 실제로 표시한다.

1. `ShufflePage` — CustomPaint → `GameWidget(game: TarotGame())` 교체.
   `RiffleAnimationState` / `TickerProviderStateMixin` 제거. `_startShuffle()`에서 playRiffle 제거 후 1.5s 물리 딜레이 적용.
2. `CardBodyComponent` — `ContactCallbacks` mixin 추가. 카드-카드 충돌 시 `HapticFeedback.selectionClick()` 발생.

완료 후: GameWidget이 ShufflePage 상단에 렌더링되어 78장 카드가 물리 법칙으로 움직이고, 폰 기울이기에 즉각 반응하는 완성 상태.

## Scope

### Included
| # | 항목 | 설명 |
|---|------|------|
| 1 | ShufflePage → GameWidget 교체 | CustomPaint 제거, GameWidget 삽입, TarotGame 라이프사이클 관리 |
| 2 | RiffleAnimationState 제거 | `_animState` 필드/호출 전부 제거, TickerProviderStateMixin 제거 |
| 3 | CardBodyComponent 햅틱 | ContactCallbacks mixin + body.userData = this + beginContact → selectionClick |
| 4 | _startShuffle 조정 | playRiffle → Future.delayed(1.5s) 교체 |

### Excluded
| 항목 | 이유 |
|------|------|
| assets/animations/hand_shuffle.riv | Rive 디자인 파일 별도 태스크. HandAnimationComponent가 graceful fallback 처리 |
| 카드 드래그/탭 인터랙션 | GestureDetector + TarotGame 통합은 별도 사이클 |
| 카드 이미지 교체 | debug 사각형 → 실제 카드 이미지는 별도 태스크 |
| EntropyPool / SensorDataCollector 로직 | 변경 없음. 독립 동작 유지 |

## Structural Decisions

> No structural decisions required — straightforward implementation.

| # | 결정 | 선택 | 근거 |
|---|------|------|------|
| 1 | GameWidget 생성 위치 | initState()에서 `_game = TarotGame()` | GameWidget은 game 인스턴스 참조만 요구. dispose는 GameWidget이 자동 관리 |
| 2 | playRiffle 대체 | Future.delayed(1.5s) | 물리 엔진이 이미 카드를 움직임. 기존 애니메이션 시간(약 1.5s) 유사하게 유지해 UX 연속성 보장 |
| 3 | 햅틱 구현 방식 | HapticFeedback.selectionClick() 직접 호출 | Flame 게임 루프 = Flutter 메인 아이솔레이트. HapticFeedback 직접 호출 안전. HapticService의 throttle이 없지만 CardBodyComponent 충돌은 자주 일어나므로 가벼운 selectionClick 선택 |
| 4 | ContactCallbacks 위치 | CardBodyComponent 내 직접 정의 | 별도 파일 불필요. 단순 beginContact 하나만 필요 |

---

## File Change Summary

### Modified Files
| # | 파일 경로 | 변경 설명 |
|---|-----------|-----------|
| 1 | `mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart` | GameWidget 교체, RiffleAnimationState 제거, TarotGame 라이프사이클 |
| 2 | `mobile/lib/features/shuffle/presentation/game/card_body_component.dart` | ContactCallbacks 믹스인, body.userData 설정, 햅틱 |

### New Files
없음.

---

## Step 1 — shuffle_page.dart: RiffleAnimationState 제거 + GameWidget 교체

### Approach

`_ShufflePageState`에서 다음을 수행한다:
1. `TickerProviderStateMixin` 제거
2. `_animState` 필드 + 모든 참조 제거
3. `late TarotGame _game` 필드 추가, `initState()`에서 초기화
4. `import` 정리: CardPainter, RiffleAnimationController 제거 / TarotGame, flame.dart 추가
5. `CustomPaint(painter: CardPainter(...))` → `GameWidget<TarotGame>(game: _game)`
6. `_startShuffle()`: `await _animState.playRiffle(...)` → `await Future.delayed(const Duration(milliseconds: 1500))`
7. `dispose()`: `_animState.dispose()` 제거 (GameWidget이 game을 자동 dispose)

### Current Code

```dart
// mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart:1-15 (imports)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../deck/presentation/providers/deck_providers.dart';
import '../../../reading/domain/entities/spread_type.dart';
import '../../data/datasources/entropy_pool.dart';
import '../../data/datasources/sensor_data_collector.dart';
import '../providers/shuffle_providers.dart';
import '../widgets/card_painter.dart';
import '../widgets/entropy_progress_indicator.dart';
import '../widgets/riffle_animation_controller.dart';
```

```dart
// mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart:26-37 (class + initState)
class _ShufflePageState extends ConsumerState<ShufflePage>
    with TickerProviderStateMixin {
  ShufflePhase _phase = ShufflePhase.collecting;
  late RiffleAnimationState _animState;
  SpreadType _selectedSpread = SpreadType.single;
  Timer? _pollTimer;
  int _lastFedSampleCount = 0;

  @override
  void initState() {
    super.initState();
    _animState = RiffleAnimationState(vsync: this);
    ref.read(entropyPoolProvider).reset();
    // ...
  }
```

```dart
// mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart:55-61 (dispose)
  @override
  void dispose() {
    _pollTimer?.cancel();
    ref.read(sensorDataCollectorProvider).stopCollecting();
    _animState.dispose();
    super.dispose();
  }
```

```dart
// mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart:63-94 (_startShuffle)
  Future<void> _startShuffle() async {
    setState(() => _phase = ShufflePhase.shuffling);
    try {
      final cards = await ref.read(deckCardsProvider(widget.deckId).future);
      final useCase = ref.read(shuffleDeckUseCaseProvider);
      final strategy = ref.read(shuffleStrategyProvider);
      final config = ref.read(shuffleConfigNotifierProvider);

      await _animState.playRiffle(
        cardCount: cards.length,
        shuffleCount: config.shuffleCount,
      );

      final result = useCase.execute(
        cards: cards,
        strategy: strategy,
        config: config,
      );
      // ...
```

```dart
// mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart:113-121 (CustomPaint)
            Expanded(
              flex: 3,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: CardPainter(animationState: _animState),
                  size: Size.infinite,
                ),
              ),
            ),
```

### After Code

```dart
// mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart (수정 후 전체)
import 'dart:async';

import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../deck/presentation/providers/deck_providers.dart';
import '../../../reading/domain/entities/spread_type.dart';
import '../../data/datasources/entropy_pool.dart';
import '../../data/datasources/sensor_data_collector.dart';
import '../game/tarot_game.dart';
import '../providers/shuffle_providers.dart';
import '../widgets/entropy_progress_indicator.dart';
```

```dart
// _ShufflePageState class 선언 (TickerProviderStateMixin 제거)
class _ShufflePageState extends ConsumerState<ShufflePage> {
  ShufflePhase _phase = ShufflePhase.collecting;
  late TarotGame _game;
  SpreadType _selectedSpread = SpreadType.single;
  Timer? _pollTimer;
  int _lastFedSampleCount = 0;

  @override
  void initState() {
    super.initState();
    _game = TarotGame();
    ref.read(entropyPoolProvider).reset();
    ref.read(sensorDataCollectorProvider).startCollecting();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_phase == ShufflePhase.collecting && mounted) {
        final collector = ref.read(sensorDataCollectorProvider);
        final pool = ref.read(entropyPoolProvider);
        final newSamples = collector.samples.skip(_lastFedSampleCount).toList();
        if (newSamples.isNotEmpty) {
          pool.addSamples(newSamples);
          _lastFedSampleCount = collector.sampleCount;
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    ref.read(sensorDataCollectorProvider).stopCollecting();
    // GameWidget이 _game의 라이프사이클을 자동 관리 — 수동 dispose 불필요
    super.dispose();
  }
```

```dart
// _startShuffle: playRiffle → Future.delayed 교체
  Future<void> _startShuffle() async {
    setState(() => _phase = ShufflePhase.shuffling);
    try {
      final cards = await ref.read(deckCardsProvider(widget.deckId).future);
      final useCase = ref.read(shuffleDeckUseCaseProvider);
      final strategy = ref.read(shuffleStrategyProvider);
      final config = ref.read(shuffleConfigNotifierProvider);

      // 물리 엔진이 카드를 움직이는 동안 잠시 대기 (RiffleAnimation 대체)
      await Future.delayed(const Duration(milliseconds: 1500));

      final result = useCase.execute(
        cards: cards,
        strategy: strategy,
        config: config,
      );

      ref.read(shuffleStateProvider.notifier).setResult(result);
      ref.read(hapticServiceProvider).mediumImpact();

      setState(() => _phase = ShufflePhase.drawing);
    } catch (e) {
      setState(() => _phase = ShufflePhase.collecting);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('셔플에 실패했습니다: $e')),
        );
      }
    }
  }
```

```dart
// build(): CustomPaint → GameWidget
            Expanded(
              flex: 3,
              child: GameWidget<TarotGame>(game: _game),
            ),
```

### Considerations

- `GameWidget`은 `_game`의 lifecycle(onGameResize, onLoad, onRemove 등)을 자동 관리한다. `dispose()` 수동 호출 불필요.
- `show GameWidget` import: `package:flame/game.dart`에서 GameWidget만 노출. flame_forge2d의 Vector2와 충돌하지 않도록 show 사용.
- `RepaintBoundary` 제거: GameWidget은 자체적으로 최적화된 렌더링을 처리하므로 불필요.
- `_startShuffle`에서 `await Future.delayed(1500ms)` — RiffleAnimation이 기존에 걸리던 시간(shuffleCount × ~500ms)과 유사. config.shuffleCount 의존성 제거로 단순화.

---

## Step 2 — card_body_component.dart: ContactCallbacks + 햅틱

### Approach

`ContactCallbacks` mixin을 `CardBodyComponent`에 추가하고, `createBody()`에서 `body.userData = this`를 설정한다.
`WorldContactListener`는 collision 시 `body.userData`에 `ContactCallbacks` 객체가 있으면 `beginContact()`를 호출한다.

카드-카드 충돌(`other is CardBodyComponent`)에만 햅틱 발생. 다른 충돌(카드-KinematicBody 등)은 무시.

### Current Code

```dart
// mobile/lib/features/shuffle/presentation/game/card_body_component.dart (전체)
import 'package:flame_forge2d/flame_forge2d.dart';

import 'tarot_game.dart';

class CardBodyComponent extends BodyComponent<TarotGame> {
  final Vector2 initialPosition;

  static const double halfWidth = 0.3;
  static const double halfHeight = 0.45;

  CardBodyComponent({required this.initialPosition})
      : super(renderBody: true);

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: initialPosition,
      linearDamping: 2.0,
      angularDamping: 1.2,
      allowSleep: true,
    );
    final shape = PolygonShape()..setAsBoxXY(halfWidth, halfHeight);
    final fixtureDef = FixtureDef(
      shape,
      density: 1.0,
      friction: 0.4,
      restitution: 0.05,
    );
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}
```

### After Code

```dart
// mobile/lib/features/shuffle/presentation/game/card_body_component.dart (수정 후)
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/services.dart';

import 'tarot_game.dart';

/// forge2d DynamicBody 타로 카드 1장.
///
/// TarotGame.onLoad()에서 78개 인스턴스 생성.
/// 물리 파라미터는 Research 036 확정값 사용.
///
/// [ContactCallbacks]: 카드끼리 충돌 시 selectionClick 햅틱 발생.
/// body.userData = this → WorldContactListener가 beginContact() 자동 라우팅.
class CardBodyComponent extends BodyComponent<TarotGame> with ContactCallbacks {
  final Vector2 initialPosition;

  /// 카드 반폭/반높이 (forge2d meters).
  /// 0.3m × 0.45m → @ zoom=100 → 60px × 90px
  static const double halfWidth = 0.3;
  static const double halfHeight = 0.45;

  CardBodyComponent({required this.initialPosition})
      : super(renderBody: true);

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: initialPosition,
      linearDamping: 2.0,   // 조작감 핵심 파라미터 — "무게감" 결정 (Research 036 확정)
      angularDamping: 1.2,  // 회전 감쇠
      allowSleep: true,     // 78장 성능 최적화: 정적 카드 CPU 절약
    );
    final shape = PolygonShape()..setAsBoxXY(halfWidth, halfHeight);
    final fixtureDef = FixtureDef(
      shape,
      density: 1.0,
      friction: 0.4,
      restitution: 0.05, // 타로 카드: 낮은 반발계수 (Research 036 확정)
    );
    final body = world.createBody(bodyDef)..createFixture(fixtureDef);
    body.userData = this; // WorldContactListener 라우팅 활성화
    return body;
  }

  @override
  void beginContact(Object other, Contact contact) {
    // 카드-카드 충돌에만 햅틱: KinematicBody(손) 충돌은 무시
    if (other is CardBodyComponent) {
      HapticFeedback.selectionClick();
    }
  }
}
```

### Considerations

- `ContactCallbacks` mixin: `flame_forge2d`의 `WorldContactListener`가 자동으로 `beginContact()`를 호출한다. 별도 등록 코드 불필요.
- `body.userData = this`: `WorldContactListener.beginContact()`에서 `body.userData`를 `ContactCallbacks`로 캐스팅해 메서드 호출. 이 줄이 없으면 충돌 이벤트 수신 안 됨.
- `HapticFeedback.selectionClick()`: Flame 게임 루프 = Flutter 메인 아이솔레이트. 직접 호출 안전. 기존 `HapticService.selectionClick()`은 Riverpod Provider 접근이 필요해 게임 컴포넌트에서 직접 사용 불가.
- 78장 × 동시 충돌: 여러 카드가 동시에 충돌하면 햅틱이 여러 번 호출될 수 있음. `selectionClick()`은 경량 햅틱이므로 UX상 문제 없음. 필요 시 throttle 추가 가능(별도 태스크).

---

## Considerations & Trade-offs

### Alternative Approaches

| 대안 | 미채택 이유 |
|------|-----------|
| `GameWidget.controlled` 사용 | game 인스턴스를 외부에서 생성하는 현재 방식과 동일. controlled는 Hot Reload 지원이 추가될 뿐 Cycle 3 MVP에 불필요 |
| TarotGame에 haptic callback 전달 | Riverpod Provider → Flame 브릿지 필요. 복잡도 증가. HapticFeedback 직접 호출로 충분 |
| 셔플 완료 시 추가 애니메이션 | 물리 엔진이 이미 시각적 피드백 제공. 추가 애니메이션 불필요 |
| `RepaintBoundary` 유지 | GameWidget 내부에서 자체 최적화. RepaintBoundary 래핑은 중복 |

### Potential Risks

1. **GameWidget 라이프사이클**: `_game = TarotGame()` 후 `GameWidget`에 전달 전에 `onLoad()`가 호출될 수 있음. Flame은 GameWidget이 mount된 후에 `onLoad()`를 호출하므로 안전.
2. **동시 햅틱 과다**: 78장 카드가 모두 중력으로 쏠릴 때 대량 충돌 → 햅틱 폭주 가능성. `selectionClick()`이 경량이므로 사용자가 인지하지 못하는 수준이나, 필요 시 throttle 추가.
3. **Riverpod와 Flame 혼재**: `initState()`에서 `_game = TarotGame()` + `ref.read(entropyPoolProvider)` 동시 사용. Riverpod는 위젯 트리 기반이므로 initState에서 ref 사용 안전(ConsumerStatefulWidget 기준).

### Backward Compatibility

- `ShufflePage` API: constructor `{required String deckId}` 변경 없음
- `SensorDataCollector`: `startCollecting()`/`stopCollecting()` 그대로 사용
- `EntropyPool`: `reset()`, `addSamples()`, `progress`, `isReady` 그대로 사용
- `shuffleStateProvider`, `hapticServiceProvider`: 변경 없음
- `CardBodyComponent`: 기존 인터페이스(`initialPosition`) 유지. mixin 추가는 additive change.

---

## Implementation Checklist

- [x] Step 1: `shuffle_page.dart` import 정리 (CardPainter, RiffleAnimationController 제거, flame/game.dart, TarotGame 추가)
- [x] Step 1: `_ShufflePageState` with 절 수정 (TickerProviderStateMixin 제거)
- [x] Step 1: `_animState` 필드 제거 + `_game` 필드 추가
- [x] Step 1: `initState()` — `_animState = ...` 제거, `_game = TarotGame()` 추가
- [x] Step 1: `dispose()` — `_animState.dispose()` 제거
- [x] Step 1: `_startShuffle()` — `playRiffle` → `Future<void>.delayed(1500ms)` 교체
- [x] Step 1: `build()` — CustomPaint → `GameWidget<TarotGame>(game: _game)`
- [x] Step 1: `flutter analyze` — 에러 없음 확인
- [x] Step 2: `card_body_component.dart` — `with ContactCallbacks` 추가
- [x] Step 2: `card_body_component.dart` — `flutter/services.dart` import 추가
- [x] Step 2: `createBody()` — `body.userData = this` 추가 (return 전)
- [x] Step 2: `beginContact()` override 추가
- [x] Step 2: `flutter analyze` — 에러 없음 확인
- [x] Final: `flutter analyze` — 전체 0 errors

## Verification Assertions

| Level | Assertion | Verification Method | Expected Result |
|-------|-----------|-------------------|-----------------|
| L1-Build | flutter analyze 통과 | `flutter analyze` | 0 errors |
| L2-CLI | GameWidget import 존재 | `grep "GameWidget" shuffle_page.dart` | 존재 |
| L2-CLI | RiffleAnimationState 제거 | `grep "RiffleAnimationState" shuffle_page.dart` | 없음 (0 matches) |
| L2-CLI | TarotGame 필드 존재 | `grep "TarotGame" shuffle_page.dart` | 존재 |
| L2-CLI | ContactCallbacks mixin 추가 | `grep "ContactCallbacks" card_body_component.dart` | 존재 |
| L2-CLI | body.userData 설정 | `grep "userData" card_body_component.dart` | 존재 |
| L2-CLI | beginContact 구현 | `grep "beginContact" card_body_component.dart` | 존재 |
| L4-Trace | Scope 043 성공 기준: GameWidget ShufflePage 통합 | grep GameWidget shuffle_page.dart | PASS |

## References

| 리소스 | 경로 | 관련 내용 |
|--------|------|-----------|
| Scope | docs/11_tarot_shuffle/043_Scope_shuffle_engine_impl.md | Cycle 3 요구사항, 성공 기준 |
| Cycle 1 플랜 | docs/11_tarot_shuffle/044_Plan_shuffle_cycle1_foundation.md | TarotGame 구조 |
| Cycle 2 플랜 | docs/11_tarot_shuffle/045_Plan_shuffle_cycle2_physics.md | CardBodyComponent, TarotGame.onLoad() |
| 최종 아키텍처 | docs/11_tarot_shuffle/042_Research_tactile_engine_final.md | GameWidget 통합 근거 |
| flame_forge2d | contact_callbacks.dart | ContactCallbacks mixin API |

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
