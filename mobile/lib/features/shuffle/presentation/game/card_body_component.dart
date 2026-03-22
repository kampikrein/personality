import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/services.dart';

import 'tarot_game.dart';

/// forge2d DynamicBody 타로 카드 1장.
///
/// card_back.webp SpriteComponent를 child로 렌더링.
/// 물리 좌표계: world meters (1m = 100px @ zoom=100).
class CardBodyComponent extends BodyComponent<TarotGame> with ContactCallbacks {
  final String deckId;
  final Vector2 initialPosition;
  final Vector2 initialVelocity;
  final double initialAngularVelocity;
  final int renderPriority;

  static const double halfWidth  = 0.3;
  static const double halfHeight = 0.45;

  CardBodyComponent({
    required this.deckId,
    required this.initialPosition,
    required this.initialVelocity,
    required this.initialAngularVelocity,
    required this.renderPriority,
  }) : super(renderBody: false);

  @override
  int get priority => renderPriority;

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: initialPosition,
      linearVelocity: initialVelocity,
      angularVelocity: initialAngularVelocity,
      linearDamping: 3.5,
      angularDamping: 2.0,
      allowSleep: true,
    );
    final shape = PolygonShape()..setAsBoxXY(halfWidth, halfHeight);
    final body = world.createBody(bodyDef)
      ..createFixture(FixtureDef(shape, density: 1.0, friction: 0.5, restitution: 0.02));
    body.userData = this;
    return body;
  }

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

  @override
  void beginContact(Object other, Contact contact) {
    if (other is CardBodyComponent) HapticFeedback.selectionClick();
  }
}
