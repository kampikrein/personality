---
id: "053"
type: verify
cycle: 3
topic: intent_placement_setting
status: completed
verdict: pass
date: 2026-04-21
---

# 053 — Cycle 3 Verify: Flow Integration

## 검증 대상

Impl commit: `42e5339`  
Plan: `051_Plan_cycle3_flow_integration.md`

---

## Check 1: Plan Adherence — 파일별 구현 확인

| # | 항목 | 확인 | 결과 |
|---|------|------|------|
| 1 | `reading_repository.dart`에 `updateQuestion` 추상 메서드 | line 10: `Future<void> updateQuestion(String readingId, String? question);` | PASS |
| 2 | `reading_repository_impl.dart` `updateQuestion` 구현 | line 63-65: `@override` + `db.readingDao.updateQuestion` 위임 | PASS |
| 3 | `reading_dao.dart` `updateQuestion` Drift 쿼리 | line 54-62: `update(readings)` + `ReadingsCompanion(question: Value(question), updatedAt: Value(DateTime.now()))` | PASS |
| 4 | `home_page.dart` `_startDraw` Lv3/4 분기 | line 77-115: `ref.read(userSettingsProvider).valueOrNull?.intentPlacement` 읽어 case 3/4에서 `beforeShuffle`이면 `/intention`, 그 외 `/shuffle` | PASS |
| 5 | `deck_selection_page.dart` `onTap` 분기 | line 46-60: 동일 패턴으로 `intentPlacement` 읽어 분기 | PASS |
| 6 | `intention_page.dart` AsyncLoading 처리 + redirect | `_redirectChecked` 플래그로 `build()`에서 `settingsAsync.whenData`를 1회 평가, postFrameCallback으로 `_maybeRedirect` 호출. `isLoading && valueOrNull==null` 시 `SizedBox.shrink` 반환 | PASS |
| 7 | `draw_result_page.dart` `afterDraw`만 질문 토글 렌더 | line 183: `if (intentPlacement == IntentPlacement.afterDraw) ...[...]` | PASS |
| 8 | `draw_result_page.dart` `_updateQuestion` → `readingRepository.updateQuestion` | line 133-139: `_savedReadingId!`와 `text.isEmpty ? null : text`를 `updateQuestion` 호출 | PASS |

**Check 1: PASS (8/8)**

---

## Check 2: Cycle 3 테스트 GREEN

```
flutter test test/features/reading/reading_repository_update_question_test.dart \
  test/features/home/intent_placement_routing_test.dart \
  test/features/shuffle/intention_page_redirect_test.dart \
  test/features/draw/draw_result_question_box_test.dart
```

결과: **10/10 passed, 0 failed**

| 테스트 | 결과 |
|--------|------|
| T1 — updateQuestion persists text | PASS |
| T2 — updateQuestion with null clears | PASS |
| T3 — Lv4 + beforeShuffle → /intention/:deckId | PASS |
| T4 — Lv4 + afterDraw → /shuffle/:deckId | PASS |
| T5 — Lv4 + disabled → /shuffle/:deckId | PASS |
| T6 — IntentionPage afterDraw → redirect to ShufflePage | PASS |
| T7 — IntentionPage beforeShuffle → renders body | PASS |
| T8a — DrawResultPage afterDraw renders question box | PASS |
| T8b — DrawResultPage beforeShuffle hides question box | PASS |
| T8c — DrawResultPage disabled hides question box | PASS |

**Check 2: PASS**

---

## Check 3: 전체 테스트 — 신규 회귀 없음

```
flutter test → +79 -6: Some tests failed.
```

실패 목록 (pre-existing 동일):
- `migration_v7_to_v8_test` T1-T4 (Cycle 3 범위 외)
- `draw_settings_panel_test` T2, T4 (pre-existing)
- `spread_layout_test` T1 (pre-existing)

Cycle 3 신규 실패: **0건**

**Check 3: PASS**

---

## Check 4: Brief Ideal Criteria #5~#9

