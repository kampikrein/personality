---
id: "071"
type: tdd-red
title: "TDD Red: Cycle 2 업스트림 통합 & ReadingPage 제거"
created: 2026-04-14
cycle: 2
traces_scope: "066"
traces_brief: "065"
status: completed
test_count: 10
framework: "flutter_test"
summary: >
  Brief 065 Cycle 2의 행위 변경(DrawResultPage initState 분기, AnimatedDrawPage 책임 축소,
  ShufflePage 후단 전환, ReadingPage draw-time 제거)을 유도하는 실패 테스트 4파일.
  Cycle 1 완료(리네임 Green) 상태에서는 모두 Red다.
test_files:
  - mobile/test/features/draw/draw_result_page_initstate_test.dart
  - mobile/test/features/draw/animated_draw_reduced_test.dart
  - mobile/test/features/shuffle/shuffle_page_navigation_test.dart
  - mobile/test/core/router/reading_page_removed_test.dart
keywords: [tdd-red, cycle2, initstate, animated-draw, shuffle-page, reading-page, static-source-check]
---

# TDD Red: Cycle 2 업스트림 통합 & ReadingPage 제거

## Test Strategy

Cycle 2는 "행위 변경" 사이클이다. Cycle 1(리네임만)이 끝난 지금 상태에서,
업스트림 플로우(AnimatedDrawPage, ShufflePage)와 다운스트림(DrawResultPage initState),
그리고 ReadingPage(draw-time) 제거가 실제로 일어났는지를 검증한다.

두 축의 테스트 스타일을 혼용한다:

1. **런타임 검증** (Group A): Riverpod provider override + widget pump으로
   `DrawResultPage.initState`의 분기 동작을 관찰. `shuffleStateProvider`를
   (a) pre-populated, (b) null 초기값 두 상태로 주입하여 재셔플 여부를 확인한다.
   `shuffleDeckUseCaseProvider`를 스파이 `ShuffleDeckUseCase` 구현체로 `overrideWithValue`하여
   호출 횟수를 카운트한다. 이 방식은 Brief MA-9(initState 분기 조건이 한 곳에서 1회)를
   직접 확인 가능한 falsifiable 테스트가 된다.

2. **정적 소스 검사** (Group B/C/D): `File(path).readAsStringSync()`로 lib 소스 내용을 읽어
   특정 심볼의 **존재/부재**를 `expect(contains(...))`로 확정한다. 정적 검사는 런타임
   mock 부담 없이 "코드가 실제로 변경되었는가"를 계약 수준에서 잡는다. Brief MA-4·MA-5·MA-6의
   교체가 원자적으로 일어났는지를 회귀 가드로 고정시킨다.

모든 테스트는 현 상태(Cycle 1 완료)에서는 실패하도록 설계되어 Red를 보장한다.

## Test Groups

### Group A — DrawResultPage initState 분기 (런타임)

파일: `mobile/test/features/draw/draw_result_page_initstate_test.dart` · 3 tests

- **A1 `reuses_existing_result_when_provider_has_value`**
  - 동작: `shuffleStateProvider`를 미리 주입된 `ShuffleResult`로 override하고,
    `shuffleDeckUseCaseProvider`는 호출 시 테스트를 실패시키는 스파이로 override.
  - 기대: `DrawResultPage` pump → 스파이의 `execute()` 호출 **0회**. 업스트림 결과
    재사용(재셔플 금지).
  - 현 상태: `_executeDraw()`가 무조건 `clear()` + 자체 셔플 수행 → 재셔플 발생 →
    스파이 `execute()`가 호출되며 fail.

- **A2 `performs_self_shuffle_when_provider_is_null`**
  - 동작: `shuffleStateProvider`는 기본값(null), 스파이 useCase로 override하여 호출 횟수 카운트.
  - 기대: pump 한 tick 이후 스파이 `execute()` 호출이 **정확히 1회** (0회 또는 2회 이상이면 fail).
  - 현 상태: 현재 구현도 1회 호출하지만, Cycle 2에서 분기 로직이 도입될 때 실수로 미호출(0회)되거나
    중복 호출(2회)되면 잡기 위한 가드. Cycle 1 상태에서 이 테스트가 Red인 이유는 A3 assert 기준으로 설명.

