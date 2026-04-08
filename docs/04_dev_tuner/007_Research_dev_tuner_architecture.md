---
id: "007"
type: research
title: "Dev Tuner 아키텍처 연구 — 라우트 감지·변수 레지스트리·오버레이 UI"
created: 2026-03-18
traces_scope: "001"
summary: >
  Universal Dev Tuner 구현을 위한 아키텍처 연구. GoRouter routerDelegate.addListener로 라우트 감지,
  단일 글로벌 TunerRegistry Notifier로 변수 관리, MaterialApp.builder 오버레이 유지,
  타입별 < N > 스텝퍼 UI, kDebugMode 트리-쉐이킹 가드. 49개 튜닝 변수 식별.
keywords: [gorouter, riverpod, overlay, stepper, debug-panel, route-detection, variable-registry]
---

# Dev Tuner 아키텍처 연구

## Research Overview

### Background & Motivation
현재 Spring Tuner는 main.dart에 3개 스프링 물리 변수(mass, stiffness, damping)만 하드코딩.
범용 Dev Tuner로 확장하려면 화면별 변수 등록, 라우트 감지, 오버레이 UI 아키텍처가 필요.

### Research Scope
- 포함: GoRouter 라우트 감지, Riverpod 변수 관리, Flutter 오버레이, 스텝퍼 UI, 화면 변수 탐색
- 제외: DevTools Extension, 외부 디버그 라이브러리

### Research Perspectives
1. **GoRouter 라우트 감지 + 변수 레지스트리 설계**
2. **오버레이 UI + 스텝퍼 컨트롤 패턴**
3. **기존 화면별 하드코딩 변수 탐색**

### Related Documents
- Checkpoint: [002_Research_dev_tuner_architecture.md](./002_Research_dev_tuner_architecture.md)
- Agent reports: [003](./003_Agent_route_registry.md), [004](./004_Agent_overlay_ui.md), [005](./005_Agent_screen_variables.md)
- Synthesis: [006_Synthesis_dev_tuner_architecture.md](./006_Synthesis_dev_tuner_architecture.md)

---

## Perspective 1: GoRouter 라우트 감지 + 변수 레지스트리 설계

### Status Analysis

현재 app_router.dart(29-76)에 5개 flat GoRoute:
- home(`/`), deck(`/deck`), intention(`/intention/:deckId`), shuffle(`/shuffle/:deckId`), reading(`/reading/:deckId`)
- `appRouterProvider`는 AutoDisposeProvider (app_router.g.dart:13) — 참조 없으면 dispose 위험

### Detailed Findings

#### 라우트 감지: 4가지 방법 비교

| 방법 | 메커니즘 | Context 필요 | 적합성 |
|------|---------|-------------|--------|
| **A. routerDelegate.addListener** | `GoRouterDelegate`가 ChangeNotifier (delegate.dart:20). `state.name`으로 라우트명 추출 | 불필요 | **최적** — 전역 오버레이에서 직접 사용 |
| B. GoRouterState.of(context) | 위젯 내부에서 현재 라우트 상태 접근 | 필요 | 오버레이 위젯에서 context 전달 필요 |
| C. NavigatorObserver | `didPush/didPop` 콜백 | 불필요 | GoRouter의 declarative 방식과 충돌 가능 |
| D. routeInformationProvider | URL 레벨 변경 감지 | 불필요 | name이 아닌 path만 제공, 추가 파싱 필요 |

**추천: 방법 A** — Provider에서 직접 연결, context 불필요, 즉시 콜백.

```dart
@Riverpod(keepAlive: true)
class ActiveRouteNotifier extends _$ActiveRouteNotifier {
  @override
  String build() => 'home';

  void listenTo(GoRouter router) {
    router.routerDelegate.addListener(() {
      final name = router.routerDelegate.state.name ?? 'home';
      if (state != name) state = name;
    });
  }
}
```

