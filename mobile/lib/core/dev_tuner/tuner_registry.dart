import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tunable_var.dart';

class DevTunerRegistry
    extends StateNotifier<Map<String, List<TunableDouble>>> {
  DevTunerRegistry() : super({});

  void registerIfAbsent(String route, List<TunableDouble> vars) {
    if (state.containsKey(route)) return;
    // build() 중 state 수정 방지 — 다음 마이크로태스크에서 업데이트
    Future.microtask(() {
      if (!state.containsKey(route)) {
        state = {...state, route: vars};
      }
    });
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
