---
id: "006"
type: research
title: "설정 초기화 & 변경 전파 메커니즘 점검 — 최종"
created: 2026-04-02
summary: >
  처음 사용자 기본 설정과 설정 변경 전파 메커니즘을 3개 관점에서 조사.
  experienceLevel 기본값 1→3 변경 필요, 글로벌 상태 clear() 미호출이 이전 결과 노출 버그의 근본 원인,
  GoRouter의 settings watch가 과잉 재생성을 유발함을 확인.
keywords: [UserSettings, experienceLevel, ShuffleState, GoRouter, Riverpod, 기본값]
---

# 설정 초기화 & 변경 전파 메커니즘 점검

## Research Overview

### Background & Motivation
- "뽑기 시작" 버튼 클릭 시 이전 뽑기 결과가 보이는 버그 보고
- experienceLevel 기본값을 1→3으로 변경 요청 (처음 사용자 = 풀셔플 체험)
- 설정 변경 시 앱 전체 전파 메커니즘 정비 필요

### Research Scope
- mobile/ Flutter 앱의 UserSettings 관련 전체 흐름
- 제외: server/, shared/

### Related Documents
- Checkpoint: [001_Research_settings_mechanism.md](./001_Research_settings_mechanism.md)
- Agent reports: [002](./002_Agent_data_model.md), [003](./003_Agent_propagation.md), [004](./004_Agent_draw_state.md)
- Synthesis: [005_Synthesis_settings.md](./005_Synthesis_settings.md)

---

## Perspective 1: 데이터 모델 & 초기화 흐름

### Status Analysis

UserSettings는 3계층에서 기본값이 정의된다:

| 계층 | 파일 | 메커니즘 |
|------|------|---------|
| Entity | `settings/domain/entities/user_settings.dart:10-18` | `@Default()` (freezed) |
| DB | `settings/data/tables/user_settings_table.dart` | `withDefault(Constant())` |
| Fallback | 각 사용처 | `?? value` |

### Detailed Findings

**현재 기본값 (3계층 모두 일치):**

| 필드 | 기본값 | 비고 |
|------|--------|------|
| experienceLevel | **1** | → 3으로 변경 필요 |
| defaultCardCount | 3 | 적절 |
| selectedDeckId | 'rws-standard' | 적절 |
| showFaceUp | false | 적절 |
| quickDrawEnabled | false | 적절 |
| defaultSpreadType | SpreadType.threeCard | 적절 |

**초기화 패턴**: Lazy init. `watchSettings()` 호출 시 id=1 행 부재 → `_ensureDefaultRow()` INSERT. 별도 seed/migration 없음.

**Fallback 분포** (grep 결과):
- `home_page.dart:54`: `settings?.experienceLevel ?? 1`
- `home_page.dart:56`: `settings?.defaultCardCount ?? 3`
- `home_page.dart:55`: `settings?.selectedDeckId ?? 'rws-standard'`
- `instant_draw_page.dart:47-51`: `?? SpreadType.threeCard`, `?? 3`, `?? 'rws-standard'`
- `animated_draw_page.dart:54-59`: 동일 패턴

**기본값 불일치**: 없음. 3계층 모두 동일 값. 단, experienceLevel이 1인 것이 문제.

### Caveats & Risks
- experienceLevel=1 변경 시 3계층 모두 동시 수정 필요 (entity, DB table, fallback)
- `instant_draw_page._initSettings()`에서 `showFaceUp`을 읽지 않음 — 설계 의도 또는 누락

### Summary
기본값 체계는 잘 통일되어 있으나, experienceLevel=1이 처음 사용자에게 부적절. 3으로 변경 시 3계층 동시 수정 필요.

---

## Perspective 2: 설정 변경 전파 메커니즘

### Status Analysis

설정 전파 체인: **DB (Drift) → Stream → userSettingsProvider (AutoDispose) → ref.watch → UI rebuild**

### Detailed Findings

**Provider 구조:**
- `userSettingsProvider`: `AutoDisposeStreamProvider<UserSettings>` — keepAlive 아님
- `userSettingsRepositoryProvider`: keepAlive: true — DB 접근 캐시

**watch/read 사용처:**

| 파일 | 패턴 | 용도 |
|------|------|------|
| `app_router.dart:35` | `ref.watch` | **GoRouter 재생성 트리거** |
| `home_page.dart:48` | `ref.watch` | 홈 UI 갱신 |
| `settings_page.dart:13` | `ref.watch` | 설정 UI 갱신 |
| `reading_page.dart:109` | `ref.watch` | showFaceUp 실시간 반영 |
| `instant_draw_page.dart:46` | `ref.read` | initState 1회 스냅샷 |
| `animated_draw_page.dart:53` | `ref.read` | initState 1회 스냅샷 |

