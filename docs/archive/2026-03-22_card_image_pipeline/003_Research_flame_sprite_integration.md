---
id: "003"
type: research
title: "Flame Sprite를 Forge2D BodyComponent에 통합하는 패턴 — 뒷면 이미지 렌더링 + 동적 카드 수"
created: 2026-03-22
traces_scope: "002"
summary: >
  Forge2D BodyComponent 내 Sprite 렌더링은 SpriteComponent를 child로 추가하는 패턴이 정석.
  BodyComponent.renderTree()가 body.position/angle로 canvas를 자동 변환하므로 child의 좌표 매핑이 자동 처리됨.
  TarotGame.images.load()로 덱별 card_back.webp를 1회 로딩 후 fromCache()로 공유하면 N장 카드에 Sprite 인스턴스 1개만 필요.
  webp는 Flutter 네이티브 디코딩 지원, card_back 1장(703x1173)은 메모리 ~3.2MB로 부담 없음.
  cacheWidth/cacheHeight는 Flame Sprite가 아닌 Flutter Image.asset 위젯에만 적용 — 결과 화면 앞면 이미지에 활용.
keywords: [flame-sprite, forge2d, body-component, sprite-component, webp, cacheWidth, image-sharing]
---

# Flame Sprite를 Forge2D BodyComponent에 통합하는 패턴

## Research Overview

### Background & Motivation

현재 `CardBodyComponent.render()`는 Canvas API로 직접 그라디언트/패턴/테두리를 그려 카드 뒷면을 표현한다 (`card_body_component.dart:57-136`). Brief(001)에서 이를 실제 `card_back.webp` 이미지의 Flame Sprite 렌더링으로 교체하기로 결정했다. 덱당 1장의 card_back 이미지를 모든 CardBodyComponent 인스턴스가 공유해야 하며, 덱별 카드 수(64장/78장)를 동적으로 반영해야 한다.

### Research Scope

**조사 범위:**
1. Forge2D BodyComponent.render(Canvas) 내에서 Sprite를 올바르게 렌더링하는 패턴
2. TarotGame.images에서 로딩한 이미지를 다수 CardBodyComponent가 공유하는 방법
3. webp 이미지의 Flame 내 디코딩 성능 특성
4. Flutter Image.asset cacheWidth/cacheHeight의 메모리 영향 (결과 화면 대비)

**조사 제외:** 결과 화면 앞면 이미지 구현 (사이클 2), 덱 선택 UI (사이클 2)

### Research Perspectives

1. **Flame/Forge2D Sprite 통합 패턴** — BodyComponent 내 이미지 렌더링의 정확한 아키텍처, 좌표 변환, 이미지 공유 메커니즘

---

## Perspective 1: Flame/Forge2D Sprite 통합 패턴

### 1. BodyComponent의 Canvas 변환 메커니즘

#### Status Analysis

`BodyComponent.renderTree()` 소스 코드(flame_forge2d 패키지)를 확인한 결과, canvas 변환이 자동으로 적용된다:

```dart
// flame_forge2d BodyComponent.renderTree() — 핵심 발췌
@override
void renderTree(Canvas canvas) {
  final matrix = _transformMatrix;
  if (matrix.m41 != body.position.x ||
      matrix.m42 != body.position.y ||
      _lastAngle != angle) {
    matrix.setIdentity();
    matrix.translateByDouble(body.position.x, body.position.y, 0.0, 1.0);
    matrix.rotateZ(angle);
    _lastAngle = angle;
  }
  canvas.save();
  canvas.transform32(matrix.storage);
  super.renderTree(canvas);  // ← 여기서 render() + children 렌더링
  canvas.restore();
}
```

**핵심 발견**: `renderTree()`가 body의 position과 angle을 Matrix4로 변환하여 canvas에 적용한 후 `super.renderTree()`를 호출한다. 이 시점에서:
- `render(Canvas)` 메서드가 호출됨 (현재 CardBodyComponent의 코드 드로잉)
- **children 컴포넌트도 렌더링됨** (Flame의 Component 트리 구조)

