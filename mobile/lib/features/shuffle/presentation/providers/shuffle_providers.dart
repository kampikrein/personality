import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/entropy_pool.dart';
import '../../data/datasources/sensor_data_collector.dart';
import '../../data/repositories/shuffle_repository_impl.dart';
import '../../data/services/haptic_service.dart';
import '../../domain/entities/shuffle_config.dart';
import '../../domain/entities/shuffle_result.dart';
import '../../domain/repositories/shuffle_repository.dart';
import '../../domain/strategies/fisher_yates_shuffle_strategy.dart';
import '../../domain/strategies/shuffle_strategy.dart';
import '../../domain/usecases/shuffle_deck_usecase.dart';

part 'shuffle_providers.g.dart';

@Riverpod(keepAlive: true)
SensorDataCollector sensorDataCollector(SensorDataCollectorRef ref) {
  final collector = SensorDataCollector();
  ref.onDispose(() => collector.dispose());
  return collector;
}

@Riverpod(keepAlive: true)
EntropyPool entropyPool(EntropyPoolRef ref) {
  return EntropyPool();
}

@Riverpod(keepAlive: true)
HapticService hapticService(HapticServiceRef ref) {
  return HapticService();
}

@riverpod
ShuffleStrategy shuffleStrategy(ShuffleStrategyRef ref) {
  return FisherYatesShuffleStrategy();
}

@riverpod
ShuffleDeckUseCase shuffleDeckUseCase(ShuffleDeckUseCaseRef ref) {
  return ShuffleDeckUseCase(
    sensorCollector: ref.watch(sensorDataCollectorProvider),
    entropyPool: ref.watch(entropyPoolProvider),
  );
}

@Riverpod(keepAlive: true)
ShuffleRepository shuffleRepository(ShuffleRepositoryRef ref) {
  return ShuffleRepositoryImpl();
}

@Riverpod(keepAlive: true)
class ShuffleState extends _$ShuffleState {
  @override
  ShuffleResult? build() => null;

  void setResult(ShuffleResult result) {
    ref.read(shuffleRepositoryProvider).cacheLastResult(result);
    state = result;
  }

  void clear() => state = null;
}

@riverpod
class ShuffleConfigNotifier extends _$ShuffleConfigNotifier {
  @override
  ShuffleConfig build() => const ShuffleConfig();

  void update(ShuffleConfig config) => state = config;
}
