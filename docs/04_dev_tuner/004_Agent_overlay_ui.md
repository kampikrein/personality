---
id: "004"
title: "오버레이 UI + 스텝퍼 컨트롤 패턴"
category: agent
status: archived
created: 2026-03-18
confidence: high
summary: >
  현재 MaterialApp.builder 기반 Spring Tuner 오버레이의 구조적 문제(kDebugMode 미사용, 이중 Stack)를 분석한다.
  OverlayEntry 대안과의 히트테스트·컨텍스트 접근성·생명주기 차이를 비교하고, builder 패턴 유지를 권장한다.
  < N > 스텝퍼 컨트롤의 타입별(double/int/bool/enum) 구현 설계와 kDebugMode 트리-쉐이킹 가드를 코드 예시로 제시한다.
keywords: [agent-report, flutter-expert, overlay, stepper, debug-panel, kDebugMode]
modules: [mobile/lib/main.dart, mobile/lib/core/theme]
---

# 오버레이 UI + 스텝퍼 컨트롤 패턴

## 1. 현재 Spring Tuner 오버레이 구현 분석

### 1-1. 아키텍처 계층 구조

`mobile/lib/main.dart`의 현재 오버레이 구조는 **2중 Stack 패턴**이다.

```
MaterialApp.router
  └── builder (context, child)
        └── Stack                       ← 레이어 1 (main.dart:101)
              ├── child!               ← 실제 앱 콘텐츠 (GoRouter 라우트)
              └── Positioned.fill      ← main.dart:104
                    └── SpringDebugPanel
                          └── Stack    ← 레이어 2 (main.dart:138)
                                ├── Positioned (FAB 버튼)     ← main.dart:140
                                └── Positioned (패널, if _expanded)  ← main.dart:171
```

**코드 참조:**
- `main.dart:100-108`: `builder` 콜백에서 `Stack` + `Positioned.fill(child: SpringDebugPanel())`
- `main.dart:138-204`: `SpringDebugPanel._build`가 내부 `Stack` + 2개 `Positioned` 반환

### 1-2. 히트테스트 동작 (HitTestBehavior 분석)

`Positioned.fill(child: SpringDebugPanel())`이 전체 화면을 채우지만, 실제 터치 이벤트가 하위 앱으로 전달되는 메커니즘은 다음과 같다.

| 위젯 | HitTestBehavior | 동작 |
|------|----------------|------|
| 외부 `Positioned.fill` | (기본값) `deferToChild` | 자식에게 위임 |
| 내부 `Stack` | (기본값) `deferToChild` | 자식에게 위임 |
| `Positioned` (FAB) → `GestureDetector` | `HitTestBehavior.opaque` (main.dart:144) | 해당 40×40 영역만 이벤트 흡수 |
| `Positioned` (패널) → `Container` | (기본값) `deferToChild` | 패널 박스 내부만 이벤트 수신 |

`Stack`의 기본 동작: 모든 자식을 히트 테스트하되, **첫 번째로 히트되는 자식이 이벤트를 소비**한다. FAB와 패널 `Positioned` 바깥 영역은 아무 자식도 히트되지 않아 `Stack`이 `false`를 반환하고, 이벤트가 부모 `Stack`의 다음 자식(`child!`)으로 전달된다.

**결론**: 빈 영역 패스스루가 작동하는 이유는 `GestureDetector`가 없는 영역에서 내부 `Stack`이 히트테스트를 통과시키기 때문이다. 이는 의도된 동작이다.

### 1-3. 드래그 FAB 구현 (main.dart:143-169)

```dart
// main.dart:143-154 — 드래그 이동 로직
GestureDetector(
  behavior: HitTestBehavior.opaque,  // 40x40 영역 전체에서 터치 수신
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
```

**단점**:
- `onPanUpdate`와 `onTap`이 동일 `GestureDetector`에 공존 → 드래그 인식 후에도 `onTap`이 발화할 수 있음 (GestureArena 경합)
- 실제로 짧은 드래그(5px 미만)는 `onTap`으로 처리되어 의도치 않게 패널이 열림

**개선 방안**: `onTapUp`을 `onPanEnd`와 분리하거나 `dragStartDetails.delta.distanceSquared` 임계값으로 탭/드래그 구분.

