// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shuffle_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ShuffleResultImpl _$$ShuffleResultImplFromJson(Map<String, dynamic> json) =>
    _$ShuffleResultImpl(
      cards: (json['cards'] as List<dynamic>)
          .map((e) => ShuffledCard.fromJson(e as Map<String, dynamic>))
          .toList(),
      entropyBits: (json['entropyBits'] as num).toInt(),
      usedSensorEntropy: json['usedSensorEntropy'] as bool,
      shuffledAt: DateTime.parse(json['shuffledAt'] as String),
    );

Map<String, dynamic> _$$ShuffleResultImplToJson(_$ShuffleResultImpl instance) =>
    <String, dynamic>{
      'cards': instance.cards,
      'entropyBits': instance.entropyBits,
      'usedSensorEntropy': instance.usedSensorEntropy,
      'shuffledAt': instance.shuffledAt.toIso8601String(),
    };

_$ShuffledCardImpl _$$ShuffledCardImplFromJson(Map<String, dynamic> json) =>
    _$ShuffledCardImpl(
      card: TarotCard.fromJson(json['card'] as Map<String, dynamic>),
      isReversed: json['isReversed'] as bool,
    );

Map<String, dynamic> _$$ShuffledCardImplToJson(_$ShuffledCardImpl instance) =>
    <String, dynamic>{
      'card': instance.card,
      'isReversed': instance.isReversed,
    };
