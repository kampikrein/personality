---
id: "003"
title: "GoRouter 라우트 감지 + 변수 레지스트리 설계"
category: agent
status: archived
created: 2026-03-18
confidence: high
summary: >
  GoRouter 14.8.1(실제 캐시 버전) 소스 분석을 통해 활성 라우트 감지 4가지 방법의
  트레이드오프를 도출했다. Riverpod 기반 화면별 tunable 변수 레지스트리는 단일
  글로벌 Notifier 패턴을 추천하며, 1줄 등록 API 설계안을 제시한다.
keywords: [agent-report, flutter-expert, gorouter, riverpod, route-detection, variable-registry]
modules: [mobile/lib/core/router, mobile/lib/main.dart]
---

# GoRouter 라우트 감지 + 변수 레지스트리 설계

## 1. 현재 app_router.dart 라우트 구조 분석

**파일**: `mobile/lib/core/router/app_router.dart`

```
GoRouter (initialLocation: '/')
├── GoRoute  path='/'                    name='home'
├── GoRoute  path='/deck'                name='deck'
├── GoRoute  path='/intention/:deckId'   name='intention'
├── GoRoute  path='/shuffle/:deckId'     name='shuffle'
└── GoRoute  path='/reading/:deckId'     name='reading'
```

**구조 특성** (app_router.dart:29-76):
- 5개 flat 라우트, ShellRoute 없음 — 중첩 라우터 복잡도 없음
- 전체 `pageBuilder` 사용 (`CustomTransitionPage`, FadeTransition 600ms)
- `pageBuilder` 패턴은 `GoRouterState.of(context)`를 페이지 내부 위젯에서만 사용 가능
  (pageBuilder 람다 자체에서는 `state` 파라미터로 직접 접근)
- `appRouterProvider`는 `AutoDisposeProvider<GoRouter>` (app_router.g.dart:13)
  — keepAlive가 없어 참조 없으면 dispose 위험. Dev Tuner에서 참조 유지 필요.
- 3개 라우트(intention/shuffle/reading)가 `:deckId` path parameter 포함
  — 라우트 name만으로 화면 식별이 충분

**5개 화면 이름 상수** (Dev Tuner에서 사용):
```dart
// 라우트 name은 GoRoute.name 필드 (app_router.dart:34,41,47,54,63)
const kRouteHome      = 'home';
const kRouteDeck      = 'deck';
const kRouteIntention = 'intention';
const kRouteShuffle   = 'shuffle';
const kRouteReading   = 'reading';
```

---

## 2. GoRouter 활성 라우트 감지 방법 비교

### 방법 A: `routerDelegate.addListener` (권장)

**소스 근거**: `GoRouterDelegate`가 `ChangeNotifier`를 mixin (go_router-14.8.1/lib/src/delegate.dart:20).
라우트 변경 시 `notifyListeners()` 호출 (delegate.dart:180).
`state` getter가 `currentConfiguration.last.buildState(...)` 반환 (delegate.dart:188-189).

```dart
// Riverpod Provider 내부에서 사용
@Riverpod(keepAlive: true)
class ActiveRouteNotifier extends _$ActiveRouteNotifier {
  @override
  String build() => 'home'; // 초기값

  void listenTo(GoRouter router) {
    router.routerDelegate.addListener(() {
      final routeName = router.routerDelegate.state.name ?? 'home';
      if (state != routeName) state = routeName;
    });
  }
}
```

**장점**:
- Context 불필요 — Provider에서 직접 연결 가능
- 라우트 전환 시 즉시 콜백 (notifyListeners 타이밍)
- `GoRouterState.name` 필드가 nullable이나, 5개 named route는 항상 non-null

**단점**:
- `appRouterProvider`가 AutoDispose이므로 router 인스턴스 생명주기 관리 필요
- `routerDelegate.addListener`는 `removeListener`로 정리해야 메모리 누수 없음

### 방법 B: `GoRouter.of(context).state` (즉시 읽기)

**소스 근거**: `GoRouter.state` getter (router.dart:264) → `routerDelegate.state` 위임.
`GoRouter.of(context)`는 `InheritedGoRouter`에서 추출 (router.dart:519-522).

```dart
// Widget.build 내부에서 사용
class SomeWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentName = GoRouter.of(context).state.name; // nullable String?
    // ...
  }
}
```

**장점**: BuildContext만 있으면 즉시 접근, 코드 간결

**단점**:
- rebuild를 유발하지 않음 — 라우트 변경 감지 불가
- 오버레이 위젯(전역 Stack)에서는 context의 GoRouter 접근이 보장되지 않음
- Dev Tuner 오버레이는 `MaterialApp.builder` 내부이므로 접근 가능하나 신뢰도 낮음

