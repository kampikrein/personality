// TDD Red — Cycle 2 · Group C
// Spec: docs/03_tarot_shuffle/071_TDD_Red_flow_cycle2.md
//
// Purpose:
//   Assert that ShufflePage (Lv4) has switched its post-selection target
//   from /reading/:deckId to /draw/result with pushReplacement. Static
//   source inspection on shuffle_page.dart.
//
// Brief anchors: MA-5, IC #11.
//
// Red state (Cycle 1 completed):
//   shuffle_page.dart:67-70 still calls `context.pushNamed('reading', ...)`
//   → C1 fails. No pushReplacementNamed('draw-result') present → C2 fails.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _shufflePagePath =
    'lib/features/shuffle/presentation/pages/shuffle_page.dart';

void main() {
  group('ShufflePage navigation rewrite (Cycle 2)', () {
    late String src;

    setUp(() {
      src = File(_shufflePagePath).readAsStringSync();
    });

    test(
      'C1 no longer navigates to /reading route',
      () {
        final hasReadingNav =
            RegExp(r"""pushNamed\(\s*['"]reading['"]""").hasMatch(src) ||
                RegExp(r"""push\(\s*['"]/reading/""").hasMatch(src) ||
                RegExp(r"""go\(\s*['"]/reading/""").hasMatch(src);

        expect(
          hasReadingNav,
          isFalse,
          reason:
              "Cycle 2 (Brief MA-5, IC #11) requires ShufflePage to stop "
              "navigating to the 'reading' route. Found a residual "
              "pushNamed('reading') or /reading/ push in $_shufflePagePath. "
              'Cycle 1 left shuffle_page.dart:67-70 untouched — Cycle 2 '
              'rewrites it.',
        );
      },
    );

    test(
      'C2 navigates to draw-result via pushReplacement',
      () {
        final hasNamedReplacement = RegExp(
          r"""pushReplacementNamed\(\s*['"]draw-result['"]""",
        ).hasMatch(src);
        final hasPathReplacement = RegExp(
          r"""pushReplacement\(\s*['"]/draw/result['"]""",
        ).hasMatch(src);

        expect(
          hasNamedReplacement || hasPathReplacement,
          isTrue,
          reason:
              "Cycle 2 requires ShufflePage to end with "
              "pushReplacementNamed('draw-result', pathParameters: "
              "{'deckId': ...}) or pushReplacement('/draw/result'). "
              'Neither pattern found.',
        );
      },
    );
  });
}
