import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../reading/domain/entities/reading.dart';
import '../../../reading/domain/entities/reflective_prompts.dart';
import '../../../reading/domain/entities/spread_type.dart';
import '../../../reading/presentation/providers/reading_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../shuffle/domain/entities/shuffle_result.dart';
import '../../../shuffle/presentation/providers/shuffle_providers.dart';
import '../../../deck/presentation/providers/deck_providers.dart';
import '../../../shuffle/presentation/pages/intention_page.dart';

class AnimatedDrawPage extends ConsumerStatefulWidget {
  const AnimatedDrawPage({super.key});

  @override
  ConsumerState<AnimatedDrawPage> createState() => _AnimatedDrawPageState();
}

class _AnimatedDrawPageState extends ConsumerState<AnimatedDrawPage>
    with TickerProviderStateMixin {
  ShuffleResult? _shuffleResult;
  late int _currentCardCount;
  late SpreadType _spreadType;
  late String _deckId;
  late bool _showFaceUp;
  final Set<int> _revealedPositions = {};
  String? _savedReadingId;
  bool _autoSaved = false;

  // 애니메이션 상태
  bool _shuffleExecuted = false;
  bool _animationComplete = false;
  final List<AnimationController> _slideControllers = [];
  final List<Animation<Offset>> _slideAnimations = [];
  final List<Animation<double>> _fadeAnimations = [];

  // 질문 입력
  final _questionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initSettings();
  }

  void _initSettings() {
    final settings = ref.read(userSettingsProvider).valueOrNull;
    _spreadType = settings?.defaultSpreadType ?? SpreadType.threeCard;
    _currentCardCount = _spreadType == SpreadType.custom
        ? settings?.defaultCardCount ?? 3
        : _spreadType.cardCount;
    _deckId = settings?.selectedDeckId ?? 'rws-standard';
    _showFaceUp = settings?.showFaceUp ?? false;
  }

  Future<void> _startDraw() async {
    // [이전 뽑기 상태 초기화] keepAlive provider 잔류 방지
    ref.read(shuffleStateProvider.notifier).clear();
    ref.read(readingQuestionProvider.notifier).clear();

    // 덱 시드 보장 (홈을 건너뛴 경우)
    final repo = ref.read(deckRepositoryProvider);
    await repo.seedRwsDeck();

    // 셔플 실행
    final cards = await ref.read(deckCardsProvider(_deckId).future);
    final useCase = ref.read(shuffleDeckUseCaseProvider);
    final strategy = ref.read(shuffleStrategyProvider);
    final result = useCase.execute(cards: cards, strategy: strategy);
    ref.read(shuffleStateProvider.notifier).setResult(result);

    // 질문 세팅
    final question = _questionController.text;
    if (question.isNotEmpty) {
      ref.read(readingQuestionProvider.notifier).set(question);
    }

    if (!mounted) return;
    setState(() {
      _shuffleResult = result;
      _shuffleExecuted = true;
    });

    // 애니메이션 컨트롤러 생성
    _setupAnimations();
    unawaited(_playAnimations());
  }

  void _setupAnimations() {
    for (var i = 0; i < _currentCardCount; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );

      final slide = Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));

      final fade = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeIn));

      _slideControllers.add(controller);
      _slideAnimations.add(slide);
      _fadeAnimations.add(fade);
    }
  }

  Future<void> _playAnimations() async {
    // 순차적 stagger 애니메이션
    for (var i = 0; i < _currentCardCount; i++) {
      if (!mounted) return;
      unawaited(_slideControllers[i].forward());
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    // 마지막 카드 슬라이드 완료 대기
    if (_slideControllers.isNotEmpty) {
      await _slideControllers.last.forward();
    }

    // 카드 플립 (showFaceUp이 아닌 경우에만 지연 후 순차 reveal)
    if (!_showFaceUp) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      for (var i = 0; i < _currentCardCount; i++) {
        if (!mounted) return;
        setState(() => _revealedPositions.add(i));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    } else {
      // showFaceUp이면 슬라이드 완료 후 즉시 전부 reveal
      if (mounted) {
        setState(() {
          for (var i = 0; i < _currentCardCount; i++) {
            _revealedPositions.add(i);
          }
        });
      }
    }

    if (mounted) {
      setState(() => _animationComplete = true);
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

  @override
  void dispose() {
    for (final c in _slideControllers) {
      c.dispose();
    }
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 애니메이션 완료 + 전체 공개 후 자동 저장
    final allRevealed = _revealedPositions.length >= _currentCardCount;
    if (allRevealed && _shuffleExecuted) _autoSave();

    // ── 셔플 전: 질문 입력 화면 ──
    if (!_shuffleExecuted) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('카드 뽑기'),
          leading: IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/'),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.self_improvement,
                  color: theme.colorScheme.primary, size: 48),
              const SizedBox(height: 16),
              Text(
                '마음속 질문을 떠올려보세요.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _questionController,
                decoration: InputDecoration(
                  hintText: '질문이나 의도를 적어보세요 (선택)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Text(
                '질문 없이 진행해도 괜찮습니다.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: _startDraw,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('카드 뽑기',
                      style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: () {
                    _questionController.clear();
                    _startDraw();
                  },
                  child: const Text('질문 없이 바로 뽑기'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── 셔플 후: 애니메이션 + 결과 ──
    if (_shuffleResult == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('카드 뽑기')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final drawnCards = _shuffleResult!.cards.take(_currentCardCount).toList();
    final hasMoreCards = _currentCardCount < _shuffleResult!.cards.length;

    final resolvedPositions =
        _spreadType.resolvePositions(drawnCards.length);
    final resolvedGuidances =
        _spreadType.resolveGuidances(drawnCards.length);

    return Scaffold(
      appBar: AppBar(
        title: Text('${_spreadType.displayName} \u2014 연출'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => context.go('/'),
        ),
      ),
      floatingActionButton: _animationComplete && hasMoreCards
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
            // 질문 표시
            if (_questionController.text.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"${_questionController.text}"',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── 애니메이션 카드 레이아웃 ──
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: _buildAnimatedCards(drawnCards),
            ),

            // 성찰 카드 (애니메이션 완료 후)
            if (_animationComplete) ...[
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

  /// 슬라이드+페이드 애니메이션으로 카드를 순차 표시
  Widget _buildAnimatedCards(List<ShuffledCard> drawnCards) {
    if (_slideControllers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // 3장 이하: 가로 나열, 4장 이상: 2열 그리드
    if (drawnCards.length <= 3) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(drawnCards.length, (i) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _animatedCard(i, drawnCards[i]),
            ),
          );
        }),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.65,
      ),
      itemCount: drawnCards.length,
      itemBuilder: (context, i) => _animatedCard(i, drawnCards[i]),
    );
  }

  Widget _animatedCard(int index, ShuffledCard card) {
    if (index >= _slideControllers.length) {
      // "+1"로 추가된 카드 — 애니메이션 없이 즉시 표시
      return _buildCardWidget(index, card);
    }

    return SlideTransition(
      position: _slideAnimations[index],
      child: FadeTransition(
        opacity: _fadeAnimations[index],
        child: _buildCardWidget(index, card),
      ),
    );
  }

  Widget _buildCardWidget(int index, ShuffledCard card) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _spreadType.resolvePositions(_currentCardCount)[index],
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Flexible(
          child: AspectRatio(
            aspectRatio: 2.5 / 3.5,
            child: _revealedPositions.contains(index)
                ? _buildFrontCard(card)
                : _buildBackCard(),
          ),
        ),
        if (_revealedPositions.contains(index) && card.isReversed)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '역방향',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBackCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        'assets/images/$_deckId/card_back.webp',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFF2D1B4E),
          child: Center(
            child: Icon(Icons.auto_awesome,
                color: Theme.of(context).colorScheme.primary, size: 32),
          ),
        ),
      ),
    );
  }

  Widget _buildFrontCard(ShuffledCard card) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            card.card.imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF1A1028),
              child: Center(
                child: Text(
                  card.card.name,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Text(
                card.card.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
