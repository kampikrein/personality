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
  LayoutType get defaultLayoutType => throw _privateConstructorUsedError;
  bool get showCardName => throw _privateConstructorUsedError;
  bool get allowReversed => throw _privateConstructorUsedError;
  int get cardsPerRow => throw _privateConstructorUsedError;
  CardSizePreset get cardSizePreset => throw _privateConstructorUsedError;
  double get customCardWidthMm => throw _privateConstructorUsedError;
  double get customCardHeightMm => throw _privateConstructorUsedError;
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
      LayoutType defaultLayoutType,
      bool showCardName,
      bool allowReversed,
      int cardsPerRow,
      CardSizePreset cardSizePreset,
      double customCardWidthMm,
      double customCardHeightMm,
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
    Object? defaultLayoutType = null,
    Object? showCardName = null,
    Object? allowReversed = null,
    Object? cardsPerRow = null,
    Object? cardSizePreset = null,
    Object? customCardWidthMm = null,
    Object? customCardHeightMm = null,
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
      defaultLayoutType: null == defaultLayoutType
          ? _value.defaultLayoutType
          : defaultLayoutType // ignore: cast_nullable_to_non_nullable
              as LayoutType,
      showCardName: null == showCardName
          ? _value.showCardName
          : showCardName // ignore: cast_nullable_to_non_nullable
              as bool,
      allowReversed: null == allowReversed
          ? _value.allowReversed
          : allowReversed // ignore: cast_nullable_to_non_nullable
              as bool,
      cardsPerRow: null == cardsPerRow
          ? _value.cardsPerRow
          : cardsPerRow // ignore: cast_nullable_to_non_nullable
              as int,
      cardSizePreset: null == cardSizePreset
          ? _value.cardSizePreset
          : cardSizePreset // ignore: cast_nullable_to_non_nullable
              as CardSizePreset,
      customCardWidthMm: null == customCardWidthMm
          ? _value.customCardWidthMm
          : customCardWidthMm // ignore: cast_nullable_to_non_nullable
              as double,
      customCardHeightMm: null == customCardHeightMm
          ? _value.customCardHeightMm
          : customCardHeightMm // ignore: cast_nullable_to_non_nullable
              as double,
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
      LayoutType defaultLayoutType,
      bool showCardName,
      bool allowReversed,
      int cardsPerRow,
      CardSizePreset cardSizePreset,
      double customCardWidthMm,
      double customCardHeightMm,
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
    Object? defaultLayoutType = null,
    Object? showCardName = null,
    Object? allowReversed = null,
    Object? cardsPerRow = null,
    Object? cardSizePreset = null,
    Object? customCardWidthMm = null,
    Object? customCardHeightMm = null,
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
      defaultLayoutType: null == defaultLayoutType
          ? _value.defaultLayoutType
          : defaultLayoutType // ignore: cast_nullable_to_non_nullable
              as LayoutType,
      showCardName: null == showCardName
          ? _value.showCardName
          : showCardName // ignore: cast_nullable_to_non_nullable
              as bool,
      allowReversed: null == allowReversed
          ? _value.allowReversed
          : allowReversed // ignore: cast_nullable_to_non_nullable
              as bool,
      cardsPerRow: null == cardsPerRow
          ? _value.cardsPerRow
          : cardsPerRow // ignore: cast_nullable_to_non_nullable
              as int,
      cardSizePreset: null == cardSizePreset
          ? _value.cardSizePreset
          : cardSizePreset // ignore: cast_nullable_to_non_nullable
              as CardSizePreset,
      customCardWidthMm: null == customCardWidthMm
          ? _value.customCardWidthMm
          : customCardWidthMm // ignore: cast_nullable_to_non_nullable
              as double,
      customCardHeightMm: null == customCardHeightMm
          ? _value.customCardHeightMm
          : customCardHeightMm // ignore: cast_nullable_to_non_nullable
              as double,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserSettingsImpl extends _UserSettings {
  const _$UserSettingsImpl(
      {this.selectedDeckId = 'rws-standard',
      this.experienceLevel = 4,
      this.defaultCardCount = 3,
      this.showFaceUp = false,
      this.quickDrawEnabled = false,
      this.defaultLayoutType = LayoutType.linear,
      this.showCardName = true,
      this.allowReversed = true,
      this.cardsPerRow = 3,
      this.cardSizePreset = CardSizePreset.standardTarot,
      this.customCardWidthMm = 70.0,
      this.customCardHeightMm = 120.0,
      required this.updatedAt})
      : super._();

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
  final LayoutType defaultLayoutType;
  @override
  @JsonKey()
  final bool showCardName;
  @override
  @JsonKey()
  final bool allowReversed;
  @override
  @JsonKey()
  final int cardsPerRow;
  @override
  @JsonKey()
  final CardSizePreset cardSizePreset;
  @override
  @JsonKey()
  final double customCardWidthMm;
  @override
  @JsonKey()
  final double customCardHeightMm;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'UserSettings(selectedDeckId: $selectedDeckId, experienceLevel: $experienceLevel, defaultCardCount: $defaultCardCount, showFaceUp: $showFaceUp, quickDrawEnabled: $quickDrawEnabled, defaultLayoutType: $defaultLayoutType, showCardName: $showCardName, allowReversed: $allowReversed, cardsPerRow: $cardsPerRow, cardSizePreset: $cardSizePreset, customCardWidthMm: $customCardWidthMm, customCardHeightMm: $customCardHeightMm, updatedAt: $updatedAt)';
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
            (identical(other.defaultLayoutType, defaultLayoutType) ||
                other.defaultLayoutType == defaultLayoutType) &&
            (identical(other.showCardName, showCardName) ||
                other.showCardName == showCardName) &&
            (identical(other.allowReversed, allowReversed) ||
                other.allowReversed == allowReversed) &&
            (identical(other.cardsPerRow, cardsPerRow) ||
                other.cardsPerRow == cardsPerRow) &&
            (identical(other.cardSizePreset, cardSizePreset) ||
                other.cardSizePreset == cardSizePreset) &&
            (identical(other.customCardWidthMm, customCardWidthMm) ||
                other.customCardWidthMm == customCardWidthMm) &&
            (identical(other.customCardHeightMm, customCardHeightMm) ||
                other.customCardHeightMm == customCardHeightMm) &&
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
      defaultLayoutType,
      showCardName,
      allowReversed,
      cardsPerRow,
      cardSizePreset,
      customCardWidthMm,
      customCardHeightMm,
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

abstract class _UserSettings extends UserSettings {
  const factory _UserSettings(
      {final String selectedDeckId,
      final int experienceLevel,
      final int defaultCardCount,
      final bool showFaceUp,
      final bool quickDrawEnabled,
      final LayoutType defaultLayoutType,
      final bool showCardName,
      final bool allowReversed,
      final int cardsPerRow,
      final CardSizePreset cardSizePreset,
      final double customCardWidthMm,
      final double customCardHeightMm,
      required final DateTime updatedAt}) = _$UserSettingsImpl;
  const _UserSettings._() : super._();

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
  LayoutType get defaultLayoutType;
  @override
  bool get showCardName;
  @override
  bool get allowReversed;
  @override
  int get cardsPerRow;
  @override
  CardSizePreset get cardSizePreset;
  @override
  double get customCardWidthMm;
  @override
  double get customCardHeightMm;
  @override
  DateTime get updatedAt;

  /// Create a copy of UserSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserSettingsImplCopyWith<_$UserSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
