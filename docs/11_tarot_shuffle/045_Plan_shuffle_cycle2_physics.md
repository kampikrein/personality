---
id: "045"
type: plan
title: "셔플 엔진 Cycle 2 — Physics & Animation (CardBody + Hand + SensorGravity)"
created: 2026-03-16
traces_scope: "043"
traces_research: "042"
summary: >
  forge2d DynamicBody 카드 78장 + Rive KinematicBody 손 + 가속도계 중력 컨트롤러 구현.
  TarotGame.onLoad()에서 3개 컴포넌트를 활성화. 폰 기울이기에 카드가 즉각 반응하는 물리 레이어 완성.
keywords: [forge2d, DynamicBody, KinematicBody, RiveComponent, accelerometer, sensors_plus, haptic]
---

# 045 — 셔플 엔진 Cycle 2: Physics & Animation

## Goal

Cycle 1에서 구축한 `TarotGame / TarotWorld` 위에 실제 물리 동작 레이어를 추가한다.

1. `CardBodyComponent` — forge2d DynamicBody 카드 1장. 78개 인스턴스.
2. `HandAnimationComponent` — Rive 손 애니메이션 + KinematicBody 동기화. .riv 없으면 graceful fallback.
3. `SensorGravityController` — 가속도계 → 로우패스 필터 → `world.gravity` 실시간 업데이트.
4. `TarotGame.onLoad()` — 3개 컴포넌트 실제 활성화 (TODO 주석 교체).

완료 후: 폰을 기울이면 카드 78장이 중력 방향에 따라 물리적으로 움직이는 상태.

## Scope

### Included
| # | 항목 | 설명 |
|---|------|------|
| 1 | CardBodyComponent | forge2d DynamicBody + Research 036 확정 파라미터 |
| 2 | HandAnimationComponent | KinematicBody + Rive 로드 시도 (실패 시 graceful fallback) |
| 3 | SensorGravityController | accelerometerEventStream + 로우패스 + world.gravity |
| 4 | TarotGame.onLoad() 수정 | TODO 주석 → 실제 컴포넌트 add 코드 |

### Excluded
| 항목 | 이유 |
|------|------|
| assets/animations/hand_shuffle.riv | Rive 디자인 파일 별도 태스크. HandAnimationComponent가 graceful fallback 처리 |
| pubspec.yaml assets/animations/ 선언 | .riv 파일 없으면 선언 시 빌드 에러 — 파일 준비 후 추가 |
| 카드 드래그/플링 인터랙션 | Cycle 3 이후 (ShufflePage 통합 단계에서 gesture 연결) |
| 카드 이미지 렌더링 | 현재는 debug 사각형. 실제 카드 비주얼은 별도 태스크 |

## Structural Decisions

| # | 결정 | 선택 | 근거 |
|---|------|------|------|
| 1 | SensorGravityController 위치 | **game.add() (게임 루트)** | physics 불필요한 순수 컨트롤러. HasGameReference<TarotGame>로 world 접근 |
| 2 | CardBody / HandBody 위치 | **world.add() (Forge2DWorld)** | BodyComponent.world 접근자가 Forge2DWorld 조상을 탐색. world 내에 있어야 함 |
| 3 | 카드 초기 배치 | **화면 중앙 ±0.25m 랜덤 분산** | 78장 모두 동일 위치 시 물리 불안정. 작은 분산으로 자연스러운 분리 시작 |
| 4 | HandAnimationComponent Rive 로드 | **try-catch + graceful fallback** | Scope 043: ".riv 없으면 플레이스홀더로 먼저 검증". KinematicBody는 항상 동작 |
| 5 | render() 좌표 단위 | **forge2d meters** | BodyComponent.renderTree가 body.position(meters)로 translate. render()에서 0.6 = 60px |

> 구조적 결정 5건 — 연구 확정값 + flame_forge2d 소스 검증 결과 반영. 사용자 추가 확인 불필요.

---

## File Change Summary

### Modified Files
| # | 파일 경로 | 변경 설명 |
|---|-----------|-----------|
| 4 | `mobile/lib/features/shuffle/presentation/game/tarot_game.dart` | onLoad() TODO 주석 → 실제 컴포넌트 add 코드 |

