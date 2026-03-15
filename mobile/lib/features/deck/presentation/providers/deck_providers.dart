import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/repositories/deck_repository_impl.dart';
import '../../domain/entities/deck_metadata.dart';
import '../../domain/entities/tarot_card.dart';
import '../../domain/repositories/deck_repository.dart';

part 'deck_providers.g.dart';

@Riverpod(keepAlive: true)
DeckRepository deckRepository(DeckRepositoryRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return DeckRepositoryImpl(db: db);
}

@riverpod
Stream<List<DeckMetadata>> watchDecks(WatchDecksRef ref) {
  final repo = ref.watch(deckRepositoryProvider);
  return repo.watchAllDecks();
}

@riverpod
Future<List<TarotCard>> deckCards(DeckCardsRef ref, String deckId) async {
  final repo = ref.watch(deckRepositoryProvider);
  return repo.getCardsByDeckId(deckId);
}

@riverpod
class SelectedDeck extends _$SelectedDeck {
  @override
  DeckMetadata? build() => null;

  void select(DeckMetadata deck) => state = deck;
  void clear() => state = null;
}
