import 'dart:math' as math;

import 'package:flutter/material.dart';

// ── 앱 전체 공유 색상 팔레트 ─────────────────────────────────
const kGold = Color(0xFFD4A84B);
const kGoldLight = Color(0xFFE8C97A);
const kDeepPurple = Color(0xFF1A1028);
const kDarkSurface = Color(0xFF0D0A14);
const kSoftPurple = Color(0xFF6B5B95);
const kTextPrimary = Color(0xFFE8E0F0);
const kTextSecondary = Color(0xFF9B8FB8);

// ── 별 위치 — 전역 1회 생성 ──────────────────────────────────
final _starPositions = List.generate(90, (i) {
  final rng = math.Random(i * 31 + 7);
  return (
    x: rng.nextDouble(),
    y: rng.nextDouble(),
    r: rng.nextDouble() * 1.3 + 0.25,
    a: rng.nextDouble() * 0.55 + 0.15,
  );
});

// ═══════════════════════════════════════════════════════════════
//  MysticalScaffold — 미스틱 배경을 포함한 Scaffold 래퍼
// ═══════════════════════════════════════════════════════════════
class MysticalScaffold extends StatelessWidget {
  const MysticalScaffold({
    super.key,
    this.appBar,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset,
    this.backgroundColor,
  });

  final PreferredSizeWidget? appBar;
  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool? resizeToAvoidBottomInset;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final effectiveAppBar = appBar ??
        (title != null || titleWidget != null
            ? AppBar(
                title: titleWidget ??
                    Text(
                      title!,
                      style: const TextStyle(
                        color: kTextPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                leading: leading,
                actions: actions,
                backgroundColor: kDarkSurface.withValues(alpha: 0.85),
                elevation: 0,
                iconTheme: const IconThemeData(color: kTextPrimary),
              )
            : null);

    return Scaffold(
      backgroundColor: backgroundColor ?? kDarkSurface,
      appBar: effectiveAppBar,
      body: Stack(
        children: [
          const MysticalBackground(),
          body,
        ],
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MysticalBackground — 별 + 방사형 그라디언트
// ═══════════════════════════════════════════════════════════════
class MysticalBackground extends StatelessWidget {
  const MysticalBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.1, -0.5),
            radius: 1.5,
            colors: [Color(0xFF2D1F48), Color(0xFF180F2A), kDarkSurface],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: CustomPaint(
          painter: _StarPainter(),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    for (final s in _starPositions) {
      paint.color = Colors.white.withValues(alpha: s.a);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════
//  GoldHairline — 골드 그라디언트 얇은 구분선
// ═══════════════════════════════════════════════════════════════
class GoldHairline extends StatelessWidget {
  const GoldHairline({super.key, this.opacity = 0.3});
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.7,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            kGold.withValues(alpha: opacity),
            kGold.withValues(alpha: opacity * 1.4),
            kGold.withValues(alpha: opacity),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MysticalCard — deepPurple + 골드 테두리 컨테이너
// ═══════════════════════════════════════════════════════════════
class MysticalCard extends StatelessWidget {
  const MysticalCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderOpacity = 0.3,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double borderOpacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: kDeepPurple.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kGold.withValues(alpha: borderOpacity),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: kGold.withValues(alpha: 0.04),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  GoldSectionTitle — 골드 섹션 제목
// ═══════════════════════════════════════════════════════════════
class GoldSectionTitle extends StatelessWidget {
  const GoldSectionTitle(this.title, {super.key, this.icon});
  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: kGold.withValues(alpha: 0.8)),
            const SizedBox(width: 7),
          ],
          Text(
            title,
            style: const TextStyle(
              color: kGold,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MysticalTextField — 골드 테두리 텍스트 필드 데코레이션
// ═══════════════════════════════════════════════════════════════
InputDecoration mysticalInputDecoration({
  String? hintText,
  String? labelText,
  Widget? suffixIcon,
  bool isDense = false,
}) {
  return InputDecoration(
    hintText: hintText,
    labelText: labelText,
    hintStyle: const TextStyle(color: kTextSecondary),
    labelStyle: const TextStyle(color: kTextSecondary),
    suffixIcon: suffixIcon,
    isDense: isDense,
    filled: true,
    fillColor: kDarkSurface.withValues(alpha: 0.6),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: kGold.withValues(alpha: 0.25), width: 0.8),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: kGold.withValues(alpha: 0.25), width: 0.8),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: kGold.withValues(alpha: 0.7), width: 1.2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}
