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
  int get schemaVersion => 8;

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
          if (from < 6) {
            await m.database.customStatement(
              'ALTER TABLE user_settings ADD COLUMN cards_per_row INTEGER DEFAULT 3',
            );
          }
          if (from < 7) {
            // 기존 풀셔플(3) 사용자를 2.5D(4)로 마이그레이션
            await m.database.customStatement(
              'UPDATE user_settings SET experience_level = 4 WHERE experience_level = 3',
            );
          }
          if (from < 8) {
            await m.database.customStatement('PRAGMA foreign_keys = OFF');
            try {
              await m.database.transaction(() async {
                // [A] readings 값 변환 — 멱등 (legacy 값 매칭 0행이면 no-op)
                await m.database.customStatement(
                  "UPDATE readings SET spread_type = 'linear' "
                  "WHERE spread_type IN ('single', 'threeCard', 'custom')",
                );
                // Phantom v7.5 재진입 가드: 이전 마이그레이션이 rename 까지 수행 후
                // user_version bump 전에 크래시한 경우 default_spread_type 이
                // 이미 존재하지 않는다. [B] UPDATE + [C] ALTER 모두 이 컬럼을
                // 참조하므로 하나의 존재 검사로 묶는다.
                final cols = await m.database.customSelect(
                  "SELECT name FROM pragma_table_info('user_settings')",
                ).get();
                final hasOldCol = cols.any(
                  (r) => r.data['name'] == 'default_spread_type',
                );
                if (hasOldCol) {
                  // [B] user_settings 값 변환 — 멱등. [C] 보다 먼저 실행되어야 함
                  await m.database.customStatement(
                    "UPDATE user_settings SET default_spread_type = 'linear' "
                    "WHERE default_spread_type IN ('single', 'threeCard', 'custom')",
                  );
                  // [C] user_settings 컬럼 rename
                  await m.database.customStatement(
                    'ALTER TABLE user_settings RENAME COLUMN default_spread_type '
                    'TO default_layout_type',
                  );
                }
                // Decision 5 — phantom v7.5 방지: user_version 도 트랜잭션 내부 commit
                await m.database.customStatement('PRAGMA user_version = 8');
              });
            } finally {
              await m.database.customStatement('PRAGMA foreign_keys = ON');
            }
          }
        },
      );
}
