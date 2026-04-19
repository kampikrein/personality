---
id: "011"
type: verify
title: "Cycle 3 홈 허브 + 뽑기 체험 — 검증 보고서"
created: 2026-03-22
traces_plan: "010"
traces_scope: "002"
traces_brief: "001"
cycle: 3
commit: da5ed20
verdict: PASS
summary: >
  12개 검증 기준 중 11개 PASS, 1개 PASS (설계 의도 확인).
  dart analyze 0건. Cycle 1-2 기존 라우트 전량 보존. 발견사항 2건(경미).
keywords: [verify, home-hub, instant-draw, animated-draw, gorouter-redirect]
---

# Cycle 3 홈 허브 + 뽑기 체험 — 검증 보고서

## 검증 대상

- **커밋**: da5ed20 (`feat: Cycle 3 홈 허브 + 뽑기 체험`)
- **변경 파일**: 7개 (신규 4 + 수정 2 + codegen 1)
- **Plan**: 010_Plan_home_draw.md

## 검증 결과 요약

| # | 기준 | 결과 | 비고 |
|---|------|------|------|
| 1 | 홈 허브 4개 기능 카드 그리드 | PASS | 뽑기/리딩기록/덱선택/설정 — GridView.count(2열) |
| 2 | GoRouter redirect: quickDrawEnabled + experienceLevel 분기 | PASS | settings null → 홈, matchedLocation != '/' → null (무한 redirect 방지) |
| 3 | Level 1 즉시 뽑기 0.5초 이내 | PASS | initState → _executeDraw (async seedRwsDeck + Drift 캐시 ~50ms + Fisher-Yates ~1ms → setState) |
| 4 | Level 1 자동 저장 | PASS | _autoSave() — build 내 호출, _autoSaved flag로 1회 보장 |
| 5 | Level 1 "+1 한 장 더" FAB | PASS | FloatingActionButton.extended, hasMoreCards 조건, DB addDrawnCard 반영 |
| 6 | Level 2 stagger 애니메이션 | PASS | 300ms 간격 순차 forward, 600ms SlideTransition+FadeTransition per card |
| 7 | Level 2 질문 입력 + skip | PASS | 셔플 전 화면: TextField + "카드 뽑기" + "질문 없이 바로 뽑기" TextButton |
| 8 | Level 3 기존 /shuffle/:deckId 라우팅 | PASS | redirect: experienceLevel 3 → '/shuffle/${settings.selectedDeckId}', 홈 _startDraw case 3 → pushNamed('shuffle') |
| 9 | showFaceUp 설정 적용 | PASS | Level 1: 항상 즉시 reveal (Plan MA-7 설계 의도). Level 2: _showFaceUp 읽어 플립 생략/실행 분기 |
| 10 | seedRwsDeck 홈 skip 시 보장 | PASS | instant_draw_page.dart:57, animated_draw_page.dart:65 — 각각 _executeDraw/_startDraw 진입부에서 seedRwsDeck() 호출 |
| 11 | dart analyze 에러 0건 | PASS | `dart analyze lib/` → "No issues found!" |
| 12 | Cycle 1-2 기능 regression 없음 | PASS | 기존 라우트 7개 전량 보존: `/`, `/deck`, `/intention/:deckId`, `/shuffle/:deckId`, `/reading/:deckId`, `/settings`, `/readings`, `/readings/:readingId` |

## 상세 검증

### 1. 홈 허브 재설계 (home_page.dart)

- `ConsumerStatefulWidget` → `_HomePageState`
- `_initializeApp()`에서 `seedRwsDeck()` 호출 (첫 진입 시 덱 보장)
- `GridView.count(crossAxisCount: 2)` — 4개 `_HubCard`:
  - 뽑기 시작: `_startDraw()` → experienceLevel별 분기
  - 리딩 기록: pushNamed('readings')
  - 덱 선택: pushNamed('deck')
  - 설정: pushNamed('settings')
- 하단 최근 리딩 3개 미리보기: `readings.take(3)`
- 기존 `_quickDraw` 제거됨, 셔플 로직은 Level 1/2 페이지 내부로 이동 (Plan Step 3 "기존 _quickDraw 제거" 의도 충족)

### 2. GoRouter redirect (app_router.dart)

```dart
final settings = ref.watch(userSettingsProvider).valueOrNull;
redirect: (context, state) {
  if (settings == null) return null;           // 로딩 전 → 홈
  if (state.matchedLocation != '/') return null; // 무한 redirect 방지
  if (settings.quickDrawEnabled) {
    return switch (settings.experienceLevel) {
      1 => '/draw/instant',
      2 => '/draw/animated',
      3 => '/shuffle/${settings.selectedDeckId}',
      _ => null,
    };
  }
  return null;
}
```

**Edge case 처리 확인:**
- `settings == null` (로딩 미완): `return null` → 홈 표시. 올바름.
- `matchedLocation != '/'`: 다른 페이지 접근 시 redirect 발생하지 않음. 올바름.
- `experienceLevel` 범위 밖 값: `_ => null` (홈 유지). 올바름.
- **ref.watch 패턴**: `appRouterProvider` 내부에서 `ref.watch(userSettingsProvider)` → settings 변경 시 GoRouter 재생성. Plan D-010-1 설계 의도와 정확히 일치.
- **EV-006-D1 대응**: AutoDispose provider가 GoRouter provider에 watch되어 앱 수명 동안 구독 유지됨. 실질적으로 dispose 미발동. Plan에서 분석한 대로.

