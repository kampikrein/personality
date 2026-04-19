---
id: "042"
type: research
title: "타로 셔플 조작감 우선 엔진 재검토 — 최종 보고서 (3차 연구)"
created: 2026-03-16
traces_scope: "018"
summary: >
  일러스트 손(Rive 2.5D) 확정 + 조작감 최우선 기준으로 Flame + forge2d + Rive 아키텍처를
  재검토. forge2d는 Dart 생태계 유일 검증 엔진으로 유지 확정. 조작감 핵심 파라미터는
  linearDamping(1.5~3.0). Rive-forge2d 연동 latency 최대 16.7ms로 조작감 영향 없음.
  가속도계 총 지연 25~40ms로 즉각 반응 달성 가능. forge2d + SpringSimulation + 햅틱
  레이어링 하이브리드가 최적 아키텍처.
keywords: [tactile, forge2d, Rive, Flame, physics, sensors_plus, haptic, SpringSimulation, card-feel]
---

# 타로 셔플 조작감 우선 엔진 재검토 — 최종 보고서

## Research Overview

### Background & Motivation
이전 연구(034)에서 경로 B 확정: **Rive 2.5D 일러스트 손 + Flame + forge2d 단일 엔진**.
사용자 최우선 가치: **조작감(tactile feel)** — 카드를 손으로 밀었을 때의 물리적 반응감이 서비스 품질을 결정한다.
이 기준에서 현재 아키텍처가 최선인지, 더 나은 방법이 있는지 5개 관점으로 재검토.

### Research Scope
- 포함: forge2d 물리 파라미터 튜닝, Rive-forge2d 연동 latency, 대안 물리 엔진, 카드 손맛 기법, 가속도계 응답성
- 제외: Rive 손 디자인 상세, 서버/백엔드, 타로 카드 콘텐츠

### Related Documents
- 체크포인트: [035_Research_tactile_engine.md](./035_Research_tactile_engine.md)
- 2차 연구 최종: [034_Research_hybrid_optimization_final.md](./034_Research_hybrid_optimization_final.md)
- 에이전트 보고서: 036~040 | Synthesis: [041](./041_Synthesis_tactile_engine.md)

---

## Perspective 1: 조작감을 결정하는 forge2d 물리 파라미터

### 상태 분석

forge2d(Box2D 기반)에서 "카드를 밀었을 때의 물리적 반응감"을 결정하는 파라미터는 6가지다.

**타로 카드 78장 권장 파라미터:**

```dart
// FixtureDef — 카드 재질
fixtureDef
  ..density = 1.0        // 표준 질량감
  ..friction = 0.4       // 카드-바닥/카드-카드 슬라이드
  ..restitution = 0.05;  // 충돌 후 거의 안 튕김

// BodyDef — 카드 운동 특성
bodyDef
  ..linearDamping = 2.0   // 핵심: 밀었을 때 멈추는 속도감
  ..angularDamping = 1.2  // 회전 안정화
  ..allowSleep = true;    // 78장 성능 필수
```

**파라미터 영향력 순위:**

| 순위 | 파라미터 | 영향 내용 | 권장 범위 |
|------|---------|----------|---------|
| **1** | **linearDamping** | 밀었을 때 멈추는 속도감 — "무게감"의 직접 결정자. 접촉 없이도 항상 작동 | `1.5 ~ 3.0` |
| **2** | **friction** | 카드끼리·바닥 슬라이드 리얼리티. 접촉 중에만 작동 | `0.3 ~ 0.5` |
| **3** | **impulse 적용점** | 카드 중심에서 오프셋 → 자연스러운 회전 유발 | 중심 ± 카드폭 × 0.2~0.3 |
| **4** | **angularDamping** | 회전 안정화 속도 | `1.0 ~ 2.0` |
| **5** | **restitution** | 충돌 후 튕김 (카드는 낮아야 함) | `0.05 ~ 0.1` |
| **6** | **density** | 임펄스 반응 스케일 | `0.5 ~ 2.0` |

**조작 방식별 권장 API:**