### 방법 C: `GoRouterState.of(context)` (위젯 트리 내부)

**소스 근거**: static `GoRouterState.of(context)` (state.dart:118-146).
`ModalRoute.of(context)` → `GoRouterStateRegistryScope` 순으로 탐색.

```dart
// GoRoute.builder 또는 해당 라우트 하위 위젯에서만 사용 가능
class ShufflePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = GoRouterState.of(context); // name, pathParameters 등
    final routeName = state.name; // 'shuffle'
    // ...
  }
}
```

**장점**: 해당 페이지 컨텍스트에서 가장 정확한 상태 제공

**단점**:
- `pageBuilder`가 반환한 `CustomTransitionPage`의 child Widget 내부에서만 호출 가능
- 전역 오버레이(Dev Tuner)에서는 사용 불가 — 오버레이는 라우트 트리 밖
- 현재 app_router.dart는 `pageBuilder` 패턴 사용이므로 주의 필요 (state.dart:99-101)

### 방법 D: `NavigatorObserver` 구현

**소스 근거**: `GoRouter(observers: [...])` 생성자 파라미터 (router.dart:137).

```dart
class DevTunerRouteObserver extends NavigatorObserver {
  final void Function(String routeName) onRouteChanged;
  DevTunerRouteObserver({required this.onRouteChanged});

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _notify(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) _notify(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _notify(newRoute);
  }

  void _notify(Route<dynamic> route) {
    final settings = route.settings;
    if (settings is Page) {
      // GoRouter의 CustomTransitionPage에서 name 추출은 복잡
      // route.settings.name은 path이지 name이 아님
      onRouteChanged(settings.name ?? '');
    }
  }
}
```

**장점**: 모든 네비게이션 이벤트 감지 (push/pop/replace)

**단점**:
- `settings.name`이 GoRoute.name이 아닌 URI path를 반환 — 추가 파싱 필요
- GoRouter 생성자에 observer 주입 필요 → app_router.dart 수정 필요
- 방법 A 대비 설정 복잡도 높음

### 비교 요약

| 방법 | Context 필요 | Rebuild 감지 | 전역 오버레이 | 복잡도 | 추천 |
|------|------------|------------|-------------|--------|------|
| A. `routerDelegate.addListener` | No | Yes | Yes | 중 | **1순위** |
| B. `GoRouter.of(context).state` | Yes | No | 조건부 | 낮 | 읽기 전용 |
| C. `GoRouterState.of(context)` | Yes | No | No | 낮 | 페이지 내부 |
| D. `NavigatorObserver` | No | Yes | Yes | 높 | 2순위 |

**결론**: Dev Tuner 오버레이(전역 Stack)에서 활성 라우트를 감지하려면 **방법 A**가 최적.
방법 D는 route name 파싱이 추가로 필요하고 설정이 복잡하므로 2순위.

---

## 3. Riverpod 화면별 변수 집합 관리 패턴 비교

### 패턴 A: 단일 글로벌 레지스트리 (추천)

`StateNotifier`를 사용하는 `Map<String, List<TunableVar>>` 중앙 레지스트리.

```dart
// domain entity
@freezed
class TunableVar with _$TunableVar {
  const factory TunableVar({
    required String key,
    required String label,
    required double value,
    required double min,
    required double max,
    required StateProvider<double> provider,
  }) = _TunableVar;
}

// notifier
@Riverpod(keepAlive: true)
class TunableRegistry extends _$TunableRegistry {
  @override
  Map<String, List<TunableVar>> build() => {};

  /// 1줄 등록 API: 화면 init 시 호출
  void register(String routeName, List<TunableVar> vars) {
    state = {...state, routeName: vars};
  }

  void unregister(String routeName) {
    final next = Map<String, List<TunableVar>>.from(state);
    next.remove(routeName);
    state = next;
  }

  List<TunableVar> variablesFor(String routeName) =>
      state[routeName] ?? [];
}

// 활성 라우트 추적
@Riverpod(keepAlive: true)
class ActiveRoute extends _$ActiveRoute {
  @override
  String build() => 'home';
  void set(String routeName) => state = routeName;
}

// Dev Tuner 패널에서 현재 화면 변수 조회
@riverpod
List<TunableVar> currentTunables(CurrentTunablesRef ref) {
  final route = ref.watch(activeRouteProvider);
  return ref.watch(tunableRegistryProvider.select((m) => m[route] ?? []));
}
```