**GoRouter 과잉 재생성 문제:**
`app_router.dart:34-35`에서 `appRouterProvider`가 `ref.watch(userSettingsProvider)`를 호출:
```dart
@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final settings = ref.watch(userSettingsProvider).valueOrNull;
  return GoRouter(...);
}
```
설정 변경 → Stream emit → provider 갱신 → **GoRouter 인스턴스 교체** → 네비게이션 스택 초기화 위험.

슬라이더 드래그처럼 연속 DB 업데이트 시 GoRouter가 수십 회 재생성될 수 있음.

### Caveats & Risks
- 설정 페이지에서 값 조정 중 GoRouter 재빌드로 깜빡임/상태 소실
- redirect 로직이 GoRouter 재생성 시 매번 재평가
- draw 페이지의 `ref.read` 스냅샷은 GoRouter 재생성 시 새 페이지가 생성되므로 결과적으로 최신 값 반영

### Summary
리액티브 전파 체인은 정상이나, GoRouter가 settings를 watch하여 과잉 재생성되는 구조적 문제 존재. redirect와 결합 시 뽑기 중 설정 변경이 세션을 파괴할 수 있음.

---

## Perspective 3: 뽑기 흐름 상태 관리

### Status Analysis

**이전 결과 노출 버그의 근본 원인 확정**: `shuffleStateProvider.notifier.clear()`가 앱 전체에서 **단 한 번도 호출되지 않음**.

### Detailed Findings

**글로벌 상태 생명주기:**

| Provider | keepAlive | clear() 정의 | clear() 호출 횟수 | 영향 |
|----------|-----------|-------------|-------------------|------|
| shuffleStateProvider | true | `shuffle_providers.dart:60` | **0회** | 이전 뽑기 카드 잔류 |
| readingQuestionProvider | true | `intention_page.dart:22` | **0회** | 이전 질문 잔류 |

**버그 재현 시나리오 (Level 3, 풀셔플):**
1. 홈 → "뽑기 시작" → IntentionPage → ShufflePage → ReadingPage
2. ReadingPage(`reading_page.dart:106`)가 `ref.watch(shuffleStateProvider)` — 정상 표시
3. 홈 버튼(ReadingPage에 없으므로 뒤로가기) → 홈 복귀
4. "뽑기 시작" 재클릭 → IntentionPage
5. **IntentionPage에서 질문 입력 전, ShuffleState에 이전 결과가 남아있음**
6. ShufflePage → ReadingPage 진입 시, 새 셔플이 `setResult()`되기 전 짧은 순간 이전 결과 렌더링

**Level 1/2에서는 다른 패턴:**
- InstantDrawPage/AnimatedDrawPage는 로컬 `_shuffleResult` 사용
- `initState()`에서 새 셔플 실행 → 글로벌 상태 의존 없음
- 단, `quickDrawEnabled` redirect 시 `go()` + 동일 `pageKey` → State 재사용 → `initState()` 미호출 가능성

**quickDrawEnabled + redirect 시나리오:**
1. 뽑기 완료 → 홈 버튼(`context.go('/')`)
2. redirect 발동 → `go('/draw/instant')`
3. `pageKey = ValueKey('/draw/instant')` — 이전과 동일
4. Flutter가 State 재사용 → `initState()` 미호출
5. `_shuffleResult` = 이전 값, `_loading` = false → **이전 결과 즉시 표시**

### Caveats & Risks
- Level 3의 ReadingPage는 글로벌 상태에 100% 의존하여 가장 취약
- quickDrawEnabled=true + Level 1/2는 pageKey 재사용으로 취약
- quickDrawEnabled=false (현재 기본)에서도 Level 3는 글로벌 상태 미정리로 취약

### Summary
clear() 미호출이 근본 원인. Level 3은 항상 취약, Level 1/2는 quickDrawEnabled=true 시 취약.

---

## Cross-Analysis

### Inter-Perspective Relationships
- **관점 1 ↔ 관점 3**: experienceLevel=1 기본값은 Level 1(즉시 뽑기)을 의미. Level 1은 로컬 상태를 쓰므로 글로벌 상태 버그에 덜 노출. 기본값을 3으로 바꾸면 Level 3(ReadingPage 글로벌 상태 의존)이 기본이 되어 버그 노출 빈도 증가.
- **관점 2 ↔ 관점 3**: GoRouter 과잉 재생성은 뽑기 중 설정 변경 시 세션 파괴. 그러나 설정 페이지와 뽑기 페이지가 동시에 열리지 않으므로 실제 위험도는 중간.
- **관점 1 ↔ 관점 2**: experienceLevel 변경 → Stream emit → GoRouter 재생성. 설정 페이지에서 레벨 변경 즉시 라우터가 재빌드되지만, 사용자가 설정 페이지에 있으므로 redirect가 발동하지 않음 (`state.matchedLocation != '/'` 가드).

