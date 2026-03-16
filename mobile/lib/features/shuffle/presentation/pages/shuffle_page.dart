import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../deck/presentation/providers/deck_providers.dart';
import '../../../reading/domain/entities/spread_type.dart';
import '../../data/datasources/entropy_pool.dart';
import '../../data/datasources/sensor_data_collector.dart';
import '../providers/shuffle_providers.dart';
import '../widgets/card_painter.dart';
import '../widgets/entropy_progress_indicator.dart';
import '../widgets/riffle_animation_controller.dart';

enum ShufflePhase { collecting, shuffling, drawing }

class ShufflePage extends ConsumerStatefulWidget {
  const ShufflePage({super.key, required this.deckId});
  final String deckId;

  @override
  ConsumerState<ShufflePage> createState() => _ShufflePageState();
}

class _ShufflePageState extends ConsumerState<ShufflePage>
    with TickerProviderStateMixin {
  ShufflePhase _phase = ShufflePhase.collecting;
  late RiffleAnimationState _animState;
  SpreadType _selectedSpread = SpreadType.single;

  @override
  void initState() {
    super.initState();
    _animState = RiffleAnimationState(vsync: this);
    ref.read(sensorDataCollectorProvider).startCollecting();
  }

  @override
  void dispose() {
    ref.read(sensorDataCollectorProvider).stopCollecting();
    _animState.dispose();
    super.dispose();
  }

  Future<void> _startShuffle() async {
    setState(() => _phase = ShufflePhase.shuffling);

    final cards = await ref.read(deckCardsProvider(widget.deckId).future);
    final useCase = ref.read(shuffleDeckUseCaseProvider);
    final strategy = ref.read(shuffleStrategyProvider);
    final config = ref.read(shuffleConfigNotifierProvider);

    await _animState.playRiffle(
      cardCount: cards.length,
      shuffleCount: config.shuffleCount,
    );

    final result = useCase.execute(
      cards: cards,
      strategy: strategy,
      config: config,
    );

    ref.read(shuffleStateProvider.notifier).setResult(result);
    ref.read(hapticServiceProvider).mediumImpact();

    setState(() => _phase = ShufflePhase.drawing);
  }

  void _goToReading() {
    context.pushNamed(
      'reading',
      pathParameters: {'deckId': widget.deckId},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entropy = ref.watch(entropyPoolProvider);
    final sensor = ref.watch(sensorDataCollectorProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('셔플')),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: CardPainter(animationState: _animState),
                size: Size.infinite,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: switch (_phase) {
                ShufflePhase.collecting =>
                  _buildCollectingUI(theme, entropy, sensor),
                ShufflePhase.shuffling =>
                  const Center(child: Text('셔플 중...')),
                ShufflePhase.drawing => _buildDrawingUI(theme),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectingUI(
    ThemeData theme,
    EntropyPool entropy,
    SensorDataCollector sensor,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        EntropyProgressIndicator(
          progress: entropy.progress,
          sensorsAvailable: sensor.sensorsAvailable,
        ),
        const SizedBox(height: 8),
        Text(
          sensor.sensorsAvailable
              ? '디바이스를 흔들어 셔플 에너지를 모으세요'
              : '센서를 사용할 수 없습니다. 시스템 난수로 진행합니다.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        SegmentedButton<SpreadType>(
          segments: SpreadType.values.map((s) {
            return ButtonSegment(value: s, label: Text(s.displayName));
          }).toList(),
          selected: {_selectedSpread},
          onSelectionChanged: (selected) {
            setState(() => _selectedSpread = selected.first);
          },
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: (entropy.isReady || !sensor.sensorsAvailable)
              ? _startShuffle
              : null,
          child: const Text('셔플 시작'),
        ),
      ],
    );
  }

  Widget _buildDrawingUI(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('셔플 완료! 카드를 뽑아보세요.',
            style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _goToReading,
          child: Text('${_selectedSpread.displayName} 리딩'),
        ),
      ],
    );
  }
}
