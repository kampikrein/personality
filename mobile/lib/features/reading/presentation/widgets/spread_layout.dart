import 'package:flutter/material.dart';

import '../../../shuffle/domain/entities/shuffle_result.dart';
import '../../domain/entities/spread_type.dart';
import 'card_reveal_widget.dart';

class SpreadLayout extends StatelessWidget {
  const SpreadLayout({
    super.key,
    required this.spreadType,
    required this.cards,
    required this.deckId,
    required this.revealedPositions,
    required this.onCardTap,
    this.showCardName = true,
    this.cardAspectRatio = 70.0 / 120.0,
  });

  final SpreadType spreadType;
  final List<ShuffledCard> cards;
  final String deckId;
  final Set<int> revealedPositions;
  final ValueChanged<int> onCardTap;
  final bool showCardName;
  final double cardAspectRatio;

  @override
  Widget build(BuildContext context) {
    return switch (spreadType) {
      SpreadType.single => _buildSingleLayout(),
      SpreadType.threeCard => _buildThreeCardLayout(),
      SpreadType.custom => _buildGenericGridLayout(),
    };
  }

  Widget _buildSingleLayout() {
    return Center(
      child: CardRevealWidget(
        card: cards[0],
        deckId: deckId,
        position: 0,
        label: spreadType.resolvePositions(cards.length)[0],
        isRevealed: revealedPositions.contains(0),
        showCardName: showCardName,
        cardAspectRatio: cardAspectRatio,
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
              deckId: deckId,
              position: i,
              label: spreadType.resolvePositions(cards.length)[i],
              isRevealed: revealedPositions.contains(i),
              showCardName: showCardName,
        cardAspectRatio: cardAspectRatio,
        onTap: () => onCardTap(i),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGenericGridLayout() {
    if (cards.length == 1) return _buildSingleLayout();

    return LayoutBuilder(
      builder: (context, constraints) {
        // 항상 3열 고정
        const crossAxisCount = 3;

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: cardAspectRatio * 0.9,
          ),
          itemCount: cards.length,
          itemBuilder: (context, i) {
            return CardRevealWidget(
              card: cards[i],
              deckId: deckId,
              position: i,
              label: spreadType.resolvePositions(cards.length)[i],
              isRevealed: revealedPositions.contains(i),
              showCardName: showCardName,
        cardAspectRatio: cardAspectRatio,
        onTap: () => onCardTap(i),
            );
          },
        );
      },
    );
  }
}
