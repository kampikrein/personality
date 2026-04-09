import '../entities/deck_metadata.dart';
import '../entities/tarot_card.dart';

abstract class DeckRepository {
  Future<List<DeckMetadata>> getAllDecks();
  Stream<List<DeckMetadata>> watchAllDecks();
  Future<DeckMetadata?> getDeckById(String id);
  Future<List<TarotCard>> getCardsByDeckId(String deckId);
  Future<void> seedAllDecks();
  Future<bool> hasAnyDecks();
}
