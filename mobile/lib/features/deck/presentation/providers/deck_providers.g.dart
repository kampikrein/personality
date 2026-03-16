// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deck_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$deckRepositoryHash() => r'c66025b67a201ea869f0e89a4c8ab2679949fd04';

/// See also [deckRepository].
@ProviderFor(deckRepository)
final deckRepositoryProvider = Provider<DeckRepository>.internal(
  deckRepository,
  name: r'deckRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$deckRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DeckRepositoryRef = ProviderRef<DeckRepository>;
String _$watchDecksHash() => r'd893b2633fdc7e71f6641df7f7b7014f9652e790';

/// See also [watchDecks].
@ProviderFor(watchDecks)
final watchDecksProvider =
    AutoDisposeStreamProvider<List<DeckMetadata>>.internal(
  watchDecks,
  name: r'watchDecksProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$watchDecksHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WatchDecksRef = AutoDisposeStreamProviderRef<List<DeckMetadata>>;
String _$deckCardsHash() => r'b5d7516d55710fa1ebe57c1483d6ca23ec1192e7';

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

/// See also [deckCards].
@ProviderFor(deckCards)
const deckCardsProvider = DeckCardsFamily();

/// See also [deckCards].
class DeckCardsFamily extends Family<AsyncValue<List<TarotCard>>> {
  /// See also [deckCards].
  const DeckCardsFamily();

  /// See also [deckCards].
  DeckCardsProvider call(
    String deckId,
  ) {
    return DeckCardsProvider(
      deckId,
    );
  }

  @override
  DeckCardsProvider getProviderOverride(
    covariant DeckCardsProvider provider,
  ) {
    return call(
      provider.deckId,
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
  String? get name => r'deckCardsProvider';
}

/// See also [deckCards].
class DeckCardsProvider extends AutoDisposeFutureProvider<List<TarotCard>> {
  /// See also [deckCards].
  DeckCardsProvider(
    String deckId,
  ) : this._internal(
          (ref) => deckCards(
            ref as DeckCardsRef,
            deckId,
          ),
          from: deckCardsProvider,
          name: r'deckCardsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$deckCardsHash,
          dependencies: DeckCardsFamily._dependencies,
          allTransitiveDependencies: DeckCardsFamily._allTransitiveDependencies,
          deckId: deckId,
        );

  DeckCardsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.deckId,
  }) : super.internal();

  final String deckId;

  @override
  Override overrideWith(
    FutureOr<List<TarotCard>> Function(DeckCardsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DeckCardsProvider._internal(
        (ref) => create(ref as DeckCardsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        deckId: deckId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<TarotCard>> createElement() {
    return _DeckCardsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DeckCardsProvider && other.deckId == deckId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, deckId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DeckCardsRef on AutoDisposeFutureProviderRef<List<TarotCard>> {
  /// The parameter `deckId` of this provider.
  String get deckId;
}

class _DeckCardsProviderElement
    extends AutoDisposeFutureProviderElement<List<TarotCard>>
    with DeckCardsRef {
  _DeckCardsProviderElement(super.provider);

  @override
  String get deckId => (origin as DeckCardsProvider).deckId;
}

String _$selectedDeckHash() => r'3d0e4d1e48926035350a331595863be5edcadf82';

/// See also [SelectedDeck].
@ProviderFor(SelectedDeck)
final selectedDeckProvider =
    AutoDisposeNotifierProvider<SelectedDeck, DeckMetadata?>.internal(
  SelectedDeck.new,
  name: r'selectedDeckProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$selectedDeckHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedDeck = AutoDisposeNotifier<DeckMetadata?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
