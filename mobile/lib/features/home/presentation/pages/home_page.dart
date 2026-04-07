import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../deck/presentation/providers/deck_providers.dart';
import '../../../reading/presentation/providers/reading_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';

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

  /// 설정된 체험 레벨에 따라 뽑기 경로로 이동
  void _startDraw(BuildContext context, int experienceLevel, String deckId) {
    switch (experienceLevel) {
      case 1:
        context.push('/draw/instant');
      case 2:
        context.push('/draw/animated');
      case 3: // 2D 셔플 (TODO: 전용 페이지 구현 후 분기)
        context.pushNamed('intention', pathParameters: {'deckId': deckId});
      case 4: // 2.5D 물리 셔플
        context.pushNamed('intention', pathParameters: {'deckId': deckId});
      default:
        context.push('/draw/instant');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(userSettingsProvider);
    final readingsAsync = ref.watch(watchReadingsProvider);
    final decksAsync = ref.watch(watchDecksProvider);
    final theme = Theme.of(context);

    final settings = settingsAsync.valueOrNull;
    final experienceLevel = settings?.experienceLevel ?? 4;
    final selectedDeckId = settings?.selectedDeckId ?? 'rws-standard';
    final defaultCardCount = settings?.defaultCardCount ?? 3;

    // 현재 덱 이름 해결
    final deckName = decksAsync.valueOrNull
            ?.where((d) => d.id == selectedDeckId)
            .firstOrNull
            ?.name ??
        selectedDeckId;

    final levelLabel = switch (experienceLevel) {
      1 => '즉시',
      2 => '연출',
      3 => '2D',
      4 => '2.5D',
      _ => '즉시',
    };

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3),
            radius: 1.2,
            colors: [Color(0xFF2A1B3D), Color(0xFF0D0A14)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── 헤더 ──
                  Icon(Icons.nights_stay,
                      color: theme.colorScheme.primary, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Personality Tarot',
                    style: theme.textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // ── 현재 설정 요약 ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _InfoChip(label: levelLabel, icon: Icons.speed),
                        _InfoChip(
                            label: '$defaultCardCount장',
                            icon: Icons.style),
                        _InfoChip(label: deckName, icon: Icons.layers),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── 뽑기 버튼 ──
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _initialized
                            ? () => _startDraw(
                                context, experienceLevel, selectedDeckId)
                            : null,
                        borderRadius: BorderRadius.circular(100),
                        child: Ink(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.primary
                                    .withValues(alpha: 0.6),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.3),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.style,
                                  size: 48,
                                  color: theme.colorScheme.onPrimary),
                              const SizedBox(height: 8),
                              Text(
                                '바로 뽑기',
                                style:
                                    theme.textTheme.titleLarge?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── 최근 리딩 미리보기 ──
                  Align(
                    alignment: Alignment.centerLeft,
                    child:
                        Text('최근 리딩', style: theme.textTheme.bodyLarge),
                  ),
                  const SizedBox(height: 8),
                  readingsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('오류: $err')),
                    data: (readings) => readings.isEmpty
                        ? Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                '아직 리딩이 없습니다.\n뽑기를 시작해보세요.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          )
                        : Column(
                            children: readings.take(3).map((reading) {
                              return Card(
                                child: ListTile(
                                  title:
                                      Text(reading.spreadType.displayName),
                                  subtitle:
                                      Text(reading.question ?? '질문 없음'),
                                  trailing: Text(
                                    _formatDate(reading.createdAt),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  onTap: () => context.push(
                                    '/readings/${reading.id}',
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// 설정 정보 칩 위젯
class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
