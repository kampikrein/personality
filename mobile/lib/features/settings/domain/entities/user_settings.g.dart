// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserSettingsImpl _$$UserSettingsImplFromJson(Map<String, dynamic> json) =>
    _$UserSettingsImpl(
      selectedDeckId: json['selectedDeckId'] as String? ?? 'rws-standard',
      experienceLevel: (json['experienceLevel'] as num?)?.toInt() ?? 3,
      defaultCardCount: (json['defaultCardCount'] as num?)?.toInt() ?? 3,
      showFaceUp: json['showFaceUp'] as bool? ?? false,
      quickDrawEnabled: json['quickDrawEnabled'] as bool? ?? false,
      defaultSpreadType:
          $enumDecodeNullable(_$SpreadTypeEnumMap, json['defaultSpreadType']) ??
              SpreadType.custom,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$UserSettingsImplToJson(_$UserSettingsImpl instance) =>
    <String, dynamic>{
      'selectedDeckId': instance.selectedDeckId,
      'experienceLevel': instance.experienceLevel,
      'defaultCardCount': instance.defaultCardCount,
      'showFaceUp': instance.showFaceUp,
      'quickDrawEnabled': instance.quickDrawEnabled,
      'defaultSpreadType': _$SpreadTypeEnumMap[instance.defaultSpreadType]!,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$SpreadTypeEnumMap = {
  SpreadType.single: 'single',
  SpreadType.threeCard: 'threeCard',
  SpreadType.custom: 'custom',
};
