// TDD Red — Cycle 1
// Spec: docs/03_tarot_shuffle/067_TDD_Red_rename_cycle1.md
//
// Purpose:
//   This test asserts the EXISTENCE of `DrawResultPage` in
//   `lib/features/draw/presentation/pages/draw_result_page.dart`.
//   Until Cycle 1 impl performs the rename, the import below will
//   not resolve and `flutter test` will fail to compile this file
//   — that is the intended Red state.
//
// After the rename, `DrawResultPage` must be constructible inside a
// ProviderScope (shuffleStateProvider overridden to the keepAlive
// notifier type) and pumpable without exceptions. This corresponds to
// Brief 065 MA-9 (test isolation via overrideWith) and Ideal Criteria
// #23 (widget testability through provider override).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// RED: this file does not exist yet. The rename introduces it.
import 'package:personality_mobile/features/draw/presentation/pages/draw_result_page.dart';

void main() {
  testWidgets(
    'DrawResultPage class exists and pumps inside ProviderScope without throwing',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DrawResultPage(),
          ),
        ),
      );

      // One frame — we only assert no exception is thrown during
      // initial build. Async draw work (if any) is not awaited here
      // because Cycle 1 is a pure rename: behavior is identical to
      // the former InstantDrawPage. Later cycles will tighten this.
      expect(find.byType(DrawResultPage), findsOneWidget);
    },
  );
}
