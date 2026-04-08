---
id: "013"
type: research
title: "설정 정비 사전 영향 평가 — 최종"
created: 2026-04-03
traces_scope: "008"
summary: >
  Brief 007의 6개 변경 항목에 대해 3사이클(9단계) 영향 평가 완료.
  4건 안전 확인, 1건 주의(SpreadType.custom 라벨), 1건 추가 제거(quickDrawEnabled UI) 식별.
  안전한 구현 순서와 삽입 지점을 확정.
keywords: [impact-assessment, experienceLevel, ShuffleState, GoRouter, migration, clear]
---

# 설정 정비 사전 영향 평가

## Research Overview

### Background & Motivation
Brief 007에서 결정된 6개 변경 항목의 구현 전 안전성을 검증하기 위해, 각 항목의 직접 영향 → 연쇄 영향 → 부작용까지 다단계 조사를 수행했다.

### Research Scope
- mobile/ Flutter 앱의 UserSettings, ShuffleState, GoRouter 관련 전체 코드
- 3사이클 × 2~4단계 = 총 9단계 조사

### Related Documents
- Scope: [008_Scope_impact_assessment.md](./008_Scope_impact_assessment.md)
- Brief: [007_Brief_settings_fix.md](./007_Brief_settings_fix.md)
- Agent reports: [009](./009_Agent_defaults_impact.md), [010](./010_Agent_clear_impact.md), [011](./011_Agent_gorouter_impact.md)
- Synthesis: [012_Synthesis_impact.md](./012_Synthesis_impact.md)

---

## Perspective 1: 설정 기본값 변경 (3단계)

### Status Analysis
UserSettings의 3계층(entity @Default, DB withDefault, fallback ??)이 모두 동일한 값을 유지하고 있어 기본값 변경 패턴이 명확하다. 변경 대상 파일 9개.

### Detailed Findings

**L1 — 직접 영향 (변경 대상 전수)**

| 파일 | 위치 | 현재 값 | 변경 값 |
|------|------|--------|--------|
| `user_settings.dart:12` | @Default(1) experienceLevel | 1 | 3 |
| `user_settings.dart:16` | @Default(SpreadType.threeCard) | threeCard | custom |
| `user_settings_table.dart:7-8` | withDefault(Constant(1)) | 1 | 3 |
| `user_settings_table.dart:15-16` | withDefault | threeCard | custom |
| `home_page.dart:54` | ?? 1 | 1 | 3 |
| `instant_draw_page.dart:47` | ?? SpreadType.threeCard | threeCard | custom |
| `animated_draw_page.dart:54` | ?? SpreadType.threeCard | threeCard | custom |
| `user_settings.g.dart:12,17-18` | JSON fallback | 자동 재생성 | build_runner |

**L2 — 연쇄 영향**
- experienceLevel=3 → `_startDraw()` case 3 → ShufflePage가 기본 진입점. **동작 변화 확인됨, 의도된 변경.**
- SpreadType.custom → cardCount가 `_spreadType.cardCount`(=0) 대신 `settings.defaultCardCount`(=3)을 사용. **분기 이미 구현되어 안전.**
- SpreadType.custom → 포지션 라벨이 "지나온 길/현재/가능성" → "카드 1/카드 2/카드 3"으로 변경. **타로 해석 의미 저하 — tarot-expert 협의 권고.**

**L3 — DB migration 부작용**
- schemaVersion 2→3 증가 + `onUpgrade(from < 3)` 블록에 UPDATE 쿼리 추가
- migration 실패 시 앱 crash 없음 (Drift fallback), 설정 UI 오류 상태 고착 가능
- 기존 리딩 데이터의 `spread_type` 컬럼은 `byName()` 매핑으로 완전 호환

### Caveats & Risks
- **[High] SpreadType.custom 라벨**: 기본 포지션 라벨이 generic해짐. tarot-expert와 협의하여 custom용 의미 있는 기본 라벨 설계 필요.
- **[Medium] build_runner 재실행 필수**: entity 변경 후 `dart run build_runner build` 필수.

### Summary
3계층 기본값 변경은 구조적으로 안전하나, SpreadType.custom의 타로 의미 저하가 유일한 High 위험.

---

## Perspective 2: 글로벌 상태 clear() 주입 (2단계)

### Status Analysis
shuffleStateProvider.clear()와 readingQuestionProvider.clear()가 정의되어 있으나 앱 전체에서 호출 0회. 이것이 이전 결과 노출 버그의 근본 원인.

### Detailed Findings

**L1 — 직접 영향 (삽입 지점 확정)**

