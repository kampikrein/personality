import 'dart:math' as math;

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart' show Color;

import 'card_body_component.dart';
import 'tarot_coordinate_utils.dart';

/// 타로 셔플 물리 게임 루프.
///
/// [cardCount]장 카드를 중앙에서 방사형으로 흩뿌림. 중력 없음 + 높은 감쇠 → 산란 후 안착.
/// SensorGravityController 비활성 (산란 연출에서는 센서 중력 불필요).
class TarotGame extends Forge2DGame<TarotWorld> {
  final String deckId;
  final int cardCount;

  TarotGame({required this.deckId, required this.cardCount})
      : super(
          world: TarotWorld(gravity: Vector2(0, 0)),
          zoom: TarotCoordinateUtils.kPixelPerMeter,
        );

  @override
  Color backgroundColor() => const Color(0xFF0D0818);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await images.load('$deckId/card_back.webp');
    _spawnCards();
  }

  void _spawnCards() {
    final rng = math.Random.secure();

    for (var i = 0; i < cardCount; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final speed = 2.0 + rng.nextDouble() * 4.0;

      world.add(CardBodyComponent(
        deckId: deckId,
        initialPosition: Vector2(
          (rng.nextDouble() - 0.5) * 0.3,
          (rng.nextDouble() - 0.5) * 0.3,
        ),
        initialVelocity: Vector2(
          math.cos(angle) * speed,
          math.sin(angle) * speed,
        ),
        initialAngularVelocity: (rng.nextDouble() - 0.5) * 8.0,
        renderPriority: i,
      ));
    }
  }
}

/// forge2d 물리 world — 고정 타임스텝 누적 패턴.
class TarotWorld extends Forge2DWorld {
  static const double kFixedDt = 1.0 / 45.0;
  double _accumulator = 0.0;

  TarotWorld({super.gravity, super.contactListener});

  @override
  void update(double dt) {
    _accumulator += dt;
    final steps = (_accumulator / kFixedDt).floor();
    for (var i = 0; i < steps; i++) {
      physicsWorld.stepDt(kFixedDt);
    }
    _accumulator -= steps * kFixedDt;
  }
}
