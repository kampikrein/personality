---
id: "041"
type: scope
title: "의도 설정 배치 옵션 + 뽑기 플로우 구조 정비 (Scope)"
created: 2026-04-21
traces_brief: "040"
complexity: complex
research_needed: false
research_reason: "Brief 040 성숙(8 decisions + Model Anchors); 모든 패턴(Drift v8 마이그레이션, freezed UserSettings, card_size_settings_page UI, reading repository) 기존 존재."
auto_run: true
effort_mode: standard
tdd_mode: true
uncertainty_level: low
intent: >
  의도 입력 위치를 사용자 설정(beforeShuffle/afterDraw/disabled)으로 노출하고 뽑기 플로우를
  단일 진실원(readingQuestionProvider) 위에 정비. 현존 버그(결과 화면 토글 입력이 저장본에
  반영되지 않음) 동시 해결. 별도로 docs/guide/001_draw_flow_guide.md 작성.
summary: >
  4 areas, 4 cycles (data → settings UI → flow integration → guide doc), tail chain 적용.
  Brief 성숙으로 deliberation 우회.
keywords: [draw-flow, intent, settings, drift-migration, routing, structure-guide]
cycles:
  - cycle: 1
    area: "data layer (enum + UserSettings + Drift v9 + Dao + provider method)"
    depends_on: []
    research_needed: false
  - cycle: 2
    area: "settings UI (IntentPlacementSettingsPage + entry)"
    depends_on: [1]
    research_needed: false
  - cycle: 3
    area: "flow integration (router branch + page conditionals + reading.updateQuestion)"
    depends_on: [1]
    research_needed: false
  - cycle: 4
    area: "draw flow guide doc"
    depends_on: [3]
    research_needed: false
---

# 의도 설정 배치 옵션 + 뽑기 플로우 구조 정비 (Scope)

## 작업 목표

Brief 040 참조. 사용자 설정으로 의도 입력 위치 3-way 옵션을 노출하고, 옵션에 따른 라우트/UI/저장
정합성을 단일 진실원으로 정비. 부수적으로 결과 화면 토글 입력의 저장 누락 버그 해결, 가이드 문서 1편.

## 접근 방향

Brief의 Model Anchors를 그대로 이행. 4사이클 분리:
1. **데이터 레이어 먼저** — 다른 모든 사이클의 선행 조건 (enum, UserSettings 필드, v8→v9 마이그레이션, Dao update 메서드, provider 노출).
2. **UI와 플로우 통합 분리** — UI(설정 페이지)와 플로우 분기(라우터/페이지 조건부)는 독립적으로 개발 가능. 병렬은 안 하지만 사이클 분리로 verify 단위 좁힘.
3. **가이드 문서 마지막** — 구현 완료 후 실제 동작을 문서화하여 표류 방지.

대안 검토:
- **2사이클로 압축** (데이터+UI / 플로우+가이드): tdd-red 테스트 단위가 너무 비대해져 verify 오류 격리 어려움. 기각.
- **deliberation 모드 진입**: Brief가 이미 8 decisions + Model Anchors로 아키텍처 확정. 4-에이전트 숙의가 Brief를 재도출할 가능성 높음. HARD-GATE의 "명백한 최선 존재" 조항으로 우회.

## Research 판단

- **판단**: 불필요
- **근거**: Brief 040이 모든 결정을 내렸고, 사용 패턴(Drift 마이그레이션, freezed, Riverpod, GoRouter)이 기존 코드에 존재. 신규 라이브러리·API 없음.
- **파이프라인**: Agent(tdd-red) → Agent(makeplan) → Agent(impl) → Agent(verify), 사이클당 반복, 마지막 사이클 후 [tail] eval → qualify → push → retro

## 영역 식별

