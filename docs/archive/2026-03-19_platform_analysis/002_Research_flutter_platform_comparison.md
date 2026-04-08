---
id: "002"
type: research
title: "Flutter 선택 재분석 + 대안 플랫폼 전환 가능성"
created: 2026-03-19
status: completed
traces_scope: "001"
summary: >
  Flutter 핵심 의존 7개 축에 대해 5개 대안 플랫폼의 대응 능력을 3개 관점에서 병렬 조사.
  게임/물리 엔진, 네이티브 API, 전환 비용 관점.
keywords: [flutter, react-native, kotlin-multiplatform, native, unity, maui, platform-migration]
parallel_plan:
  total_perspectives: 3
  phases:
    - phase: 1
      perspectives: [1, 2, 3]
      status: pending
      agent_numbers: ["003", "004", "005"]
  synthesis_number: "006"
  final_number: "007"
---

# Flutter 선택 재분석 + 대안 플랫폼 전환 가능성

## Research Overview

### Background & Motivation
personality 프로젝트의 mobile 앱은 Flutter로 구현되어 있다. 타로 카드 셔플이라는
특수한 요구사항(물리 시뮬레이션, 센서 기반 중력, 햅틱 피드백, 벡터 애니메이션)이
기술 선택의 핵심 축이었다. 이 선택이 여전히 최적인지, 대안이 있다면 어떤 트레이드오프가
있는지를 재분석한다.

### Research Scope
- **조사 대상**: React Native, Kotlin Multiplatform, Native(Swift+Kotlin), Unity, .NET MAUI
- **비교 축**: 물리 엔진, 애니메이션, 센서, 햅틱, 로컬 DB, 상태관리, 코드 생성
- **제외**: 웹 플랫폼, 데스크톱 전용 프레임워크

### Research Perspectives
1. **게임/물리 엔진 + 애니메이션 렌더링** — Flame+Forge2D+Rive 조합의 대체 가능성
2. **네이티브 API 접근 + 개발 인프라** — 센서, 햅틱, DB, 상태관리, 타입 안전성
3. **전환 비용 + 생태계 건강성** — 이식 난이도, 커뮤니티, 인력 시장, 장기 전망

## Preliminary Findings

### Flutter 선택의 기존 근거 (코드베이스에서 확인)
- Flame 게임 엔진이 Forge2D(Box2D 포트)와 Rive를 단일 게임 루프에서 통합
- sensors_plus가 크로스플랫폼 가속도계/자이로를 gameInterval로 제공
- Drift가 타입 안전 SQLite ORM을 코드 생성으로 제공
- Riverpod + Freezed가 컴파일 타임 안전 + 불변 데이터 모델 보장
- 단일 코드베이스로 iOS + Android 동시 타겟

### 핵심 기술 의존성 상세 (scope 문서에서)
- 고정 타임스텝 물리: 45fps, density=1.0, friction=0.4, restitution=0.05
- 가속도계 로우패스 필터: α=0.20, 중력 스케일 3.0
- 햅틱 쓰로틀링: 50ms 간격
- 오프라인 DB: decks, cards, readings, drawn_cards 4개 테이블

## Parallel Execution Instructions

### Perspective 1: 게임/물리 엔진 + 애니메이션 렌더링
각 플랫폼에서 다음을 조사:
- **2D 물리 엔진**: Box2D 포트 또는 동급 물리 라이브러리의 존재, 성숙도, API 수준
  - 필요 기능: rigid body, fixture(density/friction/restitution), damping, contact listener, fixed timestep
- **게임 루프 프레임워크**: 컴포넌트 시스템, 렌더링 파이프라인, 60fps 타겟
- **벡터 애니메이션**: Rive runtime 공식 지원 여부, Lottie 대안, StateMachine 인터랙션
- **통합 난이도**: 물리 + 애니메이션 + 게임 루프의 단일 시스템 통합 가능 여부

대상 플랫폼: React Native, KMP, Native(iOS SpriteKit/Android), Unity, .NET MAUI

### Perspective 2: 네이티브 API 접근 + 개발 인프라
각 플랫폼에서 다음을 조사:
- **센서 API**: 가속도계/자이로 접근 방법, 샘플링 레이트 제어, 크로스플랫폼 추상화
- **햅틱 피드백**: 시스템 API 접근성, 세밀도(selection/light/medium/heavy), 쓰로틀링
- **로컬 DB**: SQLite ORM 옵션, 오프라인-퍼스트 패턴, 타입 안전성
- **상태관리**: 반응형 패턴, 컴파일 타임 안전, 코드 생성 지원
- **코드 생성 / 타입 안전성**: Freezed 동급의 불변 데이터 모델 + JSON 직렬화

대상 플랫폼: React Native, KMP, Native(Swift+Kotlin), Unity, .NET MAUI

### Perspective 3: 전환 비용 + 생태계 건강성
각 플랫폼에서 다음을 조사:
- **이식 난이도**: 현재 Flutter 코드(~75 .dart 파일, Flame 게임 엔진, Riverpod, Drift) 재작성 규모
- **코드 공유율**: iOS/Android 간 코드 공유 비율 (크로스플랫폼 vs 네이티브)
- **커뮤니티/생태계**: npm/pub/maven/nuget 패키지 수, GitHub stars, Stack Overflow 활성도
- **인력 시장**: 한국 기준 Flutter vs RN vs KMP vs Native 개발자 채용 난이도
- **장기 전망**: 각 플랫폼 후원사의 투자 방향, 최근 1년 동향, 중단 리스크
- **앱 특성 적합도**: 이 앱이 게임 성격이 강한지 일반 앱 성격이 강한지 판단

## Remaining Work
- [ ] Perspective 1: 게임/물리 엔진 + 애니메이션 렌더링
- [ ] Perspective 2: 네이티브 API 접근 + 개발 인프라
- [ ] Perspective 3: 전환 비용 + 생태계 건강성
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
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 341150s |
| Total Tokens | 1591534 |
| Input Tokens | 71 |
| Output Tokens | 8834 |
| Cache Read | 1202235 |
| Cache Creation | 380394 |
