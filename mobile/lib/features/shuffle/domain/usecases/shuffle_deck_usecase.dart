import 'dart:math';

import '../entities/shuffle_config.dart';
import '../entities/shuffle_result.dart';
import '../strategies/shuffle_strategy.dart';
import '../../../deck/domain/entities/tarot_card.dart';
import '../../data/datasources/entropy_pool.dart';
import '../../data/datasources/sensor_data_collector.dart';

class ShuffleDeckUseCase {
  ShuffleDeckUseCase({
    required this.sensorCollector,
    required this.entropyPool,
  });

  final SensorDataCollector sensorCollector;
  final EntropyPool entropyPool;

  ShuffleResult execute({
    required List<TarotCard> cards,
    required ShuffleStrategy strategy,
    ShuffleConfig config = const ShuffleConfig(),
  }) {
    entropyPool.addSamples(sensorCollector.samples);

    final usedSensor =
        sensorCollector.sensorsAvailable && entropyPool.isReady;

    final random = Random.secure();

    final result = strategy.shuffle(
      cards: cards,
      random: random,
      config: config,
    );

    entropyPool.reset();

    return result.copyWith(usedSensorEntropy: usedSensor);
  }
}