#### 변수 레지스트리: 2가지 패턴 비교

| 패턴 | 구조 | 장점 | 단점 |
|------|------|------|------|
| **A. 단일 글로벌 Registry** | `Map<String, List<TunableVar>>` in StateNotifier | 1줄 등록 API, 전역 오버레이에서 단순 접근 | 대규모 시 Map 크기 |
| B. Provider Family | `tunableVarsProvider(routeName)` | 타입 안전, 자동 dispose | 오버레이에서 현재 route를 알아야 호출 가능 |

**추천: 패턴 A** — 오버레이가 `ref.watch(tunerRegistryProvider)[currentRoute]`로 즉시 접근.

등록 API 설계:
```dart
// 화면에서 1줄로 등록
DevTuner.register(ref, 'home', [
  TunableVar.double('bgGradientRadius', 1.2, min: 0.5, max: 3.0, step: 0.1),
  TunableVar.int('buttonHeight', 56, min: 40, max: 72, step: 4),
]);
```

### Caveats & Risks
- `appRouterProvider`가 AutoDispose → Dev Tuner가 참조를 유지하거나 `keepAlive: true`로 전환 필요
- `GoRouterState.name`이 nullable — named route만 사용하는 현재 구조에서는 항상 non-null

### Summary
`routerDelegate.addListener` + 단일 글로벌 TunerRegistry가 최적 조합. 기존 코드와 자연스러운 연속성.

---

## Perspective 2: 오버레이 UI + 스텝퍼 컨트롤 패턴

### Status Analysis

현재 Spring Tuner: `MaterialApp.builder` → `Stack` → `Positioned.fill(SpringDebugPanel)` → 내부 `Stack` (FAB + 패널).
히트테스트 패스스루가 정상 동작 (Stack의 deferToChild 기본 동작).

### Detailed Findings

#### OverlayEntry vs MaterialApp.builder 비교

| 항목 | MaterialApp.builder | OverlayEntry |
|------|-------------------|--------------|
| Riverpod 접근 | ConsumerWidget 직접 사용 | OverlayEntry.builder에 ProviderScope 래핑 필요 |
| 히트테스트 | 자동 패스스루 | IgnorePointer 명시 필요 |
| 생명주기 | MaterialApp과 동일 | 수동 insert/remove 관리 |
| 적합 케이스 | **Dev Tuner (전역 영구)** | 토스트, 광고 배너 (임시) |

**결론: MaterialApp.builder 유지** — Riverpod 접근 용이, 히트테스트 자동, 생명주기 단순.

#### < N > 스텝퍼 컨트롤 설계

```dart
// 타입별 컨트롤 분기
Widget buildControl(TunableVar v) => switch (v) {
  TunableVar<double> _ => _StepperRow(v),    // < 0.5 >
  TunableVar<int> _    => _StepperRow(v),    // < 56 >
  TunableVar<bool> _   => _ToggleRow(v),     // [OFF] / [ON]
  TunableVar<Enum> _   => _CycleRow(v),      // < ThreeCard >
};
```

스텝퍼 행 구조: `[ < ] [ 현재값 ] [ > ]`
- 탭: 1 step 증감
- 길게 누르기: `Timer.periodic(80ms)`로 연속 증감
- `GestureDetector.onLongPressStart/End`로 구현

#### kDebugMode 가드

```dart
// main.dart builder에서
builder: (context, child) {
  if (!kDebugMode) return child!;  // 릴리즈: tree-shaking으로 완전 제거
  return Stack(children: [child!, const Positioned.fill(child: DevTunerOverlay())]);
},
```

`kDebugMode`는 `bool.fromEnvironment('dart.vm.product')`의 부정 → 컴파일 타임 상수 → AOT 컴파일러가 릴리즈에서 if 블록 완전 제거.

### Caveats & Risks
- 현재 `onPanUpdate` + `onTap` 공존 시 짧은 드래그가 탭으로 오인 가능 → 임계값 분리 권장
- `Timer.periodic` 연속 증감 시 dispose 누락 주의

