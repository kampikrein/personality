---
id: "006"
type: synthesis
title: "플랫폼 비교 교차 분석 — 3개 관점 통합"
created: 2026-03-19
agents: ["003", "004", "005"]
summary: >
  게임엔진·네이티브API·전환비용 3개 관점 교차 분석. Flutter 유지가 최적이라는 결론 도출.
---

# 플랫폼 비교 교차 분석

## 관점 간 핵심 교차점

### 1. "통합 비용" — 3개 관점이 수렴하는 핵심 변수

**관점 1** (게임 엔진): Flame+Forge2D+Rive의 공식 통합 패키지(`flame_forge2d`, `flame_rive`)가 유일한 강점
**관점 2** (네이티브 API): Drift+Riverpod+Freezed 조합이 오프라인-퍼스트 반응형 파이프라인을 단일 프레임워크에서 제공
**관점 3** (전환 비용): 어떤 플랫폼도 85% 이상 재작성 필요 — "각 조각은 대체 가능하나, 조합 재현이 비용"

→ **공통 결론**: Flutter의 경쟁 우위는 개별 기능이 아닌 **7개 축의 통합 마찰 최소화**

### 2. Unity — 유일한 동등 대안이면서 동시에 부적합

**관점 1**: 물리+게임+Rive 통합에서 Flutter와 동급 (통합 난이도 "낮음")
**관점 2**: 로컬 DB, 상태관리, 코드 생성에서 최약 — "앱 인프라 극도로 약함"
**관점 3**: 앱 UI가 전체의 ~88%인데, 이 부분의 개발 생산성이 크게 떨어짐

→ **상충**: 게임 관점 최강 vs 앱 관점 최약. 하이브리드(Flutter 내 Unity 임베딩)가 유일한 실현 경로지만, 이는 "전환"이 아닌 "보강"

### 3. KMP — 개별 영역 강자, 통합 약자

**관점 1**: KorGE 미성숙 (Flame의 1/6), Rive 공식 SDK 없음 — 게임 영역 "매우 높음" 통합 난이도
**관점 2**: SQLDelight/data class/sealed class가 Drift/Freezed 동급 이상 — 개발 인프라 "강점"
**관점 3**: 급성장(7%→23%)이나 게임 엔진 생태계는 여전히 공백

→ **패턴**: 앱 인프라에서 강하지만, 이 앱의 핵심 차별점(물리 셔플)에서 약함

### 4. React Native — JS 생태계의 양날의 검

**관점 1**: 게임 프레임워크 6년 비활성, Box2D 포트 66 stars — 프로덕션 부적합
**관점 2**: Drizzle ORM 급부상, expo-sensors 성숙, react-native-haptic-feedback Flutter 동급
**관점 3**: JS 인력풀 최대, 채용 장벽 최저, 학습 곡선 1-2주

→ **패턴**: 인력/생태계 접근성은 최고이나, 게임 엔진 레이어에서 Flutter를 따라잡기 어려움

### 5. Native — 모든 축 최강이나 2배 비용

**관점 1**: iOS SpriteKit 우수 + Android LibGDX 검증, 단 코드 이중화 2배
**관점 2**: 센서/햅틱 최대 접근, DB/상태관리 최고 성숙도, 단 2개 코드베이스
**관점 3**: 6-8 인-월 + 두 명 이상의 개발자 필요

→ **패턴**: 기술적으로는 최적이나, 1인 개발 또는 소규모 팀에서는 비현실적

## 상충점 (Trade-offs)

| 트레이드오프 | 한쪽 | 반대쪽 |
|------------|------|--------|
| 통합 완성도 vs 개별 최적화 | Flutter (통합 최고) | Native/KMP (개별 최고) |
| 게임 품질 vs 앱 생산성 | Unity (게임 최강) | Flutter/RN/MAUI (앱 최강) |
| 인력 접근성 vs 기술 적합도 | RN (인력 최대) | Flutter (기술 최적) |
| 단일 코드베이스 vs 플랫폼 최적화 | Flutter/RN/Unity (단일) | Native (각각 최적) |

## 최종 우선순위

이 앱의 특성("게임 요소 있는 앱", 게임 코드 12%, 앱 코드 88%)에 최적화된 순위:

1. **Flutter (현행 유지)** — 통합 마찰 최소, 게임+앱 혼합 비율에 정확히 맞음
2. **Unity 하이브리드** — 게임 품질 사업적 임계 시 유일한 보강 경로
3. **KMP** — 장기적 언어/생태계 성장세, 게임 엔진 성숙 시 재평가
4. **Native** — 최고 품질, 팀 2명 이상 확보 시
5. **React Native** — JS 인력만 가용할 때의 현실적 대안
6. **MAUI** — 고려 불필요

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
