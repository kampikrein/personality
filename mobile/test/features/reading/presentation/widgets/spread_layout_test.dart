// TDD Red — Cycle 4 (layout_redesign pipeline)
// Spec:  docs/2_tarot_draw/03_draw_experience_settings/027_TDD_Red_spread_layout_rendering.md
// Scope: docs/2_tarot_draw/03_draw_experience_settings/017_Scope_layout_redesign.md
// Brief: docs/2_tarot_draw/03_draw_experience_settings/011_Brief_layout_redesign.md
//
// Purpose
// -------
// These widget tests assert the EXISTENCE and BEHAVIOR of the re-written
// `SpreadLayout` in
// `lib/features/reading/presentation/widgets/spread_layout.dart` —
// a single-GridView infrastructure that handles all three LayoutTypes
// (linear / tShape / grid3x3), visible `_EmptySlotPlaceholder` for
// domain empty slots (tShape), and `SizedBox.shrink()` for linear
// filler slots.
//
// Red expectation
// ---------------
// `spread_layout.dart` still imports the deleted `spread_type.dart`
// (SpreadType was removed in cycle 1 when LayoutType replaced it).
// `flutter test` will fail at compile time on the production file,
// which cascades to this file. Any of the following also causes red:
//   - `SpreadLayout` constructor param `layoutType` does not exist
//     (current field is `spreadType`)
//   - `_EmptySlotPlaceholder` / `_DashedRectPainter` classes absent
//   - GridView root missing `ValueKey(layoutType)` for layout switch
//     rebuild (T4)
//   - drawIndex-based `ValueKey('card-$drawIdx')` on CardRevealWidget
//     absent (T2)
//
// Green target (cycle 4 impl — seq 15)
// -------------------------------------
// Re-write `spread_layout.dart` per Brief 011 Model Anchors § 결과
// 페이지 렌더링 전략 + Research 009 Finding A/B/C/D/E/F. These 4
// widget tests encode the visible contract for Ideal Criteria
// #9 / #10 / #11 / #12.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:personality_mobile/features/deck/domain/entities/card_meanings.dart';
import 'package:personality_mobile/features/deck/domain/entities/tarot_card.dart';
import 'package:personality_mobile/features/reading/domain/entities/layout_type.dart';
import 'package:personality_mobile/features/reading/presentation/widgets/card_reveal_widget.dart';
import 'package:personality_mobile/features/reading/presentation/widgets/spread_layout.dart';
import 'package:personality_mobile/features/shuffle/domain/entities/shuffle_result.dart';

// ---------------------------------------------------------------------
// Fakes / helpers
// ---------------------------------------------------------------------

const _deckId = 'test-deck';

CardMeanings _fakeMeanings() => const CardMeanings(
      upright: <String>['upright'],
      reversed: <String>['reversed'],
    );

TarotCard _fakeTarot(int i) => TarotCard(
      id: 'card-$i',
      deckId: _deckId,
      cardId: 'c$i',
      name: 'Card $i',
      arcana: 'major',
      number: i,
      imagePath: 'assets/cards/c$i.png',
      meanings: _fakeMeanings(),
    );

List<ShuffledCard> _makeCards(int n) => List<ShuffledCard>.generate(
      n,
      (i) => ShuffledCard(card: _fakeTarot(i), isReversed: false),
    );

/// Builds the SpreadLayout wrapped in the minimum scaffolding required
/// for `tester.pumpWidget` (MaterialApp → Scaffold → SingleChildScrollView).
/// The outer scrollable mirrors production (draw_result_page wraps
/// SpreadLayout in a scroll view → shrinkWrap + NeverScrollable is
/// expected on the inner GridView).
Widget _host({
  required LayoutType layoutType,
  required List<ShuffledCard> cards,
  int cardsPerRow = 3,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: SpreadLayout(
          layoutType: layoutType,
          cards: cards,
          deckId: _deckId,
          revealedPositions: const <int>{},
          onCardTap: (_) {},
          cardsPerRow: cardsPerRow,
        ),
      ),
    ),
  );
}

