---
id: "038"
title: "조작감 특화 물리 엔진 대안 조사"
category: agent
status: archived
created: 2026-03-16
summary: >
  forge2d 외 Flutter 내장 Simulation 클래스, 커스텀 스프링-댐퍼, Dart 대안 라이브러리를 조작감 기준으로 비교.
  결론: 단일 카드 드래그-릴리즈 조작감은 Flutter 내장 SpringSimulation/PhysicsController2D로
  구현 가능하나, 78장 카드-카드 충돌·동시 물리 처리는 forge2d가 유일한 실용 선택지.
  커스텀 스프링-댐퍼는 개별 카드 "튕김"에 한해 forge2d보다 낮은 오버헤드로 가능하며,
  하이브리드(forge2d 충돌 + Flutter Simulation 단일 카드 스냅백)가 최적 접근법으로 도출됨.
keywords: [agent-report, forge2d, spring-damper, physics-alternative, flutter-simulation, card-physics]
modules: []
---

# 조작감 특화 물리 엔진 대안 조사

## Progress
### Completed
- [x] Flutter 내장 Simulation 클래스 조사
- [x] 커스텀 스프링-댐퍼 구현 난이도 평가
- [x] Dart 대안 물리 라이브러리 현황 조사 (2024~2025)
- [x] forge2d vs 커스텀 성능 비교
- [x] 카드 드래그-릴리즈 튕김 구현 방식 조사
- [x] 최종 결론: forge2d vs 커스텀
### Remaining
(없음)
### Current Status
조사 완료.

---

## Summary

타로 카드 78장 조작감을 기준으로 세 가지 접근법을 비교한 결과:

