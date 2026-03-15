import 'package:flutter/services.dart';

class HapticService {
  DateTime _lastHaptic = DateTime.fromMillisecondsSinceEpoch(0);
  static const _throttleDuration = Duration(milliseconds: 50);

  void selectionClick() => _throttled(HapticFeedback.selectionClick);
  void lightImpact() => _throttled(HapticFeedback.lightImpact);
  void mediumImpact() => _throttled(HapticFeedback.mediumImpact);

  void _throttled(Future<void> Function() action) {
    final now = DateTime.now();
    if (now.difference(_lastHaptic) >= _throttleDuration) {
      _lastHaptic = now;
      action();
    }
  }
}
