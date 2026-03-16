// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shuffle_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ShuffleResult _$ShuffleResultFromJson(Map<String, dynamic> json) {
  return _ShuffleResult.fromJson(json);
}

/// @nodoc
mixin _$ShuffleResult {
  List<ShuffledCard> get cards => throw _privateConstructorUsedError;
  int get entropyBits => throw _privateConstructorUsedError;
  bool get usedSensorEntropy => throw _privateConstructorUsedError;
  DateTime get shuffledAt => throw _privateConstructorUsedError;

  /// Serializes this ShuffleResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ShuffleResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ShuffleResultCopyWith<ShuffleResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShuffleResultCopyWith<$Res> {
  factory $ShuffleResultCopyWith(
          ShuffleResult value, $Res Function(ShuffleResult) then) =
      _$ShuffleResultCopyWithImpl<$Res, ShuffleResult>;
  @useResult
  $Res call(
      {List<ShuffledCard> cards,
      int entropyBits,
      bool usedSensorEntropy,
      DateTime shuffledAt});
}

/// @nodoc
class _$ShuffleResultCopyWithImpl<$Res, $Val extends ShuffleResult>
    implements $ShuffleResultCopyWith<$Res> {
  _$ShuffleResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ShuffleResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cards = null,
    Object? entropyBits = null,
    Object? usedSensorEntropy = null,
    Object? shuffledAt = null,
  }) {
    return _then(_value.copyWith(
      cards: null == cards
          ? _value.cards
          : cards // ignore: cast_nullable_to_non_nullable
              as List<ShuffledCard>,
      entropyBits: null == entropyBits
          ? _value.entropyBits
          : entropyBits // ignore: cast_nullable_to_non_nullable
              as int,
      usedSensorEntropy: null == usedSensorEntropy
          ? _value.usedSensorEntropy
          : usedSensorEntropy // ignore: cast_nullable_to_non_nullable
              as bool,
      shuffledAt: null == shuffledAt
          ? _value.shuffledAt
          : shuffledAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ShuffleResultImplCopyWith<$Res>
    implements $ShuffleResultCopyWith<$Res> {
  factory _$$ShuffleResultImplCopyWith(
          _$ShuffleResultImpl value, $Res Function(_$ShuffleResultImpl) then) =
      __$$ShuffleResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<ShuffledCard> cards,
      int entropyBits,
      bool usedSensorEntropy,
      DateTime shuffledAt});
}

/// @nodoc
class __$$ShuffleResultImplCopyWithImpl<$Res>
    extends _$ShuffleResultCopyWithImpl<$Res, _$ShuffleResultImpl>
    implements _$$ShuffleResultImplCopyWith<$Res> {
  __$$ShuffleResultImplCopyWithImpl(
      _$ShuffleResultImpl _value, $Res Function(_$ShuffleResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of ShuffleResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cards = null,
    Object? entropyBits = null,
    Object? usedSensorEntropy = null,
    Object? shuffledAt = null,
  }) {
    return _then(_$ShuffleResultImpl(
      cards: null == cards
          ? _value._cards
          : cards // ignore: cast_nullable_to_non_nullable
              as List<ShuffledCard>,
      entropyBits: null == entropyBits
          ? _value.entropyBits
          : entropyBits // ignore: cast_nullable_to_non_nullable
              as int,
      usedSensorEntropy: null == usedSensorEntropy
          ? _value.usedSensorEntropy
          : usedSensorEntropy // ignore: cast_nullable_to_non_nullable
              as bool,
      shuffledAt: null == shuffledAt
          ? _value.shuffledAt
          : shuffledAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ShuffleResultImpl implements _ShuffleResult {
  const _$ShuffleResultImpl(
      {required final List<ShuffledCard> cards,
      required this.entropyBits,
      required this.usedSensorEntropy,
      required this.shuffledAt})
      : _cards = cards;

  factory _$ShuffleResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$ShuffleResultImplFromJson(json);

  final List<ShuffledCard> _cards;
  @override
  List<ShuffledCard> get cards {
    if (_cards is EqualUnmodifiableListView) return _cards;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_cards);
  }

  @override
  final int entropyBits;
  @override
  final bool usedSensorEntropy;
  @override
  final DateTime shuffledAt;

  @override
  String toString() {
    return 'ShuffleResult(cards: $cards, entropyBits: $entropyBits, usedSensorEntropy: $usedSensorEntropy, shuffledAt: $shuffledAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShuffleResultImpl &&
            const DeepCollectionEquality().equals(other._cards, _cards) &&
            (identical(other.entropyBits, entropyBits) ||
                other.entropyBits == entropyBits) &&
            (identical(other.usedSensorEntropy, usedSensorEntropy) ||
                other.usedSensorEntropy == usedSensorEntropy) &&
            (identical(other.shuffledAt, shuffledAt) ||
                other.shuffledAt == shuffledAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_cards),
      entropyBits,
      usedSensorEntropy,
      shuffledAt);

  /// Create a copy of ShuffleResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ShuffleResultImplCopyWith<_$ShuffleResultImpl> get copyWith =>
      __$$ShuffleResultImplCopyWithImpl<_$ShuffleResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ShuffleResultImplToJson(
      this,
    );
  }
}

abstract class _ShuffleResult implements ShuffleResult {
  const factory _ShuffleResult(
      {required final List<ShuffledCard> cards,
      required final int entropyBits,
      required final bool usedSensorEntropy,
      required final DateTime shuffledAt}) = _$ShuffleResultImpl;

  factory _ShuffleResult.fromJson(Map<String, dynamic> json) =
      _$ShuffleResultImpl.fromJson;

  @override
  List<ShuffledCard> get cards;
  @override
  int get entropyBits;
  @override
  bool get usedSensorEntropy;
  @override
  DateTime get shuffledAt;

  /// Create a copy of ShuffleResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ShuffleResultImplCopyWith<_$ShuffleResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ShuffledCard _$ShuffledCardFromJson(Map<String, dynamic> json) {
  return _ShuffledCard.fromJson(json);
}

/// @nodoc
mixin _$ShuffledCard {
  TarotCard get card => throw _privateConstructorUsedError;
  bool get isReversed => throw _privateConstructorUsedError;

  /// Serializes this ShuffledCard to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ShuffledCard
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ShuffledCardCopyWith<ShuffledCard> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShuffledCardCopyWith<$Res> {
  factory $ShuffledCardCopyWith(
          ShuffledCard value, $Res Function(ShuffledCard) then) =
      _$ShuffledCardCopyWithImpl<$Res, ShuffledCard>;
  @useResult
  $Res call({TarotCard card, bool isReversed});

  $TarotCardCopyWith<$Res> get card;
}

/// @nodoc
class _$ShuffledCardCopyWithImpl<$Res, $Val extends ShuffledCard>
    implements $ShuffledCardCopyWith<$Res> {
  _$ShuffledCardCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ShuffledCard
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? card = null,
    Object? isReversed = null,
  }) {
    return _then(_value.copyWith(
      card: null == card
          ? _value.card
          : card // ignore: cast_nullable_to_non_nullable
              as TarotCard,
      isReversed: null == isReversed
          ? _value.isReversed
          : isReversed // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  /// Create a copy of ShuffledCard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TarotCardCopyWith<$Res> get card {
    return $TarotCardCopyWith<$Res>(_value.card, (value) {
      return _then(_value.copyWith(card: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ShuffledCardImplCopyWith<$Res>
    implements $ShuffledCardCopyWith<$Res> {
  factory _$$ShuffledCardImplCopyWith(
          _$ShuffledCardImpl value, $Res Function(_$ShuffledCardImpl) then) =
      __$$ShuffledCardImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({TarotCard card, bool isReversed});

  @override
  $TarotCardCopyWith<$Res> get card;
}

/// @nodoc
class __$$ShuffledCardImplCopyWithImpl<$Res>
    extends _$ShuffledCardCopyWithImpl<$Res, _$ShuffledCardImpl>
    implements _$$ShuffledCardImplCopyWith<$Res> {
  __$$ShuffledCardImplCopyWithImpl(
      _$ShuffledCardImpl _value, $Res Function(_$ShuffledCardImpl) _then)
      : super(_value, _then);

  /// Create a copy of ShuffledCard
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? card = null,
    Object? isReversed = null,
  }) {
    return _then(_$ShuffledCardImpl(
      card: null == card
          ? _value.card
          : card // ignore: cast_nullable_to_non_nullable
              as TarotCard,
      isReversed: null == isReversed
          ? _value.isReversed
          : isReversed // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ShuffledCardImpl implements _ShuffledCard {
  const _$ShuffledCardImpl({required this.card, required this.isReversed});

  factory _$ShuffledCardImpl.fromJson(Map<String, dynamic> json) =>
      _$$ShuffledCardImplFromJson(json);

  @override
  final TarotCard card;
  @override
  final bool isReversed;

  @override
  String toString() {
    return 'ShuffledCard(card: $card, isReversed: $isReversed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShuffledCardImpl &&
            (identical(other.card, card) || other.card == card) &&
            (identical(other.isReversed, isReversed) ||
                other.isReversed == isReversed));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, card, isReversed);

  /// Create a copy of ShuffledCard
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ShuffledCardImplCopyWith<_$ShuffledCardImpl> get copyWith =>
      __$$ShuffledCardImplCopyWithImpl<_$ShuffledCardImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ShuffledCardImplToJson(
      this,
    );
  }
}

abstract class _ShuffledCard implements ShuffledCard {
  const factory _ShuffledCard(
      {required final TarotCard card,
      required final bool isReversed}) = _$ShuffledCardImpl;

  factory _ShuffledCard.fromJson(Map<String, dynamic> json) =
      _$ShuffledCardImpl.fromJson;

  @override
  TarotCard get card;
  @override
  bool get isReversed;

  /// Create a copy of ShuffledCard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ShuffledCardImplCopyWith<_$ShuffledCardImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
