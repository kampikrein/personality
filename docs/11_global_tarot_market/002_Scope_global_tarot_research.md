---
id: "002"
type: scope
title: "글로벌 타로 앱 시장 조사 — Research Phase"
created: 2026-04-06
traces_brief: "001"
complexity: complex
research_needed: true
research_reason: "5개 권역 외부 시장 데이터 수집 + 서비스 유형 분류 + 사용자 행동 패턴 파악 필요"
auto_run: true
effort_mode: standard
tdd_mode: false
uncertainty_level: medium
intent: >
  5개 권역(KR/US/JP/CN/EU)의 타로 앱 시장을 체계적으로 조사하여,
  에이전트 페르소나 설계와 평가 프레임워크 구축을 위한 기초 데이터를 확보한다.
  Research phase만 실행하며, impl phase는 금지.
summary: >
  3개 연구 축(시장 현황, 서비스 분석, 사용자 문화), 3 사이클 + synthesis.
  웹 검색 기반 데스크 리서치. Impl phase 제외 — research 산출물이 최종 결과물.
keywords: [tarot, market-research, global, KR, US, JP, CN, EU, research-only]
research_axes:
  - axis: "권역별 시장 현황"
    question: "5개 권역의 타로 앱 수요(사용자 규모, 검색 트렌드)/공급(앱 수, 경쟁 강도)/시장 특성은?"
    source: "Brief In Scope #1, Decision #1"
  - axis: "주요 서비스 & 유형 분류"
    question: "각 권역 대표 타로 앱의 기능/UX/비즈니스 모델은? 서비스 유형 택소노미는?"
    source: "Brief In Scope #2, #3"
  - axis: "사용자 문화·행동 & 페르소나 기초"
    question: "권역별 타로 문화 맥락, 사용자 동기/스타일, 페르소나 설계를 위한 기초 데이터는?"
    source: "Brief In Scope #4, #6, Decision #3~5"
research_cycles: 3
cycles:
  - cycle: 1
    area: "권역별 시장 현황"
    depends_on: []
    research_needed: true
  - cycle: 2
    area: "주요 서비스 & 유형 분류"
    depends_on: []
    research_needed: true
  - cycle: 3
    area: "사용자 문화·행동 & 페르소나 기초"
    depends_on: []
    research_needed: true
---

# 글로벌 타로 앱 시장 조사 — Research Phase Scope

## 작업 목표

Brief 001에서 정의된 "글로벌 타로 앱 시장 조사 & 평가 에이전트 설계" 프로젝트의 **Research Phase**를 실행한다.

**목표**: 5개 권역(KR/US/JP/CN/EU)의 타로 앱 시장 데이터를 수집·분석하여, 후속 에이전트 페르소나 설계와 평가 프레임워크 구축의 기초 자료를 확보.

**제약**:
- Impl phase 금지 — 코드 구현, 에이전트 구축 등 실행 단계 미진입
- Research 산출물(조사 문서 + synthesis)이 이 scope의 최종 결과물
- 데이터 소스: 공개 정보 기반 데스크 리서치 (웹 검색, 앱스토어, 미디어/학술)

