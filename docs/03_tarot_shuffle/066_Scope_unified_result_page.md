---
id: "066"
type: scope
title: "뽑기 결과 페이지 통일 — Scope"
created: 2026-04-14
status: completed
complexity: complex
traces_brief: "065"
research_needed: false
effort_mode: standard
tdd_mode: true
auto_run: false
summary: >
  Brief 065의 DrawResultPage 수렴 전략을 2개 사이클로 실행하기 위한 Scope.
  Cycle 1은 리네임·라우트 원자 교체, Cycle 2는 업스트림(AnimatedDrawPage, ShufflePage)
  후단 전환과 ReadingPage(draw-time) 제거를 수행한다. Research 불필요 — Brief 성숙 + 기존 패턴 활용.
keywords: [scope, draw-result, rename, routing, refactor, unified-flow]
---

# 뽑기 결과 페이지 통일 — Scope

## Brief Anchor

Brief 065 (`docs/03_tarot_shuffle/065_Brief_unified_result_page.md`)의 **In Scope 8 항목 · Decisions D1~D8 · Model Anchors MA-0~MA-9 · Ideal Criteria 26개**가 본 Scope의 상위 규약이다. 본 Scope 문서는 그 위에서 기술적 실행 단위(사이클)를 분해한다.

## 영역 맵

| # | 영역 | 주요 파일 | 역할 |
|---|------|----------|------|
| 1 | **draw** (결과 페이지) | `features/draw/presentation/pages/instant_draw_page.dart` → `draw_result_page.dart` | 정본 결과 페이지 (리네임 대상) |
| 2 | **draw** (연출) | `features/draw/presentation/pages/animated_draw_page.dart` | Lv2 애니메이션 연출 (책임 축소 대상) |
| 3 | **shuffle** | `features/shuffle/presentation/pages/shuffle_page.dart`, `intention_page.dart` | Lv4 물리 셔플 + 의도 (후단 전환) |
| 4 | **reading** | `features/reading/presentation/pages/reading_page.dart` | draw-time ReadingPage (삭제 대상) |
| 5 | **home** | `features/home/presentation/pages/home_page.dart` | Lv1 진입 호출부 (경로 교체) |
| 6 | **core/router** | `core/router/app_router.dart` | GoRoute 정의 (경로·name 교체 + /reading 삭제) |

## 의존성 맵

```
home_page ─────push('/draw/instant')─────┐
                                         ▼
core/router ──InstantDrawPage 매핑──► draw_result_page
                                         ▲
animated_draw_page ──pushReplacement──────┤
                                         │
shuffle_page ──pushNamed('reading')──► reading_page (삭제)
                                         │
intention_page ──pushNamed('shuffle')──► shuffle_page
```

**After refactor**:
```
home_page ─────push/pushReplace('/draw/result')────┐
                                                    ▼
core/router ──DrawResultPage 매핑──►         draw_result_page
                                                    ▲
animated_draw_page ──pushReplacement('/draw/result')┤
                                                    │
shuffle_page ──pushReplacementNamed('draw-result')──┘
                                         ✗ reading_page 삭제
```

**증거** (파일:라인):
- `home_page.dart:36,44` → `/draw/instant` 호출
- `app_router.dart:153-157` → `/draw/instant` 정의, `:156` `InstantDrawPage` 사용
- `app_router.dart:141-150` → `/reading/:deckId` 정의, `:149` `ReadingPage` 사용
- `app_router.dart:14` → `reading_page.dart` import
- `shuffle_page.dart:67-70` → `pushNamed('reading')`
- `intention_page.dart:42` → 주석 "시나리오 3-A: 스택의 ReadingPage null 재빌드"

## 사이클 설계

### Cycle 1 — 리네임 & 라우트 원자 교체

**Scope**:
- 파일 이동 + Git rename 보존: `instant_draw_page.dart` → `draw_result_page.dart`
- 클래스 리네임: `InstantDrawPage` → `DrawResultPage`, `_InstantDrawPageState` → `_DrawResultPageState`
- 라우트: path `/draw/instant` → `/draw/result`, GoRoute name `draw-instant` → `draw-result`
- 호출부 교체: `app_router.dart` import + GoRoute child, `home_page.dart:36`, `:44`

**Modified (actual change)**:
1. `mobile/lib/features/draw/presentation/pages/draw_result_page.dart` (이동·리네임)
2. `mobile/lib/core/router/app_router.dart` (import + 2개 라인)
3. `mobile/lib/features/home/presentation/pages/home_page.dart` (2개 호출부)

**Reviewed (check-only)**:
- 전체 `mobile/lib` grep `InstantDrawPage|draw/instant|draw-instant` → 0건 확인

**완료 조건**:
- Ideal Criteria #1 (grep 0건), #2 (build 성공), #3 (docstring 명시)
- `flutter build apk --debug` 통과
- 기존 Lv1 "바로 뽑기" 플로우 수동 회귀 (build + 홈 → 바로 뽑기 1회)

**TDD Red** (tdd_mode: true):
- 신규 위젯 테스트: `draw_result_page_test.dart` — `DrawResultPage` 위젯이 `shuffleStateProvider` override 하에서 올바르게 초기화되는지 기본 smoke (Brief MA-9)

### Cycle 2 — 업스트림 통합 & ReadingPage 제거

