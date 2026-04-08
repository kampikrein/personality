---
id: "008"
type: plan
title: "Dev Tuner System — Core + UI (Cycle 1)"
created: 2026-03-18
traces_scope: "001"
traces_research: "007"
summary: >
  Dev Tuner 핵심 시스템 구현. TunableDouble 모델, DevTunerRegistry 프로바이더,
  DevTunerOverlay UI (드래그 FAB + < N > 스텝퍼 + 라우트 감지), kDebugMode 가드.
  기존 SpringDebugPanel 교체. 4개 신규 + 1개 수정.
keywords: [dev-tuner, tunable-var, registry, overlay, stepper, kDebugMode]
---

# 008 — Dev Tuner System (Cycle 1)

## Goal

Spring Tuner를 범용 Dev Tuner 시스템으로 교체한다. 화면별 변수 등록/표시 인프라를 구축하고,
기존 스프링 변수 3개를 첫 등록 변수로 이전한다.

## Scope

### Included
| # | Item | Description |
|---|------|-------------|
| 1 | TunableDouble 모델 | label, min, max, step, provider 참조 |
| 2 | DevTunerRegistry | 화면별 변수 집합 관리 (Map<String, List<TunableDouble>>) |
| 3 | DevTunerOverlay | 드래그 FAB + < N > 스텝퍼 패널 + 라우트 감지 |
| 4 | kDebugMode 가드 | 릴리즈 빌드에서 완전 제거 |
| 5 | 스프링 변수 이전 | 기존 3개 spring provider를 'global'로 등록 |

### Excluded
| Item | Reason/Timeline |
|------|-----------------|
| 화면별 변수 등록 (49개) | Cycle 2 |
| int/bool/enum 타입 지원 | Cycle 2 (현재 double만) |
| 변수 그룹 배율 (spacingScale) | Cycle 2 |

## Structural Decisions

No structural decisions required — Research (007)에서 모든 아키텍처 결정 완료:
- 라우트 감지: routerDelegate.addListener (R-007-F1)
- 레지스트리: 단일 글로벌 Map (R-007-F2)
- 오버레이: MaterialApp.builder 유지 (R-007-F3)
- 릴리즈 보호: kDebugMode guard (R-007-F4)

---

## File Change Summary

### New Files
| # | File Path | Description |
|---|-----------|-------------|
| 1 | `mobile/lib/core/dev_tuner/tunable_var.dart` | TunableDouble 모델 클래스 |
| 2 | `mobile/lib/core/dev_tuner/tuner_registry.dart` | DevTunerRegistry StateNotifier + provider |
| 3 | `mobile/lib/core/dev_tuner/dev_tuner_overlay.dart` | DevTunerOverlay (FAB + 패널 + 라우트) |
| 4 | `mobile/lib/core/dev_tuner/stepper_button.dart` | StepperButton (탭 + 길게 누르기) |

### Modified Files
| # | File Path | Change Description |
|---|-----------|-------------------|
| 1 | `mobile/lib/main.dart` | SpringDebugPanel 제거, DevTunerOverlay 교체, kDebugMode 가드, 스프링 변수 등록 |

---

## Step 1 — TunableDouble 모델

### Approach
Dev Tuner에서 조정 가능한 double 변수를 표현하는 모델. StateProvider 참조를 직접 보유하여
오버레이 UI가 값을 읽고 쓸 수 있다.

### After Code
```dart
// mobile/lib/core/dev_tuner/tunable_var.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TunableDouble {
  const TunableDouble({
    required this.label,
    required this.provider,
    required this.min,
    required this.max,
    this.step = 1.0,
  });

  final String label;
  final StateProvider<double> provider;
  final double min;
  final double max;
  final double step;

  /// step이 1 미만이면 소수점 1자리, 아니면 정수 표시
  String format(double value) =>
      step < 1 ? value.toStringAsFixed(1) : value.toStringAsFixed(0);
}
```

---

## Step 2 — DevTunerRegistry

### Approach
화면 이름(route name)별 TunableDouble 리스트를 관리하는 StateNotifier.
`registerIfAbsent`로 중복 등록 방지.

### After Code
```dart
// mobile/lib/core/dev_tuner/tuner_registry.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tunable_var.dart';

class DevTunerRegistry extends StateNotifier<Map<String, List<TunableDouble>>> {
  DevTunerRegistry() : super({});

  /// 화면별 변수 등록. 이미 등록된 route는 무시.
  void registerIfAbsent(String route, List<TunableDouble> vars) {
    if (state.containsKey(route)) return;
    state = {...state, route: vars};
  }

  /// 해당 route의 변수 + 'global' 변수를 합쳐 반환
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
```

### Considerations
- `varsFor`가 'global' + 현재 route를 합산 → 모든 화면에서 스프링 변수가 항상 보임
- Cycle 2에서 각 화면이 `registerIfAbsent('home', [...])` 호출하면 해당 화면 변수 추가

