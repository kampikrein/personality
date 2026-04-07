import 'package:drift/drift.dart';

class UserSettingsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get selectedDeckId =>
      text().withDefault(const Constant('rws-standard'))();
  IntColumn get experienceLevel =>
      integer().withDefault(const Constant(4))();
  IntColumn get defaultCardCount =>
      integer().withDefault(const Constant(3))();
  BoolColumn get showFaceUp =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get quickDrawEnabled =>
      boolean().withDefault(const Constant(false))();
  TextColumn get defaultSpreadType =>
      text().withDefault(const Constant('custom'))();
  BoolColumn get showCardName =>
      boolean().nullable().withDefault(const Constant(true))();
  BoolColumn get allowReversed =>
      boolean().nullable().withDefault(const Constant(true))();
  TextColumn get cardSizePreset =>
      text().withDefault(const Constant('standardTarot'))();
  RealColumn get customCardWidthMm =>
      real().withDefault(const Constant(70.0))();
  RealColumn get customCardHeightMm =>
      real().withDefault(const Constant(120.0))();
  IntColumn get cardsPerRow =>
      integer().nullable().withDefault(const Constant(3))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  String get tableName => 'user_settings';
}
