import 'package:flutter_riverpod/flutter_riverpod.dart';

class TunableDouble {
  const TunableDouble({
    required this.label,
    required this.provider,
    required this.min,
    required this.max,
    this.step = 1.0,
    this.defaultValue,
  });

  final String label;
  final StateProvider<double> provider;
  final double min;
  final double max;
  final double step;
  final double? defaultValue;

  /// Reset에 사용할 값. 명시적 defaultValue가 없으면 min을 사용.
  double get resetValue => defaultValue ?? min;

  String format(double value) =>
      step < 1 ? value.toStringAsFixed(1) : value.toStringAsFixed(0);
}
