import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shuffle/domain/entities/shuffle_result.dart';

class CardRevealWidget extends StatefulWidget {
  const CardRevealWidget({
    super.key,
    required this.card,
    required this.position,
    required this.label,
    required this.isRevealed,
    required this.onTap,
  });

  final ShuffledCard card;
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

    return GestureDetector(
      onTap: widget.isRevealed ? null : widget.onTap,
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
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                child: _showFront ? _buildFront(theme) : _buildBack(theme),
              );
            },
          ),
          if (widget.isRevealed && widget.card.isReversed)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '역방향',
                style: TextStyle(color: theme.colorScheme.secondary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBack(ThemeData theme) {
    return AspectRatio(
      aspectRatio: 2.5 / 3.5,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2D1B4E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.primary, width: 1.5),
        ),
        child: Center(
          child: Icon(Icons.auto_awesome,
              color: theme.colorScheme.primary, size: 32),
        ),
      ),
    );
  }

  Widget _buildFront(ThemeData theme) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(math.pi),
      child: AspectRatio(
        aspectRatio: 2.5 / 3.5,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1028),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.primary, width: 1.5),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.card.card.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.card.card.meanings.upright.take(2).join(', '),
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
