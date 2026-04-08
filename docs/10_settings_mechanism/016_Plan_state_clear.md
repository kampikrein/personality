---
id: "016"
type: plan
title: "State clear() 주입 실행 계획 (Cycle 2)"
created: 2026-04-01
traces_scope: "014"
traces_research: "013"
traces_agent: "010"
status: completed
summary: >
  shuffleStateProvider.clear()와 readingQuestionProvider.clear()를
  4개 뽑기 진입점에 안전하게 삽입한다.
  R-013-F6 권고: Level 3에서 shuffleState는 ShufflePage, readingQuestion은 IntentionPage에 분리 삽입.
keywords: [state-clear, ShuffleState, ReadingQuestion, IntentionPage, ShufflePage, InstantDrawPage, AnimatedDrawPage]
---

# State clear() 주입 실행 계획

## 목표

이전 뽑기 결과가 새 뽑기 시작 시 잔류하는 버그를 수정한다.
`shuffleStateProvider`와 `readingQuestionProvider`가 keepAlive:true로 설정되어 있어
clear() 호출 없이는 이전 상태가 유지된다.

## 근거 문서

- Brief: `007_Brief_settings_fix.md` — MA-2: 뽑기 진입 시 글로벌 상태 clear
- Research: `013_Research_impact_final.md` — Perspective 2, R-013-F1, R-013-F6
- Agent Report: `010_Agent_clear_impact.md` — 시나리오별 안전도 분석

## 삽입 지점 (확정)

| 파일 | 함수 | 삽입 대상 | 안전도 | 근거 |
|------|------|----------|--------|------|
| `instant_draw_page.dart` | `_executeDraw()` 선두 | shuffle + question | 안전 | `_loading=true`, ReadingPage 스택 없음 |
| `animated_draw_page.dart` | `_startDraw()` 선두 | shuffle + question | 안전 | question은 이후 `_questionController` 기반 재세팅 |
| `intention_page.dart` | `initState` addPostFrameCallback | question만 | 안전 | shuffle clear 금지 (시나리오 3-A 위험) |
| `shuffle_page.dart` | `_goToReading()` 선두 | shuffle만 | 안전 | readingQuestion은 IntentionPage에서 이미 세팅 |

## Level 3 분리 삽입 원칙 (R-013-F6)

IntentionPage에서 `shuffleStateProvider.clear()` 삽입 금지.
이유: 스택 `[..., IntentionPage, ShufflePage, ReadingPage]` 상황에서
IntentionPage 재진입 시 ReadingPage가 null 재빌드 → "셔플을 먼저 진행해주세요" 노출.

- `readingQuestionProvider.clear()` → IntentionPage.initState (새 리딩 의도 초기화)
- `shuffleStateProvider.clear()` → ShufflePage._goToReading() 선두 (뽑기 직전)

## Import 체크

| 파일 | shuffle_providers.dart | intention_page.dart |
|------|----------------------|-------------------|
| `instant_draw_page.dart` | 이미 있음 (line 13) | 이미 있음 (line 15) |
| `animated_draw_page.dart` | 이미 있음 (line 14) | 이미 있음 (line 16) |
| `intention_page.dart` | 자체 파일에 ReadingQuestion 정의 | N/A |
| `shuffle_page.dart` | 이미 있음 (line 8) | 추가 불필요 (shuffleState만 clear) |

모든 필요 import 이미 존재. 추가 import 불필요.

## 변경 상세

### 1. instant_draw_page.dart — `_executeDraw()` 선두

```dart
Future<void> _executeDraw() async {
  // [추가] 이전 뽑기 상태 초기화
  ref.read(shuffleStateProvider.notifier).clear();
  ref.read(readingQuestionProvider.notifier).clear();

  // 덱 시드 보장 (홈을 건너뛴 경우)
  final repo = ref.read(deckRepositoryProvider);
  await repo.seedRwsDeck();
  ...
}
```

### 2. animated_draw_page.dart — `_startDraw()` 선두

```dart
Future<void> _startDraw() async {
  // [추가] 이전 뽑기 상태 초기화
  ref.read(shuffleStateProvider.notifier).clear();
  ref.read(readingQuestionProvider.notifier).clear();

  // 덱 시드 보장 (홈을 건너뛴 경우)
  final repo = ref.read(deckRepositoryProvider);
  await repo.seedRwsDeck();
  ...
}
```

### 3. intention_page.dart — initState 추가

```dart
@override
void initState() {
  super.initState();
  // 새 리딩 시작 시 이전 질문 초기화
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(readingQuestionProvider.notifier).clear();
  });
}
```

### 4. shuffle_page.dart — `_goToReading()` 선두

```dart
Future<void> _goToReading() async {
  // [추가] 이전 셔플 상태 초기화 (readingQuestion은 IntentionPage에서 초기화됨)
  ref.read(shuffleStateProvider.notifier).clear();

  ref.read(hapticServiceProvider).mediumImpact();
  ...
}
```

## 검증 계획

- `dart analyze` — 정적 분석 오류 없음 확인
- 수동 검증 시나리오:
  1. Level 1 즉시 뽑기 → 홈 → 다시 즉시 뽑기: 이전 결과 미표시
  2. Level 2 연출 뽑기 → 홈 → 다시 연출 뽑기: 이전 결과 미표시
  3. Level 3: IntentionPage → ShufflePage → 뽑기: 이전 셔플 결과 미잔류
  4. Level 3 뒤로가기: ReadingPage 재진입 시 "셔플 먼저" 화면 미표시

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
| 25 | user-ai-exchange | 29s | 234056 |
| 26 | user-ai-exchange | 3s | 48718 |
| 27 | user-ai-exchange | 13s | 54002 |
| 28 | user-ai-exchange | 9s | 55309 |
| 29 | user-ai-exchange | 10s | 58339 |
| 30 | user-ai-exchange | 11s | 61129 |
| 31 | user-ai-exchange | 7s | 62416 |
| 32 | user-ai-exchange | 0s | 0 |
| 33 | user-ai-exchange | 10s | 63892 |
| 34 | user-ai-exchange | 22s | 67713 |
| 35 | user-ai-exchange | 9s | 69028 |
| 36 | user-ai-exchange | 21s | 215578 |
| 37 | user-ai-exchange | 174s | 517468 |
| 38 | user-ai-exchange | 418s | 1153988 |
| 39 | user-ai-exchange | 80s | 692099 |
| 40 | user-ai-exchange | 56s | 453585 |
| 41 | user-ai-exchange | 134s | 1054142 |
| 42 | user-ai-exchange | 587s | 979519 |
| 43 | user-ai-exchange | 44s | 619876 |
| 44 | user-ai-exchange | 451s | 4893580 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 479586s |
| Total Tokens | 12945971 |
| Input Tokens | 197 |
| Output Tokens | 67463 |
| Cache Read | 12030837 |
| Cache Creation | 847474 |