**장점**:
- 단일 진실의 원천 — 모든 화면 변수가 하나의 Map에 집중
- `register()` 1줄로 변수 등록 가능
- 화면 dispose 시 `unregister()` 호출로 정리 가능
- Riverpod `select`로 현재 라우트 변수만 구독 — 불필요한 rebuild 없음

**단점**:
- 화면이 늘어날수록 Map 크기 증가 (5개 화면이라 문제 없음)
- 화면별 변수 타입이 모두 `double`로 고정 — 추후 String/bool 확장 시 sealed class 필요

### 패턴 B: Provider Family (화면 파라미터)

```dart
@riverpod
List<TunableVar> screenTunables(ScreenTunablesRef ref, String routeName) {
  // routeName별로 별도 Provider 인스턴스 생성
  return []; // 각 화면에서 override로 값 제공
}
```

실제 사용:

```dart
// ShufflePage에서
ProviderScope(
  overrides: [
    screenTunablesProvider('shuffle').overrideWithValue([
      TunableVar(key: 'gravity', label: 'Gravity', ...),
    ]),
  ],
  child: ShufflePage(),
)
```

**장점**:
- 화면별 격리 — 다른 화면 변수가 서로 영향 없음
- Riverpod의 `family` 패턴 네이티브 활용

**단점**:
- `ProviderScope` override 방식은 화면 Widget 트리에 종속 — 전역 Dev Tuner 패널에서 접근하려면 별도 글로벌 ref 필요
- 동적 등록(런타임에 새 화면 추가)이 어려움
- 현재 app_router.dart의 pageBuilder 패턴과 ProviderScope override 조합이 복잡

### 패턴 비교 요약

| 항목 | A. 글로벌 레지스트리 | B. Provider Family |
|------|-------------------|-------------------|
| 등록 코드량 | 1줄 `register()` | ProviderScope override |
| 전역 패널 접근 | 쉬움 | 어려움 |
| 타입 안전성 | 중 (dynamic Map) | 높 (compile-time) |
| 동적 등록 | Yes | 제한적 |
| 현재 코드와 궁합 | 높음 | 낮음 |

**결론**: 패턴 A (단일 글로벌 레지스트리) 추천. 전역 오버레이에서 쉽게 접근 가능하고,
1줄 등록 API를 제공하며, 현재 `appRouterProvider + StateProvider` 코드 패턴과 일관성 있음.

---

## 4. 변수 등록 API 설계 제안

### 목표
각 화면에서 **1-2줄**로 Dev Tuner에 변수를 등록. 화면 dispose 시 자동 해제.

### 설계안 A: ConsumerStatefulWidget `initState`/`dispose` 패턴

```dart
// 사용 예시 — ShufflePage
class _ShufflePageState extends ConsumerState<ShufflePage> {
  @override
  void initState() {
    super.initState();
    // 1줄 등록
    DevTuner.register(ref, 'shuffle', [
      TunableVar.double('gravity', label: '중력', value: 9.8, min: 0, max: 30,
          provider: gravityProvider),
      TunableVar.double('friction', label: '마찰', value: 0.3, min: 0, max: 1,
          provider: frictionProvider),
    ]);
  }

  @override
  void dispose() {
    DevTuner.unregister(ref, 'shuffle'); // 1줄 해제
    super.dispose();
  }
}

// DevTuner 헬퍼 (thin wrapper)
class DevTuner {
  static void register(WidgetRef ref, String route, List<TunableVar> vars) {
    if (!kDebugMode) return; // 릴리즈 빌드 no-op
    ref.read(tunableRegistryProvider.notifier).register(route, vars);
  }

  static void unregister(WidgetRef ref, String route) {
    if (!kDebugMode) return;
    ref.read(tunableRegistryProvider.notifier).unregister(route);
  }
}
```

### 설계안 B: `ref.listenManual` + 자동 dispose Hook 패턴

```dart
// hooks_riverpod 없이 ConsumerWidget에서도 동작하는 ref.onDispose 활용
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    DevTuner.registerWithAutoDispose(ref, 'shuffle', shuffleVars);
  });
}

// registerWithAutoDispose: ref.onDispose로 자동 정리
static void registerWithAutoDispose(
  WidgetRef ref, String route, List<TunableVar> vars) {
  if (!kDebugMode) return;
  ref.read(tunableRegistryProvider.notifier).register(route, vars);
  ref.onDispose(() =>
      ref.read(tunableRegistryProvider.notifier).unregister(route));
}
```

**설계안 A 추천 이유**: `ref.onDispose`는 Provider 내부에서만 사용 가능 (WidgetRef 제한).
ConsumerStatefulWidget의 `dispose()`에서 명시적으로 unregister 호출이 더 안전하고 명확하다.

