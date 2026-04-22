---
id: "040"
type: brief
title: "의도 설정 배치 옵션 + 뽑기 플로우 구조 정비"
created: 2026-04-21
status: completed
quality_profile: standard
deep_critique: false
critique_docs: []
summary: >
  현재 뽑기 플로우의 '의도(질문) 입력'은 IntentionPage(셔플 전)와 DrawResultPage(결과 화면 토글)
  두 곳에 중복 존재하며 저장 시점이 어긋나 충돌한다. 사용자 설정으로 '뽑기 전 입력 / 뽑은 후
  입력 / 비활성' 3-way 옵션을 노출하고, 옵션에 따라 라우트 분기와 UI 노출을 단일 진실원으로
  정비한다. 별도로 docs/guide/001_draw_flow_guide.md 가이드를 작성한다.
keywords: [draw-flow, intent, settings, routing, intention, structure-guide]
---

# 의도 설정 배치 옵션 + 뽑기 플로우 구조 정비

## Intent

사용자가 카드 뽑기 시 '의도/질문 입력'이 언제 끼어드는지를 본인 취향에 맞게 선택할 수 있게 한다.
현재는 셔플 직전에 강제로 의도 입력 화면(`IntentionPage`)을 거치고, 결과 화면(`DrawResultPage`)
에도 같은 입력 박스가 토글로 또 존재한다. 사용자에 따라 (a) 의식처럼 미리 정리하고 들어가는 흐름,
(b) 카드를 먼저 보고 떠오른 질문을 적는 흐름, (c) 의도 없이 빠르게 뽑는 흐름을 선호하므로,
이를 설정 메뉴의 1-tap 선택지로 노출하고 플로우가 옵션에 따라 깔끔하게 분기되도록 정비한다.

## Context

**의도 입력 위치 (현재)**:
- `mobile/lib/features/shuffle/presentation/pages/intention_page.dart` — 셔플 전 풀 화면, 텍스트 입력 후 `readingQuestionProvider`에 저장하고 `/shuffle`로 push
- `mobile/lib/features/draw/presentation/pages/draw_result_page.dart:175-206` — 결과 화면 상단 collapsible 입력 박스 ("질문이 있으신가요? (선택)")

**라우팅 (현재)**:
- `mobile/lib/core/router/app_router.dart:121-156` — `/deck` → `/intention/:deckId` → `/shuffle/:deckId` → `/draw/animated` | `/draw/result`
- IntentionPage 스킵 경로 없음. 모든 뽑기는 IntentionPage를 통과한다.

**상태 / 저장**:
- `readingQuestionProvider` (intention_page.dart:18-25) — 의도 입력 단일 소스. `keepAlive`로 셔플~결과 사이 유지.
- `DrawResultPage._autoSave()` (draw_result_page.dart:112-130) — 카드 공개 직후 reading을 자동 저장. 이 시점의 `_questionController.text`만 reading.question으로 들어감. 결과 화면 토글 입력은 `_autoSave` 이후에 입력되므로 **저장본에 반영되지 않는 충돌이 이미 존재**.

**설정 인프라**:
- `mobile/lib/features/settings/domain/entities/user_settings.dart` — Freezed 엔티티. 신규 필드 추가는 freezed 재생성 + Drift 마이그레이션 필요.
- `mobile/lib/core/database/tables/user_settings_table.dart` — 현재 v8 (최근 cycle3에서 v7→v8 진행).
- 설정 페이지 `settings_page.dart` — 현재 placeholder ("환경설정 영역이 준비 중"). 실제 설정 UI는 `card_size_settings_page.dart` 패턴 참고.

**관련 선행 작업**:
- `docs/4_mobile_ux/02_settings_mechanism/018_Scope_user_draw_menu_split.md` — 사용자/뽑기 메뉴 분리 진행 중. 이 Brief의 설정 항목은 '뽑기 메뉴' 측 설정으로 배치한다.

## Boundaries

### In Scope
| # | Item | Description |
|---|------|-------------|
| 1 | `IntentPlacement` enum + `UserSettings` 필드 추가 | `beforeShuffle` / `afterDraw` / `disabled` 3값. Freezed 재생성, Drift 마이그레이션 v8→v9. |
| 2 | 설정 페이지 진입점 + 옵션 선택 UI | 뽑기 설정 영역에 카드/리스트 형태로 3-way 선택 노출. `card_size_settings_page.dart` 패턴 차용. |
| 3 | 뽑기 라우팅 분기 | `disabled` / `afterDraw` 시 `/intention/:deckId` 스킵, deck/home에서 직접 `/shuffle/:deckId`로 push. |
| 4 | `IntentionPage` 노출 조건 | `beforeShuffle`일 때만 라우트로 도달. 다른 모드에서 직접 URL 진입 시 즉시 shuffle로 redirect. |
| 5 | `DrawResultPage` 토글 입력 노출 조건 + 저장 정합성 | `afterDraw`일 때만 입력 박스 표시. 입력 시 저장된 reading.question 업데이트(`updateReadingQuestion`). `disabled`/`beforeShuffle`에서는 박스 자체 숨김. |
| 6 | `readingQuestionProvider` 라이프사이클 정비 | 모드 전환 시 단일 소스 유지. `beforeShuffle`은 IntentionPage가 set, `afterDraw`는 DrawResultPage가 set, `disabled`는 항상 빈 문자열. |
| 7 | 가이드 문서 | `docs/guide/001_draw_flow_guide.md` — 3가지 모드별 플로우 다이어그램 + 의사결정 트리 + 코드 진입점 매핑. |