### Summary
MaterialApp.builder 유지, 타입별 스텝퍼 UI, kDebugMode 가드로 릴리즈 안전. 구현 복잡도 낮음.

---

## Perspective 3: 기존 화면별 하드코딩 변수 탐색

### Status Analysis
11개 파일에서 67개 하드코딩 값 식별. 49개 튜닝 가능, 18개 불가.

### Detailed Findings

#### 화면별 튜닝 변수 요약

| 화면/컴포넌트 | 튜닝 가능 | 튜닝 불가 | 최우선 변수 |
|-------------|----------|----------|-----------|
| Home Page | 15 | 0 | bgGradientRadius, buttonHeight |
| Shuffle Page | 5 | 1 | cameraInitialRotateX (0.65 rad) |
| Tarot Game (Flame) | 4 | 3 | cardSpawnSpeedMin/Range |
| Card Body (forge2d) | 8+ | 1 | linearDamping(3.5), angularDamping(2.0) |
| Hand Animation | 3 | 1 | handScale, bounceAmplitude |
| Reading Page | 5 | 3 | 카드 표시 비율 (0.45) |
| Intention Page | 3 | 2 | 텍스트필드 borderRadius |
| Deck Selection | 2 | 1 | gridColumns |
| Spread Layout | 2 | 2 | card spacing |
| Card Reveal | 5 | 2 | flipDuration(400ms), 3D perspective |
| Entropy Progress | 1 | 1 | bar height |
| App Theme | 3 | 1 | fontSize, letterSpacing |
| Main (Spring) | 3 | 0 | mass, stiffness, damping (기존) |

#### 최우선 튜닝 변수 TOP 5

1. **cardLinearDamping** (card_body_component) — 3.5, range 0-10, step 0.5 → 카드 이동 감속
2. **cardAngularDamping** (card_body_component) — 2.0, range 0-8, step 0.5 → 카드 회전 감속
3. **cardSpawnSpeedMin** (tarot_game) — 2.0, range 0.5-5.0, step 0.5 → 카드 초기 속도
4. **cameraInitialRotateX** (shuffle_page) — 0.65 rad, range 0-1.57, step 0.05 → 3D 카메라 각도
5. **cardFlipDurationMs** (card_reveal_widget) — 400ms, range 100-1200, step 50 → 카드 뒤집기 속도

#### 발견: 카드 종횡비 불일치
- card_body_component: 0.3/0.45 = 2:3
- card_reveal_widget: 2.5/3.5 = 5:7
→ Dev Tuner에서 통일 조정 가능

### Caveats & Risks
- spacing 변수 30개+는 개별 등록보다 `spacingScale` 배율 1개로 일괄 제어 권장
- Flame 게임 내부 변수는 게임 루프 중 실시간 반영을 위해 별도 메커니즘 필요할 수 있음

### Summary
49개 변수 중 물리 엔진 파라미터(4개)가 체감 영향 최대. spacing은 그룹 배율로 효율화 가능.

---

## Cross-Analysis

### Inter-Perspective Relationships
- P1의 라우트 감지 → P3의 화면별 변수가 올바른 화면에 표시되도록 연결
- P2의 스텝퍼 UI → P3의 변수 타입/범위/step으로 구체적 컨트롤 생성
- P1의 레지스트리 API → P3의 49개 변수를 화면별로 등록하는 인터페이스

### Common Patterns
- 3개 관점 모두 현재 코드의 "확장"이 가장 자연스럽다고 판단 (새 아키텍처 도입 불필요)
- kDebugMode 가드 미사용 문제를 P1, P2가 독립적으로 발견

### Conflicting Items
없음. 3개 관점이 상호 보완적.

## Comprehensive Conclusion

### 핵심 발견 (우선순위 순)

