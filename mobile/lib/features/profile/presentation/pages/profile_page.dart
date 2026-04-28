import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/mystical_scaffold.dart';
import '../../../settings/presentation/providers/settings_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(userSettingsProvider);
    final settings = settingsAsync.valueOrNull;

    final levelLabel = switch (settings?.experienceLevel ?? 1) {
      1 => '즉시',
      2 => '연출',
      3 => '2D',
      4 => '2.5D',
      _ => '즉시',
    };

    return MysticalScaffold(
      title: '유저메뉴',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          // ── 프로필 헤더 ──
          Center(
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kDeepPurple,
                    border: Border.all(color: kGold.withValues(alpha: 0.5), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: kGold.withValues(alpha: 0.15),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person_outline, size: 40, color: kGold),
                ),
                const SizedBox(height: 14),
                const Text(
                  '탐험가',
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: kGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kGold.withValues(alpha: 0.35), width: 0.7),
                  ),
                  child: Text(
                    'Lv.${settings?.experienceLevel ?? 1} · $levelLabel',
                    style: const TextStyle(color: kGold, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          const GoldHairline(opacity: 0.3),
          const SizedBox(height: 20),

          // ── 메뉴 목록 ──
          MysticalCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _MenuTile(
                  icon: Icons.settings_outlined,
                  title: '앱 설정',
                  subtitle: '환경설정',
                  onTap: () => context.pushNamed('settings'),
                ),
                const GoldHairline(opacity: 0.1),
                _MenuTile(
                  icon: Icons.layers_outlined,
                  title: '덱 관리',
                  subtitle: '덱 선택 및 탐색',
                  onTap: () => context.pushNamed('deck'),
                ),
                const GoldHairline(opacity: 0.1),
                const _MenuTile(
                  icon: Icons.info_outline,
                  title: '앱 정보',
                  subtitle: 'Personality Tarot v0.1.1',
                  onTap: null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: kGold.withValues(alpha: 0.06),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kGold.withValues(alpha: 0.1),
                  border: Border.all(color: kGold.withValues(alpha: 0.3), width: 0.7),
                ),
                child: Icon(icon, color: kGold, size: 17),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                    Text(subtitle, style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, color: kGold.withValues(alpha: 0.5), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
