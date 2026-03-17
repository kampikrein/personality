// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shuffle_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sensorDataCollectorHash() =>
    r'22a6538e0e0d41c1c2ac9463a74d279954adfb7e';

/// See also [sensorDataCollector].
@ProviderFor(sensorDataCollector)
final sensorDataCollectorProvider = Provider<SensorDataCollector>.internal(
  sensorDataCollector,
  name: r'sensorDataCollectorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sensorDataCollectorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SensorDataCollectorRef = ProviderRef<SensorDataCollector>;
String _$entropyPoolHash() => r'79849758279c48c38eecb3645fabd02284560f1d';

/// See also [entropyPool].
@ProviderFor(entropyPool)
final entropyPoolProvider = Provider<EntropyPool>.internal(
  entropyPool,
  name: r'entropyPoolProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$entropyPoolHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EntropyPoolRef = ProviderRef<EntropyPool>;
String _$hapticServiceHash() => r'2be77f248023b375f831db844ea1cedb7b17a5e8';

/// See also [hapticService].
@ProviderFor(hapticService)
final hapticServiceProvider = Provider<HapticService>.internal(
  hapticService,
  name: r'hapticServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hapticServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HapticServiceRef = ProviderRef<HapticService>;
String _$shuffleStrategyHash() => r'2cb0c672ebbe77edf7e94e335b19986dfdb76177';

/// See also [shuffleStrategy].
@ProviderFor(shuffleStrategy)
final shuffleStrategyProvider = AutoDisposeProvider<ShuffleStrategy>.internal(
  shuffleStrategy,
  name: r'shuffleStrategyProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$shuffleStrategyHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ShuffleStrategyRef = AutoDisposeProviderRef<ShuffleStrategy>;
String _$shuffleDeckUseCaseHash() =>
    r'd76a836023df43c1591f579ae977cf6f197ace7d';

/// See also [shuffleDeckUseCase].
@ProviderFor(shuffleDeckUseCase)
final shuffleDeckUseCaseProvider =
    AutoDisposeProvider<ShuffleDeckUseCase>.internal(
  shuffleDeckUseCase,
  name: r'shuffleDeckUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$shuffleDeckUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ShuffleDeckUseCaseRef = AutoDisposeProviderRef<ShuffleDeckUseCase>;
String _$shuffleRepositoryHash() => r'7510411cdf870bc5be398bf712d3e8d747d5f503';

/// See also [shuffleRepository].
@ProviderFor(shuffleRepository)
final shuffleRepositoryProvider = Provider<ShuffleRepository>.internal(
  shuffleRepository,
  name: r'shuffleRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$shuffleRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ShuffleRepositoryRef = ProviderRef<ShuffleRepository>;
String _$shuffleStateHash() => r'fc2c9f220b0ccc4b086b2d9aebed667db02e0b67';

/// See also [ShuffleState].
@ProviderFor(ShuffleState)
final shuffleStateProvider =
    NotifierProvider<ShuffleState, ShuffleResult?>.internal(
  ShuffleState.new,
  name: r'shuffleStateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$shuffleStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ShuffleState = Notifier<ShuffleResult?>;
String _$shuffleConfigNotifierHash() =>
    r'95d5d3c9348815d66396271a7bbf04f674cdeaae';

/// See also [ShuffleConfigNotifier].
@ProviderFor(ShuffleConfigNotifier)
final shuffleConfigNotifierProvider =
    AutoDisposeNotifierProvider<ShuffleConfigNotifier, ShuffleConfig>.internal(
  ShuffleConfigNotifier.new,
  name: r'shuffleConfigNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$shuffleConfigNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ShuffleConfigNotifier = AutoDisposeNotifier<ShuffleConfig>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
