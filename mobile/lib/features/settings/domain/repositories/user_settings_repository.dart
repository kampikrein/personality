import '../entities/user_settings.dart';

abstract class UserSettingsRepository {
  Stream<UserSettings> watchSettings();
  Future<UserSettings> getSettings();
  Future<void> updateSelectedDeckId(String deckId);
  Future<void> updateExperienceLevel(int level);
  Future<void> updateDefaultCardCount(int count);
  Future<void> updateShowFaceUp(bool showFaceUp);
  Future<void> updateQuickDrawEnabled(bool enabled);
  Future<void> updateDefaultSpreadType(String spreadTypeName);
}
