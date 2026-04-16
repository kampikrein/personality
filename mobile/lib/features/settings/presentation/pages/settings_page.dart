import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/mystical_scaffold.dart';
import '../../../deck/presentation/providers/deck_providers.dart';
import '../../../reading/domain/entities/spread_type.dart';
import '../providers/settings_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(userSettingsProvider);
    final decksAsync = ref.watch(watchDecksProvider);

    return MysticalScaffold(
      title: '설정',
      body: settingsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: kGold),
        ),
        error: (e, _) => Center(
          child: Text('오류: $e', style: const TextStyle(color: kTextSecondary)),
        ),
        data: (settings) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // ── 덱 선택 ──
            _SettingsSection(
              title: '덱 선택',
              icon: Icons.layers_outlined,
              child: decksAsync.when(
                loading: () => const LinearProgressIndicator(color: kGold, backgroundColor: kDeepPurple),
                error: (e, _) => Text('덱 로딩 오류: $e', style: const TextStyle(color: kTextSecondary)),
                data: (decks) => _MysticalDropdown<String>(
                  value: settings.selectedDeckId,
                  items: decks.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                  onChanged: (v) {
                    if (v != null) ref.read(userSettingsRepositoryProvider).updateSelectedDeckId(v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── 체험 레벨 ──
            _SettingsSection(
              title: '체험 레벨',
              icon: Icons.speed_outlined,
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('즉시'), icon: Icon(Icons.flash_on, size: 14)),
                  ButtonSegment(value: 2, label: Text('연출'), icon: Icon(Icons.animation, size: 14)),
                  ButtonSegment(value: 3, label: Text('2D'), icon: Icon(Icons.style, size: 14)),
                  ButtonSegment(value: 4, label: Text('2.5D'), icon: Icon(Icons.view_in_ar, size: 14)),
                ],
                selected: {settings.experienceLevel},
                onSelectionChanged: (s) {
                  ref.read(userSettingsRepositoryProvider).updateExperienceLevel(s.first);
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) return kGold.withValues(alpha: 0.2);
                    return kDarkSurface.withValues(alpha: 0.5);
                  }),
                  side: WidgetStateProperty.all(
                    BorderSide(color: kGold.withValues(alpha: 0.3), width: 0.7),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── 기본 카드 수 ──
            _SettingsSection(
              title: '기본 카드 수: ${settings.defaultCardCount}장',
              icon: Icons.style_outlined,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: kGold,
                  inactiveTrackColor: kGold.withValues(alpha: 0.2),
                  thumbColor: kGold,
                  overlayColor: kGold.withValues(alpha: 0.15),
                  valueIndicatorColor: kDeepPurple,
                  valueIndicatorTextStyle: const TextStyle(color: kGold),
                ),
                child: Slider(
                  value: settings.defaultCardCount.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '${settings.defaultCardCount}장',
                  onChanged: (v) {
                    ref.read(userSettingsRepositoryProvider).updateDefaultCardCount(v.round());
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── 토글 설정들 ──
            MysticalCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SwitchTile(
                    title: '앞면으로 시작',
                    subtitle: '카드를 바로 앞면으로 표시합니다',
                    value: settings.showFaceUp,
                    onChanged: (v) => ref.read(userSettingsRepositoryProvider).updateShowFaceUp(v),
                  ),
                  GoldHairline(opacity: 0.1),
                  _SwitchTile(
                    title: '카드 이름 표시',
                    subtitle: '카드 아래에 이름을 표시합니다',
                    value: settings.showCardName,
                    onChanged: (v) => ref.read(userSettingsRepositoryProvider).updateShowCardName(v),
                  ),
                  GoldHairline(opacity: 0.1),
                  _SwitchTile(
                    title: '역방향 카드 허용',
                    subtitle: '카드가 거꾸로 뽑힐 수 있습니다',
                    value: settings.allowReversed,
                    onChanged: (v) => ref.read(userSettingsRepositoryProvider).updateAllowReversed(v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── 한 줄 카드 수 ──
            _SettingsSection(
              title: '한 줄 카드 수',
              icon: Icons.grid_view_outlined,
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('1장')),
                  ButtonSegment(value: 2, label: Text('2장')),
                  ButtonSegment(value: 3, label: Text('3장')),
                ],
                selected: {settings.cardsPerRow},
                onSelectionChanged: (s) {
                  ref.read(userSettingsRepositoryProvider).updateCardsPerRow(s.first);
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) return kGold.withValues(alpha: 0.2);
                    return kDarkSurface.withValues(alpha: 0.5);
                  }),
                  side: WidgetStateProperty.all(
                    BorderSide(color: kGold.withValues(alpha: 0.3), width: 0.7),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── 기본 스프레드 ──
            _SettingsSection(
              title: '기본 스프레드',
              icon: Icons.auto_awesome_outlined,
              child: _MysticalDropdown<SpreadType>(
                value: settings.defaultSpreadType,
                items: SpreadType.values
                    .map((st) => DropdownMenuItem(value: st, child: Text(st.displayName)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) ref.read(userSettingsRepositoryProvider).updateDefaultSpreadType(v.name);
                },
              ),
            ),
            const SizedBox(height: 12),

            // ── 카드 크기 (별도 페이지) ──
            MysticalCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(Icons.aspect_ratio, color: kGold.withValues(alpha: 0.8), size: 20),
                title: const Text('카드 크기', style: TextStyle(color: kTextPrimary)),
                subtitle: Text(settings.cardSizePreset.label, style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                trailing: Icon(Icons.chevron_right, color: kTextSecondary.withValues(alpha: 0.6)),
                onTap: () => context.push('/settings/card-size'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 설정 섹션 컨테이너 ────────────────────────────────────────
class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MysticalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoldSectionTitle(title, icon: icon),
          child,
        ],
      ),
    );
  }
}

// ── 미스틱 드롭다운 ───────────────────────────────────────────
class _MysticalDropdown<T> extends StatelessWidget {
  const _MysticalDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: kDarkSurface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kGold.withValues(alpha: 0.25), width: 0.7),
      ),
      child: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        isExpanded: true,
        style: const TextStyle(color: kTextPrimary, fontSize: 14),
        dropdownColor: kDeepPurple,
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.keyboard_arrow_down, color: kGold, size: 18),
        isDense: true,
      ),
    );
  }
}

// ── 스위치 타일 ───────────────────────────────────────────────
class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: kTextPrimary, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: kTextSecondary, fontSize: 12)),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: kGold,
              activeTrackColor: kGold.withValues(alpha: 0.25),
              inactiveThumbColor: kTextSecondary,
              inactiveTrackColor: kDarkSurface.withValues(alpha: 0.6),
              trackOutlineColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return kGold.withValues(alpha: 0.5);
                return kSoftPurple.withValues(alpha: 0.25);
              }),
            ),
          ),
        ],
      ),
    );
  }
}