**성공 기준** (Brief Exit Criteria #1, #4):
- 5개 권역별 수요·공급·주요 서비스·유형 분류가 구조화
- 조사 실행 계획(단계, 데이터 소스, 산출물 형식) 수립

## 접근 방향

3개 연구 축을 **병렬 실행** — 각 축이 독립적이므로 순차 의존성 없음.

1. **축 1: 권역별 시장 현황** — 매크로 수준. 시장 규모, 수요/공급 지표, 트렌드
2. **축 2: 주요 서비스 & 유형 분류** — 마이크로 수준. 개별 앱 심층, 택소노미 구축
3. **축 3: 사용자 문화·행동** — 정성적. 문화 맥락, 동기, 행동 패턴

Synthesis(cycle-99)에서 3축 교차 분석 + 페르소나 설계 기초 + 평가 프레임워크 초안을 도출.

## Research 판단
- **판단**: 필요 (프로젝트 자체가 연구)
- **근거**: 외부 시장 데이터 수집, 5개 권역 비교 분석, 서비스 유형 분류 체계 구축 — 모두 코드베이스 외부 정보
- **파이프라인**: Research Phase Only — `research × 3 cycles + eval × 3 + synthesis`
- **Impl phase**: 사용자 명시적 금지

## 영역 식별

| # | 영역 | 조사 범위 | 데이터 소스 |
|---|------|---------|-----------|
| 1 | 권역별 시장 현황 | 5개 권역 수요/공급/규모/트렌드 | 앱스토어 랭킹, data.ai/Sensor Tower 공개 데이터, Google Trends, 산업 보고서 |
| 2 | 주요 서비스 & 유형 분류 | 권역별 Top 5~10 앱 심층 + 서비스 유형 택소노미 | 앱스토어 리스팅, 앱 리뷰, 서비스 기사, 앱 스크린샷 |
| 3 | 사용자 문화·행동 | 타로 문화 배경, 사용자 동기/스타일, 규제 | 미디어 기사, 학술 자료, 포럼/SNS 트렌드, 리뷰 분석 |

## 의존성 맵

```
[축 1: 시장 현황] ──┐
                    ├──→ [Synthesis: 교차 분석 + 페르소나 기초 + 평가 프레임워크 초안]
[축 2: 서비스 분류] ──┤
                    │
[축 3: 사용자 문화] ──┘
```

3축 모두 독립 → 병렬 실행 가능. Synthesis만 3축 완료 후 실행.

## 실행 순서

| 사이클 | 영역 | 선행 조건 | 파이프라인 |
|--------|------|---------|-----------|
| 1 | 권역별 시장 현황 | 없음 | research → eval |
| 2 | 주요 서비스 & 유형 분류 | 없음 | research → eval |
| 3 | 사용자 문화·행동 & 페르소나 기초 | 없음 | research → eval |
| 99 | Synthesis | 사이클 1~3 완료 | synthesis (자동 첨부) |

## 사이클별 연구 가이드

**사이클 1: 권역별 시장 현황**
- 조사 대상: KR/US/JP/CN/EU 각 권역의 타로 앱 시장
- 핵심 질문:
  - 각 권역의 타로 앱 수요 규모는? (다운로드 수, 검색량, MAU 추정)
  - 공급 측면: 주요 플레이어 수, 신규 진입 빈도, 시장 집중도
  - 시장 트렌드: 성장률, AI 통합 트렌드, 결제 모델 변화
  - 권역별 차이: 어디가 수요 > 공급? 어디가 포화?
- 산출물: 권역별 시장 프로필 비교 표 + 수요/공급 매트릭스

**사이클 2: 주요 서비스 & 유형 분류**
- 조사 대상: 각 권역 대표 타로 앱/서비스 (Top 5~10)
- 핵심 질문:
  - 서비스 유형 분류: AI 해석형, 라이브 리딩형, 셀프 리딩형, 학습형, 소셜형, 종합형?
  - 각 유형별 대표 앱은? 기능 구성, UX 패턴, 비즈니스 모델(구독/인앱/광고)?
  - 권역별로 지배적인 서비스 유형이 다른가?
  - 차별화 요소: 어떤 기능/경험이 높은 평점과 상관?
- 산출물: 서비스 유형 택소노미 + 권역-유형 매트릭스 + 앱별 프로필 카드

**사이클 3: 사용자 문화·행동 & 페르소나 기초**
- 조사 대상: 권역별 타로 문화 맥락, 사용자 행동 패턴
- 핵심 질문:
  - 권역별 타로 문화 배경: 서양 전통(EU/US) vs 동양 점술 문화(KR/JP/CN) 융합 양상
  - 사용자 동기: 호기심/오락, 의사결정 보조, 심리적 위안, 자기 탐구, 학습
  - 이용 스타일: 일상 습관형(매일 오늘의 운세), 이벤트형(중요 결정 시), 학습형(타로 공부)
  - 규제 환경: 중국의 미신 규제, EU의 개인정보(GDPR), 각국 인앱결제 규제
  - 문화적 차이가 앱 기대치에 미치는 영향
- 산출물: 권역별 사용자 프로필 + 동기-스타일 매트릭스 + 규제 요약

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 131s | 302840 |
| 2 | user-ai-exchange | 90s | 427619 |
| 3 | user-ai-exchange | 0s | 0 |
| 4 | user-ai-exchange | 334s | 2229998 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 1312s |
| Total Tokens | 2960457 |
| Input Tokens | 49 |
| Output Tokens | 27086 |
| Cache Read | 2791412 |
| Cache Creation | 141910 |