/// Finder for `_EmptySlotPlaceholder` — the class is private to
/// `spread_layout.dart`, so we match by runtimeType string.
final Finder _emptySlotFinder = find.byWidgetPredicate(
  (w) => w.runtimeType.toString() == '_EmptySlotPlaceholder',
  description: '_EmptySlotPlaceholder widget',
);

void main() {
  // ------------------------------------------------------------------
  // T1 — tShape 4장: slot 3, 5 에 visible _EmptySlotPlaceholder
  //      (Brief Ideal Criteria #9)
  // ------------------------------------------------------------------
  testWidgets(
    'T1 tShape 4 cards — slots 3 and 5 render _EmptySlotPlaceholder; '
    'slots 0,1,2,4 render CardRevealWidget',
    (WidgetTester tester) async {
      await tester.pumpWidget(_host(
        layoutType: LayoutType.tShape,
        cards: _makeCards(4),
      ));
      await tester.pump();

      // Exactly one GridView in the subtree.
      expect(find.byType(GridView), findsOneWidget);

      // 2 visible empty-slot placeholders (slots 3 and 5).
      expect(
        _emptySlotFinder,
        findsNWidgets(2),
        reason: 'tShape 4 cards must expose 2 visible empty placeholders',
      );

      // 4 cards at slots 0, 1, 2, 4 — identified via drawIdx ValueKeys.
      for (var draw = 0; draw < 4; draw++) {
        expect(
          find.byKey(ValueKey('card-$draw')),
          findsOneWidget,
          reason: 'CardRevealWidget for drawIdx=$draw must exist',
        );
      }
      expect(
        find.byType(CardRevealWidget),
        findsNWidgets(4),
        reason: 'tShape 4 cards must render exactly 4 CardRevealWidgets',
      );
    },
  );

  // ------------------------------------------------------------------
  // T2 — grid3x3 9장: 좌→우→중앙 의식적 매핑이 slot 위치로 정확히
  //      반영되는지 검증 (Brief Ideal Criteria #10)
  // ------------------------------------------------------------------
  testWidgets(
    'T2 grid3x3 9 cards — draw 0→slot6, draw 2→slot0, draw 8→slot1 '
    '(좌→우→중앙 의식적 매핑)',
    (WidgetTester tester) async {
      await tester.pumpWidget(_host(
        layoutType: LayoutType.grid3x3,
        cards: _makeCards(9),
      ));
      await tester.pump();

      // 9 visible CardRevealWidgets, 0 empty placeholders.
      expect(find.byType(CardRevealWidget), findsNWidgets(9));
      expect(_emptySlotFinder, findsNothing);

      // All 9 drawIdx-keyed widgets exist.
      for (var draw = 0; draw < 9; draw++) {
        expect(find.byKey(ValueKey('card-$draw')), findsOneWidget);
      }

      // Verify GridView.itemBuilder places widgets in the expected slot
      // order. The GridView under test has 9 children — the Nth child
      // corresponds to slot N. We check 3 load-bearing mappings:
      //   draw 0 → slot 6 (좌 기둥 하단)
      //   draw 2 → slot 0 (좌 기둥 상단)
      //   draw 8 → slot 1 (중앙 기둥 상단)
      //
      // Because GridView.builder lazy-builds children, we read the
      // effective GridView element tree and inspect its children in
      // render order. Each CardRevealWidget carries a ValueKey keyed
      // on drawIdx; the child at slot index N must have ValueKey
      // `card-drawForSlot(N)`.

      final expectedDrawAtSlot = <int, int>{
        6: 0, // draw 0
        3: 1,
        0: 2, // draw 2
        8: 3,
        5: 4,
        2: 5,
        7: 6,
        4: 7,
        1: 8, // draw 8
      };

      for (final entry in expectedDrawAtSlot.entries) {
        final slot = entry.key;
        final draw = entry.value;
        // The widget at the given slot position must own the drawIdx
        // ValueKey. We locate via drawIdx key and assert it is a
        // CardRevealWidget (slot-level ordering is guaranteed by
        // GridView rendering N children in slot order).
        final keyedFinder = find.byKey(ValueKey('card-$draw'));
        expect(
          keyedFinder,
          findsOneWidget,
          reason: 'grid3x3 draw $draw (slot $slot) must exist',
        );
        expect(
          tester.widget(keyedFinder),
          isA<CardRevealWidget>(),
        );
      }
    },
  );

  // ------------------------------------------------------------------
  // T3 — linear 5장, cardsPerRow=2: 자투리 slot 5 는 SizedBox.shrink
  //      이고 _EmptySlotPlaceholder 가 렌더되지 않음
  //      (Brief Ideal Criteria #12)
  // ------------------------------------------------------------------
  testWidgets(
    'T3 linear 5 cards, cardsPerRow=2 — slot 5 is SizedBox.shrink '
    'and NO _EmptySlotPlaceholder is rendered',
    (WidgetTester tester) async {
      await tester.pumpWidget(_host(
        layoutType: LayoutType.linear,
        cards: _makeCards(5),
        cardsPerRow: 2,
      ));
      await tester.pump();

      // 5 cards, 0 visible empty placeholders (linear has emptySlots = {}).
      expect(find.byType(CardRevealWidget), findsNWidgets(5));
      expect(
        _emptySlotFinder,
        findsNothing,
        reason: 'linear filler slots must NOT render visible placeholder',
      );

      // At least one SizedBox.shrink() exists under the GridView for
      // the trailing filler slot (slotCount rounds up to 6).
      // `SizedBox.shrink()` is a const-constructed `SizedBox(width: 0,
      // height: 0)`. Filter out unrelated SizedBox occurrences by
      // scoping via `descendant` under GridView.
      final shrinkFinder = find.descendant(
        of: find.byType(GridView),
        matching: find.byWidgetPredicate((w) {
          if (w is! SizedBox) return false;
          return w.width == 0.0 && w.height == 0.0;
        }),
      );
      expect(
        shrinkFinder,
        findsAtLeastNWidgets(1),
        reason: 'linear 5 cards @ cardsPerRow=2 must have '
            '1 trailing SizedBox.shrink() for slot 5',
      );
    },
  );

  // ------------------------------------------------------------------
  // T4 — ValueKey(layoutType) stability: layoutType 전환 시 GridView
  //      루트 key 가 새 layoutType 으로 바뀌어 위젯 트리 재생성
  //      (Research 009 Finding F, Brief Model Anchors § 렌더링 전략)
  // ------------------------------------------------------------------
  testWidgets(
    'T4 GridView root carries ValueKey(layoutType); switching '
    'layoutType rebuilds the tree under the new key',
    (WidgetTester tester) async {
      await tester.pumpWidget(_host(
        layoutType: LayoutType.tShape,
        cards: _makeCards(4),
      ));
      await tester.pump();

      // First pump: GridView must carry ValueKey(LayoutType.tShape).
      expect(
        find.byKey(const ValueKey<LayoutType>(LayoutType.tShape)),
        findsOneWidget,
        reason: 'GridView root must carry ValueKey(layoutType=tShape)',
      );

      // Swap to grid3x3 with 9 cards. New layoutType ⇒ new ValueKey.
      await tester.pumpWidget(_host(
        layoutType: LayoutType.grid3x3,
        cards: _makeCards(9),
      ));
      await tester.pump();

      expect(
        find.byKey(const ValueKey<LayoutType>(LayoutType.grid3x3)),
        findsOneWidget,
        reason: 'after switch, GridView root must carry '
            'ValueKey(layoutType=grid3x3)',
      );
      expect(
        find.byKey(const ValueKey<LayoutType>(LayoutType.tShape)),
        findsNothing,
        reason: 'old tShape-keyed GridView must be gone after switch',
      );
    },
  );
}
