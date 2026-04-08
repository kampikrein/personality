---
id: "057"
type: scope
title: "바로 뽑기 — 홈에서 3장 즉시 드로우"
created: 2026-03-18
complexity: simple
research_needed: false
research_reason: "기존 셔플 인프라(Fisher-Yates + Random.secure()) + GoRouter extra 활용, 추가 조사 불필요"
auto_run: true
effort_mode: bypass
uncertainty_level: low
intent: >
  홈 화면의 '셔플 시작' 버튼 위에 '바로 뽑기' 버튼을 추가한다.
  탭하면 셔플 의식 없이 즉시 Fisher-Yates로 덱을 셔플하고
  SpreadType.threeCard(3장: 지나온 길/현재/가능성)로 리딩 페이지에 진입한다.
summary: >
  단일 영역(홈+리딩 UI). 홈 페이지에 바로 뽑기 버튼 추가,
  ReadingPage에 spreadType 파라미터 추가, 라우터에서 extra 전달. 3개 파일 변경.
keywords: [quick-draw, three-card, home-page, reading-page, spread-type]
---

# 바로 뽑기 — 홈에서 3장 즉시 드로우

## 작업 목표
- 홈 화면 '셔플 시작' 버튼 위에 '바로 뽑기' 버튼 추가
- 탭 시: 덱 로드 → Fisher-Yates 셔플 → shuffleState 설정 → 리딩 페이지(threeCard) 이동
- 셔플 의식(센서 수집, 리플 애니메이션) 생략 — 즉시 결과
- 에뮬레이터 검증으로 완성도 확인

## 접근 방향
기존 인프라를 그대로 활용:
- `ShuffleDeckUseCase` + `FisherYatesShuffleStrategy` → 즉시 셔플
- `shuffleStateProvider` → 결과 저장
- `ReadingPage`에 `spreadType` 파라미터 추가 (기본값 single 유지)
- GoRouter `extra`로 SpreadType 전달

## Research 판단
- **판단**: 불필요
- **근거**: 기존 셔플 usecase + 프로바이더 + GoRouter extra — 모두 사용 중인 패턴
- **파이프라인**: S → P → I(V)

## 설계

### 변경 대상 파일

| 파일 | 변경 유형 | 설명 |
|------|----------|------|
| `home_page.dart` | 수정 | '바로 뽑기' 버튼 추가 + 즉시 셔플 로직 |
| `reading_page.dart` | 수정 | spreadType 파라미터 수용, 하드코딩 제거 |
| `app_router.dart` | 수정 | state.extra에서 SpreadType 추출 → ReadingPage에 전달 |

## 체크포인트 & 컨텍스트 관리

| 체크포인트 | 산출물 | 컨텍스트 조치 | 판단 기준 |
|-----------|--------|-------------|----------|
| /scope 완료 | 이 문서 | **유지** | 탐색 파일 = 수정 파일 (높은 overlap) |
| /makeplan 완료 | Plan 문서 | **유지** | plan 읽은 파일 = impl 수정 파일 |
| /implementation 완료 | 커밋 + verify | 완료 | — |

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
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 341150s |
| Total Tokens | 1591534 |
| Input Tokens | 71 |
| Output Tokens | 8834 |
| Cache Read | 1202235 |
| Cache Creation | 380394 |
