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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