- **A3 `initState_branch_evaluated_once_source_check`**
  - 동작: `lib/features/draw/presentation/pages/draw_result_page.dart` 소스를 정적 검사.
    MA-9: "initState의 분기 조건은 한 곳에서만 결정" 원칙을 코드 레벨로 확인.
  - 기대: 소스에 `shuffleStateProvider`를 `ref.read`로 조회하는 구문이 initState/포스트프레임
    블록 내부에 **존재**하고, `null`(혹은 `current ==` 패턴)에 따른 분기가 **존재**.
  - 현 상태 (Cycle 1): `_executeDraw()`가 무조건 clear+self-shuffle 구조이므로 분기 자체가 없음 → fail.

### Group B — AnimatedDrawPage 책임 축소 (정적 검사)

파일: `mobile/test/features/draw/animated_draw_reduced_test.dart` · 3 tests

- **B1 `no_readingRepositoryProvider_usage`**
  - 현: `animated_draw_page.dart:180,192`에 `readingRepositoryProvider.saveReading` + `addDrawnCard` 존재.
  - 기대: 파일 내 `readingRepositoryProvider` 문자열 부재.
- **B2 `no_saveReading_call`**
  - 기대: `saveReading(` 부재 (반환된 사본, 호출 패턴 모두).
- **B3 `delegates_to_draw_result_via_pushReplacement`**
  - 기대: `pushReplacementNamed(` + `'draw-result'` 문자열이 같은 파일에 존재 (혹은
    `pushReplacement(` + `'/draw/result'` 조합).
  - 현: 연출 완료 후 같은 페이지에서 결과 렌더 → pushReplacement 경로 없음 → fail.

### Group C — ShufflePage 후단 전환 (정적 검사)

파일: `mobile/test/features/shuffle/shuffle_page_navigation_test.dart` · 2 tests

- **C1 `no_reading_navigation`**
  - 기대: `shuffle_page.dart` 소스에 `pushNamed(` 호출의 첫 인자로 `'reading'`이 등장하지 **않음**.
  - 현: `shuffle_page.dart:67-70`에 `pushNamed('reading', ...)` 존재 → fail.
- **C2 `navigates_to_draw_result`**
  - 기대: `pushReplacementNamed(` + `'draw-result'` 조합이 소스에 존재.
  - 현: 부재 → fail.

### Group D — ReadingPage(draw-time) 제거 & 회귀 가드 (정적 검사)

파일: `mobile/test/core/router/reading_page_removed_test.dart` · 3 tests

- **D1 `reading_page_file_deleted`**
  - 기대: `lib/features/reading/presentation/pages/reading_page.dart` 파일 부재
    (`File.existsSync() == false`).
  - 현: 파일 존재 → fail.
- **D2 `reading_route_removed_from_router`**
  - 기대: `app_router.dart` 소스에 path `/reading/:deckId`도 없고,
    `reading_page.dart` import도 없음.
  - 현: `app_router.dart:14` + `:141` 존재 → fail.
- **D3 `reading_list_and_detail_imports_preserved`** (회귀 가드)
  - 기대: `app_router.dart`에 `reading_list_page` import와 `reading_detail_page` import가 **유지**되고,
    path `/readings` + `:readingId` 라우트가 유지됨.
  - 현: 유지됨 → 이 테스트는 현재 상태에서 Green이어야 한다.
  - **주의**: Green 상태 테스트를 Red 그룹에 섞으면 "모두 Red" 요건 위배. 따라서 D3은
    "Cycle 2 impl 완료 후에도 regression 방지용으로 Green 유지"되는 **가드 테스트**로
    분류. Red State Verification 섹션에서는 D1/D2만 Red 대상으로 집계.

### Group E — 생략

