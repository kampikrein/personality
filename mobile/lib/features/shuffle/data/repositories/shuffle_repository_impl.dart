import '../../domain/entities/shuffle_result.dart';
import '../../domain/repositories/shuffle_repository.dart';

class ShuffleRepositoryImpl implements ShuffleRepository {
  ShuffleResult? _lastResult;

  @override
  void cacheLastResult(ShuffleResult result) {
    _lastResult = result;
  }

  @override
  ShuffleResult? getLastResult() => _lastResult;
}
