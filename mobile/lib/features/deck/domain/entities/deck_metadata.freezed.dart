// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'deck_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DeckMetadata _$DeckMetadataFromJson(Map<String, dynamic> json) {
  return _DeckMetadata.fromJson(json);
}

/// @nodoc
mixin _$DeckMetadata {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  bool get isStandardTarot => throw _privateConstructorUsedError;
  int get totalCards => throw _privateConstructorUsedError;
  String? get creator => throw _privateConstructorUsedError;
  List<DrawMode> get supportedDrawModes => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this DeckMetadata to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DeckMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeckMetadataCopyWith<DeckMetadata> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeckMetadataCopyWith<$Res> {
  factory $DeckMetadataCopyWith(
          DeckMetadata value, $Res Function(DeckMetadata) then) =
      _$DeckMetadataCopyWithImpl<$Res, DeckMetadata>;
  @useResult
  $Res call(
      {String id,
      String name,
      bool isStandardTarot,
      int totalCards,
      String? creator,
      List<DrawMode> supportedDrawModes,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$DeckMetadataCopyWithImpl<$Res, $Val extends DeckMetadata>
    implements $DeckMetadataCopyWith<$Res> {
  _$DeckMetadataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DeckMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? isStandardTarot = null,
    Object? totalCards = null,
    Object? creator = freezed,
    Object? supportedDrawModes = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      isStandardTarot: null == isStandardTarot
          ? _value.isStandardTarot
          : isStandardTarot // ignore: cast_nullable_to_non_nullable
              as bool,
      totalCards: null == totalCards
          ? _value.totalCards
          : totalCards // ignore: cast_nullable_to_non_nullable
              as int,
      creator: freezed == creator
          ? _value.creator
          : creator // ignore: cast_nullable_to_non_nullable
              as String?,
      supportedDrawModes: null == supportedDrawModes
          ? _value.supportedDrawModes
          : supportedDrawModes // ignore: cast_nullable_to_non_nullable
              as List<DrawMode>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DeckMetadataImplCopyWith<$Res>
    implements $DeckMetadataCopyWith<$Res> {
  factory _$$DeckMetadataImplCopyWith(
          _$DeckMetadataImpl value, $Res Function(_$DeckMetadataImpl) then) =
      __$$DeckMetadataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      bool isStandardTarot,
      int totalCards,
      String? creator,
      List<DrawMode> supportedDrawModes,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$$DeckMetadataImplCopyWithImpl<$Res>
    extends _$DeckMetadataCopyWithImpl<$Res, _$DeckMetadataImpl>
    implements _$$DeckMetadataImplCopyWith<$Res> {
  __$$DeckMetadataImplCopyWithImpl(
      _$DeckMetadataImpl _value, $Res Function(_$DeckMetadataImpl) _then)
      : super(_value, _then);

  /// Create a copy of DeckMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? isStandardTarot = null,
    Object? totalCards = null,
    Object? creator = freezed,
    Object? supportedDrawModes = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$DeckMetadataImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      isStandardTarot: null == isStandardTarot
          ? _value.isStandardTarot
          : isStandardTarot // ignore: cast_nullable_to_non_nullable
              as bool,
      totalCards: null == totalCards
          ? _value.totalCards
          : totalCards // ignore: cast_nullable_to_non_nullable
              as int,
      creator: freezed == creator
          ? _value.creator
          : creator // ignore: cast_nullable_to_non_nullable
              as String?,
      supportedDrawModes: null == supportedDrawModes
          ? _value._supportedDrawModes
          : supportedDrawModes // ignore: cast_nullable_to_non_nullable
              as List<DrawMode>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DeckMetadataImpl implements _DeckMetadata {
  const _$DeckMetadataImpl(
      {required this.id,
      required this.name,
      this.isStandardTarot = true,
      required this.totalCards,
      this.creator,
      final List<DrawMode> supportedDrawModes = const [
        DrawMode.freeform,
        DrawMode.namedSpread
      ],
      required this.createdAt,
      required this.updatedAt})
      : _supportedDrawModes = supportedDrawModes;

  factory _$DeckMetadataImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeckMetadataImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final bool isStandardTarot;
  @override
  final int totalCards;
  @override
  final String? creator;
  final List<DrawMode> _supportedDrawModes;
  @override
  @JsonKey()
  List<DrawMode> get supportedDrawModes {
    if (_supportedDrawModes is EqualUnmodifiableListView)
      return _supportedDrawModes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_supportedDrawModes);
  }

  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'DeckMetadata(id: $id, name: $name, isStandardTarot: $isStandardTarot, totalCards: $totalCards, creator: $creator, supportedDrawModes: $supportedDrawModes, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeckMetadataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.isStandardTarot, isStandardTarot) ||
                other.isStandardTarot == isStandardTarot) &&
            (identical(other.totalCards, totalCards) ||
                other.totalCards == totalCards) &&
            (identical(other.creator, creator) || other.creator == creator) &&
            const DeepCollectionEquality()
                .equals(other._supportedDrawModes, _supportedDrawModes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      isStandardTarot,
      totalCards,
      creator,
      const DeepCollectionEquality().hash(_supportedDrawModes),
      createdAt,
      updatedAt);

  /// Create a copy of DeckMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeckMetadataImplCopyWith<_$DeckMetadataImpl> get copyWith =>
      __$$DeckMetadataImplCopyWithImpl<_$DeckMetadataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DeckMetadataImplToJson(
      this,
    );
  }
}

abstract class _DeckMetadata implements DeckMetadata {
  const factory _DeckMetadata(
      {required final String id,
      required final String name,
      final bool isStandardTarot,
      required final int totalCards,
      final String? creator,
      final List<DrawMode> supportedDrawModes,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$DeckMetadataImpl;

  factory _DeckMetadata.fromJson(Map<String, dynamic> json) =
      _$DeckMetadataImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  bool get isStandardTarot;
  @override
  int get totalCards;
  @override
  String? get creator;
  @override
  List<DrawMode> get supportedDrawModes;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of DeckMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeckMetadataImplCopyWith<_$DeckMetadataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
