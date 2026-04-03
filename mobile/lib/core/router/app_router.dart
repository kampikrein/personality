import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/deck/presentation/pages/deck_selection_page.dart';
import '../../features/draw/presentation/pages/instant_draw_page.dart';
import '../../features/draw/presentation/pages/animated_draw_page.dart';
import '../../features/reading/presentation/pages/reading_detail_page.dart';
import '../../features/reading/presentation/pages/reading_list_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/shuffle/presentation/pages/intention_page.dart';
import '../../features/shuffle/presentation/pages/shuffle_page.dart';
import '../../features/reading/domain/entities/spread_type.dart';
import '../../features/reading/presentation/pages/reading_page.dart';

part 'app_router.g.dart';

CustomTransitionPage<void> _fadePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 600),
  );
}

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const HomePage()),
      ),
      GoRoute(
        path: '/deck',
        name: 'deck',
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const DeckSelectionPage()),
      ),
      GoRoute(
        path: '/intention/:deckId',
        name: 'intention',
        pageBuilder: (context, state) {
          final deckId = state.pathParameters['deckId']!;
          return _fadePage(
              key: state.pageKey, child: IntentionPage(deckId: deckId));
        },
      ),
      GoRoute(
        path: '/shuffle/:deckId',
        name: 'shuffle',
        pageBuilder: (context, state) {
          final deckId = state.pathParameters['deckId']!;
          return _fadePage(
              key: state.pageKey, child: ShufflePage(deckId: deckId));
        },
      ),
      GoRoute(
        path: '/reading/:deckId',
        name: 'reading',
        pageBuilder: (context, state) {
          final deckId = state.pathParameters['deckId']!;
          final spreadType =
              state.extra as SpreadType? ?? SpreadType.single;
          return _fadePage(
              key: state.pageKey,
              child: ReadingPage(deckId: deckId, spreadType: spreadType));
        },
      ),
      // ── Level 1: 즉시 뽑기 ──
      GoRoute(
        path: '/draw/instant',
        name: 'draw-instant',
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const InstantDrawPage()),
      ),
      // ── Level 2: 간단 연출 ──
      GoRoute(
        path: '/draw/animated',
        name: 'draw-animated',
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const AnimatedDrawPage()),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const SettingsPage()),
      ),
      GoRoute(
        path: '/readings',
        name: 'readings',
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const ReadingListPage()),
      ),
      GoRoute(
        path: '/readings/:readingId',
        name: 'reading-detail',
        pageBuilder: (context, state) {
          final readingId = state.pathParameters['readingId']!;
          return _fadePage(
              key: state.pageKey,
              child: ReadingDetailPage(readingId: readingId));
        },
      ),
    ],
  );
}
