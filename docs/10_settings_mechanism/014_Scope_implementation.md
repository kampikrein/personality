---
id: "014"
type: scope
title: "설정 정비 구현 — 3사이클"
created: 2026-04-03
traces_brief: "007"
complexity: complex
research_needed: false
research_reason: "R-006 + R-013 완료. 변경 대상, 삽입 지점, 영향도 모두 확정됨"
auto_run: true
effort_mode: standard
tdd_mode: false
uncertainty_level: low
intent: >
  Brief 007의 8개 항목을 3사이클로 구현. GoRouter 정리 → State clear 주입 → 설정 기본값 변경.
  연구 R-013의 권장 순서에 따라 안전한 순서로 실행.
summary: >
  3개 영역, 3개 사이클. research 불필요(R-006+R-013 완료). 권장 순서: GoRouter → clear → defaults.
keywords: [implementation, settings, GoRouter, ShuffleState, experienceLevel, migration]
cycles:
  - cycle: 1
    area: "GoRouter 정리"
    depends_on: []
    research_needed: false
  - cycle: 2
    area: "State clear 주입"
    depends_on: []
    research_needed: false
  - cycle: 3
    area: "설정 기본값 변경"
    depends_on: [2]
    research_needed: false
---

# 설정 정비 구현

## 작업 목표

Brief 007 + Research R-013 기반으로 3사이클 구현:
1. GoRouter redirect/watch 제거 + quickDrawEnabled 토글 UI 제거
2. shuffleState/readingQuestion clear() 주입
3. experienceLevel=3 + spreadType=custom + DB migration

성공 기준: 뽑기 시작 시 이전 결과 미노출, 처음 사용자 Level 3 진입, GoRouter 안정화

## 접근 방향

연구 R-013에서 확정된 정확한 변경 지점을 그대로 적용. 추가 조사 불필요.

## Research 판단
- **판단**: 불필요
- **근거**: R-006(초기 연구) + R-013(영향 평가) 완료. 변경 대상 파일, 라인 번호, 삽입 코드 모두 확정.
- **파이프라인**: Agent(makeplan) → Agent(impl) → Agent(verify) × 3사이클

## 영역 식별

| # | 영역 | Modified 파일 | Reviewed 파일 | Confidence |
|---|------|-------------|-------------|------------|
| 1 | GoRouter 정리 | `app_router.dart`, `settings_page.dart` | `main.dart` | high |
| 2 | State clear 주입 | `instant_draw_page.dart`, `animated_draw_page.dart`, `intention_page.dart`, `shuffle_page.dart` | `reading_page.dart`, `shuffle_providers.dart` | high |
| 3 | 설정 기본값 | `user_settings.dart`, `user_settings_table.dart`, `home_page.dart`, `user_settings_repository_impl.dart` | `settings_providers.dart` | high |

## 의존성 맵

```
사이클 1 (GoRouter) ──── (독립)
사이클 2 (State clear) ──→ 사이클 3 (설정 기본값)
  ↑ clear()가 있어야 Level 3 기본 전환이 안전
```

| From | To | 의존 내용 |
|------|----|---------|
| 사이클 3 | 사이클 2 | Level 3 기본화 전 clear() 필수 (R-013-F1) |

## 실행 순서

| 사이클 | 영역 | 선행 | Research | 파이프라인 |
|--------|------|------|----------|-----------|
| 1 | GoRouter 정리 | 없음 | 불필요 | Agent(makeplan) → Agent(impl) → Agent(verify) |
| 2 | State clear 주입 | 없음 | 불필요 | Agent(makeplan) → Agent(impl) → Agent(verify) |
| 3 | 설정 기본값 변경 | 사이클 2 | 불필요 | Agent(makeplan) → Agent(impl) → Agent(verify) |

## 사이클별 구현 가이드

### 사이클 1: GoRouter 정리
- `app_router.dart`: `ref.watch(userSettingsProvider)` 제거, redirect 블록(39-54행) 삭제, dead import 제거
- `settings_page.dart`: quickDrawEnabled SwitchListTile 제거
- 참조: R-013 Perspective 3, MA-3, MA-6

### 사이클 2: State clear 주입
- `instant_draw_page.dart:_executeDraw()` 선두에 clear() 2줄
- `animated_draw_page.dart:_startDraw()` 선두에 clear() 2줄
- `intention_page.dart:initState(addPostFrameCallback)` — readingQuestion.clear()만
- `shuffle_page.dart:_goToReading()` 선두 — shuffleState.clear()만
- 참조: R-013 Perspective 2, MA-2

### 사이클 3: 설정 기본값 변경
- `user_settings.dart`: @Default(1)→@Default(3), @Default(SpreadType.threeCard)→@Default(SpreadType.custom)
- `user_settings_table.dart`: withDefault(Constant(1))→withDefault(Constant(3)), spreadType 기본값 변경
- `home_page.dart:54`: ?? 1 → ?? 3
- `instant_draw_page.dart:47`, `animated_draw_page.dart:54`: ?? SpreadType.threeCard → ?? SpreadType.custom
- DB migration: schemaVersion 2→3, onUpgrade(from < 3) UPDATE 쿼리
- `build_runner build` 실행
- 참조: R-013 Perspective 1, MA-1, MA-4, MA-5

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
