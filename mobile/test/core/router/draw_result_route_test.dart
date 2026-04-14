// TDD Red — Cycle 1
// Spec: docs/03_tarot_shuffle/067_TDD_Red_rename_cycle1.md
//
// Purpose:
//   Assert that the GoRouter configuration
//   (1) exposes a route at path '/draw/result' with name 'draw-result', and
//   (2) no longer exposes the legacy path '/draw/instant' / name 'draw-instant'.
//
//   Until Cycle 1 impl renames the route, assertions (1) fail and (2) fails
//   — that is the intended Red state.
//
//   We traverse `GoRouter.configuration.routes` recursively so that nested
//   ShellRoute / StatefulShellRoute branches are included.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:personality_mobile/core/router/app_router.dart';

/// Recursively collect every GoRoute inside a RouteBase subtree.
List<GoRoute> _collectGoRoutes(List<RouteBase> routes) {
  final out = <GoRoute>[];
  for (final r in routes) {
    if (r is GoRoute) {
      out.add(r);
    }
    out.addAll(_collectGoRoutes(r.routes));
  }
  return out;
}

void main() {
  late ProviderContainer container;
  late GoRouter router;

  setUp(() {
    container = ProviderContainer();
    router = container.read(appRouterProvider);
  });

  tearDown(() {
    container.dispose();
  });

  test('GoRouter exposes /draw/result path with name "draw-result"', () {
    final routes = _collectGoRoutes(router.configuration.routes);

    final match = routes.where(
      (r) => r.path == '/draw/result' && r.name == 'draw-result',
    );

    expect(
      match,
      isNotEmpty,
      reason:
          'Cycle 1 requires GoRoute(path: "/draw/result", name: "draw-result"). '
          'None found — app_router.dart still defines the legacy "/draw/instant".',
    );
  });

  test('GoRouter no longer exposes legacy /draw/instant path', () {
    final routes = _collectGoRoutes(router.configuration.routes);

    final stale = routes.where(
      (r) => r.path == '/draw/instant' || r.name == 'draw-instant',
    );

    expect(
      stale,
      isEmpty,
      reason:
          'Cycle 1 removes the legacy "/draw/instant" / name "draw-instant". '
          'Found ${stale.length} legacy route(s) still present.',
    );
  });
}
