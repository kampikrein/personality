// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DecksTable extends Decks with TableInfo<$DecksTable, Deck> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DecksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isStandardTarotMeta =
      const VerificationMeta('isStandardTarot');
  @override
  late final GeneratedColumn<bool> isStandardTarot = GeneratedColumn<bool>(
      'is_standard_tarot', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_standard_tarot" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _totalCardsMeta =
      const VerificationMeta('totalCards');
  @override
  late final GeneratedColumn<int> totalCards = GeneratedColumn<int>(
      'total_cards', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _creatorMeta =
      const VerificationMeta('creator');
  @override
  late final GeneratedColumn<String> creator = GeneratedColumn<String>(
      'creator', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus, int> syncStatus =
      GeneratedColumn<int>('sync_status', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              defaultValue: Constant(SyncStatus.pending.index))
          .withConverter<SyncStatus>($DecksTable.$convertersyncStatus);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
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
  VerificationContext validateIntegrity(Insertable<Deck> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_standard_tarot')) {
      context.handle(
          _isStandardTarotMeta,
          isStandardTarot.isAcceptableOrUnknown(
              data['is_standard_tarot']!, _isStandardTarotMeta));
    }
    if (data.containsKey('total_cards')) {
      context.handle(
          _totalCardsMeta,
          totalCards.isAcceptableOrUnknown(
              data['total_cards']!, _totalCardsMeta));
    } else if (isInserting) {
      context.missing(_totalCardsMeta);
    }
    if (data.containsKey('creator')) {
      context.handle(_creatorMeta,
          creator.isAcceptableOrUnknown(data['creator']!, _creatorMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Deck map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Deck(
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
      syncStatus: $DecksTable.$convertersyncStatus.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sync_status'])!),
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
    );
  }

  @override
  $DecksTable createAlias(String alias) {
    return $DecksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatus, int, int> $convertersyncStatus =
      const EnumIndexConverter<SyncStatus>(SyncStatus.values);
}

class Deck extends DataClass implements Insertable<Deck> {
  final String id;
  final String name;
  final bool isStandardTarot;
  final int totalCards;
  final String? creator;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final int version;
  const Deck(
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
    {
      map['sync_status'] =
          Variable<int>($DecksTable.$convertersyncStatus.toSql(syncStatus));
    }
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

  factory Deck.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Deck(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      isStandardTarot: serializer.fromJson<bool>(json['isStandardTarot']),
      totalCards: serializer.fromJson<int>(json['totalCards']),
      creator: serializer.fromJson<String?>(json['creator']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncStatus: $DecksTable.$convertersyncStatus
          .fromJson(serializer.fromJson<int>(json['syncStatus'])),
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
      'syncStatus': serializer
          .toJson<int>($DecksTable.$convertersyncStatus.toJson(syncStatus)),
      'version': serializer.toJson<int>(version),
    };
  }

  Deck copyWith(
          {String? id,
          String? name,
          bool? isStandardTarot,
          int? totalCards,
          Value<String?> creator = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          SyncStatus? syncStatus,
          int? version}) =>
      Deck(
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
  Deck copyWithCompanion(DecksCompanion data) {
    return Deck(
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
    return (StringBuffer('Deck(')
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
      (other is Deck &&
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

class DecksCompanion extends UpdateCompanion<Deck> {
  final Value<String> id;
  final Value<String> name;
  final Value<bool> isStandardTarot;
  final Value<int> totalCards;
  final Value<String?> creator;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<SyncStatus> syncStatus;
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
  static Insertable<Deck> custom({
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
      Value<SyncStatus>? syncStatus,
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
      map['sync_status'] = Variable<int>(
          $DecksTable.$convertersyncStatus.toSql(syncStatus.value));
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

class $CardsTable extends Cards with TableInfo<$CardsTable, Card> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deckIdMeta = const VerificationMeta('deckId');
  @override
  late final GeneratedColumn<String> deckId = GeneratedColumn<String>(
      'deck_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES decks (id) ON DELETE CASCADE'));
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
      'card_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _arcanaMeta = const VerificationMeta('arcana');
  @override
  late final GeneratedColumn<String> arcana = GeneratedColumn<String>(
      'arcana', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _suitMeta = const VerificationMeta('suit');
  @override
  late final GeneratedColumn<String> suit = GeneratedColumn<String>(
      'suit', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
      'number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _imagePathMeta =
      const VerificationMeta('imagePath');
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
      'image_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<CardMeanings, String> meanings =
      GeneratedColumn<String>('meanings', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<CardMeanings>($CardsTable.$convertermeanings);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus, int> syncStatus =
      GeneratedColumn<int>('sync_status', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              defaultValue: Constant(SyncStatus.pending.index))
          .withConverter<SyncStatus>($CardsTable.$convertersyncStatus);
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
  VerificationContext validateIntegrity(Insertable<Card> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('deck_id')) {
      context.handle(_deckIdMeta,
          deckId.isAcceptableOrUnknown(data['deck_id']!, _deckIdMeta));
    } else if (isInserting) {
      context.missing(_deckIdMeta);
    }
    if (data.containsKey('card_id')) {
      context.handle(_cardIdMeta,
          cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta));
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('arcana')) {
      context.handle(_arcanaMeta,
          arcana.isAcceptableOrUnknown(data['arcana']!, _arcanaMeta));
    } else if (isInserting) {
      context.missing(_arcanaMeta);
    }
    if (data.containsKey('suit')) {
      context.handle(
          _suitMeta, suit.isAcceptableOrUnknown(data['suit']!, _suitMeta));
    }
    if (data.containsKey('number')) {
      context.handle(_numberMeta,
          number.isAcceptableOrUnknown(data['number']!, _numberMeta));
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(_imagePathMeta,
          imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta));
    } else if (isInserting) {
      context.missing(_imagePathMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {deckId, cardId},
      ];
  @override
  Card map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Card(
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
      meanings: $CardsTable.$convertermeanings.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meanings'])!),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      syncStatus: $CardsTable.$convertersyncStatus.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sync_status'])!),
    );
  }

  @override
  $CardsTable createAlias(String alias) {
    return $CardsTable(attachedDatabase, alias);
  }

  static TypeConverter<CardMeanings, String> $convertermeanings =
      const CardMeaningsConverter();
  static JsonTypeConverter2<SyncStatus, int, int> $convertersyncStatus =
      const EnumIndexConverter<SyncStatus>(SyncStatus.values);
}

class Card extends DataClass implements Insertable<Card> {
  final String id;
  final String deckId;
  final String cardId;
  final String name;
  final String arcana;
  final String? suit;
  final int number;
  final String imagePath;
  final CardMeanings meanings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  const Card(
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
    {
      map['meanings'] =
          Variable<String>($CardsTable.$convertermeanings.toSql(meanings));
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['sync_status'] =
          Variable<int>($CardsTable.$convertersyncStatus.toSql(syncStatus));
    }
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

  factory Card.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Card(
      id: serializer.fromJson<String>(json['id']),
      deckId: serializer.fromJson<String>(json['deckId']),
      cardId: serializer.fromJson<String>(json['cardId']),
      name: serializer.fromJson<String>(json['name']),
      arcana: serializer.fromJson<String>(json['arcana']),
      suit: serializer.fromJson<String?>(json['suit']),
      number: serializer.fromJson<int>(json['number']),
      imagePath: serializer.fromJson<String>(json['imagePath']),
      meanings: serializer.fromJson<CardMeanings>(json['meanings']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncStatus: $CardsTable.$convertersyncStatus
          .fromJson(serializer.fromJson<int>(json['syncStatus'])),
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
      'meanings': serializer.toJson<CardMeanings>(meanings),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncStatus': serializer
          .toJson<int>($CardsTable.$convertersyncStatus.toJson(syncStatus)),
    };
  }

  Card copyWith(
          {String? id,
          String? deckId,
          String? cardId,
          String? name,
          String? arcana,
          Value<String?> suit = const Value.absent(),
          int? number,
          String? imagePath,
          CardMeanings? meanings,
          DateTime? createdAt,
          DateTime? updatedAt,
          SyncStatus? syncStatus}) =>
      Card(
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
  Card copyWithCompanion(CardsCompanion data) {
    return Card(
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
    return (StringBuffer('Card(')
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
      (other is Card &&
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

class CardsCompanion extends UpdateCompanion<Card> {
  final Value<String> id;
  final Value<String> deckId;
  final Value<String> cardId;
  final Value<String> name;
  final Value<String> arcana;
  final Value<String?> suit;
  final Value<int> number;
  final Value<String> imagePath;
  final Value<CardMeanings> meanings;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<SyncStatus> syncStatus;
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
    required CardMeanings meanings,
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
  static Insertable<Card> custom({
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
      Value<CardMeanings>? meanings,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<SyncStatus>? syncStatus,
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
      map['meanings'] = Variable<String>(
          $CardsTable.$convertermeanings.toSql(meanings.value));
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(
          $CardsTable.$convertersyncStatus.toSql(syncStatus.value));
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

class $ReadingsTable extends Readings with TableInfo<$ReadingsTable, Reading> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deckIdMeta = const VerificationMeta('deckId');
  @override
  late final GeneratedColumn<String> deckId = GeneratedColumn<String>(
      'deck_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES decks (id)'));
  static const VerificationMeta _spreadTypeMeta =
      const VerificationMeta('spreadType');
  @override
  late final GeneratedColumn<String> spreadType = GeneratedColumn<String>(
      'spread_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _questionMeta =
      const VerificationMeta('question');
  @override
  late final GeneratedColumn<String> question = GeneratedColumn<String>(
      'question', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus, int> syncStatus =
      GeneratedColumn<int>('sync_status', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              defaultValue: Constant(SyncStatus.pending.index))
          .withConverter<SyncStatus>($ReadingsTable.$convertersyncStatus);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
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
  VerificationContext validateIntegrity(Insertable<Reading> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('deck_id')) {
      context.handle(_deckIdMeta,
          deckId.isAcceptableOrUnknown(data['deck_id']!, _deckIdMeta));
    } else if (isInserting) {
      context.missing(_deckIdMeta);
    }
    if (data.containsKey('spread_type')) {
      context.handle(
          _spreadTypeMeta,
          spreadType.isAcceptableOrUnknown(
              data['spread_type']!, _spreadTypeMeta));
    } else if (isInserting) {
      context.missing(_spreadTypeMeta);
    }
    if (data.containsKey('question')) {
      context.handle(_questionMeta,
          question.isAcceptableOrUnknown(data['question']!, _questionMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reading map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reading(
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
      syncStatus: $ReadingsTable.$convertersyncStatus.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sync_status'])!),
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
    );
  }

  @override
  $ReadingsTable createAlias(String alias) {
    return $ReadingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatus, int, int> $convertersyncStatus =
      const EnumIndexConverter<SyncStatus>(SyncStatus.values);
}

class Reading extends DataClass implements Insertable<Reading> {
  final String id;
  final String deckId;
  final String spreadType;
  final String? question;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final int version;
  const Reading(
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
    {
      map['sync_status'] =
          Variable<int>($ReadingsTable.$convertersyncStatus.toSql(syncStatus));
    }
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

  factory Reading.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reading(
      id: serializer.fromJson<String>(json['id']),
      deckId: serializer.fromJson<String>(json['deckId']),
      spreadType: serializer.fromJson<String>(json['spreadType']),
      question: serializer.fromJson<String?>(json['question']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncStatus: $ReadingsTable.$convertersyncStatus
          .fromJson(serializer.fromJson<int>(json['syncStatus'])),
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
      'syncStatus': serializer
          .toJson<int>($ReadingsTable.$convertersyncStatus.toJson(syncStatus)),
      'version': serializer.toJson<int>(version),
    };
  }

  Reading copyWith(
          {String? id,
          String? deckId,
          String? spreadType,
          Value<String?> question = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          SyncStatus? syncStatus,
          int? version}) =>
      Reading(
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
  Reading copyWithCompanion(ReadingsCompanion data) {
    return Reading(
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
    return (StringBuffer('Reading(')
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
      (other is Reading &&
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

class ReadingsCompanion extends UpdateCompanion<Reading> {
  final Value<String> id;
  final Value<String> deckId;
  final Value<String> spreadType;
  final Value<String?> question;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<SyncStatus> syncStatus;
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
  static Insertable<Reading> custom({
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
      Value<SyncStatus>? syncStatus,
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
      map['sync_status'] = Variable<int>(
          $ReadingsTable.$convertersyncStatus.toSql(syncStatus.value));
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

class $DrawnCardsTable extends DrawnCards
    with TableInfo<$DrawnCardsTable, DrawnCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DrawnCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _readingIdMeta =
      const VerificationMeta('readingId');
  @override
  late final GeneratedColumn<String> readingId = GeneratedColumn<String>(
      'reading_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES readings (id) ON DELETE CASCADE'));
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
      'card_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES cards (id) ON DELETE CASCADE'));
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isReversedMeta =
      const VerificationMeta('isReversed');
  @override
  late final GeneratedColumn<bool> isReversed = GeneratedColumn<bool>(
      'is_reversed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_reversed" IN (0, 1))'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
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
  VerificationContext validateIntegrity(Insertable<DrawnCard> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('reading_id')) {
      context.handle(_readingIdMeta,
          readingId.isAcceptableOrUnknown(data['reading_id']!, _readingIdMeta));
    } else if (isInserting) {
      context.missing(_readingIdMeta);
    }
    if (data.containsKey('card_id')) {
      context.handle(_cardIdMeta,
          cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta));
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('is_reversed')) {
      context.handle(
          _isReversedMeta,
          isReversed.isAcceptableOrUnknown(
              data['is_reversed']!, _isReversedMeta));
    } else if (isInserting) {
      context.missing(_isReversedMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DrawnCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DrawnCard(
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
  $DrawnCardsTable createAlias(String alias) {
    return $DrawnCardsTable(attachedDatabase, alias);
  }
}

class DrawnCard extends DataClass implements Insertable<DrawnCard> {
  final String id;
  final String readingId;
  final String cardId;
  final int position;
  final bool isReversed;
  final DateTime createdAt;
  const DrawnCard(
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

  factory DrawnCard.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DrawnCard(
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

  DrawnCard copyWith(
          {String? id,
          String? readingId,
          String? cardId,
          int? position,
          bool? isReversed,
          DateTime? createdAt}) =>
      DrawnCard(
        id: id ?? this.id,
        readingId: readingId ?? this.readingId,
        cardId: cardId ?? this.cardId,
        position: position ?? this.position,
        isReversed: isReversed ?? this.isReversed,
        createdAt: createdAt ?? this.createdAt,
      );
  DrawnCard copyWithCompanion(DrawnCardsCompanion data) {
    return DrawnCard(
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
    return (StringBuffer('DrawnCard(')
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
      (other is DrawnCard &&
          other.id == this.id &&
          other.readingId == this.readingId &&
          other.cardId == this.cardId &&
          other.position == this.position &&
          other.isReversed == this.isReversed &&
          other.createdAt == this.createdAt);
}

class DrawnCardsCompanion extends UpdateCompanion<DrawnCard> {
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
  static Insertable<DrawnCard> custom({
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

class $UserSettingsTableTable extends UserSettingsTable
    with TableInfo<$UserSettingsTableTable, UserSettingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _selectedDeckIdMeta =
      const VerificationMeta('selectedDeckId');
  @override
  late final GeneratedColumn<String> selectedDeckId = GeneratedColumn<String>(
      'selected_deck_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('rws-standard'));
  static const VerificationMeta _experienceLevelMeta =
      const VerificationMeta('experienceLevel');
  @override
  late final GeneratedColumn<int> experienceLevel = GeneratedColumn<int>(
      'experience_level', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(4));
  static const VerificationMeta _defaultCardCountMeta =
      const VerificationMeta('defaultCardCount');
  @override
  late final GeneratedColumn<int> defaultCardCount = GeneratedColumn<int>(
      'default_card_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(3));
  static const VerificationMeta _showFaceUpMeta =
      const VerificationMeta('showFaceUp');
  @override
  late final GeneratedColumn<bool> showFaceUp = GeneratedColumn<bool>(
      'show_face_up', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("show_face_up" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _quickDrawEnabledMeta =
      const VerificationMeta('quickDrawEnabled');
  @override
  late final GeneratedColumn<bool> quickDrawEnabled = GeneratedColumn<bool>(
      'quick_draw_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("quick_draw_enabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _defaultLayoutTypeMeta =
      const VerificationMeta('defaultLayoutType');
  @override
  late final GeneratedColumn<String> defaultLayoutType =
      GeneratedColumn<String>('default_layout_type', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('custom'));
  static const VerificationMeta _showCardNameMeta =
      const VerificationMeta('showCardName');
  @override
  late final GeneratedColumn<bool> showCardName = GeneratedColumn<bool>(
      'show_card_name', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("show_card_name" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _allowReversedMeta =
      const VerificationMeta('allowReversed');
  @override
  late final GeneratedColumn<bool> allowReversed = GeneratedColumn<bool>(
      'allow_reversed', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("allow_reversed" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _cardSizePresetMeta =
      const VerificationMeta('cardSizePreset');
  @override
  late final GeneratedColumn<String> cardSizePreset = GeneratedColumn<String>(
      'card_size_preset', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('standardTarot'));
  static const VerificationMeta _customCardWidthMmMeta =
      const VerificationMeta('customCardWidthMm');
  @override
  late final GeneratedColumn<double> customCardWidthMm =
      GeneratedColumn<double>('custom_card_width_mm', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(70.0));
  static const VerificationMeta _customCardHeightMmMeta =
      const VerificationMeta('customCardHeightMm');
  @override
  late final GeneratedColumn<double> customCardHeightMm =
      GeneratedColumn<double>('custom_card_height_mm', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(120.0));
  static const VerificationMeta _cardsPerRowMeta =
      const VerificationMeta('cardsPerRow');
  @override
  late final GeneratedColumn<int> cardsPerRow = GeneratedColumn<int>(
      'cards_per_row', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(3));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
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
  VerificationContext validateIntegrity(
      Insertable<UserSettingsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('selected_deck_id')) {
      context.handle(
          _selectedDeckIdMeta,
          selectedDeckId.isAcceptableOrUnknown(
              data['selected_deck_id']!, _selectedDeckIdMeta));
    }
    if (data.containsKey('experience_level')) {
      context.handle(
          _experienceLevelMeta,
          experienceLevel.isAcceptableOrUnknown(
              data['experience_level']!, _experienceLevelMeta));
    }
    if (data.containsKey('default_card_count')) {
      context.handle(
          _defaultCardCountMeta,
          defaultCardCount.isAcceptableOrUnknown(
              data['default_card_count']!, _defaultCardCountMeta));
    }
    if (data.containsKey('show_face_up')) {
      context.handle(
          _showFaceUpMeta,
          showFaceUp.isAcceptableOrUnknown(
              data['show_face_up']!, _showFaceUpMeta));
    }
    if (data.containsKey('quick_draw_enabled')) {
      context.handle(
          _quickDrawEnabledMeta,
          quickDrawEnabled.isAcceptableOrUnknown(
              data['quick_draw_enabled']!, _quickDrawEnabledMeta));
    }
    if (data.containsKey('default_layout_type')) {
      context.handle(
          _defaultLayoutTypeMeta,
          defaultLayoutType.isAcceptableOrUnknown(
              data['default_layout_type']!, _defaultLayoutTypeMeta));
    }
    if (data.containsKey('show_card_name')) {
      context.handle(
          _showCardNameMeta,
          showCardName.isAcceptableOrUnknown(
              data['show_card_name']!, _showCardNameMeta));
    }
    if (data.containsKey('allow_reversed')) {
      context.handle(
          _allowReversedMeta,
          allowReversed.isAcceptableOrUnknown(
              data['allow_reversed']!, _allowReversedMeta));
    }
    if (data.containsKey('card_size_preset')) {
      context.handle(
          _cardSizePresetMeta,
          cardSizePreset.isAcceptableOrUnknown(
              data['card_size_preset']!, _cardSizePresetMeta));
    }
    if (data.containsKey('custom_card_width_mm')) {
      context.handle(
          _customCardWidthMmMeta,
          customCardWidthMm.isAcceptableOrUnknown(
              data['custom_card_width_mm']!, _customCardWidthMmMeta));
    }
    if (data.containsKey('custom_card_height_mm')) {
      context.handle(
          _customCardHeightMmMeta,
          customCardHeightMm.isAcceptableOrUnknown(
              data['custom_card_height_mm']!, _customCardHeightMmMeta));
    }
    if (data.containsKey('cards_per_row')) {
      context.handle(
          _cardsPerRowMeta,
          cardsPerRow.isAcceptableOrUnknown(
              data['cards_per_row']!, _cardsPerRowMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserSettingsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserSettingsTableData(
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
  $UserSettingsTableTable createAlias(String alias) {
    return $UserSettingsTableTable(attachedDatabase, alias);
  }
}

class UserSettingsTableData extends DataClass
    implements Insertable<UserSettingsTableData> {
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
  const UserSettingsTableData(
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

  UserSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return UserSettingsTableCompanion(
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

  factory UserSettingsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserSettingsTableData(
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

  UserSettingsTableData copyWith(
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
      UserSettingsTableData(
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
  UserSettingsTableData copyWithCompanion(UserSettingsTableCompanion data) {
    return UserSettingsTableData(
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
    return (StringBuffer('UserSettingsTableData(')
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
      (other is UserSettingsTableData &&
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

class UserSettingsTableCompanion
    extends UpdateCompanion<UserSettingsTableData> {
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
  const UserSettingsTableCompanion({
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
  UserSettingsTableCompanion.insert({
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
  static Insertable<UserSettingsTableData> custom({
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

  UserSettingsTableCompanion copyWith(
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
    return UserSettingsTableCompanion(
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
    return (StringBuffer('UserSettingsTableCompanion(')
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DecksTable decks = $DecksTable(this);
  late final $CardsTable cards = $CardsTable(this);
  late final $ReadingsTable readings = $ReadingsTable(this);
  late final $DrawnCardsTable drawnCards = $DrawnCardsTable(this);
  late final $UserSettingsTableTable userSettingsTable =
      $UserSettingsTableTable(this);
  late final DeckDao deckDao = DeckDao(this as AppDatabase);
  late final CardDao cardDao = CardDao(this as AppDatabase);
  late final ReadingDao readingDao = ReadingDao(this as AppDatabase);
  late final UserSettingsDao userSettingsDao =
      UserSettingsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [decks, cards, readings, drawnCards, userSettingsTable];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('decks',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('cards', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('readings',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('drawn_cards', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('cards',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('drawn_cards', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$DecksTableCreateCompanionBuilder = DecksCompanion Function({
  required String id,
  required String name,
  Value<bool> isStandardTarot,
  required int totalCards,
  Value<String?> creator,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<SyncStatus> syncStatus,
  Value<int> version,
  Value<int> rowid,
});
typedef $$DecksTableUpdateCompanionBuilder = DecksCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<bool> isStandardTarot,
  Value<int> totalCards,
  Value<String?> creator,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<SyncStatus> syncStatus,
  Value<int> version,
  Value<int> rowid,
});

final class $$DecksTableReferences
    extends BaseReferences<_$AppDatabase, $DecksTable, Deck> {
  $$DecksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CardsTable, List<Card>> _cardsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.cards,
          aliasName: $_aliasNameGenerator(db.decks.id, db.cards.deckId));

  $$CardsTableProcessedTableManager get cardsRefs {
    final manager = $$CardsTableTableManager($_db, $_db.cards)
        .filter((f) => f.deckId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cardsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ReadingsTable, List<Reading>> _readingsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.readings,
          aliasName: $_aliasNameGenerator(db.decks.id, db.readings.deckId));

  $$ReadingsTableProcessedTableManager get readingsRefs {
    final manager = $$ReadingsTableTableManager($_db, $_db.readings)
        .filter((f) => f.deckId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_readingsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$DecksTableFilterComposer extends Composer<_$AppDatabase, $DecksTable> {
  $$DecksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isStandardTarot => $composableBuilder(
      column: $table.isStandardTarot,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalCards => $composableBuilder(
      column: $table.totalCards, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get creator => $composableBuilder(
      column: $table.creator, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, int> get syncStatus =>
      $composableBuilder(
          column: $table.syncStatus,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  Expression<bool> cardsRefs(
      Expression<bool> Function($$CardsTableFilterComposer f) f) {
    final $$CardsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cards,
        getReferencedColumn: (t) => t.deckId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardsTableFilterComposer(
              $db: $db,
              $table: $db.cards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> readingsRefs(
      Expression<bool> Function($$ReadingsTableFilterComposer f) f) {
    final $$ReadingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.readings,
        getReferencedColumn: (t) => t.deckId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReadingsTableFilterComposer(
              $db: $db,
              $table: $db.readings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DecksTableOrderingComposer
    extends Composer<_$AppDatabase, $DecksTable> {
  $$DecksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isStandardTarot => $composableBuilder(
      column: $table.isStandardTarot,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalCards => $composableBuilder(
      column: $table.totalCards, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get creator => $composableBuilder(
      column: $table.creator, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));
}

class $$DecksTableAnnotationComposer
    extends Composer<_$AppDatabase, $DecksTable> {
  $$DecksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isStandardTarot => $composableBuilder(
      column: $table.isStandardTarot, builder: (column) => column);

  GeneratedColumn<int> get totalCards => $composableBuilder(
      column: $table.totalCards, builder: (column) => column);

  GeneratedColumn<String> get creator =>
      $composableBuilder(column: $table.creator, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatus, int> get syncStatus =>
      $composableBuilder(
          column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  Expression<T> cardsRefs<T extends Object>(
      Expression<T> Function($$CardsTableAnnotationComposer a) f) {
    final $$CardsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cards,
        getReferencedColumn: (t) => t.deckId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardsTableAnnotationComposer(
              $db: $db,
              $table: $db.cards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> readingsRefs<T extends Object>(
      Expression<T> Function($$ReadingsTableAnnotationComposer a) f) {
    final $$ReadingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.readings,
        getReferencedColumn: (t) => t.deckId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReadingsTableAnnotationComposer(
              $db: $db,
              $table: $db.readings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DecksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DecksTable,
    Deck,
    $$DecksTableFilterComposer,
    $$DecksTableOrderingComposer,
    $$DecksTableAnnotationComposer,
    $$DecksTableCreateCompanionBuilder,
    $$DecksTableUpdateCompanionBuilder,
    (Deck, $$DecksTableReferences),
    Deck,
    PrefetchHooks Function({bool cardsRefs, bool readingsRefs})> {
  $$DecksTableTableManager(_$AppDatabase db, $DecksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DecksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DecksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DecksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<bool> isStandardTarot = const Value.absent(),
            Value<int> totalCards = const Value.absent(),
            Value<String?> creator = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<SyncStatus> syncStatus = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DecksCompanion(
            id: id,
            name: name,
            isStandardTarot: isStandardTarot,
            totalCards: totalCards,
            creator: creator,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: syncStatus,
            version: version,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<bool> isStandardTarot = const Value.absent(),
            required int totalCards,
            Value<String?> creator = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<SyncStatus> syncStatus = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DecksCompanion.insert(
            id: id,
            name: name,
            isStandardTarot: isStandardTarot,
            totalCards: totalCards,
            creator: creator,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: syncStatus,
            version: version,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$DecksTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({cardsRefs = false, readingsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (cardsRefs) db.cards,
                if (readingsRefs) db.readings
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cardsRefs)
                    await $_getPrefetchedData<Deck, $DecksTable, Card>(
                        currentTable: table,
                        referencedTable:
                            $$DecksTableReferences._cardsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DecksTableReferences(db, table, p0).cardsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.deckId == item.id),
                        typedResults: items),
                  if (readingsRefs)
                    await $_getPrefetchedData<Deck, $DecksTable, Reading>(
                        currentTable: table,
                        referencedTable:
                            $$DecksTableReferences._readingsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DecksTableReferences(db, table, p0).readingsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.deckId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$DecksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DecksTable,
    Deck,
    $$DecksTableFilterComposer,
    $$DecksTableOrderingComposer,
    $$DecksTableAnnotationComposer,
    $$DecksTableCreateCompanionBuilder,
    $$DecksTableUpdateCompanionBuilder,
    (Deck, $$DecksTableReferences),
    Deck,
    PrefetchHooks Function({bool cardsRefs, bool readingsRefs})>;
typedef $$CardsTableCreateCompanionBuilder = CardsCompanion Function({
  required String id,
  required String deckId,
  required String cardId,
  required String name,
  required String arcana,
  Value<String?> suit,
  required int number,
  required String imagePath,
  required CardMeanings meanings,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<SyncStatus> syncStatus,
  Value<int> rowid,
});
typedef $$CardsTableUpdateCompanionBuilder = CardsCompanion Function({
  Value<String> id,
  Value<String> deckId,
  Value<String> cardId,
  Value<String> name,
  Value<String> arcana,
  Value<String?> suit,
  Value<int> number,
  Value<String> imagePath,
  Value<CardMeanings> meanings,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<SyncStatus> syncStatus,
  Value<int> rowid,
});

final class $$CardsTableReferences
    extends BaseReferences<_$AppDatabase, $CardsTable, Card> {
  $$CardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DecksTable _deckIdTable(_$AppDatabase db) =>
      db.decks.createAlias($_aliasNameGenerator(db.cards.deckId, db.decks.id));

  $$DecksTableProcessedTableManager get deckId {
    final $_column = $_itemColumn<String>('deck_id')!;

    final manager = $$DecksTableTableManager($_db, $_db.decks)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deckIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$DrawnCardsTable, List<DrawnCard>>
      _drawnCardsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.drawnCards,
          aliasName: $_aliasNameGenerator(db.cards.id, db.drawnCards.cardId));

  $$DrawnCardsTableProcessedTableManager get drawnCardsRefs {
    final manager = $$DrawnCardsTableTableManager($_db, $_db.drawnCards)
        .filter((f) => f.cardId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_drawnCardsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CardsTableFilterComposer extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cardId => $composableBuilder(
      column: $table.cardId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get arcana => $composableBuilder(
      column: $table.arcana, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get suit => $composableBuilder(
      column: $table.suit, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get number => $composableBuilder(
      column: $table.number, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<CardMeanings, CardMeanings, String>
      get meanings => $composableBuilder(
          column: $table.meanings,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, int> get syncStatus =>
      $composableBuilder(
          column: $table.syncStatus,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  $$DecksTableFilterComposer get deckId {
    final $$DecksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.deckId,
        referencedTable: $db.decks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DecksTableFilterComposer(
              $db: $db,
              $table: $db.decks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> drawnCardsRefs(
      Expression<bool> Function($$DrawnCardsTableFilterComposer f) f) {
    final $$DrawnCardsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.drawnCards,
        getReferencedColumn: (t) => t.cardId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DrawnCardsTableFilterComposer(
              $db: $db,
              $table: $db.drawnCards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CardsTableOrderingComposer
    extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cardId => $composableBuilder(
      column: $table.cardId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get arcana => $composableBuilder(
      column: $table.arcana, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get suit => $composableBuilder(
      column: $table.suit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get number => $composableBuilder(
      column: $table.number, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get meanings => $composableBuilder(
      column: $table.meanings, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  $$DecksTableOrderingComposer get deckId {
    final $$DecksTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.deckId,
        referencedTable: $db.decks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DecksTableOrderingComposer(
              $db: $db,
              $table: $db.decks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cardId =>
      $composableBuilder(column: $table.cardId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get arcana =>
      $composableBuilder(column: $table.arcana, builder: (column) => column);

  GeneratedColumn<String> get suit =>
      $composableBuilder(column: $table.suit, builder: (column) => column);

  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CardMeanings, String> get meanings =>
      $composableBuilder(column: $table.meanings, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatus, int> get syncStatus =>
      $composableBuilder(
          column: $table.syncStatus, builder: (column) => column);

  $$DecksTableAnnotationComposer get deckId {
    final $$DecksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.deckId,
        referencedTable: $db.decks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DecksTableAnnotationComposer(
              $db: $db,
              $table: $db.decks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> drawnCardsRefs<T extends Object>(
      Expression<T> Function($$DrawnCardsTableAnnotationComposer a) f) {
    final $$DrawnCardsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.drawnCards,
        getReferencedColumn: (t) => t.cardId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DrawnCardsTableAnnotationComposer(
              $db: $db,
              $table: $db.drawnCards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CardsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CardsTable,
    Card,
    $$CardsTableFilterComposer,
    $$CardsTableOrderingComposer,
    $$CardsTableAnnotationComposer,
    $$CardsTableCreateCompanionBuilder,
    $$CardsTableUpdateCompanionBuilder,
    (Card, $$CardsTableReferences),
    Card,
    PrefetchHooks Function({bool deckId, bool drawnCardsRefs})> {
  $$CardsTableTableManager(_$AppDatabase db, $CardsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> deckId = const Value.absent(),
            Value<String> cardId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> arcana = const Value.absent(),
            Value<String?> suit = const Value.absent(),
            Value<int> number = const Value.absent(),
            Value<String> imagePath = const Value.absent(),
            Value<CardMeanings> meanings = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<SyncStatus> syncStatus = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CardsCompanion(
            id: id,
            deckId: deckId,
            cardId: cardId,
            name: name,
            arcana: arcana,
            suit: suit,
            number: number,
            imagePath: imagePath,
            meanings: meanings,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: syncStatus,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String deckId,
            required String cardId,
            required String name,
            required String arcana,
            Value<String?> suit = const Value.absent(),
            required int number,
            required String imagePath,
            required CardMeanings meanings,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<SyncStatus> syncStatus = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CardsCompanion.insert(
            id: id,
            deckId: deckId,
            cardId: cardId,
            name: name,
            arcana: arcana,
            suit: suit,
            number: number,
            imagePath: imagePath,
            meanings: meanings,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: syncStatus,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$CardsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({deckId = false, drawnCardsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (drawnCardsRefs) db.drawnCards],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (deckId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.deckId,
                    referencedTable: $$CardsTableReferences._deckIdTable(db),
                    referencedColumn:
                        $$CardsTableReferences._deckIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (drawnCardsRefs)
                    await $_getPrefetchedData<Card, $CardsTable, DrawnCard>(
                        currentTable: table,
                        referencedTable:
                            $$CardsTableReferences._drawnCardsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CardsTableReferences(db, table, p0)
                                .drawnCardsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.cardId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CardsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CardsTable,
    Card,
    $$CardsTableFilterComposer,
    $$CardsTableOrderingComposer,
    $$CardsTableAnnotationComposer,
    $$CardsTableCreateCompanionBuilder,
    $$CardsTableUpdateCompanionBuilder,
    (Card, $$CardsTableReferences),
    Card,
    PrefetchHooks Function({bool deckId, bool drawnCardsRefs})>;
typedef $$ReadingsTableCreateCompanionBuilder = ReadingsCompanion Function({
  required String id,
  required String deckId,
  required String spreadType,
  Value<String?> question,
  Value<String?> notes,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<SyncStatus> syncStatus,
  Value<int> version,
  Value<int> rowid,
});
typedef $$ReadingsTableUpdateCompanionBuilder = ReadingsCompanion Function({
  Value<String> id,
  Value<String> deckId,
  Value<String> spreadType,
  Value<String?> question,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<SyncStatus> syncStatus,
  Value<int> version,
  Value<int> rowid,
});

final class $$ReadingsTableReferences
    extends BaseReferences<_$AppDatabase, $ReadingsTable, Reading> {
  $$ReadingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DecksTable _deckIdTable(_$AppDatabase db) => db.decks
      .createAlias($_aliasNameGenerator(db.readings.deckId, db.decks.id));

  $$DecksTableProcessedTableManager get deckId {
    final $_column = $_itemColumn<String>('deck_id')!;

    final manager = $$DecksTableTableManager($_db, $_db.decks)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deckIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$DrawnCardsTable, List<DrawnCard>>
      _drawnCardsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.drawnCards,
          aliasName:
              $_aliasNameGenerator(db.readings.id, db.drawnCards.readingId));

  $$DrawnCardsTableProcessedTableManager get drawnCardsRefs {
    final manager = $$DrawnCardsTableTableManager($_db, $_db.drawnCards)
        .filter((f) => f.readingId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_drawnCardsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ReadingsTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingsTable> {
  $$ReadingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get spreadType => $composableBuilder(
      column: $table.spreadType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get question => $composableBuilder(
      column: $table.question, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, int> get syncStatus =>
      $composableBuilder(
          column: $table.syncStatus,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  $$DecksTableFilterComposer get deckId {
    final $$DecksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.deckId,
        referencedTable: $db.decks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DecksTableFilterComposer(
              $db: $db,
              $table: $db.decks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> drawnCardsRefs(
      Expression<bool> Function($$DrawnCardsTableFilterComposer f) f) {
    final $$DrawnCardsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.drawnCards,
        getReferencedColumn: (t) => t.readingId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DrawnCardsTableFilterComposer(
              $db: $db,
              $table: $db.drawnCards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ReadingsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingsTable> {
  $$ReadingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get spreadType => $composableBuilder(
      column: $table.spreadType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get question => $composableBuilder(
      column: $table.question, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  $$DecksTableOrderingComposer get deckId {
    final $$DecksTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.deckId,
        referencedTable: $db.decks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DecksTableOrderingComposer(
              $db: $db,
              $table: $db.decks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReadingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingsTable> {
  $$ReadingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get spreadType => $composableBuilder(
      column: $table.spreadType, builder: (column) => column);

  GeneratedColumn<String> get question =>
      $composableBuilder(column: $table.question, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatus, int> get syncStatus =>
      $composableBuilder(
          column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  $$DecksTableAnnotationComposer get deckId {
    final $$DecksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.deckId,
        referencedTable: $db.decks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DecksTableAnnotationComposer(
              $db: $db,
              $table: $db.decks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> drawnCardsRefs<T extends Object>(
      Expression<T> Function($$DrawnCardsTableAnnotationComposer a) f) {
    final $$DrawnCardsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.drawnCards,
        getReferencedColumn: (t) => t.readingId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DrawnCardsTableAnnotationComposer(
              $db: $db,
              $table: $db.drawnCards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ReadingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReadingsTable,
    Reading,
    $$ReadingsTableFilterComposer,
    $$ReadingsTableOrderingComposer,
    $$ReadingsTableAnnotationComposer,
    $$ReadingsTableCreateCompanionBuilder,
    $$ReadingsTableUpdateCompanionBuilder,
    (Reading, $$ReadingsTableReferences),
    Reading,
    PrefetchHooks Function({bool deckId, bool drawnCardsRefs})> {
  $$ReadingsTableTableManager(_$AppDatabase db, $ReadingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> deckId = const Value.absent(),
            Value<String> spreadType = const Value.absent(),
            Value<String?> question = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<SyncStatus> syncStatus = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReadingsCompanion(
            id: id,
            deckId: deckId,
            spreadType: spreadType,
            question: question,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: syncStatus,
            version: version,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String deckId,
            required String spreadType,
            Value<String?> question = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<SyncStatus> syncStatus = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReadingsCompanion.insert(
            id: id,
            deckId: deckId,
            spreadType: spreadType,
            question: question,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: syncStatus,
            version: version,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ReadingsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({deckId = false, drawnCardsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (drawnCardsRefs) db.drawnCards],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (deckId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.deckId,
                    referencedTable: $$ReadingsTableReferences._deckIdTable(db),
                    referencedColumn:
                        $$ReadingsTableReferences._deckIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (drawnCardsRefs)
                    await $_getPrefetchedData<Reading, $ReadingsTable,
                            DrawnCard>(
                        currentTable: table,
                        referencedTable:
                            $$ReadingsTableReferences._drawnCardsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ReadingsTableReferences(db, table, p0)
                                .drawnCardsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.readingId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ReadingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ReadingsTable,
    Reading,
    $$ReadingsTableFilterComposer,
    $$ReadingsTableOrderingComposer,
    $$ReadingsTableAnnotationComposer,
    $$ReadingsTableCreateCompanionBuilder,
    $$ReadingsTableUpdateCompanionBuilder,
    (Reading, $$ReadingsTableReferences),
    Reading,
    PrefetchHooks Function({bool deckId, bool drawnCardsRefs})>;
typedef $$DrawnCardsTableCreateCompanionBuilder = DrawnCardsCompanion Function({
  required String id,
  required String readingId,
  required String cardId,
  required int position,
  required bool isReversed,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$DrawnCardsTableUpdateCompanionBuilder = DrawnCardsCompanion Function({
  Value<String> id,
  Value<String> readingId,
  Value<String> cardId,
  Value<int> position,
  Value<bool> isReversed,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$DrawnCardsTableReferences
    extends BaseReferences<_$AppDatabase, $DrawnCardsTable, DrawnCard> {
  $$DrawnCardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ReadingsTable _readingIdTable(_$AppDatabase db) =>
      db.readings.createAlias(
          $_aliasNameGenerator(db.drawnCards.readingId, db.readings.id));

  $$ReadingsTableProcessedTableManager get readingId {
    final $_column = $_itemColumn<String>('reading_id')!;

    final manager = $$ReadingsTableTableManager($_db, $_db.readings)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_readingIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CardsTable _cardIdTable(_$AppDatabase db) => db.cards
      .createAlias($_aliasNameGenerator(db.drawnCards.cardId, db.cards.id));

  $$CardsTableProcessedTableManager get cardId {
    final $_column = $_itemColumn<String>('card_id')!;

    final manager = $$CardsTableTableManager($_db, $_db.cards)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$DrawnCardsTableFilterComposer
    extends Composer<_$AppDatabase, $DrawnCardsTable> {
  $$DrawnCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isReversed => $composableBuilder(
      column: $table.isReversed, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$ReadingsTableFilterComposer get readingId {
    final $$ReadingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.readingId,
        referencedTable: $db.readings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReadingsTableFilterComposer(
              $db: $db,
              $table: $db.readings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CardsTableFilterComposer get cardId {
    final $$CardsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cardId,
        referencedTable: $db.cards,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardsTableFilterComposer(
              $db: $db,
              $table: $db.cards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DrawnCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $DrawnCardsTable> {
  $$DrawnCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isReversed => $composableBuilder(
      column: $table.isReversed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$ReadingsTableOrderingComposer get readingId {
    final $$ReadingsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.readingId,
        referencedTable: $db.readings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReadingsTableOrderingComposer(
              $db: $db,
              $table: $db.readings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CardsTableOrderingComposer get cardId {
    final $$CardsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cardId,
        referencedTable: $db.cards,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardsTableOrderingComposer(
              $db: $db,
              $table: $db.cards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DrawnCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DrawnCardsTable> {
  $$DrawnCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<bool> get isReversed => $composableBuilder(
      column: $table.isReversed, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ReadingsTableAnnotationComposer get readingId {
    final $$ReadingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.readingId,
        referencedTable: $db.readings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReadingsTableAnnotationComposer(
              $db: $db,
              $table: $db.readings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CardsTableAnnotationComposer get cardId {
    final $$CardsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cardId,
        referencedTable: $db.cards,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardsTableAnnotationComposer(
              $db: $db,
              $table: $db.cards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DrawnCardsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DrawnCardsTable,
    DrawnCard,
    $$DrawnCardsTableFilterComposer,
    $$DrawnCardsTableOrderingComposer,
    $$DrawnCardsTableAnnotationComposer,
    $$DrawnCardsTableCreateCompanionBuilder,
    $$DrawnCardsTableUpdateCompanionBuilder,
    (DrawnCard, $$DrawnCardsTableReferences),
    DrawnCard,
    PrefetchHooks Function({bool readingId, bool cardId})> {
  $$DrawnCardsTableTableManager(_$AppDatabase db, $DrawnCardsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DrawnCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DrawnCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DrawnCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> readingId = const Value.absent(),
            Value<String> cardId = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<bool> isReversed = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DrawnCardsCompanion(
            id: id,
            readingId: readingId,
            cardId: cardId,
            position: position,
            isReversed: isReversed,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String readingId,
            required String cardId,
            required int position,
            required bool isReversed,
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DrawnCardsCompanion.insert(
            id: id,
            readingId: readingId,
            cardId: cardId,
            position: position,
            isReversed: isReversed,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DrawnCardsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({readingId = false, cardId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (readingId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.readingId,
                    referencedTable:
                        $$DrawnCardsTableReferences._readingIdTable(db),
                    referencedColumn:
                        $$DrawnCardsTableReferences._readingIdTable(db).id,
                  ) as T;
                }
                if (cardId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.cardId,
                    referencedTable:
                        $$DrawnCardsTableReferences._cardIdTable(db),
                    referencedColumn:
                        $$DrawnCardsTableReferences._cardIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$DrawnCardsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DrawnCardsTable,
    DrawnCard,
    $$DrawnCardsTableFilterComposer,
    $$DrawnCardsTableOrderingComposer,
    $$DrawnCardsTableAnnotationComposer,
    $$DrawnCardsTableCreateCompanionBuilder,
    $$DrawnCardsTableUpdateCompanionBuilder,
    (DrawnCard, $$DrawnCardsTableReferences),
    DrawnCard,
    PrefetchHooks Function({bool readingId, bool cardId})>;
typedef $$UserSettingsTableTableCreateCompanionBuilder
    = UserSettingsTableCompanion Function({
  Value<int> id,
  Value<String> selectedDeckId,
  Value<int> experienceLevel,
  Value<int> defaultCardCount,
  Value<bool> showFaceUp,
  Value<bool> quickDrawEnabled,
  Value<String> defaultLayoutType,
  Value<bool?> showCardName,
  Value<bool?> allowReversed,
  Value<String> cardSizePreset,
  Value<double> customCardWidthMm,
  Value<double> customCardHeightMm,
  Value<int?> cardsPerRow,
  required DateTime updatedAt,
});
typedef $$UserSettingsTableTableUpdateCompanionBuilder
    = UserSettingsTableCompanion Function({
  Value<int> id,
  Value<String> selectedDeckId,
  Value<int> experienceLevel,
  Value<int> defaultCardCount,
  Value<bool> showFaceUp,
  Value<bool> quickDrawEnabled,
  Value<String> defaultLayoutType,
  Value<bool?> showCardName,
  Value<bool?> allowReversed,
  Value<String> cardSizePreset,
  Value<double> customCardWidthMm,
  Value<double> customCardHeightMm,
  Value<int?> cardsPerRow,
  Value<DateTime> updatedAt,
});

class $$UserSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $UserSettingsTableTable> {
  $$UserSettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get selectedDeckId => $composableBuilder(
      column: $table.selectedDeckId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get experienceLevel => $composableBuilder(
      column: $table.experienceLevel,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get defaultCardCount => $composableBuilder(
      column: $table.defaultCardCount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get showFaceUp => $composableBuilder(
      column: $table.showFaceUp, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get quickDrawEnabled => $composableBuilder(
      column: $table.quickDrawEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get defaultLayoutType => $composableBuilder(
      column: $table.defaultLayoutType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get showCardName => $composableBuilder(
      column: $table.showCardName, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get allowReversed => $composableBuilder(
      column: $table.allowReversed, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cardSizePreset => $composableBuilder(
      column: $table.cardSizePreset,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get customCardWidthMm => $composableBuilder(
      column: $table.customCardWidthMm,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get customCardHeightMm => $composableBuilder(
      column: $table.customCardHeightMm,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cardsPerRow => $composableBuilder(
      column: $table.cardsPerRow, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$UserSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $UserSettingsTableTable> {
  $$UserSettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get selectedDeckId => $composableBuilder(
      column: $table.selectedDeckId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get experienceLevel => $composableBuilder(
      column: $table.experienceLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get defaultCardCount => $composableBuilder(
      column: $table.defaultCardCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get showFaceUp => $composableBuilder(
      column: $table.showFaceUp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get quickDrawEnabled => $composableBuilder(
      column: $table.quickDrawEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get defaultLayoutType => $composableBuilder(
      column: $table.defaultLayoutType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get showCardName => $composableBuilder(
      column: $table.showCardName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get allowReversed => $composableBuilder(
      column: $table.allowReversed,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cardSizePreset => $composableBuilder(
      column: $table.cardSizePreset,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get customCardWidthMm => $composableBuilder(
      column: $table.customCardWidthMm,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get customCardHeightMm => $composableBuilder(
      column: $table.customCardHeightMm,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cardsPerRow => $composableBuilder(
      column: $table.cardsPerRow, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$UserSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserSettingsTableTable> {
  $$UserSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get selectedDeckId => $composableBuilder(
      column: $table.selectedDeckId, builder: (column) => column);

  GeneratedColumn<int> get experienceLevel => $composableBuilder(
      column: $table.experienceLevel, builder: (column) => column);

  GeneratedColumn<int> get defaultCardCount => $composableBuilder(
      column: $table.defaultCardCount, builder: (column) => column);

  GeneratedColumn<bool> get showFaceUp => $composableBuilder(
      column: $table.showFaceUp, builder: (column) => column);

  GeneratedColumn<bool> get quickDrawEnabled => $composableBuilder(
      column: $table.quickDrawEnabled, builder: (column) => column);

  GeneratedColumn<String> get defaultLayoutType => $composableBuilder(
      column: $table.defaultLayoutType, builder: (column) => column);

  GeneratedColumn<bool> get showCardName => $composableBuilder(
      column: $table.showCardName, builder: (column) => column);

  GeneratedColumn<bool> get allowReversed => $composableBuilder(
      column: $table.allowReversed, builder: (column) => column);

  GeneratedColumn<String> get cardSizePreset => $composableBuilder(
      column: $table.cardSizePreset, builder: (column) => column);

  GeneratedColumn<double> get customCardWidthMm => $composableBuilder(
      column: $table.customCardWidthMm, builder: (column) => column);

  GeneratedColumn<double> get customCardHeightMm => $composableBuilder(
      column: $table.customCardHeightMm, builder: (column) => column);

  GeneratedColumn<int> get cardsPerRow => $composableBuilder(
      column: $table.cardsPerRow, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserSettingsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserSettingsTableTable,
    UserSettingsTableData,
    $$UserSettingsTableTableFilterComposer,
    $$UserSettingsTableTableOrderingComposer,
    $$UserSettingsTableTableAnnotationComposer,
    $$UserSettingsTableTableCreateCompanionBuilder,
    $$UserSettingsTableTableUpdateCompanionBuilder,
    (
      UserSettingsTableData,
      BaseReferences<_$AppDatabase, $UserSettingsTableTable,
          UserSettingsTableData>
    ),
    UserSettingsTableData,
    PrefetchHooks Function()> {
  $$UserSettingsTableTableTableManager(
      _$AppDatabase db, $UserSettingsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserSettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserSettingsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> selectedDeckId = const Value.absent(),
            Value<int> experienceLevel = const Value.absent(),
            Value<int> defaultCardCount = const Value.absent(),
            Value<bool> showFaceUp = const Value.absent(),
            Value<bool> quickDrawEnabled = const Value.absent(),
            Value<String> defaultLayoutType = const Value.absent(),
            Value<bool?> showCardName = const Value.absent(),
            Value<bool?> allowReversed = const Value.absent(),
            Value<String> cardSizePreset = const Value.absent(),
            Value<double> customCardWidthMm = const Value.absent(),
            Value<double> customCardHeightMm = const Value.absent(),
            Value<int?> cardsPerRow = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              UserSettingsTableCompanion(
            id: id,
            selectedDeckId: selectedDeckId,
            experienceLevel: experienceLevel,
            defaultCardCount: defaultCardCount,
            showFaceUp: showFaceUp,
            quickDrawEnabled: quickDrawEnabled,
            defaultLayoutType: defaultLayoutType,
            showCardName: showCardName,
            allowReversed: allowReversed,
            cardSizePreset: cardSizePreset,
            customCardWidthMm: customCardWidthMm,
            customCardHeightMm: customCardHeightMm,
            cardsPerRow: cardsPerRow,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> selectedDeckId = const Value.absent(),
            Value<int> experienceLevel = const Value.absent(),
            Value<int> defaultCardCount = const Value.absent(),
            Value<bool> showFaceUp = const Value.absent(),
            Value<bool> quickDrawEnabled = const Value.absent(),
            Value<String> defaultLayoutType = const Value.absent(),
            Value<bool?> showCardName = const Value.absent(),
            Value<bool?> allowReversed = const Value.absent(),
            Value<String> cardSizePreset = const Value.absent(),
            Value<double> customCardWidthMm = const Value.absent(),
            Value<double> customCardHeightMm = const Value.absent(),
            Value<int?> cardsPerRow = const Value.absent(),
            required DateTime updatedAt,
          }) =>
              UserSettingsTableCompanion.insert(
            id: id,
            selectedDeckId: selectedDeckId,
            experienceLevel: experienceLevel,
            defaultCardCount: defaultCardCount,
            showFaceUp: showFaceUp,
            quickDrawEnabled: quickDrawEnabled,
            defaultLayoutType: defaultLayoutType,
            showCardName: showCardName,
            allowReversed: allowReversed,
            cardSizePreset: cardSizePreset,
            customCardWidthMm: customCardWidthMm,
            customCardHeightMm: customCardHeightMm,
            cardsPerRow: cardsPerRow,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UserSettingsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserSettingsTableTable,
    UserSettingsTableData,
    $$UserSettingsTableTableFilterComposer,
    $$UserSettingsTableTableOrderingComposer,
    $$UserSettingsTableTableAnnotationComposer,
    $$UserSettingsTableTableCreateCompanionBuilder,
    $$UserSettingsTableTableUpdateCompanionBuilder,
    (
      UserSettingsTableData,
      BaseReferences<_$AppDatabase, $UserSettingsTableTable,
          UserSettingsTableData>
    ),
    UserSettingsTableData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DecksTableTableManager get decks =>
      $$DecksTableTableManager(_db, _db.decks);
  $$CardsTableTableManager get cards =>
      $$CardsTableTableManager(_db, _db.cards);
  $$ReadingsTableTableManager get readings =>
      $$ReadingsTableTableManager(_db, _db.readings);
  $$DrawnCardsTableTableManager get drawnCards =>
      $$DrawnCardsTableTableManager(_db, _db.drawnCards);
  $$UserSettingsTableTableTableManager get userSettingsTable =>
      $$UserSettingsTableTableTableManager(_db, _db.userSettingsTable);
}
