import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/dev_tuner/tunable_var.dart';
import '../../../../core/dev_tuner/tuner_registry.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../shuffle/domain/entities/shuffle_result.dart';
import '../../../shuffle/presentation/pages/intention_page.dart';
import '../../../shuffle/presentation/providers/shuffle_providers.dart';
import '../../domain/entities/reading.dart';
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
  late SpreadType _spreadType;
  late int _currentCardCount;
  final Set<int> _revealedPositions = {};
  String? _savedReadingId;
  bool _autoSaved = false;

  @override
  void initState() {
    super.initState();
    _spreadType = widget.spreadType;
    // EV-006-A1 대응: custom일 때 cardCount 0 sentinel 대신 UserSettings의 defaultCardCount 사용
    // named 스프레드는 정적 cardCount 사용
    _currentCardCount = _spreadType == SpreadType.custom
        ? ref.read(userSettingsProvider).valueOrNull?.defaultCardCount ?? 3
        : _spreadType.cardCount;
  }

  // ── 자동 저장 (allRevealed 시 1회 실행) ──
  void _autoSave(List<ShuffledCard> drawnCards, String question) {
    if (_autoSaved) return;
    _autoSaved = true;

    final readingId = const Uuid().v4();
    _savedReadingId = readingId;

    final reading = Reading(
      id: readingId,
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

    ref.read(readingRepositoryProvider).saveReading(reading);
  }

  // ── "+1 한 장 더" ──
  void _addOneMore(ShuffleResult shuffleResult) {
    if (_currentCardCount >= shuffleResult.cards.length) return;

    setState(() => _currentCardCount++);

    // 새 카드가 showFaceUp이면 즉시 reveal
    final showFaceUp =
        ref.read(userSettingsProvider).valueOrNull?.showFaceUp ?? false;
    if (showFaceUp) {
      _revealedPositions.add(_currentCardCount - 1);
    }

    // 이미 자동 저장된 Reading에 카드 추가
    if (_savedReadingId != null) {
      final newCard = shuffleResult.cards[_currentCardCount - 1];
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

  @override
  Widget build(BuildContext context) {
    final shuffleResult = ref.watch(shuffleStateProvider);
    final question = ref.watch(readingQuestionProvider);
    final showFaceUp =
        ref.watch(userSettingsProvider).valueOrNull?.showFaceUp ?? false;
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

    final drawnCards = shuffleResult.cards.take(_currentCardCount).toList();

    // showFaceUp이면 초기 전부 reveal
    if (showFaceUp && _revealedPositions.length < _currentCardCount) {
      for (var i = 0; i < _currentCardCount; i++) {
        _revealedPositions.add(i);
      }
    }

    final allRevealed = _revealedPositions.length >= _currentCardCount;

    // 자동 저장 트리거
    if (allRevealed) _autoSave(drawnCards, question);

    final hasMoreCards = _currentCardCount < shuffleResult.cards.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_spreadType.displayName),
        // 저장 버튼 제거됨 — 자동 저장
      ),
      // "+1 한 장 더" FAB
      floatingActionButton: allRevealed && hasMoreCards
          ? FloatingActionButton.extended(
              onPressed: () => _addOneMore(shuffleResult),
              icon: const Icon(Icons.add),
              label: Text('+1 한 장 더 (${shuffleResult.cards.length - _currentCardCount}장 남음)'),
            )
          : null,
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
                deckId: widget.deckId,
                revealedPositions: _revealedPositions,
                cardAspectRatio: ref.watch(cardAspectRatioProvider),
                onCardTap: (position) {
                  setState(() => _revealedPositions.add(position));
                },
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
