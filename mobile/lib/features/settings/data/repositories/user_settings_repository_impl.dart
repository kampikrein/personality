import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../reading/domain/entities/layout_type.dart';
import '../../domain/entities/card_size_preset.dart';
import '../../domain/entities/intent_placement.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/user_settings_repository.dart';

class UserSettingsRepositoryImpl implements UserSettingsRepository {
  UserSettingsRepositoryImpl({required this.db});

  final AppDatabase db;

  @override
  Stream<UserSettings> watchSettings() {
    return db.userSettingsDao.watchSettings().map(_toDomain);
  }

  @override
  Future<UserSettings> getSettings() async {
    final row = await db.userSettingsDao.getSettings();
    return _toDomain(row);
  }

  @override
  Future<void> updateSelectedDeckId(String deckId) async {
    await db.userSettingsDao.updateSettings(
      UserSettingsTableCompanion(selectedDeckId: Value(deckId)),
    );
  }

  @override
  Future<void> updateExperienceLevel(int level) async {
    await db.userSettingsDao.updateSettings(
      UserSettingsTableCompanion(experienceLevel: Value(level)),
    );
  }

  @override
  Future<void> updateDefaultCardCount(int count) async {
    await db.userSettingsDao.updateSettings(
      UserSettingsTableCompanion(defaultCardCount: Value(count)),
    );
  }

  @override
  Future<void> updateShowFaceUp(bool showFaceUp) async {
    await db.userSettingsDao.updateSettings(
      UserSettingsTableCompanion(showFaceUp: Value(showFaceUp)),
    );
  }

  @override
  Future<void> updateQuickDrawEnabled(bool enabled) async {
    await db.userSettingsDao.updateSettings(
      UserSettingsTableCompanion(quickDrawEnabled: Value(enabled)),
    );
  }

  @override
  Future<void> updateDefaultLayoutType(String layoutTypeName) async {
    await db.userSettingsDao.updateSettings(
      UserSettingsTableCompanion(defaultLayoutType: Value(layoutTypeName)),
    );
  }

  @override
  Future<void> updateShowCardName(bool showCardName) async {
    await db.userSettingsDao.updateSettings(
      UserSettingsTableCompanion(showCardName: Value(showCardName)),
    );
  }

  @override
  Future<void> updateAllowReversed(bool allowReversed) async {
    await db.userSettingsDao.updateSettings(
      UserSettingsTableCompanion(allowReversed: Value(allowReversed)),
    );
  }

  @override
  Future<void> updateCardSizePreset(String presetName) async {
    await db.userSettingsDao.updateSettings(
      UserSettingsTableCompanion(cardSizePreset: Value(presetName)),
    );
  }

  @override
  Future<void> updateCustomCardSize(double widthMm, double heightMm) async {
    await db.userSettingsDao.updateSettings(
      UserSettingsTableCompanion(
        cardSizePreset: const Value('custom'),
        customCardWidthMm: Value(widthMm),
        customCardHeightMm: Value(heightMm),
      ),
    );
  }

  @override
  Future<void> updateCardsPerRow(int count) async {
    await db.userSettingsDao.updateSettings(
      UserSettingsTableCompanion(cardsPerRow: Value(count)),
    );
  }

  @override
  Future<void> updateIntentPlacement(IntentPlacement value) async {
    await db.userSettingsDao.updateIntentPlacement(value.name);
  }

  UserSettings _toDomain(UserSettingsTableData row) {
    return UserSettings(
      selectedDeckId: row.selectedDeckId,
      experienceLevel: row.experienceLevel,
      defaultCardCount: row.defaultCardCount,
      showFaceUp: row.showFaceUp,
      quickDrawEnabled: row.quickDrawEnabled,
      defaultLayoutType: LayoutType.values.firstWhere(
        (e) => e.name == row.defaultLayoutType,
        orElse: () => LayoutType.linear,
      ),
      showCardName: row.showCardName ?? true,
      allowReversed: row.allowReversed ?? true,
      cardSizePreset: CardSizePreset.values.firstWhere(
        (p) => p.name == row.cardSizePreset,
        orElse: () => CardSizePreset.standardTarot,
      ),
      cardsPerRow: row.cardsPerRow ?? 3,
      customCardWidthMm: row.customCardWidthMm,
      customCardHeightMm: row.customCardHeightMm,
      intentPlacement: IntentPlacement.values.firstWhere(
        (e) => e.name == row.intentPlacement,
        orElse: () => IntentPlacement.beforeShuffle,
      ),
      updatedAt: row.updatedAt,
    );
  }
}