### New Files
| # | 파일 경로 | 설명 |
|---|-----------|------|
| 1 | `mobile/lib/features/shuffle/presentation/game/card_body_component.dart` | forge2d DynamicBody 카드 컴포넌트 |
| 2 | `mobile/lib/features/shuffle/presentation/game/hand_animation_component.dart` | KinematicBody + Rive 손 컴포넌트 |
| 3 | `mobile/lib/features/shuffle/presentation/game/sensor_gravity_controller.dart` | 가속도계 → world.gravity 컨트롤러 |

---

## Step 1 — CardBodyComponent 생성

### Approach

forge2d DynamicBody 카드 1장을 구현한다. 78개 인스턴스가 TarotGame에서 생성된다.

**핵심 파라미터 (Research 036 확정값):**
- `linearDamping: 2.0` — 조작감 결정 파라미터 1위. "무게감"
- `angularDamping: 1.2` — 회전 감쇠
- `density: 1.0, friction: 0.4, restitution: 0.05`
- `allowSleep: true` — 78장 성능 최적화

**카드 크기:** `halfWidth = 0.3m, halfHeight = 0.45m` → 60px × 90px @ zoom=100

**render() 주의:** `BodyComponent.renderTree()`가 `body.position(meters)`로 translate 후 `render(canvas)` 호출.
render 내 좌표는 forge2d meters. `0.6m × 0.9m rect` → 화면에서 60px × 90px.

**BodyComponent 기본 render** (`renderBody=true`): polygon fixture를 흰색으로 그림.
Cycle 2 MVP는 debugMode를 true로 설정해 물리 박스가 보이도록 한다.

### After Code

```dart
// mobile/lib/features/shuffle/presentation/game/card_body_component.dart (신규)
import 'package:flame_forge2d/flame_forge2d.dart';

import '../../../../../../../core/constants/app_constants.dart' // 존재 시
    show AppColors; // 없으면 Color literal 사용
import 'tarot_game.dart';

/// forge2d DynamicBody 타로 카드 1장.
///
/// TarotGame에서 78개 인스턴스 생성.
/// 물리 파라미터는 Research 036 확정값 사용.
class CardBodyComponent extends BodyComponent<TarotGame> {
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
      linearDamping: 2.0,   // 조작감 핵심 파라미터 (Research 036 확정)
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

### Considerations

- `import AppColors` 시도 부분은 실제 파일 존재 여부에 따라 Color literal로 대체.
- `renderBody = true`: 기본 polygon 렌더링으로 Cycle 2에서 카드 위치 확인 가능. Cycle 3에서 실제 카드 이미지로 교체.
- `BodyComponent<TarotGame>` 타입 파라미터: `game` 접근이 필요할 경우를 위해 명시. 없어도 컴파일됨.

---

## Step 2 — HandAnimationComponent 생성

### Approach

Rive 손 애니메이션 + forge2d KinematicBody를 결합한다.

**설계 핵심:**
1. **KinematicBody** — 물리 영향 없이 이동 가능, DynamicBody(카드)와 충돌. Research 037 확정.
2. **Rive 로드 try-catch** — `.riv` 없어도 KinematicBody는 정상 동작. `renderBody=true` fallback으로 원 표시.
3. **RiveComponent as child** — BodyComponent 좌표계(forge2d meters)에서 child 렌더. size 단위도 meters.
4. **Rive-forge2d 동기화** — `.riv` 있을 때: bone.worldTransform → KinematicBody.linearVelocity. Research 037 확정 패턴.

**RiveComponent child 좌표:**
- BodyComponent.renderTree: translate(body.position.x, body.position.y) in meters
- RiveComponent position: 부모 좌표계(meters). center on body: position = Vector2(-width/2, -height/2)
- RiveComponent size: Vector2(4.0, 4.0) → 4m × 4m = 400px × 400px @ zoom=100

**KinematicBody shape:** CircleShape radius=0.3m (30px) — 손 끝 충돌 영역

### After Code

```dart
// mobile/lib/features/shuffle/presentation/game/hand_animation_component.dart (신규)
import 'package:flame/flame.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_rive/flame_rive.dart';

