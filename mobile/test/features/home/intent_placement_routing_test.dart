// TDD Red — Cycle 3 (intent_placement_setting pipeline)
// Spec:  docs/2_tarot_draw/03_draw_experience_settings/050_TDD_Red_cycle3_flow_integration.md
// Scope: docs/2_tarot_draw/03_draw_experience_settings/041_Scope_intent_placement_setting.md
//
// Purpose
// -------
// Widget tests for HomePage._startDraw routing branch by intentPlacement:
//   T3 — Lv4 + beforeShuffle → navigates to /intention/:deckId
//   T4 — Lv4 + afterDraw    → navigates to /shuffle/:deckId (skips intention)
//   T5 — Lv4 + disabled     → navigates to /shuffle/:deckId (skips intention)
//
// Red expectation
// ---------------
// _startDraw in home_page.dart does not check intentPlacement → T4 and T5
// will observe navigation to /intention/... and fail (expect /shuffle/...).
//
// Green target (cycle 3 impl)
// ---------------------------
// In _startDraw (cases 3 & 4): read intentPlacement from settings.
// If intentPlacement != beforeShuffle → pushNamed('shuffle', ...) directly.

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
  final UserSettings _settings;
  _FakeSettingsRepo(this._settings);

  @override
  Stream<UserSettings> watchSettings() => Stream.value(_settings);
  @override
  Future<UserSettings> getSettings() async => _settings;
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

UserSettings _seedSettings({required IntentPlacement intentPlacement}) => UserSettings(
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
      intentPlacement: intentPlacement,
    );

// ---------------------------------------------------------------------------
// Test helper: tracks GoRouter location via NavigatorObserver
// ---------------------------------------------------------------------------

class _LocationTracker extends NavigatorObserver {
  String? lastPushedRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      lastPushedRoute = name;
    }
  }
}

// Tracks whether we ended up on the intention or shuffle sub-route.
// We intercept this by checking the final visible text on stub pages.
Widget _buildHost({
  required UserSettings settings,
  required String trackerKey,
}) {
  final repo = _FakeSettingsRepo(settings);

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
        routes: [
          GoRoute(
            path: 'intention/:deckId',
            name: 'intention',
            builder: (context, state) =>
                const Scaffold(body: Text('IntentionPage')),
          ),
          GoRoute(
            path: 'shuffle/:deckId',
            name: 'shuffle',
            builder: (context, state) =>
                const Scaffold(body: Text('ShufflePage')),
          ),
          GoRoute(
            path: 'draw/result',
            builder: (context, state) =>
                const Scaffold(body: Text('DrawResultPage')),
          ),
          GoRoute(
            path: 'draw/animated',
            builder: (context, state) =>
                const Scaffold(body: Text('AnimatedDrawPage')),
          ),
          GoRoute(
            path: 'deck/selection',
            builder: (context, state) => const Scaffold(),
          ),
          GoRoute(
            path: 'settings/intent-placement',
            name: 'intent-placement-settings',
            builder: (context, state) => const Scaffold(),
          ),
          GoRoute(
            path: 'settings/card-size',
            name: 'card-size-settings',
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
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _pumpNavSequence(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  // -----------------------------------------------------------------------
  // T3 — Lv4 + beforeShuffle → navigates to IntentionPage
  // -----------------------------------------------------------------------
  testWidgets(
    'T3 Lv4 + beforeShuffle: _startDraw navigates to /intention/:deckId',
    (WidgetTester tester) async {
      final settings = _seedSettings(intentPlacement: IntentPlacement.beforeShuffle);
      await tester.pumpWidget(_buildHost(settings: settings, trackerKey: 'T3'));
      await _settle(tester);

      // Tap the draw hero button (타로 드로우 시작)
      final drawBtn = find.byType(GestureDetector).first;
      await tester.tap(drawBtn, warnIfMissed: false);
      await _pumpNavSequence(tester);

      expect(
        find.text('IntentionPage'),
        findsOneWidget,
        reason: 'beforeShuffle + Lv4: must navigate to IntentionPage '
            '(pass through /intention/:deckId)',
      );
    },
  );

  // -----------------------------------------------------------------------
  // T4 — Lv4 + afterDraw → navigates to ShufflePage (skips intention)
  // -----------------------------------------------------------------------
  testWidgets(
    'T4 Lv4 + afterDraw: _startDraw skips IntentionPage and goes to /shuffle/:deckId',
    (WidgetTester tester) async {
      final settings = _seedSettings(intentPlacement: IntentPlacement.afterDraw);
      await tester.pumpWidget(_buildHost(settings: settings, trackerKey: 'T4'));
      await _settle(tester);

      final drawBtn = find.byType(GestureDetector).first;
      await tester.tap(drawBtn, warnIfMissed: false);
      await _pumpNavSequence(tester);

      expect(
        find.text('ShufflePage'),
        findsOneWidget,
        reason: 'afterDraw + Lv4: must skip IntentionPage and navigate to '
            'ShufflePage (/shuffle/:deckId)',
      );
      expect(
        find.text('IntentionPage'),
        findsNothing,
        reason: 'IntentionPage must NOT be on the route stack',
      );
    },
  );

  // -----------------------------------------------------------------------
  // T5 — Lv4 + disabled → navigates to ShufflePage (skips intention)
  // -----------------------------------------------------------------------
  testWidgets(
    'T5 Lv4 + disabled: _startDraw skips IntentionPage and goes to /shuffle/:deckId',
    (WidgetTester tester) async {
      final settings = _seedSettings(intentPlacement: IntentPlacement.disabled);
      await tester.pumpWidget(_buildHost(settings: settings, trackerKey: 'T5'));
      await _settle(tester);

      final drawBtn = find.byType(GestureDetector).first;
      await tester.tap(drawBtn, warnIfMissed: false);
      await _pumpNavSequence(tester);

      expect(
        find.text('ShufflePage'),
        findsOneWidget,
        reason: 'disabled + Lv4: must skip IntentionPage and navigate to '
            'ShufflePage (/shuffle/:deckId)',
      );
      expect(
        find.text('IntentionPage'),
        findsNothing,
        reason: 'IntentionPage must NOT be on the route stack',
      );
    },
  );
}
