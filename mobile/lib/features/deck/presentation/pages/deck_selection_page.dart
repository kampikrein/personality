import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/dev_tuner/tunable_var.dart';
import '../../../../core/dev_tuner/tuner_registry.dart';
import '../providers/deck_providers.dart';

// ── Dev Tuner 변수 ──
final deckListPaddingProvider = StateProvider<double>((ref) => 16);

class DeckSelectionPage extends ConsumerWidget {
  const DeckSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(watchDecksProvider);
    final theme = Theme.of(context);

    if (kDebugMode) {
      ref.read(devTunerRegistryProvider.notifier).registerIfAbsent('deck', [
        TunableDouble(label: 'listPad', provider: deckListPaddingProvider, min: 8, max: 32, step: 4),
      ]);
    }
    final listPadding = ref.watch(deckListPaddingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('덱 선택')),
      body: decksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('오류: $err')),
        data: (decks) => ListView.builder(
          padding: EdgeInsets.all(listPadding),
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
