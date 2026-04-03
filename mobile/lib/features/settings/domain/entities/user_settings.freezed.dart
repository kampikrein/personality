// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserSettings _$UserSettingsFromJson(Map<String, dynamic> json) {
  return _UserSettings.fromJson(json);
}

/// @nodoc
mixin _$UserSettings {
  String get selectedDeckId => throw _privateConstructorUsedError;
  int get experienceLevel => throw _privateConstructorUsedError;
  int get defaultCardCount => throw _privateConstructorUsedError;
  bool get showFaceUp => throw _privateConstructorUsedError;
  bool get quickDrawEnabled => throw _privateConstructorUsedError;
  SpreadType get defaultSpreadType => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this UserSettings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserSettingsCopyWith<UserSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserSettingsCopyWith<$Res> {
  factory $UserSettingsCopyWith(
          UserSettings value, $Res Function(UserSettings) then) =
      _$UserSettingsCopyWithImpl<$Res, UserSettings>;
  @useResult
  $Res call(
      {String selectedDeckId,
      int experienceLevel,
      int defaultCardCount,
      bool showFaceUp,
      bool quickDrawEnabled,
      SpreadType defaultSpreadType,
      DateTime updatedAt});
}

/// @nodoc
class _$UserSettingsCopyWithImpl<$Res, $Val extends UserSettings>
    implements $UserSettingsCopyWith<$Res> {
  _$UserSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selectedDeckId = null,
    Object? experienceLevel = null,
    Object? defaultCardCount = null,
    Object? showFaceUp = null,
    Object? quickDrawEnabled = null,
    Object? defaultSpreadType = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      selectedDeckId: null == selectedDeckId
          ? _value.selectedDeckId
          : selectedDeckId // ignore: cast_nullable_to_non_nullable
              as String,
      experienceLevel: null == experienceLevel
          ? _value.experienceLevel
          : experienceLevel // ignore: cast_nullable_to_non_nullable
              as int,
      defaultCardCount: null == defaultCardCount
          ? _value.defaultCardCount
          : defaultCardCount // ignore: cast_nullable_to_non_nullable
              as int,
      showFaceUp: null == showFaceUp
          ? _value.showFaceUp
          : showFaceUp // ignore: cast_nullable_to_non_nullable
              as bool,
      quickDrawEnabled: null == quickDrawEnabled
          ? _value.quickDrawEnabled
          : quickDrawEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      defaultSpreadType: null == defaultSpreadType
          ? _value.defaultSpreadType
          : defaultSpreadType // ignore: cast_nullable_to_non_nullable
              as SpreadType,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserSettingsImplCopyWith<$Res>
    implements $UserSettingsCopyWith<$Res> {
  factory _$$UserSettingsImplCopyWith(
          _$UserSettingsImpl value, $Res Function(_$UserSettingsImpl) then) =
      __$$UserSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String selectedDeckId,
      int experienceLevel,
      int defaultCardCount,
      bool showFaceUp,
      bool quickDrawEnabled,
      SpreadType defaultSpreadType,
      DateTime updatedAt});
}

