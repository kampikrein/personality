// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'card_meanings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CardMeanings _$CardMeaningsFromJson(Map<String, dynamic> json) {
  return _CardMeanings.fromJson(json);
}

/// @nodoc
mixin _$CardMeanings {
  List<String> get upright => throw _privateConstructorUsedError;
  List<String> get reversed => throw _privateConstructorUsedError;
  String? get customNotes => throw _privateConstructorUsedError;

  /// Serializes this CardMeanings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CardMeanings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CardMeaningsCopyWith<CardMeanings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CardMeaningsCopyWith<$Res> {
  factory $CardMeaningsCopyWith(
          CardMeanings value, $Res Function(CardMeanings) then) =
      _$CardMeaningsCopyWithImpl<$Res, CardMeanings>;
  @useResult
  $Res call({List<String> upright, List<String> reversed, String? customNotes});
}

/// @nodoc
class _$CardMeaningsCopyWithImpl<$Res, $Val extends CardMeanings>
    implements $CardMeaningsCopyWith<$Res> {
  _$CardMeaningsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CardMeanings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? upright = null,
    Object? reversed = null,
    Object? customNotes = freezed,
  }) {
    return _then(_value.copyWith(
      upright: null == upright
          ? _value.upright
          : upright // ignore: cast_nullable_to_non_nullable
              as List<String>,
      reversed: null == reversed
          ? _value.reversed
          : reversed // ignore: cast_nullable_to_non_nullable
              as List<String>,
      customNotes: freezed == customNotes
          ? _value.customNotes
          : customNotes // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CardMeaningsImplCopyWith<$Res>
    implements $CardMeaningsCopyWith<$Res> {
  factory _$$CardMeaningsImplCopyWith(
          _$CardMeaningsImpl value, $Res Function(_$CardMeaningsImpl) then) =
      __$$CardMeaningsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<String> upright, List<String> reversed, String? customNotes});
}

/// @nodoc
class __$$CardMeaningsImplCopyWithImpl<$Res>
    extends _$CardMeaningsCopyWithImpl<$Res, _$CardMeaningsImpl>
    implements _$$CardMeaningsImplCopyWith<$Res> {
  __$$CardMeaningsImplCopyWithImpl(
      _$CardMeaningsImpl _value, $Res Function(_$CardMeaningsImpl) _then)
      : super(_value, _then);

  /// Create a copy of CardMeanings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? upright = null,
    Object? reversed = null,
    Object? customNotes = freezed,
  }) {
    return _then(_$CardMeaningsImpl(
      upright: null == upright
          ? _value._upright
          : upright // ignore: cast_nullable_to_non_nullable
              as List<String>,
      reversed: null == reversed
          ? _value._reversed
          : reversed // ignore: cast_nullable_to_non_nullable
              as List<String>,
      customNotes: freezed == customNotes
          ? _value.customNotes
          : customNotes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CardMeaningsImpl implements _CardMeanings {
  const _$CardMeaningsImpl(
      {final List<String> upright = const [],
      final List<String> reversed = const [],
      this.customNotes})
      : _upright = upright,
        _reversed = reversed;

  factory _$CardMeaningsImpl.fromJson(Map<String, dynamic> json) =>
      _$$CardMeaningsImplFromJson(json);

  final List<String> _upright;
  @override
  @JsonKey()
  List<String> get upright {
    if (_upright is EqualUnmodifiableListView) return _upright;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_upright);
  }

  final List<String> _reversed;
  @override
  @JsonKey()
  List<String> get reversed {
    if (_reversed is EqualUnmodifiableListView) return _reversed;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_reversed);
  }

  @override
  final String? customNotes;

  @override
  String toString() {
    return 'CardMeanings(upright: $upright, reversed: $reversed, customNotes: $customNotes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CardMeaningsImpl &&
            const DeepCollectionEquality().equals(other._upright, _upright) &&
            const DeepCollectionEquality().equals(other._reversed, _reversed) &&
            (identical(other.customNotes, customNotes) ||
                other.customNotes == customNotes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_upright),
      const DeepCollectionEquality().hash(_reversed),
      customNotes);

  /// Create a copy of CardMeanings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CardMeaningsImplCopyWith<_$CardMeaningsImpl> get copyWith =>
      __$$CardMeaningsImplCopyWithImpl<_$CardMeaningsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CardMeaningsImplToJson(
      this,
    );
  }
}

abstract class _CardMeanings implements CardMeanings {
  const factory _CardMeanings(
      {final List<String> upright,
      final List<String> reversed,
      final String? customNotes}) = _$CardMeaningsImpl;

  factory _CardMeanings.fromJson(Map<String, dynamic> json) =
      _$CardMeaningsImpl.fromJson;

  @override
  List<String> get upright;
  @override
  List<String> get reversed;
  @override
  String? get customNotes;

  /// Create a copy of CardMeanings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CardMeaningsImplCopyWith<_$CardMeaningsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