### 1-4. 커스텀 슬라이더 구현 (main.dart:207-270)

`LayoutBuilder` → `GestureDetector(onHorizontalDragUpdate + onTapDown)` → 수동 fraction 계산 패턴이다.

```dart
// main.dart:226-232 — LayoutBuilder로 부모 너비를 얻어 비율 계산
LayoutBuilder(builder: (context, constraints) {
  final w = constraints.maxWidth;
  void updateValue(double dx) {
    final f = (dx / w).clamp(0.0, 1.0);
    ref.read(provider.notifier).state = min + (max - min) * f;
  }
```

**단점**: Material `Slider` 위젯을 사용하지 않아 접근성(`Semantics` 라벨 없음), 키보드 접근 불가. Dev Tuner는 개발 도구이므로 허용 범위이나, `< N >` 스텝퍼로 교체 시 접근성이 자동으로 향상됨.

### 1-5. 현재 구현의 치명적 결함: kDebugMode 미사용

**main.dart:100-108**에서 `SpringDebugPanel`이 `kDebugMode` 가드 없이 항상 포함된다.

```dart
// main.dart:100-108 — 릴리즈 빌드에도 디버그 패널이 포함됨 (버그)
builder: (context, child) {
  return Stack(
    children: [
      child!,
      const Positioned.fill(child: SpringDebugPanel()),  // kDebugMode 가드 없음!
    ],
  );
},
```

릴리즈 빌드에서 사용자에게 `tune` 아이콘이 노출되는 심각한 문제다.

---

## 2. OverlayEntry vs MaterialApp.builder 비교

### 2-1. MaterialApp.builder 패턴 (현재 방식)

**작동 원리**: `MaterialApp.builder`는 `MaterialApp`이 생성하는 `Navigator` 위에 추가 래퍼를 삽입한다. 라우트 전환과 무관하게 항상 동일한 위치에 오버레이를 렌더링한다.

```dart
// 현재 패턴 (main.dart:100-108)
MaterialApp.router(
  builder: (context, child) {
    return Stack(
      children: [
        child!,
        if (kDebugMode)  // 추가 필요
          const Positioned.fill(child: TunerOverlay()),
      ],
    );
  },
)
```

**장점:**
- 구현 단순함 — `builder` 콜백 하나로 완결
- `ProviderScope` 하위이므로 `ConsumerWidget`/`ConsumerStatefulWidget` 직접 사용 가능 (main.dart:80, 113)
- 라우트 전환 시 오버레이가 흔들리지 않음 (Navigator 위에 고정)
- `MediaQuery`, `Theme`에 자동 접근 가능 (MaterialApp 컨텍스트 상속)

**단점:**
- 오버레이를 동적으로 추가/제거하려면 `setState`나 Provider 상태 변경 필요
- `Scaffold.of(context)` 접근 불가 (Scaffold 외부)
- 다이얼로그/BottomSheet 등 `showDialog`보다 z-order가 낮음 — 다이얼로그가 튜너 위에 뜸

### 2-2. OverlayEntry 패턴 (대안)

**작동 원리**: Flutter의 `Overlay` 위젯은 `Navigator` 내부에 위치하며, `Overlay.of(context).insert(entry)`로 최상위 레이어에 위젯을 추가한다. 모든 라우트 콘텐츠와 다이얼로그 위에 렌더링된다.

```dart
// OverlayEntry 패턴 예시
class TunerOverlayController {
  OverlayEntry? _entry;

  void show(BuildContext context) {
    _entry = OverlayEntry(
      builder: (context) => const _TunerPanel(),
    );
    Overlay.of(context).insert(_entry!);
  }

  void hide() {
    _entry?.remove();
    _entry = null;
  }
}
```

**히트테스트 차이**: `OverlayEntry`는 기본적으로 전체 화면을 덮으며, `HitTestBehavior`를 직접 설정해야 패스스루가 된다. builder 패턴은 `Stack`의 기본 동작으로 자연스럽게 패스스루된다.

```dart
// OverlayEntry 패스스루 설정 예시
OverlayEntry(
  builder: (context) => IgnorePointer(   // 전체 패스스루
    ignoring: true,
    child: Stack(
      children: [
        Positioned(                       // FAB만 터치 수신
          left: x, top: y,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            child: _FabButton(),
          ),
        ),
      ],
    ),
  ),
)
```

