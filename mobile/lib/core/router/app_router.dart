import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/deck/presentation/pages/deck_selection_page.dart';
import '../../features/shuffle/presentation/pages/intention_page.dart';
import '../../features/shuffle/presentation/pages/shuffle_page.dart';
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
          return _fadePage(
              key: state.pageKey, child: ReadingPage(deckId: deckId));
        },
      ),
    ],
  );
}