| # | 영역 | 주요 파일/모듈 | 설명 |
|---|------|-------------|------|
| 1 | data | `entities/intent_placement.dart` (신규), `entities/user_settings.dart`, `app_database.dart`, `tables/user_settings_table.dart`, `daos/user_settings_dao.dart`, `providers/settings_providers.dart` | enum + Freezed 필드 + Drift v9 + Dao update + provider |
| 2 | settings UI | `pages/intent_placement_settings_page.dart` (신규), `core/router/app_router.dart`, `pages/home_page.dart`(_DrawSettingsPanel) | 3-way 선택 페이지 + 라우트 등록 + DrawSettingsPanel에 진입 행 추가 |
| 3 | flow integration | `pages/home_page.dart`(_startDraw), `pages/deck_selection_page.dart`, `pages/intention_page.dart`, `pages/draw_result_page.dart`, `repositories/reading_repository.dart`, `repositories/reading_repository_impl.dart` | 라우팅 분기 + IntentionPage redirect + DrawResult 조건부 + reading.updateQuestion |
| 4 | guide doc | `docs/guide/001_draw_flow_guide.md` (신규) | 3모드 플로우/코드 진입점/저장 시점 매핑 |

## 의존성 맵

**다이어그램:**
```
        ┌──────────────┐
        │ 1. data layer │  (enum, UserSettings.intentPlacement, Drift v9)
        └───────┬──────┘
                │ provides UserSettings.intentPlacement
        ┌───────┴───────┐
        ▼               ▼
┌──────────────┐  ┌────────────────────┐
│ 2. settings UI│  │ 3. flow integration│
└──────┬───────┘  └─────────┬──────────┘
       │                    │
       └─────────┬──────────┘
                 ▼
        ┌─────────────────┐
        │ 4. guide doc    │  (describes 3 modes' flow/code/storage)
        └─────────────────┘
```

**의존 관계 상세:**

| From | To | 의존 내용 | 근거 |
|------|----|---------|------|
| 2 | 1 | `intentPlacement` 필드 read/write | settings UI는 enum과 repo update 메서드 필요 |
| 3 | 1 | `intentPlacement` 필드 read | 라우팅 분기와 페이지 조건부가 값을 읽음 |
| 4 | 3 | 실제 구현된 플로우 묘사 | 가이드는 작동하는 코드를 문서화 |

## 실행 순서

| 사이클 | 영역 | 선행 조건 | Research | 파이프라인 |
|--------|------|---------|----------|-----------|
| 1 | data layer | 없음 | 불필요 | Agent(tdd-red)→Agent(makeplan)→Agent(impl)→Agent(verify) |
| 2 | settings UI | 사이클 1 | 불필요 | Agent(tdd-red)→Agent(makeplan)→Agent(impl)→Agent(verify) |
| 3 | flow integration | 사이클 1 | 불필요 | Agent(tdd-red)→Agent(makeplan)→Agent(impl)→Agent(verify) |
| 4 | guide doc | 사이클 3 | 불필요 | Agent(makeplan)→Agent(impl)→Agent(verify) (코드 변경 없음 → tdd-red skip) |
| [tail] | eval → qualify → push → retro | 사이클 4 | — | 자동 |

## 변경 대상 파일 (Modified / Reviewed)

**Cycle 1 — Data layer** (confidence: high)
- Modified:
  - `mobile/lib/features/settings/domain/entities/intent_placement.dart` (신규)
  - `mobile/lib/features/settings/domain/entities/user_settings.dart`
  - `mobile/lib/features/settings/domain/entities/user_settings.freezed.dart` (자동 재생성)
  - `mobile/lib/features/settings/domain/entities/user_settings.g.dart` (자동 재생성)
  - `mobile/lib/core/database/tables/user_settings_table.dart`
  - `mobile/lib/core/database/app_database.dart` (schemaVersion 8→9 + onUpgrade step)
  - `mobile/lib/core/database/app_database.g.dart` (자동 재생성)
  - `mobile/lib/core/database/daos/user_settings_dao.dart` (updateIntentPlacement 추가)
  - `mobile/lib/core/database/daos/user_settings_dao.g.dart` (자동 재생성)
  - `mobile/lib/features/settings/domain/repositories/user_settings_repository.dart` (updateIntentPlacement 시그니처)
  - `mobile/lib/features/settings/data/repositories/user_settings_repository_impl.dart`
  - `mobile/lib/features/settings/presentation/providers/settings_providers.dart` (필요 시)
  - 테스트: `mobile/test/features/settings/intent_placement_test.dart` (신규, tdd-red)
