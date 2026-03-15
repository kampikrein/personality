import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'sensor_data_collector.dart';

class EntropyPool {
  static const int minSamples = 10;

  Uint8List _pool = Uint8List(32);
  int _accumulatedSamples = 0;

  bool get isReady => _accumulatedSamples >= minSamples;
  double get progress => (_accumulatedSamples / minSamples).clamp(0.0, 1.0);

  void addSamples(List<SensorSample> samples) {
    for (final sample in samples) {
      _accumulate(sample);
    }
  }

  void _accumulate(SensorSample sample) {
    final contribution = sample.seedContribution;
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
  }
}
