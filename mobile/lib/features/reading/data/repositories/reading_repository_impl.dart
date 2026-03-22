import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/reading.dart' as domain;
import '../../domain/entities/spread_type.dart';
import '../../domain/repositories/reading_repository.dart';

class ReadingRepositoryImpl implements ReadingRepository {
  ReadingRepositoryImpl({required this.db});

  final AppDatabase db;

  @override
  Future<List<domain.Reading>> getAllReadings() async {
    final readings = await db.readingDao.getAllReadings();
    return Future.wait(readings.map(_toDomainReading));
  }

  @override
  Stream<List<domain.Reading>> watchAllReadings() {
    return db.readingDao.watchAllReadings().asyncMap(
          (readings) => Future.wait(readings.map(_toDomainReading)),
        );
  }

  @override
  Future<void> saveReading(domain.Reading reading) async {
    final readingCompanion = ReadingsCompanion.insert(
      id: reading.id,
      deckId: reading.deckId,
      spreadType: reading.spreadType.name,
      question: Value(reading.question),
      notes: Value(reading.notes),
      createdAt: reading.createdAt,
      updatedAt: reading.createdAt,
    );

    final drawnCardCompanions = reading.drawnCards.map((dc) {
      return DrawnCardsCompanion.insert(
        id: '${reading.id}-${dc.position}',
        readingId: reading.id,
        cardId: dc.cardId,
        position: dc.position,
        isReversed: dc.isReversed,
        createdAt: reading.createdAt,
      );
    }).toList();

    await db.readingDao.insertReading(readingCompanion, drawnCardCompanions);
  }

  @override
  Future<void> deleteReading(String id) async {
    await db.readingDao.deleteReading(id);
  }

  @override
  Future<void> updateNotes(String readingId, String? notes) async {
    await db.readingDao.updateNotes(readingId, notes);
  }

  @override
  Future<void> addDrawnCard(
    String readingId, domain.DrawnCardInfo card, DateTime createdAt,
  ) async {
    await db.readingDao.addDrawnCard(
      DrawnCardsCompanion.insert(
        id: '$readingId-${card.position}',
        readingId: readingId,
        cardId: card.cardId,
        position: card.position,
        isReversed: card.isReversed,
        createdAt: createdAt,
      ),
    );
  }

  @override
  Stream<List<domain.Reading>> watchReadingsBySpreadType(SpreadType spreadType) {
    return db.readingDao
        .watchReadingsBySpreadType(spreadType.name)
        .asyncMap((readings) => Future.wait(readings.map(_toDomainReading)));
  }

  @override
  Future<domain.Reading?> getReadingById(String id) async {
    final rows = await db.readingDao.getAllReadings();
    final row = rows.where((r) => r.id == id).firstOrNull;
    if (row == null) return null;
    return _toDomainReading(row);
  }

  Future<domain.Reading> _toDomainReading(Reading row) async {
    final drawnCards = await db.readingDao.getDrawnCardsForReading(row.id);
    return domain.Reading(
      id: row.id,
      deckId: row.deckId,
      spreadType: SpreadType.values.byName(row.spreadType),
      question: row.question,
      notes: row.notes,
      drawnCards: drawnCards
          .map((dc) => domain.DrawnCardInfo(
                cardId: dc.cardId,
                position: dc.position,
                isReversed: dc.isReversed,
              ))
          .toList(),
      createdAt: row.createdAt,
    );
  }
}
