import 'package:flutter_riverpod/flutter_riverpod.dart';

class TunableDouble {
  const TunableDouble({
    required this.label,
    required this.provider,
    required this.min,
    required this.max,
    this.step = 1.0,
  });

  final String label;
  final StateProvider<double> provider;
  final double min;
  final double max;
  final double step;

  String format(double value) =>
      step < 1 ? value.toStringAsFixed(1) : value.toStringAsFixed(0);
}
