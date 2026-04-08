---
id: "006"
title: "Dev Tuner 아키텍처 연구 — Synthesis Report"
category: report
status: archived
created: 2026-03-18
summary: >
  3개 관점(라우트 감지+레지스트리, 오버레이 UI+스텝퍼, 화면별 변수) 병렬 조사 통합.
  서브에이전트 3명(flutter-expert), 핵심 결론: routerDelegate.addListener + 단일 글로벌 TunerRegistry
  + MaterialApp.builder 유지 + kDebugMode 가드 + 49개 튜닝 변수 식별.
keywords: [parallel-synthesis, research, dev-tuner, gorouter, riverpod, overlay]
modules: [mobile/lib/core, mobile/lib/features, mobile/lib/main.dart]
---

# Dev Tuner 아키텍처 연구 — Synthesis Report

## Team Composition & Individual Reports

| # | Role | Agent Type | Report | Status |
|---|------|-----------|--------|--------|
| 1 | GoRouter 라우트 감지 + 변수 레지스트리 | flutter-expert | [003_Agent_route_registry.md](./003_Agent_route_registry.md) | complete |
| 2 | 오버레이 UI + 스텝퍼 컨트롤 | flutter-expert | [004_Agent_overlay_ui.md](./004_Agent_overlay_ui.md) | complete |
| 3 | 화면별 하드코딩 변수 탐색 | flutter-expert | [005_Agent_screen_variables.md](./005_Agent_screen_variables.md) | complete |

---

## Cross-Analysis

### Common Findings

1. **kDebugMode 가드 미사용**: P1, P2 모두 현재 Spring Tuner에 kDebugMode 가드가 없어 릴리즈 빌드에서 노출되는 문제를 독립적으로 발견. Dev Tuner 전체를 `if (kDebugMode)` 블록으로 감싸야 함.
2. **현재 패턴 확장 적합성**: P1(router 분석)과 P2(overlay 분석) 모두 현재 `MaterialApp.builder` + `Positioned.fill` + `Stack` 패턴이 Dev Tuner에 그대로 확장 가능함을 확인.
3. **AutoDispose 주의**: P1에서 `appRouterProvider`가 AutoDispose인 점을 발견 → Dev Tuner가 router를 참조 유지해야 dispose 방지.

### Conflicting Opinions

없음. 3개 관점이 상호 보완적이며 결론이 일치함.

### Synergy Effects

1. **P1 + P3**: P1의 "화면별 변수 집합 = Map<String, List<TunableVar>>"와 P3의 "49개 변수 + 화면별 분류"가 결합 → 구체적인 레지스트리 초기 데이터 확보
2. **P2 + P3**: P2의 "타입별 스텝퍼 컨트롤(double/int/bool/enum)"과 P3의 "변수별 타입+범위+step" → 스텝퍼 UI가 바로 구현 가능한 수준의 스펙 완성
3. **P3 발견 → P1 설계 영향**: P3에서 "spacing 변수 30개+는 spacingScale 배율 1개로 일괄 제어" 제안 → 레지스트리에 "그룹 배율" 변수 타입 고려 가능

---

## Comprehensive Conclusion

### Key Findings

1. **[Critical] 라우트 감지**: `GoRouter.routerDelegate.addListener()` — context 불필요, 전역 오버레이에서 즉시 라우트 변경 감지. `GoRouterDelegate`가 `ChangeNotifier` mixin.
2. **[Critical] 변수 레지스트리**: 단일 글로벌 `TunerRegistry` Notifier (`Map<String, List<TunableVar>>`) 패턴 추천. Provider family보다 단순하고 1줄 등록 API 제공 가능.
3. **[High] 오버레이 패턴**: `MaterialApp.builder` 유지. OverlayEntry는 Riverpod 접근 복잡 + 히트테스트 추가 설정 필요.
4. **[High] kDebugMode 가드 필수**: 릴리즈 빌드에서 Dev Tuner 코드 tree-shaking 완전 제거. `assert()`는 위젯 빌드에 부적합.
5. **[High] 튜닝 변수 49개 식별**: 11개 파일에서 67개 하드코딩 값 중 49개 튜닝 가능. 최우선: 카드 물리 4개 값 (linearDamping, angularDamping, restitution, friction).
6. **[Medium] 스텝퍼 UI**: `< N >` 방식. double/int는 증감 스텝퍼, bool은 토글, enum은 순환. 길게 누르기 연속 증감 (Timer.periodic 80ms).

### Recommended Actions

1. **Cycle 1 (Tuner System)**: core/dev_tuner/ 모듈 생성 → TunableVar 모델 + TunerRegistry + ActiveRouteNotifier + TunerOverlay UI
2. **Cycle 2 (Screen Integration)**: 49개 변수를 화면별로 등록. 최우선: 카드 물리 + 셔플 애니메이션

---

## References

개별 보고서 참조 통합:
- go_router-14.8.1 소스: delegate.dart, router.dart, configuration.dart
- mobile/lib/core/router/app_router.dart, app_router.g.dart
- mobile/lib/main.dart (SpringDebugPanel)
- mobile/lib/features/**/pages/*.dart (5개 화면)
- mobile/lib/features/shuffle/presentation/game/*.dart (Flame 엔진)
- mobile/lib/features/reading/presentation/widgets/*.dart
- mobile/lib/core/theme/app_theme.dart

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
