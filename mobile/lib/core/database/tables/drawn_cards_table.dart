import 'package:drift/drift.dart';

import 'cards_table.dart';
import 'readings_table.dart';

class DrawnCards extends Table {
  TextColumn get id => text()();
  TextColumn get readingId => text().references(Readings, #id, onDelete: KeyAction.cascade)();
  TextColumn get cardId => text().references(Cards, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  BoolColumn get isReversed => boolean()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
