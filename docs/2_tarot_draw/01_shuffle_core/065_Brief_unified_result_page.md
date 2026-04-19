---
id: "065"
type: brief
title: "뽑기 결과 페이지 통일 — DrawResultPage 수렴"
created: 2026-04-14
status: completed
quality_profile: showcase
deep_critique: false
critique_docs: []
summary: >
  체험 레벨 1~4 모든 뽑기 흐름의 **최종 결과 페이지를 DrawResultPage(신규 네이밍)로 수렴**시킨다.
  기존 InstantDrawPage(Lv1 전용 뉘앙스)를 `DrawResultPage`로 리네임/이동하여 포괄 결과 페이지 역할을 명시하고,
  AnimatedDrawPage(결과 블록)와 ReadingPage(draw-time)의 중복 렌더/저장 로직을 제거한다.
keywords: [draw, result-page, unification, navigation, draw-result, rename, reading-page, refactor]
---

# 뽑기 결과 페이지 통일 — DrawResultPage 수렴

## Intent

현재 4개 체험 레벨의 뽑기 흐름이 서로 다른 "결과 페이지"에서 종료된다:

- Lv1 `즉시` → **InstantDrawPage** (셔플 + 결과 + 저장을 한 페이지에서)
- Lv2 `연출` → **AnimatedDrawPage** (연출 후 결과까지 한 페이지에서)
- Lv3 `2D` → **ReadingPage** (shuffle2d 업스트림 후)
- Lv4 `2.5D` → **ReadingPage** (ShufflePage 업스트림 후)

결과 UI (SpreadLayout · 리딩 저장 · "한 장 더" 기능)가 InstantDrawPage / AnimatedDrawPage / ReadingPage 세 곳에 분산되어 있어
Brief 015 (`draw_result_ui_fixes`) 수준의 UI 변경이 세 파일에서 반복되고, 레벨 간 결과 체감이 달라진다.

목표는 **InstantDrawPage를 `DrawResultPage`로 리네임하면서 포괄 결과 페이지 역할로 승격**시키고,
Lv2/3/4는 그 앞단의 "연출/셔플 단계"만 담당하도록 책임을 분리하는 것이다. 결과 표시 로직은 한 곳에서만 유지보수한다.

**명칭 변경 이유**: `Instant`는 Lv1 뽑기 모드명("즉시")과 겹쳐 포괄 결과 페이지의 이름으로 오해 소지. 포괄 책임을 지는 순간 이름도 중립적·포괄적이어야 한다 (이름=진실 원칙). `Reading`은 이미 기록용 엔티티·페이지에 선점되어 충돌, `Draw`는 앱 전반에서 "뽑기" 모드 전체를 지칭하는 상위어로 쓰이고 있어 `DrawResultPage`가 자연스럽다.

## Context

### 현재 파일 · 라우트

| Level | 라우트 | 페이지 | 역할 | 라인 |
|-------|-------|--------|------|------|
| 1 | `/draw/instant` | `InstantDrawPage` → **`/draw/result` / `DrawResultPage`로 리네임 예정** | 셔플(직접 진입) + 결과 렌더 + 저장 | 299 |
| 2 | `/draw/animated` | `AnimatedDrawPage` | 연출 애니메이션 + 결과 렌더 + 저장 | 525 |
| 3/4 | `/intention/:id` | `IntentionPage` | 질문 입력 | 135 |
| 4 | `/shuffle/:id` | `ShufflePage` (Forge2D) | 2.5D 물리 셔플 | 175 |
| 3 | — | (미구현) | 2D 셔플 (Brief 064 명세) | — |
| 3/4 | `/reading/:id` | `ReadingPage` | 결과 렌더 + 저장 + "한 장 더" | 212 |

### 공통 상태 허브

- `shuffleStateProvider` — 셔플 결과(`ShuffleResult`)를 전역으로 보관. 업스트림 페이지가 `setResult()` 후 다운스트림이 `watch()`.
- `readingQuestionProvider` — 의도/질문 문자열. IntentionPage에서 set, 결과 페이지에서 read.
- `readingRepositoryProvider` — 리딩 저장 / 카드 추가 (`saveReading`, `addDrawnCard`).