따라서 child로 추가된 SpriteComponent는 body의 위치/회전이 이미 적용된 좌표계에서 렌더링된다.

#### Detailed Findings

**패턴 A: SpriteComponent를 child로 추가 (권장)**

```dart
class CardBodyComponent extends BodyComponent<TarotGame> {
  CardBodyComponent({...}) : super(renderBody: false);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final sprite = Sprite(game.images.fromCache('rws/card_back.webp'));
    add(SpriteComponent(
      sprite: sprite,
      size: Vector2(halfWidth * 2, halfHeight * 2),  // world meters
      anchor: Anchor.center,
    ));
  }
}
```

이 패턴의 장점:
- `renderTree()`의 canvas 변환이 자동 적용 — 위치/회전 수동 처리 불필요
- Flame의 표준 컴포넌트 트리 패턴 준수
- 프로젝트 내 `HandAnimationComponent`가 이미 동일 패턴 사용 (`hand_animation_component.dart:65-68`에서 `RiveComponent`를 child로 추가)

`SpriteComponent`의 `size`는 **world meters 단위** (BodyComponent 로컬 공간). `CardBodyComponent`의 카드 크기가 `halfWidth=0.3, halfHeight=0.45` 이므로 `size: Vector2(0.6, 0.9)`가 된다. `anchor: Anchor.center`로 body 중심에 정렬.

**패턴 B: render() 내에서 Sprite.render() 직접 호출 (대안)**

```dart
late Sprite _backSprite;

@override
Future<void> onLoad() async {
  await super.onLoad();
  _backSprite = Sprite(game.images.fromCache('rws/card_back.webp'));
}

@override
void render(Canvas canvas) {
  _backSprite.render(
    canvas,
    position: Vector2(-halfWidth, -halfHeight),
    size: Vector2(halfWidth * 2, halfHeight * 2),
  );
}
```

이 패턴도 동작하지만:
- canvas 원점이 body 중심이므로 position을 `(-halfWidth, -halfHeight)`로 수동 지정해야 함
- `renderTree()`가 이미 body transform을 적용했으므로 추가 변환은 불필요
- 패턴 A보다 저수준이나, 그림자·엣지 등 추가 캔버스 드로잉을 Sprite와 조합할 때 유용

**패턴 선택 근거:** 패턴 A가 프로젝트의 기존 패턴(HandAnimationComponent)과 일관되고, Flame의 공식 권장 방식이며, 코드가 간결하다. 다만 현재 render()에 그림자/엣지 효과가 있으므로, 기존 코드 드로잉을 완전히 제거하는 경우 패턴 A가 깔끔하고, 일부 효과(예: 동적 그림자)를 유지하려면 패턴 B로 render() 내에서 sprite + 추가 드로잉을 조합할 수 있다.

### 2. 이미지 로딩과 공유 메커니즘

#### Status Analysis

Flame의 `Images` 클래스 소스를 분석한 결과:

```dart
// Flame Images 클래스 생성자
Images({
  String prefix = 'assets/images/',  // 기본 prefix
  AssetBundle? bundle,
})

// load() → _fetchToMemory()
Future<Image> _fetchToMemory(String name, {String? package}) async {
  final prefix = package == null ? _prefix : 'packages/$package/$_prefix';
  final data = await bundle.load('$prefix$name');
  final bytes = Uint8List.view(data.buffer);
  return decodeImageFromList(bytes);
}
```

**경로 해석 규칙:**
- `game.images.load('rws/card_back.webp')` → `assets/images/rws/card_back.webp`
- `game.images.load('iching_holitzka/card_back.webp')` → `assets/images/iching_holitzka/card_back.webp`

이는 `pubspec.yaml`의 에셋 선언(`assets/images/rws/`, `assets/images/iching_holitzka/`)과 정확히 일치한다.

#### Detailed Findings

