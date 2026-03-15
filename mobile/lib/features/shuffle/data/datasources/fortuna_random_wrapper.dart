import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/random/fortuna_random.dart';
import 'package:pointycastle/api.dart' as pc;

class FortunaRandomWrapper implements Random {
  FortunaRandomWrapper(Uint8List seed) {
    _fortuna = FortunaRandom()..seed(pc.KeyParameter(seed));
  }

  late final FortunaRandom _fortuna;

  @override
  int nextInt(int max) {
    if (max <= 0) throw ArgumentError('max must be positive');
    final limit = (0x100000000 ~/ max) * max;
    int value;
    do {
      value = _fortuna.nextUint32();
    } while (value >= limit);
    return value % max;
  }

  @override
  double nextDouble() {
    return _fortuna.nextUint32() / 0x100000000;
  }

  @override
  bool nextBool() {
    return _fortuna.nextUint32().isOdd;
  }
}
