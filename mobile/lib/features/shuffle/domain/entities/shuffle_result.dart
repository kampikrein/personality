import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../deck/domain/entities/tarot_card.dart';

part 'shuffle_result.freezed.dart';
part 'shuffle_result.g.dart';

@freezed
class ShuffleResult with _$ShuffleResult {
  const factory ShuffleResult({
    required List<ShuffledCard> cards,
    required int entropyBits,
    required bool usedSensorEntropy,
    required DateTime shuffledAt,
  }) = _ShuffleResult;

  factory ShuffleResult.fromJson(Map<String, dynamic> json) =>
      _$ShuffleResultFromJson(json);
}

@freezed
class ShuffledCard with _$ShuffledCard {
  const factory ShuffledCard({
    required TarotCard card,
    required bool isReversed,
  }) = _ShuffledCard;

  factory ShuffledCard.fromJson(Map<String, dynamic> json) =>
      _$ShuffledCardFromJson(json);
}
