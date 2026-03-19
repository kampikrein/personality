import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/database/database_provider.dart';
import 'core/database/database_setup.dart';
import 'core/dev_tuner/dev_tuner_overlay.dart';
import 'core/dev_tuner/tunable_var.dart';
import 'core/dev_tuner/tuner_registry.dart';
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

// ── Spring 튜닝 프로바이더 ─────────────────────────────────────────────
final springMassProvider = StateProvider<double>((ref) => 0.5);
final springStiffnessProvider = StateProvider<double>((ref) => 900.0);
final springDampingProvider = StateProvider<double>((ref) => 1.3);

class _FastBouncePhysics extends BouncingScrollPhysics {
  const _FastBouncePhysics({
    super.parent,
    this.springMass = 0.5,
    this.springStiffness = 900.0,
    this.springDamping = 1.3,
  }) : super(decelerationRate: ScrollDecelerationRate.fast);

  final double springMass;
  final double springStiffness;
  final double springDamping;

  @override
  SpringDescription get spring => SpringDescription(
        mass: springMass,
        stiffness: springStiffness,
        damping: springDamping,
      );

  @override
  _FastBouncePhysics applyTo(ScrollPhysics? ancestor) {
    return _FastBouncePhysics(
      parent: buildParent(ancestor),
      springMass: springMass,
      springStiffness: springStiffness,
      springDamping: springDamping,
    );
  }
}

class _TunableScrollBehavior extends MaterialScrollBehavior {
  const _TunableScrollBehavior({
    required this.mass,
    required this.stiffness,
    required this.damping,
  });

  final double mass;
  final double stiffness;
  final double damping;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return _FastBouncePhysics(
      springMass: mass,
      springStiffness: stiffness,
      springDamping: damping,
    );
  }
}

class PersonalityApp extends ConsumerWidget {
  const PersonalityApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final mass = ref.watch(springMassProvider);
    final stiffness = ref.watch(springStiffnessProvider);
    final damping = ref.watch(springDampingProvider);

    // Dev Tuner: 스프링 변수 등록 (debug only)
    if (kDebugMode) {
      ref
          .read(devTunerRegistryProvider)
          .registerIfAbsent('global', [
        TunableDouble(
            label: 'mass',
            provider: springMassProvider,
            min: 0.1,
            max: 3.0,
            step: 0.1),
        TunableDouble(
            label: 'stiffness',
            provider: springStiffnessProvider,
            min: 50,
            max: 3000,
            step: 50),
        TunableDouble(
            label: 'damping',
            provider: springDampingProvider,
            min: 0.1,
            max: 10.0,
            step: 0.1),
      ]);
    }

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Personality Tarot',
      theme: AppTheme.darkTheme,
      scrollBehavior: _TunableScrollBehavior(
        mass: mass,
        stiffness: stiffness,
        damping: damping,
      ),
      routerConfig: router,
      builder: (context, child) {
        if (!kDebugMode) return child!;
        return Stack(
          children: [
            child!,
            const Positioned.fill(child: DevTunerOverlay()),
          ],
        );
      },
    );
  }
}

