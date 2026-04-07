import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../reading/domain/entities/spread_type.dart';
import 'card_size_preset.dart';

part 'user_settings.freezed.dart';
part 'user_settings.g.dart';

@freezed
class UserSettings with _$UserSettings {
  const UserSettings._();

  const factory UserSettings({
    @Default('rws-standard') String selectedDeckId,
    @Default(3) int experienceLevel,
    @Default(3) int defaultCardCount,
    @Default(false) bool showFaceUp,
    @Default(false) bool quickDrawEnabled,
    @Default(SpreadType.custom) SpreadType defaultSpreadType,
    @Default(true) bool showCardName,
    @Default(true) bool allowReversed,
    @Default(CardSizePreset.standardTarot) CardSizePreset cardSizePreset,
    @Default(70.0) double customCardWidthMm,
    @Default(120.0) double customCardHeightMm,
    required DateTime updatedAt,
  }) = _UserSettings;

  /// The effective card aspect ratio (width / height) based on preset or custom values.
  double get cardAspectRatio => cardSizePreset == CardSizePreset.custom
      ? customCardWidthMm / customCardHeightMm
      : cardSizePreset.aspectRatio;

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
}
