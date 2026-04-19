---
id: "067"
type: tdd-red
title: "TDD Red: Cycle 1 리네임 & 라우트 원자 교체"
created: 2026-04-14
cycle: 1
traces_scope: "066"
traces_brief: "065"
status: completed
test_count: 3
framework: "flutter_test"
summary: >
  Brief 065 Cycle 1의 리네임·라우트 교체(InstantDrawPage → DrawResultPage,
  /draw/instant → /draw/result)를 유도하는 실패 테스트. Ideal Criteria #1·#2·#24에
  대응하며, 현재는 DrawResultPage·/draw/result가 존재하지 않아 컴파일/런타임 단계에서 Red 상태가 된다.
test_files:
  - mobile/test/features/draw/draw_result_page_test.dart
  - mobile/test/core/router/draw_result_route_test.dart
keywords: [tdd-red, rename, routing, draw-result, unified-result-page]
---

# TDD Red: Cycle 1 리네임 & 라우트 원자 교체

## Test Strategy

Cycle 1은 기계적 리네임(파일 이동 + 클래스명 + 라우트 path/name + 호출부)이 원자적으로 완결되는 것을 보장하는 사이클이다. 테스트가 유도할 두 축은:

1. **클래스 존재 및 초기화 가능성 (Ideal Criteria #23, MA-9)**
   - `DrawResultPage`가 새 경로 `draw_result_page.dart`에 존재하고 `ProviderScope` 하에서 예외 없이 초기화되어야 한다.
   - `shuffleStateProvider`를 `overrideWith`로 mock한 상태에서 smoke 가능해야 한다 → 테스트 격리성 보장.

2. **라우트 매핑 존재 (Ideal Criteria #1, #24, MA-0, MA-7)**
   - GoRouter 내에서 path `/draw/result`와 name `draw-result`가 존재해야 한다.
   - 기존 path `/draw/instant` / name `draw-instant` 는 더 이상 존재하지 않아야 한다.

두 축 모두 **현 코드베이스에서는 실패**한다:
- `DrawResultPage` 클래스 미존재 → import compile 실패
- `/draw/result` 라우트 미존재 → 라우트 lookup 실패

## Test Specifications

### T1: DrawResultPage smoke (클래스 존재 + ProviderScope 초기화)
- **동작**: `DrawResultPage` 위젯이 `ProviderScope`(`shuffleStateProvider` override 포함) 내에서 예외 없이 build 첫 프레임을 통과한다.
- **입력**:
  - `ProviderScope(overrides: [shuffleStateProvider.overrideWith(() => FakeShuffleState())])`
  - `MaterialApp(home: DrawResultPage())`로 pump.
- **기대 결과**: `pumpWidget` + `pump()` 한 번 호출 시 예외가 발생하지 않는다. `find.byType(DrawResultPage)`가 하나 발견된다.
- **Red 증거**: `DrawResultPage` 및 `draw_result_page.dart`가 존재하지 않으므로 **import 단계에서 컴파일 실패** → `flutter test`가 이 파일을 컴파일하지 못한다.
- **파일**: `mobile/test/features/draw/draw_result_page_test.dart`

### T2: `/draw/result` path 라우트가 존재
- **동작**: `appRouterProvider`로부터 얻은 `GoRouter`의 `configuration.routes`를 순회했을 때 path `/draw/result`를 가진 `GoRoute`가 존재한다.
- **입력**: `ProviderContainer()`에서 `appRouterProvider`를 read.
- **기대 결과**: 라우트 트리에 `/draw/result` path와 `draw-result` name이 둘 다 발견된다.
- **Red 증거**: 현재 `app_router.dart`는 `/draw/instant` / `draw-instant`만 정의. `/draw/result`는 찾을 수 없음 → assertion 실패.
- **파일**: `mobile/test/core/router/draw_result_route_test.dart`

### T3: 기존 `/draw/instant` path 라우트는 제거됨
- **동작**: `appRouterProvider`의 라우트 트리에 path `/draw/instant`가 **존재하지 않는다**.
- **입력**: T2와 동일 container.
- **기대 결과**: `/draw/instant` path를 가진 GoRoute가 0개.
- **Red 증거**: 현재는 `/draw/instant`가 여전히 존재하므로 실패.
- **파일**: `mobile/test/core/router/draw_result_route_test.dart` (T2와 같은 파일)

## Test Files

| # | File Path | Test Count | Status |
|---|-----------|-----------|--------|
| 1 | `mobile/test/features/draw/draw_result_page_test.dart` | 1 | Red (compile fail) |
| 2 | `mobile/test/core/router/draw_result_route_test.dart` | 2 | Red (assertion fail) |

## Red State Verification

실행 커맨드:
```bash
cd /Users/kampikrein/A/personality/mobile
flutter test test/features/draw/draw_result_page_test.dart test/core/router/draw_result_route_test.dart
```

### 실패 모드 기대치

- **T1**: 컴파일 실패 — `draw_result_page.dart` 및 `DrawResultPage` 심볼 미존재로 `flutter test`가 이 파일 전체를 빌드하지 못한다. 이는 Red state의 정상 형태(import가 설계 목표).
- **T2**: runtime assertion fail — GoRoute 트리 순회 결과 path `/draw/result` 0건.
- **T3**: runtime assertion fail — GoRoute 트리 순회 결과 path `/draw/instant`가 여전히 존재.

verify 단계는 이 두 파일을 재실행하여 Red → Green 전환 여부를 판정한다.

### 실측 결과 (2026-04-14)

커맨드:
```
cd mobile && flutter test test/features/draw/draw_result_page_test.dart \
                         test/core/router/draw_result_route_test.dart
```

결과: `+0 -3: Some tests failed.` (Red 확정)

| Test | 실패 양상 | 증거 |
|------|----------|------|
| T1 `DrawResultPage smoke` | **컴파일 실패** | `Error when reading 'lib/features/draw/presentation/pages/draw_result_page.dart': No such file or directory` + `Undefined name 'DrawResultPage'` |
| T2 `/draw/result exists` | assertion fail | `Expected: non-empty / Actual: WhereIterable<GoRoute>:[]` |
| T3 `/draw/instant removed` | assertion fail | `Actual: [GoRoute(name: "draw-instant", path: "/draw/instant")]` |

모두 "구현 부재"로 인한 실패이며, 테스트 버그로 인한 실패가 아님. Cycle 1 impl이 리네임을 수행하면 세 테스트 모두 Green 전환된다.

## Design Quality Notes

- **동작 기반**: 라우트 테스트는 `GoRouter.configuration.routes` 공개 API만 읽는다. 내부 구현(특정 private 필드) 의존 없음.
- **단일 책임**: T1은 초기화만, T2/T3는 라우트 트리 내 path 유무만 체크.
- **독립성**: 각 테스트가 자체 `ProviderContainer` / `WidgetTester`를 생성.
- **MA-9 (테스트 격리)**: T1에서 `shuffleStateProvider.overrideWith`로 외부 I/O(덱 seed, DB)를 차단.

## Trace

- Brief: `docs/03_tarot_shuffle/065_Brief_unified_result_page.md` (Ideal Criteria #1, #2, #23, #24)
- Scope: `docs/03_tarot_shuffle/066_Scope_unified_result_page.md` (Cycle 1)
- Model Anchors: MA-0, MA-7, MA-9

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 0s | 0 |
| 2 | user-ai-exchange | 56s | 309862 |
| 3 | user-ai-exchange | 250s | 953594 |
| 4 | user-ai-exchange | 45s | 0 |
| 5 | user-ai-exchange | 189s | 1107972 |
| 6 | user-ai-exchange | 454s | 420177 |
| 7 | user-ai-exchange | 219s | 1752315 |
| 8 | user-ai-exchange | 5410s | 8406509 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 8790s |
| Total Tokens | 12950429 |
| Input Tokens | 197 |
| Output Tokens | 102803 |
| Cache Read | 12570274 |
| Cache Creation | 277155 |
