import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/mystical_scaffold.dart';
import '../../../deck/presentation/providers/deck_providers.dart';
import '../game/tarot_game.dart';
import '../providers/shuffle_providers.dart';

class ShufflePage extends ConsumerStatefulWidget {
  const ShufflePage({super.key, required this.deckId});
  final String deckId;

  @override
  ConsumerState<ShufflePage> createState() => _ShufflePageState();
}

class _ShufflePageState extends ConsumerState<ShufflePage> {
  TarotGame? _game;
  int _cardCount = 78;

  double _rotateX = 0.65;
  double _rotateY = 0.0;
  double _zoom = 0.001;

  @override
  void initState() {
    super.initState();
    _loadDeckAndCreateGame();
  }

  Future<void> _loadDeckAndCreateGame() async {
    final repo = ref.read(deckRepositoryProvider);
    final deck = await repo.getDeckById(widget.deckId);
    if (!mounted) return;
    setState(() {
      _cardCount = deck?.totalCards ?? 78;
      _game = TarotGame(deckId: widget.deckId, cardCount: _cardCount);
    });
  }

  void _restartGame() {
    setState(() {
      _game = TarotGame(deckId: widget.deckId, cardCount: _cardCount);
      _rotateX = 0.65;
      _rotateY = 0.0;
      _zoom = 0.001;
    });
  }

  Future<void> _goToDrawResult() async {
    ref.read(shuffleStateProvider.notifier).clear();
    ref.read(hapticServiceProvider).mediumImpact();

    try {
      final cards = await ref.read(deckCardsProvider(widget.deckId).future);
      final useCase = ref.read(shuffleDeckUseCaseProvider);
      final strategy = ref.read(shuffleStrategyProvider);
      final result = useCase.execute(cards: cards, strategy: strategy);
      ref.read(shuffleStateProvider.notifier).setResult(result);

      if (!mounted) return;
      context.pushReplacementNamed(
        'draw-result',
        pathParameters: {'deckId': widget.deckId},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('뽑기를 시작할 수 없습니다: $e'),
          backgroundColor: kDeepPurple,
        ),
      );
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkSurface,
      appBar: AppBar(
        title: const Text('셔플', style: TextStyle(color: kTextPrimary, letterSpacing: 0.5)),
        backgroundColor: kDarkSurface.withValues(alpha: 0.9),
        elevation: 0,
        iconTheme: const IconThemeData(color: kTextPrimary),
      ),
      body: Stack(
        children: [
          // ── 게임 뷰 (전체 영역) ──
          Positioned.fill(
            child: GestureDetector(
              onScaleStart: (_) {},
              onScaleUpdate: (details) {
                setState(() {
                  if (details.pointerCount == 1) {
                    _rotateX -= details.focalPointDelta.dy * 0.005;
                    _rotateY += details.focalPointDelta.dx * 0.005;
                  }
                  if (details.pointerCount == 2) {
                    _zoom = (_zoom * (1 / details.scale)).clamp(0.0003, 0.003);
                  }
                });
              },
              onDoubleTap: () => setState(() {
                _rotateX = 0.65;
                _rotateY = 0.0;
                _zoom = 0.001;
              }),
              child: _game == null
                  ? const Center(child: CircularProgressIndicator(color: kGold))
                  : Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, _zoom)
                        ..rotateX(_rotateX)
                        ..rotateY(_rotateY),
                      alignment: Alignment.center,
                      child: GameWidget<TarotGame>(
                        key: ValueKey(_game),
                        game: _game!,
                      ),
                    ),
            ),
          ),

          // ── 좌표 정보 (좌측 하단) ──
          Positioned(
            left: 12,
            bottom: 88,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: kDarkSurface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kGold.withValues(alpha: 0.15), width: 0.5),
              ),
              child: DefaultTextStyle(
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: kTextSecondary,
                  fontSize: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('rX  ${_rotateX.toStringAsFixed(3)}'),
                    Text('rY  ${_rotateY.toStringAsFixed(3)}'),
                    Text('zm  ${_zoom.toStringAsFixed(4)}'),
                  ],
                ),
              ),
            ),
          ),

          // ── 버튼 (하단 중앙) ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ShuffleBtn(
                  onPressed: _restartGame,
                  icon: Icons.replay_rounded,
                  label: '재시작',
                  outlined: true,
                ),
                const SizedBox(width: 12),
                _ShuffleBtn(
                  onPressed: _goToDrawResult,
                  icon: Icons.auto_awesome,
                  label: '뽑기',
                  outlined: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShuffleBtn extends StatelessWidget {
  const _ShuffleBtn({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.outlined,
  });
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: outlined ? kDarkSurface.withValues(alpha: 0.8) : kGold.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: outlined ? kGold.withValues(alpha: 0.45) : Colors.transparent,
            width: 0.8,
          ),
          boxShadow: outlined
              ? []
              : [BoxShadow(color: kGold.withValues(alpha: 0.3), blurRadius: 12, spreadRadius: 2)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: outlined ? kGold : kDarkSurface),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: outlined ? kGold : kDarkSurface,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
