import 'package:flame/flame.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_rive/flame_rive.dart';

import 'tarot_coordinate_utils.dart';
import 'tarot_game.dart';

/// Rive 손 애니메이션 + forge2d KinematicBody.
///
/// .riv 파일 없을 때: KinematicBody만 동작 (renderBody=true로 원 outline 표시).
/// .riv 파일 있을 때: RiveComponent child 렌더 + bone 좌표 동기화.
///
/// Cycle 2에서 body 위치는 고정(초기값). 실제 손 이동 로직은 .riv 파일 완성 후 추가.
///
/// 배치: TarotGame.onLoad()에서 world.add()로 Forge2DWorld에 추가.
class HandAnimationComponent extends BodyComponent<TarotGame> {
  Artboard? _artboard;
  StateMachineController? _smController;
  bool _riveLoaded = false;

  /// 손 초기 위치: 화면 상단 중앙 (y < 0 = 기본 카메라 기준 화면 위쪽 방향)
  static final Vector2 _initialPosition = Vector2(0.0, -1.5);

  HandAnimationComponent() : super(renderBody: true);

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.kinematic,
      position: _initialPosition,
    );
    // 손 끝 충돌 영역: 반지름 0.3m = 30px
    // KinematicBody: density=0, isSensor=false → DynamicBody(카드) 물리적으로 밀어냄
    final shape = CircleShape()..radius = 0.3;
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
      // .riv 파일 로드 시도 (Scope 043: 없으면 KinematicBody로 먼저 검증)
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
      // size 4.0m × 4.0m = 400px × 400px @ zoom=100. body 중앙 정렬.
      // position/size를 생성자가 아닌 setter로 설정:
      // flame(32-bit) vs forge2d(64-bit) Vector2 타입 충돌 우회.
      // RiveComponent.position은 NotifyingVector2(flame 32-bit)이며
      // setValues(double, double)로 타입 없이 값만 주입한다.
      final riveChild = RiveComponent(artboard: _artboard!, priority: 0)
        ..position.setValues(-2.0, -2.0) // center offset (좌상단 → 중앙)
        ..size.setValues(4.0, 4.0); // 4.0m × 4.0m = 400px × 400px @ zoom=100
      await add(riveChild);
    } catch (_) {
      // .riv 파일 없음 또는 로드 실패 — KinematicBody만 동작.
      // renderBody=true이므로 원 outline(debug)이 화면에 표시됨.
      // Rive 디자인 완성 후 hand_shuffle.riv + pubspec 선언으로 활성화.
      _riveLoaded = false;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_riveLoaded || _artboard == null || dt <= 0) return;

    // Rive bone → KinematicBody 동기화 (Research 037 확정 패턴).
    // .riv 파일에 'hand_tip' bone이 있을 때 아래 주석 해제.
    //
    // final bone = _artboard!.component<Bone>('hand_tip');
    // if (bone == null) return;
    // final mat = bone.worldTransform;
    // final worldPos = TarotCoordinateUtils.artboardToWorldSimple(mat[4], mat[5]);
    // body.linearVelocity = (worldPos - body.position) / dt;
    //
    // (참조만 유지 — 사용되지 않는 import 경고 방지)
    TarotCoordinateUtils.kPixelPerMeter; // ignore: unnecessary_statements
  }
}