import 'tarot_coordinate_utils.dart';
import 'tarot_game.dart';

/// Rive 손 애니메이션 + forge2d KinematicBody.
///
/// .riv 파일 없을 때: KinematicBody만 동작 (시각 없음).
/// .riv 파일 있을 때: RiveComponent child 렌더 + bone 좌표 동기화.
///
/// Cycle 2에서 body 위치는 고정 (기울이기 물리 검증용).
/// 실제 손 이동 로직은 .riv 파일 완성 후 추가.
class HandAnimationComponent extends BodyComponent<TarotGame> {
  Artboard? _artboard;
  StateMachineController? _smController;
  bool _riveLoaded = false;

  /// 손 초기 위치: 화면 하단 중앙 (y < 0 = 화면 위쪽, 기본 카메라 기준)
  static final Vector2 _initialPosition = Vector2(0.0, -1.0);

  HandAnimationComponent() : super(renderBody: true);

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.kinematic,
      position: _initialPosition,
    );
    // 손 끝 충돌 영역: 반지름 0.3m = 30px
    final shape = CircleShape()..radius = 0.3;
    // Kinematic body: density=0 (isSensor=false → 카드를 밀 수 있음)
    final fixtureDef = FixtureDef(shape, density: 0.0);
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad(); // createBody() 호출
    await _tryLoadRive();
  }

  Future<void> _tryLoadRive() async {
    try {
      // .riv 파일 로드 (없으면 catch로 graceful skip)
      final data = await Flame.bundle.load('assets/animations/hand_shuffle.riv');
      final riveFile = RiveFile.import(data);
      _artboard = riveFile.mainArtboard.instance();
      _smController = StateMachineController.fromArtboard(
        _artboard!,
        'StateMachine', // Rive 에디터에서 설정할 StateMachine 이름
      );
      if (_smController != null) _artboard!.addController(_smController!);
      _riveLoaded = true;

      // RiveComponent를 child로 추가.
      // 좌표계: forge2d meters (BodyComponent 로컬 공간).
      // size 4.0m × 4.0m → 400px × 400px @ zoom=100. body 중앙 정렬.
      await add(
        RiveComponent(
          artboard: _artboard!,
          position: Vector2(-2.0, -2.0), // body 중심 기준 offset (좌상단 → 중앙 정렬)
          size: Vector2(4.0, 4.0),
          priority: 0,
        ),
      );
    } catch (e) {
      // .riv 파일 없음 — KinematicBody만 동작.
      // renderBody=true이므로 원 outline이 debug 렌더됨.
      // ignore: avoid_print
      assert(() {
        // ignore: avoid_print
        print('[HandAnimationComponent] .riv not loaded: $e');
        return true;
      }());
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_riveLoaded || _artboard == null || dt <= 0) return;

    // Rive bone → KinematicBody 동기화 (Research 037 확정 패턴).
    // .riv 파일에 'hand_tip' bone이 있을 때 활성화.
    // TODO(Rive파일준비후): 아래 주석 해제하고 artboardToWorldSimple 사용
    //
    // final bone = _artboard!.component<Bone>('hand_tip');
    // if (bone == null) return;
    // final mat = bone.worldTransform;
    // final worldPos = TarotCoordinateUtils.artboardToWorldSimple(mat[4], mat[5]);
    // body.linearVelocity = (worldPos - body.position) / dt;
    //
    // KinematicBody priority: 0 (RiveComponent) → 1 (physics sync)
    // Flame이 priority 순으로 update 호출 보장
  }
}
```

### Considerations

- `Flame.bundle.load()`: Flutter's rootBundle를 통해 assets 로드. pubspec.yaml 미선언 시 예외 발생 → catch로 처리.
- `RiveFile.import(data)`: 동기 파싱. rive ^0.13.x API. `riveFile.mainArtboard.instance()`로 독립 artboard 인스턴스 생성.
- `artboard.instance()`: 중요 — 여러 컴포넌트가 같은 artboard를 공유하면 state 충돌. `instance()`로 각자 독립 복사본.
- bone 동기화 TODO: `.riv` 파일에 `hand_tip` bone이 있을 때 활성화. Rive 에디터 설계 후 주석 해제.

---

## Step 3 — SensorGravityController 생성

### Approach

가속도계 이벤트를 구독하고, 로우패스 필터를 통해 `world.gravity`를 실시간으로 업데이트한다.

**배치 위치:** `game.add()` (게임 루트 레벨, Forge2DWorld 외부).
`HasGameReference<TarotGame>`으로 `game.world` 접근.

**확정 파라미터 (Research 040, 041):**
- `alpha = 0.20` (로우패스 필터 계수)
- `gravityScale = 3.0` (가속도계값 → gravity 배율)
- `SensorInterval.gameInterval` (Android 필수 — 20ms / 50Hz)

**SensorInterval.gameInterval**: Android에서 `SENSOR_DELAY_GAME`(20ms) 보장. iOS는 기본값(100Hz)이 충분하므로 동일 상수 사용해도 무방.

**world.gravity setter** (Forge2DWorld 내장):
- `physicsWorld.gravity = newGravity`
- `body.setAwake(true)` for all bodies → sleep 중인 카드도 즉각 반응

### After Code

```dart
// mobile/lib/features/shuffle/presentation/game/sensor_gravity_controller.dart (신규)
import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'tarot_game.dart';

