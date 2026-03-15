import 'package:flutter/material.dart';

import '../../../shuffle/domain/entities/shuffle_result.dart';
import '../../domain/entities/spread_type.dart';
import 'card_reveal_widget.dart';

class SpreadLayout extends StatelessWidget {
  const SpreadLayout({
    super.key,
    required this.spreadType,
    required this.cards,
    required this.revealedPositions,
    required this.onCardTap,
  });

  final SpreadType spreadType;
  final List<ShuffledCard> cards;
  final Set<int> revealedPositions;
  final ValueChanged<int> onCardTap;

  @override
  Widget build(BuildContext context) {
    return switch (spreadType) {
      SpreadType.single => _buildSingleLayout(),
      SpreadType.threeCard => _buildThreeCardLayout(),
    };
  }

  Widget _buildSingleLayout() {
    return Center(
      child: CardRevealWidget(
        card: cards[0],
        position: 0,
        label: spreadType.positions[0],
        isRevealed: revealedPositions.contains(0),
        onTap: () => onCardTap(0),
      ),
    );
  }

  Widget _buildThreeCardLayout() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (i) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CardRevealWidget(
              card: cards[i],
              position: i,
              label: spreadType.positions[i],
              isRevealed: revealedPositions.contains(i),
              onTap: () => onCardTap(i),
            ),
          ),
        );
      }),
    );
  }
}
