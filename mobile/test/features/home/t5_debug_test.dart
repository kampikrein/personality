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

class _FakeDeckRepo implements DeckRepository {
  @override Future<List<DeckMetadata>> getAllDecks() async => [_fakeDeck()];
  @override Stream<List<DeckMetadata>> watchAllDecks() => Stream.value([_fakeDeck()]);
  @override Future<DeckMetadata?> getDeckById(String id) async => _fakeDeck();
  @override Future<List<TarotCard>> getCardsByDeckId(String deckId) async => const [];
  @override Future<void> seedAllDecks() async {}
  @override Future<bool> hasAnyDecks() async => true;
}

class _FakeSettingsRepo implements UserSettingsRepository {
  final UserSettings _current;
  _FakeSettingsRepo(this._current);
  @override Stream<UserSettings> watchSettings() => Stream.value(_current);
  @override Future<UserSettings> getSettings() async => _current;
  @override Future<void> updateIntentPlacement(IntentPlacement value) async {}
  @override Future<void> updateSelectedDeckId(String deckId) async {}
  @override Future<void> updateExperienceLevel(int level) async {}
  @override Future<void> updateDefaultCardCount(int count) async {}
  @override Future<void> updateShowFaceUp(bool showFaceUp) async {}
  @override Future<void> updateQuickDrawEnabled(bool enabled) async {}
  @override Future<void> updateDefaultLayoutType(String layoutTypeName) async {}
  @override Future<void> updateShowCardName(bool showCardName) async {}
  @override Future<void> updateAllowReversed(bool allowReversed) async {}
  @override Future<void> updateCardSizePreset(String presetName) async {}
  @override Future<void> updateCustomCardSize(double widthMm, double heightMm) async {}
  @override Future<void> updateCardsPerRow(int count) async {}
}

DeckMetadata _fakeDeck() => DeckMetadata(id: 'rws-standard', name: 'Rider-Waite', isStandardTarot: true, totalCards: 78, createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1));

UserSettings _seedSettings() => UserSettings(selectedDeckId: 'rws-standard', experienceLevel: 4, defaultCardCount: 3, showFaceUp: false, quickDrawEnabled: false, defaultLayoutType: LayoutType.linear, showCardName: true, allowReversed: true, cardsPerRow: 3, cardSizePreset: CardSizePreset.standardTarot, customCardWidthMm: 70.0, customCardHeightMm: 120.0, updatedAt: DateTime(2026, 1, 1), intentPlacement: IntentPlacement.beforeShuffle);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(() async { await Future<void>.delayed(const Duration(milliseconds: 10)); });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('T5 debug', (WidgetTester tester) async {
    final repo = _FakeSettingsRepo(_seedSettings());
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomePage(),
          routes: [
            GoRoute(
              path: 'settings/intent-placement',
              name: 'intent-placement-settings',
              builder: (context, state) => const Scaffold(body: Text('IntentPlacementSettingsPage')),
            ),
            GoRoute(path: 'settings/card-size', name: 'card-size-settings', builder: (context, state) => const Scaffold(body: Text('CardSizeSettingsPage'))),
            GoRoute(path: 'deck/selection', builder: (context, state) => const Scaffold()),
          ],
        ),
      ],
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        deckRepositoryProvider.overrideWithValue(_FakeDeckRepo()),
        userSettingsRepositoryProvider.overrideWithValue(repo),
        userSettingsProvider.overrideWith((ref) => repo.watchSettings()),
        watchDecksProvider.overrideWith((ref) => Stream.value(<DeckMetadata>[_fakeDeck()])),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await _settle(tester);

    // Check what's on screen
    final intentCount = find.text('의도 입력').evaluate().length;
    print('=== 의도 입력 count after settle: $intentCount ===');
    
    // Try to open the settings panel first - look for any relevant widgets
    final settingsPanelTrigger = find.text('바로 뽑기');
    print('바로 뽑기 count: ${settingsPanelTrigger.evaluate().length}');
    
    // Look for what's visible
    final allTexts = tester.widgetList(find.byType(Text)).map((w) => (w as Text).data).where((t) => t != null && t.isNotEmpty).toList();
    print('Visible texts (first 20): ${allTexts.take(20).toList()}');
  });
}
