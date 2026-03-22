import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shuffle/domain/entities/shuffle_result.dart';

class CardRevealWidget extends StatefulWidget {
  const CardRevealWidget({
    super.key,
    required this.card,
    required this.deckId,
    required this.position,
    required this.label,
    required this.isRevealed,
    required this.onTap,
  });

  final ShuffledCard card;
  final String deckId;
  final int position;
  final String label;
  final bool isRevealed;
  final VoidCallback onTap;

  @override
  State<CardRevealWidget> createState() => _CardRevealWidgetState();
}

class _CardRevealWidgetState extends State<CardRevealWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFront = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _animation.addListener(() {
      if (_animation.value >= 0.5 && !_showFront) {
        setState(() => _showFront = true);
      }
    });
  }

  @override
  void didUpdateWidget(CardRevealWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRevealed && !oldWidget.isRevealed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: widget.isRevealed
          ? '${widget.label} 포지션: ${widget.card.card.name}'
          : '${widget.label} 포지션: 탭하여 카드를 뒤집으세요',
      button: !widget.isRevealed,
      child: GestureDetector(
        onTap: widget.isRevealed
            ? null
            : () {
                widget.onTap();
                HapticFeedback.lightImpact();
              },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.label, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final angle = _animation.value * math.pi;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateY(angle),
                  child: _showFront ? _buildFront(theme) : _buildBack(theme),
                );
              },
            ),
            if (widget.isRevealed && widget.card.isReversed)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '역방향 — 이 카드의 에너지가 내면으로 향합니다',
                  style: TextStyle(
                    color: theme.colorScheme.secondary,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBack(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pixelRatio = MediaQuery.of(context).devicePixelRatio;
        final cacheW = (constraints.maxWidth * pixelRatio).toInt().clamp(1, 1024);
        return AspectRatio(
          aspectRatio: 2.5 / 3.5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/${widget.deckId}/card_back.webp',
              cacheWidth: cacheW,
              fit: BoxFit.cover,
              semanticLabel: '카드 뒷면',
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF2D1B4E),
                child: Center(
                  child: Icon(Icons.auto_awesome,
                      color: theme.colorScheme.primary, size: 32),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFront(ThemeData theme) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(math.pi),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pixelRatio = MediaQuery.of(context).devicePixelRatio;
          final cacheW = (constraints.maxWidth * pixelRatio).toInt().clamp(1, 1024);
          return AspectRatio(
            aspectRatio: 2.5 / 3.5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 카드 앞면 이미지
                  Image.asset(
                    widget.card.card.imagePath,
                    cacheWidth: cacheW,
                    fit: BoxFit.cover,
                    semanticLabel: widget.card.card.name,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1A1028),
                      child: Center(
                        child: Text(
                          widget.card.card.name,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  // 카드 이름 오버레이 (하단)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        widget.card.card.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
