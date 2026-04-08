---
id: "004"
type: plan
title: "Cycle 1 구현 계획 — Flame 뒷면 Sprite + 동적 카드 수"
created: 2026-03-22
traces_scope: "002"
traces_research: "003"
summary: >
  CardBodyComponent의 코드 드로잉을 card_back.webp SpriteComponent로 교체하고,
  TarotGame에 deckId/cardCount 파라미터를 추가하여 덱별 동적 카드 수를 지원한다.
  ShufflePage에서 DeckMetadata.totalCards를 조회하여 TarotGame에 전달.
  수정 파일 3개, 신규 파일 0개.
---

# Cycle 1 구현 계획 — Flame 뒷면 Sprite + 동적 카드 수

## 목표

1. `CardBodyComponent.render()`의 코드 드로잉(그라디언트/패턴/그림자)을 `card_back.webp` SpriteComponent로 교체
2. `TarotGame`에 `deckId`, `cardCount` 파라미터를 추가하여 덱별 이미지 로딩 + 동적 카드 수 지원
3. `ShufflePage`에서 `DeckMetadata.totalCards`를 조회하여 `TarotGame`에 전달

## 구현 순서

### Step 1: TarotGame — deckId/cardCount 파라미터 + Sprite 로딩

**파일**: `mobile/lib/features/shuffle/presentation/game/tarot_game.dart`

**변경 내용**:

1-A. 생성자에 `deckId`, `cardCount` 파라미터 추가:

```dart
class TarotGame extends Forge2DGame<TarotWorld> {
  final String deckId;
  final int cardCount;

  TarotGame({required this.deckId, required this.cardCount})
      : super(
          world: TarotWorld(gravity: Vector2(0, 0)),
          zoom: TarotCoordinateUtils.kPixelPerMeter,
        );
```

1-B. `onLoad()`에서 `images.load()`로 card_back.webp 로딩 후 `_spawnCards()` 호출:

```dart
@override
Future<void> onLoad() async {
  await super.onLoad();
  await images.load('$deckId/card_back.webp');
  _spawnCards();
}
```

- `images.load('rws/card_back.webp')` → Flame 기본 prefix `assets/images/` 적용 → `assets/images/rws/card_back.webp` (프로젝트 에셋 경로와 일치)
- `await` 완료 후 `_spawnCards()` 호출 → CardBodyComponent.onLoad()에서 `fromCache()` 안전

1-C. `_spawnCards()`에서 하드코딩 `22` → `cardCount` 파라미터 사용:

```dart
void _spawnCards() {
  final rng = math.Random.secure();

  for (var i = 0; i < cardCount; i++) {
```

1-D. CardBodyComponent 생성 시 `deckId` 전달 (Step 2에서 사용):

```dart
world.add(CardBodyComponent(
  deckId: deckId,
  initialPosition: Vector2(...),
  initialVelocity: Vector2(...),
  initialAngularVelocity: ...,
  renderPriority: i,
));
```

### Step 2: CardBodyComponent — SpriteComponent child 패턴

**파일**: `mobile/lib/features/shuffle/presentation/game/card_body_component.dart`

**변경 내용**:

2-A. 생성자에 `deckId` 파라미터 추가:

```dart
final String deckId;

CardBodyComponent({
  required this.deckId,
  required this.initialPosition,
  required this.initialVelocity,
  required this.initialAngularVelocity,
  required this.renderPriority,
}) : super(renderBody: false);
```

2-B. `onLoad()` 오버라이드 추가 — SpriteComponent를 child로 add:

```dart
@override
Future<void> onLoad() async {
  await super.onLoad();
  final image = game.images.fromCache('$deckId/card_back.webp');
  final sprite = Sprite(image);
  add(SpriteComponent(
    sprite: sprite,
    size: Vector2(halfWidth * 2, halfHeight * 2),
    anchor: Anchor.center,
  ));
}
```

- `game.images.fromCache()` — TarotGame.onLoad()에서 이미 로딩 완료, 동기적 캐시 조회
- `size: Vector2(0.6, 0.9)` — body fixture의 `setAsBoxXY(0.3, 0.45)`와 정확히 일치
- `anchor: Anchor.center` — body 중심 정렬 (BodyComponent renderTree()가 body.position을 canvas에 적용한 상태)
- Research R-003-F1: SpriteComponent child 패턴은 프로젝트의 HandAnimationComponent와 동일한 접근

2-C. `render()` 메서드의 코드 드로잉 전체 제거:

