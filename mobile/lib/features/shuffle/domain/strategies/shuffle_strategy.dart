import 'dart:math';

import '../entities/shuffle_config.dart';
import '../entities/shuffle_result.dart';
import '../../../deck/domain/entities/tarot_card.dart';

abstract class ShuffleStrategy {
  String get name;
  String get displayName;

  ShuffleResult shuffle({
    required List<TarotCard> cards,
    required Random random,
    required ShuffleConfig config,
  });
}
