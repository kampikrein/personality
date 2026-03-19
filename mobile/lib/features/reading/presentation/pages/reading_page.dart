import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/dev_tuner/tunable_var.dart';
import '../../../../core/dev_tuner/tuner_registry.dart';
import '../../../shuffle/domain/entities/shuffle_result.dart';
import '../../../shuffle/presentation/pages/intention_page.dart';
import '../../../shuffle/presentation/providers/shuffle_providers.dart';
import '../../domain/entities/reading.dart';
import '../../domain/entities/reflective_prompts.dart';
import '../../domain/entities/spread_type.dart';
import '../providers/reading_providers.dart';
import '../widgets/spread_layout.dart';

// ── Dev Tuner 변수 ──
final readingCardHeightFactorProvider = StateProvider<double>((ref) => 0.45);
final readingContentPaddingProvider = StateProvider<double>((ref) => 16);

class ReadingPage extends ConsumerStatefulWidget {
  const ReadingPage({super.key, required this.deckId, this.spreadType = SpreadType.single});
  final String deckId;
  final SpreadType spreadType;

  @override
  ConsumerState<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends ConsumerState<ReadingPage> {
  late final _spreadType = widget.spreadType;
  final Set<int> _revealedPositions = {};

  @override
  Widget build(BuildContext context) {
    final shuffleResult = ref.watch(shuffleStateProvider);
    final question = ref.watch(readingQuestionProvider);
    final theme = Theme.of(context);

    if (kDebugMode) {
      ref.read(devTunerRegistryProvider).registerIfAbsent('reading', [
        TunableDouble(label: 'cardHeight%', provider: readingCardHeightFactorProvider, min: 0.3, max: 0.7, step: 0.05),
        TunableDouble(label: 'padding', provider: readingContentPaddingProvider, min: 8, max: 32, step: 4),
      ]);
    }
    final cardHeightFactor = ref.watch(readingCardHeightFactorProvider);
    final contentPadding = ref.watch(readingContentPaddingProvider);

    if (shuffleResult == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('리딩')),
        body: const Center(child: Text('셔플을 먼저 진행해주세요.')),
      );
    }

    final drawnCards =
        shuffleResult.cards.take(_spreadType.cardCount).toList();
    final allRevealed = _revealedPositions.length == _spreadType.cardCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(_spreadType.displayName),
        actions: [
          if (allRevealed)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () => _saveReading(drawnCards, question),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(contentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 질문 표시
            if (question.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"$question"',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 스프레드 레이아웃
            SizedBox(
              height: MediaQuery.of(context).size.height * cardHeightFactor,
              child: SpreadLayout(
                spreadType: _spreadType,
                cards: drawnCards,
                revealedPositions: _revealedPositions,
                onCardTap: (position) {
                  setState(() => _revealedPositions.add(position));
                },
              ),
            ),

            // 반성 질문 (모든 카드 공개 후)
            if (allRevealed) ...[
              const SizedBox(height: 24),
              Text(
                '성찰의 시간',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < drawnCards.length; i++) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_spreadType.positions[i]}: ${drawnCards[i].card.name}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _spreadType.guidances[i],
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ReflectivePrompts.getPrompt(drawnCards[i].card.cardId),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ],

            // 안전 고지
            const SizedBox(height: 16),
            Text(
              '타로는 자기 성찰의 도구입니다. 결과에 과도한 의미를 부여하지 마세요.\n'
              '심리적 어려움이 있다면 정신건강 위기상담전화 1577-0199',
              style: TextStyle(
                color: theme.colorScheme.secondary.withValues(alpha: 0.7),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveReading(
      List<ShuffledCard> drawnCards, String question) async {
    final reading = Reading(
      id: const Uuid().v4(),
      deckId: widget.deckId,
      spreadType: _spreadType,
      question: question.isNotEmpty ? question : null,
      drawnCards: List.generate(
        drawnCards.length,
        (i) => DrawnCardInfo(
          cardId: drawnCards[i].card.id,
          position: i,
          isReversed: drawnCards[i].isReversed,
        ),
      ),
      createdAt: DateTime.now(),
    );

    await ref.read(readingRepositoryProvider).saveReading(reading);
    if (mounted) {
      ref.read(readingQuestionProvider.notifier).clear();
      context.go('/');
    }
  }
}
