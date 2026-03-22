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
    return transaction(() async {
      await (delete(drawnCards)..where((dc) => dc.readingId.equals(id))).go();
      return (delete(readings)..where((r) => r.id.equals(id))).go();
    });
  }

  /// 리딩의 notes 필드 업데이트.
  Future<void> updateNotes(String readingId, String? notes) async {
    await (update(readings)..where((r) => r.id.equals(readingId))).write(
      ReadingsCompanion(
        notes: Value(notes),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 리딩에 drawn card 1장 추가. "+1 한 장 더" 기능용.
  Future<void> addDrawnCard(DrawnCardsCompanion card) async {
    await into(drawnCards).insert(card);
    // Reading의 updatedAt도 갱신
    await (update(readings)..where((r) => r.id.equals(card.readingId.value)))
        .write(ReadingsCompanion(updatedAt: Value(DateTime.now())));
  }

  /// spreadType 기준 필터 조회 (리딩 목록 페이지용).
  Stream<List<Reading>> watchReadingsBySpreadType(String spreadType) {
    return (select(readings)
          ..where((r) => r.spreadType.equals(spreadType))
          ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
        .watch();
  }
}