/// @nodoc
class __$$UserSettingsImplCopyWithImpl<$Res>
    extends _$UserSettingsCopyWithImpl<$Res, _$UserSettingsImpl>
    implements _$$UserSettingsImplCopyWith<$Res> {
  __$$UserSettingsImplCopyWithImpl(
      _$UserSettingsImpl _value, $Res Function(_$UserSettingsImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selectedDeckId = null,
    Object? experienceLevel = null,
    Object? defaultCardCount = null,
    Object? showFaceUp = null,
    Object? quickDrawEnabled = null,
    Object? defaultSpreadType = null,
    Object? updatedAt = null,
  }) {
    return _then(_$UserSettingsImpl(
      selectedDeckId: null == selectedDeckId
          ? _value.selectedDeckId
          : selectedDeckId // ignore: cast_nullable_to_non_nullable
              as String,
      experienceLevel: null == experienceLevel
          ? _value.experienceLevel
          : experienceLevel // ignore: cast_nullable_to_non_nullable
              as int,
      defaultCardCount: null == defaultCardCount
          ? _value.defaultCardCount
          : defaultCardCount // ignore: cast_nullable_to_non_nullable
              as int,
      showFaceUp: null == showFaceUp
          ? _value.showFaceUp
          : showFaceUp // ignore: cast_nullable_to_non_nullable
              as bool,
      quickDrawEnabled: null == quickDrawEnabled
          ? _value.quickDrawEnabled
          : quickDrawEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      defaultSpreadType: null == defaultSpreadType
          ? _value.defaultSpreadType
          : defaultSpreadType // ignore: cast_nullable_to_non_nullable
              as SpreadType,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserSettingsImpl implements _UserSettings {
  const _$UserSettingsImpl(
      {this.selectedDeckId = 'rws-standard',
      this.experienceLevel = 3,
      this.defaultCardCount = 3,
      this.showFaceUp = false,
      this.quickDrawEnabled = false,
      this.defaultSpreadType = SpreadType.custom,
      required this.updatedAt});

  factory _$UserSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserSettingsImplFromJson(json);

  @override
  @JsonKey()
  final String selectedDeckId;
  @override
  @JsonKey()
  final int experienceLevel;
  @override
  @JsonKey()
  final int defaultCardCount;
  @override
  @JsonKey()
  final bool showFaceUp;
  @override
  @JsonKey()
  final bool quickDrawEnabled;
  @override
  @JsonKey()
  final SpreadType defaultSpreadType;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'UserSettings(selectedDeckId: $selectedDeckId, experienceLevel: $experienceLevel, defaultCardCount: $defaultCardCount, showFaceUp: $showFaceUp, quickDrawEnabled: $quickDrawEnabled, defaultSpreadType: $defaultSpreadType, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserSettingsImpl &&
            (identical(other.selectedDeckId, selectedDeckId) ||
                other.selectedDeckId == selectedDeckId) &&
            (identical(other.experienceLevel, experienceLevel) ||
                other.experienceLevel == experienceLevel) &&
            (identical(other.defaultCardCount, defaultCardCount) ||
                other.defaultCardCount == defaultCardCount) &&
            (identical(other.showFaceUp, showFaceUp) ||
                other.showFaceUp == showFaceUp) &&
            (identical(other.quickDrawEnabled, quickDrawEnabled) ||
                other.quickDrawEnabled == quickDrawEnabled) &&
            (identical(other.defaultSpreadType, defaultSpreadType) ||
                other.defaultSpreadType == defaultSpreadType) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      selectedDeckId,
      experienceLevel,
      defaultCardCount,
      showFaceUp,
      quickDrawEnabled,
      defaultSpreadType,
      updatedAt);

  /// Create a copy of UserSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserSettingsImplCopyWith<_$UserSettingsImpl> get copyWith =>
      __$$UserSettingsImplCopyWithImpl<_$UserSettingsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserSettingsImplToJson(
      this,
    );
  }
}

abstract class _UserSettings implements UserSettings {
  const factory _UserSettings(
      {final String selectedDeckId,
      final int experienceLevel,
      final int defaultCardCount,
      final bool showFaceUp,
      final bool quickDrawEnabled,
      final SpreadType defaultSpreadType,
      required final DateTime updatedAt}) = _$UserSettingsImpl;

  factory _UserSettings.fromJson(Map<String, dynamic> json) =
      _$UserSettingsImpl.fromJson;

  @override
  String get selectedDeckId;
  @override
  int get experienceLevel;
  @override
  int get defaultCardCount;
  @override
  bool get showFaceUp;
  @override
  bool get quickDrawEnabled;
  @override
  SpreadType get defaultSpreadType;
  @override
  DateTime get updatedAt;

  /// Create a copy of UserSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserSettingsImplCopyWith<_$UserSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
