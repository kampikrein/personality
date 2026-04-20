import 'package:flutter/material.dart';

import '../../../shuffle/domain/entities/shuffle_result.dart';
import '../../domain/entities/layout_type.dart';
import 'card_reveal_widget.dart';

class SpreadLayout extends StatelessWidget {
  const SpreadLayout({
    super.key,
    required this.layoutType,
    required this.cards,
    required this.deckId,
    required this.revealedPositions,
    required this.onCardTap,
    this.cardsPerRow = 3,
    this.showCardName = true,
    this.cardAspectRatio = 70.0 / 120.0,
  });

  final LayoutType layoutType;
  final List<ShuffledCard> cards;
  final String deckId;
  final Set<int> revealedPositions;
  final ValueChanged<int> onCardTap;
  final int cardsPerRow;
  final bool showCardName;
  final double cardAspectRatio;

  @override
  Widget build(BuildContext context) {
    final cardCount = cards.length;
    if (cardCount == 0) return const SizedBox.shrink();

    final totalSlots = layoutType.slotCount(cardCount);
    final emptySlotsSet = layoutType.emptySlots(cardCount);
    final crossAxisCount = layoutType.cardsPerRowOverride ?? cardsPerRow;

    final slotToDraw = <int, int>{};
    for (int draw = 0; draw < cardCount; draw++) {
      slotToDraw[layoutType.drawToSlot(draw, cardCount)] = draw;
    }

    final positions = layoutType.resolvePositions(cardCount);

    return GridView.builder(
      key: ValueKey(layoutType),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalSlots,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: cardAspectRatio * 0.9,
      ),
      itemBuilder: (context, slot) {
        if (emptySlotsSet.contains(slot)) {
          return _EmptySlotPlaceholder(
            key: ValueKey('empty-$slot'),
            aspectRatio: cardAspectRatio,
          );
        }
        final drawIdx = slotToDraw[slot];
        if (drawIdx == null) return const SizedBox.shrink();
        return CardRevealWidget(
          key: ValueKey('card-$drawIdx'),
          card: cards[drawIdx],
          deckId: deckId,
          position: drawIdx,
          label: positions.length > drawIdx
              ? positions[drawIdx]
              : '카드 ${drawIdx + 1}',
          isRevealed: revealedPositions.contains(drawIdx),
          showCardName: showCardName,
          cardAspectRatio: cardAspectRatio,
          onTap: () => onCardTap(drawIdx),
        );
      },
    );
  }
}

class _EmptySlotPlaceholder extends StatelessWidget {
  const _EmptySlotPlaceholder({
    super.key,
    this.aspectRatio = 70.0 / 120.0,
  });

  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: const CustomPaint(
        painter: _DashedRectPainter(
          color: Color(0x556B5B95),
          dashWidth: 6,
          dashGap: 4,
          strokeWidth: 1,
          cornerRadius: 4,
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  const _DashedRectPainter({
    required this.color,
    required this.dashWidth,
    required this.dashGap,
    required this.strokeWidth,
    required this.cornerRadius,
  });

  final Color color;
  final double dashWidth;
  final double dashGap;
  final double strokeWidth;
  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(cornerRadius),
      ));
    canvas.drawPath(_createDashedPath(path), paint);
  }

  Path _createDashedPath(Path source) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final length = draw ? dashWidth : dashGap;
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, distance + length),
            Offset.zero,
          );
        }
        distance += length;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter old) =>
      color != old.color ||
      dashWidth != old.dashWidth ||
      dashGap != old.dashGap ||
      strokeWidth != old.strokeWidth ||
      cornerRadius != old.cornerRadius;
}
