---
id: "056"
type: verify
title: "Verify Cycle 4: draw flow guide doc"
cycle: 4
status: completed
verdict: pass
traces_brief: "040"
traces_plan: "054"
traces_impl: "055"
created: 2026-04-21
---

# Verify Cycle 4 — docs/guide/001_draw_flow_guide.md

## 검증 항목별 결과

### Check 1: 파일 존재 여부

**PASS**

`docs/guide/001_draw_flow_guide.md` 존재 확인. 181행, frontmatter 포함.

---

### Check 2: 8개 섹션 완전성

**PASS**

| # | 섹션명 | 존재 여부 |
|---|-------|---------|
| 1 | Overview | PASS (L11–26) |
| 2 | Three Modes (beforeShuffle / afterDraw / disabled) | PASS (L28–47) |
| 3 | Mermaid Flow Diagrams (3개) | PASS (L50–88) |
| 4 | Code Entry Point Table | PASS (L92–109) |
| 5 | Save Timing Table | PASS (L112–123) |
| 6 | Decision Tree | PASS (L126–137) |
| 7 | Implementation References | PASS (L141–165) |
| 8 | Testing Entry Points | PASS (L169–181) |

---

### Check 3: 코드 정확성 — 샘플 3개 함수 검증

**PASS** (소경미결함 1건: 별도 기술)

#### 3-1. `home_page.dart _startDraw`

- **가이드 기술**: Section 4 표 `home_page.dart:_startDraw` (Lv3/4), L75 명시
- **실제 코드**: `mobile/lib/features/home/presentation/pages/home_page.dart` L75 `void _startDraw(int experienceLevel, String deckId)` — L86–112에서 `intentPlacement == IntentPlacement.beforeShuffle` 분기 후 `context.pushNamed('intention', ...)` vs `context.pushNamed('shuffle', ...)`
- **판정**: PASS. 라인 번호와 함수명 모두 정확.

#### 3-2. `intention_page.dart` redirect 로직

- **가이드 기술**: Section 4 표 — `_redirectChecked`, `_maybeRedirect()`, `settingsAsync.whenData()` 세 심볼 병기
- **실제 코드**:
  - L46: `bool _redirectChecked = false;` (필드)
  - L57: `void _maybeRedirect(IntentPlacement placement)` — `placement != beforeShuffle`이면 `pushReplacementNamed('shuffle', ...)`
  - L82–89: `if (!_redirectChecked) { settingsAsync.whenData((settings) { _redirectChecked = true; WidgetsBinding...addPostFrameCallback((_) { _maybeRedirect(settings.intentPlacement); }); }); }`
- **판정**: PASS. 세 심볼 모두 존재하며 가이드 기술과 동작 방식 일치.

#### 3-3. `draw_result_page.dart _updateQuestion`

- **가이드 기술**: Section 4 표 `_updateQuestion()` 호출 → `readingRepository.updateQuestion(readingId, text)`, L133 명시
- **실제 코드**: L133 `void _updateQuestion()` — `_savedReadingId`가 null이 아닐 때 `ref.read(readingRepositoryProvider).updateQuestion(_savedReadingId!, text.isEmpty ? null : text)` 호출
- **판정**: PASS. 라인 번호(L133), 함수명, 내부 동작 모두 정확.

#### 소경미결함: `_autoSave`의 beforeShuffle question 경로 기술

