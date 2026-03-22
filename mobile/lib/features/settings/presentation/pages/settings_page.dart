import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../deck/presentation/providers/deck_providers.dart';
import '../../../reading/domain/entities/spread_type.dart';
import '../providers/settings_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(userSettingsProvider);
    final decksAsync = ref.watch(watchDecksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (settings) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 덱 선택
            const _SectionTitle('덱 선택'),
            decksAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('덱 로딩 오류: $e'),
              data: (decks) => DropdownButtonFormField<String>(
                initialValue: settings.selectedDeckId,
                items: decks
                    .map((d) => DropdownMenuItem(
                          value: d.id,
                          child: Text(d.name),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    ref.read(userSettingsRepositoryProvider)
                        .updateSelectedDeckId(v);
                  }
                },
              ),
            ),
            const SizedBox(height: 24),

            // 체험 레벨
            const _SectionTitle('체험 레벨'),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('즉시'), icon: Icon(Icons.flash_on)),
                ButtonSegment(value: 2, label: Text('연출'), icon: Icon(Icons.animation)),
                ButtonSegment(value: 3, label: Text('풀셔플'), icon: Icon(Icons.shuffle)),
              ],
              selected: {settings.experienceLevel},
              onSelectionChanged: (s) {
                ref.read(userSettingsRepositoryProvider)
                    .updateExperienceLevel(s.first);
              },
            ),
            const SizedBox(height: 24),

            // 기본 카드 수
            _SectionTitle('기본 카드 수: ${settings.defaultCardCount}장'),
            Slider(
              value: settings.defaultCardCount.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '${settings.defaultCardCount}장',
              onChanged: (v) {
                ref.read(userSettingsRepositoryProvider)
                    .updateDefaultCardCount(v.round());
              },
            ),
            const SizedBox(height: 16),

            // 앞면/뒷면
            SwitchListTile(
              title: const Text('앞면으로 시작'),
              subtitle: const Text('카드를 바로 앞면으로 표시합니다'),
              value: settings.showFaceUp,
              onChanged: (v) {
                ref.read(userSettingsRepositoryProvider)
                    .updateShowFaceUp(v);
              },
            ),

            // 즉시 뽑기 토글
            SwitchListTile(
              title: const Text('앱 시작 시 바로 뽑기'),
              subtitle: const Text('다음 실행부터 설정된 방식으로 자동 카드 뽑기'),
              value: settings.quickDrawEnabled,
              onChanged: (v) {
                ref.read(userSettingsRepositoryProvider)
                    .updateQuickDrawEnabled(v);
              },
            ),
            const SizedBox(height: 16),

            // 기본 스프레드
            const _SectionTitle('기본 스프레드'),
            DropdownButtonFormField<SpreadType>(
              initialValue: settings.defaultSpreadType,
              items: SpreadType.values
                  .map((st) => DropdownMenuItem(
                        value: st,
                        child: Text(st.displayName),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  ref.read(userSettingsRepositoryProvider)
                      .updateDefaultSpreadType(v.name);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