| 삽입 위치 | 대상 | 안전도 | 근거 |
|----------|------|--------|------|
| `instant_draw_page._executeDraw()` 선두 | shuffle + question | **안전** | _loading=true 중 UI 미노출 |
| `animated_draw_page._startDraw()` 선두 | shuffle + question | **안전** | question은 직후 _questionController에서 재세팅 |
| `intention_page.initState(addPostFrameCallback)` | question만 | **안전** | shuffle clear는 여기 금지 (시나리오 3-A) |
| `shuffle_page._goToReading()` 선두 | shuffle만 | **안전** | 화면 전환 직전, 직후 setResult() |

**L2 — 연쇄 시나리오 판정**

| 시나리오 | 판정 | 위험도 |
|---------|------|--------|
| 완료→홈→뒤로가기 재진입 | go()로 스택 교체, 재진입 불가 | Low |
| 백그라운드→포그라운드 | keepAlive 유지, clear 미호출 | Low |
| IntentionPage에서 shuffle clear | **삽입 금지** — 스택 ReadingPage null 재빌드 | Medium |
| _startDraw() 내 순서 충돌 | 독립 데이터소스, 충돌 없음 | Low |
| +1 한 장 더 중 clear | 해당 경로 없음 | Low |

### Caveats & Risks
- **[Medium] Level 3 삽입 위치 분리**: shuffleState clear는 ShufflePage._goToReading()에, readingQuestion clear는 IntentionPage.initState에 분리 삽입. 동일 함수에 넣으면 안 됨.

### Summary
모든 삽입 지점이 안전 확인됨. Level 3의 삽입 위치 분리만 주의하면 부작용 없음.

---

## Perspective 3: GoRouter redirect 제거 + watch 제거 (4단계)

### Status Analysis
appRouterProvider가 `ref.watch(userSettingsProvider)`로 settings 전체를 구독하여, 설정 변경마다 GoRouter 인스턴스가 재생성되는 구조.

### Detailed Findings

**L1 — 직접 영향**
- watch 제거 → appRouterProvider가 앱 시작 1회만 평가. AutoDispose이지만 `main.dart:89`의 ref.watch가 참조 유지하므로 GC 안 됨.
- redirect 제거 → '/' 진입 시 항상 HomePage 표시.
- 기능 손실: quickDrawEnabled=true 사용자의 "앱 시작 시 바로 뽑기" → 현재 기본=false이므로 영향 없음.

**L2 — 연쇄 영향 (핵심 발견)**
- **quickDrawEnabled가 dead feature가 됨**: 런타임 소비처가 app_router.dart(제거됨)와 settings_page.dart(토글 UI)뿐. redirect 제거 후 토글이 아무 효과 없는 dead feature.
- **settings_page.dart의 quickDrawEnabled 토글 UI 함께 제거 필수**.
- quickDrawEnabled DB 컬럼 자체는 Drift migration 필요하므로 다음 사이클 권고.

**L3 — 네비게이션 안정성**
- `context.go('/')` 3곳: animated_draw_page.dart:225,307, instant_draw_page.dart:175
- **현재 UX 버그 발견**: quickDrawEnabled=true && experienceLevel=3이면 홈 버튼 → redirect → shuffle 페이지 (의도치 않은 루프). redirect 제거가 이 버그를 자동 해소.
- 딥링크 없음, Android 뒤로가기 영향 없음.

**L4 — 성능/안정성**
- 현재: 설정 Slider 드래그 → 연속 DB write → Stream emit → GoRouter 재생성 연쇄
- 변경 후: GoRouter 앱 시작 1회 생성, 이후 불변. 위 연쇄 완전 차단.
- routerConfig 교체 빈도: 매 설정 변경 → 0회. 네비게이션 스택 안정성 대폭 향상.

### Caveats & Risks
- **[High] quickDrawEnabled 토글 UI 제거 필수**: dead feature 방치 시 사용자 혼란.
- **[Low] quickDrawEnabled DB 컬럼**: entity/DB에서 필드 제거는 별도 migration. 이번에는 UI만 제거 권고.

### Summary
redirect + watch 제거는 안전하며, 기존 UX 버그 해소 + 성능 개선 효과. quickDrawEnabled 토글 UI 동시 제거 필수.

---

## Cross-Analysis

### Inter-Perspective Relationships
- 사이클 1의 experienceLevel=3 변경이 redirect 경로를 `/shuffle/{deckId}`로 변경하지만, 사이클 3에서 redirect 자체를 제거하므로 이 연쇄는 무효화됨.
- 사이클 2의 clear() 주입과 사이클 3의 GoRouter 변경은 완전히 독립적.

