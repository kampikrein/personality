// dart format width=80
// GENERATED CODE, DO NOT EDIT BY HAND.
// ignore_for_file: type=lint
import 'package:drift/drift.dart';

class Decks extends Table with TableInfo<Decks, DecksData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Decks(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<bool> isStandardTarot = GeneratedColumn<bool>(
      'is_standard_tarot', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_standard_tarot" IN (0, 1))'),
      defaultValue: const CustomExpression('1'));
  late final GeneratedColumn<int> totalCards = GeneratedColumn<int>(
      'total_cards', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  late final GeneratedColumn<String> creator = GeneratedColumn<String>(
      'creator', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression('1'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        isStandardTarot,
        totalCards,
        creator,
        createdAt,
        updatedAt,
        syncStatus,
        version
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'decks';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DecksData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DecksData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      isStandardTarot: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}is_standard_tarot'])!,
      totalCards: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_cards'])!,
      creator: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}creator']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sync_status'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
    );
  }

  @override
  Decks createAlias(String alias) {
    return Decks(attachedDatabase, alias);
  }
}

class DecksData extends DataClass implements Insertable<DecksData> {
  final String id;
  final String name;
  final bool isStandardTarot;
  final int totalCards;
  final String? creator;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int syncStatus;
  final int version;
  const DecksData(
      {required this.id,
      required this.name,
      required this.isStandardTarot,
      required this.totalCards,
      this.creator,
      required this.createdAt,
      required this.updatedAt,
      required this.syncStatus,
      required this.version});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['is_standard_tarot'] = Variable<bool>(isStandardTarot);
    map['total_cards'] = Variable<int>(totalCards);
    if (!nullToAbsent || creator != null) {
      map['creator'] = Variable<String>(creator);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['sync_status'] = Variable<int>(syncStatus);
    map['version'] = Variable<int>(version);
    return map;
  }

  DecksCompanion toCompanion(bool nullToAbsent) {
    return DecksCompanion(
      id: Value(id),
      name: Value(name),
      isStandardTarot: Value(isStandardTarot),
      totalCards: Value(totalCards),
      creator: creator == null && nullToAbsent
          ? const Value.absent()
          : Value(creator),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      version: Value(version),
    );
  }

  factory DecksData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DecksData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      isStandardTarot: serializer.fromJson<bool>(json['isStandardTarot']),
      totalCards: serializer.fromJson<int>(json['totalCards']),
      creator: serializer.fromJson<String?>(json['creator']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'isStandardTarot': serializer.toJson<bool>(isStandardTarot),
      'totalCards': serializer.toJson<int>(totalCards),
      'creator': serializer.toJson<String?>(creator),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'version': serializer.toJson<int>(version),
    };
  }

  DecksData copyWith(
          {String? id,
          String? name,
          bool? isStandardTarot,
          int? totalCards,
          Value<String?> creator = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          int? syncStatus,
          int? version}) =>
      DecksData(
        id: id ?? this.id,
        name: name ?? this.name,
        isStandardTarot: isStandardTarot ?? this.isStandardTarot,
        totalCards: totalCards ?? this.totalCards,
        creator: creator.present ? creator.value : this.creator,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncStatus: syncStatus ?? this.syncStatus,
        version: version ?? this.version,
      );
  DecksData copyWithCompanion(DecksCompanion data) {
    return DecksData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      isStandardTarot: data.isStandardTarot.present
          ? data.isStandardTarot.value
          : this.isStandardTarot,
      totalCards:
          data.totalCards.present ? data.totalCards.value : this.totalCards,
      creator: data.creator.present ? data.creator.value : this.creator,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DecksData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isStandardTarot: $isStandardTarot, ')
          ..write('totalCards: $totalCards, ')
          ..write('creator: $creator, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, isStandardTarot, totalCards,
      creator, createdAt, updatedAt, syncStatus, version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DecksData &&
          other.id == this.id &&
          other.name == this.name &&
          other.isStandardTarot == this.isStandardTarot &&
          other.totalCards == this.totalCards &&
          other.creator == this.creator &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.version == this.version);
}

class DecksCompanion extends UpdateCompanion<DecksData> {
  final Value<String> id;
  final Value<String> name;
  final Value<bool> isStandardTarot;
  final Value<int> totalCards;
  final Value<String?> creator;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> syncStatus;
  final Value<int> version;
  final Value<int> rowid;
  const DecksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.isStandardTarot = const Value.absent(),
    this.totalCards = const Value.absent(),
    this.creator = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DecksCompanion.insert({
    required String id,
    required String name,
    this.isStandardTarot = const Value.absent(),
    required int totalCards,
    this.creator = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        totalCards = Value(totalCards),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<DecksData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<bool>? isStandardTarot,
    Expression<int>? totalCards,
    Expression<String>? creator,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? syncStatus,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (isStandardTarot != null) 'is_standard_tarot': isStandardTarot,
      if (totalCards != null) 'total_cards': totalCards,
      if (creator != null) 'creator': creator,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DecksCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<bool>? isStandardTarot,
      Value<int>? totalCards,
      Value<String?>? creator,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? syncStatus,
      Value<int>? version,
      Value<int>? rowid}) {
    return DecksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      isStandardTarot: isStandardTarot ?? this.isStandardTarot,
      totalCards: totalCards ?? this.totalCards,
      creator: creator ?? this.creator,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isStandardTarot.present) {
      map['is_standard_tarot'] = Variable<bool>(isStandardTarot.value);
    }
    if (totalCards.present) {
      map['total_cards'] = Variable<int>(totalCards.value);
    }
    if (creator.present) {
      map['creator'] = Variable<String>(creator.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DecksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isStandardTarot: $isStandardTarot, ')
          ..write('totalCards: $totalCards, ')
          ..write('creator: $creator, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Cards extends Table with TableInfo<Cards, CardsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Cards(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> deckId = GeneratedColumn<String>(
      'deck_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES decks (id) ON DELETE CASCADE'));
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
      'card_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> arcana = GeneratedColumn<String>(
      'arcana', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> suit = GeneratedColumn<String>(
      'suit', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
      'number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
      'image_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> meanings = GeneratedColumn<String>(
      'meanings', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression('0'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        deckId,
        cardId,
        name,
        arcana,
        suit,
        number,
        imagePath,
        meanings,
        createdAt,
        updatedAt,
        syncStatus
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cards';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {deckId, cardId},
      ];
  @override
  CardsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardsData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      deckId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}deck_id'])!,
      cardId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}card_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      arcana: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}arcana'])!,
      suit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}suit']),
      number: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}number'])!,
      imagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_path'])!,
      meanings: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meanings'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sync_status'])!,
    );
  }

  @override
  Cards createAlias(String alias) {
    return Cards(attachedDatabase, alias);
  }
}

