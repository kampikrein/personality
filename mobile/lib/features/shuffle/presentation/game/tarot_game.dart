import 'dart:math';

import 'package:flame_forge2d/flame_forge2d.dart';

import 'card_body_component.dart';
import 'hand_animation_component.dart';
import 'sensor_gravity_controller.dart';
import 'tarot_coordinate_utils.dart';

/// 타로 셔플 물리 게임 루프.
///
/// `Forge2DGame<TarotWorld>` 기반. [TarotCoordinateUtils.kPixelPerMeter]로
/// forge2d world(미터)와 화면 픽셀을 1:100 비율로 유지.
///
/// Cycle 2에서 추가될 컴포넌트:
///   - CardBodyComponent: 카드 DynamicBody
///   - HandAnimationComponent: Rive 손 KinematicBody
///   - SensorGravityController: 가속도계 → world.gravity
class TarotGame extends Forge2DGame<TarotWorld> {
  TarotGame()
      : super(
          world: TarotWorld(gravity: Vector2(0, 9.8)),
          zoom: TarotCoordinateUtils.kPixelPerMeter,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // SensorGravityController: 게임 루트 레벨 (physics 없음, 순수 컨트롤러)
    await add(SensorGravityController());

    // CardBodyComponent: Forge2DWorld에 추가 (BodyComponent 필수)
    // 화면 중앙(world origin ≈ 0,0) 근처 ±0.25m 랜덤 분산으로 78장 배치
    final rng = Random();
    await world.addAll(
      List.generate(
        78,
        (_) => CardBodyComponent(
          initialPosition: Vector2(
            (rng.nextDouble() - 0.5) * 0.5, // ±0.25m = ±25px random
            (rng.nextDouble() - 0.5) * 0.5,
          ),
        ),
      ),
    );

    // HandAnimationComponent: Forge2DWorld에 추가 (KinematicBody 필요)
    world.add(HandAnimationComponent());
  }
}

/// forge2d 물리 world — 고정 타임스텝 누적 패턴 적용.
///
/// [Forge2DWorld.update] 오버라이드로 고정 1/45초 스텝 실행.
/// iOS/Android 물리 시뮬레이션 일관성 보장 (Research 036 확정값).
///
/// Cycle 2에서 [SensorGravityController]가 [gravity] setter를 통해
/// 가속도계 값을 중력으로 반영한다.
class TarotWorld extends Forge2DWorld {
  /// 고정 물리 타임스텝: 1/45초 (Research 036 확정값).
  static const double kFixedDt = 1.0 / 45.0;
  double _accumulator = 0.0;

  TarotWorld({
    super.gravity,
    super.contactListener,
  });

  @override
  void update(double dt) {
    // 고정 타임스텝 누적 패턴 (Research 036 확정값):
    // 가변 dt를 kFixedDt 단위로 분해해 물리 안정성 확보.
    // super.update(dt) 미호출 → physicsWorld.stepDt(dt) 이중 실행 방지.
    // Flame이 별도로 children의 updateTree(dt)를 호출해 컴포넌트 업데이트는 정상 실행됨.
    _accumulator += dt;
    final steps = (_accumulator / kFixedDt).floor();
    for (var i = 0; i < steps; i++) {
      physicsWorld.stepDt(kFixedDt);
    }
    _accumulator -= steps * kFixedDt;
  }
}