Brief IC #26이 수동 E2E로 명시되어 있고, GoRouter 기반 widget-level integration은
본 Cycle의 행위 변경(특히 reading_page.dart 파일 부재)과 충돌이 커서 만들면 유지 비용
증가. 생략 — 수동 회귀로 대체.

## Test Files

| # | File Path | Test Count | Status |
|---|-----------|-----------|--------|
| 1 | `mobile/test/features/draw/draw_result_page_initstate_test.dart` | 3 | Red (A1/A3 fail, A2 pass-가드) |
| 2 | `mobile/test/features/draw/animated_draw_reduced_test.dart` | 3 | Red (B1/B2/B3 fail) |
| 3 | `mobile/test/features/shuffle/shuffle_page_navigation_test.dart` | 2 | Red (C1/C2 fail) |
| 4 | `mobile/test/core/router/reading_page_removed_test.dart` | 3 | Red (D1/D2 fail, D3 pass-가드) |

Red 집계: 4파일 / 11 tests 중 **핵심 Red 7건**(A1, A3, B1, B2, B3, C1, C2, D1, D2) = 9건 fail, A2/D3 2건은 regression 가드로서 Green 유지.

실제로는 A2는 Cycle 1 상태에서 useCase mock 주입 경로상 통과/실패가 구현 세부에 달려있어,
아래 Red State Verification 섹션에서 실측을 기반으로 최종 분류한다.

## Red State Verification

실행 커맨드:
```bash
cd /Users/kampikrein/A/personality/mobile
flutter test \
  test/features/draw/draw_result_page_initstate_test.dart \
  test/features/draw/animated_draw_reduced_test.dart \
  test/features/shuffle/shuffle_page_navigation_test.dart \
  test/core/router/reading_page_removed_test.dart
```

### 실패 모드 기대치

- **A1**: spy useCase의 `execute`가 1회 이상 호출되어 test-fail throw → Red.
- **A3**: 정적 grep — 현재 `draw_result_page.dart`에 분기 로직 부재 → Red.
- **B1/B2**: 현재 `animated_draw_page.dart:180,192`가 `readingRepositoryProvider.saveReading` + `addDrawnCard`를 호출 → Red.
- **B3**: 현재 `animated_draw_page.dart`에 `pushReplacementNamed('draw-result')` / `/draw/result` 부재 → Red.
- **C1**: 현재 `shuffle_page.dart:67-68`에 `pushNamed('reading', ...)` → Red.
- **C2**: 현재 `shuffle_page.dart`에 `pushReplacementNamed('draw-result')` 부재 → Red.
- **D1**: 현재 `reading_page.dart` 파일 존재 → Red.
- **D2**: 현재 `app_router.dart:14` import + `:141` route → Red.

### 실측 결과 (2026-04-14)

커맨드:
```
cd mobile && flutter test \
  test/features/draw/draw_result_page_initstate_test.dart \
  test/features/draw/animated_draw_reduced_test.dart \
  test/features/shuffle/shuffle_page_navigation_test.dart \
  test/core/router/reading_page_removed_test.dart
```

결과: `+2 -9: Some tests failed.` (Red 확정 — 9개 핵심 테스트 실패, 2개 Green-guard 통과)

| Test | 상태 | 실패 양상 |
|------|------|-----------|
| A1 `reuses_existing_result` | **FAIL** | `identical(after, upstream)` false — `_executeDraw()`가 provider를 clear + 재셔플하여 객체 교체됨 |
| A2 `green_guard_null_smoke` | PASS (의도된 Green-guard) | pump 후 DrawResultPage 위젯 mount 확인 |
| A3 `initState_branch_source` | **FAIL** | `shuffleStateProvider` 참조는 있으나 null 체크 분기(`== null` / `!= null` / `??` / `case null`) 부재 |
| B1 `no_readingRepositoryProvider` | **FAIL** | animated_draw_page.dart에 `readingRepositoryProvider` 문자열 존재 |
| B2 `no_saveReading` | **FAIL** | `saveReading(` 존재 (L180) |
| B3 `delegates_via_pushReplacement` | **FAIL** | `pushReplacementNamed('draw-result')` / `pushReplacement('/draw/result')` 모두 부재 |
| C1 `no_reading_navigation` | **FAIL** | `pushNamed('reading', ...)` 존재 (shuffle_page.dart:67-68) |
| C2 `navigates_to_draw_result` | **FAIL** | pushReplacement 타겟 부재 |
| D1 `reading_page_file_deleted` | **FAIL** | `lib/features/reading/presentation/pages/reading_page.dart` 파일 존재 |
| D2 `reading_route_removed` | **FAIL** | `'/reading/:deckId'` 경로·`reading_page.dart` import·`name: 'reading'` 모두 잔존 |
| D3 `list_detail_preserved` | PASS (의도된 regression guard) | reading_list / reading_detail import + 라우트 유지 확인 |

