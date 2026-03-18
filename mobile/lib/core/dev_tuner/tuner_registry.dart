import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tunable_var.dart';

class DevTunerRegistry
    extends StateNotifier<Map<String, List<TunableDouble>>> {
  DevTunerRegistry() : super({});

  void registerIfAbsent(String route, List<TunableDouble> vars) {
    if (state.containsKey(route)) return;
    state = {...state, route: vars};
  }

  List<TunableDouble> varsFor(String route) {
    return [
      ...state['global'] ?? [],
      if (route != 'global') ...state[route] ?? [],
    ];
  }
}

final devTunerRegistryProvider =
    StateNotifierProvider<DevTunerRegistry, Map<String, List<TunableDouble>>>(
  (ref) => DevTunerRegistry(),
);
