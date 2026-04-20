// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReadingImpl _$$ReadingImplFromJson(Map<String, dynamic> json) =>
    _$ReadingImpl(
      id: json['id'] as String,
      deckId: json['deckId'] as String,
      spreadType: $enumDecode(_$LayoutTypeEnumMap, json['spreadType']),
      question: json['question'] as String?,
      notes: json['notes'] as String?,
      drawnCards: (json['drawnCards'] as List<dynamic>)
          .map((e) => DrawnCardInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$ReadingImplToJson(_$ReadingImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deckId': instance.deckId,
      'spreadType': _$LayoutTypeEnumMap[instance.spreadType]!,
      'question': instance.question,
      'notes': instance.notes,
      'drawnCards': instance.drawnCards,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$LayoutTypeEnumMap = {
  LayoutType.linear: 'linear',
  LayoutType.tShape: 'tShape',
  LayoutType.grid3x3: 'grid3x3',
};

_$DrawnCardInfoImpl _$$DrawnCardInfoImplFromJson(Map<String, dynamic> json) =>
    _$DrawnCardInfoImpl(
      cardId: json['cardId'] as String,
      position: (json['position'] as num).toInt(),
      isReversed: json['isReversed'] as bool,
    );

Map<String, dynamic> _$$DrawnCardInfoImplToJson(_$DrawnCardInfoImpl instance) =>
    <String, dynamic>{
      'cardId': instance.cardId,
      'position': instance.position,
      'isReversed': instance.isReversed,
    };
