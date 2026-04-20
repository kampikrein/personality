// TDD Red — Cycle 5 (layout_redesign pipeline)
// Spec:  docs/2_tarot_draw/03_draw_experience_settings/030_TDD_Red_home_panel_layout.md
// Scope: docs/2_tarot_draw/03_draw_experience_settings/017_Scope_layout_redesign.md
// Brief: docs/2_tarot_draw/03_draw_experience_settings/011_Brief_layout_redesign.md
//
// Purpose
// -------
// These widget tests encode the visible contract of the cycle-5
// `_DrawSettingsPanel` restructure in
// `lib/features/home/presentation/pages/home_page.dart`:
//
//   - 3-group layout: 기본 설정 / 모양 / 표시 옵션 (Decision 4, Criteria #6)
//   - `_PillSelector<LayoutType>` replacing the deleted SpreadType
//   - cardCount stepper min/max bound to selected LayoutType, auto-clamps
//     out-of-range values to `defaultCardCount` (Decision 4, Criteria #7)
//   - SnackBar "이전 값 복원" action on layout change (Decision 4)
//   - cardsPerRow control disabled when tShape / grid3x3 (Criteria #8)
//   - "드로우 순서" row only on grid3x3, "기본" enabled + "다른 순서 (준비 중)"
//     disabled (Decision 12, Criteria #14)
//
// Red expectation
// ---------------
// `home_page.dart:8` still imports the deleted `spread_type.dart`, so the
// production library fails to compile and transitively fails this test
// file. Even after the import is updated, T1/T2/T4 remain red because
// the "모양" group header, SnackBar undo, and "드로우 순서" row do not
// exist yet.
//
// Green target (cycle 5 impl — seq 19)
// ------------------------------------
// Rewrite `_DrawSettingsPanel` per Brief 011 Model Anchors §
// 그룹 구조 재배치 + 자동 조정 원칙 + Decision 12.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:personality_mobile/features/deck/domain/entities/deck_metadata.dart';
import 'package:personality_mobile/features/deck/presentation/providers/deck_providers.dart';
import 'package:personality_mobile/features/home/presentation/pages/home_page.dart';
import 'package:personality_mobile/features/reading/domain/entities/layout_type.dart';
import 'package:personality_mobile/features/settings/domain/entities/card_size_preset.dart';
import 'package:personality_mobile/features/settings/domain/entities/user_settings.dart';
import 'package:personality_mobile/features/settings/domain/repositories/user_settings_repository.dart';
import 'package:personality_mobile/features/settings/presentation/providers/settings_providers.dart';
import 'package:personality_mobile/features/deck/domain/entities/tarot_card.dart';
import 'package:personality_mobile/features/deck/domain/repositories/deck_repository.dart';

// ---------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------

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

/// Fake repository capturing every update call. Does not persist — the
/// driving source for `userSettingsProvider` in tests is the override
/// stream we build below, not this repo's watch method.
class _FakeSettingsRepo implements UserSettingsRepository {
  UserSettings _current;
  _FakeSettingsRepo(this._current);

  final List<String> updatedLayoutTypes = <String>[];
  final List<int> updatedCardCounts = <int>[];
  final List<int> updatedCardsPerRow = <int>[];

  @override
  Stream<UserSettings> watchSettings() => Stream<UserSettings>.value(_current);

  @override
  Future<UserSettings> getSettings() async => _current;

  @override
  Future<void> updateSelectedDeckId(String deckId) async {}

  @override
  Future<void> updateExperienceLevel(int level) async {}

  @override
  Future<void> updateDefaultCardCount(int count) async {
    updatedCardCounts.add(count);
    _current = _current.copyWith(defaultCardCount: count);
  }

  @override
  Future<void> updateShowFaceUp(bool showFaceUp) async {}

  @override
  Future<void> updateQuickDrawEnabled(bool enabled) async {}

  @override
  Future<void> updateDefaultLayoutType(String layoutTypeName) async {
    updatedLayoutTypes.add(layoutTypeName);
    final next = LayoutType.values.firstWhere(
      (e) => e.name == layoutTypeName,
      orElse: () => LayoutType.linear,
    );
    _current = _current.copyWith(defaultLayoutType: next);
  }

  @override
  Future<void> updateShowCardName(bool showCardName) async {}

  @override
  Future<void> updateAllowReversed(bool allowReversed) async {}

  @override
  Future<void> updateCardSizePreset(String presetName) async {}

  @override
  Future<void> updateCustomCardSize(double widthMm, double heightMm) async {}

  @override
  Future<void> updateCardsPerRow(int count) async {
    updatedCardsPerRow.add(count);
    _current = _current.copyWith(cardsPerRow: count);
  }
}

