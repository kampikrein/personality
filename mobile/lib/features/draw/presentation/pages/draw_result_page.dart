import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../reading/domain/entities/reading.dart';
import '../../../reading/domain/entities/spread_type.dart';
import '../../../reading/presentation/providers/reading_providers.dart';
import '../../../reading/presentation/widgets/spread_layout.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../shuffle/domain/entities/shuffle_config.dart';
import '../../../shuffle/domain/entities/shuffle_result.dart';
import '../../../shuffle/presentation/providers/shuffle_providers.dart';
import '../../../deck/presentation/providers/deck_providers.dart';
import '../../../shuffle/presentation/pages/intention_page.dart';

/// Lv1~Lv4 공용 뽑기 결과 페이지.
///
/// Cycle 1에서는 리네임만 수행하여 기존 Lv1 결과 페이지의 행동을
/// 그대로 유지한다. 업스트림(AnimatedDrawPage, ShufflePage)과의
/// 상태 인계 및 `shuffleStateProvider` 초기값 분기는 Cycle 2에서
/// 도입된다.
///
/// 참조: docs/03_tarot_shuffle/065_Brief_unified_result_page.md (MA-1)
class DrawResultPage extends ConsumerStatefulWidget {
  const DrawResultPage({super.key});

  @override
  ConsumerState<DrawResultPage> createState() => _DrawResultPageState();
}

class _DrawResultPageState extends ConsumerState<DrawResultPage> {
  ShuffleResult? _shuffleResult;
  late int _currentCardCount;
  late SpreadType _spreadType;
  late String _deckId;
  late bool _allowReversed;
  late bool _showCardName;
  final Set<int> _revealedPositions = {};
  String? _savedReadingId;
  bool _autoSaved = false;
  bool _loading = true;

  // MA-9: shuffleStateProvider에 업스트림 결과가 있으면 재사용.
  // initState에서 단일 지점으로 1회 판단된 뒤 _executeDraw가 소비.
  bool _reuseUpstreamResult = false;

  // 질문 입력 관련
  final _questionController = TextEditingController();
  bool _questionExpanded = false;

  @override
  void initState() {
    super.initState();
    _initSettings();

    // ── MA-9: initState 단일 지점 분기 ──
    // shuffleStateProvider가 이미 결과를 가지고 있으면 재사용 (Lv2/Lv4 업스트림),
    // null이면 자체 셔플 (Lv1 직접 진입).
    final existing = ref.read(shuffleStateProvider);
    _reuseUpstreamResult = existing != null;

    Future.microtask(() => _executeDraw());
  }

  void _initSettings() {
    final settings = ref.read(userSettingsProvider).valueOrNull;
    _spreadType = settings?.defaultSpreadType ?? SpreadType.custom;
    _currentCardCount = _spreadType == SpreadType.custom
        ? settings?.defaultCardCount ?? 3
        : _spreadType.cardCount;
    _deckId = settings?.selectedDeckId ?? 'rws-standard';
    _allowReversed = settings?.allowReversed ?? true;
    _showCardName = settings?.showCardName ?? true;
  }

  Future<void> _executeDraw() async {
    try {
      if (_reuseUpstreamResult) {
        // ── 재사용 경로: clear 금지. 업스트림 객체 identity 보존 ──
        final upstream = ref.read(shuffleStateProvider);
        if (upstream != null) {
          if (!mounted) return;
          setState(() {
            _shuffleResult = upstream;
            _loading = false;
            // 업스트림 경로도 모든 카드 즉시 reveal (Lv2/Lv4에서 이미 공개된 상태)
            for (var i = 0; i < _currentCardCount; i++) {
              _revealedPositions.add(i);
            }
          });
          _triggerAutoSave();
          return;
        }
        // 이론상 도달 불가 (initState에서 non-null 확정). 방어적 fallback.
        _reuseUpstreamResult = false;
      }

      // ── 자체 셔플 경로 (Lv1 직접 진입) ──
      // [이전 뽑기 상태 초기화] keepAlive provider 잔류 방지
      ref.read(shuffleStateProvider.notifier).clear();
      ref.read(readingQuestionProvider.notifier).clear();

      // 덱 시드 보장 (홈을 건너뛴 경우)
      final repo = ref.read(deckRepositoryProvider);
      await repo.seedAllDecks();

      final cards = await ref.read(deckCardsProvider(_deckId).future);
      final useCase = ref.read(shuffleDeckUseCaseProvider);
      final strategy = ref.read(shuffleStrategyProvider);
      final result = useCase.execute(
        cards: cards,
        strategy: strategy,
        config: ShuffleConfig(useReversals: _allowReversed),
      );
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
      _triggerAutoSave();
    } catch (e, st) {
      debugPrint('_executeDraw error: $e\n$st');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /// `_executeDraw` 성공 경로에서 호출. repository provider 미override
  /// 환경(테스트 등)에서 throw되더라도 페이지 렌더에는 영향이 없도록
  /// 예외를 삼킨다 (자동 저장은 best-effort 기능).
  void _triggerAutoSave() {
    try {
      _autoSave();
    } catch (e, st) {
      debugPrint('_autoSave skipped: $e\n$st');
    }
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
    final hasMoreCards = _currentCardCount < _shuffleResult!.cards.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_spreadType.displayName} \u2014 즉시'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Column(
        children: [
          // ── 질문 입력 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: GestureDetector(
              onTap: () =>
                  setState(() => _questionExpanded = !_questionExpanded),
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
          ),
          if (_questionExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
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
            ),

          // ── 스프레드 레이아웃 (남은 공간 전체 사용) ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SpreadLayout(
                spreadType: _spreadType,
                cards: drawnCards,
                deckId: _deckId,
                revealedPositions: _revealedPositions,
                showCardName: _showCardName,
                cardAspectRatio: ref.watch(cardAspectRatioProvider),
                onCardTap: (_) {},
              ),
            ),
          ),

          // ── 하단 버튼 바 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              children: [
                // 다시
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      setState(() {
                        _shuffleResult = null;
                        _revealedPositions.clear();
                        _savedReadingId = null;
                        _autoSaved = false;
                        _loading = true;
                        // "다시"는 강제 재셔플 — 업스트림 재사용 flag 리셋
                        _reuseUpstreamResult = false;
                      });
                      _executeDraw();
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('다시'),
                  ),
                ),
                const SizedBox(width: 8),
                // +1
                Expanded(
                  child: FilledButton.icon(
                    onPressed: hasMoreCards ? _addOneMore : null,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text('+ ${_currentCardCount}장'),
                  ),
                ),
                const SizedBox(width: 8),
                // 리셋
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.home, size: 18),
                    label: const Text('리셋'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
