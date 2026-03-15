import '../entities/shuffle_result.dart';

abstract class ShuffleRepository {
  void cacheLastResult(ShuffleResult result);
  ShuffleResult? getLastResult();
}