1. **[Critical] R-007-F1: 라우트 감지 최적 방법** — `GoRouter.routerDelegate.addListener()`. ChangeNotifier 기반, context 불필요, 전역 오버레이에서 직접 사용. *(관점 1)*
2. **[Critical] R-007-F2: 변수 레지스트리 패턴** — 단일 글로벌 TunerRegistry StateNotifier. `Map<String, List<TunableVar>>` 구조, 1줄 등록 API. Provider family보다 오버레이 접근 단순. *(관점 1)*
3. **[High] R-007-F3: 오버레이 패턴 유지** — MaterialApp.builder 패턴이 최적. OverlayEntry는 Riverpod 접근 복잡 + 히트테스트 추가 설정 필요. *(관점 2)*
4. **[High] R-007-F4: kDebugMode 가드 필수** — 현재 Spring Tuner에 가드 없음. 릴리즈 빌드 노출 버그. `if (!kDebugMode) return child!`로 tree-shaking 완전 제거. *(관점 1, 2)*
5. **[High] R-007-F5: 튜닝 변수 49개 식별** — 11파일에서 67값 중 49개 튜닝 가능. 최우선: 카드 물리 4개 (linearDamping, angularDamping, restitution, friction). *(관점 3)*
6. **[Medium] R-007-F6: 타입별 스텝퍼 UI** — double/int → `< N >` 증감, bool → 토글, enum → 순환. 길게 누르기 연속 증감 (Timer.periodic 80ms). *(관점 2)*
7. **[Medium] R-007-F7: spacing 그룹 배율** — 30개+ spacing 변수를 `spacingScale` 배율 1개로 일괄 제어 가능. 개별 등록은 비효율. *(관점 3)*
8. **[Low] R-007-F8: 카드 종횡비 불일치** — card_body(2:3) vs card_reveal(5:7). Dev Tuner로 통일 조정 가능. *(관점 3)*

## Unresolved Items

1. **Flame 게임 내부 변수 실시간 반영**: forge2d 물리 파라미터 변경이 게임 루프 중 즉시 반영되는지 확인 필요. 게임 재시작이 필요할 수 있음 → makeplan에서 검토.

## Referenced File List

| File Path | Related Perspective | Role/Content |
|-----------|-------------------|--------------|
| mobile/lib/core/router/app_router.dart | 1 | GoRouter 5개 route 설정 |
| mobile/lib/core/router/app_router.g.dart | 1 | AutoDisposeProvider 확인 |
| mobile/lib/main.dart | 1, 2 | SpringDebugPanel, 스프링 StateProvider, builder |
| mobile/lib/core/theme/app_theme.dart | 2, 3 | 테마 변수 |
| mobile/lib/features/home/presentation/pages/home_page.dart | 3 | 15개 튜닝 변수 |
| mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart | 3 | 카메라 각도 등 5개 |
| mobile/lib/features/shuffle/presentation/game/tarot_game.dart | 3 | 카드 스폰 속도 |
| mobile/lib/features/shuffle/presentation/game/card_body_component.dart | 3 | 물리 파라미터 8개+ |
| mobile/lib/features/shuffle/presentation/game/hand_animation_component.dart | 3 | 손 애니메이션 3개 |
| mobile/lib/features/reading/presentation/pages/reading_page.dart | 3 | 리딩 레이아웃 5개 |
| mobile/lib/features/reading/presentation/widgets/card_reveal_widget.dart | 3 | 카드 뒤집기 5개 |
| mobile/lib/features/reading/presentation/widgets/spread_layout.dart | 3 | 스프레드 간격 2개 |
| mobile/lib/features/shuffle/presentation/pages/intention_page.dart | 3 | 의도 화면 3개 |
| mobile/lib/features/deck/presentation/pages/deck_selection_page.dart | 3 | 덱 선택 2개 |
| go_router-14.8.1 (delegate.dart, router.dart) | 1 | routerDelegate ChangeNotifier 확인 |

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
