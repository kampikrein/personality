import '../entities/intent_placement.dart';
import '../entities/user_settings.dart';

abstract class UserSettingsRepository {
  Stream<UserSettings> watchSettings();
  Future<UserSettings> getSettings();
  Future<void> updateSelectedDeckId(String deckId);
  Future<void> updateExperienceLevel(int level);
  Future<void> updateDefaultCardCount(int count);
  Future<void> updateShowFaceUp(bool showFaceUp);
  Future<void> updateQuickDrawEnabled(bool enabled);
  Future<void> updateDefaultLayoutType(String layoutTypeName);
  Future<void> updateShowCardName(bool showCardName);
  Future<void> updateAllowReversed(bool allowReversed);
  Future<void> updateCardSizePreset(String presetName);
  Future<void> updateCustomCardSize(double widthMm, double heightMm);
  Future<void> updateCardsPerRow(int count);
  Future<void> updateIntentPlacement(IntentPlacement value);
}
