import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/deck_providers.dart';

class DeckSelectionPage extends ConsumerWidget {
  const DeckSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(watchDecksProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('덱 선택')),
      body: decksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('오류: $err')),
        data: (decks) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: decks.length,
          itemBuilder: (context, index) {
            final deck = decks[index];
            return Card(
              child: ListTile(
                title: Text(deck.name, style: theme.textTheme.bodyLarge),
                subtitle: Text('${deck.totalCards}장'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ref.read(selectedDeckProvider.notifier).select(deck);
                  context.pushNamed(
                    'intention',
                    pathParameters: {'deckId': deck.id},
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
