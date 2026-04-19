---
id: "001"
type: scope
title: "Universal Dev Tuner — 화면별 변수 실시간 조정 시스템"
created: 2026-03-18
complexity: complex
research_needed: true
research_reason: "화면 감지 + 변수 등록 아키텍처 패턴 조사 필요 — Flutter+Riverpod에서 유사 패턴 없음"
auto_run: true
effort_mode: standard
uncertainty_level: medium
intent: >
  Spring Tuner를 범용 Dev Tuner로 확장. 각 화면별 조정 가능 변수를 등록하고,
  드래그 가능한 오버레이 패널에서 < 숫자 > 방식으로 값을 실시간 조절하여 즉시 반영.
  모든 화면에서 동작하며, 새 기능 추가 시 변수를 자동 등록하는 확장 가능한 구조.
summary: >
  2개 영역(튜너 시스템 인프라 + 화면별 통합), 2개 사이클.
  사이클 1에서 라우트 감지·변수 모델·오버레이 UI 구현, 사이클 2에서 기존 5개 화면 통합.
keywords: [dev-tuner, debug-panel, spring-tuner, route-aware, variable-registry]
cycles:
  - cycle: 1
    area: "Tuner System (core + UI)"
    depends_on: []
    research_needed: true
  - cycle: 2
    area: "Screen Integration"
    depends_on: [1]
    research_needed: false
---

# Universal Dev Tuner — 화면별 변수 실시간 조정 시스템

## 작업 목표

현재 Spring Tuner(3개 스프링 변수)를 범용 Dev Tuner로 확장한다.
- 각 화면마다 고유한 조정 가능 변수 집합을 등록
- `< 숫자 >` 스텝퍼 UI로 값을 직접 조정하여 즉시 화면에 반영
- 최상위 레이어에 드래그 가능한 FAB 버튼, 탭 시 현재 화면의 변수 목록 표시
- 새 기능/화면 추가 시 변수를 쉽게 등록할 수 있는 확장 가능한 구조

성공 기준:
1. 어떤 화면에서든 튜너 버튼이 보이고 드래그로 이동 가능
2. 탭 시 현재 화면의 변수만 표시
3. 값 변경이 즉시 화면에 반영
4. 새 화면/변수 추가 시 등록 코드 1-2줄로 가능

## 접근 방향

Riverpod StateProvider 기반 변수 레지스트리 + GoRouter 라우트 감지로 화면별 변수 필터링.
기존 Spring Tuner의 오버레이 패턴을 확장하여 범용 패널 구축.

대안:
- InheritedWidget 기반: Riverpod과 이중 상태 관리 → 비채택
- DevTools Extension: 앱 외부 도구 → 실시간 반영 어려움 → 비채택

## Research 판단

- **판단**: 필요
- **근거**: 라우트 감지 + 변수 자동 등록 아키텍처가 프로젝트에 전례 없음. GoRouter의 route observer 패턴, Riverpod에서 화면별 provider 집합 관리 방법 조사 필요
- **파이프라인**: S → R → P → I(V)

## 영역 식별

| # | 영역 | 주요 파일/모듈 | 설명 |
|---|------|-------------|------|
| 1 | Tuner System (core + UI) | `mobile/lib/core/dev_tuner/`, `main.dart` | 변수 모델, 레지스트리, 라우트 감지, 오버레이 UI |
| 2 | Screen Integration | `mobile/lib/features/*/` 각 화면 | 5개 화면에 변수 등록 코드 추가 |

## 의존성 맵

### 다이어그램
```
[Cycle 1: Tuner System]
  ├── TunableVariable 모델 (double/int/bool/enum)
  ├── TunerRegistry (화면별 변수 집합 관리)
  ├── RouteDetector (GoRouter → 현재 화면 이름)
  └── TunerOverlay UI (드래그 FAB + < N > 스텝퍼 패널)
         │
         ▼
[Cycle 2: Screen Integration]
  ├── Home (기존 스프링 변수 이전 + gradient 등)
  ├── Shuffle (물리 파라미터, 애니메이션 속도)
  ├── Reading (카드 크기, 간격, 애니메이션)
  ├── Intention (텍스트필드 스타일)
  └── DeckSelection (그리드 컬럼, 카드 비율)
```

### 의존 관계 상세

| From | To | 의존 내용 | 근거 |
|------|----|---------|------|
| Screen Integration | Tuner System | 변수 등록 API, TunableVariable 모델 | 각 화면이 registry에 변수를 등록해야 함 |
| Tuner System | GoRouter | 현재 라우트 감지 | app_router.dart의 GoRouter 인스턴스 참조 |

## 실행 순서

| 사이클 | 영역 | 선행 조건 | Research | 파이프라인 |
|--------|------|---------|----------|-----------|
| 1 | Tuner System (core + UI) | 없음 | 필요 | R→P→I(V) |
| 2 | Screen Integration | 사이클 1 | 불필요 | P→I(V) |

## 사이클별 연구 가이드

### 사이클 1: Tuner System
- 조사 대상:
  - GoRouter route observer / listener 패턴 (현재 화면 감지)
  - Riverpod에서 동적 provider 집합 관리 (화면별 변수 그룹)
  - Flutter OverlayEntry vs builder 기반 오버레이 비교
  - `< 숫자 >` 스텝퍼 UI 구현 패턴 (increment/decrement + 직접 입력)
  - kDebugMode 가드 (릴리즈 빌드에서 튜너 제거)
- 핵심 질문:
  - 변수 등록을 선언적으로 할 수 있는 가장 간결한 API는?
  - 라우트 전환 시 변수 목록을 어떻게 자동 갱신하는가?
  - StateProvider vs StateNotifier vs ChangeNotifier 중 최적 선택은?

## 체크포인트 & 컨텍스트 관리

### 파이프라인 체크포인트

| 체크포인트 | 산출물 | 컨텍스트 조치 | 판단 기준 |
|-----------|--------|-------------|----------|
| /scope 완료 | Scope 문서 | /clear | 다음 스킬이 /research — 독립적 넓은 탐색 |
| /research 완료 | Research 문서 | /clear | research 광범위 탐색 → makeplan에 노이즈 |
| /makeplan 완료 | Plan 문서 | 매트릭스 판단 | plan 파일 = impl 수정 파일이면 유지 |
| /implementation 완료 | 커밋 | /clear | 다음 사이클은 독립적 |

## 예상 밖 의존성 대응 규칙
- 사이클 2 통합 중 사이클 1 API 수정 필요 발견 시:
  - 수정 범위 ≤ 3 파일: 사이클 2 플랜에 포함
  - 수정 범위 > 3 파일: Scope 문서 업데이트 + 사이클 재조정

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
