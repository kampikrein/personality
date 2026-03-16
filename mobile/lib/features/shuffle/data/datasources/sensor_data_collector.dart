import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

class SensorSample {
  const SensorSample({
    required this.accelMagnitude,
    required this.gyroZ,
    required this.timestampMicros,
  });

  final double accelMagnitude;
  final double gyroZ;
  final int timestampMicros;

  double get seedContribution => accelMagnitude * gyroZ;
}

class SensorDataCollector {
  final List<SensorSample> _samples = [];
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  AccelerometerEvent? _lastAccel;
  bool _isCollecting = false;
  bool _sensorsAvailable = true;
  Timer? _fallbackTimer;

  int get sampleCount => _samples.length;
  bool get isCollecting => _isCollecting;
  bool get sensorsAvailable => _sensorsAvailable;
  List<SensorSample> get samples => List.unmodifiable(_samples);

  void startCollecting() {
    if (_isCollecting) return;
    _isCollecting = true;
    _samples.clear();

    // 3초 내 센서 데이터가 없으면 센서 미가용으로 전환 (에뮬레이터 대응)
    _fallbackTimer = Timer(const Duration(seconds: 3), () {
      if (_samples.isEmpty) {
        _sensorsAvailable = false;
      }
    });

    try {
      _accelSub = accelerometerEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(
        (event) => _lastAccel = event,
        onError: (_) => _sensorsAvailable = false,
      );

      _gyroSub = gyroscopeEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(
        (event) {
          if (_lastAccel == null) return;
          _fallbackTimer?.cancel();
          final accel = _lastAccel!;
          _samples.add(SensorSample(
            accelMagnitude: sqrt(
              accel.x * accel.x + accel.y * accel.y + accel.z * accel.z,
            ),
            gyroZ: event.z,
            timestampMicros: DateTime.now().microsecondsSinceEpoch,
          ));
        },
        onError: (_) => _sensorsAvailable = false,
      );
    } catch (_) {
      _sensorsAvailable = false;
    }
  }

  void stopCollecting() {
    _isCollecting = false;
    _fallbackTimer?.cancel();
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _accelSub = null;
    _gyroSub = null;
  }

  void dispose() {
    stopCollecting();
    _samples.clear();
  }
}