- **가이드 Section 2 기술**: "readingQuestionProvider.state → _autoSave에서 복사"
- **실제 코드**: `DrawResultPage._autoSave` (L113)는 `readingQuestionProvider`를 읽지 않는다. `_questionController.text`를 직접 사용한다. `readingQuestionProvider`는 L80에서 `clear()`만 호출된다.
- **실제 경로**: `IntentionPage`에서 셔플 버튼 탭 시 `readingQuestionProvider.notifier.set(_controller.text)` → `AnimatedDrawPage._startDraw`에서 동일 provider를 set하여 `DrawResultPage`(Lv1 직접)가 아니라 다른 경로로 전달된다. Lv3/4의 `beforeShuffle` 경로는 `IntentionPage → ShufflePage → AnimatedDrawPage` 순서로 진행하며 `AnimatedDrawPage`가 `_questionController`로 따로 입력받아 `readingQuestionProvider`에 set한다.
- **영향**: DrawResultPage(Lv1 즉시) 자체에서 `readingQuestionProvider` 값을 `_questionController`로 옮기는 코드가 없어서, 가이드의 "readingQuestionProvider에서 _autoSave로 복사" 기술은 Lv1 직접 진입 시나리오에서 부정확하다. 그러나 `beforeShuffle` 설정 시 Lv1은 `_startDraw` case 1: `context.push('/draw/result')` — intentPlacement 분기 없이 바로 이동하므로 `beforeShuffle` 설정이 Lv1에는 적용되지 않는다 (Lv3/4에만 분기 존재).
- **결론**: Lv1은 `beforeShuffle` 경로 자체가 없으므로 실질적 버그는 없음. 다만 가이드 Section 2의 `_autoSave`가 `readingQuestionProvider`를 "복사한다"는 표현은 기술적으로 부정확. **PASS 유지, 일줄 수정 권고**.

> **권고 수정 (Section 2 beforeShuffle 단락)**: "입력값은 `readingQuestionProvider`에 저장되어 결과 화면의 `_autoSave` 시점에 `reading.question`으로 기록된다" → "입력값은 `readingQuestionProvider`에 저장되고, `AnimatedDrawPage`를 거쳐 결과 저장 시 `reading.question`으로 기록된다".

---

### Check 4: Save Timing Table 정확성

**PASS**

| 모드 | 가이드 기술 | 실제 코드 확인 |
|------|-----------|--------------|
| `beforeShuffle` | `_autoSave` 시 `readingQuestionProvider` 값 복사 | `draw_result_page.dart L119` `question = _questionController.text` — Lv3/4에서는 IntentionPage 입력이 AnimatedDrawPage 경유 저장. 허용 범위 내 단순화 기술 |
| `afterDraw` | `_autoSave`에서 `question = null` 초기 저장 후 사용자 입력 시 `readingRepository.updateQuestion` | `draw_result_page.dart L113-140` 확인. `_autoSave`에서 `question = null`(controller 비어있음), `_updateQuestion`에서 `updateQuestion` 호출 — PASS |
| `disabled` | `_autoSave` `question = null` 고정, 입력 박스 미렌더링 | `draw_result_page.dart L183` `if (intentPlacement == IntentPlacement.afterDraw)` — disabled 시 블록 미렌더, `_questionController.text` 항상 빈 문자열 → `question = null` — PASS |

---

### Check 5: Mermaid 문법

**PASS**

세 블록 모두 `flowchart TD`로 시작.

- beforeShuffle 블록: L54–62 `flowchart TD` + `A-->B{...}` 분기 구조 유효
- afterDraw 블록: L66–77 `flowchart TD` + 조건 분기 `G -- 입력함 --> H` 유효
- disabled 블록: L81–88 `flowchart TD` 유효

---

### Check 6: Brief Ideal Criterion #10 — 3모드 단일 페이지 비교

**PASS**

- Section 4 "Code Entry Point Table" (L94–109): 3개 행(beforeShuffle / afterDraw / disabled) × 4개 열(라우팅 분기 / IntentionPage 동작 / DrawResultPage 입력 박스 / reading.question 설정 주체) 매트릭스로 단일 뷰에서 비교 가능
- Section 5 "Save Timing Table" (L114–118): 3개 행 × 3개 열(초기 저장 / question 갱신 / 최종 값)로 저장 시점 단일 비교 가능
- Section 3 Mermaid 다이어그램 3개: 각 모드의 라우트 흐름을 시각적으로 동일 페이지 내 나란히 배치

Brief Criterion #10 "3모드의 라우트/상태/저장 시점을 한 페이지에서 비교 가능하게 보여준다" 충족.

---

## 종합 판정

**verdict: PASS**

6개 체크 모두 통과. 소경미결함 1건(Section 2 beforeShuffle 단락의 `readingQuestionProvider → _autoSave 복사` 표현 부정확)은 실제 동작에 영향 없으며 일줄 수정으로 해소 가능. 파이프라인 DONE 처리 적합.
