---
id: "044"
type: plan
title: "셔플 엔진 Cycle 1 — Foundation (pubspec + TarotGame + CoordinateUtils)"
created: 2026-03-16
traces_scope: "043"
traces_research: "042"
summary: >
  Flame + forge2d + Rive 의존성 추가 및 게임 루프 기반(TarotGame, TarotCoordinateUtils) 구축.
  Cycle 2(Physics & Animation)가 의존하는 좌표 변환 유틸과 Forge2DGame 클래스 뼈대를 제공.
keywords: [flame, forge2d, rive, flame_forge2d, flame_rive, TarotGame, TarotCoordinateUtils, pubspec]
---

# 044 — 셔플 엔진 Cycle 1: Foundation

## Goal

Cycle 2(CardBodyComponent, HandAnimationComponent, SensorGravityController)가 의존하는
기반 레이어를 구축한다.

1. `pubspec.yaml`에 flame / flame_rive / flame_forge2d / rive 패키지 추가
2. `game/tarot_coordinate_utils.dart` — artboard → 화면 → forge2d 단위 변환 유틸
3. `game/tarot_game.dart` — Forge2DGame 서브클래스. 고정 타임스텝 루프, 기본 월드 설정

이 3개 파일이 완성되면 `flutter analyze`에서 에러 없이 빌드 가능한 상태가 된다.
`.riv` 에셋과 에셋 선언은 Cycle 2에서 HandAnimationComponent와 함께 추가한다.

## Scope

### Included
| # | 항목 | 설명 |
|---|------|------|
| 1 | pubspec.yaml 패키지 추가 | flame, flame_rive, flame_forge2d, rive |
| 2 | TarotCoordinateUtils | 좌표 변환 정적 유틸 (kPixelPerMeter 기준) |
| 3 | TarotGame | Forge2DGame 기반 게임 루프 클래스 |

### Excluded
| 항목 | 이유 |
|------|------|
| assets/animations/hand_shuffle.riv | Rive 디자인 파일 — Cycle 2에서 선언 |
| CardBodyComponent | forge2d 카드 body — Cycle 2 |
| HandAnimationComponent | Rive 손 컴포넌트 — Cycle 2 |
| SensorGravityController | 가속도계 중력 — Cycle 2 |
| ShufflePage 수정 | GameWidget 통합 — Cycle 3 |

## Structural Decisions

| # | 결정 | 선택 | 근거 |
|---|------|------|------|
| 1 | FlameGame vs Forge2DGame | **Forge2DGame** | flame_forge2d 공식 base class. World 내장, zoom = kPixelPerMeter로 픽셀↔미터 자동 변환 |
| 2 | 고정 타임스텝 구현 방식 | **누적 패턴** (accumulator) | 036 연구 확정값. dt 가변성 흡수, iOS/Android 동일 물리 시뮬레이션 보장 |
| 3 | kPixelPerMeter 상수 위치 | **TarotCoordinateUtils** | 유틸 클래스에 집중. TarotGame은 import로 참조 |
| 4 | .riv 에셋 선언 시점 | **Cycle 2** | Cycle 1에서 로드 코드 없음 → 미선언이 맞음. 선언만 하면 빌드 시 파일 존재 필요 |

> 구조적 결정 4건 — 연구 문서(042) 및 Scope(043) 확정값 반영. 사용자 추가 확인 불필요.

---

## File Change Summary

### Modified Files
| # | 파일 경로 | 변경 설명 |
|---|-----------|-----------|
| 1 | `mobile/pubspec.yaml` | flame, flame_rive, flame_forge2d, rive 패키지 추가 |

### New Files
| # | 파일 경로 | 설명 |
|---|-----------|------|
| 2 | `mobile/lib/features/shuffle/presentation/game/tarot_coordinate_utils.dart` | artboard → 화면 → forge2d 단위 변환 정적 유틸 |
| 3 | `mobile/lib/features/shuffle/presentation/game/tarot_game.dart` | Forge2DGame 기반 셔플 게임 루프 |

---

## Step 1 — pubspec.yaml 패키지 추가

### Approach

`dependencies` 블록에 게임 엔진 4개 패키지를 추가한다.
버전 선택 기준: flame_forge2d와 flame은 반드시 호환 버전을 쌍으로 고정.

