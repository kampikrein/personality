import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/mystical_scaffold.dart';
import '../../domain/entities/intent_placement.dart';
import '../providers/settings_providers.dart';

class IntentPlacementSettingsPage extends ConsumerStatefulWidget {
  const IntentPlacementSettingsPage({super.key});

  @override
  ConsumerState<IntentPlacementSettingsPage> createState() =>
      _IntentPlacementSettingsPageState();
}

class _IntentPlacementSettingsPageState
    extends ConsumerState<IntentPlacementSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(userSettingsProvider);

    return MysticalScaffold(
      title: '의도 설정',
      body: settingsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: kGold)),
        error: (e, _) => Center(
            child: Text('오류: $e',
                style: const TextStyle(color: kTextSecondary))),
        data: (settings) {
          final current = settings.intentPlacement;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              MysticalCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ...IntentPlacement.values.map((placement) {
                      final isSelected = placement == current;
                      final isLast =
                          placement == IntentPlacement.values.last;
                      return Column(
                        children: [
                          _IntentTile(
                            placement: placement,
                            isSelected: isSelected,
                            onTap: () => ref
                                .read(userSettingsRepositoryProvider)
                                .updateIntentPlacement(placement),
                          ),
                          if (!isLast) const GoldHairline(opacity: 0.1),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IntentTile extends StatelessWidget {
  const _IntentTile({
    required this.placement,
    required this.isSelected,
    required this.onTap,
  });

  final IntentPlacement placement;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? kGold
                      : kSoftPurple.withValues(alpha: 0.4),
                  width: isSelected ? 1.5 : 1,
                ),
                color: isSelected
                    ? kGold.withValues(alpha: 0.15)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.circle, color: kGold, size: 10)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    placement.displayLabel,
                    style: TextStyle(
                      color: isSelected ? kGold : kTextPrimary,
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  Text(
                    placement.description,
                    style: const TextStyle(
                        color: kTextSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_rounded, color: kGold, size: 18),
          ],
        ),
      ),
    );
  }
}
