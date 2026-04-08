---
id: "005"
type: synthesis
title: "설정 메커니즘 교차 분석"
created: 2026-04-02
summary: >
  3개 관점(데이터 모델, 전파 메커니즘, 뽑기 상태) 교차 분석.
  기본값 불일치(experienceLevel=1→3), 글로벌 상태 미정리, GoRouter 과잉 재생성 3개 핵심 이슈 식별.
---

# 교차 분석

## 공통 패턴: keepAlive: true 글로벌 상태의 생명주기 미관리

| Provider | keepAlive | clear() 존재 | clear() 호출 | 영향 |
|----------|-----------|-------------|-------------|------|
| shuffleStateProvider | true | O | **X (0회)** | 이전 뽑기 결과 잔류 |
| readingQuestionProvider | true | O | **X (0회)** | 이전 질문 잔류 |
| userSettingsRepositoryProvider | true | - | - | 정상 (DB 캐시) |

clear() 메서드를 만들어두고 호출하지 않는 패턴이 반복됨.

## 상충점: GoRouter의 settings watch

- **관점 2**: appRouterProvider가 userSettingsProvider를 watch → 설정 변경마다 GoRouter 재생성
- **관점 1**: userSettingsProvider는 AutoDispose Stream → 빈번한 emit 가능
- **관점 3**: GoRouter 재생성 시 네비게이션 스택 초기화 → 뽑기 중 설정 변경 시 진행 중인 뽑기 소실

이 3개가 결합되면: 설정 페이지에서 슬라이더 드래그 → 연속 DB write → Stream emit → GoRouter 재생성 → 사용자 체감 깜빡임/상태 소실

## 핵심 이슈 3개

1. **[Critical] experienceLevel 기본값 = 1**: 처음 사용자에게 즉시 뽑기(Level 1)가 적용됨. 3이어야 함.
2. **[Critical] 글로벌 상태 미정리**: shuffleState/readingQuestion clear() 미호출로 이전 결과 노출.
3. **[High] GoRouter 과잉 재생성**: settings stream watch로 인한 라우터 불안정.

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
