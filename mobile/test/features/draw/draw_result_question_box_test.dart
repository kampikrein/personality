// TDD Red — Cycle 3 (intent_placement_setting pipeline)
// Spec:  docs/2_tarot_draw/03_draw_experience_settings/050_TDD_Red_cycle3_flow_integration.md
// Scope: docs/2_tarot_draw/03_draw_experience_settings/041_Scope_intent_placement_setting.md
//
// Purpose
// -------
// Widget tests for DrawResultPage question toggle box visibility:
//   T8a — intentPlacement = afterDraw   → '질문이 있으신가요?' toggle visible
//   T8b — intentPlacement = beforeShuffle → toggle hidden
//   T8c — intentPlacement = disabled    → toggle hidden
//
// Red expectation
// ---------------
// DrawResultPage does not check intentPlacement — it always renders the toggle.
// T8b and T8c will fail (expect hidden, find visible).
//
// Green target (cycle 3 impl)
// ---------------------------
// In DrawResultPage.build: read intentPlacement from userSettingsProvider.
// Render the question toggle GestureDetector only when intentPlacement == afterDraw.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:personality_mobile/features/deck/domain/entities/card_meanings.dart';
import 'package:personality_mobile/features/deck/domain/entities/deck_metadata.dart';
import 'package:personality_mobile/features/deck/domain/entities/tarot_card.dart';
import 'package:personality_mobile/features/deck/domain/repositories/deck_repository.dart';
import 'package:personality_mobile/features/deck/presentation/providers/deck_providers.dart';
import 'package:personality_mobile/features/draw/presentation/pages/draw_result_page.dart';
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
  Future<List<TarotCard>> getCardsByDeckId(String deckId) async => [
        const TarotCard(
          id: 'card-01',
          deckId: 'rws-standard',
          cardId: 'fool',
          name: 'The Fool',
          arcana: 'major',
          number: 0,
          imagePath: 'assets/cards/rws/fool.jpg',
          meanings: CardMeanings(),
        ),
        const TarotCard(
          id: 'card-02',
          deckId: 'rws-standard',
          cardId: 'magician',
          name: 'The Magician',
          arcana: 'major',
          number: 1,
          imagePath: 'assets/cards/rws/magician.jpg',
          meanings: CardMeanings(),
        ),
        const TarotCard(
          id: 'card-03',
          deckId: 'rws-standard',
          cardId: 'high_priestess',
          name: 'The High Priestess',
          arcana: 'major',
          number: 2,
          imagePath: 'assets/cards/rws/high_priestess.jpg',
          meanings: CardMeanings(),
        ),
      ];
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
      experienceLevel: 1,
      defaultCardCount: 1,
      showFaceUp: false,
      quickDrawEnabled: false,
      defaultLayoutType: LayoutType.linear,
      showCardName: true,
      allowReversed: false,
      cardsPerRow: 3,
      cardSizePreset: CardSizePreset.standardTarot,
      customCardWidthMm: 70.0,
      customCardHeightMm: 120.0,
      updatedAt: DateTime(2026, 1, 1),
      intentPlacement: intentPlacement,
    );

Widget _buildHost({required IntentPlacement intentPlacement}) {
  final repo = _FakeSettingsRepo(_seedSettings(intentPlacement: intentPlacement));
  return ProviderScope(
    overrides: [
      deckRepositoryProvider.overrideWithValue(_FakeDeckRepo()),
      userSettingsRepositoryProvider.overrideWithValue(repo),
      userSettingsProvider.overrideWith((ref) => repo.watchSettings()),
      watchDecksProvider.overrideWith(
          (ref) => Stream.value(<DeckMetadata>[_fakeDeck()])),
    ],
    child: const MaterialApp(
      home: DrawResultPage(),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 200));
}

/// 질문 토글 찾기 — '질문이 있으신가요?' 텍스트를 포함하는 Finder
Finder _questionToggleFinder() => find.textContaining('질문이 있으신가요?');

void main() {
  // -----------------------------------------------------------------------
  // T8a — afterDraw: question toggle is visible
  // -----------------------------------------------------------------------
  testWidgets(
    'T8a DrawResultPage with afterDraw renders the question toggle box',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildHost(intentPlacement: IntentPlacement.afterDraw));
      await _settle(tester);

      expect(
        _questionToggleFinder(),
        findsOneWidget,
        reason: 'afterDraw: the question toggle ("질문이 있으신가요?") must be visible '
            'so users can record their question after drawing',
      );
    },
  );

  // -----------------------------------------------------------------------
  // T8b — beforeShuffle: question toggle is hidden
  // -----------------------------------------------------------------------
  testWidgets(
    'T8b DrawResultPage with beforeShuffle hides the question toggle box',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildHost(intentPlacement: IntentPlacement.beforeShuffle));
      await _settle(tester);

      expect(
        _questionToggleFinder(),
        findsNothing,
        reason: 'beforeShuffle: question was entered before shuffle → '
            'the toggle box must NOT render on the result page',
      );
    },
  );

  // -----------------------------------------------------------------------
  // T8c — disabled: question toggle is hidden
  // -----------------------------------------------------------------------
  testWidgets(
    'T8c DrawResultPage with disabled hides the question toggle box',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildHost(intentPlacement: IntentPlacement.disabled));
      await _settle(tester);

      expect(
        _questionToggleFinder(),
        findsNothing,
        reason: 'disabled: intent input is off → '
            'the toggle box must NOT render on the result page',
      );
    },
  );
}
