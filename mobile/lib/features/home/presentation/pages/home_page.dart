import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/dev_tuner/tunable_var.dart';
import '../../../../core/dev_tuner/tuner_registry.dart';
import '../../../deck/presentation/providers/deck_providers.dart';
import '../../../reading/domain/entities/spread_type.dart';
import '../../../reading/presentation/providers/reading_providers.dart';
import '../../../shuffle/presentation/providers/shuffle_providers.dart';

// ── Dev Tuner 변수 ──
final homeGradientCenterYProvider = StateProvider<double>((ref) => -0.3);
final homeGradientRadiusProvider = StateProvider<double>((ref) => 1.2);
final homeButtonHeightProvider = StateProvider<double>((ref) => 56);
final homeTitleIconSizeProvider = StateProvider<double>((ref) => 40);

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (_initialized) return;
    final repo = ref.read(deckRepositoryProvider);
    await repo.seedRwsDeck();
    if (mounted) setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    final readingsAsync = ref.watch(watchReadingsProvider);
    final theme = Theme.of(context);

    if (kDebugMode) {
      ref.read(devTunerRegistryProvider).registerIfAbsent('home', [
        TunableDouble(label: 'gradCenterY', provider: homeGradientCenterYProvider, min: -1.0, max: 1.0, step: 0.1),
        TunableDouble(label: 'gradRadius', provider: homeGradientRadiusProvider, min: 0.5, max: 3.0, step: 0.1),
        TunableDouble(label: 'btnHeight', provider: homeButtonHeightProvider, min: 40, max: 72, step: 4),
        TunableDouble(label: 'iconSize', provider: homeTitleIconSizeProvider, min: 24, max: 64, step: 4),
      ]);
    }

    final gradCenterY = ref.watch(homeGradientCenterYProvider);
    final gradRadius = ref.watch(homeGradientRadiusProvider);
    final btnHeight = ref.watch(homeButtonHeightProvider);
    final iconSize = ref.watch(homeTitleIconSizeProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, gradCenterY),
            radius: gradRadius,
            colors: const [Color(0xFF2A1B3D), Color(0xFF0D0A14)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Icon(Icons.nights_stay,
                    color: theme.colorScheme.primary, size: iconSize),
                const SizedBox(height: 8),
                Text(
                  'Personality Tarot',
                  style: theme.textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: btnHeight,
                  child: FilledButton.icon(
                    onPressed: _initialized ? () => _quickDraw(context) : null,
                    icon: const Icon(Icons.style, size: 20),
                    label: const Text('바로 뽑기',
                        style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: btnHeight,
                  child: ElevatedButton(
                    onPressed: () => context.pushNamed(
                      'shuffle',
                      pathParameters: {'deckId': 'rws-standard'},
                    ),
                    child: const Text('셔플 시작',
                        style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 32),
                Text('최근 리딩', style: theme.textTheme.bodyLarge),
                const SizedBox(height: 8),
                Expanded(
                  child: readingsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('오류: $err')),
                    data: (readings) => readings.isEmpty
                        ? Center(
                            child: Text(
                              '아직 리딩이 없습니다.\n셔플을 시작해보세요.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                          )
                        : ListView.builder(
                            itemCount: readings.length,
                            itemBuilder: (context, index) {
                              final reading = readings[index];
                              return Card(
                                child: ListTile(
                                  title:
                                      Text(reading.spreadType.displayName),
                                  subtitle:
                                      Text(reading.question ?? '질문 없음'),
                                  trailing: Text(
                                    _formatDate(reading.createdAt),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _quickDraw(BuildContext context) async {
    const deckId = 'rws-standard';
    final cards = await ref.read(deckCardsProvider(deckId).future);

    final useCase = ref.read(shuffleDeckUseCaseProvider);
    final strategy = ref.read(shuffleStrategyProvider);
    final result = useCase.execute(cards: cards, strategy: strategy);

    ref.read(shuffleStateProvider.notifier).setResult(result);

    if (!context.mounted) return;
    await context.pushNamed(
      'reading',
      pathParameters: {'deckId': deckId},
      extra: SpreadType.threeCard,
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