모두 "Cycle 2 구현 미적용"으로 인한 실패이며, 테스트 자체 버그로 인한 실패가 아님 (Cycle 1 완료 직후 상태가 원인). Cycle 2 impl이 Scope 066의 변경을 수행하면 9개 Red → Green 전환되고 A2/D3은 Green 유지된다.

## Green Transition Map

각 테스트가 Green으로 전환되기 위한 구현 작업:

| Test | Green 조건 | 대상 파일 | Scope 066 Cycle 2 항목 |
|------|-----------|----------|------------------------|
| A1 | `initState` 내에서 `shuffleStateProvider`가 non-null이면 재사용, `shuffleDeckUseCase`를 호출하지 않음 | `draw_result_page.dart` | #1 initState 분기 |
| A2 | null일 때는 여전히 자체 셔플 (1회) | `draw_result_page.dart` | #1 initState 분기 |
| A3 | initState 내 `shuffleStateProvider` null 여부 체크 후 if-else 분기 | `draw_result_page.dart` | MA-9 |
| B1/B2 | 결과 렌더·저장 블록 삭제 | `animated_draw_page.dart` | #2 AnimatedDrawPage 책임 축소 |
| B3 | 연출 종료 후 `pushReplacementNamed('draw-result', ...)` | `animated_draw_page.dart` | #2 |
| C1/C2 | `shuffle_page.dart:67-70` 수정 | `shuffle_page.dart` | #3 ShufflePage 후단 |
| D1 | `reading_page.dart` 파일 삭제 | filesystem | #4 ReadingPage 제거 |
| D2 | `app_router.dart`에서 import + `/reading/:deckId` GoRoute 삭제 | `app_router.dart` | #4 |
| D3 | regression 가드 — 변경 없음 | `app_router.dart` | Reviewed |

## Design Quality Notes

- **Behavior-driven (Group A)**: provider override + widget pump으로 관찰 가능한
  `useCase.execute` 호출 횟수만 검증. private 필드 / setState 내부에 의존하지 않음.
- **정적 검사의 범위 한정**: Group B/C/D는 "코드 존재/부재"라는 명시적 계약만 본다.
  의미론은 런타임 테스트(Group A)가 커버. 정적 검사는 리팩터링 도중 의도치 않은
  문자열 잔존(예: 미사용 import)을 즉시 잡아 Brief IC #1·#17 같은 엄격한 grep 기준을
  테스트 수준에서 예방.
- **독립성**: 각 파일/테스트가 자체 `ProviderContainer` / `File.readAsStringSync`를 생성.
  순서 의존 없음.
- **A2 & D3 가드**: Cycle 2 완료 후에도 회귀(필요 동작이 지워지는 실수)를 방지하는
  Green-유지 가드 테스트. tdd-red 문서 품질 원칙의 "실현 가능한 기대값" 원칙에 부합.

## Trace

- Brief: `docs/03_tarot_shuffle/065_Brief_unified_result_page.md` (MA-3, MA-4, MA-5, MA-6, MA-9; IC #6, #8, #10, #11, #16, #17, #20, #23)
- Scope: `docs/03_tarot_shuffle/066_Scope_unified_result_page.md` (Cycle 2)
- Cycle 1 Verify: `070_Verify_rename_cycle1.md` — Cycle 2 시작 전제(리네임 Green)