### Common Patterns
- **keepAlive: true + clear() 미호출**: shuffleState, readingQuestion 모두 동일 패턴
- **ref.read 스냅샷 고착**: draw 페이지들이 initState에서 1회만 설정을 읽어 이후 변경 미반영 (의도된 설계)

### Conflicting Items
- GoRouter의 settings watch: 설정 변경 즉시 반영(좋음) vs 과잉 재생성(나쁨). 트레이드오프.

## Comprehensive Conclusion

### 핵심 발견 (우선순위 순)

1. **[Critical] R-006-F1: experienceLevel 기본값 = 1** — 처음 사용자에게 즉시 뽑기(Level 1)가 적용됨. 3(풀셔플)이어야 함. entity(@Default), DB(withDefault), fallback(??) 3계층 동시 수정 필요. *(관점 1)*

2. **[Critical] R-006-F2: shuffleStateProvider.clear() 미호출** — keepAlive: true인 글로벌 셔플 상태가 뽑기 간에 정리되지 않음. ReadingPage가 이 상태를 watch하므로 이전 결과가 노출됨. 앱 전체에서 clear() 호출 0회. *(관점 3)*

3. **[Critical] R-006-F3: readingQuestionProvider.clear() 미호출** — 동일 패턴. 이전 질문이 새 리딩에 잔류. *(관점 3)*

4. **[High] R-006-F4: GoRouter 과잉 재생성** — appRouterProvider가 userSettingsProvider를 watch하여 설정 변경마다 GoRouter 인스턴스 교체. 슬라이더 드래그 시 연속 재생성 가능. *(관점 2)*

5. **[High] R-006-F5: quickDrawEnabled + pageKey 재사용** — redirect로 동일 경로 재진입 시 Flutter State 재사용 → initState() 미호출 → 이전 결과 표시. 현재 quickDrawEnabled 기본값=false이므로 즉시 영향은 제한적. *(관점 3)*

6. **[Medium] R-006-F6: InstantDrawPage showFaceUp 미참조** — 즉시 뽑기 페이지가 showFaceUp 설정을 읽지 않음. 설계 의도인지 누락인지 확인 필요. *(관점 1)*

## Unresolved Items

- GoRouter 과잉 재생성의 실제 사용자 체감 영향도 (슬라이더 드래그 테스트 필요)
- quickDrawEnabled=true 활성화 시 pageKey 재사용 버그의 실제 재현 여부 (현재 기본=false)

## Referenced File List

| File Path | Related Perspective | Role/Content |
|-----------|-------------------|--------------|
| `mobile/lib/features/settings/domain/entities/user_settings.dart` | 관점 1 | UserSettings entity, @Default 기본값 |
| `mobile/lib/features/settings/data/tables/user_settings_table.dart` | 관점 1 | DB 테이블 스키마, withDefault |
| `mobile/lib/features/settings/data/repositories/user_settings_repository_impl.dart` | 관점 1 | _ensureDefaultRow lazy init |
| `mobile/lib/features/settings/presentation/providers/settings_providers.dart` | 관점 1,2 | userSettingsProvider 정의 |
| `mobile/lib/core/router/app_router.dart` | 관점 2,3 | GoRouter, redirect, pageKey |
| `mobile/lib/features/shuffle/presentation/providers/shuffle_providers.dart` | 관점 3 | ShuffleState keepAlive, clear() |
| `mobile/lib/features/shuffle/presentation/pages/intention_page.dart` | 관점 3 | ReadingQuestion keepAlive, clear() |
| `mobile/lib/features/draw/presentation/pages/instant_draw_page.dart` | 관점 1,3 | Level 1 뽑기, 로컬 상태 |
| `mobile/lib/features/draw/presentation/pages/animated_draw_page.dart` | 관점 1,3 | Level 2 뽑기, 로컬 상태 |
| `mobile/lib/features/reading/presentation/pages/reading_page.dart` | 관점 3 | Level 3 결과, 글로벌 상태 watch |
| `mobile/lib/features/home/presentation/pages/home_page.dart` | 관점 1,2 | 홈 허브, fallback 값 |
| `mobile/lib/main.dart` | 관점 2 | MaterialApp.router 주입 |

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
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 385871s |
| Total Tokens | 4253170 |
| Input Tokens | 135 |
| Output Tokens | 31938 |
| Cache Read | 3624819 |
| Cache Creation | 596278 |
