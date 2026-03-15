import 'dart:math';

import '../entities/shuffle_config.dart';
import '../entities/shuffle_result.dart';
import '../../../deck/domain/entities/tarot_card.dart';
import 'shuffle_strategy.dart';

class RiffleShuffleStrategy implements ShuffleStrategy {
  @override
  String get name => 'riffle';

  @override
  String get displayName => '리플 셔플';

  @override
  ShuffleResult shuffle({
    required List<TarotCard> cards,
    required Random random,
    required ShuffleConfig config,
  }) {
    var deck = List<TarotCard>.from(cards);

    for (var i = 0; i < config.shuffleCount; i++) {
      deck = _riffleOnce(deck, random);
    }

    final shuffledCards = deck.map((card) {
      final isReversed = config.useReversals &&
          random.nextDouble() < config.reversalProbability;
      return ShuffledCard(card: card, isReversed: isReversed);
    }).toList();

    return ShuffleResult(
      cards: shuffledCards,
      entropyBits: 256,
      usedSensorEntropy: true,
      shuffledAt: DateTime.now(),
    );
  }

  List<TarotCard> _riffleOnce(List<TarotCard> deck, Random random) {
    final mid = deck.length ~/ 2;
    final offset = random.nextInt(5) - 2;
    final cutPoint = (mid + offset).clamp(1, deck.length - 1);

    final leftHalf = deck.sublist(0, cutPoint);
    final rightHalf = deck.sublist(cutPoint);

    final result = <TarotCard>[];
    var leftIdx = 0;
    var rightIdx = 0;

    while (leftIdx < leftHalf.length || rightIdx < rightHalf.length) {
      final leftDrop = random.nextInt(3) + 1;
      for (var j = 0; j < leftDrop && leftIdx < leftHalf.length; j++) {
        result.add(leftHalf[leftIdx++]);
      }
      final rightDrop = random.nextInt(3) + 1;
      for (var j = 0; j < rightDrop && rightIdx < rightHalf.length; j++) {
        result.add(rightHalf[rightIdx++]);
      }
    }

    return result;
  }
}