- `flame ^1.19.0` — 게임 루프, 컴포넌트 시스템
- `flame_rive ^1.0.0` — RiveComponent (Rive 애니메이션 → Flame 컴포넌트)
- `flame_forge2d ^0.18.0` — Forge2DGame, BodyComponent (flame ↔ forge2d 브리지)
- `rive ^0.13.16` — Rive 런타임 (FlutterRiveController, Artboard, StateMachine)

### Current Code

```yaml
# mobile/pubspec.yaml:9-17 (현재)
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
```

### After Code

```yaml
# mobile/pubspec.yaml (변경 후)
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

  # Game Engine — Tarot Shuffle
  flame: ^1.19.0
  flame_rive: ^1.0.0
  flame_forge2d: ^0.18.0
  rive: ^0.13.16
```

### Considerations

- `flame_forge2d` 내부적으로 `forge2d` 의존성을 포함 — 별도 `forge2d` 선언 불필요.
- 버전 충돌 시: `flutter pub get`의 오류 메시지를 기준으로 `flame_forge2d`가 요구하는 `flame` 버전으로 맞춤.
- `flame_rive`는 `rive` 패키지를 peer dependency로 사용 — 반드시 함께 선언.

---

## Step 2 — TarotCoordinateUtils 생성

### Approach

artboard 로컬 좌표 → 화면 픽셀 → forge2d 미터의 3-단계 변환을 정적 메서드로 제공.
Cycle 2에서 HandAnimationComponent가 Rive bone 좌표를 forge2d body에 반영할 때 사용.

핵심 상수: `kPixelPerMeter = 100.0`
→ 1 forge2d meter = 100 화면 픽셀. TarotGame의 zoom 파라미터와 반드시 일치.

### After Code

```dart
// mobile/lib/features/shuffle/presentation/game/tarot_coordinate_utils.dart (신규)
import 'package:flame/extensions.dart';

/// artboard(px) ↔ 화면(px) ↔ forge2d(m) 단위 변환 유틸.
///
/// kPixelPerMeter = 100.0 → 1 forge2d meter = 100 화면 픽셀.
/// TarotGame의 zoom 파라미터와 반드시 동일해야 Flame 렌더링과 물리가 일치.
abstract final class TarotCoordinateUtils {
  /// forge2d world 단위와 화면 픽셀의 변환 비율.
  /// TarotGame(zoom: kPixelPerMeter)과 반드시 동기화.
  static const double kPixelPerMeter = 100.0;

  // ─── 화면(px) ↔ forge2d(m) ──────────────────────────────────────────────

  /// 화면 픽셀 좌표 → forge2d world 좌표(미터)
  static Vector2 screenToWorld(double x, double y) =>
      Vector2(x / kPixelPerMeter, y / kPixelPerMeter);

  /// forge2d world 좌표(미터) → 화면 픽셀 좌표
  static Vector2 worldToScreen(double x, double y) =>
      Vector2(x * kPixelPerMeter, y * kPixelPerMeter);

  // ─── Rive artboard(px) → forge2d(m) ─────────────────────────────────────

  /// Rive artboard 로컬 좌표 → forge2d world 좌표(미터).
  ///
  /// Rive bone.worldTransform의 Mat2D[4], Mat2D[5]를 인자로 전달.
  /// artboard 해상도가 화면 해상도와 다를 경우 screenWidth/Height로 정규화.
  static Vector2 artboardToWorld(
    double artX,
    double artY, {
    required double artboardWidth,
    required double artboardHeight,
    required double screenWidth,
    required double screenHeight,
  }) {
    final screenX = artX / artboardWidth * screenWidth;
    final screenY = artY / artboardHeight * screenHeight;
    return screenToWorld(screenX, screenY);
  }

  /// 화면 크기가 artboard와 동일하다고 가정하는 단순 변환 (아트보드 = 화면 해상도일 때).
  /// artboard 크기 확인 전 임시 사용. Cycle 2에서 artboardToWorld로 교체.
  static Vector2 artboardToWorldSimple(double artX, double artY) =>
      Vector2(artX / kPixelPerMeter, artY / kPixelPerMeter);
}
```

### Considerations

- `abstract final class`를 사용해 인스턴스화를 언어 수준에서 차단.
- `artboardToWorldSimple`: Cycle 2 개발 시 Rive artboard 실제 크기 확인 전 임시 메서드. HandAnimationComponent 구현 후 `artboardToWorld`로 교체.
- Scope 043 확정값 `Vector2(x / kPixelPerMeter, y / kPixelPerMeter)`를 그대로 반영.

