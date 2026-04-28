// TDD Red — Cycle 2 · Group D
// Spec: docs/03_tarot_shuffle/071_TDD_Red_flow_cycle2.md
//
// Purpose:
//   Assert that the draw-time ReadingPage has been removed:
//   - D1: reading_page.dart file deleted.
//   - D2: /reading/:deckId GoRoute + reading_page.dart import gone.
//   - D3 (Green-guard, regression): reading_list_page / reading_detail_page
//        imports and /readings + :readingId routes preserved.
//
// Brief anchors: MA-6, IC #16, IC #17.
//
// Red state (Cycle 1 completed): reading_page.dart still exists and is
// referenced by app_router.dart:14 + :141 — D1/D2 fail. D3 passes as
// regression guard.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _readingPagePath =
    'lib/features/reading/presentation/pages/reading_page.dart';
const _routerPath = 'lib/core/router/app_router.dart';

void main() {
  group('ReadingPage (draw-time) removal (Cycle 2)', () {
    test(
      'D1 reading_page.dart file is deleted',
      () {
        final f = File(_readingPagePath);
        expect(
          f.existsSync(),
          isFalse,
          reason:
              'Cycle 2 (Brief MA-6, IC #16) requires deletion of '
              '$_readingPagePath. The draw-time ReadingPage has been '
              'absorbed by DrawResultPage; keeping the file risks '
              'dead-code rediscovery (D7 in Brief 065).',
        );
      },
    );

    test(
      'D2 app_router.dart drops /reading/:deckId route and reading_page '
      'import',
      () {
        final src = File(_routerPath).readAsStringSync();

        expect(
          src.contains("'/reading/:deckId'"),
          isFalse,
          reason:
              "Cycle 2 removes GoRoute(path: '/reading/:deckId', ...) "
              'from $_routerPath. Path literal still present.',
        );

        expect(
          src.contains('reading/presentation/pages/reading_page.dart'),
          isFalse,
          reason:
              'Cycle 2 removes the reading_page.dart import from '
              '$_routerPath. Import line still present.',
        );

        // Also verify the GoRoute name 'reading' (used by ShufflePage's
        // legacy pushNamed) is gone.
        expect(
          RegExp(r"""name:\s*['"]reading['"]""").hasMatch(src),
          isFalse,
          reason:
              "Cycle 2 removes name: 'reading' alongside the path — "
              'ShufflePage no longer targets it (see Group C).',
        );
      },
    );

    test(
      'D3 GREEN-guard: reading_list_page / reading_detail_page routes '
      'remain intact (regression fence)',
      () {
        final src = File(_routerPath).readAsStringSync();

        expect(
          src.contains('reading_list_page.dart'),
          isTrue,
          reason:
              'Brief 065 Boundaries: reading_list_page must remain. This '
              'guard fails if the deletion overreaches and takes down '
              'the list page import.',
        );
        expect(
          src.contains('reading_detail_page.dart'),
          isTrue,
          reason:
              'Brief 065 Boundaries: reading_detail_page must remain.',
        );
        expect(
          src.contains("'/readings'"),
          isTrue,
          reason: '/readings route (list) must remain.',
        );
        expect(
          src.contains("':readingId'"),
          isTrue,
          reason: 'readings/:readingId detail route must remain.',
        );
      },
    );
  });
}
