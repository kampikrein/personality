---
id: "009"
type: eval
title: "Eval: Cycle 2 — 설정 + 리딩 기능 (Settings & Reading)"
created: 2026-03-22
cycle: 2
effort_mode: standard
persona: default
verdict: proceed
depth_score: 11
critical_gate: PASS
terminate: false
recommended_changes: []
summary: >
  Cycle 2(설정+리딩 기능)가 Brief MA-5, MA-7, MA-8을 정확히 구현. Verify 8/9 PASS,
  1 finding(F-008-01 showFaceUp)은 gate가 264b181 커밋으로 즉시 수정.
  Plan 7 Step 전수 구현, scope drift 0. Depth Score 11/12로 proceed 판정.
  Cycle 3(홈 허브 + 뽑기 체험) 즉시 착수 가능.
---

# Eval: Cycle 2 — 설정 + 리딩 기능 (Settings & Reading)

## 1. 시그널 수집 결과

### Scope 문서 (002)

| 항목 | 값 |
|------|---|
| Intent | 메인 메뉴 허브 → 3단계 체험 레벨 → 즉시 뽑기. 1~10장 자유 + 덱별 고유 뽑기 + 한 장 더. 설정은 UserSettings DB |
| Cycle 2 영역 | 설정 + 리딩 기능 — 설정 페이지, 리딩 목록/상세, 자동 저장, +1 뽑기 |
| 의존관계 | Cycle 2는 Cycle 1에 의존. Cycle 3이 Cycle 1, 2에 의존 |
| 파이프라인 | eval → Agent(P) → Agent(I) → Agent(V) [Cycle 2] |

### Verify 리포트 (008)

| 시그널 | 값 |
|--------|---|
| V3 (pass rate) | 8/9 = **89%** (F-008-01 showFaceUp 미동작 → gate 수정 후 실질 9/9) |
| V4 (critical issues) | **0건** (F-008-01은 Medium — UX 결함, 런타임 에러 아님) |
| V5 (skip count) | **0건** |

### Implementation 결과

| 시그널 | 값 |
|--------|---|
| I1 (scope 외 변경 파일) | **0건** — 소스 11개 + codegen 2개, 모두 Plan(007) 명세 파일과 일치 |
| I2 (unresolved items) | **0건** — Plan 7 Step + codegen + 빌드 검증 모두 완료 |

### Git diff vs Plan 파일 목록

**Plan 명세 파일 (11개, 수정 7 + 신규 4)**:

| # | Plan 파일 | 커밋 포함 | 일치 |
|---|----------|----------|------|
| 1 | `reading_dao.dart` (MODIFY) | deca30a | O |
| 2 | `reading_repository.dart` (MODIFY) | deca30a | O |
| 3 | `reading_repository_impl.dart` (MODIFY) | deca30a | O |
| 4 | `reading_providers.dart` (MODIFY) | deca30a | O |
| 5 | `settings_page.dart` (NEW) | deca30a | O |
| 6 | `reading_list_page.dart` (NEW) | deca30a | O |
| 7 | `reading_detail_page.dart` (NEW) | deca30a | O |
| 8 | `reading_page.dart` (MODIFY) | deca30a | O |
| 9 | `app_router.dart` (MODIFY) | deca30a | O |
| 10 | `card_reveal_widget.dart` (MODIFY — F-008-01 fix) | 264b181 | O |
| 11 | `reading_providers.g.dart` (codegen) | deca30a | O |

**codegen 재생성 (2개)**: `reading_providers.g.dart`, `app_router.g.dart` — 정상.

**Plan 외 변경 파일**: 0건. 두 커밋(deca30a + 264b181) 합산 12파일 전부 Plan 명세 범위 내.

### 상위 Initiative 정렬 (S1/S2/S3)

| 시그널 | 값 | 근거 |
|--------|---|------|
| S1 (커버리지) | **67%** (2/3 사이클 완료) | Cycle 1(데이터 기반) + Cycle 2(설정+리딩) 완료 |
| S2 (미구현 영역) | 홈 허브 재설계, 라우터 재구조, Level 1/2/3 뽑기 페이지 | Cycle 3 영역 |
| S3 (잔여율) | N/A | 데이터 전환 과제 아님 |

## 2. Critical Gate

**PASS** — V4 (critical issues) = 0건. F-008-01은 Medium 심각도(UX 결함, 런타임 에러 아님)이며 gate가 264b181에서 즉시 수정 완료.

