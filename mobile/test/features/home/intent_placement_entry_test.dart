// TDD Red — Cycle 2 (intent_placement_setting pipeline)
// Spec:  docs/2_tarot_draw/03_draw_experience_settings/046_TDD_Red_cycle2_settings_ui.md
// Scope: docs/2_tarot_draw/03_draw_experience_settings/041_Scope_intent_placement_setting.md
//
// Purpose
// -------
// Failing widget tests for HomePage._DrawSettingsPanel entry row:
//   T4 — '의도 입력' row exists in _DrawSettingsPanel
//   T5 — tapping '의도 입력' navigates to /settings/intent-placement
//
// Red expectation
// ---------------
// T4 fails because '의도 입력' row has not been added to _DrawSettingsPanel yet.
// T5 fails for the same reason (tap target doesn't exist).
//
// Green target (cycle 2 impl)
// ---------------------------
// Add '의도 입력' GestureDetector row to _DrawSettingsPanel in home_page.dart,
// register GoRoute('/settings/intent-placement') in app_router.dart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:personality_mobile/features/deck/domain/entities/deck_metadata.dart';
import 'package:personality_mobile/features/deck/domain/entities/tarot_card.dart';
import 'package:personality_mobile/features/deck/domain/repositories/deck_repository.dart';
import 'package:personality_mobile/features/deck/presentation/providers/deck_providers.dart';
import 'package:personality_mobile/features/home/presentation/pages/home_page.dart';
import 'package:personality_mobile/features/reading/domain/entities/layout_type.dart';
import 'package:personality_mobile/features/settings/domain/entities/card_size_preset.dart';
import 'package:personality_mobile/features/settings/domain/entities/intent_placement.dart';
import 'package:personality_mobile/features/settings/domain/entities/user_settings.dart';
import 'package:personality_mobile/features/settings/domain/repositories/user_settings_repository.dart';
import 'package:personality_mobile/features/settings/presentation/providers/settings_providers.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeDeckRepo implements DeckRepository {
  @override
  Future<List<DeckMetadata>> getAllDecks() async => [_fakeDeck()];
  @override
  Stream<List<DeckMetadata>> watchAllDecks() => Stream.value([_fakeDeck()]);
  @override
  Future<DeckMetadata?> getDeckById(String id) async => _fakeDeck();
  @override
  Future<List<TarotCard>> getCardsByDeckId(String deckId) async => const [];
  @override
  Future<void> seedAllDecks() async {}
  @override
  Future<bool> hasAnyDecks() async => true;
}

class _FakeSettingsRepo implements UserSettingsRepository {
  final UserSettings _current;
  _FakeSettingsRepo(this._current);

  @override
  Stream<UserSettings> watchSettings() => Stream.value(_current);
  @override
  Future<UserSettings> getSettings() async => _current;
  @override
  Future<void> updateIntentPlacement(IntentPlacement value) async {}
  @override
  Future<void> updateSelectedDeckId(String deckId) async {}
  @override
  Future<void> updateExperienceLevel(int level) async {}
  @override
  Future<void> updateDefaultCardCount(int count) async {}
  @override
  Future<void> updateShowFaceUp(bool showFaceUp) async {}
  @override
  Future<void> updateQuickDrawEnabled(bool enabled) async {}
  @override
  Future<void> updateDefaultLayoutType(String layoutTypeName) async {}
  @override
  Future<void> updateShowCardName(bool showCardName) async {}
  @override
  Future<void> updateAllowReversed(bool allowReversed) async {}
  @override
  Future<void> updateCardSizePreset(String presetName) async {}
  @override
  Future<void> updateCustomCardSize(double widthMm, double heightMm) async {}
  @override
  Future<void> updateCardsPerRow(int count) async {}
}