| 접근법 | 단일 카드 조작감 | 78장 충돌 | 구현 난이도 | 결론 |
|--------|-----------------|-----------|------------|------|
| forge2d 단독 | 튜닝 필요하나 충분 | 네이티브 지원 | 중 | 충돌 필수 시 채택 |
| Flutter Simulation (SpringSimulation/FrictionSimulation) | 우수 (즉시 사용) | 미지원 | 낮음 | 단일 카드 스냅백에 적합 |
| 커스텀 스프링-댐퍼 (Hooke's Law) | 우수 (완전 제어) | 별도 구현 필요 | 중~고 | 1-3장 조작감 튜닝에 적합 |
| flutter_physics (PhysicsController2D) | 우수 (2D fling 지원) | 미지원 | 낮음 | forge2d 없는 단일 카드 대안 |

**최적 결론**: forge2d(충돌/다중 물리) + Flutter SpringSimulation(단일 카드 스냅백) **하이브리드** 채택. forge2d를 버릴 이유는 없으나, 모든 물리를 forge2d에 넣는 것도 최선이 아님.

---

## Details

### 1. Flutter 내장 Simulation 클래스

#### SpringSimulation
- `SpringDescription(mass, stiffness, damping)` + `SpringSimulation` + `AnimationController.animateWith()`로 구성
- 카드 드래그 릴리즈 시 velocity를 넘기면 자연스러운 스냅백 구현 가능
- 파라미터 예: `SpringDescription(mass: 1.0, stiffness: 180.0, damping: 20.0)` → 약간 통통 튀는 카드
- `AnimationController.fling()`: 내장 스프링 + 초기 velocity로 단숨에 fling 구현 (1줄)
- **한계**: 1D 애니메이션만 구동. 2D 카드 위치 이동 시 X/Y 축 별도 컨트롤러 2개 필요 → 코드 증가

#### FrictionSimulation
- 유체 마찰(공기저항) 모델 → 카드 릴리즈 후 점점 감속 → 자연스러운 슬라이딩
- `FrictionSimulation(drag, position, velocity)`: drag 값이 낮을수록 멀리 미끄러짐
- 스크롤 물리(BouncingScrollPhysics 등)에서 검증된 코드 기반 → 안정성 높음
- **타로 활용**: 카드를 세게 밀었을 때 테이블 위를 미끄러지다 멈추는 느낌

#### GravitySimulation
- 중력 가속도 기반 → 카드 드롭 시 가속 낙하 구현
- 기울이기 연동(accelerometer)과 조합 시 직접 구현도 가능하지만, forge2d gravity가 더 유연

#### 조작감 구현 가능성 평가
- 단일 카드 드래그-릴리즈-스냅백: **forge2d 없이 완전 구현 가능**
- 카드-카드 충돌: **불가능** (Simulation 클래스는 충돌 모델 없음)
- 78장 동시 처리: **비현실적** (각 카드마다 AnimationController 인스턴스 관리 복잡도 폭발)

---

### 2. 커스텀 스프링-댐퍼 (Hooke's Law + 감쇠)

#### 수식 기반 구현
```
acceleration = -stiffness * (position - target) - damping * velocity
velocity += acceleration * dt
position += velocity * dt
```
- 게임 루프(Flame `update(dt)`) 내에서 매 프레임 계산 → forge2d body 없이 순수 Dart
- Vector2(x, y)로 2D 직접 처리 가능 (Flame의 Vector2는 mutable → 객체 생성 비용 없음)
- **조작감 완전 제어**: stiffness/damping 값만 바꾸면 "딱딱한 카드" ↔ "말랑한 카드" 즉시 전환

#### 구현 난이도
- 1장: **낮음** (약 30~50줄 Dart 코드)
- 5장 동시: **낮음~중간** (Card 클래스 내 물리 상태 캡슐화)
- 78장 동시 + 충돌: **높음** (충돌 broadphase, AABB 체크, 반발 계산 직접 구현 필요)

#### 주요 패키지: sprung
- pub.dev: [sprung](https://pub.dev/packages/sprung)
- `Sprung.custom(damping: 20, stiffness: 180, mass: 1.0, velocity: 0.0)` → Curve로 사용
- AnimationController의 `drive(CurveTween(curve: Sprung.overDamped))` 패턴
- **한계**: Curve 기반 → velocity 승계 불가 (중간에 새 제스처 들어오면 velocity 리셋)

#### flutter_spring_animation 패키지
- SpringAnimation 위젯 레벨 추상화 → 파라미터(stiffness, damping, velocity) 직접 노출
- 위젯 레벨 추상화라 Flame 게임 루프와 통합 시 마찰

---

### 3. Dart 대안 물리 라이브러리 현황 (2024~2025)

#### flutter_physics (2025년 5월 pub.dev 업데이트)
- GitHub: [sangddn/flutter_physics](https://github.com/sangddn/flutter_physics)
- **핵심 기능**: `PhysicsController2D` — 2D Offset 기반 물리 컨트롤러
  ```dart
  final _ctrl = PhysicsController2D.unbounded(
    vsync: this,
    defaultPhysics: Simulation2D(Spring.elegant, Spring.elegant),
  );
  // pan update
  _ctrl.animateTo(_ctrl.value + details.delta);
  // pan end (velocity 자동 승계)
  ```
- velocity 중간 전환 시 prior velocity 유지 → **카드 드래그 연속 제스처에서 자연스러운 동작**
- `PhysicsControllerMulti`: N차원 확장 가능 (3D 카드 뒤집기 등)
- **한계**: 충돌 없음, 다체 상호작용 없음

#### Flame 내장 Collision Detection (forge2d 없이)
- Flame의 `HasCollisionDetection` + `ShapeHitbox` → sweep-and-prune broadphase
- quad tree broadphase 옵션(`HasQuadTreeCollisionDetection`) → 넓은 필드 최적화
- 78장 카드 AABB 충돌 감지는 **forge2d 없이 Flame 자체로 처리 가능**
- 단, 충돌 후 반발 계산(impulse resolution)은 직접 구현 필요 → forge2d가 이를 자동화

#### 기타 Dart 물리 라이브러리
- **dart_physics**: pub.dev 검색 결과 없음 (Dart 전용 독립 물리 엔진은 2025 기준 forge2d 외 실용적 대안 없음)
- **just_game_engine**: 경량 게임 엔진 (pub.dev 확인됨) → physics 기능 미포함
- **rapier-dart**: Rust rapier 엔진의 Dart 바인딩 — 조사 결과 Dart 공식 포트 없음 (2025 기준)
- 결론: Dart 생태계에서 forge2d는 **사실상 유일한 검증된 2D 물리 엔진**

---

### 4. forge2d vs 커스텀 접근법: 78장 카드 성능 비교

#### forge2d 특성
- Box2D 기반 → 2007년부터 검증된 broadphase + narrow-phase 충돌 파이프라인
- Flame 팀 공식 지원 → `flame_forge2d` 패키지로 Flame 컴포넌트 시스템과 통합
- 78개 Body: Box2D는 수백~수천 개 body를 60fps에서 처리하는 것으로 검증됨 (78개는 매우 여유로운 규모)
- **오버헤드**: World.step() 호출 비용 — 78개 body에서는 무시할 수 있는 수준
- **sleeping 기능**: 정지한 카드를 자동으로 sleep 상태로 전환 → CPU 절약

#### 커스텀 스프링-댐퍼 (78장 동시)
- 각 카드 물리 계산: O(n) → 78장에서 충분히 빠름
- **문제**: 카드-카드 충돌 broadphase를 직접 구현해야 함 → O(n²) naive → 최적화 필요
- AABB sweep-and-prune: 직접 구현 시 500~1000줄 수준의 추가 코드
- Flame의 내장 `HasCollisionDetection`을 커스텀 물리와 조합 시 충돌 감지는 Flame에게 위임 가능

#### 성능 결론
- **단일 카드 조작감**: 커스텀 > forge2d (오버헤드 없음, 즉각적 파라미터 반응)
- **78장 충돌 포함**: forge2d >> 커스텀 (충돌 시스템 완성도 차이)
- **혼합 시나리오 (대부분의 카드는 정적, 1~3장만 활성)**: 커스텀으로도 충분하나 forge2d sleeping이 동일 효과

---

### 5. 카드 드래그-릴리즈 "자연스러운 튕김" 구현 방식

#### Velocity 기반 fling (핵심 패턴)
```dart
// GestureDetector.onPanEnd
void _onPanEnd(DragEndDetails details) {
  final velocity = details.velocity.pixelsPerSecond;
  // forge2d 방식
  body.linearVelocity = Vector2(velocity.dx / scale, velocity.dy / scale);
  // 또는 Flutter Simulation 방식
  _controller.animateWith(SpringSimulation(
    SpringDescription(mass: 1, stiffness: 200, damping: 15),
    currentValue,    // 현재 위치
    targetValue,     // 목표 위치
    velocity.dy / screenHeight,  // 정규화된 초기 velocity
  ));
}
```
- **핵심**: 드래그 종료 시 velocity를 물리 시스템에 그대로 전달 → 관성 표현
- velocity 정규화 필요 (픽셀/초 → 시뮬레이션 단위 변환)

#### 스냅 포인트
- 카드 중심이 특정 영역(예: 덱, 보드 슬롯)에 가까우면 snap
- `SpringSimulation`으로 snap 포인트까지 스프링 애니메이션 → 자연스러운 "달라붙는" 느낌

#### flutter_physics의 velocity 승계
- `PhysicsController2D.animateTo(offset)` — 중간에 새 pan이 와도 prior velocity 보존
- forge2d `body.linearVelocity` 직접 설정도 동일 효과

---

### 6. 카드-카드 충돌: forge2d 없이 가능한가

#### Flame 내장 방식
- `ShapeHitbox` (RectangleHitbox) + `HasCollisionDetection` + `onCollision` 콜백
- broadphase: sweep-and-prune (기본) 또는 quad tree (대규모)
- **충돌 감지는 가능**, 충돌 후 반발(impulse) 계산은 개발자가 직접 작성
- 예: 충돌 시 두 카드의 velocity를 교환하는 단순 탄성 충돌 공식 (약 10줄)

#### 타로 셔플 맥락
- 실제 타로 셔플에서 카드-카드 충돌이 "물리적으로 정확"할 필요는 없음
- 카드가 겹치지 않도록 밀리는 느낌만 있으면 충분 → 단순 반발 공식으로 구현 가능
- **결론**: 카드 충돌을 위해 반드시 forge2d가 필요하지는 않으나, forge2d를 쓰면 작업량이 대폭 감소

---

## Key Findings

1. **Flutter 내장 SpringSimulation/FrictionSimulation**: 단일 카드 조작감(드래그-릴리즈-스냅백) 구현에 충분. forge2d 없이도 자연스러운 물리감 달성 가능. 단, 카드-카드 충돌 모델 없음.

2. **flutter_physics PhysicsController2D** (2025 최신): 2D drag-fling에 최적화된 Flutter 전용 물리 컨트롤러. velocity 승계, 2D 동시 처리, spring 파라미터 노출. forge2d 없는 단일 카드 조작감의 최선 대안.

3. **커스텀 스프링-댐퍼**: Hooke's Law 수식으로 1~3장 카드 조작감 구현은 쉬움(30~50줄). 78장 충돌까지 커스텀으로 구현하면 500줄+ 추가 공수 → 비효율적.

4. **Dart 물리 엔진 생태계**: forge2d 외 실용적 대안 없음. rapier-dart 포트 없음, just_game_engine 물리 미포함. forge2d는 2025 기준 유일한 검증된 선택지.

5. **forge2d 78장 성능**: 78개 body는 Box2D 기준으로 매우 여유로운 규모. sleeping 기능으로 정지 카드 CPU 비용 자동 절감. 성능 병목은 forge2d가 아닌 Rive 렌더링에서 발생할 가능성이 높음.

6. **카드-카드 충돌**: Flame 내장 collision detection으로 감지 가능하나, 반발 계산은 수동 구현 필요. forge2d는 이를 자동화. 타로 셔플 수준의 충돌이라면 단순 반발 공식(10줄)으로 forge2d 없이도 충분.

---

## Recommendations

### 최적 아키텍처: 하이브리드 접근법

```
[사용자 제스처]
    │
    ├─ 드래그 중 (pan update)
    │    → forge2d body.linearVelocity 직접 업데이트 (가장 즉각적)
    │
    ├─ 드래그 릴리즈 (pan end)
    │    → forge2d body에 velocity 전달 (충돌 포함 자연스러운 slowing)
    │    → OR SpringSimulation으로 스냅 포인트로 애니메이션 (충돌 불필요 시)
    │
    └─ 카드 정지 후 스냅백 (예: 덱으로 돌아가기)
         → SpringSimulation / flutter_physics (forge2d body sleep 후)
```

### forge2d 유지 판단: YES

forge2d를 버릴 이유는 없음. 이유:
- 78장 카드 동시 물리: 검증된 성능
- 카드-카드 충돌 자동화: 구현 공수 대폭 절감
- Flame 통합: `flame_forge2d` 공식 지원으로 설계 일관성 유지
- sleeping 최적화: 정지 카드 자동 CPU 절약

### 커스텀 보완 포인트

forge2d 단독 사용 시 추가할 개선사항:
1. **스냅백**: forge2d body를 disable하고 `SpringSimulation`으로 스냅 애니메이션 구동 → 더 정밀한 착지감
2. **fling velocity**: `GestureDetector.onPanEnd`의 pixel velocity를 forge2d 단위로 정규화 후 `body.linearVelocity`에 직접 주입
3. **카드 "들어올림" 효과**: forge2d 관여 없이 위젯 레이어에서 `Transform.scale + Shadow` 조합 → 물리 오버헤드 없음

### 추천 패키지 조합 (조작감 최우선)

| 역할 | 패키지 | 비고 |
|------|--------|------|
| 다체 충돌·물리 | `forge2d` + `flame_forge2d` | 78장 동시 물리의 실질적 유일 선택 |
| 단일 카드 스냅백 | `flutter/physics.dart` (내장) | 외부 패키지 불필요 |
| 2D fling 컨트롤러 | `flutter_physics` (선택적) | `PhysicsController2D`가 편의성 높음 |
| 스프링 커브 | `sprung` (선택적) | `AnimationController` curve로 사용 |

---

## References

- Flutter 공식: [Animate a widget using a physics simulation](https://docs.flutter.dev/cookbook/animation/physics-simulation)
- Flutter API: [SpringSimulation class](https://api.flutter.dev/flutter/physics/SpringSimulation-class.html)
- Flutter API: [FrictionSimulation class](https://api.flutter.dev/flutter/physics/FrictionSimulation-class.html)
- Flutter API: [AnimationController.fling()](https://api.flutter.dev/flutter/animation/AnimationController/fling.html)
- pub.dev: [flutter_physics](https://pub.dev/packages/flutter_physics) (May 2025)
- GitHub: [sangddn/flutter_physics](https://github.com/sangddn/flutter_physics)
- pub.dev: [sprung](https://pub.dev/documentation/sprung/latest/)
- GitHub: [lukepighetti/sprung](https://github.com/lukepighetti/sprung)
- pub.dev: [forge2d](https://pub.dev/packages/forge2d)
- Flame 공식: [Forge2D — Flame](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/forge2d.html)
- Flame 공식: [Collision Detection — Flame](https://docs.flame-engine.org/latest/flame/collision_detection.html)
- Medium: [Why Forge2D Is Bridging the Gap for Physics in Flutter Games](https://medium.com/@ogbonnaijeoma871/why-forge2d-is-bridging-the-gap-for-physics-in-flutter-games-9fdf6c97966b)
- Medium: [Flutter Explicit Animations: Curves vs. Physics vs. Springs](https://medium.com/@punithsuppar7795/flutter-explicit-animations-curves-vs-physics-vs-springs-6dcf3a55aea4)
- DEV Community: [Mastering Physics-based Animation in Flutter](https://dev.to/mostafa_ead/mastering-physics-based-animation-in-flutter-3790)
- Dominik Roszkowski: [Cool Flutter packages: flutter_physics](https://roszkowski.dev/2025/flutter-physics/)
- Google I/O 2024: [Build a 2D physics game with Flutter and Flame](https://io.google/2024/explore/c47e984b-af2f-4f5f-bcde-e148a5a626bf/)

---

## Communication Log
| # | 방향 | 상대 | 내용 요약 | 시점(단계) |
|---|------|------|----------|-----------|
| 1 | 수신 | 오케스트레이터 | 조작감 기준 물리 엔진 대안 조사 요청 (Perspective 3) | 시작 |
| 2 | 반환 | 오케스트레이터 | 하이브리드 결론: forge2d 유지 + Flutter Simulation 보완 권장 | 완료 |

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
