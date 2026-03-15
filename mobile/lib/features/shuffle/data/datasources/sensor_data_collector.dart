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

  int get sampleCount => _samples.length;
  bool get isCollecting => _isCollecting;
  bool get sensorsAvailable => _sensorsAvailable;
  List<SensorSample> get samples => List.unmodifiable(_samples);

  void startCollecting() {
    if (_isCollecting) return;
    _isCollecting = true;
    _samples.clear();

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