기존 `render()` 메서드(57-136행)를 삭제한다. SpriteComponent가 child로 추가되었으므로 `renderTree()`가 자동 렌더링한다.

- 색상 상수 (`_cFaceTop`, `_cFaceBot`, `_cBorder`, `_cPattern`, `_cEdge`, `_cEdgeDark`)도 삭제
- `flutter/material.dart` import도 삭제 (Color 더 이상 미사용)
- `flame/components.dart`에서 `Sprite`, `SpriteComponent` import 추가

**코드 드로잉 제거 근거**: card_back.webp 이미지 자체가 완성된 카드 뒷면 디자인을 포함한다. 동적 그림자(속도 기반)는 시각적 가치가 있으나, 실제 카드 이미지 위에 코드 그림자를 합성하면 부자연스러울 수 있다. 먼저 Sprite만으로 시각 품질을 확인하고, 필요 시 verify 단계에서 그림자 추가를 검토한다.

2-D. 필요한 import 변경:

```dart
import 'package:flame/components.dart';  // SpriteComponent, Sprite
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/services.dart';  // HapticFeedback (유지)

import 'tarot_game.dart';
```

`flutter/material.dart` import 제거 (Color 미사용).

### Step 3: ShufflePage — TarotGame에 deckId + cardCount 전달

**파일**: `mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart`

**변경 내용**:

3-A. DeckMetadata 조회를 위한 provider 사용. `ConsumerStatefulWidget`이므로 `ref.read` 사용 가능:

```dart
import '../../deck/presentation/providers/deck_providers.dart';
```

3-B. `initState()`에서 TarotGame 생성 시 deckId와 cardCount 전달. `initState()`에서 `ref`에 직접 접근하는 것은 Riverpod에서 `ConsumerStatefulWidget`의 경우 가능하지만, 비동기 데이터(getDeckById)가 필요하므로 두 가지 방식을 고려해야 한다.

**방식 선택: FutureProvider + AsyncValue 패턴**

ShufflePage가 이미 `deckId`를 보유하고 있고, `deck_providers.dart`에 `deckRepository`가 `@Riverpod(keepAlive: true)`로 등록되어 있다. 가장 간단한 방식은 `initState`를 제거하고 `build()` 내에서 deck 메타데이터를 비동기 조회한 뒤 TarotGame을 생성하는 것이다.

그러나 TarotGame은 `late` 필드로 `_game`에 보관되며 재시작(`_restartGame`)에서 재생성된다. 비동기 조회와 즉시 게임 생성의 양립을 위해 다음 패턴을 사용한다:

```dart
int _cardCount = 78;  // 기본값 (대부분의 타로 덱)

@override
void initState() {
  super.initState();
  _loadDeckAndCreateGame();
}

Future<void> _loadDeckAndCreateGame() async {
  final repo = ref.read(deckRepositoryProvider);
  final deck = await repo.getDeckById(widget.deckId);
  if (deck != null && mounted) {
    setState(() {
      _cardCount = deck.totalCards;
      _game = TarotGame(deckId: widget.deckId, cardCount: _cardCount);
    });
  }
}
```

초기 `_game` 생성을 `_loadDeckAndCreateGame()` 안으로 이동하여, 덱 메타데이터 조회 완료 후 정확한 cardCount로 게임을 생성한다.

**문제**: `_game`이 `late`이므로 `build()`에서 접근 시 아직 초기화되지 않았을 수 있다.

**해결**: `_game`을 nullable(`TarotGame?`)로 변경하고, `build()`에서 null이면 로딩 인디케이터를 표시한다:

```dart
TarotGame? _game;
int _cardCount = 78;

@override
void initState() {
  super.initState();
  _loadDeckAndCreateGame();
}

Future<void> _loadDeckAndCreateGame() async {
  final repo = ref.read(deckRepositoryProvider);
  final deck = await repo.getDeckById(widget.deckId);
  if (!mounted) return;
  setState(() {
    _cardCount = deck?.totalCards ?? 78;
    _game = TarotGame(deckId: widget.deckId, cardCount: _cardCount);
  });
}

void _restartGame() {
  setState(() {
    _game = TarotGame(deckId: widget.deckId, cardCount: _cardCount);
    _rotateX = 0.65;
    _rotateY = 0.0;
    _zoom = 0.001;
  });
}
```

3-C. `build()` 내 GameWidget 부분에 null 체크 추가:

