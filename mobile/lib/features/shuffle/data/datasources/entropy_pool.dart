import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'sensor_data_collector.dart';

class EntropyPool {
  static const int minSamples = 50;

  Uint8List _pool = Uint8List(32);
  int _accumulatedSamples = 0;
  bool _healthTestPassed = true;

  // RCT: 동일 값 연속 반복 제한
  static const int _rctCutoff = 5;
  double? _lastContribution;
  int _repetitionCount = 0;

  // APT: 가장 빈번한 값의 비율 제한
  static const int _aptWindowSize = 64;
  static const int _aptCutoff = 48;
  final List<int> _aptBuckets = List.filled(8, 0);
  int _aptSampleCount = 0;

  bool get isReady => _accumulatedSamples >= minSamples;
  bool get isHealthy => _healthTestPassed;
  double get progress => (_accumulatedSamples / minSamples).clamp(0.0, 1.0);

  void addSamples(List<SensorSample> samples) {
    for (final sample in samples) {
      _accumulate(sample);
    }
  }

  void _accumulate(SensorSample sample) {
    final contribution = sample.seedContribution;
    _runHealthTests(contribution);

    final timestamp = sample.timestampMicros;

    final contributionBytes = ByteData(8)..setFloat64(0, contribution);
    final timestampBytes = ByteData(8)..setInt64(0, timestamp);

    final combined = Uint8List(16);
    for (var i = 0; i < 8; i++) {
      combined[i] = contributionBytes.getUint8(i) ^ timestampBytes.getUint8(i);
      combined[i + 8] = contributionBytes.getUint8(i);
    }

    final digest = sha256.convert([..._pool, ...combined]);
    _pool = Uint8List.fromList(digest.bytes);
    _accumulatedSamples++;
  }

  void _runHealthTests(double contribution) {
    // RCT: Repetition Count Test
    if (_lastContribution != null && contribution == _lastContribution) {
      _repetitionCount++;
      if (_repetitionCount >= _rctCutoff) {
        _healthTestPassed = false;
      }
    } else {
      _repetitionCount = 0;
    }
    _lastContribution = contribution;

    // APT: Adaptive Proportion Test (quantized to 8 buckets)
    if (_aptSampleCount < _aptWindowSize) {
      final bucket = (contribution.abs() % 8).toInt();
      _aptBuckets[bucket]++;
      _aptSampleCount++;

      if (_aptSampleCount == _aptWindowSize) {
        final maxCount = _aptBuckets.reduce((a, b) => a > b ? a : b);
        if (maxCount >= _aptCutoff) {
          _healthTestPassed = false;
        }
      }
    }
  }

  Uint8List generateSeed() {
    final systemRandom = Random.secure();
    final systemBytes = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      systemBytes[i] = systemRandom.nextInt(256);
    }

    final finalDigest = sha256.convert([..._pool, ...systemBytes]);
    return Uint8List.fromList(finalDigest.bytes);
  }

  Uint8List generateFallbackSeed() {
    final systemRandom = Random.secure();
    final bytes = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      bytes[i] = systemRandom.nextInt(256);
    }
    return bytes;
  }

  void reset() {
    _pool = Uint8List(32);
    _accumulatedSamples = 0;
    _healthTestPassed = true;
    _lastContribution = null;
    _repetitionCount = 0;
    _aptBuckets.fillRange(0, _aptBuckets.length, 0);
    _aptSampleCount = 0;
  }
}
