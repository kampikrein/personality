import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/deck/presentation/pages/deck_selection_page.dart';
import '../../features/draw/presentation/pages/animated_draw_page.dart';
import '../../features/draw/presentation/pages/draw_result_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/reading/domain/entities/spread_type.dart';
import '../../features/reading/presentation/pages/reading_detail_page.dart';
import '../../features/reading/presentation/pages/reading_list_page.dart';
import '../../features/reading/presentation/pages/reading_page.dart';
import '../../features/settings/presentation/pages/card_size_settings_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/shuffle/presentation/pages/intention_page.dart';
import '../../features/shuffle/presentation/pages/shuffle_page.dart';
import 'main_shell.dart';

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

// ── 탭별 Navigator 키 ──
final _drawNavKey = GlobalKey<NavigatorState>(debugLabel: 'draw');
final _storageNavKey = GlobalKey<NavigatorState>(debugLabel: 'storage');
final _chatNavKey = GlobalKey<NavigatorState>(debugLabel: 'chat');
final _profileNavKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // ── 하단 네비게이션 셸 ──
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // 탭 0: 바로 뽑기
          StatefulShellBranch(
            navigatorKey: _drawNavKey,
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                pageBuilder: (context, state) =>
                    _fadePage(key: state.pageKey, child: const HomePage()),
              ),
            ],
          ),
          // 탭 1: 저장소
          StatefulShellBranch(
            navigatorKey: _storageNavKey,
            routes: [
              GoRoute(
                path: '/readings',
                name: 'readings',
                pageBuilder: (context, state) => _fadePage(
                    key: state.pageKey, child: const ReadingListPage()),
                routes: [
                  GoRoute(
                    path: ':readingId',
                    name: 'reading-detail',
                    pageBuilder: (context, state) {
                      final readingId = state.pathParameters['readingId']!;
                      return _fadePage(
                          key: state.pageKey,
                          child: ReadingDetailPage(readingId: readingId));
                    },
                  ),
                ],
              ),
            ],
          ),
          // 탭 2: 채팅
          StatefulShellBranch(
            navigatorKey: _chatNavKey,
            routes: [
              GoRoute(
                path: '/chat',
                name: 'chat',
                pageBuilder: (context, state) =>
                    _fadePage(key: state.pageKey, child: const ChatPage()),
              ),
            ],
          ),
          // 탭 3: 유저메뉴
          StatefulShellBranch(
            navigatorKey: _profileNavKey,
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                pageBuilder: (context, state) =>
                    _fadePage(key: state.pageKey, child: const ProfilePage()),
              ),
            ],
          ),
        ],
      ),

      // ── 셸 밖 전체화면 라우트 (뽑기 플로우, 설정 등) ──
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
      GoRoute(
        path: '/draw/result',
        name: 'draw-result',
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const DrawResultPage()),
      ),
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
        path: '/settings/card-size',
        name: 'card-size-settings',
        pageBuilder: (context, state) => _fadePage(
            key: state.pageKey,
            child: const CardSizeSettingsPage()),
      ),
    ],
  );
}
