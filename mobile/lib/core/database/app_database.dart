import 'package:drift/drift.dart';

import '../../features/deck/domain/entities/card_meanings.dart';
import 'converters/card_meanings_converter.dart';
import 'tables/decks_table.dart';
import 'tables/cards_table.dart';
import 'tables/readings_table.dart';
import 'tables/drawn_cards_table.dart';
import 'daos/deck_dao.dart';
import 'daos/card_dao.dart';
import 'daos/reading_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Decks, Cards, Readings, DrawnCards],
  daos: [DeckDao, CardDao, ReadingDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) => m.createAll(),
      );
}