**Scope**:
- `DrawResultPage.initState` 분기: `shuffleStateProvider` 초기값 null 시 자체 셔플, 아니면 재사용 (if-else 1회, Brief MA-3·MA-9)
- `AnimatedDrawPage`: 결과 블록(SpreadLayout · saveReading · 한 장 더 UI) 제거 + 연출 종료 콜백에서 `pushReplacementNamed('draw-result')` (Brief MA-4)
- `ShufflePage:67-70`: `pushNamed('reading', ...)` → `pushReplacementNamed('draw-result', pathParameters: {'deckId': ...})` (Brief MA-5)
- `reading_page.dart` 파일 삭제 + `app_router.dart`의 `/reading/:deckId` 라우트 + import 삭제 (Brief MA-6)
- `intention_page.dart:42`: 시나리오 3-A 주석 업데이트 — ReadingPage 제거로 자연 해결되는지 검증 후 주석 갱신 또는 삭제
- `addOneMore` 기능 동치 검증: ReadingPage의 `addOneMore`가 `DrawResultPage`의 `addDrawnCard` 경로로 완전히 대체되는지 코드 비교

**Modified (actual change)**:
1. `mobile/lib/features/draw/presentation/pages/draw_result_page.dart` (initState 분기 로직 추가)
2. `mobile/lib/features/draw/presentation/pages/animated_draw_page.dart` (결과 블록 제거 + pushReplacement)
3. `mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart` (navigation 타겟 교체 + pushReplacement)
4. `mobile/lib/features/shuffle/presentation/pages/intention_page.dart` (주석 갱신)
5. `mobile/lib/core/router/app_router.dart` (`/reading/:deckId` GoRoute + import 삭제)
6. `mobile/lib/features/reading/presentation/pages/reading_page.dart` (**DELETE**)

**Reviewed (check-only)**:
- `reading_list_page.dart`, `reading_detail_page.dart` — 라우트 `/readings`, `/readings/:readingId` 독립 동작 확인
- `reading_providers.dart` — `addDrawnCard` / `saveReading` 인터페이스 불변 확인

**완료 조건**:
- Ideal Criteria #5~#22, #26 충족
- Lv1~Lv4 수동 end-to-end: 홈에서 체험 레벨 1~4 각각 진입 → 뽑기 → 저장 → `/readings` 목록에서 조회 성공
- `flutter analyze` unresolved import 경고 0건
- `grep -r "ReadingPage\|/reading/:deckId" mobile/lib` = 0 (reading_list/detail 제외)

**TDD Red**:
- `DrawResultPage.initState` 분기 테스트: `shuffleStateProvider` override (a) null → 자체 셔플 호출 확인, (b) 기존 결과 → 재사용 확인 (Criterion #6, #20)
- Race/중복 셔플 방지 테스트: initState에서 셔플이 2회 이상 호출되지 않음

## 잠재 리스크 (Scope 수준)

| # | 리스크 | 대응 |
|---|-------|------|
| R1 | intention_page 주석의 "시나리오 3-A: ReadingPage null 재빌드" | Cycle 2 완료 후 시나리오 재현 시도 → 자연 해결이면 주석 삭제, 잔존이면 DrawResultPage로 이관 |
| R2 | `pushNamed`(현재) vs `pushReplacementNamed`(목표) 차이로 뒤로가기 동작 변화 | Brief Constraints에 명시된 "뒤로가기는 홈 복귀" 원칙에 맞음 — 수동 회귀에서 각 레벨 뒤로가기 1회 검증 |
| R3 | `addOneMore`와 `addDrawnCard` 기능 동치 불일치 가능성 | Cycle 2 범위에 코드 diff 비교 포함. 불일치 시 DrawResultPage로 누락 기능 이관 |
| R4 | Git rename 추적 손실 (파일 이동 + 편집 혼재) | `git mv` 후 별도 커밋으로 리네임 / 내용 변경 분리 권장 (구현 단계에서 지침 전달) |
| R5 | /reading 라우트에 대한 외부 deep link | 현재 앱 외부 진입점 없음 (확인 완료) → 삭제 안전 |

## Ideal Criteria 커버리지

Brief 065의 Ideal Criteria 26개는 본 Scope의 2개 사이클로 다음과 같이 커버된다:

| Criteria | Cycle |
|----------|-------|
| #1, #2, #3, #4 (리네임 원자성) | Cycle 1 |
| #5, #7 (업스트림 규약) | Cycle 2 |
| #6, #20, #21, #22, #23 (DrawResultPage 분기/robustness) | Cycle 2 |
| #8, #9, #10 (AnimatedDrawPage 축소) | Cycle 2 |
| #11, #12, #13 (ShufflePage 후단) | Cycle 2 |
| #14, #15 (Lv3 규약 참조) | Cycle 2 (문서 확인) |
| #16, #17, #18, #19 (ReadingPage 제거) | Cycle 2 |
| #24, #25 (라우트 리네임) | Cycle 1 + Cycle 2 (문서) |
| #26 (E2E) | Cycle 2 완료 후 수동 |

## Trace

- **Brief**: `docs/03_tarot_shuffle/065_Brief_unified_result_page.md`
- **Related Brief (precedent)**: `docs/03_tarot_shuffle/063_Brief_shuffle_rebuild.md`, `064_Brief_experience_level_page_design.md`
- **Related Brief (UI context)**: `docs/09_mobile_ui_overhaul/015_Brief_draw_result_ui_fixes.md`

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
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 2810s |
| Total Tokens | 4543920 |
| Input Tokens | 81 |
| Output Tokens | 51753 |
| Cache Read | 4304215 |
| Cache Creation | 187871 |