- Reviewed:
  - `mobile/lib/features/settings/domain/entities/card_size_preset.dart` (enum 패턴 참조)

**Cycle 2 — Settings UI** (confidence: high)
- Modified:
  - `mobile/lib/features/settings/presentation/pages/intent_placement_settings_page.dart` (신규)
  - `mobile/lib/core/router/app_router.dart` (route 등록)
  - `mobile/lib/features/home/presentation/pages/home_page.dart` (_DrawSettingsPanel에 '의도 입력' 진입 행 추가)
  - 테스트: `mobile/test/features/settings/intent_placement_settings_page_test.dart` (신규, tdd-red)
- Reviewed:
  - `mobile/lib/features/settings/presentation/pages/card_size_settings_page.dart` (UI 패턴)

**Cycle 3 — Flow integration** (confidence: medium — Lv1/2/3/4 분기 처리 필요)
- Modified:
  - `mobile/lib/features/home/presentation/pages/home_page.dart` (_startDraw에서 Lv3/4 분기에 intentPlacement 적용)
  - `mobile/lib/features/deck/presentation/pages/deck_selection_page.dart` (intent 분기)
  - `mobile/lib/features/shuffle/presentation/pages/intention_page.dart` (build 시점 redirect)
  - `mobile/lib/features/draw/presentation/pages/draw_result_page.dart` (질문 박스 조건부 + updateQuestion 호출)
  - `mobile/lib/features/reading/domain/repositories/reading_repository.dart` (updateQuestion 시그니처)
  - `mobile/lib/features/reading/data/repositories/reading_repository_impl.dart`
  - 테스트: `mobile/test/features/draw/intent_placement_flow_test.dart` (신규, tdd-red)
- Reviewed:
  - `mobile/lib/features/draw/presentation/pages/animated_draw_page.dart` (Lv2 경로 — 변경 없음 확인)

**Cycle 4 — Guide doc** (confidence: high, 코드 변경 없음)
- Modified:
  - `docs/guide/001_draw_flow_guide.md` (신규)

**파일 수 합계**: ~22개 (자동 재생성 4개 제외 시 ~18). 다영역이므로 사이클 분리 정당화.

## 사이클별 연구 가이드

(research_needed: false이므로 생략)

## 예상 밖 의존성 대응

- 사이클 3 진행 중 Lv1/2 경로(`/draw/result`, `/draw/animated`)에서 의도 처리에 추가 변경 필요 발견 시:
  - 수정 ≤ 3 파일: 사이클 3 plan에 포함
  - > 3 파일: Scope 업데이트 + 사이클 5 추가
- v8→v9 마이그레이션 대상 컬럼 충돌(우연한 동명 컬럼) 발견 시: 컬럼명 `intent_placement` 그대로 유지하되 사전 grep으로 충돌 확인 (cycle 1 makeplan 단계).

## Brief 정렬 확인

Brief 040 In Scope 7항목 모두 Cycle 1-4에 매핑 완료:
- IS#1 enum + UserSettings 필드 → Cycle 1
- IS#2 설정 페이지 + 진입점 → Cycle 2
- IS#3 라우팅 분기 → Cycle 3 (home_page, deck_selection_page)
- IS#4 IntentionPage redirect → Cycle 3
- IS#5 DrawResultPage 조건부 + updateQuestion → Cycle 3
- IS#6 readingQuestionProvider 라이프사이클 → Cycle 3
- IS#7 가이드 문서 → Cycle 4

Ideal Criteria 10항목은 [tail] qualify에서 측정.
