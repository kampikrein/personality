// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserSettingsImpl _$$UserSettingsImplFromJson(Map<String, dynamic> json) =>
    _$UserSettingsImpl(
      selectedDeckId: json['selectedDeckId'] as String? ?? 'rws-standard',
      experienceLevel: (json['experienceLevel'] as num?)?.toInt() ?? 4,
      defaultCardCount: (json['defaultCardCount'] as num?)?.toInt() ?? 3,
      showFaceUp: json['showFaceUp'] as bool? ?? false,
      quickDrawEnabled: json['quickDrawEnabled'] as bool? ?? false,
      defaultLayoutType:
          $enumDecodeNullable(_$LayoutTypeEnumMap, json['defaultLayoutType']) ??
              LayoutType.linear,
      showCardName: json['showCardName'] as bool? ?? true,
      allowReversed: json['allowReversed'] as bool? ?? true,
      cardsPerRow: (json['cardsPerRow'] as num?)?.toInt() ?? 3,
      cardSizePreset: $enumDecodeNullable(
              _$CardSizePresetEnumMap, json['cardSizePreset']) ??
          CardSizePreset.standardTarot,
      customCardWidthMm:
          (json['customCardWidthMm'] as num?)?.toDouble() ?? 70.0,
      customCardHeightMm:
          (json['customCardHeightMm'] as num?)?.toDouble() ?? 120.0,
      intentPlacement: $enumDecodeNullable(
              _$IntentPlacementEnumMap, json['intentPlacement']) ??
          IntentPlacement.beforeShuffle,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$UserSettingsImplToJson(_$UserSettingsImpl instance) =>
    <String, dynamic>{
      'selectedDeckId': instance.selectedDeckId,
      'experienceLevel': instance.experienceLevel,
      'defaultCardCount': instance.defaultCardCount,
      'showFaceUp': instance.showFaceUp,
      'quickDrawEnabled': instance.quickDrawEnabled,
      'defaultLayoutType': _$LayoutTypeEnumMap[instance.defaultLayoutType]!,
      'showCardName': instance.showCardName,
      'allowReversed': instance.allowReversed,
      'cardsPerRow': instance.cardsPerRow,
      'cardSizePreset': _$CardSizePresetEnumMap[instance.cardSizePreset]!,
      'customCardWidthMm': instance.customCardWidthMm,
      'customCardHeightMm': instance.customCardHeightMm,
      'intentPlacement': _$IntentPlacementEnumMap[instance.intentPlacement]!,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$LayoutTypeEnumMap = {
  LayoutType.linear: 'linear',
  LayoutType.tShape: 'tShape',
  LayoutType.grid3x3: 'grid3x3',
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

const _$IntentPlacementEnumMap = {
  IntentPlacement.beforeShuffle: 'beforeShuffle',
  IntentPlacement.afterDraw: 'afterDraw',
  IntentPlacement.disabled: 'disabled',
};