### Out of Scope
| # | Item | Reason |
|---|------|--------|
| 1 | 의도/질문 자체의 LLM 활용 (질문 추천, 자동 보강) | AI 기능은 별도 토픽 (`docs/5_ai/`) |
| 2 | 뽑기 모드(`ShuffleMode`)별 의도 입력 차별화 | 현재 모드는 모두 동일하게 처리. 향후 필요 시 별도 Brief. |
| 3 | 의도 입력 다국어/i18n | 앱 전체 i18n 미도입. 별도 토픽. |
| 4 | 의도 텍스트 길이 제한, 검열, 저장 형식 변경 | 현재 동작 유지. |
| 5 | 사용자/뽑기 메뉴 분리 자체 | `018_Scope_user_draw_menu_split.md`에서 진행 중인 별도 작업. 본 Brief는 그 산출물의 '뽑기 설정' 영역에 항목 추가만 담당. |

## Decisions

| # | Decision | Chosen | Rationale | Trade-off | Alternatives Considered |
|---|----------|--------|-----------|-----------|------------------------|
| 1 | 토픽 폴더 위치 | `docs/2_tarot_draw/03_draw_experience_settings/` | 본 작업은 '뽑기 경험'의 일부(의도 입력 위치). 동일 토픽에 cycle1~6의 layout/settings 작업이 누적되어 있어 컨텍스트 응집성이 가장 높다. | `4_mobile_ux/02_settings_mechanism`이 설정 인프라 측면에서 더 가까울 수 있으나, 사용자 가시 변화의 본질이 '뽑기 흐름'이라 2_tarot_draw 우선. | `4_mobile_ux/02_settings_mechanism` (설정 메뉴 추가 측면), 신규 토픽 폴더 (응집성 손상으로 기각) |
| 2 | 옵션 enum 형태 | 3값 enum: `beforeShuffle` / `afterDraw` / `disabled` | 사용자가 명시한 3가지 분기와 1:1 매핑. bool 2개(`enabled` + `placement`)보다 invalid state(disabled+beforeShuffle 등) 차단. | enum 재명명/추가 시 마이그레이션 필요. 다만 의도 입력 위치는 본질상 '시점' 축이라 확장 시에도 enum이 적합. | bool 2개 조합 (invalid state 발생), 자유 문자열 (타입 안전성 손실) |
| 3 | 기본값 | `beforeShuffle` | 현재 동작과 동일 → 기존 사용자 회귀 0. 의식적·명상적 톤이 앱 전반의 디자인 언어(`MysticalScaffold`, kGold)와 정합. | 빠른 진입을 선호하는 사용자는 첫 사용 후 설정 변경 필요. 그러나 마이그레이션 시 기존 사용자 보호가 우선. | `disabled` (회귀 발생), `afterDraw` (현재와 다른 톤, 회귀) |
| 4 | 단일 진실 원칙 | `readingQuestionProvider`만이 의도 텍스트의 source of truth. UI 위치만 모드에 따라 변하고, 데이터 경로는 하나. | 두 입력 지점이 같은 provider를 set/clear하므로 충돌 시 추적 1곳. `_autoSave` 시점 정합성을 명시적으로 다룰 수 있음. | provider를 두 개로 분리하면 어느 쪽이 reading.question에 들어가는지 분기 로직이 흩어진다. | provider 2개 분리 (저장 시 어느 값 우선인지 분기 필요), 직접 `_questionController` 참조 (테스트성 손실) |
| 5 | `afterDraw` 모드의 저장 정합성 | reading은 `_autoSave` 시점에 question 없이 일단 저장 → 사용자가 입력 박스에 적으면 `readingRepository.updateQuestion(readingId, text)` 호출로 갱신. | 결과 화면 입력이 저장본에 반영되지 않는 현존 버그를 본 작업에서 해결. | reading의 첫 저장이 question 없는 상태로 잠깐 존재. 사용자가 결과 화면을 즉시 떠나면 question 없는 reading이 남는다 — 이는 `afterDraw` 의미상 허용 가능(질문은 선택). | `_autoSave`를 입력 박스 blur 후로 지연 (사용자 화면 이탈 시 저장 누락 위험), question 강제 입력 (UX 강압) |
| 6 | 라우팅 분기 위치 | deck 선택 후 다음 라우트 결정 직전(home_page / deck_selection_page의 navigation 콜백)에서 `userSettings.intentPlacement`를 읽어 분기. | 라우트 정의(`app_router.dart`)에 조건 분기를 넣지 않음으로써 라우트 정의는 선언적으로 유지. | navigation 콜백이 ref.read 의존성을 갖게 됨. | `app_router.dart`에 redirect 로직 (라우트 정의 복잡도 증가), `IntentionPage` 내부에서 build 시 redirect (한 프레임 깜빡임 발생) |
| 7 | 가이드 문서 위치 | 사용자 지시대로 `docs/guide/001_draw_flow_guide.md` 신규 생성 | 사용자가 명시. 기존 `docs/{N_카테고리}/{NN_토픽}/` 규칙의 예외이지만, 'guide'는 카테고리 횡단 참조용으로 적합. | docs 트리 규칙에서 벗어남 → 추후 다른 가이드 누적 시 정렬/번호 규칙 정의 필요. | `docs/0_platform_meta/` 하위 (사용자 지시와 다름) |
| 8 | 마이그레이션 전략 | Drift v8→v9. 신규 컬럼 `intent_placement TEXT NOT NULL DEFAULT 'beforeShuffle'`. | 기본값으로 기존 사용자 회귀 차단. cycle3에서 동일 패턴(v7→v8) 검증됨. | 마이그레이션 1회 추가. | nullable 컬럼 (UI에서 null 핸들링 분기 추가 필요) |

