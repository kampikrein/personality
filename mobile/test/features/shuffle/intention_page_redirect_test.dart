// TDD Red — Cycle 3 (intent_placement_setting pipeline)
// Spec:  docs/2_tarot_draw/03_draw_experience_settings/050_TDD_Red_cycle3_flow_integration.md
// Scope: docs/2_tarot_draw/03_draw_experience_settings/041_Scope_intent_placement_setting.md
//
// Purpose
// -------
// Widget tests for IntentionPage addPostFrameCallback redirect:
//   T6 — intentPlacement = afterDraw  → redirect to shuffle
//   T7 — intentPlacement = beforeShuffle → no redirect, body renders normally
//
// Red expectation
// ---------------
// IntentionPage.build does not read intentPlacement → no redirect fires → T6 fails.
//
// Green target (cycle 3 impl)
// ---------------------------
// In IntentionPage.initState (or build via addPostFrameCallback):
//   read intentPlacement from userSettingsProvider.
//   If != beforeShuffle → pushReplacementNamed('shuffle', pathParameters: {'deckId': widget.deckId}, ...).
//   During the redirect frame render SizedBox.shrink().

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:personality_mobile/features/reading/domain/entities/layout_type.dart';
import 'package:personality_mobile/features/settings/domain/entities/card_size_preset.dart';
import 'package:personality_mobile/features/settings/domain/entities/intent_placement.dart';
import 'package:personality_mobile/features/settings/domain/entities/user_settings.dart';
import 'package:personality_mobile/features/settings/domain/repositories/user_settings_repository.dart';
import 'package:personality_mobile/features/settings/presentation/providers/settings_providers.dart';
import 'package:personality_mobile/features/shuffle/presentation/pages/intention_page.dart';

// ---------------------------------------------------------------------------
// Fake settings repo
// ---------------------------------------------------------------------------

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

Widget _buildHost({
  required IntentPlacement intentPlacement,
}) {
  final repo = _FakeSettingsRepo(_seedSettings(intentPlacement: intentPlacement));

  final router = GoRouter(
    initialLocation: '/intention/rws-standard',
    routes: [
      GoRoute(
        path: '/intention/:deckId',
        name: 'intention',
        builder: (context, state) => IntentionPage(
          deckId: state.pathParameters['deckId'] ?? 'rws-standard',
        ),
      ),
      GoRoute(
        path: '/shuffle/:deckId',
        name: 'shuffle',
        builder: (context, state) =>
            const Scaffold(body: Text('ShufflePage')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      userSettingsRepositoryProvider.overrideWithValue(repo),
      userSettingsProvider.overrideWith((ref) => repo.watchSettings()),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _settle(WidgetTester tester) async {
  // addPostFrameCallback fires after first frame
  await tester.pump(); // build
  await tester.pump(); // postFrameCallback
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  // -----------------------------------------------------------------------
  // T6 — afterDraw: IntentionPage redirects to shuffle
  // -----------------------------------------------------------------------
  testWidgets(
    'T6 IntentionPage with afterDraw redirects to ShufflePage via pushReplacementNamed',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildHost(intentPlacement: IntentPlacement.afterDraw));
      await _settle(tester);

      expect(
        find.text('ShufflePage'),
        findsOneWidget,
        reason: 'afterDraw: IntentionPage must redirect to /shuffle/:deckId '
            'via pushReplacementNamed in addPostFrameCallback',
      );
      expect(
        find.text('잠시 눈을 감고'),
        findsNothing,
        reason: 'IntentionPage body must not be visible after redirect',
      );
    },
  );

  // -----------------------------------------------------------------------
  // T7 — beforeShuffle: IntentionPage renders normally, no redirect
  // -----------------------------------------------------------------------
  testWidgets(
    'T7 IntentionPage with beforeShuffle renders body without redirecting',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildHost(intentPlacement: IntentPlacement.beforeShuffle));
      await _settle(tester);

      // ShufflePage must NOT appear (no redirect).
      expect(
        find.text('ShufflePage'),
        findsNothing,
        reason: 'ShufflePage must not appear — no redirect should fire for beforeShuffle',
      );
      // IntentionPage's key widget (button to proceed to shuffle) must be visible.
      expect(
        find.text('셔플로 이동'),
        findsOneWidget,
        reason: 'beforeShuffle: IntentionPage must render its body with "셔플로 이동" button',
      );
    },
  );
}
