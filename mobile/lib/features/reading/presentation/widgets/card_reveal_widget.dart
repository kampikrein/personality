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
    this.showCardName = true,
    this.cardAspectRatio = 70.0 / 120.0,
  });

  final ShuffledCard card;
  final String deckId;
  final int position;
  final String label;
  final bool isRevealed;
  final VoidCallback onTap;
  final bool showCardName;
  final double cardAspectRatio;

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
    if (widget.isRevealed) {
      _showFront = true;
      _controller.value = 1.0;
    }
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
            // 역방향: 이름이 카드 위에 뒤집혀 보임
            if (widget.showCardName && widget.isRevealed && _showFront && widget.card.isReversed)
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationZ(math.pi),
                child: _buildCardName(theme),
              ),
            Flexible(
              child: AnimatedBuilder(
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
            ),
            // 정방향: 카드 아래에 이름
            if (widget.showCardName && widget.isRevealed && _showFront && !widget.card.isReversed)
              _buildCardName(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildBack(ThemeData theme) {
    return AspectRatio(
      aspectRatio: widget.cardAspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Image.asset(
          'assets/images/${widget.deckId}/card_back.webp',
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
  }

  Widget _buildCardName(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        widget.card.card.name,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildFront(ThemeData theme) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..rotateY(math.pi)
        // 역방향 카드: 180도 회전 (뒤집어서 표시)
        ..rotateZ(widget.card.isReversed ? math.pi : 0),
      child: AspectRatio(
        aspectRatio: widget.cardAspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 카드 앞면 이미지
              Image.asset(
                widget.card.card.imagePath,
                fit: BoxFit.cover,
                semanticLabel: widget.card.card.name,
                errorBuilder: (_, error, ___) {
                  debugPrint(
                    'CardRevealWidget: image load error for '
                    '${widget.card.card.imagePath}: $error',
                  );
                  return Container(
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
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
