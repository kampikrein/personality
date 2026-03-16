import 'dart:async';

import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../deck/presentation/providers/deck_providers.dart';
import '../../../reading/domain/entities/spread_type.dart';
import '../../data/datasources/entropy_pool.dart';
import '../../data/datasources/sensor_data_collector.dart';
import '../game/tarot_game.dart';
import '../providers/shuffle_providers.dart';
import '../widgets/entropy_progress_indicator.dart';

enum ShufflePhase { collecting, shuffling, drawing }

class ShufflePage extends ConsumerStatefulWidget {
  const ShufflePage({super.key, required this.deckId});
  final String deckId;

  @override
  ConsumerState<ShufflePage> createState() => _ShufflePageState();
}

class _ShufflePageState extends ConsumerState<ShufflePage> {
  ShufflePhase _phase = ShufflePhase.collecting;
  late TarotGame _game;
  SpreadType _selectedSpread = SpreadType.single;
  Timer? _pollTimer;
  int _lastFedSampleCount = 0;

  @override
  void initState() {
    super.initState();
    _game = TarotGame();
    ref.read(entropyPoolProvider).reset();
    ref.read(sensorDataCollectorProvider).startCollecting();
    // 센서 샘플을 엔트로피 풀에 주기적으로 투입 + UI 갱신
    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_phase == ShufflePhase.collecting && mounted) {
        final collector = ref.read(sensorDataCollectorProvider);
        final pool = ref.read(entropyPoolProvider);
        final newSamples = collector.samples.skip(_lastFedSampleCount).toList();
        if (newSamples.isNotEmpty) {
          pool.addSamples(newSamples);
          _lastFedSampleCount = collector.sampleCount;
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    ref.read(sensorDataCollectorProvider).stopCollecting();
    // GameWidget이 _game의 라이프사이클을 자동 관리 — 수동 dispose 불필요
    super.dispose();
  }

  Future<void> _startShuffle() async {
    setState(() => _phase = ShufflePhase.shuffling);
    try {
      final cards = await ref.read(deckCardsProvider(widget.deckId).future);
      final useCase = ref.read(shuffleDeckUseCaseProvider);
      final strategy = ref.read(shuffleStrategyProvider);
      final config = ref.read(shuffleConfigNotifierProvider);

      // 물리 엔진이 카드를 움직이는 동안 잠시 대기 (RiffleAnimation 대체)
      await Future<void>.delayed(const Duration(milliseconds: 1500));

      final result = useCase.execute(
        cards: cards,
        strategy: strategy,
        config: config,
      );

      ref.read(shuffleStateProvider.notifier).setResult(result);
      ref.read(hapticServiceProvider).mediumImpact();

      setState(() => _phase = ShufflePhase.drawing);
    } catch (e) {
      setState(() => _phase = ShufflePhase.collecting);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('셔플에 실패했습니다: $e')),
        );
      }
    }
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
            child: GameWidget<TarotGame>(game: _game),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: switch (_phase) {
                ShufflePhase.collecting =>
                  _buildCollectingUI(theme, entropy, sensor),
                ShufflePhase.shuffling => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '카드가 당신의 에너지에 응답하고 있습니다...',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
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
              : '조용히 호흡을 가다듬으세요.\n우주가 카드를 배열합니다.',
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