/// 가속도계 → forge2d world.gravity 실시간 업데이트 컨트롤러.
///
/// TarotGame에 game.add()로 추가 (world가 아닌 게임 루트 레벨).
/// HasGameReference<TarotGame>으로 game.world.gravity setter 접근.
///
/// 파라미터 (Research 040, 041 확정값):
///   alpha = 0.20 (로우패스 필터 계수)
///   gravityScale = 3.0 (linearDamping=2.0과 쌍으로 튜닝)
class SensorGravityController extends Component with HasGameReference<TarotGame> {
  /// 로우패스 필터 계수 (Research 041 확정값: 신비로운 분위기 = 중간~부드러움)
  static const double _alpha = 0.20;

  /// 가속도계 → gravity 배율 (Research 041: linearDamping 2.0 기준 권장 3.0)
  static const double _gravityScale = 3.0;

  double _rawX = 0.0;
  double _rawY = 9.8; // 기본값: 아래 방향 중력
  double _smoothX = 0.0;
  double _smoothY = 9.8;

  StreamSubscription<AccelerometerEvent>? _subscription;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      _subscription = accelerometerEventStream(
        // SensorInterval.gameInterval: Android 필수 (20ms = 50Hz). Research 040 확정.
        samplingPeriod: SensorInterval.gameInterval,
      ).listen((event) {
        _rawX = event.x;
        _rawY = event.y;
      });
    } catch (e) {
      // 시뮬레이터 또는 센서 미지원 기기: 기본 중력(0, 9.8) 유지
      assert(() {
        // ignore: avoid_print
        print('[SensorGravityController] accelerometer not available: $e');
        return true;
      }());
    }
  }

  @override
  void update(double dt) {
    // 로우패스 필터 (Research 040 확정값: alpha=0.20)
    _smoothX += _alpha * (_rawX - _smoothX);
    _smoothY += _alpha * (_rawY - _smoothY);

    // world.gravity 업데이트 (Research 041 확정값: scale=3.0)
    // Forge2DWorld.gravity setter: 자동으로 모든 body를 setAwake(true)
    game.world.gravity = Vector2(_smoothX * _gravityScale, _smoothY * _gravityScale);
  }

  @override
  void onRemove() {
    _subscription?.cancel();
    super.onRemove();
  }
}
```

### Considerations

- `HasGameReference<TarotGame>`: Flame 컴포넌트가 게임 트리에 mount된 후 `game` getter 사용 가능. onLoad()에서는 사용 가능 (mount 후 호출).
- `accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)`: sensors_plus 5.x API. `SensorInterval.gameInterval` = Android `SENSOR_DELAY_GAME` (20ms). iOS 기본 100Hz 충분.
- gravity setter가 모든 body를 wakeup → sleep 중 카드도 즉각 반응. `allowSleep: true`와 함께 쓸 때 정상 동작.
- `try-catch`: iOS 시뮬레이터에서 sensors_plus가 더미 스트림 반환하므로 catch 불필요할 수도 있으나, 방어적으로 유지.

---

## Step 4 — TarotGame.onLoad() 수정

### Approach

Cycle 1에서 남긴 TODO 주석을 실제 컴포넌트 add 코드로 교체한다.

**컴포넌트 배치 규칙:**
- `add(SensorGravityController())` → game 루트 (physics 없음, controller)
- `world.addAll([...CardBodyComponent...])` → Forge2DWorld (BodyComponent 필수)
- `world.add(HandAnimationComponent())` → Forge2DWorld (BodyComponent)

**카드 78장 초기 위치:** 화면 중앙(world origin ≈ 0,0) 근처에 ±0.25m 랜덤 분산.
forge2d의 기본 camera centerAt(0,0)으로 세계 원점이 화면 중앙에 대응.

### Current Code

```dart
// mobile/lib/features/shuffle/presentation/game/tarot_game.dart:22-27 (현재)
@override
Future<void> onLoad() async {
  await super.onLoad();
  // TODO(Cycle2): add(SensorGravityController());
  // TODO(Cycle2): addAll(List.generate(78, (_) => CardBodyComponent()));
  // TODO(Cycle2): add(HandAnimationComponent());
}
```

### After Code

```dart
// mobile/lib/features/shuffle/presentation/game/tarot_game.dart:1-6 (import 추가)
import 'dart:math';

