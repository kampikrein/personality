import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/repositories/user_settings_repository_impl.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/user_settings_repository.dart';

part 'settings_providers.g.dart';

@Riverpod(keepAlive: true)
UserSettingsRepository userSettingsRepository(UserSettingsRepositoryRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return UserSettingsRepositoryImpl(db: db);
}

@riverpod
Stream<UserSettings> userSettings(UserSettingsRef ref) {
  final repo = ref.watch(userSettingsRepositoryProvider);
  return repo.watchSettings();
}
