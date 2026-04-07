import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
                ButtonSegment(value: 3, label: Text('2D'), icon: Icon(Icons.style)),
                ButtonSegment(value: 4, label: Text('2.5D'), icon: Icon(Icons.view_in_ar)),
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

            // 카드 이름 표시
            SwitchListTile(
              title: const Text('카드 이름 표시'),
              subtitle: const Text('카드 아래에 이름을 표시합니다'),
              value: settings.showCardName,
              onChanged: (v) {
                ref.read(userSettingsRepositoryProvider)
                    .updateShowCardName(v);
              },
            ),

            // 역방향 허용
            SwitchListTile(
              title: const Text('역방향 카드 허용'),
              subtitle: const Text('카드가 거꾸로 뽑힐 수 있습니다'),
              value: settings.allowReversed,
              onChanged: (v) {
                ref.read(userSettingsRepositoryProvider)
                    .updateAllowReversed(v);
              },
            ),

            // 한 줄 카드 수
            const _SectionTitle('한 줄 카드 수'),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1장')),
                ButtonSegment(value: 2, label: Text('2장')),
                ButtonSegment(value: 3, label: Text('3장')),
              ],
              selected: {settings.cardsPerRow},
              onSelectionChanged: (s) {
                ref.read(userSettingsRepositoryProvider)
                    .updateCardsPerRow(s.first);
              },
            ),
            const SizedBox(height: 24),

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
            const SizedBox(height: 24),

            // 카드 크기 (별도 페이지)
            ListTile(
              leading: const Icon(Icons.aspect_ratio),
              title: const Text('카드 크기'),
              subtitle: Text(settings.cardSizePreset.label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/card-size'),
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