## 3. Scoring

| 차원 | 원시값 | 점수 | 근거 |
|------|--------|------|------|
| **V-score** | 89% (8/9) → gate 수정 후 실질 100% | **3** | Verify 시점 8/9이나, F-008-01이 264b181에서 2줄 수정으로 해결됨. 수정이 정확하고 최소 범위(initState에 `if (widget.isRevealed)` 체크 추가). 실질 pass rate 100% |
| **U-score** | 0건 unresolved | **3** | I2 = 0. Plan 7 Step 전수 구현 완료 |
| **D-score** | 0건 scope drift | **3** | I1 = 0. 12파일 전부 Plan 명세 범위 내. 가중 drift = 0 |
| **T-score** | Verify가 9개 기준 전수 + 코드 경로 추적 | **2** | Verify(008)가 검증 기준별 코드 라인 참조 + edge case 5개 검증. 자동화 verify-trace 미실행이나 수동 전수 검증 수행. T=2 |

**Depth Score = 3 + 3 + 3 + 2 = 11 / 12**

## 4. 문서 미기재 발견사항

### 신규 발견

- **EV-009-D1**: `ReadingDetailPage`가 `watchReadingsProvider`를 watch하여 전체 리딩을 로딩한 후 `where`로 ID 필터링. Plan 리스크 #4에서 인지했으나, 리딩 수가 증가하면 성능 문제가 될 수 있음. Cycle 3에서는 영향 없으나, 향후 `getReadingByIdProvider` 도입 고려.

- **EV-009-D2**: `_autoSave`가 `build()` 메서드 내에서 호출됨 (reading_page.dart:140). Flutter의 build는 side-effect-free여야 한다는 관례를 위반. 현재 `_autoSaved` 플래그로 중복 실행 방지되어 기능적 문제는 없으나, `WidgetsBinding.instance.addPostFrameCallback`으로 이동하면 더 관용적. 차단 사유 아님.

### 문서 간 불일치

- 없음. Brief(001) → Scope(002) → Plan(007) → Verify(008) 전 문서 체인의 일관성 확인 완료. Plan(007)의 EV-006 대응 섹션이 Eval(006) 발견사항을 정확히 참조.

### 암묵적 가정

- **EV-009-A1**: `SettingsPage`가 `DropdownButtonFormField`에 `initialValue`를 사용 (Plan 스니펫은 `value`). `DropdownButtonFormField`의 `initialValue` 파라미터는 FormField의 초기값이며, `settingsAsync.when(data:)`로 매 rebuild 시 새 위젯이 생성되므로 기능적 차이 없음. 다만 `DropdownButtonFormField`는 `initialValue`와 `value`를 동시에 받으면 assert fail하는데, 현재 `initialValue`만 사용하므로 안전.

- **EV-009-A2**: `reading_page.dart`의 `readingQuestionProvider`는 `IntentionPage`에서 설정되는 것을 전제. Level 1/2 즉시 뽑기(Cycle 3)에서 `IntentionPage`를 경유하지 않으면 question이 빈 문자열. `_autoSave`에서 `question.isNotEmpty ? question : null`로 처리하므로 기능 문제는 없으나, Cycle 3 Plan에서 question 전달 경로 설계 필요.

### 부수 효과

