import 'package:drift/drift.dart';

import '../converters/card_meanings_converter.dart';
import 'decks_table.dart';

class Cards extends Table {
  TextColumn get id => text()();
  TextColumn get deckId => text().references(Decks, #id, onDelete: KeyAction.cascade)();
  TextColumn get cardId => text()();
  TextColumn get name => text()();
  TextColumn get arcana => text()();
  TextColumn get suit => text().nullable()();
  IntColumn get number => integer()();
  TextColumn get imagePath => text()();
  TextColumn get meanings =>
      text().map(const CardMeaningsConverter())();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus =>
      intEnum<SyncStatus>().withDefault(Constant(SyncStatus.pending.index))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {deckId, cardId},
      ];
}