**이미지 공유 패턴: TarotGame에서 1회 로딩 → CardBodyComponent에서 fromCache()**

```dart
// TarotGame.onLoad()
@override
Future<void> onLoad() async {
  await super.onLoad();
  await images.load('$deckId/card_back.webp');  // 1회 로딩, 자동 캐시
  _spawnCards();
}

// CardBodyComponent.onLoad()
@override
Future<void> onLoad() async {
  await super.onLoad();
  // game = TarotGame (BodyComponent<TarotGame>로 이미 타입 접근 가능)
  final image = game.images.fromCache('$deckId/card_back.webp');  // 캐시에서 동기적 조회
  final sprite = Sprite(image);
  add(SpriteComponent(
    sprite: sprite,
    size: Vector2(halfWidth * 2, halfHeight * 2),
    anchor: Anchor.center,
  ));
}
```

**핵심 메커니즘:**
- `images.load(fileName)`은 파일명을 키로 자동 캐시한다 (`_assets[key ?? fileName]`). 같은 파일명으로 여러 번 호출해도 1회만 디코딩.
- `images.fromCache(name)`은 캐시에서 **동기적으로** `dart:ui.Image` 객체를 반환한다. `CardBodyComponent.onLoad()`에서 안전하게 사용 가능 (TarotGame.onLoad()에서 이미 로딩 완료 후 `_spawnCards()`가 호출되므로).
- `Sprite(image)` 생성은 `dart:ui.Image` 참조만 보유 — 이미지 데이터 복사 없음. 22~78장의 CardBodyComponent가 각각 `Sprite` 인스턴스를 생성해도 실제 이미지 메모리는 1장분.

**deckId 전달 방식:**

현재 `TarotGame()` 생성자에 파라미터가 없다 (`tarot_game.dart:13-18`). `ShufflePage`가 이미 `deckId`를 보유하므로 (`shuffle_page.dart:11`) 이를 TarotGame에 전달하면 된다:

```dart
class TarotGame extends Forge2DGame<TarotWorld> {
  final String deckId;
  final int cardCount;

  TarotGame({required this.deckId, required this.cardCount})
      : super(world: TarotWorld(gravity: Vector2(0, 0)),
              zoom: TarotCoordinateUtils.kPixelPerMeter);
}
```

`ShufflePage`에서 `DeckMetadata.totalCards`를 조회하여 `cardCount`로 전달.

### 3. webp 이미지의 Flame 내 디코딩 성능

#### Status Analysis

card_back.webp 파일 정보:
- **RWS**: 703x1173px, VP8 encoding (lossy), 252KB
- **I Ching Holitzka**: 700x1212px, VP8 encoding (lossy), 172KB

#### Detailed Findings

**디코딩 과정:**
1. `bundle.load('assets/images/rws/card_back.webp')` → `ByteData`로 읽기 (I/O, ~1-5ms)
2. `decodeImageFromList(bytes)` → Flutter 네이티브 디코더가 webp → RGBA 비트맵 변환
3. 결과 `dart:ui.Image` 객체는 GPU 텍스처로 업로드됨

**메모리 사용량 계산:**

디코딩된 비트맵(RGBA, 4 bytes/pixel):
- **RWS card_back**: 703 × 1173 × 4 = **3,298,116 bytes ≈ 3.15MB**
- **I Ching card_back**: 700 × 1212 × 4 = **3,393,600 bytes ≈ 3.24MB**

단일 이미지이며 모든 카드가 공유하므로 카드 수(22~78장)와 무관하게 **고정 ~3.2MB**. 모바일 환경에서 부담 없는 수준.

**webp 특성:**
- Flutter는 webp를 네이티브로 지원 (Skia/Impeller 내장 코덱). 별도 패키지 불필요.
- webp lossy 디코딩은 PNG 무손실 디코딩보다 CPU 비용이 약간 높을 수 있으나, card_back 1장만 로딩하므로 차이 무의미.
- webp는 PNG 대비 25-35% 작은 파일 크기 → I/O 시간 절약으로 상쇄.
- Flame `Images` 클래스가 자동 캐시하므로 게임 세션 내 재디코딩 없음.

