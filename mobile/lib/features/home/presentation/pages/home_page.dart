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
      case 3:
        context.pushNamed('shuffle', pathParameters: {'deckId': deckId});
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
    final experienceLevel = settings?.experienceLevel ?? 1;
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
      3 => '풀셔플',
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 헤더 ──
                const SizedBox(height: 16),
                Icon(Icons.nights_stay,
                    color: theme.colorScheme.primary, size: 40),
                const SizedBox(height: 8),
                Text(
                  'Personality Tarot',
                  style: theme.textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // ── 기능 카드 그리드 ──
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    // 뽑기 시작
                    _HubCard(
                      icon: Icons.style,
                      title: '뽑기 시작',
                      subtitle: '$levelLabel \u2022 $defaultCardCount장 \u2022 $deckName',
                      color: theme.colorScheme.primary,
                      enabled: _initialized,
                      onTap: () =>
                          _startDraw(context, experienceLevel, selectedDeckId),
                    ),
                    // 리딩 기록
                    _HubCard(
                      icon: Icons.history,
                      title: '리딩 기록',
                      subtitle: readingsAsync.valueOrNull != null
                          ? '${readingsAsync.valueOrNull!.length}개의 기록'
                          : '로딩 중...',
                      color: theme.colorScheme.secondary,
                      onTap: () => context.pushNamed('readings'),
                    ),
                    // 덱 선택
                    _HubCard(
                      icon: Icons.layers,
                      title: '덱 선택',
                      subtitle: '현재: $deckName',
                      color: theme.colorScheme.tertiary,
                      onTap: () => context.pushNamed('deck'),
                    ),
                    // 설정
                    _HubCard(
                      icon: Icons.tune,
                      title: '설정',
                      subtitle: '레벨 $experienceLevel ($levelLabel)',
                      color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      onTap: () => context.pushNamed('settings'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── 최근 리딩 미리보기 ──
                Text('최근 리딩', style: theme.textTheme.bodyLarge),
                const SizedBox(height: 8),
                readingsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('오류: $err')),
                  data: (readings) => readings.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
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
                                title: Text(reading.spreadType.displayName),
                                subtitle:
                                    Text(reading.question ?? '질문 없음'),
                                trailing: Text(
                                  _formatDate(reading.createdAt),
                                  style: theme.textTheme.bodySmall,
                                ),
                                onTap: () => context.pushNamed(
                                  'reading-detail',
                                  pathParameters: {'readingId': reading.id},
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
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// 홈 허브 기능 카드 위젯
class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