import 'package:flame_forge2d/flame_forge2d.dart';

import 'tarot_coordinate_utils.dart';
import 'card_body_component.dart';
import 'hand_animation_component.dart';
import 'sensor_gravity_controller.dart';
```

```dart
// mobile/lib/features/shuffle/presentation/game/tarot_game.dart:22-33 (onLoad 교체)
@override
Future<void> onLoad() async {
  await super.onLoad();

  // SensorGravityController: 게임 루트 레벨 (physics 없음, 순수 컨트롤러)
  add(SensorGravityController());

  // CardBodyComponent: Forge2DWorld에 추가 (BodyComponent 필수)
  // 화면 중앙(world origin ~0,0) 근처 ±0.25m 랜덤 분산으로 78장 배치
  final rng = Random();
  world.addAll(
    List.generate(78, (_) => CardBodyComponent(
      initialPosition: Vector2(
        (rng.nextDouble() - 0.5) * 0.5,  // ±0.25m = ±25px random
        (rng.nextDouble() - 0.5) * 0.5,
      ),
    )),
  );

  // HandAnimationComponent: Forge2DWorld에 추가 (KinematicBody 필요)
  world.add(HandAnimationComponent());
}
```

### Considerations

- `dart:math` import: `Random()` 사용을 위해 필요.
- `world.addAll()` / `world.add()`: Flame의 비동기 큐잉. `await` 없이도 다음 프레임에 마운트됨. 의존성 없으므로 await 불필요.
- 카드 랜덤 위치: `rng.nextDouble()` → 0.0~1.0, 중앙화 후 ±0.25m 범위. 모든 카드가 화면 중앙 근처에서 시작.

---

## Considerations & Trade-offs

### Alternative Approaches

| 대안 | 미채택 이유 |
|------|-----------|
| HandAnimationComponent extends PositionComponent | BodyComponent 상속으로 forge2d world 접근, contactCallback 등 통합 용이. PositionComponent 사용 시 세계 참조 수동 관리 필요 |
| 78장 모두 동일 위치 배치 | forge2d에서 동일 위치 다중 body = 폭발적 충돌력 발생. 랜덤 분산 필수 |
| SensorGravityController를 world에 추가 | world에 있어도 동작하지만 게임 루트 레벨이 의미상 명확. 컨트롤러와 물리 객체 분리 |
| .riv 파일 플레이스홀더 직접 생성 | Rive binary 형식은 수동 생성 불가. graceful fallback이 더 robust |

### Potential Risks

1. **BodyComponent renderTree 좌표 혼동**: `body.position`이 forge2d meters인데 render()에서 실수로 pixel 값 사용 시 크기 100배 오차. 검증 필수.
2. **78장 body 성능**: 1000개 이상에서 forge2d 성능 저하 가능. 78장은 Research 036에서 "문제 없음" 확정. `allowSleep=true`로 정적 카드 CPU 절약.
3. **센서 없는 환경**: iOS 시뮬레이터/Android 에뮬레이터에서 accelerometerEventStream이 0값 반환 또는 에러. try-catch 및 기본 중력(0, 9.8)으로 fallback.
4. **RiveComponent size 단위**: meters 단위를 pixel로 혼동 시 400m × 400m = 40000px 렌더링 → 화면 전체 덮음. size: Vector2(4.0, 4.0) = 400px 검증 필요.

### Backward Compatibility

- `shuffle_page.dart`: Cycle 2에서 변경 없음. 여전히 CustomPainter 사용.
- `sensor_data_collector.dart`: Cycle 2에서 변경 없음. 엔트로피 수집 목적이므로 SensorGravityController와 독립.
- Cycle 1 파일들 (TarotGame, TarotCoordinateUtils): tarot_game.dart만 onLoad() 수정.

---

## Implementation Checklist

- [x] Step 1: `card_body_component.dart` 작성 + import 경로 확인
- [x] Step 1: `flutter analyze` — 에러 없음 확인
- [x] Step 2: `hand_animation_component.dart` 작성
- [x] Step 2: `flutter analyze` — 에러 없음 확인 (flame 32-bit vs forge2d 64-bit Vector2 충돌 해결)
- [x] Step 3: `sensor_gravity_controller.dart` 작성
- [x] Step 3: `flutter analyze` — 에러 없음 확인
- [x] Step 4: `tarot_game.dart` onLoad() 수정 + import 추가
- [x] Step 4: `flutter analyze` — 에러 없음 확인
- [x] Final: `flutter analyze` — 전체 0 errors

## Verification Assertions

| Level | Assertion | Verification Method | Expected Result |
|-------|-----------|-------------------|-----------------|
| L1-Build | flutter analyze 통과 | `flutter analyze` | 0 errors |
| L2-CLI | CardBodyComponent 파라미터 확인 | `grep "linearDamping: 2.0" card_body_component.dart` | 존재 |
| L2-CLI | SensorGravityController alpha 확인 | `grep "_alpha = 0.20" sensor_gravity_controller.dart` | 존재 |
| L2-CLI | HandAnimationComponent try-catch 존재 | `grep "try" hand_animation_component.dart` | 존재 |
| L2-CLI | TarotGame.onLoad world.addAll 존재 | `grep "world.addAll" tarot_game.dart` | 존재 |
| L4-Trace | Research 036 파라미터 반영 | grep density/friction/restitution | 1.0/0.4/0.05 |
| L4-Trace | Research 040 SensorInterval.gameInterval | grep SensorInterval.gameInterval | 존재 |

## References

| 리소스 | 경로 | 관련 내용 |
|--------|------|-----------|
| Scope | docs/11_tarot_shuffle/043_Scope_shuffle_engine_impl.md | Cycle 2 요구사항 |
| 물리 파라미터 | docs/11_tarot_shuffle/036_Agent_physics_params.md | 확정 파라미터 |
| Rive-forge2d latency | docs/11_tarot_shuffle/037_Agent_rive_forge2d_latency.md | KinematicBody + bone sync |
| 가속도계 | docs/11_tarot_shuffle/040_Agent_accelerometer_response.md | SensorInterval.gameInterval |
| 최종 아키텍처 | docs/11_tarot_shuffle/042_Research_tactile_engine_final.md | 전체 확정값 |
| Cycle 1 플랜 | docs/11_tarot_shuffle/044_Plan_shuffle_cycle1_foundation.md | TarotGame/TarotWorld 구조 |
