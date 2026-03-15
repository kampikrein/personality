import 'package:freezed_annotation/freezed_annotation.dart';

import 'card_meanings.dart';

part 'tarot_card.freezed.dart';
part 'tarot_card.g.dart';

@freezed
class TarotCard with _$TarotCard {
  const factory TarotCard({
    required String id,
    required String deckId,
    required String cardId,
    required String name,
    required String arcana,
    String? suit,
    required int number,
    required String imagePath,
    required CardMeanings meanings,
  }) = _TarotCard;

  factory TarotCard.fromJson(Map<String, dynamic> json) =>
      _$TarotCardFromJson(json);
}