### 활성 라우트 연결 설계

```dart
// app_router.dart 수정 — redirect 또는 GoRouter 생성 시 리스너 연결
@Riverpod(keepAlive: true) // keepAlive로 변경 필요
GoRouter appRouter(AppRouterRef ref) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [...],
  );

  // 라우트 변경 감지 — routerDelegate.addListener (방법 A)
  void onRouteChanged() {
    final name = router.routerDelegate.state.name ?? 'home';
    ref.read(activeRouteProvider.notifier).set(name);
  }

  router.routerDelegate.addListener(onRouteChanged);
  ref.onDispose(() => router.routerDelegate.removeListener(onRouteChanged));

  return router;
}
```

**주의**: 현재 `appRouterProvider`는 AutoDispose (app_router.g.dart:13). 리스너 연결을 위해
`@Riverpod(keepAlive: true)`로 변경이 필요하다. 또는 `main.dart`의 `PersonalityApp`에서
`ref.watch(appRouterProvider)` 시점에 리스너 연결.

### 전체 흐름 요약

```
GoRouter.routerDelegate.addListener()
    │ 라우트 변경 시
    ▼
activeRouteProvider.notifier.set('shuffle')
    │ Riverpod 구독자 알림
    ▼
currentTunablesProvider (select: activeRoute → registry[route])
    │ 현재 화면 변수 목록 반환
    ▼
Dev Tuner 오버레이 패널 rebuild
```

---

## Summary

GoRouter 14.8.1의 `GoRouterDelegate`는 `ChangeNotifier`를 mixin하므로
`routerDelegate.addListener()`가 라우트 변경 감지의 가장 직접적이고 신뢰할 수 있는 방법이다.
`GoRouter.of(context).state`는 즉시 읽기에 적합하지만 rebuild를 유발하지 않으므로
전역 오버레이의 반응형 감지에는 부적합하다.

Riverpod 화면별 변수 레지스트리는 `Map<String, List<TunableVar>>` 기반 단일 글로벌
`Notifier`가 전역 Dev Tuner 패널 접근과 1줄 등록 API 모두를 만족한다.
Provider family는 타입 안전성이 높으나 전역 오버레이와의 연결이 복잡해 현재 구조에 맞지 않는다.

## Key Findings

1. **GoRouterDelegate는 ChangeNotifier** — `addListener`로 라우트 변경 감지 가능
   (go_router-14.8.1/lib/src/delegate.dart:20, 180, 188)

2. **5개 라우트 모두 named route** — `state.name`이 항상 non-null
   (app_router.dart:34, 41, 47, 54, 63)

3. **appRouterProvider는 AutoDispose** — keepAlive 전환 또는 외부에서 리스너 관리 필요
   (app_router.g.dart:13)

4. **pageBuilder 패턴** — `GoRouterState.of(context)`는 builder 패턴에서만 동작.
   현재 앱은 pageBuilder이므로 오버레이에서 GoRouterState.of() 사용 불가
   (go_router-14.8.1/lib/src/state.dart:99-101)

5. **main.dart SpringDebugPanel 구조** — 이미 `MaterialApp.router builder`에서
   전역 오버레이 Stack 패턴 사용 중 (main.dart:100-108). Dev Tuner도 동일 패턴 확장 가능.

6. **현재 SpringProvider 패턴** — `StateProvider<double>` 3개 (main.dart:25-27).
   `TunableVar`도 동일하게 `StateProvider<double>`를 참조 필드로 포함하면 기존 패턴과 일관성.

## Recommendations

1. **라우트 감지**: `appRouter` provider를 `keepAlive: true`로 변경하고,
   `routerDelegate.addListener` 패턴으로 `activeRouteProvider` 업데이트

2. **변수 레지스트리**: 패턴 A(단일 글로벌 `TunableRegistry` Notifier) 채택.
   `Map<String, List<TunableVar>>` + `keepAlive: true`

3. **등록 API**: `DevTuner.register(ref, 'routeName', [...])` 1줄 인터페이스.
   `initState`/`dispose`에서 명시적 등록/해제. `kDebugMode` 가드로 릴리즈 no-op.

4. **기존 SpringProvider 통합**: `springMassProvider` 등을 `TunableVar`로 래핑하여
   'home' 라우트에 등록하면 기존 Spring Tuner를 Dev Tuner 하위로 통합 가능.

5. **주의사항**: `GoRouterState.name`은 `String?` (nullable). 5개 라우트는 모두
   `name` 필드 설정되어 있으나, fallback `?? 'home'` 처리 필요 (state.dart:49).

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