| 상황 | API | 이유 |
|------|-----|------|
| 드래그 중 (손가락 추종) | `body.linearVelocity = panDelta / dt` | 질량 무관, 즉각 추종 |
| 플릭 (손가락 뗄 때) | `body.applyLinearImpulse(velocity * mass)` | 즉각 속도 변화, 질량감 반영 |
| 지속 힘 (기울기 중력) | `world.gravity = Vector2(gx, gy)` | 전체 중력장 변경 |

**78장 성능:**
Box2D sleeping body 메커니즘으로 정지 카드는 CPU 연산에서 자동 제외. 실제 활성 body는 조작 중인 5~15장에 불과. 단, **고정 타임스텝(1/45s) 적용 필수** — Android/iOS 간 물리 일관성 보장.

```dart
// 고정 타임스텝 패턴
static const double tickLimit = 1.0 / 45;
double _accumulated = 0;

@override
void update(double dt) {
  _accumulated += dt;
  int steps = _accumulated ~/ tickLimit;
  for (int i = 0; i < steps; i++) {
    world.stepDt(tickLimit);
  }
  _accumulated -= steps * tickLimit;
}
```

### Summary
linearDamping이 조작감의 가장 결정적 파라미터. 2.0 기준값에서 1.5~3.0 범위로 튜닝하면 "가벼운 종이 카드" ↔ "묵직한 고급 카드" 느낌을 구현할 수 있다.

---

## Perspective 2: Rive ↔ forge2d 연동 Latency

### 상태 분석

Flame 게임 루프 내 Rive-forge2d 동기화 구조:

```
Flutter vsync (16.7ms/frame)
  └── FlameGame.update(dt)
       ├── RiveComponent.update(dt)  [priority 0] ← artboard.advance(dt) 실행
       │    → bone 위치 계산 완료
       ├── HandPhysicsComponent.update(dt)  [priority 1]
       │    → bone.worldTransform 읽기 (Mat2D[4]=x, Mat2D[5]=y)
       │    → handBody.linearVelocity = (targetPos - currentPos) / dt
       └── Forge2DGame.update() → world.stepDt(dt) 실행
```

**bone 좌표 추출 공식 API:**
```dart
final bone = artboard.component<Bone>('hand_tip');
final mat = bone.worldTransform;  // Mat2D
final worldX = mat[4];  // translateX
final worldY = mat[5];  // translateY
```

**손 충돌체 타입 비교:**

| 타입 | 매 프레임 이동 | 동적 body 충돌 | 적합성 |
|------|-------------|--------------|--------|
| StaticBody | 불가 | 가능 | 부적합 |
| **KinematicBody** | **가능** | **가능** | **유일 적합** |
| DynamicBody | 가능 | 가능 | 부적합 (물리 영향 받음) |

**Latency 분석:**

| 단계 | 지연 | 비고 |
|------|------|------|
| 입력 → Rive 상태 변경 | 0ms | StateMachineController 즉시 반영 |
| 상태 변경 → bone 계산 | 최대 16.7ms | 다음 advance(dt) 대기 |
| bone → forge2d body | 0ms | 동일 update(dt) 내 처리 |
| body → 물리 스텝 | 0ms | 동일 프레임 내 실행 |
| **총 지연** | **최대 16.7ms** | 체감 임계값(~50ms) 이하 |