---

## Step 3 — StepperButton

### Approach
탭 = 1 step, 길게 누르기 = 80ms 간격 연속 증감. Timer.periodic 사용.
독립 위젯으로 분리하여 dispose에서 Timer 정리 보장.

### After Code
```dart
// mobile/lib/core/dev_tuner/stepper_button.dart
import 'dart:async';

import 'package:flutter/material.dart';

class StepperButton extends StatefulWidget {
  const StepperButton({
    super.key,
    required this.icon,
    required this.onStep,
  });

  final IconData icon;
  final VoidCallback onStep;

  @override
  State<StepperButton> createState() => _StepperButtonState();
}

class _StepperButtonState extends State<StepperButton> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onStep,
      onLongPressStart: (_) {
        widget.onStep();
        _timer = Timer.periodic(
          const Duration(milliseconds: 80),
          (_) => widget.onStep(),
        );
      },
      onLongPressEnd: (_) {
        _timer?.cancel();
        _timer = null;
      },
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: Icon(widget.icon, color: Colors.white70, size: 18),
      ),
    );
  }
}
```

---

## Step 4 — DevTunerOverlay

### Approach
기존 SpringDebugPanel을 완전 교체. 핵심 기능:
1. 드래그 가능 FAB (기존 패턴 유지)
2. 라우트 감지 (routerDelegate.addListener)
3. 현재 화면 변수를 < N > 스텝퍼로 표시
4. 패널 헤더에 현재 라우트 표시

### After Code
```dart
// mobile/lib/core/dev_tuner/dev_tuner_overlay.dart
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
    final registry = ref.watch(devTunerRegistryProvider);
    final vars = ref.read(devTunerRegistryProvider.notifier).varsFor(_currentRoute);
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    if (!_positioned) {
      _buttonOffset = Offset(size.width - 48, size.height - bottomPadding - 80);
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
                  // Header with route name
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
                    ...vars.map((v) => _buildStepperRow(v)),
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
          // Label
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
          // < button
          StepperButton(
            icon: Icons.chevron_left,
            onStep: () {
              final next = (ref.read(variable.provider) - variable.step)
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
                fontSize: 13,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // > button
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
```

### Considerations
- `ref.watch(devTunerRegistryProvider)` — registry 변경 시 rebuild (Cycle 2에서 동적 등록 시 필요)
- `ref.read(...notifier).varsFor()` — 읽기 전용 메서드는 notifier에서 직접 호출
- `_router` 참조 보존 — dispose 시 안전한 listener 해제

---

## Step 5 — main.dart 교체

### Approach
1. SpringDebugPanel 클래스 전체 제거 (112-280줄)
2. DevTunerOverlay로 교체 + `kDebugMode` 가드
3. `_registerDevTunerVars` 메서드로 기존 스프링 변수 등록
4. spring StateProvider 3개와 _FastBouncePhysics, _TunableScrollBehavior는 유지

### Current Code
```dart
// main.dart:1-7
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/database/database_provider.dart';
import 'core/database/database_setup.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
```

### After Code
```dart
// main.dart:1-10
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
```

### Current Code
```dart
// main.dart:100-107 (builder)
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            const Positioned.fill(child: SpringDebugPanel()),
          ],
        );
      },
```

### After Code
```dart
// main.dart (builder with kDebugMode guard)
      builder: (context, child) {
        if (!kDebugMode) return child!;
        return Stack(
          children: [
            child!,
            const Positioned.fill(child: DevTunerOverlay()),
          ],
        );
      },
```

### Current Code
```dart
// main.dart:80-110 (PersonalityApp class)
class PersonalityApp extends ConsumerWidget {
  const PersonalityApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final mass = ref.watch(springMassProvider);
    final stiffness = ref.watch(springStiffnessProvider);
    final damping = ref.watch(springDampingProvider);

    return MaterialApp.router(
      ...
    );
  }
}
```

### After Code
```dart
// main.dart (PersonalityApp with dev tuner registration)
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
      ref.read(devTunerRegistryProvider.notifier).registerIfAbsent('global', [
        TunableDouble(label: 'mass', provider: springMassProvider, min: 0.1, max: 3.0, step: 0.1),
        TunableDouble(label: 'stiffness', provider: springStiffnessProvider, min: 50, max: 3000, step: 50),
        TunableDouble(label: 'damping', provider: springDampingProvider, min: 0.1, max: 10.0, step: 0.1),
      ]);
    }

    return MaterialApp.router(
      ...
    );
  }
}
```

### Removals
- `SpringDebugPanel` 클래스 전체 제거 (112-280줄)
- 연관 주석 제거 (`// ── 디버그 패널 위젯...`)

---

## Step 6 — 빌드 검증

### Approach
1. `flutter analyze` — 정적 분석
2. 에뮬레이터에서 Dev Tuner FAB 표시 + 패널 열기/닫기 + 스프링 변수 조정 확인

---

## Considerations & Trade-offs