UserSettings _seedSettings({
  LayoutType defaultLayoutType = LayoutType.linear,
  int defaultCardCount = 3,
  int cardsPerRow = 3,
}) {
  return UserSettings(
    selectedDeckId: 'rws-standard',
    experienceLevel: 4,
    defaultCardCount: defaultCardCount,
    showFaceUp: false,
    quickDrawEnabled: false,
    defaultLayoutType: defaultLayoutType,
    showCardName: true,
    allowReversed: true,
    cardsPerRow: cardsPerRow,
    cardSizePreset: CardSizePreset.standardTarot,
    customCardWidthMm: 70.0,
    customCardHeightMm: 120.0,
    updatedAt: DateTime(2026, 1, 1),
  );
}

DeckMetadata _fakeDeck() => DeckMetadata(
      id: 'rws-standard',
      name: 'Rider-Waite',
      isStandardTarot: true,
      totalCards: 78,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

/// Build a ProviderScope-wrapped HomePage with overrides that short-circuit
/// database access. `userSettingsProvider` is driven directly by a
/// synthetic stream so pumping is deterministic.
Widget _hostHomePage({
  required UserSettings initial,
  required _FakeSettingsRepo repo,
}) {
  return ProviderScope(
    overrides: <Override>[
      deckRepositoryProvider.overrideWithValue(_FakeDeckRepo()),
      userSettingsRepositoryProvider.overrideWithValue(repo),
      userSettingsProvider.overrideWith((ref) => repo.watchSettings()),
      watchDecksProvider.overrideWith((ref) => Stream.value(<DeckMetadata>[_fakeDeck()])),
    ],
    child: MaterialApp(
      home: const HomePage(),
    ),
  );
}

Future<void> _pumpAndSettle(WidgetTester tester) async {
  // Home page animates a glow controller indefinitely — avoid
  // pumpAndSettle (would hang). Four pumps with small gaps let async*
  // stream override drain and provider rebuild propagate.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  // ------------------------------------------------------------------
  // T1 — 3 그룹 헤더 + "한 줄 카드 수" 가 "모양" 그룹 내에 존재
  //      (Brief Decision 4, Ideal Criteria #6)
  // ------------------------------------------------------------------
  testWidgets(
    'T1 _DrawSettingsPanel renders 3 group headers '
    '(기본 설정 / 모양 / 표시 옵션) and "한 줄 카드 수" lives in 모양',
    (WidgetTester tester) async {
      final repo = _FakeSettingsRepo(_seedSettings());
      await tester.pumpWidget(_hostHomePage(initial: repo._current, repo: repo));
      await _pumpAndSettle(tester);

      // 3 group subheaders must all render simultaneously.
      expect(
        find.text('기본 설정'),
        findsOneWidget,
        reason: 'group header "기본 설정" must exist',
      );
      expect(
        find.text('모양'),
        findsOneWidget,
        reason: 'Brief Decision 4: new group header "모양" must be added',
      );
      expect(
        find.text('표시 옵션'),
        findsOneWidget,
        reason: 'group header "표시 옵션" must still exist',
      );

      // "한 줄 카드 수" row must exist AND must appear BEFORE "표시 옵션"
      // (i.e. under the "모양" group in render order). We assert positional
      // ordering by comparing the top-left Y offset of each finder.
      final cardsPerRowLabel = find.text('한 줄 카드 수');
      expect(
        cardsPerRowLabel,
        findsOneWidget,
        reason: '"한 줄 카드 수" row must exist and sit inside 모양 group',
      );

      final modayanCenter = tester.getCenter(find.text('모양'));
      final displayOptsCenter = tester.getCenter(find.text('표시 옵션'));
      final cardsPerRowCenter = tester.getCenter(cardsPerRowLabel);
      expect(
        cardsPerRowCenter.dy > modayanCenter.dy &&
            cardsPerRowCenter.dy < displayOptsCenter.dy,
        isTrue,
        reason: '"한 줄 카드 수" must render between "모양" and "표시 옵션" headers',
      );
    },
  );

  // ------------------------------------------------------------------
  // T2 — grid3x3 선택 시 cardCount 범위가 [9, 10] 으로 전환되고,
  //      현재 값 7 은 defaultCardCount=9 로 auto-reset. SnackBar 에
  //      "이전 값 복원" 액션 노출. (Decision 4, Ideal Criteria #7)
  // ------------------------------------------------------------------
  testWidgets(
    'T2 switching layout to grid3x3 clamps cardCount to defaultCardCount '
    'and shows SnackBar undo action "이전 값 복원"',
    (WidgetTester tester) async {
      final repo = _FakeSettingsRepo(_seedSettings(
        defaultLayoutType: LayoutType.linear,
        defaultCardCount: 7,
      ));
      await tester.pumpWidget(_hostHomePage(initial: repo._current, repo: repo));
      await _pumpAndSettle(tester);

      // Tap the grid3x3 pill. The impl exposes LayoutType.grid3x3 via the
      // PillSelector labelled "3x3" (Brief Model Anchors displayName).
      final grid3x3Pill = find.text('3x3');
      expect(
        grid3x3Pill,
        findsOneWidget,
        reason: 'cycle-5 impl must expose LayoutType.grid3x3 option '
            '(label "3x3")',
      );
      await tester.tap(grid3x3Pill);
      await _pumpAndSettle(tester);

      // cardCount auto-reset: prior value 7 is outside [9,10] so the impl
      // must fall back to LayoutType.grid3x3.defaultCardCount == 9.
      expect(
        repo.updatedCardCounts.contains(9),
        isTrue,
        reason: 'cardCount out of [9,10] must auto-reset to '
            'LayoutType.grid3x3.defaultCardCount (9); '
            'actual updatedCardCounts=${repo.updatedCardCounts}',
      );

      // SnackBar with "이전 값 복원" action must surface. Decision 4 guarantees
      // a 10-second undo affordance immediately after the auto-adjustment.
      expect(
        find.text('이전 값 복원'),
        findsOneWidget,
        reason: 'Brief Decision 4 mandates a SnackBar with "이전 값 복원" '
            'action whenever layout change triggers cardCount reset',
      );
    },
  );

  // ------------------------------------------------------------------
  // T3 — tShape 선택 시 cardsPerRow 슬라이더가 회색 비활성 상태
  //      (Brief Ideal Criteria #8)
  // ------------------------------------------------------------------
  testWidgets(
    'T3 tShape layout renders cardsPerRow control as disabled '
    '(tap on its pills has no effect)',
    (WidgetTester tester) async {
      final repo = _FakeSettingsRepo(_seedSettings(
        defaultLayoutType: LayoutType.tShape,
        defaultCardCount: 4,
        cardsPerRow: 3,
      ));
      await tester.pumpWidget(_hostHomePage(initial: repo._current, repo: repo));
      await _pumpAndSettle(tester);

      // "한 줄 카드 수" row is present.
      expect(find.text('한 줄 카드 수'), findsOneWidget);

      // Attempt to change cardsPerRow by tapping the "2장" pill inside the
      // "한 줄 카드 수" row. In the disabled state the tap must be a no-op —
      // `updateCardsPerRow` on the repo must never fire.
      //
      // Multiple "2장" labels may exist (cardCount pills also show "2장"
      // for linear). We target the "한 줄 카드 수" row by finding the
      // descendant pill of that row.
      final cardsPerRowRow = find.ancestor(
        of: find.text('한 줄 카드 수'),
        matching: find.byType(Row),
      );
      final twoPillInRow = find.descendant(
        of: cardsPerRowRow.first,
        matching: find.text('2장'),
      );
      if (twoPillInRow.evaluate().isNotEmpty) {
        await tester.tap(twoPillInRow.first, warnIfMissed: false);
        await _pumpAndSettle(tester);
      }

      expect(
        repo.updatedCardsPerRow,
        isEmpty,
        reason: 'tShape must disable cardsPerRow — tapping the selector '
            'must NOT call updateCardsPerRow; '
            'actual calls=${repo.updatedCardsPerRow}',
      );
    },
  );

  // ------------------------------------------------------------------
  // T4 — "드로우 순서" 행은 grid3x3 일 때만 렌더. "기본" 활성 +
  //      "다른 순서 (준비 중)" 비활성. (Decision 12, Criteria #14)
  // ------------------------------------------------------------------
  testWidgets(
    'T4 "드로우 순서" row is absent on linear, present on grid3x3 with '
    '"기본" + "다른 순서 (준비 중)" options',
    (WidgetTester tester) async {
      // --- linear: row must NOT exist ---
      final repoLinear = _FakeSettingsRepo(_seedSettings(
        defaultLayoutType: LayoutType.linear,
      ));
      await tester.pumpWidget(
        _hostHomePage(initial: repoLinear._current, repo: repoLinear),
      );
      await _pumpAndSettle(tester);
      expect(
        find.text('드로우 순서'),
        findsNothing,
        reason: 'linear layout must NOT render the 드로우 순서 menu row',
      );

      // --- grid3x3: row must exist with "기본" + "다른 순서 (준비 중)" ---
      final repoGrid = _FakeSettingsRepo(_seedSettings(
        defaultLayoutType: LayoutType.grid3x3,
        defaultCardCount: 9,
      ));
      await tester.pumpWidget(
        _hostHomePage(initial: repoGrid._current, repo: repoGrid),
      );
      await _pumpAndSettle(tester);

      expect(
        find.text('드로우 순서'),
        findsOneWidget,
        reason: 'Decision 12: grid3x3 must render 드로우 순서 row',
      );
      expect(
        find.text('기본'),
        findsOneWidget,
        reason: 'Decision 12: 드로우 순서 menu must expose the "기본" option',
      );
      expect(
        find.text('다른 순서 (준비 중)'),
        findsOneWidget,
        reason: 'Decision 12: 드로우 순서 menu must expose a disabled '
            '"다른 순서 (준비 중)" placeholder option',
      );
    },
  );
}
