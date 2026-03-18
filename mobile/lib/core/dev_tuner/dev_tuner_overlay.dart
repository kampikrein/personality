import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import 'stepper_button.dart';
import 'tunable_var.dart';
import 'tuner_registry.dart';

class DevTunerOverlay extends ConsumerStatefulWidget {
  const DevTunerOverlay({super.key});

  @override
  ConsumerState<DevTunerOverlay> createState() => _DevTunerOverlayState();
}

class _DevTunerOverlayState extends ConsumerState<DevTunerOverlay> {
  bool _expanded = false;
  Offset _buttonOffset = Offset.zero;
  bool _positioned = false;
  String _currentRoute = 'home';
  GoRouter? _router;
  VoidCallback? _routeListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _router = ref.read(appRouterProvider);
      _routeListener = () {
        final name = _router!.routerDelegate.state.name ?? 'home';
        if (_currentRoute != name) setState(() => _currentRoute = name);
      };
      _router!.routerDelegate.addListener(_routeListener!);
    });
  }

  @override
  void dispose() {
    if (_routeListener != null && _router != null) {
      _router!.routerDelegate.removeListener(_routeListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch registry so we rebuild when vars are registered
    ref.watch(devTunerRegistryProvider);
    final vars =
        ref.read(devTunerRegistryProvider.notifier).varsFor(_currentRoute);
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    if (!_positioned) {
      _buttonOffset =
          Offset(size.width - 48, size.height - bottomPadding - 80);
      _positioned = true;
    }

    return Stack(
      children: [
        // Draggable FAB
        Positioned(
          left: _buttonOffset.dx,
          top: _buttonOffset.dy,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) {
              setState(() {
                _buttonOffset += details.delta;
                _buttonOffset = Offset(
                  _buttonOffset.dx.clamp(0, size.width - 40),
                  _buttonOffset.dy.clamp(0, size.height - 40),
                );
              });
            },
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _expanded ? Icons.close : Icons.tune,
                color: Colors.white70,
                size: 20,
              ),
            ),
          ),
        ),
        // Bottom panel
        if (_expanded)
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPadding + 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dev Tuner — $_currentRoute',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (vars.isEmpty)
                    const Text(
                      '등록된 변수 없음',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    )
                  else
                    ...vars.map(_buildStepperRow),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStepperRow(TunableDouble variable) {
    final value = ref.watch(variable.provider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              variable.label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          StepperButton(
            icon: Icons.chevron_left,
            onStep: () {
              final next = (ref.read(variable.provider) - variable.step)
                  .clamp(variable.min, variable.max);
              ref.read(variable.provider.notifier).state = next;
            },
          ),
          SizedBox(
            width: 60,
            child: Text(
              variable.format(value),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.tealAccent,
                fontSize: 13,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          StepperButton(
            icon: Icons.chevron_right,
            onStep: () {
              final next = (ref.read(variable.provider) + variable.step)
                  .clamp(variable.min, variable.max);
              ref.read(variable.provider.notifier).state = next;
            },
          ),
        ],
      ),
    );
  }
}
