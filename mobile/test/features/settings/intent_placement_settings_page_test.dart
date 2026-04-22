// TDD Red — Cycle 2 (intent_placement_setting pipeline)
// Spec:  docs/2_tarot_draw/03_draw_experience_settings/046_TDD_Red_cycle2_settings_ui.md
// Scope: docs/2_tarot_draw/03_draw_experience_settings/041_Scope_intent_placement_setting.md
//
// Purpose
// -------
// Failing widget tests for IntentPlacementSettingsPage:
//   T1 — 3 option labels visible
//   T2 — selected option shows check indicator
//   T3 — tapping another option calls repo.updateIntentPlacement
//
// Red expectation
// ---------------
// IntentPlacementSettingsPage does not exist yet → import fails → RED.
//
// Green target (cycle 2 impl)
// ---------------------------
// Create mobile/lib/features/settings/presentation/pages/intent_placement_settings_page.dart
// with 3-way selector UI matching the label spec defined in these tests.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:personality_mobile/features/settings/domain/entities/card_size_preset.dart';
import 'package:personality_mobile/features/settings/domain/entities/intent_placement.dart';
import 'package:personality_mobile/features/settings/domain/entities/user_settings.dart';
import 'package:personality_mobile/features/settings/domain/repositories/user_settings_repository.dart';
import 'package:personality_mobile/features/settings/presentation/pages/intent_placement_settings_page.dart';
import 'package:personality_mobile/features/settings/presentation/providers/settings_providers.dart';
import 'package:personality_mobile/features/reading/domain/entities/layout_type.dart';

// ---------------------------------------------------------------------------
// Fake repo — captures updateIntentPlacement calls
// ---------------------------------------------------------------------------

class _FakeSettingsRepo implements UserSettingsRepository {
  final UserSettings _settings;
  IntentPlacement? capturedValue;

  _FakeSettingsRepo(this._settings);

  @override
  Stream<UserSettings> watchSettings() => Stream.value(_settings);

  @override
  Future<UserSettings> getSettings() async => _settings;

  @override
  Future<void> updateIntentPlacement(IntentPlacement value) async {
    capturedValue = value;
  }

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

UserSettings _seedSettings({IntentPlacement intent = IntentPlacement.beforeShuffle}) {
  return UserSettings(
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
    intentPlacement: intent,
  );
}

Widget _pumpPage({required _FakeSettingsRepo repo}) {
  return ProviderScope(
    overrides: [
      userSettingsRepositoryProvider.overrideWithValue(repo),
      userSettingsProvider.overrideWith((ref) => repo.watchSettings()),
    ],
    child: const MaterialApp(
      home: IntentPlacementSettingsPage(),
    ),
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

void main() {
  // -----------------------------------------------------------------------
  // T1 — 3 option labels rendered
  // -----------------------------------------------------------------------
  testWidgets(
    'T1 IntentPlacementSettingsPage renders 3 option labels',
    (WidgetTester tester) async {
      final repo = _FakeSettingsRepo(_seedSettings());
      await tester.pumpWidget(_pumpPage(repo: repo));
      await _settle(tester);

      expect(
        find.text('뽑기 전 입력'),
        findsOneWidget,
        reason: 'IntentPlacement.beforeShuffle label must render',
      );
      expect(
        find.text('뽑은 후 입력'),
        findsOneWidget,
        reason: 'IntentPlacement.afterDraw label must render',
      );
      expect(
        find.text('의도 입력 비활성'),
        findsOneWidget,
        reason: 'IntentPlacement.disabled label must render',
      );
    },
  );

  // -----------------------------------------------------------------------
  // T2 — selected option shows check icon
  // -----------------------------------------------------------------------
  testWidgets(
    'T2 selected IntentPlacement option shows check indicator',
    (WidgetTester tester) async {
      final repo = _FakeSettingsRepo(_seedSettings(intent: IntentPlacement.beforeShuffle));
      await tester.pumpWidget(_pumpPage(repo: repo));
      await _settle(tester);

      // The check icon (Icons.check_rounded) must exist for the selected row.
      expect(
        find.byIcon(Icons.check_rounded),
        findsOneWidget,
        reason: 'selected option must show a check icon',
      );
    },
  );

  // -----------------------------------------------------------------------
  // T3 — tapping another row calls updateIntentPlacement
  // -----------------------------------------------------------------------
  testWidgets(
    'T3 tapping another option row calls repo.updateIntentPlacement',
    (WidgetTester tester) async {
      final repo = _FakeSettingsRepo(_seedSettings(intent: IntentPlacement.beforeShuffle));
      await tester.pumpWidget(_pumpPage(repo: repo));
      await _settle(tester);

      await tester.tap(find.text('뽑은 후 입력'));
      await _settle(tester);

      expect(
        repo.capturedValue,
        equals(IntentPlacement.afterDraw),
        reason: 'tapping afterDraw row must call updateIntentPlacement(IntentPlacement.afterDraw)',
      );
    },
  );
}
