// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draw_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$executeDrawHash() => r'e0d708fe5e7bedb5ce8f5feebd542ba1210bda40';

/// Level 1/2 뽑기에서 사용할 셔플 실행 use case.
/// 호출 시 UserSettings의 selectedDeckId를 사용하여 셔플하고,
/// ShuffleState에 결과를 세팅한 뒤 ShuffleResult를 반환.
///
/// Copied from [executeDraw].
@ProviderFor(executeDraw)
final executeDrawProvider = AutoDisposeFutureProvider<ShuffleResult>.internal(
  executeDraw,
  name: r'executeDrawProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$executeDrawHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ExecuteDrawRef = AutoDisposeFutureProviderRef<ShuffleResult>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
