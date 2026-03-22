import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../reading/domain/entities/spread_type.dart';
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
  Future<void> updateDefaultSpreadType(String spreadTypeName) async {
    await db.userSettingsDao.updateSettings(
      UserSettingsTableCompanion(defaultSpreadType: Value(spreadTypeName)),
    );
  }

  UserSettings _toDomain(UserSettingsTableData row) {
    return UserSettings(
      selectedDeckId: row.selectedDeckId,
      experienceLevel: row.experienceLevel,
      defaultCardCount: row.defaultCardCount,
      showFaceUp: row.showFaceUp,
      quickDrawEnabled: row.quickDrawEnabled,
      defaultSpreadType: SpreadType.values.byName(row.defaultSpreadType),
      updatedAt: row.updatedAt,
    );
  }
}