### 2-3. 비교 매트릭스

| 기준 | MaterialApp.builder | OverlayEntry |
|------|---------------------|--------------|
| **구현 복잡도** | 낮음 — builder 콜백 | 중간 — Entry 생명주기 관리 필요 |
| **Riverpod 접근** | 즉시 가능 (ProviderScope 내부) | `UncontrolledProviderScope` 또는 별도 ProviderContainer 필요 |
| **z-order (다이얼로그 위)** | 불가 (Navigator 아래) | 가능 (Navigator Overlay 최상위) |
| **라우트 전환 안정성** | 완벽 — Navigator 외부 고정 | 완벽 — Overlay 레이어 고정 |
| **히트테스트 패스스루** | Stack 기본 동작으로 자동 | IgnorePointer 명시 필요 |
| **동적 추가/제거** | 상태 변수로 처리 | `insert`/`remove` API로 처리 |
| **MediaQuery/Theme 접근** | 자동 상속 | 자동 상속 (Overlay도 MaterialApp 하위) |
| **Dev Tuner 적합성** | **권장** | 과도한 복잡성 |

**결론**: Dev Tuner는 Riverpod 변수에 직접 접근하고 다이얼로그 위에 뜰 필요가 없으므로 **`MaterialApp.builder` 패턴 유지를 권장**한다. OverlayEntry는 다이얼로그 위 오버레이가 필요한 광고 배너, 토스트 알림 등에 적합하다.

### 2-4. 컨텍스트 접근성 심층 분석

`OverlayEntry`에서 Riverpod을 사용하려면 추가 설정이 필요하다:

```dart
// OverlayEntry 내부에서 Riverpod 사용 — 복잡한 방법
OverlayEntry(
  builder: (context) {
    // context가 ProviderScope 외부인 경우 에러 발생
    // Consumer로 감싸야 함
    return Consumer(
      builder: (context, ref, _) {
        final value = ref.watch(someProvider);
        return Text('$value');
      },
    );
  },
)
```

`MaterialApp.builder`는 `ProviderScope` → `PersonalityApp(ConsumerWidget)` → `builder` 콜백 순서이므로, builder 내부의 context는 항상 `ProviderScope` 하위다. `ConsumerStatefulWidget`인 `SpringDebugPanel`(main.dart:113)이 직접 `ref.watch`를 사용할 수 있는 이유가 여기에 있다.

---

## 3. `< N >` 스텝퍼 컨트롤 구현 설계

### 3-1. 설계 요구사항

- `<` 버튼으로 값 감소, `>` 버튼으로 값 증가
- 중앙에 현재 값 표시 (포맷은 타입별로 다름)
- 변수별 다른 `step` 크기 지원 (예: mass=0.1, stiffness=50.0)
- 길게 누르면 연속 증감 (선택)
- `double`, `int`, `bool`, `enum` 타입별 컨트롤 차이

### 3-2. TunableVariable 모델