### 중복 지점

InstantDrawPage · ReadingPage · AnimatedDrawPage 세 파일 모두:
- `SpreadLayout` 위젯으로 결과 카드 렌더 (`instant:240`, `reading:183`, animated도 동일 패턴)
- `readingRepositoryProvider.saveReading()` 호출
- `addDrawnCard()` 호출로 "한 장 더" 지원
- `cardAspectRatioProvider`, `showFaceUp` 등 동일 설정 읽음

### 선행 Brief

- **063** `shuffle_rebuild` — Lv3/Lv4 셔플 단계 리빌딩 (status: completed)
- **064** `experience_level_page_design` — 4레벨 UI/UX 명세 (status: completed)
- **015** `draw_result_ui_fixes` (09_mobile_ui_overhaul) — 최근 Lv1/2 결과 화면 수정 (3건)

본 Brief는 063/064의 흐름 위에서 **결과 페이지 수렴**이라는 새로운 축을 추가한다.

## Boundaries

### In Scope

| # | Item | Description |
|---|------|-------------|
| 1 | **리네임 & 역할 승격** | `InstantDrawPage` → `DrawResultPage`, 파일 `instant_draw_page.dart` → `draw_result_page.dart`, 클래스/상태/import 경로 전역 교체. 역할을 "전 레벨 공용 결과 페이지"로 승격 |
| 2 | 업스트림 결과 전달 규약 통일 | Lv2/3/4 업스트림 페이지가 `shuffleStateProvider`에 결과를 설정한 뒤 `DrawResultPage`로 진입 |
| 3 | AnimatedDrawPage 책임 축소 | 연출 애니메이션만 담당, 완료 시 `DrawResultPage`로 `pushReplacement` |
| 4 | ShufflePage(Lv4) 후단 전환 | 현 `ReadingPage` 내비게이션 → `DrawResultPage`로 변경 |
| 5 | Shuffle2dPage(Lv3, 신규) 후단 | 구현 시 `DrawResultPage`로 수렴 |
| 6 | ReadingPage(draw-time) 제거 | 뽑기 플로우 라우트에서 제외. reading_list/detail은 별개 (유지) |
| 7 | `DrawResultPage` 초기화 분기 | 업스트림 결과 있으면 재사용, 없으면(Lv1 직접 진입) 자체 셔플 실행 |
| 8 | 라우트 리네임 | `/draw/instant` → `/draw/result`, GoRoute name `draw-instant` → `draw-result`. 모든 내비게이션 호출부 교체 |

### Out of Scope

| # | Item | Reason |
|---|------|--------|
| 1 | Lv3 2D 셔플 신규 구현 | Brief 064 후속 작업. 본 Brief는 "수렴 규약"만 정의 |
| 2 | InstantDrawPage 내부 UI 재디자인 | Brief 015에서 최근 정비 완료. 현 UI를 정본으로 차용 |
| 3 | Reading 도메인 엔티티 변경 | 저장 스키마·Reading 모델 불변 |
| 4 | reading_list_page / reading_detail_page | 기록 조회 용도, 뽑기 플로우와 무관 |
| 5 | 다른 페이지/클래스의 리네임 | AnimatedDrawPage, ShufflePage 등은 이름 유지 (역할은 축소되지만 명칭은 그대로 의미를 가짐) |
| 6 | 새 상태 허브 도입 | 기존 `shuffleStateProvider` / `readingQuestionProvider` 재사용 |
| 7 | 디렉터리 재배치 | `features/draw/presentation/pages/` 위치 유지 (Lv2 animated와 동일 디렉터리) |

## Decisions