class CardsData extends DataClass implements Insertable<CardsData> {
  final String id;
  final String deckId;
  final String cardId;
  final String name;
  final String arcana;
  final String? suit;
  final int number;
  final String imagePath;
  final String meanings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int syncStatus;
  const CardsData(
      {required this.id,
      required this.deckId,
      required this.cardId,
      required this.name,
      required this.arcana,
      this.suit,
      required this.number,
      required this.imagePath,
      required this.meanings,
      required this.createdAt,
      required this.updatedAt,
      required this.syncStatus});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['deck_id'] = Variable<String>(deckId);
    map['card_id'] = Variable<String>(cardId);
    map['name'] = Variable<String>(name);
    map['arcana'] = Variable<String>(arcana);
    if (!nullToAbsent || suit != null) {
      map['suit'] = Variable<String>(suit);
    }
    map['number'] = Variable<int>(number);
    map['image_path'] = Variable<String>(imagePath);
    map['meanings'] = Variable<String>(meanings);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  CardsCompanion toCompanion(bool nullToAbsent) {
    return CardsCompanion(
      id: Value(id),
      deckId: Value(deckId),
      cardId: Value(cardId),
      name: Value(name),
      arcana: Value(arcana),
      suit: suit == null && nullToAbsent ? const Value.absent() : Value(suit),
      number: Value(number),
      imagePath: Value(imagePath),
      meanings: Value(meanings),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory CardsData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardsData(
      id: serializer.fromJson<String>(json['id']),
      deckId: serializer.fromJson<String>(json['deckId']),
      cardId: serializer.fromJson<String>(json['cardId']),
      name: serializer.fromJson<String>(json['name']),
      arcana: serializer.fromJson<String>(json['arcana']),
      suit: serializer.fromJson<String?>(json['suit']),
      number: serializer.fromJson<int>(json['number']),
      imagePath: serializer.fromJson<String>(json['imagePath']),
      meanings: serializer.fromJson<String>(json['meanings']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'deckId': serializer.toJson<String>(deckId),
      'cardId': serializer.toJson<String>(cardId),
      'name': serializer.toJson<String>(name),
      'arcana': serializer.toJson<String>(arcana),
      'suit': serializer.toJson<String?>(suit),
      'number': serializer.toJson<int>(number),
      'imagePath': serializer.toJson<String>(imagePath),
      'meanings': serializer.toJson<String>(meanings),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  CardsData copyWith(
          {String? id,
          String? deckId,
          String? cardId,
          String? name,
          String? arcana,
          Value<String?> suit = const Value.absent(),
          int? number,
          String? imagePath,
          String? meanings,
          DateTime? createdAt,
          DateTime? updatedAt,
          int? syncStatus}) =>
      CardsData(
        id: id ?? this.id,
        deckId: deckId ?? this.deckId,
        cardId: cardId ?? this.cardId,
        name: name ?? this.name,
        arcana: arcana ?? this.arcana,
        suit: suit.present ? suit.value : this.suit,
        number: number ?? this.number,
        imagePath: imagePath ?? this.imagePath,
        meanings: meanings ?? this.meanings,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncStatus: syncStatus ?? this.syncStatus,
      );
  CardsData copyWithCompanion(CardsCompanion data) {
    return CardsData(
      id: data.id.present ? data.id.value : this.id,
      deckId: data.deckId.present ? data.deckId.value : this.deckId,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      name: data.name.present ? data.name.value : this.name,
      arcana: data.arcana.present ? data.arcana.value : this.arcana,
      suit: data.suit.present ? data.suit.value : this.suit,
      number: data.number.present ? data.number.value : this.number,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      meanings: data.meanings.present ? data.meanings.value : this.meanings,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardsData(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('cardId: $cardId, ')
          ..write('name: $name, ')
          ..write('arcana: $arcana, ')
          ..write('suit: $suit, ')
          ..write('number: $number, ')
          ..write('imagePath: $imagePath, ')
          ..write('meanings: $meanings, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, deckId, cardId, name, arcana, suit,
      number, imagePath, meanings, createdAt, updatedAt, syncStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardsData &&
          other.id == this.id &&
          other.deckId == this.deckId &&
          other.cardId == this.cardId &&
          other.name == this.name &&
          other.arcana == this.arcana &&
          other.suit == this.suit &&
          other.number == this.number &&
          other.imagePath == this.imagePath &&
          other.meanings == this.meanings &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus);
}

class CardsCompanion extends UpdateCompanion<CardsData> {
  final Value<String> id;
  final Value<String> deckId;
  final Value<String> cardId;
  final Value<String> name;
  final Value<String> arcana;
  final Value<String?> suit;
  final Value<int> number;
  final Value<String> imagePath;
  final Value<String> meanings;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const CardsCompanion({
    this.id = const Value.absent(),
    this.deckId = const Value.absent(),
    this.cardId = const Value.absent(),
    this.name = const Value.absent(),
    this.arcana = const Value.absent(),
    this.suit = const Value.absent(),
    this.number = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.meanings = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CardsCompanion.insert({
    required String id,
    required String deckId,
    required String cardId,
    required String name,
    required String arcana,
    this.suit = const Value.absent(),
    required int number,
    required String imagePath,
    required String meanings,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        deckId = Value(deckId),
        cardId = Value(cardId),
        name = Value(name),
        arcana = Value(arcana),
        number = Value(number),
        imagePath = Value(imagePath),
        meanings = Value(meanings),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<CardsData> custom({
    Expression<String>? id,
    Expression<String>? deckId,
    Expression<String>? cardId,
    Expression<String>? name,
    Expression<String>? arcana,
    Expression<String>? suit,
    Expression<int>? number,
    Expression<String>? imagePath,
    Expression<String>? meanings,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deckId != null) 'deck_id': deckId,
      if (cardId != null) 'card_id': cardId,
      if (name != null) 'name': name,
      if (arcana != null) 'arcana': arcana,
      if (suit != null) 'suit': suit,
      if (number != null) 'number': number,
      if (imagePath != null) 'image_path': imagePath,
      if (meanings != null) 'meanings': meanings,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CardsCompanion copyWith(
      {Value<String>? id,
      Value<String>? deckId,
      Value<String>? cardId,
      Value<String>? name,
      Value<String>? arcana,
      Value<String?>? suit,
      Value<int>? number,
      Value<String>? imagePath,
      Value<String>? meanings,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? syncStatus,
      Value<int>? rowid}) {
    return CardsCompanion(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      cardId: cardId ?? this.cardId,
      name: name ?? this.name,
      arcana: arcana ?? this.arcana,
      suit: suit ?? this.suit,
      number: number ?? this.number,
      imagePath: imagePath ?? this.imagePath,
      meanings: meanings ?? this.meanings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (deckId.present) {
      map['deck_id'] = Variable<String>(deckId.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (arcana.present) {
      map['arcana'] = Variable<String>(arcana.value);
    }
    if (suit.present) {
      map['suit'] = Variable<String>(suit.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (meanings.present) {
      map['meanings'] = Variable<String>(meanings.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardsCompanion(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('cardId: $cardId, ')
          ..write('name: $name, ')
          ..write('arcana: $arcana, ')
          ..write('suit: $suit, ')
          ..write('number: $number, ')
          ..write('imagePath: $imagePath, ')
          ..write('meanings: $meanings, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Readings extends Table with TableInfo<Readings, ReadingsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Readings(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> deckId = GeneratedColumn<String>(
      'deck_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES decks (id)'));
  late final GeneratedColumn<String> spreadType = GeneratedColumn<String>(
      'spread_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> question = GeneratedColumn<String>(
      'question', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression('1'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        deckId,
        spreadType,
        question,
        notes,
        createdAt,
        updatedAt,
        syncStatus,
        version
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'readings';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingsData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      deckId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}deck_id'])!,
      spreadType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}spread_type'])!,
      question: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}question']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sync_status'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
    );
  }

  @override
  Readings createAlias(String alias) {
    return Readings(attachedDatabase, alias);
  }
}

class ReadingsData extends DataClass implements Insertable<ReadingsData> {
  final String id;
  final String deckId;
  final String spreadType;
  final String? question;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int syncStatus;
  final int version;
  const ReadingsData(
      {required this.id,
      required this.deckId,
      required this.spreadType,
      this.question,
      this.notes,
      required this.createdAt,
      required this.updatedAt,
      required this.syncStatus,
      required this.version});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['deck_id'] = Variable<String>(deckId);
    map['spread_type'] = Variable<String>(spreadType);
    if (!nullToAbsent || question != null) {
      map['question'] = Variable<String>(question);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['sync_status'] = Variable<int>(syncStatus);
    map['version'] = Variable<int>(version);
    return map;
  }

  ReadingsCompanion toCompanion(bool nullToAbsent) {
    return ReadingsCompanion(
      id: Value(id),
      deckId: Value(deckId),
      spreadType: Value(spreadType),
      question: question == null && nullToAbsent
          ? const Value.absent()
          : Value(question),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      version: Value(version),
    );
  }

  factory ReadingsData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingsData(
      id: serializer.fromJson<String>(json['id']),
      deckId: serializer.fromJson<String>(json['deckId']),
      spreadType: serializer.fromJson<String>(json['spreadType']),
      question: serializer.fromJson<String?>(json['question']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'deckId': serializer.toJson<String>(deckId),
      'spreadType': serializer.toJson<String>(spreadType),
      'question': serializer.toJson<String?>(question),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'version': serializer.toJson<int>(version),
    };
  }

  ReadingsData copyWith(
          {String? id,
          String? deckId,
          String? spreadType,
          Value<String?> question = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          int? syncStatus,
          int? version}) =>
      ReadingsData(
        id: id ?? this.id,
        deckId: deckId ?? this.deckId,
        spreadType: spreadType ?? this.spreadType,
        question: question.present ? question.value : this.question,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncStatus: syncStatus ?? this.syncStatus,
        version: version ?? this.version,
      );
  ReadingsData copyWithCompanion(ReadingsCompanion data) {
    return ReadingsData(
      id: data.id.present ? data.id.value : this.id,
      deckId: data.deckId.present ? data.deckId.value : this.deckId,
      spreadType:
          data.spreadType.present ? data.spreadType.value : this.spreadType,
      question: data.question.present ? data.question.value : this.question,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingsData(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('spreadType: $spreadType, ')
          ..write('question: $question, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, deckId, spreadType, question, notes,
      createdAt, updatedAt, syncStatus, version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingsData &&
          other.id == this.id &&
          other.deckId == this.deckId &&
          other.spreadType == this.spreadType &&
          other.question == this.question &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.version == this.version);
}

class ReadingsCompanion extends UpdateCompanion<ReadingsData> {
  final Value<String> id;
  final Value<String> deckId;
  final Value<String> spreadType;
  final Value<String?> question;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> syncStatus;
  final Value<int> version;
  final Value<int> rowid;
  const ReadingsCompanion({
    this.id = const Value.absent(),
    this.deckId = const Value.absent(),
    this.spreadType = const Value.absent(),
    this.question = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingsCompanion.insert({
    required String id,
    required String deckId,
    required String spreadType,
    this.question = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        deckId = Value(deckId),
        spreadType = Value(spreadType),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<ReadingsData> custom({
    Expression<String>? id,
    Expression<String>? deckId,
    Expression<String>? spreadType,
    Expression<String>? question,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? syncStatus,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deckId != null) 'deck_id': deckId,
      if (spreadType != null) 'spread_type': spreadType,
      if (question != null) 'question': question,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingsCompanion copyWith(
      {Value<String>? id,
      Value<String>? deckId,
      Value<String>? spreadType,
      Value<String?>? question,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? syncStatus,
      Value<int>? version,
      Value<int>? rowid}) {
    return ReadingsCompanion(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      spreadType: spreadType ?? this.spreadType,
      question: question ?? this.question,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (deckId.present) {
      map['deck_id'] = Variable<String>(deckId.value);
    }
    if (spreadType.present) {
      map['spread_type'] = Variable<String>(spreadType.value);
    }
    if (question.present) {
      map['question'] = Variable<String>(question.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingsCompanion(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('spreadType: $spreadType, ')
          ..write('question: $question, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DrawnCards extends Table with TableInfo<DrawnCards, DrawnCardsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  DrawnCards(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> readingId = GeneratedColumn<String>(
      'reading_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES readings (id) ON DELETE CASCADE'));
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
      'card_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES cards (id) ON DELETE CASCADE'));
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  late final GeneratedColumn<bool> isReversed = GeneratedColumn<bool>(
      'is_reversed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_reversed" IN (0, 1))'));
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, readingId, cardId, position, isReversed, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drawn_cards';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DrawnCardsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DrawnCardsData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      readingId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reading_id'])!,
      cardId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}card_id'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      isReversed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_reversed'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  DrawnCards createAlias(String alias) {
    return DrawnCards(attachedDatabase, alias);
  }
}

class DrawnCardsData extends DataClass implements Insertable<DrawnCardsData> {
  final String id;
  final String readingId;
  final String cardId;
  final int position;
  final bool isReversed;
  final DateTime createdAt;
  const DrawnCardsData(
      {required this.id,
      required this.readingId,
      required this.cardId,
      required this.position,
      required this.isReversed,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['reading_id'] = Variable<String>(readingId);
    map['card_id'] = Variable<String>(cardId);
    map['position'] = Variable<int>(position);
    map['is_reversed'] = Variable<bool>(isReversed);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DrawnCardsCompanion toCompanion(bool nullToAbsent) {
    return DrawnCardsCompanion(
      id: Value(id),
      readingId: Value(readingId),
      cardId: Value(cardId),
      position: Value(position),
      isReversed: Value(isReversed),
      createdAt: Value(createdAt),
    );
  }

  factory DrawnCardsData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DrawnCardsData(
      id: serializer.fromJson<String>(json['id']),
      readingId: serializer.fromJson<String>(json['readingId']),
      cardId: serializer.fromJson<String>(json['cardId']),
      position: serializer.fromJson<int>(json['position']),
      isReversed: serializer.fromJson<bool>(json['isReversed']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'readingId': serializer.toJson<String>(readingId),
      'cardId': serializer.toJson<String>(cardId),
      'position': serializer.toJson<int>(position),
      'isReversed': serializer.toJson<bool>(isReversed),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DrawnCardsData copyWith(
          {String? id,
          String? readingId,
          String? cardId,
          int? position,
          bool? isReversed,
          DateTime? createdAt}) =>
      DrawnCardsData(
        id: id ?? this.id,
        readingId: readingId ?? this.readingId,
        cardId: cardId ?? this.cardId,
        position: position ?? this.position,
        isReversed: isReversed ?? this.isReversed,
        createdAt: createdAt ?? this.createdAt,
      );
  DrawnCardsData copyWithCompanion(DrawnCardsCompanion data) {
    return DrawnCardsData(
      id: data.id.present ? data.id.value : this.id,
      readingId: data.readingId.present ? data.readingId.value : this.readingId,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      position: data.position.present ? data.position.value : this.position,
      isReversed:
          data.isReversed.present ? data.isReversed.value : this.isReversed,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DrawnCardsData(')
          ..write('id: $id, ')
          ..write('readingId: $readingId, ')
          ..write('cardId: $cardId, ')
          ..write('position: $position, ')
          ..write('isReversed: $isReversed, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, readingId, cardId, position, isReversed, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DrawnCardsData &&
          other.id == this.id &&
          other.readingId == this.readingId &&
          other.cardId == this.cardId &&
          other.position == this.position &&
          other.isReversed == this.isReversed &&
          other.createdAt == this.createdAt);
}

class DrawnCardsCompanion extends UpdateCompanion<DrawnCardsData> {
  final Value<String> id;
  final Value<String> readingId;
  final Value<String> cardId;
  final Value<int> position;
  final Value<bool> isReversed;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DrawnCardsCompanion({
    this.id = const Value.absent(),
    this.readingId = const Value.absent(),
    this.cardId = const Value.absent(),
    this.position = const Value.absent(),
    this.isReversed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DrawnCardsCompanion.insert({
    required String id,
    required String readingId,
    required String cardId,
    required int position,
    required bool isReversed,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        readingId = Value(readingId),
        cardId = Value(cardId),
        position = Value(position),
        isReversed = Value(isReversed),
        createdAt = Value(createdAt);
  static Insertable<DrawnCardsData> custom({
    Expression<String>? id,
    Expression<String>? readingId,
    Expression<String>? cardId,
    Expression<int>? position,
    Expression<bool>? isReversed,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (readingId != null) 'reading_id': readingId,
      if (cardId != null) 'card_id': cardId,
      if (position != null) 'position': position,
      if (isReversed != null) 'is_reversed': isReversed,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DrawnCardsCompanion copyWith(
      {Value<String>? id,
      Value<String>? readingId,
      Value<String>? cardId,
      Value<int>? position,
      Value<bool>? isReversed,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return DrawnCardsCompanion(
      id: id ?? this.id,
      readingId: readingId ?? this.readingId,
      cardId: cardId ?? this.cardId,
      position: position ?? this.position,
      isReversed: isReversed ?? this.isReversed,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (readingId.present) {
      map['reading_id'] = Variable<String>(readingId.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (isReversed.present) {
      map['is_reversed'] = Variable<bool>(isReversed.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DrawnCardsCompanion(')
          ..write('id: $id, ')
          ..write('readingId: $readingId, ')
          ..write('cardId: $cardId, ')
          ..write('position: $position, ')
          ..write('isReversed: $isReversed, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class UserSettings extends Table
    with TableInfo<UserSettings, UserSettingsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  UserSettings(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  late final GeneratedColumn<String> selectedDeckId = GeneratedColumn<String>(
      'selected_deck_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression('\'rws-standard\''));
  late final GeneratedColumn<int> experienceLevel = GeneratedColumn<int>(
      'experience_level', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression('4'));
  late final GeneratedColumn<int> defaultCardCount = GeneratedColumn<int>(
      'default_card_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression('3'));
  late final GeneratedColumn<bool> showFaceUp = GeneratedColumn<bool>(
      'show_face_up', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("show_face_up" IN (0, 1))'),
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<bool> quickDrawEnabled = GeneratedColumn<bool>(
      'quick_draw_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("quick_draw_enabled" IN (0, 1))'),
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<String> defaultLayoutType =
      GeneratedColumn<String>('default_layout_type', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const CustomExpression('\'custom\''));
  late final GeneratedColumn<bool> showCardName = GeneratedColumn<bool>(
      'show_card_name', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("show_card_name" IN (0, 1))'),
      defaultValue: const CustomExpression('1'));
  late final GeneratedColumn<bool> allowReversed = GeneratedColumn<bool>(
      'allow_reversed', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("allow_reversed" IN (0, 1))'),
      defaultValue: const CustomExpression('1'));
  late final GeneratedColumn<String> cardSizePreset = GeneratedColumn<String>(
      'card_size_preset', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression('\'standardTarot\''));
  late final GeneratedColumn<double> customCardWidthMm =
      GeneratedColumn<double>('custom_card_width_mm', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const CustomExpression('70.0'));
  late final GeneratedColumn<double> customCardHeightMm =
      GeneratedColumn<double>('custom_card_height_mm', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const CustomExpression('120.0'));
  late final GeneratedColumn<int> cardsPerRow = GeneratedColumn<int>(
      'cards_per_row', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression('3'));
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        selectedDeckId,
        experienceLevel,
        defaultCardCount,
        showFaceUp,
        quickDrawEnabled,
        defaultLayoutType,
        showCardName,
        allowReversed,
        cardSizePreset,
        customCardWidthMm,
        customCardHeightMm,
        cardsPerRow,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_settings';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserSettingsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserSettingsData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      selectedDeckId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}selected_deck_id'])!,
      experienceLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}experience_level'])!,
      defaultCardCount: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}default_card_count'])!,
      showFaceUp: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}show_face_up'])!,
      quickDrawEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}quick_draw_enabled'])!,
      defaultLayoutType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}default_layout_type'])!,
      showCardName: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}show_card_name']),
      allowReversed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}allow_reversed']),
      cardSizePreset: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}card_size_preset'])!,
      customCardWidthMm: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}custom_card_width_mm'])!,
      customCardHeightMm: attachedDatabase.typeMapping.read(DriftSqlType.double,
          data['${effectivePrefix}custom_card_height_mm'])!,
      cardsPerRow: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cards_per_row']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  UserSettings createAlias(String alias) {
    return UserSettings(attachedDatabase, alias);
  }
}

class UserSettingsData extends DataClass
    implements Insertable<UserSettingsData> {
  final int id;
  final String selectedDeckId;
  final int experienceLevel;
  final int defaultCardCount;
  final bool showFaceUp;
  final bool quickDrawEnabled;
  final String defaultLayoutType;
  final bool? showCardName;
  final bool? allowReversed;
  final String cardSizePreset;
  final double customCardWidthMm;
  final double customCardHeightMm;
  final int? cardsPerRow;
  final DateTime updatedAt;
  const UserSettingsData(
      {required this.id,
      required this.selectedDeckId,
      required this.experienceLevel,
      required this.defaultCardCount,
      required this.showFaceUp,
      required this.quickDrawEnabled,
      required this.defaultLayoutType,
      this.showCardName,
      this.allowReversed,
      required this.cardSizePreset,
      required this.customCardWidthMm,
      required this.customCardHeightMm,
      this.cardsPerRow,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['selected_deck_id'] = Variable<String>(selectedDeckId);
    map['experience_level'] = Variable<int>(experienceLevel);
    map['default_card_count'] = Variable<int>(defaultCardCount);
    map['show_face_up'] = Variable<bool>(showFaceUp);
    map['quick_draw_enabled'] = Variable<bool>(quickDrawEnabled);
    map['default_layout_type'] = Variable<String>(defaultLayoutType);
    if (!nullToAbsent || showCardName != null) {
      map['show_card_name'] = Variable<bool>(showCardName);
    }
    if (!nullToAbsent || allowReversed != null) {
      map['allow_reversed'] = Variable<bool>(allowReversed);
    }
    map['card_size_preset'] = Variable<String>(cardSizePreset);
    map['custom_card_width_mm'] = Variable<double>(customCardWidthMm);
    map['custom_card_height_mm'] = Variable<double>(customCardHeightMm);
    if (!nullToAbsent || cardsPerRow != null) {
      map['cards_per_row'] = Variable<int>(cardsPerRow);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserSettingsCompanion toCompanion(bool nullToAbsent) {
    return UserSettingsCompanion(
      id: Value(id),
      selectedDeckId: Value(selectedDeckId),
      experienceLevel: Value(experienceLevel),
      defaultCardCount: Value(defaultCardCount),
      showFaceUp: Value(showFaceUp),
      quickDrawEnabled: Value(quickDrawEnabled),
      defaultLayoutType: Value(defaultLayoutType),
      showCardName: showCardName == null && nullToAbsent
          ? const Value.absent()
          : Value(showCardName),
      allowReversed: allowReversed == null && nullToAbsent
          ? const Value.absent()
          : Value(allowReversed),
      cardSizePreset: Value(cardSizePreset),
      customCardWidthMm: Value(customCardWidthMm),
      customCardHeightMm: Value(customCardHeightMm),
      cardsPerRow: cardsPerRow == null && nullToAbsent
          ? const Value.absent()
          : Value(cardsPerRow),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserSettingsData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserSettingsData(
      id: serializer.fromJson<int>(json['id']),
      selectedDeckId: serializer.fromJson<String>(json['selectedDeckId']),
      experienceLevel: serializer.fromJson<int>(json['experienceLevel']),
      defaultCardCount: serializer.fromJson<int>(json['defaultCardCount']),
      showFaceUp: serializer.fromJson<bool>(json['showFaceUp']),
      quickDrawEnabled: serializer.fromJson<bool>(json['quickDrawEnabled']),
      defaultLayoutType: serializer.fromJson<String>(json['defaultLayoutType']),
      showCardName: serializer.fromJson<bool?>(json['showCardName']),
      allowReversed: serializer.fromJson<bool?>(json['allowReversed']),
      cardSizePreset: serializer.fromJson<String>(json['cardSizePreset']),
      customCardWidthMm: serializer.fromJson<double>(json['customCardWidthMm']),
      customCardHeightMm:
          serializer.fromJson<double>(json['customCardHeightMm']),
      cardsPerRow: serializer.fromJson<int?>(json['cardsPerRow']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'selectedDeckId': serializer.toJson<String>(selectedDeckId),
      'experienceLevel': serializer.toJson<int>(experienceLevel),
      'defaultCardCount': serializer.toJson<int>(defaultCardCount),
      'showFaceUp': serializer.toJson<bool>(showFaceUp),
      'quickDrawEnabled': serializer.toJson<bool>(quickDrawEnabled),
      'defaultLayoutType': serializer.toJson<String>(defaultLayoutType),
      'showCardName': serializer.toJson<bool?>(showCardName),
      'allowReversed': serializer.toJson<bool?>(allowReversed),
      'cardSizePreset': serializer.toJson<String>(cardSizePreset),
      'customCardWidthMm': serializer.toJson<double>(customCardWidthMm),
      'customCardHeightMm': serializer.toJson<double>(customCardHeightMm),
      'cardsPerRow': serializer.toJson<int?>(cardsPerRow),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserSettingsData copyWith(
          {int? id,
          String? selectedDeckId,
          int? experienceLevel,
          int? defaultCardCount,
          bool? showFaceUp,
          bool? quickDrawEnabled,
          String? defaultLayoutType,
          Value<bool?> showCardName = const Value.absent(),
          Value<bool?> allowReversed = const Value.absent(),
          String? cardSizePreset,
          double? customCardWidthMm,
          double? customCardHeightMm,
          Value<int?> cardsPerRow = const Value.absent(),
          DateTime? updatedAt}) =>
      UserSettingsData(
        id: id ?? this.id,
        selectedDeckId: selectedDeckId ?? this.selectedDeckId,
        experienceLevel: experienceLevel ?? this.experienceLevel,
        defaultCardCount: defaultCardCount ?? this.defaultCardCount,
        showFaceUp: showFaceUp ?? this.showFaceUp,
        quickDrawEnabled: quickDrawEnabled ?? this.quickDrawEnabled,
        defaultLayoutType: defaultLayoutType ?? this.defaultLayoutType,
        showCardName:
            showCardName.present ? showCardName.value : this.showCardName,
        allowReversed:
            allowReversed.present ? allowReversed.value : this.allowReversed,
        cardSizePreset: cardSizePreset ?? this.cardSizePreset,
        customCardWidthMm: customCardWidthMm ?? this.customCardWidthMm,
        customCardHeightMm: customCardHeightMm ?? this.customCardHeightMm,
        cardsPerRow: cardsPerRow.present ? cardsPerRow.value : this.cardsPerRow,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  UserSettingsData copyWithCompanion(UserSettingsCompanion data) {
    return UserSettingsData(
      id: data.id.present ? data.id.value : this.id,
      selectedDeckId: data.selectedDeckId.present
          ? data.selectedDeckId.value
          : this.selectedDeckId,
      experienceLevel: data.experienceLevel.present
          ? data.experienceLevel.value
          : this.experienceLevel,
      defaultCardCount: data.defaultCardCount.present
          ? data.defaultCardCount.value
          : this.defaultCardCount,
      showFaceUp:
          data.showFaceUp.present ? data.showFaceUp.value : this.showFaceUp,
      quickDrawEnabled: data.quickDrawEnabled.present
          ? data.quickDrawEnabled.value
          : this.quickDrawEnabled,
      defaultLayoutType: data.defaultLayoutType.present
          ? data.defaultLayoutType.value
          : this.defaultLayoutType,
      showCardName: data.showCardName.present
          ? data.showCardName.value
          : this.showCardName,
      allowReversed: data.allowReversed.present
          ? data.allowReversed.value
          : this.allowReversed,
      cardSizePreset: data.cardSizePreset.present
          ? data.cardSizePreset.value
          : this.cardSizePreset,
      customCardWidthMm: data.customCardWidthMm.present
          ? data.customCardWidthMm.value
          : this.customCardWidthMm,
      customCardHeightMm: data.customCardHeightMm.present
          ? data.customCardHeightMm.value
          : this.customCardHeightMm,
      cardsPerRow:
          data.cardsPerRow.present ? data.cardsPerRow.value : this.cardsPerRow,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsData(')
          ..write('id: $id, ')
          ..write('selectedDeckId: $selectedDeckId, ')
          ..write('experienceLevel: $experienceLevel, ')
          ..write('defaultCardCount: $defaultCardCount, ')
          ..write('showFaceUp: $showFaceUp, ')
          ..write('quickDrawEnabled: $quickDrawEnabled, ')
          ..write('defaultLayoutType: $defaultLayoutType, ')
          ..write('showCardName: $showCardName, ')
          ..write('allowReversed: $allowReversed, ')
          ..write('cardSizePreset: $cardSizePreset, ')
          ..write('customCardWidthMm: $customCardWidthMm, ')
          ..write('customCardHeightMm: $customCardHeightMm, ')
          ..write('cardsPerRow: $cardsPerRow, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      selectedDeckId,
      experienceLevel,
      defaultCardCount,
      showFaceUp,
      quickDrawEnabled,
      defaultLayoutType,
      showCardName,
      allowReversed,
      cardSizePreset,
      customCardWidthMm,
      customCardHeightMm,
      cardsPerRow,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserSettingsData &&
          other.id == this.id &&
          other.selectedDeckId == this.selectedDeckId &&
          other.experienceLevel == this.experienceLevel &&
          other.defaultCardCount == this.defaultCardCount &&
          other.showFaceUp == this.showFaceUp &&
          other.quickDrawEnabled == this.quickDrawEnabled &&
          other.defaultLayoutType == this.defaultLayoutType &&
          other.showCardName == this.showCardName &&
          other.allowReversed == this.allowReversed &&
          other.cardSizePreset == this.cardSizePreset &&
          other.customCardWidthMm == this.customCardWidthMm &&
          other.customCardHeightMm == this.customCardHeightMm &&
          other.cardsPerRow == this.cardsPerRow &&
          other.updatedAt == this.updatedAt);
}

class UserSettingsCompanion extends UpdateCompanion<UserSettingsData> {
  final Value<int> id;
  final Value<String> selectedDeckId;
  final Value<int> experienceLevel;
  final Value<int> defaultCardCount;
  final Value<bool> showFaceUp;
  final Value<bool> quickDrawEnabled;
  final Value<String> defaultLayoutType;
  final Value<bool?> showCardName;
  final Value<bool?> allowReversed;
  final Value<String> cardSizePreset;
  final Value<double> customCardWidthMm;
  final Value<double> customCardHeightMm;
  final Value<int?> cardsPerRow;
  final Value<DateTime> updatedAt;
  const UserSettingsCompanion({
    this.id = const Value.absent(),
    this.selectedDeckId = const Value.absent(),
    this.experienceLevel = const Value.absent(),
    this.defaultCardCount = const Value.absent(),
    this.showFaceUp = const Value.absent(),
    this.quickDrawEnabled = const Value.absent(),
    this.defaultLayoutType = const Value.absent(),
    this.showCardName = const Value.absent(),
    this.allowReversed = const Value.absent(),
    this.cardSizePreset = const Value.absent(),
    this.customCardWidthMm = const Value.absent(),
    this.customCardHeightMm = const Value.absent(),
    this.cardsPerRow = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  UserSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.selectedDeckId = const Value.absent(),
    this.experienceLevel = const Value.absent(),
    this.defaultCardCount = const Value.absent(),
    this.showFaceUp = const Value.absent(),
    this.quickDrawEnabled = const Value.absent(),
    this.defaultLayoutType = const Value.absent(),
    this.showCardName = const Value.absent(),
    this.allowReversed = const Value.absent(),
    this.cardSizePreset = const Value.absent(),
    this.customCardWidthMm = const Value.absent(),
    this.customCardHeightMm = const Value.absent(),
    this.cardsPerRow = const Value.absent(),
    required DateTime updatedAt,
  }) : updatedAt = Value(updatedAt);
  static Insertable<UserSettingsData> custom({
    Expression<int>? id,
    Expression<String>? selectedDeckId,
    Expression<int>? experienceLevel,
    Expression<int>? defaultCardCount,
    Expression<bool>? showFaceUp,
    Expression<bool>? quickDrawEnabled,
    Expression<String>? defaultLayoutType,
    Expression<bool>? showCardName,
    Expression<bool>? allowReversed,
    Expression<String>? cardSizePreset,
    Expression<double>? customCardWidthMm,
    Expression<double>? customCardHeightMm,
    Expression<int>? cardsPerRow,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (selectedDeckId != null) 'selected_deck_id': selectedDeckId,
      if (experienceLevel != null) 'experience_level': experienceLevel,
      if (defaultCardCount != null) 'default_card_count': defaultCardCount,
      if (showFaceUp != null) 'show_face_up': showFaceUp,
      if (quickDrawEnabled != null) 'quick_draw_enabled': quickDrawEnabled,
      if (defaultLayoutType != null) 'default_layout_type': defaultLayoutType,
      if (showCardName != null) 'show_card_name': showCardName,
      if (allowReversed != null) 'allow_reversed': allowReversed,
      if (cardSizePreset != null) 'card_size_preset': cardSizePreset,
      if (customCardWidthMm != null) 'custom_card_width_mm': customCardWidthMm,
      if (customCardHeightMm != null)
        'custom_card_height_mm': customCardHeightMm,
      if (cardsPerRow != null) 'cards_per_row': cardsPerRow,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  UserSettingsCompanion copyWith(
      {Value<int>? id,
      Value<String>? selectedDeckId,
      Value<int>? experienceLevel,
      Value<int>? defaultCardCount,
      Value<bool>? showFaceUp,
      Value<bool>? quickDrawEnabled,
      Value<String>? defaultLayoutType,
      Value<bool?>? showCardName,
      Value<bool?>? allowReversed,
      Value<String>? cardSizePreset,
      Value<double>? customCardWidthMm,
      Value<double>? customCardHeightMm,
      Value<int?>? cardsPerRow,
      Value<DateTime>? updatedAt}) {
    return UserSettingsCompanion(
      id: id ?? this.id,
      selectedDeckId: selectedDeckId ?? this.selectedDeckId,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      defaultCardCount: defaultCardCount ?? this.defaultCardCount,
      showFaceUp: showFaceUp ?? this.showFaceUp,
      quickDrawEnabled: quickDrawEnabled ?? this.quickDrawEnabled,
      defaultLayoutType: defaultLayoutType ?? this.defaultLayoutType,
      showCardName: showCardName ?? this.showCardName,
      allowReversed: allowReversed ?? this.allowReversed,
      cardSizePreset: cardSizePreset ?? this.cardSizePreset,
      customCardWidthMm: customCardWidthMm ?? this.customCardWidthMm,
      customCardHeightMm: customCardHeightMm ?? this.customCardHeightMm,
      cardsPerRow: cardsPerRow ?? this.cardsPerRow,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (selectedDeckId.present) {
      map['selected_deck_id'] = Variable<String>(selectedDeckId.value);
    }
    if (experienceLevel.present) {
      map['experience_level'] = Variable<int>(experienceLevel.value);
    }
    if (defaultCardCount.present) {
      map['default_card_count'] = Variable<int>(defaultCardCount.value);
    }
    if (showFaceUp.present) {
      map['show_face_up'] = Variable<bool>(showFaceUp.value);
    }
    if (quickDrawEnabled.present) {
      map['quick_draw_enabled'] = Variable<bool>(quickDrawEnabled.value);
    }
    if (defaultLayoutType.present) {
      map['default_layout_type'] = Variable<String>(defaultLayoutType.value);
    }
    if (showCardName.present) {
      map['show_card_name'] = Variable<bool>(showCardName.value);
    }
    if (allowReversed.present) {
      map['allow_reversed'] = Variable<bool>(allowReversed.value);
    }
    if (cardSizePreset.present) {
      map['card_size_preset'] = Variable<String>(cardSizePreset.value);
    }
    if (customCardWidthMm.present) {
      map['custom_card_width_mm'] = Variable<double>(customCardWidthMm.value);
    }
    if (customCardHeightMm.present) {
      map['custom_card_height_mm'] = Variable<double>(customCardHeightMm.value);
    }
    if (cardsPerRow.present) {
      map['cards_per_row'] = Variable<int>(cardsPerRow.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsCompanion(')
          ..write('id: $id, ')
          ..write('selectedDeckId: $selectedDeckId, ')
          ..write('experienceLevel: $experienceLevel, ')
          ..write('defaultCardCount: $defaultCardCount, ')
          ..write('showFaceUp: $showFaceUp, ')
          ..write('quickDrawEnabled: $quickDrawEnabled, ')
          ..write('defaultLayoutType: $defaultLayoutType, ')
          ..write('showCardName: $showCardName, ')
          ..write('allowReversed: $allowReversed, ')
          ..write('cardSizePreset: $cardSizePreset, ')
          ..write('customCardWidthMm: $customCardWidthMm, ')
          ..write('customCardHeightMm: $customCardHeightMm, ')
          ..write('cardsPerRow: $cardsPerRow, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class DatabaseAtV8 extends GeneratedDatabase {
  DatabaseAtV8(QueryExecutor e) : super(e);
  late final Decks decks = Decks(this);
  late final Cards cards = Cards(this);
  late final Readings readings = Readings(this);
  late final DrawnCards drawnCards = DrawnCards(this);
  late final UserSettings userSettings = UserSettings(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [decks, cards, readings, drawnCards, userSettings];
  @override
  int get schemaVersion => 8;
}
