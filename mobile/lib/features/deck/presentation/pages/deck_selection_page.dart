import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/dev_tuner/tunable_var.dart';
import '../../../../core/dev_tuner/tuner_registry.dart';
import '../../domain/entities/deck_metadata.dart';
import '../providers/deck_providers.dart';

// ── Dev Tuner 변수 ──
final deckListPaddingProvider = StateProvider<double>((ref) => 16);

class DeckSelectionPage extends ConsumerWidget {
  const DeckSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(watchDecksProvider);

    if (kDebugMode) {
      ref.read(devTunerRegistryProvider).registerIfAbsent('deck', [
        TunableDouble(label: 'listPad', provider: deckListPaddingProvider, min: 8, max: 32, step: 4),
      ]);
    }
    final listPadding = ref.watch(deckListPaddingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('덱 선택')),
      body: decksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('오류: $err')),
        data: (decks) => ListView.builder(
          padding: EdgeInsets.all(listPadding),
          itemCount: decks.length,
          itemBuilder: (context, index) {
            final deck = decks[index];
            return _DeckPreviewCard(
              deck: deck,
              onTap: () {
                ref.read(selectedDeckProvider.notifier).select(deck);
                context.pushNamed(
                  'intention',
                  pathParameters: {'deckId': deck.id},
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _DeckPreviewCard extends ConsumerWidget {
  const _DeckPreviewCard({
    required this.deck,
    required this.onTap,
  });

  final DeckMetadata deck;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cardsAsync = ref.watch(deckCardsProvider(deck.id));
    // 썸네일 cacheWidth: 80 logical px * pixelRatio
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final thumbCacheW = (80 * pixelRatio).toInt().clamp(1, 320);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 카드 뒷면 이미지 (왼쪽)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/${deck.id}/card_back.webp',
                  width: 60,
                  height: 84,
                  cacheWidth: thumbCacheW,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 60,
                    height: 84,
                    color: const Color(0xFF2D1B4E),
                    child: const Icon(Icons.auto_awesome, color: Colors.white54, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 덱 정보 (중앙)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deck.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${deck.totalCards}장',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              // 대표 카드 2장 프리뷰 (오른쪽)
              cardsAsync.when(
                loading: () => const SizedBox(width: 68),
                error: (_, __) => const SizedBox(width: 68),
                data: (cards) {
                  final previewCards = cards.take(2).toList();
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < previewCards.length; i++) ...[
                        if (i > 0) const SizedBox(width: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.asset(
                            previewCards[i].imagePath,
                            width: 32,
                            height: 45,
                            cacheWidth: thumbCacheW,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 32,
                              height: 45,
                              color: const Color(0xFF1A1028),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: theme.colorScheme.secondary),
            ],
          ),
        ),
      ),
    );
  }
}