| # | Decision | Chosen | Rationale | Trade-off | Alternatives Considered |
|---|----------|--------|-----------|-----------|------------------------|
| D1 | 결과 페이지 단일화 방식 | **`InstantDrawPage` → `DrawResultPage`로 리네임 + 공용 결과 페이지로 승격** | `Instant`는 Lv1 모드명("즉시")과 겹쳐 포괄 역할 명칭으로 부적합. 포괄 책임을 지는 순간 이름도 포괄적이어야 후속 작업자 혼동 방지 (이름=진실 원칙). 사용자 확인을 받아 초기 결정 반전 | 파일명·클래스명·import·라우트·모든 호출부 일괄 교체 비용 발생 (1회성, 기계적) | (a) 이름 유지(기각 — Lv1 뉘앙스 혼동). (b) `ReadingResultPage`(기각 — `Reading` 엔티티와 충돌). (c) `TarotResultPage`(기각 — `Tarot*` 프리픽스가 앱 전반에 드묾). (d) `SpreadResultPage`(기각 — 렌더 위젯에 종속) |
| D2 | 업스트림→결과 데이터 전달 | **`shuffleStateProvider` 재사용** (+ `readingQuestionProvider`) | 이미 모든 업스트림 페이지(ShufflePage, AnimatedDrawPage 내부)가 `setResult()`로 결과를 저장하고 있음. 라우트 `extra` 페이로드 없이 전환 가능 | 전역 상태 의존으로 테스트 격리 시 프로바이더 리셋 필요 | 라우트 `extra`로 `ShuffleResult` 전달 — 직렬화 부담 + 현 providers 리셋 로직과 충돌 |
| D3 | `DrawResultPage` 초기화 분기 | **`shuffleStateProvider`가 비어있으면 자체 셔플 실행, 값이 있으면 그대로 사용** | Lv1 직접 진입 시 결과 페이지가 셔플 주체가 되는 현 동작을 유지. Lv2/3/4에서는 이미 업스트림이 결과를 설정한 뒤 진입 → 재셔플 방지 | 최초 build에서 provider 값 기반 분기 로직 추가 (`initState`에서 조건부) | 모드 플래그를 라우트 파라미터로 전달 — D2 전역 상태 방침과 불일치 |
| D4 | AnimatedDrawPage 후단 전환 | **연출 완료 후 `context.pushReplacement('/draw/result')`** | 스택에 AnimatedDrawPage를 남기면 뒤로가기 시 다시 연출 재생되는 어색함. 결과 페이지가 뒤로가기로 홈 복귀되는 것이 자연스러움 | AnimatedDrawPage 내 "저장" / "한 장 더" 기능 제거 → 한 페이지 525라인 중 결과 부분 삭감 필요 | `push` 유지 — 뒤로가기 UX 문제. 같은 페이지에서 인플레이스 교체 — Flutter 관례 벗어남 |
| D5 | ShufflePage(Lv4) 후단 전환 | **카드 선택 완료 시 `/reading/:id` 대신 `/draw/result`로 `pushReplacement`** | ReadingPage 의존을 끊고 결과를 `DrawResultPage`로 일원화. `shuffleStateProvider`는 이미 ShufflePage가 설정 | ReadingPage의 draw-time 경로 폐기 → D7 연동 | ReadingPage 유지 — 수렴 목표 배반 |
| D6 | Shuffle2dPage(Lv3) 후단 전환 | **구현 시 동일하게 `/draw/result`로 `pushReplacement`** | Lv3/4 대칭 유지. Brief 064의 신규 페이지가 본 규약을 따르도록 선행 고정 | Lv3 구현 시점에 본 Brief의 규약 준수 필요 (구현 Brief의 제약으로 전달) | Lv3 전용 결과 페이지 — 규약 분기 유발 |
| D7 | ReadingPage(draw-time) 처리 | **라우트 `/reading/:deckId` 제거 + `reading_page.dart` 삭제** (reading_list/detail은 유지) | draw-time 결과 로직이 `DrawResultPage`에 통합 후 ReadingPage는 dead code. 제거가 혼란 방지 | `addOneMore` 등 ReadingPage 고유 기능이 `DrawResultPage`로 마이그레이션되어야 함 (현재 InstantDrawPage에도 `addDrawnCard` 코드 존재 → 동치 확인 후 통합) | 라우트만 제거하고 파일 보존 — 코드 잔존 시 재발견 위험 |
| D8 | 라우트 네이밍 | **`/draw/instant` → `/draw/result` 리네임**, GoRoute name `draw-instant` → `draw-result` | D1과 일관. 공용 결과 페이지의 경로 의미를 포괄화. Lv1 직접 진입 시에도 의미 부합 | 모든 `context.push('/draw/instant')` 호출부 교체 필요 (home_page 2곳 + router) | `/draw/instant` 유지(기각 — D1과 불일치). 레벨별 라우트(기각 — 수렴 원칙과 모순) |

