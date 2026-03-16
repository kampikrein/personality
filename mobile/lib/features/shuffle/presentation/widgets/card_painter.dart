import 'package:flutter/material.dart';

import 'riffle_animation_controller.dart';

class CardPainter extends CustomPainter {
  CardPainter({required this.animationState})
      : super(repaint: animationState);

  final RiffleAnimationState animationState;

  static const _cardColor = Color(0xFF2D1B4E);
  static const _cardBorderColor = Color(0xFFD4A84B);
  static const _backPatternColor = Color(0xFF6B5B95);
  static const _cardAspectRatio = 2.5 / 3.5;

  @override
  void paint(Canvas canvas, Size size) {
    final cardWidth = size.width * 0.22;
    final cardHeight = cardWidth / _cardAspectRatio;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final positions = animationState.cardPositions;
    if (positions.isEmpty) {
      _drawDeckStack(canvas, centerX, centerY, cardWidth, cardHeight);
      return;
    }

    for (var i = 0; i < positions.length; i++) {
      final pos = positions[i];
      _drawCard(
        canvas,
        centerX + pos.dx * size.width,
        centerY + pos.dy * size.height,
        cardWidth,
        cardHeight,
        pos.rotation,
      );
    }
  }

  void _drawDeckStack(
    Canvas canvas,
    double cx,
    double cy,
    double w,
    double h,
  ) {
    final paint = Paint()..color = _cardColor;
    final borderPaint = Paint()
      ..color = _cardBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var i = 4; i >= 0; i--) {
      final offset = i * 1.5;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + offset, cy - offset),
          width: w,
          height: h,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, paint);
      canvas.drawRRect(rect, borderPaint);
    }

    _drawBackPattern(canvas, cx, cy, w * 0.6, h * 0.6);
  }

  void _drawCard(
    Canvas canvas,
    double cx,
    double cy,
    double w,
    double h,
    double rotation,
  ) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(rotation);

    final paint = Paint()..color = _cardColor;
    final borderPaint = Paint()
      ..color = _cardBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: w, height: h),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, paint);
    canvas.drawRRect(rect, borderPaint);

    canvas.restore();
  }

  void _drawBackPattern(
    Canvas canvas,
    double cx,
    double cy,
    double w,
    double h,
  ) {
    final patternPaint = Paint()
      ..color = _backPatternColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final path = Path()
      ..moveTo(cx, cy - h / 2)
      ..lineTo(cx + w / 2, cy)
      ..lineTo(cx, cy + h / 2)
      ..lineTo(cx - w / 2, cy)
      ..close();
    canvas.drawPath(path, patternPaint);
  }

  @override
  bool shouldRepaint(CardPainter oldDelegate) => true; // ChangeNotifier repaint handles this via super(repaint:)
}
