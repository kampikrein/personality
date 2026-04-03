import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../reading/domain/entities/spread_type.dart';

part 'user_settings.freezed.dart';
part 'user_settings.g.dart';

@freezed
class UserSettings with _$UserSettings {
  const factory UserSettings({
    @Default('rws-standard') String selectedDeckId,
    @Default(3) int experienceLevel,
    @Default(3) int defaultCardCount,
    @Default(false) bool showFaceUp,
    @Default(false) bool quickDrawEnabled,
    @Default(SpreadType.custom) SpreadType defaultSpreadType,
    required DateTime updatedAt,
  }) = _UserSettings;

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
}
