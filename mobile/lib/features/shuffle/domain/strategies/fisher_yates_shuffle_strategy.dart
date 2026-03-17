import 'dart:math';

import '../entities/shuffle_config.dart';
import '../entities/shuffle_result.dart';
import '../../../deck/domain/entities/tarot_card.dart';
import 'shuffle_strategy.dart';

class FisherYatesShuffleStrategy implements ShuffleStrategy {
  @override
  String get name => 'fisher_yates';

  @override
  String get displayName => 'Fisher-Yates 셔플';

  @override
  ShuffleResult shuffle({
    required List<TarotCard> cards,
    required Random random,
    required ShuffleConfig config,
  }) {
    final deck = List<TarotCard>.from(cards);

    // Knuth Fisher-Yates: O(n), 1/n! 균등 분포 (TAOCP Vol.2 §3.4.2)
    for (var i = deck.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = deck[i];
      deck[i] = deck[j];
      deck[j] = temp;
    }

    final shuffledCards = deck.map((card) {
      final isReversed = config.useReversals &&
          random.nextDouble() < config.reversalProbability;
      return ShuffledCard(card: card, isReversed: isReversed);
    }).toList();

    return ShuffleResult(
      cards: shuffledCards,
      entropyBits: 256,
      usedSensorEntropy: false,
      shuffledAt: DateTime.now(),
    );
  }
}
