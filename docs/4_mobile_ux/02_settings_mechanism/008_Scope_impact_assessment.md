---
id: "008"
type: scope
title: "설정 정비 사전 영향 평가 — 3사이클 연구"
created: 2026-04-03
traces_brief: "007"
complexity: complex
research_needed: true
research_reason: "각 변경 항목의 다단계 영향 평가(직접→연쇄→부작용)가 구현 전에 필요"
auto_run: false
effort_mode: standard
tdd_mode: false
uncertainty_level: medium
intent: >
  Brief 007의 6개 In Scope 항목에 대해 구현 전 사전 영향 평가를 수행한다.
  각 항목의 직접 영향 → 연쇄 영향 → 부작용까지 다단계 조사하여 안전한 구현 순서를 확정한다.
summary: >
  3개 영역(설정 기본값, 상태 clear, GoRouter)으로 그룹핑, 3개 사이클.
  연구 깊이: 설정 3단계, 상태 clear 2단계, GoRouter 4단계. 총 9개 연구 단계.
keywords: [impact-assessment, experienceLevel, ShuffleState, GoRouter, migration]
cycles:
  - cycle: 1
    area: "설정 기본값 (Items 1+5+6)"
    depends_on: []
    research_needed: true
  - cycle: 2
    area: "상태 clear (Items 2+3)"
    depends_on: []
    research_needed: true
  - cycle: 3
    area: "GoRouter (Item 4)"
    depends_on: [1]
    research_needed: true
---

# 설정 정비 사전 영향 평가

## 작업 목표

Brief 007의 6개 변경 항목 각각에 대해 **구현 전 사전 영향 평가**를 수행한다.
각 항목의 변경이 코드베이스 전체에 미치는 영향을 다단계로 조사하여,
안전한 구현 순서와 주의사항을 확정한다.

**성공 기준**: 각 사이클의 연구 보고서가 docs/10_settings_mechanism/에 저장됨

## 접근 방향

6개 항목을 **관련성 기준으로 3개 사이클**로 그룹핑하여 효율적으로 연구한다.
각 사이클은 2~4단계 깊이로 조사하되, 복잡도에 비례하여 단계 수를 차등 배정한다.

**통합 판단 근거**:
- Items 1+5+6: 모두 UserSettings 3계층(entity, DB, fallback) 동일 패턴
- Items 2+3: 동일한 provider clear() 삽입 패턴, 동일 삽입 지점
- Item 4: GoRouter는 독립 모듈이지만 설정 기본값 변경(사이클 1) 후 redirect 동작이 달라지므로 사이클 1 이후 수행

## Research 판단

- **판단**: 필요 (전 사이클)
- **근거**: 구현이 아닌 영향 평가가 목적. 각 변경의 연쇄 효과를 코드 레벨에서 추적해야 함.
- **파이프라인**: 사이클별 research → 종합 보고서

## 영역 식별

| # | 영역 | 주요 파일/모듈 | Brief Items | 설명 |
|---|------|-------------|-------------|------|
| 1 | 설정 기본값 | `user_settings.dart`, `user_settings_table.dart`, `home_page.dart`, `*_draw_page.dart` | 1, 5, 6 | experienceLevel=3, DB migration, spreadType=custom |
| 2 | 상태 clear | `shuffle_providers.dart`, `intention_page.dart`, `instant_draw_page.dart`, `animated_draw_page.dart`, `shuffle_page.dart` | 2, 3 | shuffleState/readingQuestion clear() 주입 |
| 3 | GoRouter | `app_router.dart`, `main.dart`, `home_page.dart` | 4 | redirect 제거, settings watch 제거 |

## 의존성 맵

```
사이클 1 (설정 기본값) ─────→ 사이클 3 (GoRouter)
                              ↑ redirect 동작이 기본값에 의존
사이클 2 (상태 clear) ────── (독립)
```

| From | To | 의존 내용 | 근거 |
|------|----|---------|------|
| 사이클 3 | 사이클 1 | redirect가 experienceLevel을 참조하여 경로 결정 | `app_router.dart:46-49` |

## 실행 순서

| 사이클 | 영역 | 선행 조건 | 연구 깊이 | 병렬 가능 |
|--------|------|---------|----------|----------|
| 1 | 설정 기본값 (Items 1+5+6) | 없음 | 3단계 | 사이클 2와 병렬 |
| 2 | 상태 clear (Items 2+3) | 없음 | 2단계 | 사이클 1과 병렬 |
| 3 | GoRouter (Item 4) | 사이클 1 | 4단계 | 순차 |

## 사이클별 연구 가이드