## Open Questions

| # | Question | Impact | Status |
|---|----------|--------|--------|
| — | (없음 — 모든 결정 자율 처리됨) | — | — |

## Constraints

- **Drift schemaVersion 증가** 필요 (v8 → v9). `user_settings_table.dart` 수정 + migration step 추가.
- **Freezed 재생성**: `user_settings.dart` 수정 후 `flutter pub run build_runner build --delete-conflicting-outputs` 실행.
- **빌드 검증 필수**: CLAUDE.md 정책상 `flutter build apk --debug` 성공 후에만 완료 보고.
- **회귀 차단**: 기존 reading 데이터 / 기존 사용자 플로우(IntentionPage 거치는) 동일하게 유지.
- **저작권/콘텐츠**: 의도 입력 placeholder/안내 문구는 기존 톤(`잠시 눈을 감고...`) 유지.

## Exit Criteria

- 설정 메뉴에서 3가지 옵션 중 하나를 선택 → 즉시 다음 뽑기부터 반영.
- `beforeShuffle`: 현재 동작과 동일.
- `afterDraw`: deck → shuffle → result 직행, 결과 화면 토글 입력 시 reading.question 갱신.
- `disabled`: deck → shuffle → result 직행, 결과 화면 입력 박스 미노출, reading.question = null.
- `docs/guide/001_draw_flow_guide.md` 작성 완료, 3가지 모드 플로우와 코드 진입점 매핑 포함.
- `flutter build apk --debug` 성공.

## Ideal Criteria

Quality Profile: **standard**
Priority Dimensions: 없음 (자율 추론 — 일반 기능 추가 + 가이드 문서, 회귀 위험 있는 마이그레이션 포함)

| # | Criterion | References (In Scope #) | Type | Dimension |
|---|-----------|------------------------|------|-----------|
| 1 | `IntentPlacement` enum 3값이 정의되고 `UserSettings`에 필드로 노출되며 Freezed/JSON 직렬화가 동작한다 | In Scope #1 | assertion | Function |
| 2 | Drift v8→v9 마이그레이션이 기존 row를 잃지 않고 `intent_placement = 'beforeShuffle'`으로 채운다 | In Scope #1 | assertion | Robustness |
| 3 | 설정 페이지에서 3가지 옵션을 선택할 수 있으며 변경 즉시 `userSettingsProvider`에 반영된다 | In Scope #2 | assertion | Function |
| 4 | 옵션 선택 UI가 현재/미선택 상태를 시각적으로 명확히 구분한다 (selected indicator + 설명 텍스트) | In Scope #2 | directional | UX |
| 5 | `afterDraw` / `disabled` 모드에서 deck 선택 후 IntentionPage를 거치지 않고 shuffle로 직행한다 | In Scope #3 | assertion | Function |
| 6 | 직접 URL로 `/intention/:deckId`에 진입해도 모드가 `beforeShuffle`이 아니면 한 프레임 깜빡임 없이 redirect된다 | In Scope #4 | assertion | Edge |
| 7 | `afterDraw` 모드에서 결과 화면 입력 박스에 텍스트 입력 시 저장된 reading.question이 갱신된다 (DB 확인 가능) | In Scope #5 | assertion | Function |
| 8 | `disabled` 모드에서 결과 화면에 입력 박스가 렌더링되지 않으며 reading.question은 null로 저장된다 | In Scope #5 | assertion | Edge |
| 9 | `readingQuestionProvider`의 set/clear가 모드 전환 시 일관되게 동작 (이전 모드 잔존값 누출 없음) | In Scope #6 | assertion | Robustness |
| 10 | `docs/guide/001_draw_flow_guide.md`가 3가지 모드의 라우트/상태/저장 시점을 한 페이지에서 비교 가능하게 보여준다 | In Scope #7 | directional | Completeness |

