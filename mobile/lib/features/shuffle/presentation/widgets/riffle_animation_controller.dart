import 'dart:math' as math;

import 'package:flutter/material.dart';

class CardPosition {
  const CardPosition({this.dx = 0, this.dy = 0, this.rotation = 0});
  final double dx;
  final double dy;
  final double rotation;
}

class RiffleAnimationState extends ChangeNotifier {
  RiffleAnimationState({required TickerProvider vsync}) : _vsync = vsync;

  final TickerProvider _vsync;
  AnimationController? _controller;
  List<CardPosition> _cardPositions = [];
  int _cardCount = 0;

  List<CardPosition> get cardPositions => _cardPositions;

  Future<void> playRiffle({
    required int cardCount,
    required int shuffleCount,
  }) async {
    _cardCount = cardCount;

    for (var round = 0; round < shuffleCount; round++) {
      await _playOneRiffle(round);
    }

    await _gatherCards();
  }

  Future<void> _playOneRiffle(int round) async {
    _controller?.dispose();
    _controller = AnimationController(
      vsync: _vsync,
      duration: const Duration(milliseconds: 800),
    );

    final curved = CurvedAnimation(parent: _controller!, curve: Curves.easeInOut);
    curved.addListener(() {
      final t = curved.value;
      _cardPositions = _generateRifflePositions(t, round);
      notifyListeners();
    });

    await _controller!.forward();
  }

  List<CardPosition> _generateRifflePositions(double t, int round) {
    final positions = <CardPosition>[];
    final mid = _cardCount ~/ 2;
    final rng = math.Random(round);

    for (var i = 0; i < _cardCount; i++) {
      final isLeft = i < mid;
      final normalizedIndex =
          isLeft ? i / mid : (i - mid) / (_cardCount - mid);

      double dx, dy, rotation;

      if (t < 0.3) {
        final spread = t / 0.3;
        dx = isLeft ? -0.15 * spread : 0.15 * spread;
        dy = normalizedIndex * 0.01 - 0.005;
        rotation = 0;
      } else if (t < 0.8) {
        final interleave = (t - 0.3) / 0.5;
        final dropProgress = (interleave * _cardCount - i).clamp(0.0, 1.0);

        dx = isLeft
            ? -0.15 * (1 - dropProgress)
            : 0.15 * (1 - dropProgress);
        dy = (normalizedIndex * 0.3 - 0.15) * dropProgress;
        rotation = (rng.nextDouble() - 0.5) * 0.05 * dropProgress;
      } else {
        final gather = (t - 0.8) / 0.2;
        dx = 0;
        dy = normalizedIndex * 0.01 * (1 - gather);
        rotation = 0;
      }

      positions.add(CardPosition(dx: dx, dy: dy, rotation: rotation));
    }

    return positions;
  }

  Future<void> _gatherCards() async {
    _controller?.dispose();
    _controller = AnimationController(
      vsync: _vsync,
      duration: const Duration(milliseconds: 400),
    );

    final startPositions = List<CardPosition>.from(_cardPositions);

    final curved = CurvedAnimation(parent: _controller!, curve: Curves.easeOut);
    curved.addListener(() {
      final t = curved.value;
      _cardPositions = List.generate(
        startPositions.length,
        (i) => CardPosition(
          dx: startPositions[i].dx * (1 - t),
          dy: startPositions[i].dy * (1 - t),
          rotation: startPositions[i].rotation * (1 - t),
        ),
      );
      notifyListeners();
    });

    await _controller!.forward();
    _cardPositions = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
