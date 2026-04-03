import 'package:drift/drift.dart';

class UserSettingsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get selectedDeckId =>
      text().withDefault(const Constant('rws-standard'))();
  IntColumn get experienceLevel =>
      integer().withDefault(const Constant(3))();
  IntColumn get defaultCardCount =>
      integer().withDefault(const Constant(3))();
  BoolColumn get showFaceUp =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get quickDrawEnabled =>
      boolean().withDefault(const Constant(false))();
  TextColumn get defaultSpreadType =>
      text().withDefault(const Constant('custom'))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  String get tableName => 'user_settings';
}
