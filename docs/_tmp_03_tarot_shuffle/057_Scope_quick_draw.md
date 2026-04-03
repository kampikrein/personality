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
