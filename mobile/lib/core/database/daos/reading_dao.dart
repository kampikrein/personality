import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/readings_table.dart';
import '../tables/drawn_cards_table.dart';

part 'reading_dao.g.dart';

@DriftAccessor(tables: [Readings, DrawnCards])
class ReadingDao extends DatabaseAccessor<AppDatabase> with _$ReadingDaoMixin {
  ReadingDao(super.db);

  Future<List<Reading>> getAllReadings() =>
      (select(readings)..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
          .get();

  Stream<List<Reading>> watchAllReadings() =>
      (select(readings)..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
          .watch();

  Future<void> insertReading(
    ReadingsCompanion reading,
    List<DrawnCardsCompanion> cards,
  ) async {
    await transaction(() async {
      await into(readings).insert(reading);
      await batch((b) => b.insertAll(drawnCards, cards));
    });
  }

  Future<List<DrawnCard>> getDrawnCardsForReading(String readingId) =>
      (select(drawnCards)
            ..where((dc) => dc.readingId.equals(readingId))
            ..orderBy([(dc) => OrderingTerm.asc(dc.position)]))
          .get();

  Future<int> deleteReading(String id) async {
    await (delete(drawnCards)..where((dc) => dc.readingId.equals(id))).go();
    return (delete(readings)..where((r) => r.id.equals(id))).go();
  }
}