### Common Patterns
- **3계층 동시 변경**: experienceLevel과 defaultSpreadType 모두 entity+DB+fallback 3계층 패턴. 하나라도 누락하면 불일치 발생.
- **dead code 파생**: redirect 제거 → quickDrawEnabled dead feature. 변경 시 파생 dead code를 추적하는 습관 필요.

### Conflicting Items
- SpreadType.custom 변경(사이클 1)과 타로 체험 품질(사이클 2의 ReadingPage) 간 트레이드오프: 자유도 vs 의미 있는 기본 라벨.

## Comprehensive Conclusion

### 핵심 발견 (우선순위 순)

1. **[Critical] R-013-F1: clear() 삽입 지점 확정** — 4개 삽입 위치 모두 안전 확인. Level 3은 shuffleState와 readingQuestion의 삽입 위치를 분리해야 함. *(관점 2)*

2. **[High] R-013-F2: SpreadType.custom 라벨 의미 저하** — custom 기본 포지션 라벨이 "카드 1/2/3"으로 generic화. tarot-expert 협의 필요. *(관점 1)*

3. **[High] R-013-F3: quickDrawEnabled 토글 UI 제거 필수** — redirect 제거 시 dead feature. settings_page.dart에서 동시 제거 필요. *(관점 3)*

4. **[High] R-013-F4: 기존 UX 버그 자동 해소** — quickDrawEnabled+experienceLevel=3 시 홈→셔플 루프 버그가 redirect 제거로 해결. *(관점 3)*

5. **[Medium] R-013-F5: DB migration schemaVersion 2→3** — UPDATE 쿼리로 기존 행 변경. 실패 시 crash 없으나 설정 고착 가능. *(관점 1)*

6. **[Medium] R-013-F6: Level 3 clear() 위치 분리** — shuffleState=ShufflePage._goToReading(), readingQuestion=IntentionPage.initState. 동일 함수 삽입 금지. *(관점 2)*

7. **[Low] R-013-F7: GoRouter 성능 개선** — 설정 변경마다 재생성 → 앱 시작 1회. Slider 드래그 시 연속 재생성 문제 완전 해소. *(관점 3)*

### 권장 구현 순서

1. **GoRouter 정리** (사이클 3) — redirect 제거 + watch 제거 + quickDrawEnabled 토글 UI 제거. 다른 변경과 독립적이며 기존 버그 해소.
2. **State clear() 주입** (사이클 2) — 뽑기 버그 수정. GoRouter 변경과 독립.
3. **설정 기본값 변경** (사이클 1) — experienceLevel=3 + DB migration. SpreadType.custom은 tarot-expert 협의 후.

## Unresolved Items

- **SpreadType.custom 기본 포지션 라벨 설계**: tarot-expert 협의 필요. "카드 1/2/3" 대신 의미 있는 범용 라벨이 필요한지, 또는 custom 시 사용자가 직접 설정하는 UX가 필요한지.
- **quickDrawEnabled DB 컬럼 제거**: entity/DB 필드 제거는 별도 migration. 이번에는 UI만 제거 권고.

## Referenced File List

| File Path | Cycle | Role |
|-----------|-------|------|
| `settings/domain/entities/user_settings.dart` | 1 | @Default 기본값 |
| `core/database/tables/user_settings_table.dart` | 1 | DB withDefault |
| `home/presentation/pages/home_page.dart` | 1 | fallback ??, _startDraw() |
| `draw/presentation/pages/instant_draw_page.dart` | 1,2 | fallback, clear() 삽입 |
| `draw/presentation/pages/animated_draw_page.dart` | 1,2 | fallback, clear() 삽입 |
| `shuffle/presentation/providers/shuffle_providers.dart` | 2 | ShuffleState.clear() |
| `shuffle/presentation/pages/intention_page.dart` | 2 | ReadingQuestion.clear() |
| `shuffle/presentation/pages/shuffle_page.dart` | 2 | _goToReading() clear 삽입 |
| `reading/presentation/pages/reading_page.dart` | 2 | shuffleState watch, null 가드 |
| `core/router/app_router.dart` | 3 | redirect, watch 제거 |
| `main.dart` | 3 | MaterialApp.router |
| `settings/presentation/pages/settings_page.dart` | 3 | quickDrawEnabled 토글 |
| `settings/presentation/providers/settings_providers.dart` | 1 | userSettingsProvider |

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
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 478862s |
| Total Tokens | 7432515 |
| Input Tokens | 166 |
| Output Tokens | 55553 |
| Cache Read | 6567656 |
| Cache Creation | 809140 |
