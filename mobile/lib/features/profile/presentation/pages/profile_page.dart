import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../settings/presentation/providers/settings_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(userSettingsProvider);
    final theme = Theme.of(context);

    final settings = settingsAsync.valueOrNull;
    final levelLabel = switch (settings?.experienceLevel ?? 1) {
      1 => '즉시',
      2 => '연출',
      3 => '2D',
      4 => '2.5D',
      _ => '즉시',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('유저메뉴')),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          // 프로필 아이콘
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(Icons.person, size: 40, color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: 12),
          Text(
            '탐험가',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          Text(
            '레벨 ${settings?.experienceLevel ?? 1} ($levelLabel)',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const Divider(),
          // 설정
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('설정'),
            subtitle: const Text('체험 레벨, 카드 수, 스프레드'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed('settings'),
          ),
          // 덱 관리
          ListTile(
            leading: const Icon(Icons.layers),
            title: const Text('덱 관리'),
            subtitle: const Text('덱 선택 및 탐색'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed('deck'),
          ),
          // 앱 정보
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('앱 정보'),
            subtitle: const Text('Personality Tarot v0.1.1'),
          ),
        ],
      ),
    );
  }
}
