import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/dev_tuner/tunable_var.dart';
import '../../../../core/dev_tuner/tuner_registry.dart';
import '../../../../core/widgets/mystical_scaffold.dart';
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

    return MysticalScaffold(
      title: '덱 선택',
      body: decksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kGold)),
        error: (err, _) => Center(child: Text('오류: $err', style: const TextStyle(color: kTextSecondary))),
        data: (decks) => ListView.builder(
          padding: EdgeInsets.fromLTRB(listPadding, listPadding, listPadding, 32),
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
  const _DeckPreviewCard({required this.deck, required this.onTap});

  final DeckMetadata deck;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(deckCardsProvider(deck.id));
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final thumbCacheW = (80 * pixelRatio).toInt().clamp(1, 320);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kDeepPurple.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kGold.withValues(alpha: 0.25), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: kGold.withValues(alpha: 0.04),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: kGold.withValues(alpha: 0.08),
          highlightColor: kGold.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // 카드 뒷면 이미지
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/images/${deck.id}/card_back.webp',
                    width: 58,
                    height: 82,
                    cacheWidth: thumbCacheW,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 58,
                      height: 82,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D1B4E),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: kGold.withValues(alpha: 0.3), width: 0.7),
                      ),
                      child: const Icon(Icons.auto_awesome, color: kGold, size: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // 덱 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck.name,
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${deck.totalCards}장',
                        style: const TextStyle(color: kTextSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // 대표 카드 2장 프리뷰
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
                                color: kDeepPurple,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: kGold.withValues(alpha: 0.6), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
