// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deck_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DeckMetadataImpl _$$DeckMetadataImplFromJson(Map<String, dynamic> json) =>
    _$DeckMetadataImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      isStandardTarot: json['isStandardTarot'] as bool? ?? true,
      totalCards: (json['totalCards'] as num).toInt(),
      creator: json['creator'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$DeckMetadataImplToJson(_$DeckMetadataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isStandardTarot': instance.isStandardTarot,
      'totalCards': instance.totalCards,
      'creator': instance.creator,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