| # | 기준 | 확인 방법 | 결과 |
|---|------|----------|------|
| #5 | afterDraw/disabled → /shuffle 직행, IntentionPage 스킵 | T4(afterDraw), T5(disabled) GREEN + `home_page.dart` case 3/4 `else` 분기 `/shuffle` 직행 | PASS |
| #6 | 직접 /intention URL 접근 시 != beforeShuffle → redirect | T6(afterDraw→redirect) GREEN + `intention_page.dart` `_maybeRedirect` 구현 | PASS |
| #7 | afterDraw 모드에서 입력이 reading.question 갱신 | T8a GREEN + `_updateQuestion`이 `readingRepositoryProvider.updateQuestion(_savedReadingId!, text)` 호출 | PASS |
| #8 | disabled → 입력 박스 없음, reading.question=null | T8c GREEN (질문 토글 미렌더). `_autoSave` 시 `_questionController.text == ''` → `question=null` 저장. disabled 모드에서 `updateQuestion` 호출 경로 없음 | PASS |
| #9 | readingQuestionProvider 라이프사이클 — 모드 간 누출 없음 | `intention_page.dart` initState에서 `readingQuestionProvider.notifier.clear()` 호출. `draw_result_page.dart`는 `_executeDraw()` 내 `readingQuestionProvider.notifier.clear()` 호출. 두 페이지 모두 진입 시 clear → 누출 없음. `afterDraw` 모드에서 DrawResultPage는 `readingQuestionProvider`를 읽지 않고 `updateQuestion`으로 DB에 직접 기록 | PASS |

**Check 4: PASS (5/5)**

---

## Check 5: Bug Resolution — _autoSave race condition 없음

`_autoSave` 분석:
- `_autoSaved` 플래그로 1회만 실행 (race 불가)
- 실행 시점: `_executeDraw()` 완료 후 → `_questionController.text == ''` (질문 입력 전)
- `afterDraw` 모드에서 `_autoSave`는 `question=null` 저장 (설계 허용 — Brief Decision 5)
- 사용자가 질문 입력 후 `onSubmitted` → `_updateQuestion()` → `readingRepository.updateQuestion(_savedReadingId!, text)` 호출
- `_updateQuestion`은 `onSubmitted` 콜백에서만 호출 → input write가 autoSave 이후에 일어남 → race 없음

Brief Decision #5 ("결과 화면 입력이 저장본에 반영되지 않는 현존 버그") 해결 확인:
- 기존: `_updateQuestion`이 `readingQuestionProvider.notifier.set(text)`로 메모리에만 저장
- 수정 후: `readingRepository.updateQuestion(_savedReadingId!, ...)` 호출로 DB에 영속화

**Check 5: PASS**

---

## Plan 미비점 기록

| # | 항목 | 심각도 | 설명 |
|---|------|--------|------|
| 1 | `_autoSave` `beforeShuffle` 모드에서 question 소스 | Low | `_questionController.text` 항상 빈 문자열 → `question=null` 저장. `readingQuestionProvider`의 값이 DB에 반영되지 않음. IS#6 정합성 구현은 별도 작업 필요 |

---

## Summary

| 항목 | 결과 |
|------|------|
| Check 1 — Plan adherence | PASS (8/8) |
| Check 2 — Cycle 3 tests GREEN | PASS (10/10) |
| Check 3 — No new regressions | PASS (+79 -6, pre-existing only) |
| Check 4 — Brief Criteria #5-#9 | PASS (5/5) |
| Check 5 — Bug resolution (_autoSave race) | PASS |

**Verdict: PASS**

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 0s | 0 |
| 2 | user-ai-exchange | 0s | 0 |
| 3 | user-ai-exchange | 0s | 0 |
| 4 | user-ai-exchange | 0s | 0 |
| 5 | user-ai-exchange | 0s | 0 |
| 6 | user-ai-exchange | 0s | 0 |
| 7 | user-ai-exchange | 196s | 462019 |
| 8 | user-ai-exchange | 105088s | 8988850 |
| 9 | user-ai-exchange | 196s | 2025463 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 112172s |
| Total Tokens | 11476332 |
| Input Tokens | 197 |
| Output Tokens | 70885 |
| Cache Read | 10450461 |
| Cache Creation | 954789 |