## Open Questions

(없음 — 1라운드 자율 결정으로 수렴)

| # | Question | Impact | Status |
|---|----------|--------|--------|

## Constraints

- **하위 호환**: 사용자가 이미 저장한 Reading 기록은 그대로 유지되어야 함 (reading_list/detail 동작 불변).
- **프로바이더 수명**: `shuffleStateProvider.clear()` 호출 타이밍이 Lv1 진입과 업스트림 경유 진입에서 달라짐 — InstantDrawPage는 "결과가 이미 있으면 clear 금지"를 지켜야 한다.
- **뒤로가기 UX**: 결과 페이지에서 뒤로가기는 홈으로 복귀해야 함. 중간 단계(연출/셔플)는 스택에 남지 않도록 `pushReplacement` 사용.
- **체험 레벨 분기 (`home_page.dart:32-46`)**: Lv3/Lv4가 현재 동일 라우트(`/intention/:deckId`)로 진입 중 — 본 Brief 후속 구현에서 Lv3 전용 분기 필요(out of scope, Brief 064 책임).
- **리네임 원자성**: MA-0의 리네임 항목은 반드시 단일 커밋에 묶는다. 파일 이동과 라우트 경로 교체가 분리되면 중간 상태에서 앱이 동작하지 않는다 (import 깨짐 / 라우트 mismatch).
- **Brief 064와의 정합**: 064가 정의한 "각 레벨의 UI 경험"은 **중간 단계** 명세이고, 본 Brief는 **최종 결과 페이지** 명세. 두 Brief는 직교.

## Exit Criteria

- [x] Lv1~Lv4 전 흐름이 `/draw/instant`(InstantDrawPage)에서 종료된다는 규약이 문서화됨
- [x] 업스트림 결과 전달 메커니즘(`shuffleStateProvider` 재사용)이 명시됨
- [x] ReadingPage(draw-time) 처리 방침이 결정됨
- [x] 라우트 변경 범위 및 네이밍 결정됨
- [x] Quality Profile 확정: **Showcase**, Priority: **Robustness**

## Ideal Criteria

Quality Profile: **Showcase** · Priority Dimension: **Robustness (안전성)**

밀도: In Scope 항목당 3+ criteria (5축 전체 커버). Robustness 축은 Priority로 1단계 상향 → 항목별 Robustness criteria를 1개 이상 필수 포함.

