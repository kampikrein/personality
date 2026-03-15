import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../features/deck/domain/entities/card_meanings.dart';

class CardMeaningsConverter extends TypeConverter<CardMeanings, String> {
  const CardMeaningsConverter();

  @override
  CardMeanings fromSql(String fromDb) {
    final json = jsonDecode(fromDb) as Map<String, dynamic>;
    return CardMeanings.fromJson(json);
  }

  @override
  String toSql(CardMeanings value) {
    return jsonEncode(value.toJson());
  }
}
