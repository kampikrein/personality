import 'package:drift/drift.dart';

enum SyncStatus { pending, synced, conflict }

class Decks extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  BoolColumn get isStandardTarot =>
      boolean().withDefault(const Constant(true))();
  IntColumn get totalCards => integer()();
  TextColumn get creator => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus =>
      intEnum<SyncStatus>().withDefault(Constant(SyncStatus.pending.index))();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
