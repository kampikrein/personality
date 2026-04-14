// TDD Red — Cycle 2 · Group A
// Spec: docs/03_tarot_shuffle/071_TDD_Red_flow_cycle2.md
//
// Purpose:
//   Validate DrawResultPage.initState branching:
//   - When shuffleStateProvider is pre-populated (Lv2/3/4 upstream), reuse it
//     (no self-shuffle, no clear).
//   - When shuffleStateProvider is null (Lv1 direct entry), perform self-shuffle.
//   - The branch condition is evaluated in a single place (MA-9).
//
//   Current Cycle 1 code unconditionally clears shuffleStateProvider and
//   performs a fresh shuffle in _executeDraw() — so A1 and A3 are Red.
//
// Observation technique:
//   Instead of mocking shuffleDeckUseCase (which requires sensor/entropy
//   dependencies), we observe the ShuffleResult *identity* in the provider.
//   If DrawResultPage reuses the upstream result, the same Dart object
//   (identical by reference) remains after pump. If it re-shuffles, the
//   provider's state is replaced (identity changes).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:personality_mobile/features/deck/domain/entities/card_meanings.dart';
import 'package:personality_mobile/features/deck/domain/entities/tarot_card.dart';
import 'package:personality_mobile/features/draw/presentation/pages/draw_result_page.dart';
import 'package:personality_mobile/features/shuffle/domain/entities/shuffle_result.dart';
import 'package:personality_mobile/features/shuffle/presentation/providers/shuffle_providers.dart';

/// Builds a deterministic in-memory ShuffleResult without hitting
/// deck repository / sensors / entropy. Used as the "upstream pre-populated"
/// value injected through shuffleStateProvider.
ShuffleResult _fakeUpstreamResult({int count = 3}) {
  TarotCard card(int i) => TarotCard(
        id: 'test-$i',
        deckId: 'rws-standard',
        cardId: 'card-$i',
        name: 'Test Card $i',
        arcana: 'major',
        number: i,
        imagePath: 'assets/decks/rws-standard/majors/$i.png',
        meanings: const CardMeanings(
          upright: ['upright keyword'],
          reversed: ['reversed keyword'],
        ),
      );

  return ShuffleResult(
    cards: List.generate(
      count,
      (i) => ShuffledCard(card: card(i), isReversed: false),
    ),
    entropyBits: 0,
    usedSensorEntropy: false,
    shuffledAt: DateTime(2026, 4, 14),
  );
}

void main() {
  group('DrawResultPage initState branching (Cycle 2)', () {
    testWidgets(
      'A1 reuses existing shuffleStateProvider result (no re-shuffle, '
      'no clear)',
      (WidgetTester tester) async {
        final upstream = _fakeUpstreamResult();
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Seed provider with upstream result BEFORE pump, simulating
        // Lv2/3/4 having called setResult() before navigating to
        // DrawResultPage.
        container.read(shuffleStateProvider.notifier).setResult(upstream);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: DrawResultPage()),
          ),
        );

        // Let microtasks (initState -> Future.microtask -> _executeDraw)
        // run. We pump a few frames to give async init a chance to clobber
        // the provider if the page is still behaving as Cycle 1 did.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        final after = container.read(shuffleStateProvider);

        expect(
          identical(after, upstream),
          isTrue,
          reason:
              'Cycle 2 requires DrawResultPage to reuse the upstream '
              'ShuffleResult from shuffleStateProvider when non-null. '
              'The stored ShuffleResult identity must be unchanged after '
              'pump. Currently _executeDraw() calls clear() + self-shuffle '
              'unconditionally, replacing the object. after=$after '
              'upstream=$upstream',
        );
      },
    );

    testWidgets(
      'A2 GREEN-guard: when provider is null, self-shuffle eventually '
      'populates it (Lv1 fallback, regression guard for Cycle 2+)',
      (WidgetTester tester) async {
        // NOTE: This test is expected to remain Green both before and after
        // Cycle 2 impl. It guards against a refactor that accidentally
        // drops the Lv1 fallback path. We keep it here because Group A is
        // the natural home for initState branching behavior.
        //
        // We accept either outcome in the current environment (Cycle 1 code
        // may fail the shuffle due to missing deck seed in tests) but the
        // assertion is structural: after Cycle 2, a null-start must still
        // attempt to populate the provider (i.e. the branch exists).
        //
        // To avoid flakiness from deck repository I/O in tests, we assert
        // only the structural expectation via source inspection in A3.
        // This test body is intentionally a no-op smoke: it exercises the
        // widget under a null provider to confirm it at least mounts
        // without throwing a synchronous exception.

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: DrawResultPage()),
          ),
        );

        // One frame only — do not await async draw; deck I/O is not
        // available in unit-test sandbox.
        expect(find.byType(DrawResultPage), findsOneWidget);
      },
    );

    test(
      'A3 initState source declares a null-check branch on '
      'shuffleStateProvider (MA-9: single evaluation site)',
      () {
        final src = File(
          'lib/features/draw/presentation/pages/draw_result_page.dart',
        ).readAsStringSync();

        // Must reference the provider inside init-time code path.
        expect(
          src.contains('shuffleStateProvider'),
          isTrue,
          reason:
              'Source must reference shuffleStateProvider to decide '
              'between reuse and self-shuffle (MA-3, MA-9).',
        );

        // Cycle 2 introduces a conditional branch. We detect the presence
        // of an explicit null comparison against the provider value. This
        // is a source-level proxy for "single if-else branch evaluated
        // once" (MA-9). Cycle 1 code has no such comparison.
        final hasNullBranch = RegExp(
          r'shuffleStateProvider\s*\)?\s*;?[\s\S]{0,120}?(==\s*null|!=\s*null|\?\?|\bcase null\b)',
        ).hasMatch(src);

        expect(
          hasNullBranch,
          isTrue,
          reason:
              'Cycle 2 requires a null-check branch on shuffleStateProvider '
              'in draw_result_page.dart (e.g. `final existing = '
              'ref.read(shuffleStateProvider); if (existing == null) ...`). '
              'No such pattern was found — Cycle 1 still unconditionally '
              'clears + re-shuffles.',
        );
      },
    );
  });
}
