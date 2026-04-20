// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reading.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Reading _$ReadingFromJson(Map<String, dynamic> json) {
  return _Reading.fromJson(json);
}

/// @nodoc
mixin _$Reading {
  String get id => throw _privateConstructorUsedError;
  String get deckId => throw _privateConstructorUsedError;
  LayoutType get spreadType => throw _privateConstructorUsedError;
  String? get question => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  List<DrawnCardInfo> get drawnCards => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Reading to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Reading
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReadingCopyWith<Reading> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReadingCopyWith<$Res> {
  factory $ReadingCopyWith(Reading value, $Res Function(Reading) then) =
      _$ReadingCopyWithImpl<$Res, Reading>;
  @useResult
  $Res call(
      {String id,
      String deckId,
      LayoutType spreadType,
      String? question,
      String? notes,
      List<DrawnCardInfo> drawnCards,
      DateTime createdAt});
}

/// @nodoc
class _$ReadingCopyWithImpl<$Res, $Val extends Reading>
    implements $ReadingCopyWith<$Res> {
  _$ReadingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Reading
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? deckId = null,
    Object? spreadType = null,
    Object? question = freezed,
    Object? notes = freezed,
    Object? drawnCards = null,
    Object? createdAt = null,
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
      spreadType: null == spreadType
          ? _value.spreadType
          : spreadType // ignore: cast_nullable_to_non_nullable
              as LayoutType,
      question: freezed == question
          ? _value.question
          : question // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      drawnCards: null == drawnCards
          ? _value.drawnCards
          : drawnCards // ignore: cast_nullable_to_non_nullable
              as List<DrawnCardInfo>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ReadingImplCopyWith<$Res> implements $ReadingCopyWith<$Res> {
  factory _$$ReadingImplCopyWith(
          _$ReadingImpl value, $Res Function(_$ReadingImpl) then) =
      __$$ReadingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String deckId,
      LayoutType spreadType,
      String? question,
      String? notes,
      List<DrawnCardInfo> drawnCards,
      DateTime createdAt});
}

/// @nodoc
class __$$ReadingImplCopyWithImpl<$Res>
    extends _$ReadingCopyWithImpl<$Res, _$ReadingImpl>
    implements _$$ReadingImplCopyWith<$Res> {
  __$$ReadingImplCopyWithImpl(
      _$ReadingImpl _value, $Res Function(_$ReadingImpl) _then)
      : super(_value, _then);

  /// Create a copy of Reading
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? deckId = null,
    Object? spreadType = null,
    Object? question = freezed,
    Object? notes = freezed,
    Object? drawnCards = null,
    Object? createdAt = null,
  }) {
    return _then(_$ReadingImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      deckId: null == deckId
          ? _value.deckId
          : deckId // ignore: cast_nullable_to_non_nullable
              as String,
      spreadType: null == spreadType
          ? _value.spreadType
          : spreadType // ignore: cast_nullable_to_non_nullable
              as LayoutType,
      question: freezed == question
          ? _value.question
          : question // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      drawnCards: null == drawnCards
          ? _value._drawnCards
          : drawnCards // ignore: cast_nullable_to_non_nullable
              as List<DrawnCardInfo>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ReadingImpl implements _Reading {
  const _$ReadingImpl(
      {required this.id,
      required this.deckId,
      required this.spreadType,
      this.question,
      this.notes,
      required final List<DrawnCardInfo> drawnCards,
      required this.createdAt})
      : _drawnCards = drawnCards;

  factory _$ReadingImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReadingImplFromJson(json);

  @override
  final String id;
  @override
  final String deckId;
  @override
  final LayoutType spreadType;
  @override
  final String? question;
  @override
  final String? notes;
  final List<DrawnCardInfo> _drawnCards;
  @override
  List<DrawnCardInfo> get drawnCards {
    if (_drawnCards is EqualUnmodifiableListView) return _drawnCards;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_drawnCards);
  }

  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'Reading(id: $id, deckId: $deckId, spreadType: $spreadType, question: $question, notes: $notes, drawnCards: $drawnCards, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReadingImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.deckId, deckId) || other.deckId == deckId) &&
            (identical(other.spreadType, spreadType) ||
                other.spreadType == spreadType) &&
            (identical(other.question, question) ||
                other.question == question) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            const DeepCollectionEquality()
                .equals(other._drawnCards, _drawnCards) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, deckId, spreadType, question,
      notes, const DeepCollectionEquality().hash(_drawnCards), createdAt);

  /// Create a copy of Reading
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReadingImplCopyWith<_$ReadingImpl> get copyWith =>
      __$$ReadingImplCopyWithImpl<_$ReadingImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReadingImplToJson(
      this,
    );
  }
}

