---
id: "001"
type: research
title: "설정 초기화 & 변경 전파 메커니즘 점검"
created: 2026-04-02
status: completed
summary: >
  처음 사용자 기본 설정(experienceLevel=3)과 설정 변경 시 앱 동작 반영 메커니즘을 점검한다.
  뽑기 시작 시 이전 결과가 보이는 버그의 근본 원인을 추적한다.
keywords: [UserSettings, experienceLevel, Riverpod, ShuffleState, GoRouter, 기본값]
parallel_plan:
  total_perspectives: 3
  phases:
    - phase: 1
      perspectives: [1, 2, 3]
      status: completed
      agent_numbers: ["002", "003", "004"]
  synthesis_number: "005"
  final_number: "006"
---

# 설정 초기화 & 변경 전파 메커니즘 점검

## Research Overview

### Background & Motivation
- 사용자가 "뽑기 시작" 버튼을 누르면 이전 뽑기 결과가 보이는 버그 보고
- experienceLevel 기본값이 1인데 3이어야 함 (처음 사용자 = 풀셔플 체험)
- 설정 변경 시 앱 전체에 올바르게 전파되는지 점검 필요

### Research Scope
- mobile/ Flutter 앱의 UserSettings 관련 전체 흐름
- 제외: server/, shared/, docs/

### Research Perspectives
1. **데이터 모델 & 초기화 흐름** — UserSettings entity, DB 테이블, 기본값, 최초 실행 시드
2. **설정 변경 전파 메커니즘** — Riverpod provider 구조, watch/read 패턴, 라우터 재빌드
3. **뽑기 흐름 상태 관리** — ShuffleState 생명주기, 뽑기 간 상태 리셋, 이전 결과 표시 버그

## Parallel Execution Instructions

### Perspective 1: 데이터 모델 & 초기화 흐름
- `mobile/lib/features/settings/` 전체 탐색
- UserSettings entity: 필드 목록, 기본값, DB 테이블 스키마
- 최초 실행 시 설정이 어떻게 생성되는지 (seed/migration)
- experienceLevel 기본값이 어디서 정의되고 어디서 사용되는지
- quickDrawEnabled 기본값과 의미

### Perspective 2: 설정 변경 전파 메커니즘
- `settings_providers.dart` — userSettingsProvider 구조, keepAlive, watch 패턴
- 설정 변경 시 provider → UI 전파 경로
- `app_router.dart` — appRouter provider가 settings를 watch하는 구조
- GoRouter가 settings 변경 시 재생성되는지, 부작용은 없는지
- redirect 로직과 quickDrawEnabled의 상호작용

### Perspective 3: 뽑기 흐름 상태 관리
- `shuffle_providers.dart` — ShuffleState, keepAlive: true의 영향
- 뽑기 시작 → 결과 표시 → 홈 복귀 → 재뽑기 전체 흐름 추적
- Level 1/2/3 각각의 상태 초기화 시점
- ReadingPage가 shuffleStateProvider를 watch하는 패턴
- GoRouter pageKey 재사용으로 인한 State 미갱신 가능성
- readingQuestionProvider 잔류 상태 문제

## Remaining Work
- [ ] Perspective 1: 데이터 모델 & 초기화 흐름
- [ ] Perspective 2: 설정 변경 전파 메커니즘
- [ ] Perspective 3: 뽑기 흐름 상태 관리
- [ ] Cross-Analysis
- [ ] Comprehensive Conclusion

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
