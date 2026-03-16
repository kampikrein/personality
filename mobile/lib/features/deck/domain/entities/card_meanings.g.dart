// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_meanings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CardMeaningsImpl _$$CardMeaningsImplFromJson(Map<String, dynamic> json) =>
    _$CardMeaningsImpl(
      upright: (json['upright'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      reversed: (json['reversed'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      customNotes: json['customNotes'] as String?,
    );

Map<String, dynamic> _$$CardMeaningsImplToJson(_$CardMeaningsImpl instance) =>
    <String, dynamic>{
      'upright': instance.upright,
      'reversed': instance.reversed,
      'customNotes': instance.customNotes,
    };