**주의사항:**
- `body.setTransform()` 사용 시 렌더 버그 발생(Issue #3489) → `linearVelocity` 방식 사용
- rive ≥0.14 필수 (C++ FFI 런타임, 성능 최적화)
- Rive 좌표계(artboard 기준) → Flame 픽셀 → forge2d 미터 단위 변환 유틸 별도 구현 필요

### Summary
Rive-forge2d 연동의 최대 latency는 1프레임(16.7ms)로 조작감에 영향을 주지 않는다. KinematicBody + linearVelocity 방식이 유일한 안정적 구현 경로.

---

## Perspective 3: 조작감 특화 물리 엔진 대안

### 상태 분석

**결론: forge2d 유지 + Flutter SpringSimulation 하이브리드가 최적**

Dart 물리 엔진 생태계 현황 (2025):

| 접근법 | 78장 충돌 | 조작감 | 구현 비용 | 결론 |
|--------|----------|--------|---------|------|
| **forge2d** | 네이티브 | 튜닝 필요 | 낮음 | **기본 채택** |
| Flutter SpringSimulation | 불가 | 우수 (단일) | 매우 낮음 | **스냅백 보완** |
| 커스텀 스프링-댐퍼 | 별도 구현 | 우수 (1~3장) | 중~고 | 한정 활용 |
| flutter_physics (2025) | 불가 | 우수 (2D fling) | 낮음 | 선택적 보완 |
| rapier-dart | **미존재** | — | — | 불가 |

**최적 역할 분배:**

```
forge2d                → 78장 동시 충돌, 가속도계 중력, 다체 물리
SpringSimulation       → 선택한 카드 1장을 스냅 위치로 이동 (착지 스프링)
flutter_physics        → fling velocity 자연스러운 승계 (선택적)
```

**forge2d를 버리지 않는 이유:**
- Box2D 기반 — 2007년부터 수천 개 게임에서 검증
- flame_forge2d 공식 지원 — Flame 컴포넌트 시스템과 완전 통합
- sleeping body 자동 최적화 — 정지 카드 CPU 비용 자동 절감
- Dart 생태계 유일 검증 2D 물리 엔진

### Summary
forge2d를 대체할 Dart 물리 엔진은 없다. 단, 단일 카드 스냅백/착지에는 Flutter 내장 SpringSimulation이 forge2d보다 더 정밀한 조작감을 제공한다. 두 시스템의 역할 분배가 최적해.

---

## Perspective 4: 카드 게임 "손맛" 구현 사례

### 상태 분석

Marvel Snap, Hearthstone, Solitaire 계열 앱 분석 결과, 손맛은 **세 기둥**으로 구성된다.

**기여도 1위: velocity 기반 fling + SpringSimulation 스냅백**

```dart
GestureDetector(
  onPanEnd: (details) {
    final speed = details.velocity.pixelsPerSecond.distance;
    if (speed > 800) {
      // 플릭: forge2d body에 속도 전달
      final v = details.velocity.pixelsPerSecond;
      body.linearVelocity = Vector2(v.dx / scale, v.dy / scale);
      HapticFeedback.mediumImpact();
    } else {
      // 스냅백: SpringSimulation으로 착지
      _controller.animateWith(SpringSimulation(
        SpringDescription(mass: 1, stiffness: 600, damping: 30),
        currentOffset, 0, -speed / 1000,
      ));
      HapticFeedback.lightImpact();
    }
  },
)
```

**기여도 2위: 카드 집기 다층 시각 피드백 (lift effect)**

| 레이어 | 변화 | 구현 |
|--------|------|------|
| 그림자 | elevation 4 → 24 | `BoxShadow` blur 증가 |
| 크기 | scale 1.0 → 1.05 | `Transform.scale` |
| 기울기 | velocity.x 비례 rotation | `Transform.rotate` |
| 잔상 | opacity 0.3 원래 자리 | `childWhenDragging` |

**기여도 3위: 시점별 햅틱 레이어링**

| 시점 | API | 강도 |
|------|-----|------|
| 카드 터치 시작 | `lightImpact()` | 약 |
| 카드 들어올림 | `mediumImpact()` | 중 |
| 카드-카드 충돌 (forge2d beginContact) | `heavyImpact()` | 강 |
| 착지 성공 | `mediumImpact()` | 중 |
| 스냅백 | `lightImpact()` | 약 |
| 카드 뒤집기 완료 | `heavyImpact()` | 강 |

**forge2d 이벤트 활용:**
```dart
@override
void beginContact(Object other, ...) {
  HapticFeedback.heavyImpact();  // 카드-카드 충돌 순간
}
```

### Summary
조작감 핵심은 물리 엔진만이 아니다. velocity fling + 다층 시각 lift + 햅틱 레이어링 세 기법이 함께 적용될 때 "실제 카드를 다루는 느낌"이 만들어진다.

---

## Perspective 5: sensors_plus 가속도계 응답성

### 상태 분석

**전체 파이프라인:**
```
기기 기울이기
  → 가속도계 이벤트 (iOS: 10ms, Android: 20ms)
  → Stream listener: rawX/rawY 캐싱
  → Flame update(dt): 로우패스 필터 적용
  → world.gravity = Vector2(smoothX * scale, smoothY * scale)
  → 다음 물리 스텝에 즉각 반영
  → 총 지연: 25~40ms (체감 임계값 50ms 이하) ✅
```

**샘플링 레이트:**

| 플랫폼 | 기본값 | 게임 설정 | 주기 |
|--------|--------|---------|------|
| iOS | 100Hz | 기본 충분 | 10ms |
| Android | ~5Hz | `SensorInterval.gameInterval` 필수 | 20ms |

**구현 코드:**
```dart
class TarotGame extends Forge2DGame {
  double _rawX = 0, _rawY = 0;
  double _smoothX = 0, _smoothY = 0;
  static const _alpha = 0.20;  // 타로 권장 (0.18~0.22)
  static const _gravityScale = 3.0;  // linearDamping과 쌍으로 튜닝

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((e) { _rawX = e.x; _rawY = e.y; });
  }

  @override
  void update(double dt) {
    _smoothX += _alpha * (_rawX - _smoothX);
    _smoothY += _alpha * (_rawY - _smoothY);
    world.gravity = Vector2(_smoothX * _gravityScale, _smoothY * _gravityScale);
    super.update(dt);
  }
}
```

**중요 주의사항:**
- `world.gravity` setter는 O(1) 필드 대입, 프레임당 호출 비용 없음
- flame_forge2d는 Flame 좌표계로 y축 통일 — y+ 가 화면 아래 방향
- Android 기본값(normalInterval)은 ~5Hz → 게임에서 반드시 `gameInterval` 명시
- deadzone 권장: 기울기 5° 이하는 기본 중력(0, 9.8) 유지

**linearDamping + gravityScale 쌍 튜닝 원칙:**
```
linearDamping 높으면 → gravityScale도 높여야 기울기 반응이 느껴짐
linearDamping 낮으면 → gravityScale 낮게도 충분히 반응
```

| linearDamping | gravityScale 권장 |
|--------------|-----------------|
| 1.5 (가벼운) | 2.0~3.0 |
| 2.0 (표준) | 3.0~4.0 |
| 3.0 (묵직한) | 4.0~6.0 |

### Summary
sensors_plus + forge2d 조합으로 25~40ms 지연의 즉각적 기울기 반응 달성 가능. Android에서 `gameInterval` 명시와 로우패스 필터(α=0.20)가 필수 조건.

---

## Cross-Analysis

### 문제 연쇄 구조

```
linearDamping(관점1) ←→ gravityScale(관점5)
    반드시 쌍으로 튜닝 — 높은 damping → 높은 gravity scale

forge2d beginContact(관점1) → 햅틱 heavyImpact(관점4)
    충돌 이벤트를 햅틱 트리거로 사용 → "카드끼리 부딪히는 느낌"

Rive KinematicBody 충돌(관점2) → 햅틱 mediumImpact(관점4)
    손이 카드를 치는 순간 → "손으로 미는 느낌"

velocity fling(관점4) → forge2d applyLinearImpulse(관점1)
    GestureDetector velocity → forge2d body에 직접 전달
```

### 공통 패턴
모든 관점에서 "단일 기법보다 레이어링(조합)"이 조작감을 결정한다는 발견이 수렴됨.
물리 파라미터 + 시각 피드백 + 햅틱 피드백이 각각이 아닌 동시 적용될 때 체감 차이가 생긴다.

---

## Comprehensive Conclusion

### 핵심 발견 (우선순위 순)

1. **[Critical] R-042-F1: forge2d 유지 확정** — Dart 생태계 유일 검증 2D 물리 엔진. rapier-dart 미존재. flame_forge2d 공식 통합. 교체 불필요. *(관점 3)*

2. **[Critical] R-042-F2: 조작감 파라미터 1위는 linearDamping** — 1.5~3.0 범위에서 "가벼운 카드" ↔ "묵직한 카드" 결정. 접촉 없이도 항상 작동하는 유일한 감쇠. *(관점 1)*

3. **[High] R-042-F3: Rive-forge2d latency 조작감 영향 없음** — 최대 1프레임(16.7ms). KinematicBody + linearVelocity 방식으로 구현. setTransform 버그(#3489) 회피 필수. *(관점 2)*

4. **[High] R-042-F4: 가속도계 즉각 반응 달성 가능** — 총 지연 25~40ms. Android: `SensorInterval.gameInterval` 명시 + α=0.20 로우패스 필터 필수. iOS는 기본 설정으로 충분. *(관점 5)*

5. **[High] R-042-F5: 조작감 핵심 3기법 — velocity fling + 시각 lift + 햅틱 레이어링** — 세 기법 동시 적용 시 "실제 카드 다루는 느낌". 하나만 있으면 체감 차이 미미. *(관점 4)*

6. **[High] R-042-F6: forge2d + SpringSimulation 하이브리드 최적** — forge2d는 다체 충돌, SpringSimulation은 단일 카드 스냅백. 역할 분배로 조작감 극대화. *(관점 3, 4)*

7. **[Medium] R-042-F7: linearDamping ↔ gravityScale 쌍 튜닝 필수** — linearDamping 높일수록 gravityScale도 함께 올려야 기울기 반응이 살아남. *(관점 1, 5 교차)*

8. **[Medium] R-042-F8: forge2d beginContact → 햅틱 연결** — 카드 충돌 시점을 정확히 포착해 heavyImpact() 트리거. 가장 자연스러운 물리-햅틱 연동. *(관점 1, 4 교차)*

---

### 최종 아키텍처 권장

```
[타로 셔플 조작감 최적 아키텍처]

입력 레이어:
  GestureDetector (velocity 포착) → forge2d body.linearVelocity / applyLinearImpulse
  sensors_plus (gameInterval) → 로우패스 α=0.20 → world.gravity

물리 레이어:
  forge2d (다체 충돌, 중력 시뮬레이션)
    linearDamping: 2.0  friction: 0.4  restitution: 0.05
    allowSleep: true  타임스텝: 1/45s (고정)

시각 레이어:
  Rive (손 애니메이션, KinematicBody 동기화)
  카드 집기: scale 1.05 + BoxShadow blur 증가 + 기울기 rotation

피드백 레이어:
  forge2d beginContact → HapticFeedback.heavyImpact()  [충돌]
  카드 들어올림 → mediumImpact()
  카드 착지 → SpringSimulation + mediumImpact()
  카드 뒤집기 → heavyImpact()
```

---

## Unresolved Items

1. **gravityScale 최적값**: linearDamping 2.0 기준 gravityScale 3.0 권장이나, 실기기 튜닝 없이는 최적값 불명확.
2. **Android 저사양 기기 가속도계**: gameInterval 보장 여부 기기별로 다름 — 중저가 기기 실기기 테스트 필요.
3. **Rive bone worldTransform 좌표계 변환**: artboard 로컬 → Flame 픽셀 → forge2d 미터 변환 유틸 설계 필요 (구현 단계에서 확정).

---

## Referenced File List

| 파일 경로 | 관련 관점 | 역할 |
|----------|---------|------|
| docs/11_tarot_shuffle/036_Agent_physics_params.md | 관점 1 | forge2d 물리 파라미터 상세 |
| docs/11_tarot_shuffle/037_Agent_rive_forge2d_latency.md | 관점 2 | Rive-forge2d 연동 latency 상세 |
| docs/11_tarot_shuffle/038_Agent_physics_alternatives.md | 관점 3 | 물리 엔진 대안 비교 상세 |
| docs/11_tarot_shuffle/039_Agent_card_feel_cases.md | 관점 4 | 카드 손맛 구현 사례 상세 |
| docs/11_tarot_shuffle/040_Agent_accelerometer_response.md | 관점 5 | 가속도계 응답성 상세 |
| mobile/pubspec.yaml | 전체 | 현재 의존성 (sensors_plus 포함 확인) |
| docs/11_tarot_shuffle/034_Research_hybrid_optimization_final.md | 전체 | 2차 연구 최종 (Rive 경로 확정) |
| pub.dev/packages/flame_forge2d | 관점 2 | forge2d + Flame 공식 브릿지 |
| pub.dev/packages/flame_rive | 관점 2 | Rive + Flame 공식 브릿지 |
| flutter/flutter#3489 | 관점 2 | setTransform 렌더 버그 |

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
