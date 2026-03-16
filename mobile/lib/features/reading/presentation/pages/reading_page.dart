import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../shuffle/domain/entities/shuffle_result.dart';
import '../../../shuffle/presentation/providers/shuffle_providers.dart';
import '../../domain/entities/reading.dart';
import '../../domain/entities/spread_type.dart';
import '../providers/reading_providers.dart';
import '../widgets/spread_layout.dart';

class ReadingPage extends ConsumerStatefulWidget {
  const ReadingPage({super.key, required this.deckId});
  final String deckId;

  @override
  ConsumerState<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends ConsumerState<ReadingPage> {
  final _spreadType = SpreadType.single;
  final Set<int> _revealedPositions = {};

  @override
  Widget build(BuildContext context) {
    final shuffleResult = ref.watch(shuffleStateProvider);

    if (shuffleResult == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('리딩')),
        body: const Center(child: Text('셔플을 먼저 진행해주세요.')),
      );
    }

    final drawnCards =
        shuffleResult.cards.take(_spreadType.cardCount).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_spreadType.displayName),
        actions: [
          if (_revealedPositions.length == _spreadType.cardCount)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () => _saveReading(drawnCards),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SpreadLayout(
                spreadType: _spreadType,
                cards: drawnCards,
                revealedPositions: _revealedPositions,
                onCardTap: (position) {
                  setState(() => _revealedPositions.add(position));
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              '타로는 자기 성찰의 도구입니다. 결과에 과도한 의미를 부여하지 마세요.\n'
              '심리적 어려움이 있다면 정신건강 위기상담전화 1577-0199',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveReading(List<ShuffledCard> drawnCards) async {
    final reading = Reading(
      id: const Uuid().v4(),
      deckId: widget.deckId,
      spreadType: _spreadType,
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
    if (mounted) context.go('/');
  }
}
