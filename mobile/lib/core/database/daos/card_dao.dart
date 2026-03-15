import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/cards_table.dart';

part 'card_dao.g.dart';

@DriftAccessor(tables: [Cards])
class CardDao extends DatabaseAccessor<AppDatabase> with _$CardDaoMixin {
  CardDao(super.db);

  Future<List<Card>> getCardsByDeckId(String deckId) =>
      (select(cards)..where((c) => c.deckId.equals(deckId))).get();

  Stream<List<Card>> watchCardsByDeckId(String deckId) =>
      (select(cards)..where((c) => c.deckId.equals(deckId))).watch();

  Future<Card?> getCardById(String id) =>
      (select(cards)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<void> insertCard(CardsCompanion card) => into(cards).insert(card);

  Future<void> insertCards(List<CardsCompanion> cardList) =>
      batch((b) => b.insertAll(cards, cardList));
}
