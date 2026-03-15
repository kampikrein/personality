import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/decks_table.dart';
import '../tables/cards_table.dart';

part 'deck_dao.g.dart';

@DriftAccessor(tables: [Decks, Cards])
class DeckDao extends DatabaseAccessor<AppDatabase> with _$DeckDaoMixin {
  DeckDao(super.db);

  Future<List<Deck>> getAllDecks() => select(decks).get();

  Stream<List<Deck>> watchAllDecks() => select(decks).watch();

  Future<Deck?> getDeckById(String id) =>
      (select(decks)..where((d) => d.id.equals(id))).getSingleOrNull();

  Future<void> insertDeck(DecksCompanion deck) => into(decks).insert(deck);

  Future<void> insertDeckWithCards(
    DecksCompanion deck,
    List<CardsCompanion> cardList,
  ) async {
    await transaction(() async {
      await into(decks).insert(deck);
      await batch((b) => b.insertAll(cards, cardList));
    });
  }

  Future<bool> updateDeck(DecksCompanion deck) => update(decks).replace(deck);

  Future<int> deleteDeck(String id) =>
      (delete(decks)..where((d) => d.id.equals(id))).go();
}
