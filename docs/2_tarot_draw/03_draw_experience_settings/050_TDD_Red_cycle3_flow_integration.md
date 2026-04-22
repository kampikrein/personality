---
id: "050"
type: tdd-red
cycle: 3
topic: intent_placement_setting
status: completed
date: 2026-04-21
summary: "Cycle 3 TDD-Red — flow integration tests (T1~T8c), 5 RED / 5 GREEN"
---

# TDD Red — Cycle 3: Flow Integration (intent_placement_setting)

## 테스트 현황 (최종)

| ID  | 파일 | 테스트 설명 | 상태 | Red 이유 |
|-----|------|------------|------|----------|
| T1  | reading_repository_update_question_test.dart | updateQuestion persists updated text | GREEN (fake) | 프로덕션 인터페이스에 `updateQuestion` 미존재 → @override 경고 |
| T2  | reading_repository_update_question_test.dart | updateQuestion(null) clears question | GREEN (fake) | 동상 |
| T3  | intent_placement_routing_test.dart | Lv4 + beforeShuffle → /intention/:deckId | GREEN | 기존 동작과 일치 |
| T4  | intent_placement_routing_test.dart | Lv4 + afterDraw → /shuffle/:deckId | **RED** | `_startDraw`이 intentPlacement 미확인, 항상 /intention 진입 |
| T5  | intent_placement_routing_test.dart | Lv4 + disabled → /shuffle/:deckId | **RED** | 동상 |
| T6  | intention_page_redirect_test.dart | afterDraw → IntentionPage가 /shuffle로 redirect | **RED** | IntentionPage.initState에 redirect 로직 미존재 |
| T7  | intention_page_redirect_test.dart | beforeShuffle → IntentionPage가 정상 렌더 | GREEN | "셔플로 이동" 버튼 이미 존재 |
| T8a | draw_result_question_box_test.dart | afterDraw → 질문 토글 표시 | GREEN | 토글이 항상 표시됨 |
| T8b | draw_result_question_box_test.dart | beforeShuffle → 질문 토글 숨김 | **RED** | DrawResultPage가 intentPlacement 미확인, 항상 토글 표시 |
| T8c | draw_result_question_box_test.dart | disabled → 질문 토글 숨김 | **RED** | 동상 |

**결과: 5 RED / 5 GREEN** — 모든 실패가 "프로덕션 코드 미구현"을 이유로 실패 (scaffolding 문제 없음).

## 테스트 파일 (최종 경로)

```
mobile/test/features/reading/reading_repository_update_question_test.dart
mobile/test/features/home/intent_placement_routing_test.dart
mobile/test/features/shuffle/intention_page_redirect_test.dart
mobile/test/features/draw/draw_result_question_box_test.dart
```

## Red 검증 출력 (last 30 lines)

```
00:00 +3 -1: intention_page_redirect_test.dart: T6 ... [E]
  Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "ShufflePage">
  afterDraw: IntentionPage must redirect to /shuffle/:deckId

00:00 +5 -3: draw_result_question_box_test.dart: T8b ... [E]
  Expected: no matching candidates
  Actual: Found 1 widget with text containing 질문이 있으신가요?
  beforeShuffle: question was entered before shuffle → the toggle box must NOT render

00:00 +5 -3: intent_placement_routing_test.dart: T4 ... [E]
  Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "ShufflePage">
  afterDraw + Lv4: must skip IntentionPage

00:00 +5 -4: draw_result_question_box_test.dart: T8c ... [E]
  Expected: no matching candidates
  Actual: Found 1 widget with text containing 질문이 있으신가요?
  disabled: intent input is off → toggle must NOT render

00:01 +5 -5: intent_placement_routing_test.dart: T5 ... [E]
  Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "ShufflePage">
  disabled + Lv4: must skip IntentionPage

00:01 +5 -5: Some tests failed.
```

## 프로덕션에서 구현해야 할 헬퍼 / 메서드

### 1. `ReadingRepository.updateQuestion` (인터페이스)

```dart
// lib/features/reading/domain/repositories/reading_repository.dart
Future<void> updateQuestion(String readingId, String? question);
```

- `ReadingRepositoryImpl`에도 추가 (mirror of `updateNotes`)
- T1/T2는 fake로 GREEN이지만 인터페이스에 없으면 `dart analyze` warning 발생

### 2. `_startDraw` — intentPlacement 분기 (HomePage)

```dart
// lib/features/home/presentation/pages/home_page.dart
// cases 3 & 4: 경험 레벨 Lv4+ 진입점
if (settings.intentPlacement == IntentPlacement.beforeShuffle) {
  context.pushNamed('intention', pathParameters: {'deckId': deckId});
} else {
  context.pushNamed('shuffle', pathParameters: {'deckId': deckId});
}
```

- T4(afterDraw), T5(disabled) 둘 다 /shuffle로 직행해야 RED → GREEN

### 3. `IntentionPage` — intentPlacement redirect

```dart
// lib/features/shuffle/presentation/pages/intention_page.dart
// initState의 addPostFrameCallback 내부에 추가
final settings = ref.read(userSettingsProvider).valueOrNull;
if (settings != null && settings.intentPlacement != IntentPlacement.beforeShuffle) {
  context.pushReplacementNamed('shuffle',
      pathParameters: {'deckId': widget.deckId},
      extra: {'cardCount': settings.defaultCardCount});
}
```

- redirect 중 렌더는 `SizedBox.shrink()` 반환
- T6(afterDraw redirect) RED → GREEN 목표

### 4. `DrawResultPage` — intentPlacement 조건부 질문 토글

```dart
// lib/features/draw/presentation/pages/draw_result_page.dart
// build() 내부에서 userSettingsProvider watch
final intentPlacement = ref.watch(userSettingsProvider).valueOrNull?.intentPlacement;
// 질문 토글 섹션:
if (intentPlacement == IntentPlacement.afterDraw) ...[
  // GestureDetector + 질문 입력 UI
]
```

- T8b(beforeShuffle 숨김), T8c(disabled 숨김) RED → GREEN 목표

## 드롭된 테스트

없음 — 모든 4개 파일이 컴파일 성공, 올바른 이유로 RED.

T1/T2는 fake 내부에서 GREEN이지만 인터페이스 부재로 `@override` warning이 발생 — 이것이 Cycle 3 구현의 첫 번째 타깃. 인터페이스에 추가 후 `ReadingRepositoryImpl`에도 실제 Drift 쿼리 구현이 필요함.