## Model Anchors

- **`IntentPlacement` enum 위치**: `mobile/lib/features/settings/domain/entities/intent_placement.dart` 신규 파일. 값: `beforeShuffle`, `afterDraw`, `disabled`. JSON serializable.
- **UserSettings 필드 추가**: `user_settings.dart`의 freezed 생성자에 `@Default(IntentPlacement.beforeShuffle) IntentPlacement intentPlacement` 추가. Freezed 재생성 필수.
- **마이그레이션**: `mobile/lib/core/database/database.dart`(또는 동등 위치)의 `schemaVersion`을 8→9. `onUpgrade` step에 `ALTER TABLE user_settings ADD COLUMN intent_placement TEXT NOT NULL DEFAULT 'beforeShuffle'` 추가.
- **설정 UI**: `card_size_settings_page.dart` 구조 차용. 라우트 `/settings/intent-placement` 신규 추가. `settings_page.dart`(현재 placeholder)에 진입 항목 추가하되, `018_Scope_user_draw_menu_split.md` 결과의 '뽑기 설정' 페이지로 분리되면 그쪽에 배치.
- **라우팅 분기**: `home_page.dart` 및 `deck_selection_page.dart`에서 deck 선택 후 navigation 시점에 `ref.read(userSettingsProvider).valueOrNull?.intentPlacement` 읽어 분기. `beforeShuffle`이면 `/intention/:deckId`, 그 외는 `/shuffle/:deckId` 직행.
- **IntentionPage redirect**: `IntentionPage.build` 첫 줄에서 `intentPlacement != beforeShuffle`이면 `WidgetsBinding.instance.addPostFrameCallback`으로 `context.pushReplacementNamed('shuffle', ...)`. 한 프레임 빈 화면 노출 방지를 위해 첫 빌드에서 `const SizedBox.shrink()` 반환.
- **DrawResultPage 입력 박스 노출 조건**: `_questionExpanded` 토글 자체를 `intentPlacement == afterDraw`일 때만 렌더. 다른 모드에서는 토글/입력 모두 미렌더.
- **저장 정합성**: `_autoSave`는 모든 모드에서 동일하게 카드 공개 직후 실행. `afterDraw` 모드는 `_questionController.onChanged`(또는 onSubmitted/디바운스) 시 `readingRepository.updateQuestion(readingId, text)` 호출. 신규 메서드 추가 필요 시 `reading_repository.dart`에 `Future<void> updateQuestion(String readingId, String? question)` 정의.
- **`readingQuestionProvider` 정책**: `beforeShuffle`에서 IntentionPage가 set, ShufflePage/AnimatedDraw가 read-only 참조, ResultPage `_autoSave`에서 reading.question으로 카피 후 clear. `afterDraw`에서는 IntentionPage를 거치지 않으므로 항상 빈 문자열에서 시작, ResultPage 입력 박스가 set, `_autoSave`는 question = null로 reading 저장 후 입력 시 update. `disabled`에서는 항상 빈 문자열, reading.question = null 고정.
- **가이드 문서 형식**: `docs/guide/001_draw_flow_guide.md` 작성. 3가지 모드 각각: (1) Mermaid flow diagram (deck → ?? → result), (2) 코드 진입점 표 (라우트 / 페이지 / provider 호출), (3) 저장 시점 명시. 마지막에 '의사결정 트리' 섹션으로 어떤 사용자에게 어떤 모드를 권하는지 1줄씩.
- **빌드 검증**: 구현 완료 후 `cd mobile && flutter build apk --debug` 실행하여 성공 확인. Freezed/Drift 코드 생성 누락 시 `flutter pub run build_runner build --delete-conflicting-outputs` 선행.

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
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 2176s |
| Total Tokens | 462019 |
| Input Tokens | 18 |
| Output Tokens | 12447 |
| Cache Read | 391070 |
| Cache Creation | 58484 |