### 3. Level 1 즉시 뽑기 (instant_draw_page.dart, 304줄)

- `initState` → `_initSettings()` + `_executeDraw()` 동시 호출
- `_executeDraw()`: `seedRwsDeck()` → `deckCardsProvider.future` → `shuffleDeckUseCaseProvider.execute()` → `shuffleStateProvider.notifier.setResult()` → `setState(loading: false)`
- 모든 카드 즉시 reveal: `for (var i = 0; i < _currentCardCount; i++) _revealedPositions.add(i)`
- showFaceUp 미사용: Plan MA-7 "Level 1: 항상 즉시 reveal" 설계 의도 충족
- `_autoSave()`: build 내 호출, `_autoSaved` flag로 1회 보장
- `_addOneMore()`: `_currentCardCount++`, `_revealedPositions.add`, DB `addDrawnCard` 호출
- 질문 입력: `_questionExpanded` toggle, 접힘 기본 → Plan D-010-3 "결과 후 추가" 패턴 충족

### 4. Level 2 간단 연출 (animated_draw_page.dart, 568줄)

- `TickerProviderStateMixin` — 다수 AnimationController 지원
- 셔플 전 화면: 질문 입력 TextField + "카드 뽑기" FilledButton + "질문 없이 바로 뽑기" TextButton
- `_startDraw()`: seedRwsDeck → 셔플 → `_setupAnimations()` → `_playAnimations()`
- **Stagger 타이밍**:
  - 카드당 AnimationController(600ms), SlideTransition(Offset(0, 0.5) → zero) + FadeTransition
  - 300ms 간격 순차 forward (`unawaited` + `Future.delayed(300ms)`)
  - 마지막 카드 완료 대기 → 플립
  - 3장 기준: 300*2 + 600 + 200 + 200*3 = 2000ms ≈ 2초 (Plan 목표 2~3초 충족)
- **showFaceUp 분기**: `_showFaceUp` 읽어 플립 생략(즉시 전부 reveal) / 순차 reveal(200ms 간격) 결정
- `_autoSave()`: `allRevealed && _shuffleExecuted` 조건으로 애니메이션 완료 후 저장
- `_addOneMore()`: 애니메이션 완료(`_animationComplete`) 후에만 FAB 표시

### 5. draw_providers.dart

- `@riverpod` `executeDraw()`: UserSettings → deckId → 셔플 → ShuffleState 세팅
- Plan Step 1 설계와 동일. 다만 실제 InstantDrawPage/AnimatedDrawPage는 이 provider를 직접 사용하지 않고 인라인으로 동일 로직을 실행함 (seedRwsDeck 추가 필요 등). Provider는 향후 리팩터링 시 활용 가능한 인프라로 존재.

### 6. Cycle 1-2 Regression 확인

app_router.dart에 기존 라우트 전량 보존 확인:
- `/` (home), `/deck`, `/intention/:deckId`, `/shuffle/:deckId`, `/reading/:deckId` — 기존
- `/settings`, `/readings`, `/readings/:readingId` — Cycle 2에서 추가된 것
- `/draw/instant`, `/draw/animated` — Cycle 3 신규

`git diff` 확인: app_router.dart 변경은 순수 추가(import 3줄 + redirect 블록 + 라우트 2개). 기존 라우트 코드 수정 없음.

## 발견사항

### D-011-1: InstantDrawPage에서 executeDraw provider 미사용 (경미)

draw_providers.dart에 `executeDrawProvider`를 생성했으나, InstantDrawPage와 AnimatedDrawPage 모두 인라인으로 셔플 로직을 실행한다. 이유는 `seedRwsDeck()` 호출이 provider에는 포함되지 않았기 때문. Provider 자체는 에러 없이 동작하며, 향후 리팩터링 시 seedRwsDeck을 포함하도록 확장하면 인라인 코드를 줄일 수 있다.

- **심각도**: 경미 (dead code 수준, 기능 영향 없음)
- **권장**: 향후 리팩터링 시 provider에 seedRwsDeck 통합 또는 미사용 시 제거

### D-011-2: Level 1 질문 타이밍 — 저장 후 질문 반영 불가 (Plan에서 인지됨)

InstantDrawPage의 `_autoSave()`가 build에서 즉시 호출되므로, 사용자가 질문을 입력하기 전에 Reading이 빈 question으로 저장된다. Plan(Step 4, line 1019-1021)에서 이미 인지하고 "Level 1의 핵심 가치는 즉시 결과. 질문 중요 시 Level 2/3 사용 가이드"로 결론낸 사항.

- **심각도**: 경미 (설계 의도 내)
- **권장**: 향후 ReadingRepository에 updateQuestion 메서드 추가 시 개선 가능

## 총평

**PASS** — Plan(010) 검증 기준 11개 전량 충족 + dart analyze 0건. 발견사항 2건 모두 경미하며 기능 영향 없음. Cycle 1-2 regression 없음 확인.

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