### Alternative Approaches
| 접근법 | 비채택 이유 |
|--------|-----------|
| OverlayEntry 기반 오버레이 | Riverpod 접근 복잡, 히트테스트 추가 설정 필요 (R-007-F3) |
| Provider Family 레지스트리 | 오버레이에서 route를 알아야 호출 가능, 단순 Map이 더 직관적 (R-007-F2) |
| riverpod_annotation 코드젠 | 개발용 도구에 코드젠 의존성 불필요, 수동 provider로 충분 |
| sealed class TunableVar<T> | Cycle 1은 double만 지원, YAGNI — Cycle 2에서 확장 |

### Potential Risks
| 리스크 | 완화 |
|--------|------|
| appRouterProvider AutoDispose | DevTunerOverlay가 ref.read로 참조 → PersonalityApp의 ref.watch가 이미 유지 |
| Timer.periodic dispose 누락 | StepperButton에 dispose 명시, StatefulWidget 분리 |
| build() 내 registerIfAbsent 반복 호출 | containsKey 체크로 1회만 실행 |

### Backward Compatibility
- spring StateProvider 3개 유지 → _TunableScrollBehavior 영향 없음
- 기존 셔플/리딩 화면 코드 변경 없음 (Cycle 2에서 통합)

## Implementation Checklist

- [x] Step 1: TunableDouble 모델 생성
- [x] Step 2: DevTunerRegistry + provider 생성
- [x] Step 3: StepperButton 위젯 생성
- [x] Step 4: DevTunerOverlay 위젯 생성
- [x] Step 5: main.dart 교체 (SpringDebugPanel 제거, DevTunerOverlay + kDebugMode + 등록)
- [x] Step 6: 빌드 검증

## Verification Assertions

| Level | Assertion | Verification Method | Expected Result |
|-------|-----------|-------------------|-----------------|
| L1-Build | Dart 정적 분석 통과 | `flutter analyze` | 에러 0 |
| L3-Browser | Dev Tuner FAB 표시 | 에뮬레이터 스크린샷 | 우하단 tune 아이콘 |
| L3-Browser | 패널 열기 → 변수 3개 표시 | 에뮬레이터 탭 | mass, stiffness, damping + < N > 컨트롤 |
| L3-Browser | 변수 조정 → 스크롤 반영 | 에뮬레이터 인터랙션 | stiffness 변경 시 스크롤 바운스 속도 변화 |
| L3-Browser | 화면 전환 → 라우트 표시 | 에뮬레이터 네비게이션 | 패널 헤더 "Dev Tuner — shuffle" |
| L4-Trace | R-007-F1 라우트 감지 | /verify-trace | routerDelegate.addListener 구현 |
| L4-Trace | R-007-F4 kDebugMode 가드 | /verify-trace | builder에 kDebugMode 가드 적용 |

## References

| Resource | Path/URL | Related Content |
|----------|---------|-----------------|
| Scope | docs/15_dev_tuner/001_Scope_universal_dev_tuner.md | 전체 범위 |
| Research | docs/15_dev_tuner/007_Research_dev_tuner_architecture.md | 아키텍처 결정 |
| 현재 SpringDebugPanel | mobile/lib/main.dart:112-280 | 교체 대상 |
| GoRouter 설정 | mobile/lib/core/router/app_router.dart | 라우트 구조 |

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 0s | 0 |
| 2 | user-ai-exchange | 19s | 76045 |
| 3 | user-ai-exchange | 11s | 40778 |
| 4 | user-ai-exchange | 10s | 42195 |
| 5 | user-ai-exchange | 9s | 44183 |
| 6 | user-ai-exchange | 14s | 46529 |
| 7 | user-ai-exchange | 5s | 48356 |
| 8 | user-ai-exchange | 9s | 50568 |
| 9 | user-ai-exchange | 13s | 105037 |
| 10 | user-ai-exchange | 12s | 54453 |
| 11 | user-ai-exchange | 11s | 55874 |
| 12 | user-ai-exchange | 12s | 57359 |
| 13 | user-ai-exchange | 14s | 58996 |
| 14 | user-ai-exchange | 13s | 60582 |
| 15 | user-ai-exchange | 8s | 61831 |
| 16 | user-ai-exchange | 11s | 63033 |
| 17 | user-ai-exchange | 29s | 202688 |
| 18 | user-ai-exchange | 11s | 140060 |
| 19 | user-ai-exchange | 11s | 71985 |
| 20 | user-ai-exchange | 9s | 147944 |
| 21 | user-ai-exchange | 14s | 76148 |
| 22 | user-ai-exchange | 19s | 0 |
| 23 | user-ai-exchange | 10s | 41780 |
| 24 | user-ai-exchange | 13s | 45110 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 341150s |
| Total Tokens | 1591534 |
| Input Tokens | 71 |
| Output Tokens | 8834 |
| Cache Read | 1202235 |
| Cache Creation | 380394 |