**렌더링 성능:**
- `Sprite.render()`는 내부적으로 `canvas.drawImageRect()`를 호출 — GPU 가속 텍스처 드로잉.
- 22~78장의 카드가 동일 텍스처를 참조하므로 GPU batch 최적화 가능.
- 현재 코드 드로잉(그라디언트, 패스, 블러 필터)보다 단일 텍스처 드로잉이 **더 빠를 가능성이 높음** (특히 `MaskFilter.blur`가 비용이 큰 연산).

### 4. cacheWidth/cacheHeight의 메모리 영향 (결과 화면 대비)

#### Status Analysis

`cacheWidth`/`cacheHeight`는 **Flutter의 `Image.asset` 위젯**에만 적용되는 파라미터이다. Flame의 `Sprite`/`Images` 클래스에는 해당 파라미터가 없다.

#### Detailed Findings

**Flutter Image.asset의 cacheWidth/cacheHeight 메커니즘:**

```dart
Image.asset(
  'assets/images/rws/card_01.webp',
  cacheWidth: 200,  // 디코딩 시 이 크기로 다운스케일
)
```

- 이미지를 디스크에서 읽은 후 **디코딩 단계에서** 지정 크기로 리사이즈하여 메모리에 저장.
- 원본: 703 × 1173 × 4 = 3.15MB → `cacheWidth: 200` (비율 유지 cacheHeight: 334): 200 × 334 × 4 = **267KB** → **91.5% 메모리 절감**.
- `devicePixelRatio` 고려 권장: `cacheWidth: (displayWidth * devicePixelRatio).toInt()`

**Flame Sprite에서의 적용 불가:**
- Flame `Images.load()`는 원본 해상도로 디코딩하여 `dart:ui.Image`를 생성한다.
- 다운스케일하려면 별도로 `pictureRecorder` + `Canvas`로 축소 이미지를 수동 생성해야 하나, card_back 1장(~3.2MB)에 대해 이 작업은 불필요.
- Flame의 `Sprite.render()`에 `size` 파라미터로 렌더링 크기를 지정하면, GPU가 런타임에 스케일링을 처리하므로 화질/성능 모두 충분.

**결과 화면(사이클 2)에서의 활용:**
- 스프레드 뷰 썸네일(화면 너비의 1/3~1/4): `cacheWidth: 120~150`으로 카드당 ~200KB
- 3장 스프레드 기준: 원본 3장 = 9.5MB → `cacheWidth` 적용 시 ~600KB → **93.7% 절감**
- 10장 스프레드 기준: 원본 10장 = 31.5MB → `cacheWidth` 적용 시 ~2MB → **93.7% 절감**
- 카드 확대(탭하여 큰 이미지): `cacheWidth: 400~500`으로 카드당 ~1MB

### Caveats & Risks

1. **onLoad 실행 순서**: `CardBodyComponent.onLoad()` 에서 `game.images.fromCache()`를 호출하려면 TarotGame.onLoad()에서 이미지 로딩이 **먼저 완료**되어야 한다. 현재 코드에서 `TarotGame.onLoad()` → `_spawnCards()` 순서이므로, `images.load()` await 후 `_spawnCards()` 호출하면 안전하다.

2. **SpriteComponent size와 Forge2D body fixture 크기 일치**: SpriteComponent의 `size`를 body fixture의 `setAsBoxXY(halfWidth, halfHeight)`와 동일하게 맞춰야 이미지가 물리 충돌 영역과 정확히 겹친다. `size: Vector2(halfWidth * 2, halfHeight * 2)`.

3. **renderBody: false 확인**: `CardBodyComponent` 생성자에서 이미 `super(renderBody: false)` 설정 중 (`card_body_component.dart:33`). Sprite 교체 후에도 유지해야 fixture debug 렌더링이 표시되지 않음.