```dart
child: _game == null
    ? const Center(child: CircularProgressIndicator())
    : Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, _zoom)
          ..rotateX(_rotateX)
          ..rotateY(_rotateY),
        alignment: Alignment.center,
        child: GameWidget<TarotGame>(
          key: ValueKey(_game),
          game: _game!,
        ),
      ),
```

## 고려사항

### 카드 크기와 Sprite 일치

- `CardBodyComponent`의 물리 body: `setAsBoxXY(0.3, 0.45)` → 0.6m x 0.9m
- SpriteComponent `size`: `Vector2(0.6, 0.9)` — 정확히 일치
- card_back.webp 원본(703x1173)의 종횡비 ≈ 0.599 ≈ 0.6/0.9 = 0.667. 약간의 비율 차이가 있으나 (webp가 더 세로로 긴), SpriteComponent가 지정된 size로 스트레치하므로 미미한 왜곡. 육안으로 거의 구분 불가.
- 만약 비율 불일치가 시각적으로 거슬릴 경우, verify 단계에서 `halfWidth`/`halfHeight` 비율을 webp 종횡비에 맞춰 조정 검토 (예: `halfWidth=0.27, halfHeight=0.45` → 0.54/0.9 = 0.6 ≈ webp 비율).

### 카드 수 증가에 따른 물리 파라미터

- **현재**: 22장, `linearDamping: 3.5`, `speed: 2.0 + random * 4.0`
- **64장(이칭)**: 카드 밀도 ~2.9배 증가. 카드 간 겹침과 충돌이 증가하여 산란이 충분히 퍼지지 않을 수 있음.
- **78장(RWS)**: 카드 밀도 ~3.5배 증가. 더 큰 영향.
- **이번 구현에서는 물리 파라미터를 변경하지 않는다.** 실제 시뮬레이션을 실행하여 시각적 결과를 확인한 후, verify 단계에서 다음 튜닝을 검토:
  - `initialVelocity` 범위를 카드 수에 비례하여 증가 (더 넓게 퍼뜨림)
  - `linearDamping`을 카드 수에 반비례하여 감소 (더 멀리 이동)
  - 산란 중심 영역(`initialPosition` 범위) 확대
- DevTuner가 이미 셔플 변수를 등록하고 있으므로, 런타임 튜닝으로 최적값을 찾을 수 있다.

### Flame import 구조

- `SpriteComponent`와 `Sprite`는 `package:flame/components.dart`에서 export된다.
- `flame_forge2d` 패키지가 `flame`을 re-export하므로 별도 `flame` import 없이도 접근 가능할 수 있으나, 명시적 import가 안전하다.
- 실제 빌드 시 확인하여 필요 최소한의 import만 유지.

## 완료 체크리스트

- [ ] `TarotGame` 생성자에 `deckId`, `cardCount` 파라미터 추가
- [ ] `TarotGame.onLoad()`에서 `images.load('$deckId/card_back.webp')` 호출
- [ ] `_spawnCards()`에서 하드코딩 `22` → `cardCount` 사용
- [ ] `CardBodyComponent`에 `deckId` 파라미터 추가
- [ ] `CardBodyComponent.onLoad()`에서 `SpriteComponent` child 추가
- [ ] `CardBodyComponent.render()` 코드 드로잉 제거 + 미사용 색상 상수 제거
- [ ] `ShufflePage`에서 `DeckMetadata.totalCards` 조회 → `TarotGame`에 전달
- [ ] `ShufflePage._restartGame()`에서 새 `TarotGame` 생성 시 deckId/cardCount 전달
- [ ] `ShufflePage.build()`에서 `_game == null` 로딩 상태 처리
- [ ] Flutter 빌드 성공 확인
- [ ] 셔플 화면에서 card_back.webp 이미지가 올바르게 렌더링되는지 확인

## 참조 파일

| 파일 | 역할 |
|------|------|
| `mobile/lib/features/shuffle/presentation/game/tarot_game.dart` | Modified — deckId/cardCount 파라미터, Sprite 로딩 |
| `mobile/lib/features/shuffle/presentation/game/card_body_component.dart` | Modified — SpriteComponent child, 코드 드로잉 제거 |
| `mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart` | Modified — 덱 메타데이터 조회, TarotGame 파라미터 전달 |
| `mobile/lib/features/shuffle/presentation/game/hand_animation_component.dart` | Reference — child 컴포넌트 패턴 선례 |
| `mobile/lib/features/deck/domain/entities/deck_metadata.dart` | Reference — totalCards 필드 |
| `mobile/lib/features/deck/presentation/providers/deck_providers.dart` | Reference — deckRepositoryProvider |

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
