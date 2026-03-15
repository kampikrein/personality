import '../entities/reading.dart';

abstract class ReadingRepository {
  Future<List<Reading>> getAllReadings();
  Stream<List<Reading>> watchAllReadings();
  Future<void> saveReading(Reading reading);
  Future<void> deleteReading(String id);
}
