---
id: "041"
title: "타로 셔플 조작감 우선 엔진 재검토 — Synthesis Report"
category: report
status: archived
created: 2026-03-16
summary: >
  5개 관점 병렬 조사 종합. forge2d 유지 확정(Dart 생태계 유일 검증 엔진),
  조작감은 linearDamping(1.5~3.0)이 가장 결정적 파라미터. Rive-forge2d 연동 latency
  최대 16.7ms로 조작감 영향 없음. 가속도계 총 지연 25~40ms로 즉각 반응 달성 가능.
  하이브리드(forge2d 충돌 + SpringSimulation 스냅백 + 햅틱 레이어링)가 최적 아키텍처.
keywords: [synthesis, forge2d, rive, flame, tactile, haptic, accelerometer, spring, physics]
modules: []
---

# 타로 셔플 조작감 우선 엔진 재검토 — Synthesis Report

## 팀 구성 & 개별 보고서

| # | 역할 | 보고서 | 상태 |
|---|------|--------|------|
| 1 | 물리 파라미터 분석가 | [036_Agent_physics_params.md](./036_Agent_physics_params.md) | 완료 |
| 2 | Rive↔forge2d Latency 분석가 | [037_Agent_rive_forge2d_latency.md](./037_Agent_rive_forge2d_latency.md) | 완료 |
| 3 | 물리 엔진 대안 분석가 | [038_Agent_physics_alternatives.md](./038_Agent_physics_alternatives.md) | 완료 |
| 4 | 카드 손맛 구현 사례 분석가 | [039_Agent_card_feel_cases.md](./039_Agent_card_feel_cases.md) | 완료 |
| 5 | 가속도계 응답성 분석가 | [040_Agent_accelerometer_response.md](./040_Agent_accelerometer_response.md) | 완료 |

---

## Cross-Analysis

### 공통 발견 (2개+ 에이전트 독립 확인)

**forge2d 유지 결론 — 관점 2, 3 독립 확인**
- 관점 3: Dart 생태계에서 forge2d 외 실용적 대안 없음 (rapier-dart 미존재)
- 관점 2: flame_rive + flame_forge2d 공식 통합 경로 확인
- → forge2d 교체는 불필요하고 비효율적. 유지 확정.

**SpringSimulation 보완 필요 — 관점 3, 4 독립 확인**
- 관점 3: "forge2d 단독보다 SpringSimulation 스냅백 하이브리드가 최적"
- 관점 4: "velocity fling + SpringSimulation이 조작감 기여 1위 기법"
- → forge2d + Flutter SpringSimulation 하이브리드 아키텍처 채택 권장

### Synergy 발견

**linearDamping(관점 1) + 가속도계 scale(관점 5)의 연결**
- linearDamping이 높을수록(3.0) 카드가 빨리 멈춤
- gravity scale(3.0~6.0)이 높을수록 기울기 반응 강함
- 두 값은 반드시 쌍으로 튜닝 필요 — linearDamping 높으면 gravity scale도 높여야 기울기 반응이 느껴짐

**햅틱(관점 4) + forge2d 충돌 이벤트(관점 1, 2)의 연결**
- forge2d `beginContact` 콜백 → 카드-카드 충돌 시점 정확히 포착 가능
- 이 시점에 `HapticFeedback.heavyImpact()` 연결 → "카드끼리 부딪히는 느낌" 구현

**Rive-forge2d latency(관점 2) + 햅틱 타이밍(관점 4)의 연결**
- Rive 손이 forge2d 카드를 미는 순간(KinematicBody 충돌) = `beginContact` 발생
- 동일 프레임 내 처리 → 햅틱 트리거를 이 콜백에 연결하면 "손이 카드를 치는 느낌" 구현

### 상충 발견

| 항목 | 즉각성 우선 | 부드러움 우선 |
|------|-----------|-------------|
| 로우패스 α | 0.4~0.6 | 0.08~0.15 |
| linearDamping | 낮게(0.5~1.0) | 높게(2.0~3.0) |
| **타로 권장** | **α 0.20 + linearDamping 2.0** | — |

타로 셔플 특성(신비로운 분위기, 느긋한 속도감)을 고려하면 중간~부드러움 설정이 적합.

---

## Comprehensive Conclusion

### 핵심 발견 요약

1. **forge2d 유지 확정** — Dart 생태계 유일 검증 엔진, 78장 body 성능 문제 없음
2. **조작감 결정 파라미터 1위: linearDamping (1.5~3.0)** — 가장 직접적 "무게감" 결정자
3. **Rive-forge2d latency: 조작감 영향 없음** — 최대 1프레임(16.7ms), 체감 임계값 50ms 이하
4. **가속도계 응답성 충분** — 총 지연 25~40ms, 즉각 반응 달성 가능
5. **최적 아키텍처**: forge2d(충돌·다체) + SpringSimulation(단일 카드 스냅백) + 햅틱 레이어링

### 권장 파라미터 세트

```dart
// forge2d 카드 BodyDef/FixtureDef
fixtureDef
  ..density = 1.0
  ..friction = 0.4
  ..restitution = 0.05;

bodyDef
  ..linearDamping = 2.0   // 조작감 핵심 파라미터
  ..angularDamping = 1.2
  ..allowSleep = true;

// 가속도계 → gravity
world.gravity = Vector2(smoothX * 3.0, smoothY * 3.0);  // scale 2.0~6.0 튜닝

// 로우패스 필터
const alpha = 0.20;
smoothX += alpha * (rawX - smoothX);
smoothY += alpha * (rawY - smoothY);
```

---

## References
- [036_Agent_physics_params.md](./036_Agent_physics_params.md)
- [037_Agent_rive_forge2d_latency.md](./037_Agent_rive_forge2d_latency.md)
- [038_Agent_physics_alternatives.md](./038_Agent_physics_alternatives.md)
- [039_Agent_card_feel_cases.md](./039_Agent_card_feel_cases.md)
- [040_Agent_accelerometer_response.md](./040_Agent_accelerometer_response.md)

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
