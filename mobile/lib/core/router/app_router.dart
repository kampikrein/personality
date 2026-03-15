import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/deck/presentation/pages/deck_selection_page.dart';
import '../../features/shuffle/presentation/pages/shuffle_page.dart';
import '../../features/reading/presentation/pages/reading_page.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/deck',
        name: 'deck',
        builder: (context, state) => const DeckSelectionPage(),
      ),
      GoRoute(
        path: '/shuffle/:deckId',
        name: 'shuffle',
        builder: (context, state) {
          final deckId = state.pathParameters['deckId']!;
          return ShufflePage(deckId: deckId);
        },
      ),
      GoRoute(
        path: '/reading/:deckId',
        name: 'reading',
        builder: (context, state) {
          final deckId = state.pathParameters['deckId']!;
          return ReadingPage(deckId: deckId);
        },
      ),
    ],
  );
}
