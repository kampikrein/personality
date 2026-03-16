// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tarot_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TarotCardImpl _$$TarotCardImplFromJson(Map<String, dynamic> json) =>
    _$TarotCardImpl(
      id: json['id'] as String,
      deckId: json['deckId'] as String,
      cardId: json['cardId'] as String,
      name: json['name'] as String,
      arcana: json['arcana'] as String,
      suit: json['suit'] as String?,
      number: (json['number'] as num).toInt(),
      imagePath: json['imagePath'] as String,
      meanings: CardMeanings.fromJson(json['meanings'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$TarotCardImplToJson(_$TarotCardImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deckId': instance.deckId,
      'cardId': instance.cardId,
      'name': instance.name,
      'arcana': instance.arcana,
      'suit': instance.suit,
      'number': instance.number,
      'imagePath': instance.imagePath,
      'meanings': instance.meanings,
    };
