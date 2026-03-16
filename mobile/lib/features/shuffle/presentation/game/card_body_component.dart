import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/services.dart';

import 'tarot_game.dart';

/// forge2d DynamicBody 타로 카드 1장.
///
/// TarotGame.onLoad()에서 78개 인스턴스 생성.
/// 물리 파라미터는 Research 036 확정값 사용.
///
/// render: renderBody=true (기본값) → polygon fixture를 흰색으로 표시.
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
