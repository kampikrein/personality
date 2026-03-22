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

  // FAB gesture disambiguation
  Offset _panStartOffset = Offset.zero;

  // Floating panel
  Offset _panelOffset = Offset.zero;
  Size _panelSize = Size.zero;

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

  void _resetAllVars(List<TunableDouble> vars) {
    for (final v in vars) {
      ref.read(v.provider.notifier).state = v.resetValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vars = ref.read(devTunerRegistryProvider).varsFor(_currentRoute);
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    if (!_positioned) {
      _buttonOffset =
          Offset(size.width - 56, size.height - bottomPadding - 80);
      _panelOffset = Offset(16, size.height - 340);
      _panelSize = Size(size.width - 32, 300);
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
            onPanStart: (_) {
              _panStartOffset = _buttonOffset;
            },
            onPanUpdate: (details) {
              setState(() {
                _buttonOffset += details.delta;
                _buttonOffset = Offset(
                  _buttonOffset.dx.clamp(0, size.width - 48),
                  _buttonOffset.dy.clamp(0, size.height - 48),
                );
              });
            },
            onPanEnd: (_) {
              if ((_buttonOffset - _panStartOffset).distance < 10) {
                setState(() => _expanded = !_expanded);
              }
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _expanded ? Icons.close : Icons.tune,
                color: Colors.white70,
                size: 24,
              ),
            ),
          ),
        ),
        // Floating panel
        if (_expanded)
          Positioned(
            left: _panelOffset.dx,
            top: _panelOffset.dy,
            child: Container(
              width: _panelSize.width,
              height: _panelSize.height,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header (drag handle) ──
                  GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _panelOffset += details.delta;
                        _panelOffset = Offset(
                          _panelOffset.dx
                              .clamp(0, size.width - _panelSize.width),
                          _panelOffset.dy
                              .clamp(0, size.height - _panelSize.height),
                        );
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.drag_handle,
                              color: Colors.white38, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Dev Tuner — $_currentRoute',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Reset button
                          GestureDetector(
                            onTap: () => _resetAllVars(vars),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.restart_alt,
                                  color: Colors.white54, size: 20),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Close button
                          GestureDetector(
                            onTap: () => setState(() => _expanded = false),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.close,
                                  color: Colors.white54, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ── Variable list (scrollable) ──
                  Expanded(
                    child: vars.isEmpty
                        ? const Center(
                            child: Text(
                              '등록된 변수 없음',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 13),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Column(
                              children:
                                  vars.map(_buildSliderRow).toList(),
                            ),
                          ),
                  ),
                  // ── Resize handle ──
                  Align(
                    alignment: Alignment.bottomRight,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _panelSize = Size(
                            (_panelSize.width + details.delta.dx)
                                .clamp(200, size.width - 16),
                            (_panelSize.height + details.delta.dy)
                                .clamp(150, size.height - 100),
                          );
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.open_in_full,
                            color: Colors.white24, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSliderRow(TunableDouble variable) {
    final value = ref.watch(variable.provider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            // Label
            SizedBox(
              width: 80,
              child: Text(
                variable.label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Decrement stepper
            StepperButton(
              icon: Icons.remove,
              onStep: () {
                final next = (ref.read(variable.provider) - variable.step)
                    .clamp(variable.min, variable.max);
                ref.read(variable.provider.notifier).state = next;
              },
            ),
            // Slider
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: Colors.tealAccent.withValues(alpha: 0.7),
                  inactiveTrackColor: Colors.white12,
                  thumbColor: Colors.tealAccent,
                  overlayColor: Colors.tealAccent.withValues(alpha: 0.15),
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 8),
                  trackHeight: 3,
                ),
                child: Slider(
                  value: value.clamp(variable.min, variable.max),
                  min: variable.min,
                  max: variable.max,
                  divisions:
                      ((variable.max - variable.min) / variable.step).round(),
                  onChanged: (newValue) {
                    ref.read(variable.provider.notifier).state = newValue;
                  },
                ),
              ),
            ),
            // Increment stepper
            StepperButton(
              icon: Icons.add,
              onStep: () {
                final next = (ref.read(variable.provider) + variable.step)
                    .clamp(variable.min, variable.max);
                ref.read(variable.provider.notifier).state = next;
              },
            ),
            // Value display
            SizedBox(
              width: 60,
              child: Text(
                variable.format(value),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 15,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
