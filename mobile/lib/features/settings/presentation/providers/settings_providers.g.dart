// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userSettingsRepositoryHash() =>
    r'd99383504738ba658ea34ab916eba06f68de2e26';

/// See also [userSettingsRepository].
@ProviderFor(userSettingsRepository)
final userSettingsRepositoryProvider =
    Provider<UserSettingsRepository>.internal(
  userSettingsRepository,
  name: r'userSettingsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userSettingsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserSettingsRepositoryRef = ProviderRef<UserSettingsRepository>;
String _$userSettingsHash() => r'491adf7974c8218fa943be6f2ae8573734cac262';

/// See also [userSettings].
@ProviderFor(userSettings)
final userSettingsProvider = AutoDisposeStreamProvider<UserSettings>.internal(
  userSettings,
  name: r'userSettingsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$userSettingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserSettingsRef = AutoDisposeStreamProviderRef<UserSettings>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
