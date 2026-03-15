import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/repositories/reading_repository_impl.dart';
import '../../domain/entities/reading.dart';
import '../../domain/repositories/reading_repository.dart';

part 'reading_providers.g.dart';

@Riverpod(keepAlive: true)
ReadingRepository readingRepository(ReadingRepositoryRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return ReadingRepositoryImpl(db: db);
}

@riverpod
Stream<List<Reading>> watchReadings(WatchReadingsRef ref) {
  final repo = ref.watch(readingRepositoryProvider);
  return repo.watchAllReadings();
}
