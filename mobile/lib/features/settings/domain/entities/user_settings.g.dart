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
      showCardName: json['showCardName'] as bool? ?? true,
      allowReversed: json['allowReversed'] as bool? ?? true,
      cardSizePreset: $enumDecodeNullable(
              _$CardSizePresetEnumMap, json['cardSizePreset']) ??
          CardSizePreset.standardTarot,
      customCardWidthMm:
          (json['customCardWidthMm'] as num?)?.toDouble() ?? 70.0,
      customCardHeightMm:
          (json['customCardHeightMm'] as num?)?.toDouble() ?? 120.0,
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
      'showCardName': instance.showCardName,
      'allowReversed': instance.allowReversed,
      'cardSizePreset': _$CardSizePresetEnumMap[instance.cardSizePreset]!,
      'customCardWidthMm': instance.customCardWidthMm,
      'customCardHeightMm': instance.customCardHeightMm,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$SpreadTypeEnumMap = {
  SpreadType.single: 'single',
  SpreadType.threeCard: 'threeCard',
  SpreadType.custom: 'custom',
};

const _$CardSizePresetEnumMap = {
  CardSizePreset.standardTarot: 'standardTarot',
  CardSizePreset.mini: 'mini',
  CardSizePreset.largeTarot: 'largeTarot',
  CardSizePreset.oracle: 'oracle',
  CardSizePreset.thoth: 'thoth',
  CardSizePreset.poker: 'poker',
  CardSizePreset.custom: 'custom',
};
