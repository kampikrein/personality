import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  // 인터랙티브 카메라 제어
  double _rotateX = 0.65;   // 상하 기울기 (라디안) — 스크린샷 기준 기본 앵글
  double _rotateY = 0.0;    // 좌우 회전 (라디안)
  double _zoom = 0.001;     // 원근 강도

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

  void _goToReading() {
    ref.read(hapticServiceProvider).mediumImpact();
    context.pushNamed(
      'reading',
      pathParameters: {'deckId': widget.deckId},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('셔플')),
      body: Stack(
        children: [
          // ── 게임 뷰 (전체 영역) ──────────────────────────────────────────
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
                    _zoom = (_zoom * (1 / details.scale))
                        .clamp(0.0003, 0.003);
                  }
                });
              },
              onDoubleTap: () {
                setState(() {
                  _rotateX = 0.65;
                  _rotateY = 0.0;
                  _zoom = 0.001;
                });
              },
              child: _game == null
                  ? const Center(child: CircularProgressIndicator())
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

          // ── 좌표 정보 (좌측 하단) ──────────────────────────────────────────
          Positioned(
            left: 12,
            bottom: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DefaultTextStyle(
                style: theme.textTheme.bodySmall!.copyWith(
                  fontFamily: 'monospace',
                  color: Colors.white70,
                  fontSize: 11,
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

          // ── 버튼 (하단 중앙) ───────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _restartGame,
                  icon: const Icon(Icons.replay, size: 18),
                  label: const Text('재시작'),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _goToReading,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('뽑기'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
