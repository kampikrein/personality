// TDD Red — Cycle 2 · Group B
// Spec: docs/03_tarot_shuffle/071_TDD_Red_flow_cycle2.md
//
// Purpose:
//   Assert that AnimatedDrawPage has had its result / save / "한 장 더"
//   responsibilities removed and now delegates to DrawResultPage via
//   pushReplacement. Static source inspection — cheap, falsifiable, and
//   immune to widget-pump flakiness.
//
// Brief anchors: MA-4, IC #8, IC #10.
//
// Red state (Cycle 1 completed, Cycle 2 not yet):
//   - animated_draw_page.dart still contains `readingRepositoryProvider`
//     and `saveReading(` calls → B1/B2 fail.
//   - animated_draw_page.dart has no pushReplacementNamed('draw-result')
//     nor pushReplacement('/draw/result') → B3 fail.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _animatedDrawPath =
    'lib/features/draw/presentation/pages/animated_draw_page.dart';

void main() {
  group('AnimatedDrawPage responsibility reduction (Cycle 2)', () {
    late String src;

    setUp(() {
      src = File(_animatedDrawPath).readAsStringSync();
    });

    test(
      'B1 removes readingRepositoryProvider usage',
      () {
        expect(
          src.contains('readingRepositoryProvider'),
          isFalse,
          reason:
              'Cycle 2 (Brief MA-4, IC #8) requires AnimatedDrawPage to '
              'stop saving readings directly. readingRepositoryProvider '
              'must not appear in $_animatedDrawPath. The save / '
              'addDrawnCard logic belongs to DrawResultPage alone (MA-1).',
        );
      },
    );

    test(
      'B2 removes direct saveReading invocation',
      () {
        expect(
          src.contains('saveReading('),
          isFalse,
          reason:
              'Cycle 2 removes the reading-save block from '
              'AnimatedDrawPage. `saveReading(` literal must not appear.',
        );
      },
    );

    test(
      'B3 delegates to DrawResultPage via pushReplacement',
      () {
        final hasNamedReplacement =
            src.contains("pushReplacementNamed('draw-result'") ||
                src.contains('pushReplacementNamed("draw-result"');
        final hasPathReplacement =
            src.contains("pushReplacement('/draw/result'") ||
                src.contains('pushReplacement("/draw/result"') ||
                src.contains("go('/draw/result'") ||
                src.contains('go("/draw/result"');

        expect(
          hasNamedReplacement || hasPathReplacement,
          isTrue,
          reason:
              'Cycle 2 (Brief MA-4, D4) requires AnimatedDrawPage to '
              'transition to the unified result page on animation end: '
              "pushReplacementNamed('draw-result') or "
              "pushReplacement('/draw/result'). Neither pattern found in "
              '$_animatedDrawPath.',
        );
      },
    );
  });
}