### 사이클 1: 설정 기본값 (3단계)

**L1 — 직접 영향**: experienceLevel, defaultSpreadType, DB withDefault 변경 대상 전수 파악
- `user_settings.dart` @Default 값
- `user_settings_table.dart` withDefault(Constant()) 값
- grep `experienceLevel.*??.*1` / `defaultSpreadType.*??.*threeCard` 패턴 전수
- 변경 대상 파일 목록 + 라인 번호

**L2 — 연쇄 영향**: 변경된 기본값이 참조되는 모든 위치의 동작 변화
- experienceLevel=3일 때 _startDraw() 라우팅 변화 (Level 3 = shuffle 경로)
- SpreadType.custom일 때 cardCount 결정 로직 변화 (정적→동적)
- 홈 페이지 UI 표시 변화 (levelLabel, subtitle 텍스트)

**L3 — DB migration 부작용**: schemaVersion 증가 + 기존 데이터 일관성
- Drift onUpgrade 패턴 확인 (현재 schemaVersion=2)
- UPDATE 쿼리로 기존 행 변경 시 다른 필드 영향 여부
- migration 실패 시 앱 초기화 동작

### 사이클 2: 상태 clear (2단계)

**L1 — 직접 영향**: clear() 삽입 지점 + 호출 시 상태 전이
- `_executeDraw()` (instant), `_startDraw()` (animated) 시작부 삽입
- Level 3: IntentionPage 진입 시 또는 ShufflePage 진입 시 삽입 지점 결정
- clear() 호출 시 state=null → 이후 코드에서 null 체크 경로 확인

**L2 — 연쇄 영향**: clear() 후 시나리오 검증
- 뒤로가기(pop)로 이전 결과 페이지 복귀 시 null 상태 처리
- ReadingPage의 `shuffleResult == null` 분기 (`reading_page.dart:121-126`) 동작
- 앱 백그라운드→포그라운드 전환 시 keepAlive 상태 유지 여부

### 사이클 3: GoRouter (4단계)

**L1 — 직접 영향**: redirect 제거 + watch 제거 시 즉각적 동작 변화
- `app_router.dart:39-54` redirect 블록 삭제 후 '/' 접근 동작
- `ref.watch(userSettingsProvider)` 제거 후 appRouterProvider 동작
- GoRouter가 settings 무관한 순수 라우트 정의로 변환

**L2 — 연쇄 영향**: quickDrawEnabled 의존 코드 + 설정 페이지 동작
- quickDrawEnabled가 UI에서만 참조되는지 (설정 페이지 토글)
- 설정 변경 후 GoRouter 미재생성 시 redirect 미적용 — 의도된 동작인지 확인
- settings_page.dart의 quickDrawEnabled 토글 UI 제거/유지 판단

**L3 — 네비게이션 안정성**: go/push 패턴 + 앱 라이프사이클
- context.go('/') vs context.push() 사용 패턴 전수 조사
- GoRouter 미재생성 시 네비게이션 스택 관리 안정성
- 딥링크/앱 재시작 시 초기 라우트 동작

**L4 — 성능/안정성 비교**: 변경 전후 GoRouter 생성 빈도
- 현재: settings 변경마다 재생성 (슬라이더 드래그 시 다수)
- 변경 후: 앱 시작 시 1회만 생성
- MaterialApp.router의 routerConfig 교체 빈도 변화

### 파일 영향 예측

| 파일 | 사이클 | 카테고리 | Confidence |
|------|--------|---------|------------|
| `user_settings.dart` | 1 | Modified | high |
| `user_settings_table.dart` | 1 | Modified | high |
| `user_settings_repository_impl.dart` | 1 | Modified | high |
| `home_page.dart` | 1 | Reviewed | high |
| `instant_draw_page.dart` | 1,2 | Reviewed | high |
| `animated_draw_page.dart` | 1,2 | Reviewed | high |
| `shuffle_providers.dart` | 2 | Reviewed | high |
| `intention_page.dart` | 2 | Reviewed | high |
| `reading_page.dart` | 2 | Reviewed | high |
| `shuffle_page.dart` | 2 | Reviewed | medium |
| `app_router.dart` | 3 | Modified | high |
| `main.dart` | 3 | Reviewed | medium |
| `settings_page.dart` | 3 | Reviewed | medium |
| `settings_providers.dart` | 1 | Reviewed | high |

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
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 478155s |
| Total Tokens | 6452996 |
| Input Tokens | 156 |
| Output Tokens | 45060 |
| Cache Read | 5621220 |
| Cache Creation | 786560 |
