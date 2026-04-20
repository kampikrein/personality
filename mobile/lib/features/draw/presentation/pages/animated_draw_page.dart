import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/mystical_scaffold.dart';
import '../../../deck/presentation/providers/deck_providers.dart';
import '../../../reading/domain/entities/layout_type.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../shuffle/domain/entities/shuffle_config.dart';
import '../../../shuffle/domain/entities/shuffle_result.dart';
import '../../../shuffle/presentation/pages/intention_page.dart';
import '../../../shuffle/presentation/providers/shuffle_providers.dart';

/// 연출 단계(Lv2) 페이지.
class AnimatedDrawPage extends ConsumerStatefulWidget {
  const AnimatedDrawPage({super.key});

  @override
  ConsumerState<AnimatedDrawPage> createState() => _AnimatedDrawPageState();
}

class _AnimatedDrawPageState extends ConsumerState<AnimatedDrawPage>
    with TickerProviderStateMixin {
  ShuffleResult? _shuffleResult;
  late int _currentCardCount;
  late LayoutType _layoutType;
  late String _deckId;
  late bool _showFaceUp;
  late bool _allowReversed;
  late bool _showCardName;
  final Set<int> _revealedPositions = {};

  bool _shuffleExecuted = false;
  bool _animationComplete = false;
  bool _navigatedToResult = false;
  final List<AnimationController> _slideControllers = [];
  final List<Animation<Offset>> _slideAnimations = [];
  final List<Animation<double>> _fadeAnimations = [];

  final _questionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initSettings();
  }

  void _initSettings() {
    final settings = ref.read(userSettingsProvider).valueOrNull;
    _layoutType = settings?.defaultLayoutType ?? LayoutType.linear;
    _currentCardCount =
        settings?.defaultCardCount ?? _layoutType.defaultCardCount;
    _deckId = settings?.selectedDeckId ?? 'rws-standard';
    _showFaceUp = settings?.showFaceUp ?? false;
    _allowReversed = settings?.allowReversed ?? true;
    _showCardName = settings?.showCardName ?? true;
  }

  Future<void> _startDraw() async {
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

    final question = _questionController.text;
    if (question.isNotEmpty) {
      ref.read(readingQuestionProvider.notifier).set(question);
    }

    if (!mounted) return;
    setState(() {
      _shuffleResult = result;
      _shuffleExecuted = true;
    });

    _setupAnimations();
    unawaited(_playAnimations());
  }

  void _setupAnimations() {
    for (var i = 0; i < _currentCardCount; i++) {
      final controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
      final slide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
          .animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));
      final fade = Tween<double>(begin: 0.0, end: 1.0)
          .animate(CurvedAnimation(parent: controller, curve: Curves.easeIn));
      _slideControllers.add(controller);
      _slideAnimations.add(slide);
      _fadeAnimations.add(fade);
    }
  }

  Future<void> _playAnimations() async {
    for (var i = 0; i < _currentCardCount; i++) {
      if (!mounted) return;
      unawaited(_slideControllers[i].forward());
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    if (_slideControllers.isNotEmpty) {
      await _slideControllers.last.forward();
    }
    if (_showFaceUp && mounted) {
      setState(() {
        for (var i = 0; i < _currentCardCount; i++) _revealedPositions.add(i);
        _animationComplete = true;
      });
      _maybeGoToResult();
    } else if (mounted) {
      setState(() => _animationComplete = true);
    }
  }

  void _maybeGoToResult() {
    if (_navigatedToResult) return;
    if (!_animationComplete) return;
    if (_revealedPositions.length < _currentCardCount) return;
    if (!mounted) return;
    _navigatedToResult = true;
    context.pushReplacementNamed('draw-result');
  }

  @override
  void dispose() {
    for (final c in _slideControllers) c.dispose();
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── 셔플 전: 질문 입력 화면 ──
    if (!_shuffleExecuted) {
      return MysticalScaffold(
        appBar: AppBar(
          title: const Text('카드 뽑기', style: TextStyle(color: kTextPrimary, letterSpacing: 0.5)),
          backgroundColor: kDarkSurface.withValues(alpha: 0.85),
          elevation: 0,
          iconTheme: const IconThemeData(color: kTextPrimary),
          leading: IconButton(
            icon: const Icon(Icons.home_outlined),
            onPressed: () => context.go('/'),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kDeepPurple.withValues(alpha: 0.8),
                    border: Border.all(color: kGold.withValues(alpha: 0.4), width: 0.8),
                    boxShadow: [BoxShadow(color: kGold.withValues(alpha: 0.15), blurRadius: 16, spreadRadius: 3)],
                  ),
                  child: const Icon(Icons.self_improvement, color: kGold, size: 34),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '마음속 질문을 떠올려보세요.',
                style: TextStyle(color: kTextPrimary, fontSize: 16, letterSpacing: 0.3),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              MysticalCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GoldSectionTitle('질문 / 의도', icon: Icons.edit_outlined),
                    TextField(
                      controller: _questionController,
                      decoration: mysticalInputDecoration(hintText: '질문이나 의도를 적어보세요 (선택)'),
                      style: const TextStyle(color: kTextPrimary, fontSize: 14),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '질문 없이 진행해도 괜찮습니다.',
                style: TextStyle(color: kTextSecondary.withValues(alpha: 0.7), fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGold, foregroundColor: kDarkSurface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _startDraw,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('카드 뽑기', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () { _questionController.clear(); _startDraw(); },
                child: const Text('질문 없이 바로 뽑기', style: TextStyle(color: kTextSecondary, fontSize: 13)),
              ),
            ],
          ),
        ),
      );
    }

    // ── 셔플 후: 연출 애니메이션 ──
    if (_shuffleResult == null) {
      return const MysticalScaffold(
        title: '카드 뽑기',
        body: Center(child: CircularProgressIndicator(color: kGold)),
      );
    }

    final drawnCards = _shuffleResult!.cards.take(_currentCardCount).toList();

    return MysticalScaffold(
      appBar: AppBar(
        title: Text('${_layoutType.displayName} \u2014 연출',
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
          if (_questionController.text.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: kDeepPurple.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kGold.withValues(alpha: 0.2), width: 0.7),
              ),
              child: Row(
                children: [
                  Icon(Icons.format_quote, color: kGold.withValues(alpha: 0.5), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _questionController.text,
                      style: const TextStyle(color: kTextPrimary, fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _buildAnimatedCards(drawnCards),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCards(List<ShuffledCard> drawnCards) {
    if (_slideControllers.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: kGold));
    }
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
        childAspectRatio: ref.watch(cardAspectRatioProvider) * 0.85,
      ),
      itemCount: drawnCards.length,
      itemBuilder: (context, i) => _animatedCard(i, drawnCards[i]),
    );
  }

  Widget _animatedCard(int index, ShuffledCard card) {
    if (index >= _slideControllers.length) return _buildCardWidget(index, card);
    return SlideTransition(
      position: _slideAnimations[index],
      child: FadeTransition(opacity: _fadeAnimations[index], child: _buildCardWidget(index, card)),
    );
  }

  void _revealCard(int index) {
    if (_revealedPositions.contains(index)) return;
    setState(() => _revealedPositions.add(index));
    _maybeGoToResult();
  }

  Widget _buildCardWidget(int index, ShuffledCard card) {
    final isRevealed = _revealedPositions.contains(index);
    return GestureDetector(
      onTap: isRevealed ? null : () => _revealCard(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showCardName && isRevealed && card.isReversed)
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationZ(math.pi),
              child: _buildCardName(card),
            ),
          Flexible(
            child: AspectRatio(
              aspectRatio: ref.watch(cardAspectRatioProvider),
              child: isRevealed ? _buildFrontCard(card) : _buildBackCard(),
            ),
          ),
          if (_showCardName && isRevealed && !card.isReversed) _buildCardName(card),
        ],
      ),
    );
  }

  Widget _buildCardName(ShuffledCard card) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        card.card.name,
        style: const TextStyle(color: kTextSecondary, fontSize: 10, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildBackCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.asset(
        'assets/images/$_deckId/card_back.webp',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          decoration: BoxDecoration(
            color: kDeepPurple,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: kGold.withValues(alpha: 0.3), width: 0.7),
          ),
          child: const Center(child: Icon(Icons.auto_awesome, color: kGold, size: 24)),
        ),
      ),
    );
  }

  Widget _buildFrontCard(ShuffledCard card) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationZ(card.isReversed ? math.pi : 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.asset(
          card.card.imagePath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: kDeepPurple,
            child: Center(
              child: Text(card.card.name,
                  style: const TextStyle(color: kGold, fontWeight: FontWeight.bold, fontSize: 11),
                  textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }
}