4. **기존 render() 코드 드로잉**: 패턴 A(SpriteComponent child)를 사용하면 기존 `render()` 메서드의 코드 드로잉(그림자, 그라디언트, 테두리 등 `card_body_component.dart:57-136`)을 제거하거나 빈 메서드로 교체해야 한다. 패턴 B를 사용하면 render() 내에서 sprite + 추가 효과를 조합할 수 있다.

5. **카드 수 변경 시 물리 밀도**: 22장 → 78장으로 카드 수가 증가하면 물리 시뮬레이션의 밀도가 높아진다. `linearDamping`, `initialVelocity` 범위, 산란 각도를 카드 수에 따라 조정할 필요가 있을 수 있다.

### Summary

BodyComponent 내 Sprite 렌더링은 SpriteComponent를 child로 추가하는 것이 Flame의 표준 패턴이며, 프로젝트의 기존 HandAnimationComponent와도 일관된다. renderTree()가 body transform을 자동 적용하므로 별도 좌표 처리가 불필요하다.

---

## Cross-Analysis

### Inter-Perspective Relationships

4개 연구 질문이 하나의 구현 흐름으로 연결된다:

1. **이미지 로딩** (Q2, Q3): `TarotGame.onLoad()`에서 `images.load('$deckId/card_back.webp')` → 1회 디코딩, 자동 캐시. webp 네이티브 지원으로 추가 작업 없음.
2. **이미지 렌더링** (Q1): 각 `CardBodyComponent.onLoad()`에서 `fromCache()` → `Sprite()` → `SpriteComponent` child 추가. body transform 자동 적용.
3. **메모리 관리** (Q3, Q4): card_back 1장 ~3.2MB 고정. cacheWidth는 Flame Sprite에 해당 없음 — 사이클 2의 Flutter Image.asset에서 활용.

### Common Patterns

- **캐시 기반 공유**: Flame `Images`와 Flutter `ImageCache` 모두 파일명 키 기반 자동 캐시. 동일 이미지의 중복 디코딩 방지.
- **child 컴포넌트 패턴**: HandAnimationComponent(RiveComponent child)와 CardBodyComponent(SpriteComponent child)가 동일한 "BodyComponent + visual child" 패턴. 프로젝트 내 일관성 유지.

### Conflicting Items

- **그림자 효과 유지 여부**: 현재 render()의 동적 그림자(속도 기반 크기/블러 변화)는 시각적 가치가 있으나, Sprite 이미지로 교체하면 기본적으로 사라진다. 그림자를 유지하려면 render()에서 그림자만 그린 후 SpriteComponent가 그 위에 렌더링되도록 해야 한다 (render()가 children 렌더링 전에 호출되므로 가능). 또는 그림자를 Sprite 이미지에 포함시키거나, 별도 그림자 컴포넌트를 추가할 수 있다. 이는 구현 단계에서 판단할 사항.

## Comprehensive Conclusion

### 핵심 발견 (우선순위 순)

1. **[Critical] R-003-F1: SpriteComponent child 패턴이 정석** — BodyComponent.renderTree()가 body.position/angle을 canvas에 자동 변환하므로, SpriteComponent를 child로 add()하면 위치/회전 동기화가 자동 처리된다. render() 내 Sprite.render() 직접 호출(패턴 B)도 동작하나, 프로젝트의 기존 패턴(HandAnimationComponent)과 Flame 공식 가이드 모두 child 패턴을 사용한다. *(관점 1, 발견 패턴 A)*

2. **[Critical] R-003-F2: images.load() → fromCache() 공유 패턴** — TarotGame.onLoad()에서 `images.load('$deckId/card_back.webp')`로 1회 로딩 후, 각 CardBodyComponent가 `game.images.fromCache()`로 동기적 조회. dart:ui.Image 참조만 공유하므로 카드 수 무관하게 이미지 메모리 1장분(~3.2MB). Flame Images 클래스의 기본 prefix `'assets/images/'`가 프로젝트 에셋 경로와 일치. *(관점 1, 이미지 로딩 분석)*

