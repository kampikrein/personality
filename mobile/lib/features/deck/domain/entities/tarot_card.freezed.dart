// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tarot_card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TarotCard _$TarotCardFromJson(Map<String, dynamic> json) {
  return _TarotCard.fromJson(json);
}

/// @nodoc
mixin _$TarotCard {
  String get id => throw _privateConstructorUsedError;
  String get deckId => throw _privateConstructorUsedError;
  String get cardId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get arcana => throw _privateConstructorUsedError;
  String? get suit => throw _privateConstructorUsedError;
  int get number => throw _privateConstructorUsedError;
  String get imagePath => throw _privateConstructorUsedError;
  CardMeanings get meanings => throw _privateConstructorUsedError;

  /// Serializes this TarotCard to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TarotCard
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TarotCardCopyWith<TarotCard> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TarotCardCopyWith<$Res> {
  factory $TarotCardCopyWith(TarotCard value, $Res Function(TarotCard) then) =
      _$TarotCardCopyWithImpl<$Res, TarotCard>;
  @useResult
  $Res call(
      {String id,
      String deckId,
      String cardId,
      String name,
      String arcana,
      String? suit,
      int number,
      String imagePath,
      CardMeanings meanings});

  $CardMeaningsCopyWith<$Res> get meanings;
}

/// @nodoc
class _$TarotCardCopyWithImpl<$Res, $Val extends TarotCard>
    implements $TarotCardCopyWith<$Res> {
  _$TarotCardCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TarotCard
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? deckId = null,
    Object? cardId = null,
    Object? name = null,
    Object? arcana = null,
    Object? suit = freezed,
    Object? number = null,
    Object? imagePath = null,
    Object? meanings = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      deckId: null == deckId
          ? _value.deckId
          : deckId // ignore: cast_nullable_to_non_nullable
              as String,
      cardId: null == cardId
          ? _value.cardId
          : cardId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      arcana: null == arcana
          ? _value.arcana
          : arcana // ignore: cast_nullable_to_non_nullable
              as String,
      suit: freezed == suit
          ? _value.suit
          : suit // ignore: cast_nullable_to_non_nullable
              as String?,
      number: null == number
          ? _value.number
          : number // ignore: cast_nullable_to_non_nullable
              as int,
      imagePath: null == imagePath
          ? _value.imagePath
          : imagePath // ignore: cast_nullable_to_non_nullable
              as String,
      meanings: null == meanings
          ? _value.meanings
          : meanings // ignore: cast_nullable_to_non_nullable
              as CardMeanings,
    ) as $Val);
  }

  /// Create a copy of TarotCard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CardMeaningsCopyWith<$Res> get meanings {
    return $CardMeaningsCopyWith<$Res>(_value.meanings, (value) {
      return _then(_value.copyWith(meanings: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TarotCardImplCopyWith<$Res>
    implements $TarotCardCopyWith<$Res> {
  factory _$$TarotCardImplCopyWith(
          _$TarotCardImpl value, $Res Function(_$TarotCardImpl) then) =
      __$$TarotCardImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String deckId,
      String cardId,
      String name,
      String arcana,
      String? suit,
      int number,
      String imagePath,
      CardMeanings meanings});

  @override
  $CardMeaningsCopyWith<$Res> get meanings;
}

/// @nodoc
class __$$TarotCardImplCopyWithImpl<$Res>
    extends _$TarotCardCopyWithImpl<$Res, _$TarotCardImpl>
    implements _$$TarotCardImplCopyWith<$Res> {
  __$$TarotCardImplCopyWithImpl(
      _$TarotCardImpl _value, $Res Function(_$TarotCardImpl) _then)
      : super(_value, _then);

  /// Create a copy of TarotCard
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? deckId = null,
    Object? cardId = null,
    Object? name = null,
    Object? arcana = null,
    Object? suit = freezed,
    Object? number = null,
    Object? imagePath = null,
    Object? meanings = null,
  }) {
    return _then(_$TarotCardImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      deckId: null == deckId
          ? _value.deckId
          : deckId // ignore: cast_nullable_to_non_nullable
              as String,
      cardId: null == cardId
          ? _value.cardId
          : cardId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      arcana: null == arcana
          ? _value.arcana
          : arcana // ignore: cast_nullable_to_non_nullable
              as String,
      suit: freezed == suit
          ? _value.suit
          : suit // ignore: cast_nullable_to_non_nullable
              as String?,
      number: null == number
          ? _value.number
          : number // ignore: cast_nullable_to_non_nullable
              as int,
      imagePath: null == imagePath
          ? _value.imagePath
          : imagePath // ignore: cast_nullable_to_non_nullable
              as String,
      meanings: null == meanings
          ? _value.meanings
          : meanings // ignore: cast_nullable_to_non_nullable
              as CardMeanings,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TarotCardImpl implements _TarotCard {
  const _$TarotCardImpl(
      {required this.id,
      required this.deckId,
      required this.cardId,
      required this.name,
      required this.arcana,
      this.suit,
      required this.number,
      required this.imagePath,
      required this.meanings});

  factory _$TarotCardImpl.fromJson(Map<String, dynamic> json) =>
      _$$TarotCardImplFromJson(json);

  @override
  final String id;
  @override
  final String deckId;
  @override
  final String cardId;
  @override
  final String name;
  @override
  final String arcana;
  @override
  final String? suit;
  @override
  final int number;
  @override
  final String imagePath;
  @override
  final CardMeanings meanings;

  @override
  String toString() {
    return 'TarotCard(id: $id, deckId: $deckId, cardId: $cardId, name: $name, arcana: $arcana, suit: $suit, number: $number, imagePath: $imagePath, meanings: $meanings)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TarotCardImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.deckId, deckId) || other.deckId == deckId) &&
            (identical(other.cardId, cardId) || other.cardId == cardId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.arcana, arcana) || other.arcana == arcana) &&
            (identical(other.suit, suit) || other.suit == suit) &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.imagePath, imagePath) ||
                other.imagePath == imagePath) &&
            (identical(other.meanings, meanings) ||
                other.meanings == meanings));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, deckId, cardId, name, arcana,
      suit, number, imagePath, meanings);

  /// Create a copy of TarotCard
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TarotCardImplCopyWith<_$TarotCardImpl> get copyWith =>
      __$$TarotCardImplCopyWithImpl<_$TarotCardImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TarotCardImplToJson(
      this,
    );
  }
}

abstract class _TarotCard implements TarotCard {
  const factory _TarotCard(
      {required final String id,
      required final String deckId,
      required final String cardId,
      required final String name,
      required final String arcana,
      final String? suit,
      required final int number,
      required final String imagePath,
      required final CardMeanings meanings}) = _$TarotCardImpl;

  factory _TarotCard.fromJson(Map<String, dynamic> json) =
      _$TarotCardImpl.fromJson;

  @override
  String get id;
  @override
  String get deckId;
  @override
  String get cardId;
  @override
  String get name;
  @override
  String get arcana;
  @override
  String? get suit;
  @override
  int get number;
  @override
  String get imagePath;
  @override
  CardMeanings get meanings;

  /// Create a copy of TarotCard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TarotCardImplCopyWith<_$TarotCardImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