- **EV-009-S1**: `ReadingPage`에서 수동 저장 버튼(`IconButton(icon: Icon(Icons.save))`) 제거 + 자동 저장 전환. 기존 사용자 플로우(셔플 → 리딩 → 수동 저장) 중 "저장 안 하고 나가기" 옵션이 사라짐. 모든 공개 완료 리딩이 자동 저장됨. 의도된 동작(Brief Decision #6: "매 뽑기 자동 저장")이나, 사용자가 연습/테스트 뽑기를 삭제하려면 리딩 상세에서 삭제 기능이 필요함 — 현재 UI에 삭제 버튼 미구현. 차단 사유는 아니나 향후 고려.

## 5. Verdict 도출

### Scoring -> Verdict 매핑

- Depth Score: **11/12**
- 0점 차원: **없음** (최저 T-score = 2)
- 판정 기준: 10-12 -> **proceed**

### Brief Alignment 상세

| Model Anchor | 요구사항 | 구현 상태 | 평가 |
|-------------|---------|----------|------|
| **MA-5** (리딩 저장 & 메모) | 자동 저장 + notes 인라인 편집 + spreadType 필터 목록 | `_autoSave()` allRevealed 시 자동 실행 + `ReadingDetailPage` debounce notes + `ReadingListPage` FilterChip | **완전 충족** |
| **MA-7** (앞면/뒷면) | showFaceUp 설정 적용 → 카드 초기 표시 상태 | `ReadingPage` build에서 `_revealedPositions` 추가 + `CardRevealWidget.initState`에서 `isRevealed` 체크 (264b181) | **완전 충족** (gate 수정 포함) |
| **MA-8** (한 장 더 뽑기) | "+1" FAB → 카드 append + DB 갱신 + 비활성화 | `_addOneMore()` + `addDrawnCard()` + FAB 조건부 표시 + 남은 카드 수 label | **완전 충족** |

### Plan -> Implementation 완전성

| Step | 내용 | 구현 상태 |
|------|------|----------|
| 1-1 | ReadingDao 확장 (updateNotes, addDrawnCard, watchReadingsBySpreadType) | 완료 — Plan 코드와 100% 일치 |
| 1-2 | ReadingRepository 인터페이스 4개 메서드 추가 | 완료 — 4개 메서드 선언 확인 |
| 1-3 | ReadingRepositoryImpl 4개 메서드 구현 | 완료 — Plan 패턴 일치 |
| 1-4 | ReadingProviders watchReadingsBySpreadType family provider | 완료 — codegen 정상 |
| 2 | SettingsPage 6개 설정 항목 UI | 완료 — 덱/레벨/카드수/앞면뒷면/즉시뽑기/스프레드 전부 구현 |
| 3 | ReadingListPage + FilterChip 필터 | 완료 — DB-level 쿼리 필터 + 빈 목록 메시지 |
| 4 | ReadingDetailPage + notes debounce 자동 저장 | 완료 — 500ms Timer + 저장 상태 UI |
| 5 | ReadingPage 자동 저장 + "+1" FAB + showFaceUp | 완료 — _autoSaved 플래그 + _addOneMore + _revealedPositions |
| 6 | 라우터 3개 라우트 등록 | 완료 — /settings, /readings, /readings/:readingId |
| 7 | 코드 생성 + 빌드 검증 | 완료 — dart analyze 0건 |

**7/7 Step 전수 구현 완료.**

### Verify Finding 대응 — F-008-01

| 항목 | 값 |
|------|---|
| Finding | `CardRevealWidget.initState`에서 `_showFront = false` 고정 → `isRevealed: true`로 생성 시 뒷면 유지 |
| 수정 커밋 | 264b181 |
| 수정 내용 | `initState`에 `if (widget.isRevealed) { _showFront = true; _controller.value = 1.0; }` 4줄 추가 |
| 수정 범위 | `card_reveal_widget.dart` 1파일, 4줄 |
| 정합성 | Verify(008)에서 제시한 수정 방향과 정확히 일치. 최소 범위 수정으로 기존 애니메이션 플로우(뒷면→앞면 플립) 미영향 |
| 평가 | **적절** — gate가 verify 이후 즉시 수정하여 F-008-01 해소. `_controller.value = 1.0`으로 애니메이션 스킵하여 showFaceUp 시 즉시 앞면 표시 |

### Cycle 1 Eval 발견사항 반영 여부

| ID | 발견 | Plan(007) 대응 | 구현 반영 | 평가 |
|----|------|---------------|----------|------|
| **EV-006-D1** | `userSettingsProvider` AutoDispose → GoRouter lifecycle 주의 | "이 사이클에서는 영향 없음. Cycle 3에서 확인" | ReadingPage에서 `ref.watch(userSettingsProvider)` 정상 사용. AutoDispose 문제 미발생 (페이지 lifecycle 내) | **적절** — Cycle 2 범위 내에서 올바르게 대응. Cycle 3 전달 유지 |
| **EV-006-A1** | `custom.cardCount == 0` sentinel → 카드 수 관리 주의 | `_currentCardCount = defaultCardCount ?? 3` 초기화 | reading_page.dart:44 — custom일 때 `userSettingsProvider.defaultCardCount ?? 3` fallback 사용 | **완전 반영** — 0 sentinel 직접 미사용, 실제 카드 수를 `_currentCardCount` 상태 변수로 추적 |
| **EV-006-D2** | `_ensureDefaultRow` 다중 행 edge case | 모든 update가 `id.equals(1)` 패턴 | SettingsPage의 모든 onChanged가 `userSettingsRepositoryProvider` → DAO `id.equals(1)` 경유 | **적절** — 다중 행 존재해도 id=1만 업데이트 |

### Cycle 3 Readiness 평가

| Cycle 3 필요 사항 | 준비 상태 | 근거 |
|------------------|----------|------|
| `/settings` 라우트 | **Ready** | app_router.dart에 등록 완료. 홈 허브에서 네비게이션 연결만 필요 |
| `/readings` 라우트 | **Ready** | app_router.dart에 등록 완료. 홈 허브에서 네비게이션 연결만 필요 |
| `/readings/:readingId` 라우트 | **Ready** | app_router.dart에 등록 완료. 리딩 목록 → 상세 흐름 동작 |
| 자동 저장 로직 | **Ready** | Level 1/2에서 build 시점에 allRevealed → 즉시 _autoSave. Level 3은 기존 방식 유지 |
| showFaceUp 적용 | **Ready** | CardRevealWidget initState에서 isRevealed 체크 완료(264b181). Level 1/2에서 showFaceUp=true 시 즉시 앞면 |
| `_currentCardCount` 초기화 | **Ready** | UserSettings.defaultCardCount로 초기화. Level 1 즉시 뽑기 시 설정된 장수 표시 |
| `userSettingsProvider` 접근 | **주의** | EV-006-D1 미해소. Cycle 3의 GoRouter redirect에서 async 조회 + AutoDispose lifecycle 정합성 확인 필요 |
| question 전달 경로 | **주의** | EV-009-A2. Level 1/2에서 IntentionPage를 경유하지 않으면 readingQuestionProvider가 기본값(빈 문자열). 기능적으로는 안전하나 UX 설계 결정 필요 |

**총평**: Cycle 3 착수에 차단 사유 없음. 2개 주의 사항은 Cycle 3 Plan에서 설계 결정으로 처리 가능.

### 대안 검토

- **adjust 고려**: T-score가 2이나, Verify가 9개 기준 + edge case 5개를 코드 라인 수준으로 추적. F-008-01이 gate 수정으로 해소됨. 추가 사이클 불필요.
- **deepen 고려**: 해당 없음. 모든 차원 2점 이상, critical issue 0건.

### 종료 판단

- **계속 진행**: Cycle 2는 3사이클 중 두 번째. Intent 달성률 ~67% (데이터 기반 + 설정/리딩 완료). Cycle 3(홈 허브 + 뽑기 체험)이 남아있음.
- `terminate: false`

## 6. 권고사항

### Verdict: PROCEED

### 체크리스트 변경 권고

```yaml
recommended_changes: []
```

추가 사이클, 재작업, scope 수정 불필요.

### 다음 사이클 전달사항

- **EV-006-D1 계속 유효**: Cycle 3에서 GoRouter provider 작성 시 `userSettingsProvider`의 AutoDispose 특성 확인. `ref.watch`가 GoRouter의 redirect 내에서 사용 가능한지, 또는 `keepAlive: true` provider로 래핑해야 하는지 설계 결정.
- **EV-009-A2 question 경로**: Level 1/2 즉시 뽑기 시 IntentionPage를 경유하지 않으면 question이 빈 문자열. Cycle 3 Plan에서 (a) 즉시 뽑기에서도 간단한 질문 입력 제공, (b) question 없이 진행, (c) 홈 허브에서 질문 입력 후 즉시 뽑기 — 중 설계 선택.
- **EV-009-S1 리딩 삭제**: 자동 저장 전환으로 모든 리딩이 DB에 쌓임. 리딩 삭제 UI는 현재 미구현. 홈 허브의 리딩 목록에서 삭제/스와이프 기능을 Cycle 3에서 추가할지, 별도 과제로 남길지 결정.
- **Cycle 2 산출물 인계**: `/settings`, `/readings`, `/readings/:readingId` 라우트 + 자동 저장 + showFaceUp + _currentCardCount 초기화 — Cycle 3에서 즉시 활용 가능.

---

```
== Eval: Cycle 2 Complete ==
Depth Score: 11/12 (V:3 U:3 D:3 T:2)
Critical gate: PASS
Verdict: PROCEED
Persona: default
Findings: D:2 C:0 A:2 S:1 (5건)
Document: docs/20_mobile_ui_overhaul/009_Eval_Cycle_2.md
```

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
