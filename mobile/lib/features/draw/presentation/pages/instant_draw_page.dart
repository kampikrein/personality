import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../reading/domain/entities/reading.dart';
import '../../../reading/domain/entities/reflective_prompts.dart';
import '../../../reading/domain/entities/spread_type.dart';
import '../../../reading/presentation/providers/reading_providers.dart';
import '../../../reading/presentation/widgets/spread_layout.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../shuffle/domain/entities/shuffle_result.dart';
import '../../../shuffle/presentation/providers/shuffle_providers.dart';
import '../../../deck/presentation/providers/deck_providers.dart';
import '../../../shuffle/presentation/pages/intention_page.dart';

class InstantDrawPage extends ConsumerStatefulWidget {
  const InstantDrawPage({super.key});

  @override
  ConsumerState<InstantDrawPage> createState() => _InstantDrawPageState();
}

class _InstantDrawPageState extends ConsumerState<InstantDrawPage> {
  ShuffleResult? _shuffleResult;
  late int _currentCardCount;
  late SpreadType _spreadType;
  late String _deckId;
  final Set<int> _revealedPositions = {};
  String? _savedReadingId;
  bool _autoSaved = false;
  bool _loading = true;

  // 질문 입력 관련
  final _questionController = TextEditingController();
  bool _questionExpanded = false;

  @override
  void initState() {
    super.initState();
    _initSettings();
    _executeDraw();
  }

  void _initSettings() {
    final settings = ref.read(userSettingsProvider).valueOrNull;
    _spreadType = settings?.defaultSpreadType ?? SpreadType.threeCard;
    _currentCardCount = _spreadType == SpreadType.custom
        ? settings?.defaultCardCount ?? 3
        : _spreadType.cardCount;
    _deckId = settings?.selectedDeckId ?? 'rws-standard';
  }

  Future<void> _executeDraw() async {
    // [이전 뽑기 상태 초기화] keepAlive provider 잔류 방지
    ref.read(shuffleStateProvider.notifier).clear();
    ref.read(readingQuestionProvider.notifier).clear();

    // 덱 시드 보장 (홈을 건너뛴 경우)
    final repo = ref.read(deckRepositoryProvider);
    await repo.seedRwsDeck();

    final cards = await ref.read(deckCardsProvider(_deckId).future);
    final useCase = ref.read(shuffleDeckUseCaseProvider);
    final strategy = ref.read(shuffleStrategyProvider);
    final result = useCase.execute(cards: cards, strategy: strategy);
    ref.read(shuffleStateProvider.notifier).setResult(result);

    if (!mounted) return;
    setState(() {
      _shuffleResult = result;
      _loading = false;
      // 즉시 뽑기 — 모든 카드 즉시 reveal
      for (var i = 0; i < _currentCardCount; i++) {
        _revealedPositions.add(i);
      }
    });
  }

  void _autoSave() {
    if (_autoSaved || _shuffleResult == null) return;
    _autoSaved = true;

    final readingId = const Uuid().v4();
    _savedReadingId = readingId;

    final drawnCards = _shuffleResult!.cards.take(_currentCardCount).toList();
    final question = _questionController.text;

    final reading = Reading(
      id: readingId,
      deckId: _deckId,
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

    ref.read(readingRepositoryProvider).saveReading(reading);
  }

  void _addOneMore() {
    if (_shuffleResult == null) return;
    if (_currentCardCount >= _shuffleResult!.cards.length) return;

    setState(() => _currentCardCount++);
    _revealedPositions.add(_currentCardCount - 1);

    // DB에 카드 추가
    if (_savedReadingId != null) {
      final newCard = _shuffleResult!.cards[_currentCardCount - 1];
      ref.read(readingRepositoryProvider).addDrawnCard(
            _savedReadingId!,
            DrawnCardInfo(
              cardId: newCard.card.id,
              position: _currentCardCount - 1,
              isReversed: newCard.isReversed,
            ),
            DateTime.now(),
          );
    }
  }

  void _updateQuestion() {
    if (_savedReadingId == null) return;
    final question = _questionController.text;
    // question은 readingQuestionProvider에 세팅하여 다음 뽑기에 반영
    ref.read(readingQuestionProvider.notifier).set(question);
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('즉시 뽑기')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_shuffleResult == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('즉시 뽑기')),
        body: const Center(child: Text('셔플 실행 실패')),
      );
    }

    final drawnCards = _shuffleResult!.cards.take(_currentCardCount).toList();

    // 자동 저장 트리거
    _autoSave();

    final hasMoreCards = _currentCardCount < _shuffleResult!.cards.length;

    final resolvedPositions =
        _spreadType.resolvePositions(drawnCards.length);
    final resolvedGuidances =
        _spreadType.resolveGuidances(drawnCards.length);

    return Scaffold(
      appBar: AppBar(
        title: Text('${_spreadType.displayName} \u2014 즉시'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => context.go('/'),
        ),
      ),
      floatingActionButton: hasMoreCards
          ? FloatingActionButton.extended(
              onPressed: _addOneMore,
              icon: const Icon(Icons.add),
              label: Text(
                  '+1 한 장 더 (${_shuffleResult!.cards.length - _currentCardCount}장 남음)'),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 질문 입력 (접힌 상태 / 펼친 상태) ──
            GestureDetector(
              onTap: () => setState(() => _questionExpanded = !_questionExpanded),
              child: Row(
                children: [
                  Icon(
                    _questionExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '질문이 있으신가요? (선택)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            if (_questionExpanded) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _questionController,
                decoration: InputDecoration(
                  hintText: '이 뽑기에 대한 질문...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                maxLines: 1,
                onSubmitted: (_) => _updateQuestion(),
              ),
            ],
            const SizedBox(height: 16),

            // ── 스프레드 레이아웃 ──
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: SpreadLayout(
                spreadType: _spreadType,
                cards: drawnCards,
                deckId: _deckId,
                revealedPositions: _revealedPositions,
                onCardTap: (_) {}, // 이미 모두 reveal됨
              ),
            ),

            // ── 성찰 카드 ──
            const SizedBox(height: 24),
            Text(
              '성찰의 시간',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < drawnCards.length; i++)
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
                      '${resolvedPositions[i]}: ${drawnCards[i].card.name}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resolvedGuidances[i],
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
}
