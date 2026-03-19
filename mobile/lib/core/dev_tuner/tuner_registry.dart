import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tunable_var.dart';

class DevTunerRegistry {
  final _vars = <String, List<TunableDouble>>{};

  void registerIfAbsent(String route, List<TunableDouble> vars) {
    _vars.putIfAbsent(route, () => vars);
  }

  List<TunableDouble> varsFor(String route) {
    return [
      ..._vars['global'] ?? [],
      if (route != 'global') ..._vars[route] ?? [],
    ];
  }
}

final devTunerRegistryProvider =
    Provider<DevTunerRegistry>((ref) => DevTunerRegistry());