3. **[High] R-003-F3: webp 1장 디코딩 비용 무시 가능** — card_back.webp는 172~252KB 파일, 디코딩 후 ~3.2MB RGBA 비트맵. Flutter 네이티브 webp 코덱으로 별도 패키지 불필요. 현재 코드 드로잉(MaskFilter.blur 포함)보다 단일 텍스처 드로잉이 더 효율적일 가능성 높음. *(관점 1, 성능 분석)*

4. **[High] R-003-F4: cacheWidth/cacheHeight는 사이클 2 전용** — Flame Sprite에는 해당 파라미터 없음. Flutter Image.asset에서 사용하며, 결과 화면 스프레드 뷰에서 카드 앞면 이미지(3~10장)의 메모리를 93%+ 절감 가능. *(관점 1, 메모리 분석)*

5. **[Medium] R-003-F5: 동적 카드 수 전달 경로** — ShufflePage(deckId 보유) → TarotGame(deckId, cardCount 파라미터 추가) → _spawnCards(cardCount 사용). DeckMetadata.totalCards에서 값 조회. 현재 22장 하드코딩(`tarot_game.dart:30`)을 파라미터로 교체. *(관점 1, 데이터 흐름 분석)*

6. **[Medium] R-003-F6: 카드 수 증가 시 물리 조정 필요 가능** — 22장 → 78장에서 산란 밀도가 3.5배 증가. linearDamping, initialVelocity 범위를 카드 수에 비례하여 조정하거나, 산란 영역을 넓히는 튜닝이 필요할 수 있다. *(관점 1, 물리 분석)*

7. **[Low] R-003-F7: 기존 그림자 효과 결정 필요** — 현재 render()의 동적 그림자/엣지 효과를 Sprite 교체 시 유지할지 결정 필요. 구현 단계에서 판단. *(관점 1, 렌더링 분석)*

## Unresolved Items

- **그림자 효과 유지 여부**: 최종 결정은 구현 시 시각적 품질 확인 후 판단. card_back.webp 이미지 자체에 충분한 시각적 깊이가 있으면 코드 그림자 제거 가능. 이는 구현 단계의 디자인 판단이므로 research 범위를 넘어감.
- **78장 물리 파라미터 튜닝 값**: 정확한 값은 실제 시뮬레이션 테스트로만 결정 가능. 구현 후 DevTuner로 조정.

## Referenced File List

| File Path | Related Perspective | Role/Content |
|-----------|-------------------|--------------|
| `mobile/lib/features/shuffle/presentation/game/card_body_component.dart` | 관점 1 | 현재 render() 코드 드로잉 (교체 대상). halfWidth=0.3, halfHeight=0.45 |
| `mobile/lib/features/shuffle/presentation/game/tarot_game.dart` | 관점 1 | 현재 22장 하드코딩, images 로딩 미구현 |
| `mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart` | 관점 1 | deckId 보유, TarotGame에 파라미터 전달 필요 |
| `mobile/lib/features/shuffle/presentation/game/hand_animation_component.dart` | 관점 1 | child 컴포넌트 패턴 선례 (RiveComponent) |
| `mobile/lib/features/shuffle/presentation/game/tarot_coordinate_utils.dart` | 관점 1 | kPixelPerMeter=100, 좌표 변환 유틸 |
| `mobile/lib/features/deck/domain/entities/deck_metadata.dart` | 관점 1 | totalCards 필드 (동적 카드 수 소스) |
| `mobile/pubspec.yaml` | 관점 1 | flame: ^1.19.0, flame_forge2d: ^0.19.0, 에셋 선언 |
| `mobile/assets/images/rws/card_back.webp` | 관점 1 | 703x1173px, VP8 lossy, 252KB |
| `mobile/assets/images/iching_holitzka/card_back.webp` | 관점 1 | 700x1212px, VP8 lossy, 172KB |

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
