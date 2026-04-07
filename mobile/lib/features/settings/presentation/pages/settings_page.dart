import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../deck/presentation/providers/deck_providers.dart';
import '../../../reading/domain/entities/spread_type.dart';
import '../../domain/entities/card_size_preset.dart';
import '../../domain/entities/user_settings.dart';
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

            // 카드 크기
            const _SectionTitle('카드 크기'),
            _CardSizeSection(settings: settings),
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

class _CardSizeSection extends ConsumerStatefulWidget {
  const _CardSizeSection({required this.settings});
  final UserSettings settings;

  @override
  ConsumerState<_CardSizeSection> createState() => _CardSizeSectionState();
}

class _CardSizeSectionState extends ConsumerState<_CardSizeSection> {
  late TextEditingController _widthController;
  late TextEditingController _heightController;

  @override
  void initState() {
    super.initState();
    _widthController = TextEditingController(
      text: widget.settings.customCardWidthMm.toStringAsFixed(1),
    );
    _heightController = TextEditingController(
      text: widget.settings.customCardHeightMm.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _applyCustomSize() {
    final w = double.tryParse(_widthController.text);
    final h = double.tryParse(_heightController.text);
    if (w != null && h != null && w > 0 && h > 0) {
      ref.read(userSettingsRepositoryProvider).updateCustomCardSize(w, h);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentPreset = widget.settings.cardSizePreset;
    final aspectRatio = widget.settings.cardAspectRatio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preset selector
        ...CardSizePreset.values.map((preset) {
          return RadioListTile<CardSizePreset>(
            title: Text(preset.label),
            subtitle: Text(
              preset == CardSizePreset.custom
                  ? '${_widthController.text} × ${_heightController.text} mm'
                  : preset.subtitle,
            ),
            value: preset,
            groupValue: currentPreset,
            dense: true,
            onChanged: (v) {
              if (v != null) {
                ref
                    .read(userSettingsRepositoryProvider)
                    .updateCardSizePreset(v.name);
              }
            },
          );
        }),

        // Custom size inputs (only when custom is selected)
        if (currentPreset == CardSizePreset.custom) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _widthController,
                    decoration: const InputDecoration(
                      labelText: '가로 (mm)',
                      isDense: true,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    onSubmitted: (_) => _applyCustomSize(),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('×'),
                ),
                Expanded(
                  child: TextField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: '세로 (mm)',
                      isDense: true,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    onSubmitted: (_) => _applyCustomSize(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _applyCustomSize,
                  tooltip: '적용',
                ),
              ],
            ),
          ),
        ],

        // Preview card
        const SizedBox(height: 16),
        Center(
          child: SizedBox(
            height: 120,
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2D1B4E),
                  border: Border.all(color: const Color(0xFFD4A84B)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    '미리보기',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFD4A84B),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '종횡비: ${aspectRatio.toStringAsFixed(3)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
