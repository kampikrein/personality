import '../entities/reading.dart';
import '../entities/spread_type.dart';

abstract class ReadingRepository {
  Future<List<Reading>> getAllReadings();
  Stream<List<Reading>> watchAllReadings();
  Future<void> saveReading(Reading reading);
  Future<void> deleteReading(String id);
  Future<void> updateNotes(String readingId, String? notes);
  Future<void> addDrawnCard(String readingId, DrawnCardInfo card, DateTime createdAt);
  Stream<List<Reading>> watchReadingsBySpreadType(SpreadType spreadType);
  Future<Reading?> getReadingById(String id);
}