---

## Step 3 — TarotGame 생성

### Approach

`Forge2DGame`을 상속해 물리 게임 루프를 구성한다.

핵심 설계:
1. `zoom: kPixelPerMeter` — Forge2DGame의 카메라 줌 = 1미터/100픽셀. 렌더링과 물리 좌표 자동 일치.
2. **고정 타임스텝 누적 패턴** (036 연구 확정값): `1/45s` 스텝으로 iOS/Android 물리 일관성 보장.
3. Cycle 2에서 SensorGravityController가 `world.gravity`를 직접 수정 — TarotGame은 초기 중력만 설정.
4. `world` 접근자를 제공해 Cycle 2 컴포넌트가 physics world에 접근 가능.

> **Forge2DGame의 update() 주의사항**: 기본 `super.update(dt)`는 `world.stepDt(dt)`를 내부 호출.
> 고정 타임스텝을 위해 직접 `world.stepDt(_kFixedDt)`를 누적 실행 후 컴포넌트 update는
> `updateTree(dt)` (Flame 내부 API)로 분리 호출. 이 패턴이 flame_forge2d 커뮤니티 표준.

### After Code

```dart
// mobile/lib/features/shuffle/presentation/game/tarot_game.dart (신규)
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame/components.dart';

import 'tarot_coordinate_utils.dart';

/// 타로 셔플 물리 게임 루프.
///
/// Forge2DGame 기반. TarotCoordinateUtils.kPixelPerMeter로
/// forge2d world(미터)와 화면 픽셀을 1:100 비율로 유지.
///
/// Cycle 2에서 추가될 컴포넌트:
///   - CardBodyComponent: 카드 DynamicBody
///   - HandAnimationComponent: Rive 손 KinematicBody
///   - SensorGravityController: 가속도계 → world.gravity
class TarotGame extends Forge2DGame {
  /// 고정 물리 타임스텝: 1/45초 (036 연구 확정값).
  /// 이 값으로 iOS/Android 동일한 물리 시뮬레이션 보장.
  static const double _kFixedDt = 1.0 / 45.0;
  double _accumulator = 0.0;

  TarotGame()
      : super(
          gravity: Vector2(0, 9.8), // SensorGravityController가 Cycle 2에서 교체
          zoom: TarotCoordinateUtils.kPixelPerMeter,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // TODO(Cycle2): add(SensorGravityController());
    // TODO(Cycle2): addAll(List.generate(78, (_) => CardBodyComponent()));
    // TODO(Cycle2): add(HandAnimationComponent());
  }

  @override
  void update(double dt) {
    // 고정 타임스텝 누적 패턴 (036 연구 확정값)
    // super.update(dt) 대신 직접 stepDt 제어로 물리 일관성 확보
    _accumulator += dt;
    final steps = (_accumulator / _kFixedDt).floor();
    for (var i = 0; i < steps; i++) {
      world.stepDt(_kFixedDt);
    }
    _accumulator -= steps * _kFixedDt;

    // 컴포넌트 트리 업데이트 (물리 스텝과 분리)
    super.update(dt);
  }
}
```

### Considerations

- **`super.update(dt)` 이중 호출 문제**: Forge2DGame의 `super.update(dt)` 내부에서 `world.stepDt(dt)`를 1회 더 호출한다. 이를 방지하려면 `FlameGame.update(dt)`를 직접 호출하거나 `Forge2DGame`의 소스를 확인해야 한다.

  **검증 방법**: `flutter pub get` 후 `flame_forge2d` 소스에서 `update()` 구현 확인.
  만약 `super.update(dt)`가 이중 물리 스텝을 유발한다면:
  ```dart
  // 대안: FlameGame.update() 직접 호출
  @override
  void update(double dt) {
    _accumulator += dt;
    final steps = (_accumulator / _kFixedDt).floor();
    for (var i = 0; i < steps; i++) {
      world.stepDt(_kFixedDt);
    }
    _accumulator -= steps * _kFixedDt;
    // FlameGame의 update()를 호출해 컴포넌트만 업데이트
    // (world.stepDt 제외)
    updateTree(dt); // Flame internal — 버전에 따라 다를 수 있음
  }
  ```
  Implementation 단계에서 `flutter analyze` + 실기기 테스트로 검증.

- **Cycle 2 연결 지점**: TODO 주석으로 Cycle 2에서 추가할 컴포넌트 위치를 명시해 연속성 확보.

