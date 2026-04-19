---
id: "043"
type: scope
title: "타로 셔플 엔진 구현 — Flame + Rive + forge2d"
created: 2026-03-16
complexity: complex
research_needed: false
research_reason: "036~042 연구 완료 — 파라미터, latency, 대안, 손맛, 가속도계 전부 확정"
auto_run: true
intent: >
  현재 CustomPainter 2D 셔플 엔진을 Flame + Rive 2.5D 일러스트 손 + forge2d 물리로
  교체한다. 조작감 최우선. 가속도계 기울이기 → 카드 중력 반응, 햅틱 레이어링 포함.
summary: >
  3개 영역, 3개 순차 사이클. Cycle 1: Foundation (pubspec + Flame 게임 + 좌표 유틸).
  Cycle 2: Physics & Animation (forge2d 카드 + Rive 손 + 가속도계). Cycle 3: UI Integration
  (ShufflePage GameWidget 교체 + 햅틱). 모든 사이클 research_needed: false.
keywords: [flame, rive, forge2d, sensors_plus, haptic, shuffle-engine, implementation]
cycles:
  - cycle: 1
    area: "Foundation"
    depends_on: []
    research_needed: false
  - cycle: 2
    area: "Physics & Animation"
    depends_on: [1]
    research_needed: false
  - cycle: 3
    area: "UI Integration"
    depends_on: [1, 2]
    research_needed: false
---

# 타로 셔플 엔진 구현 — Flame + Rive + forge2d

## 작업 목표
- **현재**: `CustomPainter` + `RiffleAnimationState` 2D 셔플 (game/ 폴더 없음)
- **목표**: Flame 게임 루프 + Rive 2.5D 일러스트 손 + forge2d 카드 물리 단일 엔진
- **제약**: 조작감 최우선. 가속도계 → 중력 방향. 햅틱 레이어링. sensors_plus 이미 포함.
- **성공 기준**: GameWidget이 ShufflePage에 통합되어 카드 78장이 물리 법칙에 따라 움직이고, 폰 기울이기에 즉각 반응하며, 손 애니메이션이 Rive로 재생됨.

## 접근 방향
3차 연구(042) 확정 아키텍처를 그대로 구현. 대안 검토 완료 — 단일 경로.

```
Rive 에디터(.riv 파일) + Flame 게임 루프 + forge2d 물리 + sensors_plus 중력
  → GameWidget으로 ShufflePage에 통합
  → 기존 CustomPainter / RiffleAnimationController 제거
```

## Research 판단
- **판단**: 불필요
- **근거**: forge2d 파라미터(036), Rive-forge2d latency 패턴(037), 물리 대안 결론(038), 손맛 구현 기법(039), 가속도계 응답성(040), 최종 아키텍처(042) 모두 확정
- **파이프라인**: S → P → I(V) (research 없이 바로 makeplan)

## 영역 식별

| # | 영역 | 주요 파일/모듈 | 설명 |
|---|------|-------------|------|
| 1 | Foundation | pubspec.yaml, game/tarot_game.dart, game/tarot_coordinate_utils.dart | Flame 게임 루프 + 의존성 + 좌표계 변환 유틸 |
| 2 | Physics & Animation | game/card_body_component.dart, game/hand_animation_component.dart, game/sensor_gravity_controller.dart | forge2d 카드 body + Rive 손 KinematicBody + 가속도계 중력 |
| 3 | UI Integration | presentation/pages/shuffle_page.dart | ShufflePage → GameWidget 교체, 햅틱 연결 |

## 의존성 맵

```
Foundation (Cycle 1)
  → TarotGame (Flame 게임 클래스)
  → TarotCoordinateUtils (artboard→Flame→forge2d 단위 변환)
       ↓ (Cycle 1 완료 후)
Physics & Animation (Cycle 2)
  → CardBodyComponent (forge2d DynamicBody, 카드 1장)
  → HandAnimationComponent (RiveComponent + KinematicBody 동기화)
  → SensorGravityController (accelerometerEventStream → world.gravity)
       ↓ (Cycle 2 완료 후)
UI Integration (Cycle 3)
  → ShufflePage (CustomPaint → GameWidget 교체)
  → 햅틱: beginContact → HapticFeedback, 카드 집기/뒤집기 이벤트 연결
```