| # | Criterion | References (In Scope #) | Type | Dimension |
|---|-----------|------------------------|------|-----------|
| 1 | `grep -r "InstantDrawPage\|/draw/instant\|draw-instant" mobile/lib` 결과가 0건이다 | 1, 8 | assertion | Function |
| 2 | 리네임 커밋 체크아웃 직후 `flutter build apk --debug`가 성공한다 (중간 상태 빌드 실패 없음) | 1, 8 | assertion | Robustness |
| 3 | `draw_result_page.dart`의 클래스/파일 상단 docstring이 "Lv1~Lv4 공용 결과 페이지" 역할을 명시한다 | 1 | assertion | Completeness |
| 4 | 리네임 전/후 `flutter test` 결과의 pass/fail 카운트가 동일하다 (회귀 없음) | 1 | assertion | Robustness |
| 5 | Lv2/3/4 업스트림 페이지 모두 DrawResultPage로 내비게이션하기 **직전**에 `shuffleStateProvider.setResult(result)` 호출이 존재한다 (코드 경로 검사) | 2 | assertion | Function |
| 6 | `shuffleStateProvider`가 null인 상태로 DrawResultPage에 진입한 경우(예외 상황) 자체 셔플 fallback이 동작하여 빈 화면/크래시가 발생하지 않는다 | 2, 7 | assertion | Robustness |
| 7 | 업스트림에서 setResult 후 사용자가 즉시 뒤로가기로 이탈한 뒤 다른 모드로 재진입하면, 이전 stale 결과가 재사용되지 않는다 | 2 | assertion | Edge |
| 8 | AnimatedDrawPage에서 `SpreadLayout` / `saveReading` / "한 장 더" UI 블록이 제거되었다 (grep으로 확인) | 3 | assertion | Function |
| 9 | 연출 종료 → DrawResultPage 전환 시 사용자가 보는 카드·질문이 끊김·재애니메이션·깜빡임 없이 이어진다 | 3 | directional | UX |
| 10 | 연출 재생 중 뒤로가기 → 홈 → 재진입 시 `shuffleStateProvider`에 중간 상태가 남지 않는다 (leak 없음) | 3 | assertion | Robustness |
| 11 | ShufflePage(Lv4)의 카드 선택 콜백이 정확히 named route `draw-result`로 `pushReplacement`한다 | 4 | assertion | Function |
| 12 | 카드 선택 도중 센서/Forge2D 예외 발생 시 앱이 크래시하지 않고, 복구 가능하거나 안전하게 홈으로 이탈한다 | 4 | directional | Robustness |
| 13 | ShufflePage에서 DrawResultPage로 전환 후 뒤로가기 시 ShufflePage로 돌아가지 않고 홈으로 복귀한다 | 4 | assertion | UX |
| 14 | Lv3 Shuffle2dPage 구현 Brief/Scope가 본 MA-5 규약 (named route `draw-result` 사용)을 명시적으로 참조한다 | 5 | directional | Completeness |
| 15 | Lv3/Lv4 구현이 동일한 상수/named route 기호로 DrawResultPage를 호출한다 (매직 스트링 중복 없음) | 5 | assertion | Function |
| 16 | `reading_page.dart` 파일과 `/reading/:deckId` GoRoute가 삭제되었다 | 6 | assertion | Function |
| 17 | 삭제 후 `flutter analyze`에 unresolved import 경고가 발생하지 않는다 | 6 | assertion | Robustness |
| 18 | ReadingPage의 `addOneMore`에 해당하는 동작이 DrawResultPage의 `addDrawnCard` 경로로 기능 동치함을 수동 시나리오(3장 → 4장 추가 → 저장 → reading_detail 조회)로 검증한다 | 6 | assertion | Completeness |
| 19 | 기존에 저장된 Reading 기록의 reading_list/detail 조회 동작이 영향받지 않는다 (backward compat) | 6 | assertion | Edge |
| 20 | DrawResultPage의 `initState`에서 `shuffleStateProvider` null 여부 분기가 **단일 지점에서 1회**만 평가된다 (race/중복 셔플 방지) | 7 | assertion | Robustness |
| 21 | Lv1 진입 직후 설정 변경(defaultCardCount)이 자체 셔플의 카드 수에 반영된다 | 7 | assertion | Edge |
| 22 | Lv2/3/4 경로에서 DrawResultPage 진입 직전 OS가 앱을 백그라운드로 전환했다 복귀해도 `shuffleStateProvider` 결과가 보존되어 재셔플이 발생하지 않는다 | 7 | directional | Robustness |
| 23 | DrawResultPage를 리버팟 `overrideWith`로 mock한 위젯 테스트가 가능하다 (상태 주입 격리) | 7 | assertion | Robustness |
| 24 | 기존 홈 화면의 "바로 뽑기" (Lv1) 바로가기가 새 라우트 `/draw/result`로 정상 동작한다 | 8 | assertion | Function |
| 25 | 라우트 리네임이 딥링크·외부 공유 기능(있다면)의 하위 호환 전략과 함께 문서화된다. 없다면 "미사용" 명시 | 8 | directional | Completeness |
| 26 | Lv1~Lv4 전 모드에서 뽑기 → 저장 → reading_list에서 조회까지 end-to-end가 성공한다 (최소 각 레벨 1회 수동) | 1, 2, 4, 5, 6, 7, 8 | assertion | Function |

## Model Anchors

