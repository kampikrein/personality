// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$readingRepositoryHash() => r'c8b727c960620968cc4d92fdcccc5762de777d5b';

/// See also [readingRepository].
@ProviderFor(readingRepository)
final readingRepositoryProvider = Provider<ReadingRepository>.internal(
  readingRepository,
  name: r'readingRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$readingRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ReadingRepositoryRef = ProviderRef<ReadingRepository>;
String _$watchReadingsHash() => r'db1de116df43cbe8cd70b2ce0f75d2739a5ac587';

/// See also [watchReadings].
@ProviderFor(watchReadings)
final watchReadingsProvider = AutoDisposeStreamProvider<List<Reading>>.internal(
  watchReadings,
  name: r'watchReadingsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$watchReadingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WatchReadingsRef = AutoDisposeStreamProviderRef<List<Reading>>;
String _$watchReadingsBySpreadTypeHash() =>
    r'ac5aeb8cf77af7004cb05a9bb75e59acc0e97869';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [watchReadingsBySpreadType].
@ProviderFor(watchReadingsBySpreadType)
const watchReadingsBySpreadTypeProvider = WatchReadingsBySpreadTypeFamily();

/// See also [watchReadingsBySpreadType].
class WatchReadingsBySpreadTypeFamily
    extends Family<AsyncValue<List<Reading>>> {
  /// See also [watchReadingsBySpreadType].
  const WatchReadingsBySpreadTypeFamily();

  /// See also [watchReadingsBySpreadType].
  WatchReadingsBySpreadTypeProvider call(
    SpreadType spreadType,
  ) {
    return WatchReadingsBySpreadTypeProvider(
      spreadType,
    );
  }

  @override
  WatchReadingsBySpreadTypeProvider getProviderOverride(
    covariant WatchReadingsBySpreadTypeProvider provider,
  ) {
    return call(
      provider.spreadType,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'watchReadingsBySpreadTypeProvider';
}

/// See also [watchReadingsBySpreadType].
class WatchReadingsBySpreadTypeProvider
    extends AutoDisposeStreamProvider<List<Reading>> {
  /// See also [watchReadingsBySpreadType].
  WatchReadingsBySpreadTypeProvider(
    SpreadType spreadType,
  ) : this._internal(
          (ref) => watchReadingsBySpreadType(
            ref as WatchReadingsBySpreadTypeRef,
            spreadType,
          ),
          from: watchReadingsBySpreadTypeProvider,
          name: r'watchReadingsBySpreadTypeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$watchReadingsBySpreadTypeHash,
          dependencies: WatchReadingsBySpreadTypeFamily._dependencies,
          allTransitiveDependencies:
              WatchReadingsBySpreadTypeFamily._allTransitiveDependencies,
          spreadType: spreadType,
        );

  WatchReadingsBySpreadTypeProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.spreadType,
  }) : super.internal();

  final SpreadType spreadType;

  @override
  Override overrideWith(
    Stream<List<Reading>> Function(WatchReadingsBySpreadTypeRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WatchReadingsBySpreadTypeProvider._internal(
        (ref) => create(ref as WatchReadingsBySpreadTypeRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        spreadType: spreadType,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<Reading>> createElement() {
    return _WatchReadingsBySpreadTypeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchReadingsBySpreadTypeProvider &&
        other.spreadType == spreadType;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, spreadType.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin WatchReadingsBySpreadTypeRef
    on AutoDisposeStreamProviderRef<List<Reading>> {
  /// The parameter `spreadType` of this provider.
  SpreadType get spreadType;
}

class _WatchReadingsBySpreadTypeProviderElement
    extends AutoDisposeStreamProviderElement<List<Reading>>
    with WatchReadingsBySpreadTypeRef {
  _WatchReadingsBySpreadTypeProviderElement(super.provider);

  @override
  SpreadType get spreadType =>
      (origin as WatchReadingsBySpreadTypeProvider).spreadType;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
