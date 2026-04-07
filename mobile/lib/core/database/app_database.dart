import 'package:drift/drift.dart';

import '../../features/deck/domain/entities/card_meanings.dart';
import 'converters/card_meanings_converter.dart';
import 'tables/decks_table.dart';
import 'tables/cards_table.dart';
import 'tables/readings_table.dart';
import 'tables/drawn_cards_table.dart';
import 'tables/user_settings_table.dart';
import 'daos/deck_dao.dart';
import 'daos/card_dao.dart';
import 'daos/reading_dao.dart';
import 'daos/user_settings_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Decks, Cards, Readings, DrawnCards, UserSettingsTable],
  daos: [DeckDao, CardDao, ReadingDao, UserSettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) => m.createAll(),
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(userSettingsTable);
          }
          if (from < 3) {
            await m.database.customStatement(
              "UPDATE user_settings SET experience_level = 3, default_spread_type = 'custom'",
            );
          }
          if (from < 4) {
            await m.database.customStatement(
              'ALTER TABLE user_settings ADD COLUMN show_card_name INTEGER DEFAULT 1',
            );
            await m.database.customStatement(
              'ALTER TABLE user_settings ADD COLUMN allow_reversed INTEGER DEFAULT 1',
            );
          }
          if (from < 5) {
            await m.database.customStatement(
              "ALTER TABLE user_settings ADD COLUMN card_size_preset TEXT DEFAULT 'standardTarot'",
            );
            await m.database.customStatement(
              'ALTER TABLE user_settings ADD COLUMN custom_card_width_mm REAL DEFAULT 70.0',
            );
            await m.database.customStatement(
              'ALTER TABLE user_settings ADD COLUMN custom_card_height_mm REAL DEFAULT 120.0',
            );
          }
        },
      );
}