- **world 접근**: `Forge2DGame.world`는 이미 public 접근자. SensorGravityController에서 `(game as TarotGame).world.gravity = ...`로 직접 수정 가능.

---

## Considerations & Trade-offs

### Alternative Approaches

| 대안 | 미채택 이유 |
|------|-----------|
| `FlameGame` + 수동 forge2d World | Forge2DGame이 World 생성, BodyComponent 통합, zoom 처리를 모두 제공 — 수동 구성 대비 코드 절약 |
| `kPixelPerMeter = 50.0` (더 작은 스케일) | 100.0이 카드(약 88×56mm → 8.8cm → 0.088m) 기준 적절한 단위. 연구(043 확정) |
| Rive placeholder .riv 생성 | Cycle 1에서 Rive 로드 코드 없음 → 플레이스홀더 필요 없음. Cycle 2에서 파일과 코드 동시 추가 |

### Potential Risks

1. **flame_forge2d 버전 충돌**: `flame ^1.19.0`과 `flame_forge2d ^0.18.0` 호환성 미검증 상태.
   → `flutter pub get` 후 pubspec.lock 확인. 충돌 시 scope 043의 대응 규칙 적용.

2. **super.update 이중 stepDt**: flame_forge2d 버전에 따라 `Forge2DGame.update()`가 내부적으로 `world.stepDt(dt)`를 호출할 수 있음.
   → Implementation 단계에서 소스 확인 후 필요 시 `updateTree(dt)` 패턴으로 교체.

3. **zoom 파라미터 동작**: `Forge2DGame`의 zoom이 카메라 스케일인지, 물리-렌더 비율인지 버전별 차이.
   → Implementation 후 카드를 화면에 추가하고 위치 확인으로 검증.

### Backward Compatibility

- `shuffle_page.dart`: Cycle 1에서 변경 없음. 기존 CustomPainter 그대로 유지.
- 기존 sensor_data_collector, haptic_service: 변경 없음.
- pubspec 추가 패키지가 기존 패키지와 충돌 없어야 함 (버전 범위 여유로 낮음).

---

## Implementation Checklist

- [x] Step 1: pubspec.yaml에 flame/flame_rive/flame_forge2d/rive 추가
- [x] Step 1: `flutter pub get` 실행 — 에러 없이 완료 확인 (flame 1.36.0, flame_forge2d 0.18.3+1, flame_rive 1.10.23, rive 0.13.20)
- [x] Step 2: `game/` 디렉토리 생성
- [x] Step 2: `tarot_coordinate_utils.dart` 작성
- [x] Step 3: `tarot_game.dart` 작성 (TarotWorld 서브클래스로 고정 타임스텝 구현)
- [x] Step 3: Forge2DGame.update() 소스 확인 → 이중 stepDt 없음 확인 (Forge2DWorld.update에서 처리)
- [x] Final: `flutter analyze` — 에러 0개

## Verification Assertions

| Level | 어설션 | 검증 방법 | 예상 결과 |
|-------|--------|-----------|-----------|
| L1-Build | flutter pub get 성공 | `flutter pub get` | 에러 없이 완료, pubspec.lock 생성 |
| L1-Build | flutter analyze 통과 | `flutter analyze mobile/lib/features/shuffle/presentation/game/` | 0 errors |
| L2-CLI | TarotCoordinateUtils 상수 검증 | grep "kPixelPerMeter = 100.0" | 파일에 존재 |
| L2-CLI | TarotGame 컴파일 가능 | `flutter build apk --debug` (또는 analyze) | 타입 에러 없음 |
| L4-Trace | Scope 043 Cycle 1 요구사항 | pubspec + 2개 파일 존재 | Foundation 영역 완료 |

## References

| 리소스 | 경로 | 관련 내용 |
|--------|------|-----------|
| Scope | docs/11_tarot_shuffle/043_Scope_shuffle_engine_impl.md | Cycle 1 요구사항 정의 |
| 물리 파라미터 | docs/11_tarot_shuffle/036_Agent_physics_params.md | 고정 타임스텝 1/45s 확정 |
| 최종 아키텍처 | docs/11_tarot_shuffle/042_Research_tactile_engine_final.md | zoom = kPixelPerMeter 확정 |
| flame_forge2d | https://pub.dev/packages/flame_forge2d | 패키지 API 참조 |
