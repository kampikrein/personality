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

    return MaterialApp.router(
      title: 'Personality Tarot',
      theme: AppTheme.darkTheme,
      scrollBehavior: _TunableScrollBehavior(
        mass: mass,
        stiffness: stiffness,
        damping: damping,
      ),
      routerConfig: router,
      builder: (context, child) {
        final top = MediaQuery.of(context).padding.top + 8;
        return Stack(
          children: [
            child!,
            Positioned(
              right: 8,
              top: top,
              child: const SpringDebugPanel(),
            ),
          ],
        );
      },
    );
  }
}

// ── 디버그 패널 위젯 (홈 페이지에서 사용) ───────────────────────────────
class SpringDebugPanel extends ConsumerStatefulWidget {
  const SpringDebugPanel({super.key});

  @override
  ConsumerState<SpringDebugPanel> createState() => _SpringDebugPanelState();
}

class _SpringDebugPanelState extends ConsumerState<SpringDebugPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final mass = ref.watch(springMassProvider);
    final stiffness = ref.watch(springStiffnessProvider);
    final damping = ref.watch(springDampingProvider);

    if (!_expanded) {
      return GestureDetector(
        onTap: () => setState(() => _expanded = true),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.tune, color: Colors.white70, size: 20),
        ),
      );
    }

    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Spring Tuner',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => setState(() => _expanded = false),
                child: const Icon(Icons.close, color: Colors.white54, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSlider('mass', mass, 0.1, 3.0, springMassProvider),
          _buildSlider('stiffness', stiffness, 50, 3000, springStiffnessProvider),
          _buildSlider('damping', damping, 0.1, 10.0, springDampingProvider),
          const SizedBox(height: 4),
          Text(
            'T ∝ √(m/k)  지금: ${(2 * 3.14159 * _sqrt(mass / stiffness) * 1000).toStringAsFixed(0)}ms',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    StateProvider<double> provider,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(
            '$label: ${value.toStringAsFixed(1)}',
            style: const TextStyle(
                color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: Colors.tealAccent.withValues(alpha: 0.7),
              thumbColor: Colors.tealAccent,
              inactiveTrackColor: Colors.white24,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: (v) => ref.read(provider.notifier).state = v,
            ),
          ),
        ),
      ],
    );
  }

  double _sqrt(double x) => x > 0 ? x * x > 0 ? _newtonSqrt(x) : 0 : 0;
  double _newtonSqrt(double x) {
    var g = x / 2;
    for (var i = 0; i < 10; i++) {
      g = (g + x / g) / 2;
    }
    return g;
  }
}
