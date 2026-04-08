---
id: "001"
type: scope
title: "Flutter 선택 재분석 + 대안 플랫폼 전환 가능성"
created: 2026-03-19
complexity: simple
research_needed: true
research_reason: "각 대안 플랫폼(RN, KMP, Native, Unity)의 물리엔진·센서·애니메이션 생태계 비교 필요"
auto_run: false
effort_mode: light
uncertainty_level: medium
intent: >
  현재 mobile이 Flutter로 구현된 이유를 기술 의존성 관점에서 재분석하고,
  대안 플랫폼으로 전환 시 가능성과 선택폭을 평가한다.
  구현이 아닌 의사결정 지원 분석.
summary: >
  단일 영역 (플랫폼 비교 분석). Flutter 핵심 의존 7개 축
  (Flame/Forge2D, Rive, sensors_plus, Haptic, Drift, Riverpod, Freezed)에 대해
  5개 대안 플랫폼의 대응 능력을 조사. Research 필요.
keywords: [flutter, react-native, kotlin-multiplatform, platform-migration, flame, forge2d, rive]
---

# Flutter 선택 재분석 + 대안 플랫폼 전환 가능성

## 작업 목표

- **목표**: Flutter 선택 이유를 기술 의존성 기반으로 재분석, 대안 플랫폼 전환 가능성 평가
- **제약**: 분석/의사결정 지원만 — 코드 변경 없음
- **성공 기준**: 각 대안 플랫폼별 "전환 비용 vs 이점" 매트릭스 도출

## 현재 Flutter 핵심 의존성 (코드베이스 직접 확인)

### 1. 게임 엔진 레이어 (Flame + Forge2D)
- `flame: ^1.19.0` — 게임 루프, 컴포넌트 시스템
- `flame_forge2d: ^0.19.0` — Box2D 물리 (카드 충돌, 감쇠, 마찰)
- `flame_rive: ^1.1.0` — Rive 애니메이션 Flame 통합
- **사용처**: `game/tarot_game.dart`, `card_body_component.dart`
- **핵심**: 고정 타임스텝 물리 (45fps), density/friction/restitution/damping 파라미터

### 2. 벡터 애니메이션 (Rive)
- `rive: ^0.13.16`
- **사용처**: `hand_animation_component.dart` — 2.5D 손 일러스트
- **핵심**: StateMachine 기반 인터랙티브 애니메이션, Flame 게임 루프와 동기화

### 3. 센서 API (sensors_plus)
- `sensors_plus: ^5.0.0` — 가속도계/자이로스코프
- **사용처**: `sensor_data_collector.dart` (엔트로피), `sensor_gravity_controller.dart` (중력)
- **핵심**: gameInterval 샘플링, 로우패스 필터(α=0.20), 폰 기울이기 → 카드 중력 방향

### 4. 햅틱 피드백
- `flutter/services.dart` — HapticFeedback (시스템 API)
- **사용처**: `haptic_service.dart` — 50ms 쓰로틀링, selection/light/medium impact
- **핵심**: 물리 충돌 → 촉각 피드백 매핑

### 5. 오프라인 DB (Drift)
- `drift: ^2.22.0` — 타입 안전 SQLite ORM
- **사용처**: `core/database/` — decks, cards, readings, drawn_cards 테이블
- **핵심**: 오프라인-퍼스트, 코드 생성 기반 DAO

### 6. 상태관리 (Riverpod)
- `flutter_riverpod: ^2.6.0` + `riverpod_annotation`
- **사용처**: 전 화면 providers, Dev Tuner registry
- **핵심**: 컴파일 타임 안전, 코드 생성, 반응형 재빌드

### 7. 데이터 모델 (Freezed)
- `freezed: ^2.5.0` + `json_serializable`
- **사용처**: 전 domain entity — `tarot_card.dart`, `deck_metadata.dart` 등 6개 모델
- **핵심**: 불변 객체, union type, JSON 직렬화 코드 생성

## 접근 방향

**비교 대상 플랫폼** (5개):

| # | 플랫폼 | 특성 |
|---|--------|------|
| 1 | React Native | JS/TS 크로스플랫폼, 가장 큰 생태계 |
| 2 | Kotlin Multiplatform (KMP) | Kotlin 공유 로직, 네이티브 UI |
| 3 | Native (Swift + Kotlin) | 각 플랫폼 최적, 두 코드베이스 |
| 4 | Unity (C#) | 게임 엔진 최강, 앱 UX 약점 |
| 5 | .NET MAUI / Uno Platform | C# 크로스플랫폼, 엔터프라이즈 |

**비교 축** (7개): 위 Flutter 핵심 의존성 각각에 대한 대응 능력

## Research 판단
- **판단**: 필요
- **근거**: 5개 플랫폼 × 7개 축 = 35개 셀의 생태계 조사. 각 플랫폼의 물리 엔진·센서·애니메이션 라이브러리 현황은 코드베이스에서 추론 불가.
- **파이프라인**: S → R (연구 후 의사결정 지원 문서로 종결 — makeplan/implementation 불필요)

## 체크포인트 & 컨텍스트 관리

| 체크포인트 | 산출물 | 컨텍스트 조치 | 판단 기준 |
|-----------|--------|-------------|----------|
| /scope 완료 | 이 문서 | /clear 권장 | research가 독립적 넓은 탐색 수행, 현재 컨텍스트가 노이즈 |
| /research 완료 | Research 문서 | 완료 | 분석 태스크 — implementation 없음 |

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
