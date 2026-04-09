import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/card_meanings.dart';
import '../../domain/entities/deck_metadata.dart';
import '../../domain/entities/tarot_card.dart';
import '../../domain/repositories/deck_repository.dart';

class DeckRepositoryImpl implements DeckRepository {
  DeckRepositoryImpl({required this.db});

  final AppDatabase db;

  @override
  Future<List<DeckMetadata>> getAllDecks() async {
    final rows = await db.deckDao.getAllDecks();
    return rows.map(_toDeckMetadata).toList();
  }

  @override
  Stream<List<DeckMetadata>> watchAllDecks() {
    return db.deckDao.watchAllDecks().map(
          (rows) => rows.map(_toDeckMetadata).toList(),
        );
  }

  @override
  Future<DeckMetadata?> getDeckById(String id) async {
    final row = await db.deckDao.getDeckById(id);
    return row != null ? _toDeckMetadata(row) : null;
  }

  @override
  Future<List<TarotCard>> getCardsByDeckId(String deckId) async {
    final rows = await db.cardDao.getCardsByDeckId(deckId);
    return rows.map(_toTarotCard).toList();
  }

  @override
  Future<bool> hasAnyDecks() async {
    final decks = await db.deckDao.getAllDecks();
    return decks.isNotEmpty;
  }

  @override
  Future<void> seedAllDecks() async {
    await _seedDeckIfAbsent('rws-standard', 'assets/data/rws_deck.json');
    await _seedDeckIfAbsent('iching-holitzka', 'assets/data/iching_holitzka_deck.json');
  }

  Future<void> _seedDeckIfAbsent(String deckId, String assetPath) async {
    final existing = await db.deckDao.getDeckById(deckId);
    if (existing != null) return;

    final jsonStr = await rootBundle.loadString(assetPath);
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final deckData = data['deck'] as Map<String, dynamic>;
    final cardsData = data['cards'] as List;

    final now = DateTime.now();
    final deckCompanion = DecksCompanion.insert(
      id: deckData['id'] as String,
      name: deckData['name'] as String,
      isStandardTarot: Value(deckData['isStandardTarot'] as bool),
      totalCards: deckData['totalCards'] as int,
      creator: Value(deckData['creator'] as String?),
      createdAt: now,
      updatedAt: now,
    );

    final cardCompanions = cardsData.map((c) {
      final card = c as Map<String, dynamic>;
      return CardsCompanion.insert(
        id: '${deckData['id']}-${card['cardId']}',
        deckId: deckData['id'] as String,
        cardId: card['cardId'] as String,
        name: card['name'] as String,
        arcana: card['arcana'] as String,
        suit: Value(card['suit'] as String?),
        number: card['number'] as int,
        imagePath: card['imagePath'] as String,
        meanings: CardMeanings.fromJson(
            card['meanings'] as Map<String, dynamic>),
        createdAt: now,
        updatedAt: now,
      );
    }).toList();

    await db.deckDao.insertDeckWithCards(deckCompanion, cardCompanions);
  }

  DeckMetadata _toDeckMetadata(Deck row) => DeckMetadata(
        id: row.id,
        name: row.name,
        isStandardTarot: row.isStandardTarot,
        totalCards: row.totalCards,
        creator: row.creator,
        supportedDrawModes: row.isStandardTarot
            ? [DrawMode.freeform, DrawMode.namedSpread]
            : [DrawMode.hexagram],
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  TarotCard _toTarotCard(Card row) => TarotCard(
        id: row.id,
        deckId: row.deckId,
        cardId: row.cardId,
        name: row.name,
        arcana: row.arcana,
        suit: row.suit,
        number: row.number,
        imagePath: row.imagePath,
        meanings: row.meanings,
      );
}
