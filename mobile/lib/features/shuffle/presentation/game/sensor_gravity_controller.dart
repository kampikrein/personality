import 'dart:async';

// show로 필요한 것만 import → 32-bit flame Vector2 노출 방지
// flame_forge2d의 64-bit Vector2와 충돌하지 않도록 방어.
import 'package:flame/components.dart' show Component, HasGameReference;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'tarot_game.dart';

/// 가속도계 → forge2d world.gravity 실시간 업데이트 컨트롤러.
///
/// TarotGame에 game.add()로 추가 (world가 아닌 게임 루트 레벨).
/// HasGameReference로 game.world.gravity setter 접근.
///
/// 파라미터 (Research 040, 041 확정값):
///   alpha = 0.20 (로우패스 필터 계수)
///   gravityScale = 3.0 (linearDamping=2.0과 쌍으로 튜닝)
class SensorGravityController extends Component with HasGameReference<TarotGame> {
  /// 로우패스 필터 계수 (Research 041 확정: 신비로운 분위기 = 중간~부드러움)
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
        // SensorInterval.gameInterval: Android SENSOR_DELAY_GAME(20ms). Research 040 확정.
        samplingPeriod: SensorInterval.gameInterval,
      ).listen((event) {
        _rawX = event.x;
        _rawY = event.y;
      });
    } catch (e) {
      // 시뮬레이터 또는 센서 미지원 기기: 기본 중력(0, 9.8) 유지.
      assert(() {
        // ignore: avoid_print
        print('[SensorGravityController] accelerometer not available: $e');
        return true;
      }());
    }
  }

  @override
  void update(double dt) {
    // 로우패스 필터 (alpha=0.20: 진동 제거, 빠른 반응 균형)
    _smoothX += _alpha * (_rawX - _smoothX);
    _smoothY += _alpha * (_rawY - _smoothY);

    // world.gravity setter: 자동으로 모든 body를 setAwake(true) → sleep 카드도 즉각 반응
    game.world.gravity = Vector2(_smoothX * _gravityScale, _smoothY * _gravityScale);
  }

  @override
  void onRemove() {
    _subscription?.cancel();
    super.onRemove();
  }
}