```dart
// mobile/lib/core/dev_tuner/tunable_variable.dart
import 'package:flutter/foundation.dart';

/// 튜닝 가능 변수의 타입
enum TunableType { doubleType, intType, boolType, enumType }

/// Dev Tuner에서 조정 가능한 변수 메타데이터 + 현재 값 홀더
class TunableVariable<T> {
  TunableVariable({
    required this.key,           // 고유 식별자 (화면명_변수명)
    required this.label,         // UI 표시 레이블
    required this.initialValue,  // 초기값
    this.min,                    // double/int 최솟값
    this.max,                    // double/int 최댓값
    this.step,                   // double/int 스텝 크기
    this.enumValues,             // enum 타입의 선택지
    this.format,                 // 값 포맷 함수
  }) : _value = initialValue;

  final String key;
  final String label;
  final T initialValue;
  final double? min;
  final double? max;
  final double? step;
  final List<T>? enumValues;
  final String Function(T)? format;

  T _value;
  T get value => _value;

  // ValueNotifier 대신 콜백 패턴 (Riverpod 연동 시 대체)
  final List<void Function(T)> _listeners = [];
  void addListener(void Function(T) listener) => _listeners.add(listener);

  void increment() {
    if (_value is double) {
      final v = (_value as double) + (step ?? 0.1);
      _value = (max != null ? v.clamp(min ?? double.negativeInfinity, max!) : v) as T;
    } else if (_value is int) {
      final v = (_value as int) + (step?.toInt() ?? 1);
      _value = (max != null ? v.clamp((min ?? double.negativeInfinity).toInt(), max!.toInt()) : v) as T;
    } else if (_value is bool) {
      _value = (true) as T;
    } else if (enumValues != null) {
      final idx = enumValues!.indexOf(_value);
      _value = enumValues![(idx + 1) % enumValues!.length];
    }
    for (final l in _listeners) { l(_value); }
  }

  void decrement() {
    if (_value is double) {
      final v = (_value as double) - (step ?? 0.1);
      _value = (min != null ? v.clamp(min!, max ?? double.infinity) : v) as T;
    } else if (_value is int) {
      final v = (_value as int) - (step?.toInt() ?? 1);
      _value = (min != null ? v.clamp(min!.toInt(), (max ?? double.infinity).toInt()) : v) as T;
    } else if (_value is bool) {
      _value = (false) as T;
    } else if (enumValues != null) {
      final idx = enumValues!.indexOf(_value);
      _value = enumValues![(idx - 1 + enumValues!.length) % enumValues!.length];
    }
    for (final l in _listeners) { l(_value); }
  }

  String get displayValue {
    if (format != null) return format!(_value);
    if (_value is double) return (_value as double).toStringAsFixed(
      (step ?? 0.1) < 1 ? 2 : 0,
    );
    return '$_value';
  }
}
```

### 3-3. 스텝퍼 위젯 구현

```dart
// mobile/lib/core/dev_tuner/widgets/stepper_control.dart
import 'package:flutter/material.dart';
import 'dart:async';

class StepperControl extends StatefulWidget {
  const StepperControl({
    super.key,
    required this.label,
    required this.displayValue,
    required this.onIncrement,
    required this.onDecrement,
    this.onLongPressInterval = const Duration(milliseconds: 80),
  });

  final String label;
  final String displayValue;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final Duration onLongPressInterval;

  @override
  State<StepperControl> createState() => _StepperControlState();
}

class _StepperControlState extends State<StepperControl> {
  Timer? _repeatTimer;

  void _startRepeat(VoidCallback action) {
    action();  // 즉시 1회 실행
    _repeatTimer = Timer.periodic(widget.onLongPressInterval, (_) => action());
  }

  void _stopRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  @override
  void dispose() {
    _stopRepeat();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // 라벨
          SizedBox(
            width: 72,
            child: Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // < 감소 버튼
          _ArrowButton(
            symbol: '<',
            onTap: widget.onDecrement,
            onLongPressStart: () => _startRepeat(widget.onDecrement),
            onLongPressEnd: _stopRepeat,
          ),
          // 현재 값 표시 (고정 너비)
          Container(
            width: 72,
            alignment: Alignment.center,
            child: Text(
              widget.displayValue,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // > 증가 버튼
          _ArrowButton(
            symbol: '>',
            onTap: widget.onIncrement,
            onLongPressStart: () => _startRepeat(widget.onIncrement),
            onLongPressEnd: _stopRepeat,
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.symbol,
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  final String symbol;
  final VoidCallback onTap;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPressStart: (_) => onLongPressStart(),
      onLongPressEnd: (_) => onLongPressEnd(),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          symbol,
          style: const TextStyle(
            color: Colors.tealAccent,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
```

### 3-4. bool/enum 타입별 UI 차이

| 타입 | 표시 방식 | < / > 동작 |
|------|---------|-----------|
| `double` | `"1.30"` (소수점 2자리) | step만큼 증감, min/max clamp |
| `int` | `"900"` (정수) | step(기본 1)만큼 증감 |
| `bool` | `"true"` / `"false"` | < = false, > = true (또는 토글) |
| `enum` | enum name (예: `"fast"`) | 목록 순환 (< = 이전, > = 다음) |

`bool` 타입의 경우 `<>` 스텝퍼보다 **토글 스위치**가 더 직관적이다. `TunableType`에 따라 `StepperControl` 또는 `ToggleControl`을 조건부 렌더링하는 팩토리 위젯을 권장한다:

```dart
// 타입별 컨트롤 팩토리
Widget buildControl(TunableVariable variable) {
  if (variable.value is bool) {
    return _BoolToggleRow(variable: variable);
  }
  return StepperControl(
    label: variable.label,
    displayValue: variable.displayValue,
    onIncrement: variable.increment,
    onDecrement: variable.decrement,
  );
}
```

### 3-5. 스프링 튜너 마이그레이션 예시

현재 `_buildSlider` (main.dart:207-270)를 `StepperControl`로 교체하는 마이그레이션:

```dart
// Before: main.dart:189-193 — 슬라이더 방식
_buildSlider('mass', mass, 0.1, 3.0, springMassProvider),
_buildSlider('stiffness', stiffness, 50, 3000, springStiffnessProvider),
_buildSlider('damping', damping, 0.1, 10.0, springDampingProvider),

// After: 스텝퍼 방식
StepperControl(
  label: 'mass',
  displayValue: mass.toStringAsFixed(2),
  onDecrement: () => ref.read(springMassProvider.notifier).update(
    (v) => (v - 0.1).clamp(0.1, 3.0),
  ),
  onIncrement: () => ref.read(springMassProvider.notifier).update(
    (v) => (v + 0.1).clamp(0.1, 3.0),
  ),
),
```

---

## 4. kDebugMode 가드 패턴

### 4-1. kDebugMode란

`package:flutter/foundation.dart`에서 제공하는 컴파일 타임 상수다.

```dart
import 'package:flutter/foundation.dart';

// Flutter SDK 정의 (foundation/constants.dart)
const bool kDebugMode = !kReleaseMode && !kProfileMode;
const bool kReleaseMode = bool.fromEnvironment('dart.vm.product');
const bool kProfileMode = bool.fromEnvironment('dart.vm.profile');
```

**핵심**: `bool.fromEnvironment`는 Dart 컴파일러가 컴파일 타임에 값을 결정한다. `kReleaseMode`는 릴리즈 빌드에서 `true`, 디버그에서 `false`로 하드코딩된다.

### 4-2. Tree Shaking 동작

Dart의 tree shaking은 `if (kDebugMode)` 블록을 릴리즈 빌드에서 **완전히 제거**한다.

```dart
// 디버그 빌드 → 컴파일됨
// 릴리즈 빌드 → 컴파일러가 블록 전체 제거 (dead code elimination)
if (kDebugMode) {
  // 이 블록은 릴리즈 바이너리에 포함되지 않음
  const Positioned.fill(child: TunerOverlay()),
}
```