- **MA-0 (리네임 일괄)**: 다음 교체를 **한 커밋 단위**로 수행한다. 부분 적용 금지.
  - 파일: `lib/features/draw/presentation/pages/instant_draw_page.dart` → `draw_result_page.dart`
  - 클래스: `InstantDrawPage` → `DrawResultPage`, 상태 클래스 `_InstantDrawPageState` → `_DrawResultPageState`
  - import: `instant_draw_page.dart`를 참조하는 모든 파일 (최소 `core/router/app_router.dart`, `home_page.dart`) 교체
  - 라우트 경로: `/draw/instant` → `/draw/result`, GoRoute name `draw-instant` → `draw-result`
  - 라우트 호출부: `context.push('/draw/instant')` 등 모든 호출부 교체 (home_page.dart:36, :44 등)

- **MA-1 (결과 페이지 정본)**: `lib/features/draw/presentation/pages/draw_result_page.dart`의 `DrawResultPage` 클래스를 뽑기 결과 페이지의 유일한 정본으로 취급한다. 결과 UI(`SpreadLayout`), 저장(`readingRepositoryProvider.saveReading`), 한 장 더(`addDrawnCard`)는 이 파일에만 존재한다.

- **MA-2 (라우트 수렴)**: `/draw/result`는 Lv1의 진입점이자 Lv2/3/4의 종착점이다. Lv2/3/4 업스트림 페이지는 종료 시 `context.pushReplacementNamed('draw-result')` (또는 `context.pushReplacement('/draw/result')`)를 호출한다.

- **MA-3 (상태 인계)**: 업스트림 페이지는 `DrawResultPage`로 전환하기 직전 반드시 `ref.read(shuffleStateProvider.notifier).setResult(result)`를 완료한다. `readingQuestionProvider`는 `IntentionPage`에서만 set한다. `DrawResultPage`는 `shuffleStateProvider` 초기값이 null일 때만 자체 셔플을 수행한다.

- **MA-4 (AnimatedDrawPage 책임 축소)**: `AnimatedDrawPage`는 애니메이션 연출 + `shuffleStateProvider.setResult()`까지만 수행한다. 내부의 `SpreadLayout` 결과 블록, `saveReading` 호출, 한 장 더 UI는 제거한다. 애니메이션 종료 콜백에서 `pushReplacement('/draw/result')`.

- **MA-5 (ShufflePage 후단)**: `ShufflePage` (Lv4)의 현 내비게이션 타겟 `/reading/:deckId`를 `/draw/result`로 교체한다. 2D 대체 페이지(Lv3)가 신설될 때에도 같은 타겟을 사용한다.

- **MA-6 (ReadingPage 제거)**: `lib/features/reading/presentation/pages/reading_page.dart` 파일과 `app_router.dart`의 `/reading/:deckId` 라우트를 삭제한다. `reading_list_page.dart`, `reading_detail_page.dart` 및 해당 라우트는 **유지한다** (기록 조회용).

- **MA-7 (Home 분기 유지 + 경로만 갱신)**: `home_page.dart`의 `_startDraw` 분기 구조는 유지. Lv1의 타겟만 `/draw/instant` → `/draw/result`로 교체. Lv2→`/draw/animated`, Lv3/4→`/intention/:deckId`는 그대로. Lv3/Lv4 내부 분기는 본 Brief의 관심사가 아니다 (Brief 064 관할).

- **MA-8 (Scope 확장 금지)**: `DrawResultPage` 내부 UI/UX (카드 연출, 성찰 블록 유무, 텍스트 위계)는 변경하지 않는다. 리네임 이전 `InstantDrawPage` 현 구현을 정본으로 삼는다. 추가 UI 요구는 별도 Brief로 분리한다.

- **MA-9 (테스트 격리)**: `DrawResultPage`의 "초기값 null 시 자체 셔플" 분기는 테스트에서 `shuffleStateProvider.overrideWith(...)`로 격리 가능해야 한다. `initState`의 분기 조건은 한 곳에서만 결정되어야 한다 (if-else 1회).

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 0s | 0 |
| 2 | user-ai-exchange | 56s | 309862 |
| 3 | user-ai-exchange | 250s | 953594 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 887s |
| Total Tokens | 1263456 |
| Input Tokens | 38 |
| Output Tokens | 18461 |
| Cache Read | 1180089 |
| Cache Creation | 64868 |