abstract class _Reading implements Reading {
  const factory _Reading(
      {required final String id,
      required final String deckId,
      required final LayoutType spreadType,
      final String? question,
      final String? notes,
      required final List<DrawnCardInfo> drawnCards,
      required final DateTime createdAt}) = _$ReadingImpl;

  factory _Reading.fromJson(Map<String, dynamic> json) = _$ReadingImpl.fromJson;

  @override
  String get id;
  @override
  String get deckId;
  @override
  LayoutType get spreadType;
  @override
  String? get question;
  @override
  String? get notes;
  @override
  List<DrawnCardInfo> get drawnCards;
  @override
  DateTime get createdAt;

  /// Create a copy of Reading
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReadingImplCopyWith<_$ReadingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DrawnCardInfo _$DrawnCardInfoFromJson(Map<String, dynamic> json) {
  return _DrawnCardInfo.fromJson(json);
}

/// @nodoc
mixin _$DrawnCardInfo {
  String get cardId => throw _privateConstructorUsedError;
  int get position => throw _privateConstructorUsedError;
  bool get isReversed => throw _privateConstructorUsedError;

  /// Serializes this DrawnCardInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DrawnCardInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DrawnCardInfoCopyWith<DrawnCardInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DrawnCardInfoCopyWith<$Res> {
  factory $DrawnCardInfoCopyWith(
          DrawnCardInfo value, $Res Function(DrawnCardInfo) then) =
      _$DrawnCardInfoCopyWithImpl<$Res, DrawnCardInfo>;
  @useResult
  $Res call({String cardId, int position, bool isReversed});
}

/// @nodoc
class _$DrawnCardInfoCopyWithImpl<$Res, $Val extends DrawnCardInfo>
    implements $DrawnCardInfoCopyWith<$Res> {
  _$DrawnCardInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DrawnCardInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cardId = null,
    Object? position = null,
    Object? isReversed = null,
  }) {
    return _then(_value.copyWith(
      cardId: null == cardId
          ? _value.cardId
          : cardId // ignore: cast_nullable_to_non_nullable
              as String,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as int,
      isReversed: null == isReversed
          ? _value.isReversed
          : isReversed // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DrawnCardInfoImplCopyWith<$Res>
    implements $DrawnCardInfoCopyWith<$Res> {
  factory _$$DrawnCardInfoImplCopyWith(
          _$DrawnCardInfoImpl value, $Res Function(_$DrawnCardInfoImpl) then) =
      __$$DrawnCardInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String cardId, int position, bool isReversed});
}

/// @nodoc
class __$$DrawnCardInfoImplCopyWithImpl<$Res>
    extends _$DrawnCardInfoCopyWithImpl<$Res, _$DrawnCardInfoImpl>
    implements _$$DrawnCardInfoImplCopyWith<$Res> {
  __$$DrawnCardInfoImplCopyWithImpl(
      _$DrawnCardInfoImpl _value, $Res Function(_$DrawnCardInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of DrawnCardInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cardId = null,
    Object? position = null,
    Object? isReversed = null,
  }) {
    return _then(_$DrawnCardInfoImpl(
      cardId: null == cardId
          ? _value.cardId
          : cardId // ignore: cast_nullable_to_non_nullable
              as String,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as int,
      isReversed: null == isReversed
          ? _value.isReversed
          : isReversed // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DrawnCardInfoImpl implements _DrawnCardInfo {
  const _$DrawnCardInfoImpl(
      {required this.cardId, required this.position, required this.isReversed});

  factory _$DrawnCardInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$DrawnCardInfoImplFromJson(json);

  @override
  final String cardId;
  @override
  final int position;
  @override
  final bool isReversed;

  @override
  String toString() {
    return 'DrawnCardInfo(cardId: $cardId, position: $position, isReversed: $isReversed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DrawnCardInfoImpl &&
            (identical(other.cardId, cardId) || other.cardId == cardId) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.isReversed, isReversed) ||
                other.isReversed == isReversed));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, cardId, position, isReversed);

  /// Create a copy of DrawnCardInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DrawnCardInfoImplCopyWith<_$DrawnCardInfoImpl> get copyWith =>
      __$$DrawnCardInfoImplCopyWithImpl<_$DrawnCardInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DrawnCardInfoImplToJson(
      this,
    );
  }
}

abstract class _DrawnCardInfo implements DrawnCardInfo {
  const factory _DrawnCardInfo(
      {required final String cardId,
      required final int position,
      required final bool isReversed}) = _$DrawnCardInfoImpl;

  factory _DrawnCardInfo.fromJson(Map<String, dynamic> json) =
      _$DrawnCardInfoImpl.fromJson;

  @override
  String get cardId;
  @override
  int get position;
  @override
  bool get isReversed;

  /// Create a copy of DrawnCardInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DrawnCardInfoImplCopyWith<_$DrawnCardInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