DeckMetadata _fakeDeck() => DeckMetadata(
      id: 'rws-standard',
      name: 'Rider-Waite',
      isStandardTarot: true,
      totalCards: 78,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

UserSettings _seedSettings() => UserSettings(
      selectedDeckId: 'rws-standard',
      experienceLevel: 4,
      defaultCardCount: 3,
      showFaceUp: false,
      quickDrawEnabled: false,
      defaultLayoutType: LayoutType.linear,
      showCardName: true,
      allowReversed: true,
      cardsPerRow: 3,
      cardSizePreset: CardSizePreset.standardTarot,
      customCardWidthMm: 70.0,
      customCardHeightMm: 120.0,
      updatedAt: DateTime(2026, 1, 1),
      intentPlacement: IntentPlacement.beforeShuffle,
    );

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

// ---------------------------------------------------------------------------
// Router-aware host: records pushed locations
// ---------------------------------------------------------------------------

class _NavigationObserver extends NavigatorObserver {
  final List<String> pushedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name;
    if (name != null) pushedRoutes.add(name);
  }
}

Widget _hostWithRouter({
  required UserSettings initial,
  required _FakeSettingsRepo repo,
  required _NavigationObserver observer,
}) {
  // Use GoRouter with a stub /settings/intent-placement route so that
  // context.push('/settings/intent-placement') does not throw.
  final router = GoRouter(
    initialLocation: '/',
    observers: [observer],
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
        routes: [
          GoRoute(
            path: 'settings/intent-placement',
            name: 'intent-placement-settings',
            builder: (context, state) =>
                const Scaffold(body: Text('IntentPlacementSettingsPage')),
          ),
          GoRoute(
            path: 'settings/card-size',
            name: 'card-size-settings',
            builder: (context, state) =>
                const Scaffold(body: Text('CardSizeSettingsPage')),
          ),
          GoRoute(
            path: 'deck/selection',
            builder: (context, state) => const Scaffold(),
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      deckRepositoryProvider.overrideWithValue(_FakeDeckRepo()),
      userSettingsRepositoryProvider.overrideWithValue(repo),
      userSettingsProvider.overrideWith((ref) => repo.watchSettings()),
      watchDecksProvider.overrideWith(
          (ref) => Stream.value(<DeckMetadata>[_fakeDeck()])),
    ],
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

void main() {
  // -----------------------------------------------------------------------
  // T4 — '의도 입력' row exists in _DrawSettingsPanel
  // -----------------------------------------------------------------------
  testWidgets(
    'T4 _DrawSettingsPanel contains "의도 입력" entry row',
    (WidgetTester tester) async {
      final repo = _FakeSettingsRepo(_seedSettings());
      final observer = _NavigationObserver();
      await tester.pumpWidget(
        _hostWithRouter(initial: repo._current, repo: repo, observer: observer),
      );
      await _settle(tester);

      expect(
        find.text('의도 입력'),
        findsOneWidget,
        reason: '_DrawSettingsPanel must contain an "의도 입력" navigation row '
            'so users can reach IntentPlacementSettingsPage',
      );
    },
  );

  // -----------------------------------------------------------------------
  // T5 — tapping '의도 입력' navigates to /settings/intent-placement
  // -----------------------------------------------------------------------
  testWidgets(
    'T5 tapping "의도 입력" row navigates to /settings/intent-placement',
    (WidgetTester tester) async {
      final repo = _FakeSettingsRepo(_seedSettings());
      final observer = _NavigationObserver();
      await tester.pumpWidget(
        _hostWithRouter(initial: repo._current, repo: repo, observer: observer),
      );
      await _settle(tester);

      // The widget may be off-screen inside a SingleChildScrollView.
      // Scroll it into view before tapping.
      await tester.ensureVisible(find.text('의도 입력'));
      await tester.pump();

      await tester.tap(find.text('의도 입력'));
      // pumpAndSettle times out when there are infinite animations (e.g. star
      // painter in HomePage).  Use a bounded pump sequence instead.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 200));

      // After navigation, the stub page text must be visible.
      expect(
        find.text('IntentPlacementSettingsPage'),
        findsOneWidget,
        reason: 'tapping "의도 입력" must push /settings/intent-placement route',
      );
    },
  );
}