## 실행 순서

| 사이클 | 영역 | 선행 조건 | Research | 파이프라인 |
|--------|------|---------|----------|-----------|
| 1 | Foundation | 없음 | 불필요 | P→I(V) |
| 2 | Physics & Animation | Cycle 1 | 불필요 | P→I(V) |
| 3 | UI Integration | Cycle 1, 2 | 불필요 | P→I(V) |

## 변경 대상 파일

**신규 생성:**
- `mobile/pubspec.yaml` — flame, flame_rive, flame_forge2d, rive 추가
- `mobile/lib/features/shuffle/presentation/game/tarot_game.dart`
- `mobile/lib/features/shuffle/presentation/game/tarot_coordinate_utils.dart`
- `mobile/lib/features/shuffle/presentation/game/card_body_component.dart`
- `mobile/lib/features/shuffle/presentation/game/hand_animation_component.dart`
- `mobile/lib/features/shuffle/presentation/game/sensor_gravity_controller.dart`
- `mobile/assets/animations/hand_shuffle.riv` — Rive 파일 플레이스홀더

**수정:**
- `mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart` — GameWidget 교체

**보존 (변경 없음):**
- `sensor_data_collector.dart` — 엔트로피 수집 계속 사용
- `haptic_service.dart` — 기존 서비스 재사용
- `shuffle_repository_impl.dart`, `shuffle_deck_usecase.dart` — 도메인 레이어 무관

## 핵심 설계 결정 (연구 확정값)

```dart
// Cycle 1: 좌표 변환 유틸 핵심
// artboard(px) → forge2d(meter): 1 meter = 100px (조정 가능)
static const double kPixelPerMeter = 100.0;
static Vector2 artboardToForge2d(double x, double y) =>
    Vector2(x / kPixelPerMeter, y / kPixelPerMeter);

// Cycle 2: forge2d 카드 파라미터 (036 확정값)
fixtureDef..density = 1.0..friction = 0.4..restitution = 0.05;
bodyDef..linearDamping = 2.0..angularDamping = 1.2..allowSleep = true;

// Cycle 2: 가속도계 (040 확정값)
accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
  .listen((e) { _rawX = e.x; _rawY = e.y; });
// update(dt): smoothX += 0.20 * (rawX - smoothX); world.gravity = Vector2(smoothX * 3.0, smoothY * 3.0);

// Cycle 3: 햅틱 연결 (039 확정값)
// forge2d beginContact → HapticFeedback.heavyImpact()
// 카드 집기(onPanStart) → mediumImpact()
// 카드 뒤집기 완료 → heavyImpact()
```

## 체크포인트 & 컨텍스트 관리

| 체크포인트 | 산출물 | 컨텍스트 조치 |
|-----------|--------|-------------|
| /scope 완료 | 043_Scope | /clear 권장 — 연구 대량 로딩됨 |
| Cycle 1 makeplan 완료 | Plan 문서 | 유지 — 수정 대상 파일 = plan 읽은 파일 |
| Cycle 1 impl 완료 | 코드 커밋 | /clear — Cycle 2는 독립 |
| Cycle 2 impl 완료 | 코드 커밋 | /clear — Cycle 3은 독립 |
| Cycle 3 impl 완료 | 코드 커밋 + verify | 완료 |

## 예상 밖 의존성 대응 규칙
- Rive .riv 파일이 없는 경우: 플레이스홀더(빈 artboard)로 Flame 통합 먼저 검증, Rive 디자인은 별도 태스크
- forge2d 버전 충돌 시: flame_forge2d 버전에 맞춰 forge2d 고정
- iOS Rive C++ 런타임 빌드 이슈 시: rive 패키지 ≥0.14 확인

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
