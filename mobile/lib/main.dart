import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/database/database_provider.dart';
import 'core/database/database_setup.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = await constructDb();

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
      child: const PersonalityApp(),
    ),
  );
}

class _FastBouncePhysics extends BouncingScrollPhysics {
  const _FastBouncePhysics({super.parent})
      : super(decelerationRate: ScrollDecelerationRate.fast);

  // 기본 spring(stiffness:100, damping:1.1)의 복원 시간을 1/3로 축소.
  // T ∝ 1/√k 이므로 stiffness 9배 → 시간 1/3.
  @override
  SpringDescription get spring =>
      const SpringDescription(mass: 0.5, stiffness: 900.0, damping: 3.3);

  @override
  _FastBouncePhysics applyTo(ScrollPhysics? ancestor) {
    return _FastBouncePhysics(parent: buildParent(ancestor));
  }
}

class _SubtleBounceScrollBehavior extends MaterialScrollBehavior {
  const _SubtleBounceScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const _FastBouncePhysics();
  }
}

class PersonalityApp extends ConsumerWidget {
  const PersonalityApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Personality Tarot',
      theme: AppTheme.darkTheme,
      scrollBehavior: const _SubtleBounceScrollBehavior(),
      routerConfig: router,
    );
  }
}
