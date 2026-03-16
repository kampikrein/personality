// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shuffle_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ShuffleConfig _$ShuffleConfigFromJson(Map<String, dynamic> json) {
  return _ShuffleConfig.fromJson(json);
}

/// @nodoc
mixin _$ShuffleConfig {
  int get shuffleCount => throw _privateConstructorUsedError;
  bool get useReversals => throw _privateConstructorUsedError;
  double get reversalProbability => throw _privateConstructorUsedError;

  /// Serializes this ShuffleConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ShuffleConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ShuffleConfigCopyWith<ShuffleConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShuffleConfigCopyWith<$Res> {
  factory $ShuffleConfigCopyWith(
          ShuffleConfig value, $Res Function(ShuffleConfig) then) =
      _$ShuffleConfigCopyWithImpl<$Res, ShuffleConfig>;
  @useResult
  $Res call({int shuffleCount, bool useReversals, double reversalProbability});
}

/// @nodoc
class _$ShuffleConfigCopyWithImpl<$Res, $Val extends ShuffleConfig>
    implements $ShuffleConfigCopyWith<$Res> {
  _$ShuffleConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ShuffleConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? shuffleCount = null,
    Object? useReversals = null,
    Object? reversalProbability = null,
  }) {
    return _then(_value.copyWith(
      shuffleCount: null == shuffleCount
          ? _value.shuffleCount
          : shuffleCount // ignore: cast_nullable_to_non_nullable
              as int,
      useReversals: null == useReversals
          ? _value.useReversals
          : useReversals // ignore: cast_nullable_to_non_nullable
              as bool,
      reversalProbability: null == reversalProbability
          ? _value.reversalProbability
          : reversalProbability // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ShuffleConfigImplCopyWith<$Res>
    implements $ShuffleConfigCopyWith<$Res> {
  factory _$$ShuffleConfigImplCopyWith(
          _$ShuffleConfigImpl value, $Res Function(_$ShuffleConfigImpl) then) =
      __$$ShuffleConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int shuffleCount, bool useReversals, double reversalProbability});
}

/// @nodoc
class __$$ShuffleConfigImplCopyWithImpl<$Res>
    extends _$ShuffleConfigCopyWithImpl<$Res, _$ShuffleConfigImpl>
    implements _$$ShuffleConfigImplCopyWith<$Res> {
  __$$ShuffleConfigImplCopyWithImpl(
      _$ShuffleConfigImpl _value, $Res Function(_$ShuffleConfigImpl) _then)
      : super(_value, _then);

  /// Create a copy of ShuffleConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? shuffleCount = null,
    Object? useReversals = null,
    Object? reversalProbability = null,
  }) {
    return _then(_$ShuffleConfigImpl(
      shuffleCount: null == shuffleCount
          ? _value.shuffleCount
          : shuffleCount // ignore: cast_nullable_to_non_nullable
              as int,
      useReversals: null == useReversals
          ? _value.useReversals
          : useReversals // ignore: cast_nullable_to_non_nullable
              as bool,
      reversalProbability: null == reversalProbability
          ? _value.reversalProbability
          : reversalProbability // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ShuffleConfigImpl implements _ShuffleConfig {
  const _$ShuffleConfigImpl(
      {this.shuffleCount = 3,
      this.useReversals = true,
      this.reversalProbability = 0.33});

  factory _$ShuffleConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$ShuffleConfigImplFromJson(json);

  @override
  @JsonKey()
  final int shuffleCount;
  @override
  @JsonKey()
  final bool useReversals;
  @override
  @JsonKey()
  final double reversalProbability;

  @override
  String toString() {
    return 'ShuffleConfig(shuffleCount: $shuffleCount, useReversals: $useReversals, reversalProbability: $reversalProbability)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShuffleConfigImpl &&
            (identical(other.shuffleCount, shuffleCount) ||
                other.shuffleCount == shuffleCount) &&
            (identical(other.useReversals, useReversals) ||
                other.useReversals == useReversals) &&
            (identical(other.reversalProbability, reversalProbability) ||
                other.reversalProbability == reversalProbability));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, shuffleCount, useReversals, reversalProbability);

  /// Create a copy of ShuffleConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ShuffleConfigImplCopyWith<_$ShuffleConfigImpl> get copyWith =>
      __$$ShuffleConfigImplCopyWithImpl<_$ShuffleConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ShuffleConfigImplToJson(
      this,
    );
  }
}

abstract class _ShuffleConfig implements ShuffleConfig {
  const factory _ShuffleConfig(
      {final int shuffleCount,
      final bool useReversals,
      final double reversalProbability}) = _$ShuffleConfigImpl;

  factory _ShuffleConfig.fromJson(Map<String, dynamic> json) =
      _$ShuffleConfigImpl.fromJson;

  @override
  int get shuffleCount;
  @override
  bool get useReversals;
  @override
  double get reversalProbability;

  /// Create a copy of ShuffleConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ShuffleConfigImplCopyWith<_$ShuffleConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
