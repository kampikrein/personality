import 'dart:async';

import 'package:flutter/material.dart';

class StepperButton extends StatefulWidget {
  const StepperButton({
    super.key,
    required this.icon,
    required this.onStep,
  });

  final IconData icon;
  final VoidCallback onStep;

  @override
  State<StepperButton> createState() => _StepperButtonState();
}

class _StepperButtonState extends State<StepperButton> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onStep,
      onLongPressStart: (_) {
        widget.onStep();
        _timer = Timer.periodic(
          const Duration(milliseconds: 80),
          (_) => widget.onStep(),
        );
      },
      onLongPressEnd: (_) {
        _timer?.cancel();
        _timer = null;
      },
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: Icon(widget.icon, color: Colors.white70, size: 18),
      ),
    );
  }
}