**증명**: Flutter 공식 문서 [Dart compile-time constants](https://dart.dev/guides/language/language-tour#final-and-const) — `bool.fromEnvironment`의 결과가 컴파일 타임 상수이므로, Dart AOT 컴파일러는 dead branch를 완전히 제거한다.

### 4-3. assert() vs if(kDebugMode) 비교

| | `assert(() { ... }())` | `if (kDebugMode) { ... }` |
|--|----------------------|--------------------------|
| **적용 범위** | 디버그 모드만 실행 | 디버그 모드만 실행 |
| **Tree shaking** | 릴리즈 빌드에서 제거 | 릴리즈 빌드에서 제거 |
| **반환값** | `bool` (assertion 성공 여부) | 없음 |
| **사용 목적** | 불변 조건 검증 | 디버그 전용 코드 실행 |
| **위젯 빌드** | 불가 (표현식 제한) | 가능 (임의 코드 블록) |
| **적합 사례** | `assert(value >= 0, 'negative!')` | 디버그 패널, 로깅 코드 |

Dev Tuner 오버레이처럼 위젯을 조건부 포함하는 경우 **`if (kDebugMode)`**를 사용해야 한다:

```dart
// sensor_gravity_controller.dart:46 — assert 사용 사례 (현재 프로젝트)
assert(() {
  // 디버그 검증 코드
  return true;  // assert는 true를 반환해야 통과
}());

// Dev Tuner 오버레이 — if(kDebugMode) 필수
builder: (context, child) {
  return Stack(
    children: [
      child!,
      if (kDebugMode)
        const Positioned.fill(child: TunerOverlay()),
    ],
  );
},
```

### 4-4. 완전한 kDebugMode 가드 패턴 (main.dart 수정 목표)

```dart
// mobile/lib/main.dart — 수정 목표 코드
import 'package:flutter/foundation.dart';  // kDebugMode

class PersonalityApp extends ConsumerWidget {
  const PersonalityApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // 릴리즈 빌드에서는 springMass/Stiffness/Damping Provider를 읽지 않음
    // → tree shaking이 Provider 자체도 제거할 수 있음
    final mass = kDebugMode ? ref.watch(springMassProvider) : 0.5;
    final stiffness = kDebugMode ? ref.watch(springStiffnessProvider) : 900.0;
    final damping = kDebugMode ? ref.watch(springDampingProvider) : 1.3;

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
        return Stack(
          children: [
            child!,
            if (kDebugMode)  // 릴리즈 빌드에서 TunerOverlay 완전 제거
              const Positioned.fill(child: TunerOverlay()),
          ],
        );
      },
    );
  }
}
```

### 4-5. Provider 수준 kDebugMode 가드

튜너 `StateProvider` 자체도 `kDebugMode` 가드로 감쌀 수 있다:

```dart
// Dev Tuner 전용 Provider를 별도 파일로 분리
// mobile/lib/core/dev_tuner/tuner_providers.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// kDebugMode 가드가 있으므로 릴리즈에서 dead code
final springMassProvider = kDebugMode
    ? StateProvider<double>((ref) => 0.5)
    : StateProvider<double>((ref) => 0.5);  // 릴리즈에서도 동일 기본값
```

**주의**: Provider 자체는 `kDebugMode`로 tree shaking되지 않는다 (런타임 조건이 아닌 컴파일 타임이지만, Provider 등록은 런타임 객체). 가장 확실한 방법은 `if (kDebugMode)` 블록에서만 `ref.watch`하여 Provider가 구독되지 않도록 하는 것이다.

---

## Summary

현재 `Spring Tuner` 구현은 `MaterialApp.builder` + 이중 `Stack` + `Positioned.fill` 패턴으로 오버레이를 구현한다. 히트테스트 패스스루는 `Stack`의 기본 동작으로 자동 처리되어 의도적으로 잘 작동한다. 그러나 **`kDebugMode` 가드가 없어** 릴리즈 빌드에서도 디버그 패널이 노출되는 버그가 존재한다.

`OverlayEntry` 대안은 다이얼로그 위에 오버레이를 띄워야 할 때 적합하지만, Riverpod 접근 복잡성과 생명주기 관리 부담이 크다. Dev Tuner에는 `MaterialApp.builder` 패턴 유지가 최적이다.

`< N >` 스텝퍼 컨트롤은 `GestureDetector.onLongPressStart/End` + `Timer.periodic`으로 길게 누르기 연속 증감을 구현하며, `bool` 타입은 토글 스위치로 분기한다.

## Key Findings

1. **main.dart:104** — `Positioned.fill(child: SpringDebugPanel())`에 `kDebugMode` 가드 없음 → 릴리즈 빌드 버그
2. **main.dart:144** — `HitTestBehavior.opaque`가 FAB 영역(40×40)에만 적용되어 빈 영역 패스스루 자동 동작
3. **OverlayEntry 결론** — Riverpod ConsumerWidget 사용 시 복잡도 상승, Dev Tuner에 부적합
4. **kDebugMode tree shaking** — `if (kDebugMode)` 블록은 Dart AOT에서 릴리즈 바이너리에 완전 미포함
5. **드래그/탭 경합** — `onPanUpdate`와 `onTap`이 동일 GestureDetector → 짧은 드래그 후 패널 열림 발생 가능

## Recommendations

1. **즉시 수정**: `main.dart:104`에 `if (kDebugMode)` 추가 — 릴리즈 빌드 보안
2. **슬라이더 → 스텝퍼 교체**: `_buildSlider` 메서드를 `StepperControl` 위젯으로 대체 — UX 개선
3. **TunableVariable 모델 도입**: 범용 Dev Tuner 확장을 위한 타입별 모델 설계 (섹션 3-2 코드 참조)
4. **드래그/탭 분리**: `onPanUpdate` 누적 거리 임계값(예: 5px²)으로 탭/드래그 구분
5. **builder 패턴 유지**: OverlayEntry 마이그레이션 불필요 — 현재 패턴이 Dev Tuner에 최적

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
