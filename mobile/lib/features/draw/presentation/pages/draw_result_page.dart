import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/widgets/mystical_scaffold.dart';
import '../../../reading/domain/entities/reading.dart';
import '../../../reading/domain/entities/layout_type.dart';
import '../../../reading/presentation/providers/reading_providers.dart';
import '../../../reading/presentation/widgets/spread_layout.dart';
import '../../../settings/domain/entities/intent_placement.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../shuffle/domain/entities/shuffle_config.dart';
import '../../../shuffle/domain/entities/shuffle_result.dart';
import '../../../shuffle/presentation/pages/intention_page.dart';
import '../../../shuffle/presentation/providers/shuffle_providers.dart';
import '../../../deck/presentation/providers/deck_providers.dart';

/// Lv1~Lv4 공용 뽑기 결과 페이지.
class DrawResultPage extends ConsumerStatefulWidget {
  const DrawResultPage({super.key});

  @override
  ConsumerState<DrawResultPage> createState() => _DrawResultPageState();
}

class _DrawResultPageState extends ConsumerState<DrawResultPage> {
  ShuffleResult? _shuffleResult;
  late int _currentCardCount;
  late LayoutType _layoutType;
  late String _deckId;
  late bool _allowReversed;
  late bool _showCardName;
  final Set<int> _revealedPositions = {};
  String? _savedReadingId;
  bool _autoSaved = false;
  bool _loading = true;
  bool _reuseUpstreamResult = false;

  final _questionController = TextEditingController();
  bool _questionExpanded = false;

  @override
  void initState() {
    super.initState();
    _initSettings();
    final existing = ref.read(shuffleStateProvider);
    _reuseUpstreamResult = existing != null;
    Future.microtask(() => _executeDraw());
  }

  void _initSettings() {
    final settings = ref.read(userSettingsProvider).valueOrNull;
    _layoutType = settings?.defaultLayoutType ?? LayoutType.linear;
    _currentCardCount =
        settings?.defaultCardCount ?? _layoutType.defaultCardCount;
    _deckId = settings?.selectedDeckId ?? 'rws-standard';
    _allowReversed = settings?.allowReversed ?? true;
    _showCardName = settings?.showCardName ?? true;
  }

  Future<void> _executeDraw() async {
    try {
      if (_reuseUpstreamResult) {
        final upstream = ref.read(shuffleStateProvider);
        if (upstream != null) {
          if (!mounted) return;
          setState(() {
            _shuffleResult = upstream;
            _loading = false;
            for (var i = 0; i < _currentCardCount; i++) _revealedPositions.add(i);
          });
          _triggerAutoSave();
          return;
        }
        _reuseUpstreamResult = false;
      }

      ref.read(shuffleStateProvider.notifier).clear();
      ref.read(readingQuestionProvider.notifier).clear();

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
        for (var i = 0; i < _currentCardCount; i++) _revealedPositions.add(i);
      });
      _triggerAutoSave();
    } catch (e, st) {
      debugPrint('_executeDraw error: $e\n$st');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _triggerAutoSave() {
    try { _autoSave(); } catch (e, st) { debugPrint('_autoSave skipped: $e\n$st'); }
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
      spreadType: _layoutType,
      question: question.isNotEmpty ? question : null,
      drawnCards: List.generate(drawnCards.length, (i) => DrawnCardInfo(
        cardId: drawnCards[i].card.id, position: i, isReversed: drawnCards[i].isReversed,
      )),
      createdAt: DateTime.now(),
    );
    ref.read(readingRepositoryProvider).saveReading(reading);
  }

  void _updateQuestion() {
    if (_savedReadingId == null) return;
    final text = _questionController.text;
    ref.read(readingRepositoryProvider).updateQuestion(
      _savedReadingId!,
      text.isEmpty ? null : text,
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const MysticalScaffold(
        title: '즉시 뽑기',
        body: Center(child: CircularProgressIndicator(color: kGold)),
      );
    }

    if (_shuffleResult == null) {
      return const MysticalScaffold(
        title: '즉시 뽑기',
        body: Center(child: Text('셔플 실행 실패', style: TextStyle(color: kTextSecondary))),
      );
    }

    final drawnCards = _shuffleResult!.cards.take(_currentCardCount).toList();
    final intentPlacement = ref.watch(userSettingsProvider).valueOrNull?.intentPlacement
        ?? IntentPlacement.beforeShuffle;

    return MysticalScaffold(
      appBar: AppBar(
        title: Text('${_layoutType.displayName} \u2014 즉시',
            style: const TextStyle(color: kTextPrimary, letterSpacing: 0.3)),
        backgroundColor: kDarkSurface.withValues(alpha: 0.85),
        elevation: 0,
        iconTheme: const IconThemeData(color: kTextPrimary),
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Column(
        children: [
          // ── 질문 입력 토글 (afterDraw 모드 전용) ──
          if (intentPlacement == IntentPlacement.afterDraw) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: GestureDetector(
                onTap: () => setState(() => _questionExpanded = !_questionExpanded),
                child: Row(
                  children: [
                    Icon(
                      _questionExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: kGold.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '질문이 있으신가요? (선택)',
                      style: TextStyle(color: kTextSecondary.withValues(alpha: 0.8), fontSize: 12),
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
                  decoration: mysticalInputDecoration(hintText: '이 뽑기에 대한 질문...', isDense: true),
                  style: const TextStyle(color: kTextPrimary, fontSize: 13),
                  maxLines: 1,
                  onSubmitted: (_) => _updateQuestion(),
                ),
              ),
          ],

          // ── 스프레드 레이아웃 ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SpreadLayout(
                layoutType: _layoutType,
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
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: kDarkSurface.withValues(alpha: 0.7),
              border: Border(top: BorderSide(color: kGold.withValues(alpha: 0.15), width: 0.7)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ResultBtn(
                    onPressed: () {
                      setState(() {
                        _shuffleResult = null;
                        _revealedPositions.clear();
                        _savedReadingId = null;
                        _autoSaved = false;
                        _loading = true;
                        _reuseUpstreamResult = false;
                      });
                      _executeDraw();
                    },
                    icon: Icons.refresh_rounded,
                    label: '다시',
                    outlined: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ResultBtn(
                    onPressed: () => context.go('/'),
                    icon: Icons.home_outlined,
                    label: '홈',
                    outlined: true,
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

class _ResultBtn extends StatelessWidget {
  const _ResultBtn({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.outlined,
  });
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: outlined
              ? Colors.transparent
              : (disabled ? kDeepPurple.withValues(alpha: 0.4) : kGold.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: disabled
                ? kSoftPurple.withValues(alpha: 0.2)
                : (outlined ? kGold.withValues(alpha: 0.4) : kGold.withValues(alpha: 0.6)),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15,
                color: disabled ? kTextSecondary.withValues(alpha: 0.4) : (outlined ? kGold : kGold)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: disabled ? kTextSecondary.withValues(alpha: 0.4) : (outlined ? kGold : kGold),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
