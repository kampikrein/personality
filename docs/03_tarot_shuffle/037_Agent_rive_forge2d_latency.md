---
id: "037"
title: "Rive ↔ forge2d 연동 Latency 조사"
category: agent
status: archived
created: 2026-03-16
summary: >
  Rive bone 좌표는 artboard.component(name).worldTransform(Mat2D)으로 추출.
  Flame update(dt) 내 순서는 Rive advance → bone 읽기 → forge2d setTransform/linearVelocity.
  손 충돌체는 KinematicBody가 유일한 적합 타입.
  동일 프레임 내 물리-렌더 분리로 인한 1프레임 시각 지연 가능성 존재하나,
  KinematicBody.linearVelocity 방식으로 최소화 가능. 60fps 유지 조건 충족 시 조작감 영향 없음.
keywords: [agent-report, rive, forge2d, flame_rive, latency, kinematic, bone-sync]
modules: []
---

# Rive ↔ forge2d 연동 Latency 조사

## Progress
### Completed
- [x] Rive bone 좌표 추출 공식 API 조사
- [x] Flame update(dt) 동기화 순서 확인
- [x] KinematicBody vs StaticBody 비교
- [x] 프레임 지연 가능성 분석
- [x] 60fps 보장 조건 확인
- [x] latency 조작감 영향 수준 판단
### Remaining
- (없음)
### Current Status
조사 완료.

---

## Summary

Rive bone 위치를 forge2d body에 반영할 때의 latency는 **1프레임(≈16.7ms@60fps) 수준**이며, 올바른 동기화 순서와 KinematicBody 타입 사용 시 **조작감에 실질적 영향 없음**. 60fps 유지를 위해서는 Rive C++ 런타임(rive ≥0.14)과 forge2d 물리 스텝을 동일 Flame 게임 루프 내에서 처리해야 하며, UI 스레드 외부 연산이 없는 Flutter 단일-스레드 구조 특성상 프레임 예산(16.7ms) 초과가 유일한 위험 요소다.

---

## Details

### 1. Rive bone 좌표 추출 공식 API

**공식 API: `artboard.component<T>(name)` + `.worldTransform`**

```dart
// Rive 런타임 (0.14+, C++ 기반 FFI)
final handBone = artboard.component<Bone>('hand_tip');
// 또는 Node 타입으로도 접근 가능
final handNode = artboard.component<Node>('hand_palm');

// worldTransform: Mat2D (6-element 변환 행렬)
// [scaleX, skewY, skewX, scaleY, translateX, translateY]
final mat = handBone.worldTransform;
final worldX = mat[4]; // translateX
final worldY = mat[5]; // translateY
```

**주요 제약사항:**
- `worldTransform`은 읽기/쓰기 모두 가능한 프로퍼티
- `StateMachineController`는 입력 제어(bool/number/trigger)만 담당 — bone 좌표 직접 접근 불가
- bone 좌표는 Rive 에디터의 artboard 로컬 좌표계 기준 → Flutter 화면 좌표로 변환 필요
- Rive GameKit은 현재 iOS/macOS(Apple Silicon)만 지원 — 크로스플랫폼 앱에서는 표준 `rive` 패키지 사용

**rive 패키지 0.14 이전(순수 Dart 런타임)에서는:**
```dart
// 구버전: RuntimeArtboard 내부 API 경유 (비공개)
// 0.14+에서 C++ FFI 기반으로 완전 교체 → 공개 API 안정화
```

---

### 2. Flame update(dt) 내 Rive → forge2d 동기화 순서

**Flame 게임 루프 순서 (단일 프레임 내):**

```
Flutter vsync 콜백
  │
  ├─ [1] FlameGame.update(dt) 호출
  │    ├─ [1a] 모든 Component.update(dt) 순회 (priority 낮은 순)
  │    │    ├─ RiveComponent.update(dt)  ← artboard.advance(dt) 실행
  │    │    │    → Rive 상태머신 + 본 위치 계산 완료
  │    │    └─ HandPhysicsComponent.update(dt)  ← 사용자 정의 컴포넌트
  │    │         → bone.worldTransform 읽기
  │    │         → body.linearVelocity = targetVelocity  (KinematicBody)
  │    └─ [1b] Forge2DGame.update(dt): 물리 스텝 실행
  │         → world.stepDt(dt)  ← 모든 body 위치 갱신
  │
  └─ [2] FlameGame.render(canvas) 호출
       → 모든 Component 렌더링
```

**핵심: RiveComponent의 update(dt) priority를 HandPhysicsComponent보다 낮게(먼저 실행되도록) 설정해야 함.**

Flame에서 priority 숫자가 낮을수록 먼저 update됨 (기본값 0). 따라서:
```dart
// RiveComponent priority를 HandPhysicsComponent보다 낮게 설정
riveComponent.priority = 0;
handPhysicsComponent.priority = 1;
```

이 순서를 지키면 동일 프레임 내에서 Rive bone 계산 → forge2d body 업데이트 → 물리 스텝 → 렌더가 모두 완료된다.

---

### 3. KinematicBody vs StaticBody: 손 충돌체 적합 타입

| 항목 | StaticBody | KinematicBody |
|------|-----------|---------------|
| 이동 가능 | 불가 | 가능 |
| 물리 반응 | 없음 | 없음 |
| 동적 body와 충돌 | 가능 | **가능** |
| 다른 kinematic/static과 충돌 | 없음 | 없음 |
| 매 프레임 위치 변경 | 지원 안 됨 | **지원** |
| 적합성 | 불가 | **유일한 적합 타입** |

**결론: KinematicBody만 사용 가능.**

StaticBody는 물리 엔진이 "영구 고정"으로 처리하므로 매 프레임 위치 변경 시 물리 시뮬레이션 일관성이 깨진다. KinematicBody는 코드로 직접 제어하면서 dynamic body(카드)와 충돌 반응을 받을 수 있는 유일한 타입이다.

**KinematicBody 위치 업데이트 방법:**

```dart
// 방법 A: velocity 방식 (권장 — 물리 스텝이 보간 처리)
final targetPos = boneToWorldPos(bone.worldTransform);
final currentPos = body.position;
final vel = (targetPos - currentPos) / dt;  // 1프레임 내 도달 속도
body.linearVelocity = vel;
body.setAwake(true);

// 방법 B: setTransform 방식 (직접 텔레포트 — 터널링 위험)
body.setTransform(targetPos, body.angle);
body.setAwake(true);
```

velocity 방식이 터널링(얇은 카드를 손이 통과하는 현상)을 방지하고 물리 스텝 내 연속 충돌 감지에 유리하다.

---

### 4. 프레임 지연 가능성 분석

**이론적 지연 경로:**

```
손 제스처 입력
  → Flutter input 처리 (~0ms, 동기)
  → Rive StateMachine 상태 변경
  → [다음 update(dt)] artboard.advance(dt)  ← 최대 1프레임 지연
  → bone.worldTransform 읽기
  → body.linearVelocity 설정
  → world.stepDt(dt)  ← 물리 반영
  → render()  ← 화면 출력
```

**실제 지연 분석:**

| 단계 | 지연량 | 비고 |
|------|--------|------|
| 입력 → Rive 상태 변경 | 0ms | StateMachineController 즉시 반영 |
| Rive 상태 변경 → bone 계산 | 0~16.7ms | 다음 advance(dt) 호출 시 처리 |
| bone → body 위치 반영 | 0ms | 동일 update(dt) 내 처리 가능 |
| body 반영 → 물리 스텝 | 0ms | 동일 프레임 내 world.stepDt() |
| 물리 스텝 → 렌더 | 0ms | 동일 프레임 내 render() |

**총 지연: 최대 1프레임(≈16.7ms@60fps)**

단, 입력이 프레임 중간에 들어오면 다음 프레임 advance(dt)에서야 처리되므로 0~16.7ms 범위의 가변 지연이 발생. 이는 모든 게임 엔진의 정상 동작 범위다.

**추가 위험: BodyComponent 렌더 버그**
`body.setTransform(Vector2(0, 0), angle)` 사용 시 body의 position은 업데이트되지만 렌더는 원래 위치에 그려지는 버그가 2025년 초 보고됨 (flame-engine/flame Issue #3489). velocity 방식으로 회피 가능.

---

### 5. 60fps 보장 조건

**프레임 예산: 16.7ms (60fps 기준)**

Rive + forge2d 동시 실행 시 성능 병목 지점:

| 항목 | 예상 비용 | 최적화 방법 |
|------|---------|------------|
| Rive artboard.advance(dt) | ~2-5ms | rive ≥0.14 C++ 런타임 자동 최적화 |
| bone.worldTransform 읽기 | <0.1ms | 매 프레임 1회만 읽기 |
| forge2d world.stepDt() | ~1-3ms | 복잡한 충돌 형상 단순화 |
| 카드 수 * physics shapes | 선형 증가 | 덱(52장) 중 활성 카드만 물리 처리 |
| Flutter 렌더링 pipeline | ~2-4ms | Impeller(iOS) 자동 최적화 |

**60fps 유지 체크리스트:**
1. rive 패키지 ≥0.14 사용 (C++ FFI 런타임 — 성능 대폭 향상)
2. forge2d 충돌 형상을 단순 다각형/원으로 유지 (메시 형상 금지)
3. 화면에 보이지 않는 카드의 physics body 비활성화 (`body.setActive(false)`)
4. Rive 아트보드를 불필요하게 복수 인스턴스화하지 않음
5. Flutter DevTools의 Timeline 뷰로 프레임 예산 모니터링

**실제 사례:**
- Rive GameKit 공식 블로그에서 Flutter를 선택한 이유로 "60fps 렌더링 역량, 효율적 메모리 관리, 저지연 입력 처리"를 명시
- flame_forge2d + Flame 조합은 2D 물리 게임에서 60fps 달성 가능한 것으로 문서화됨

---

### 6. flame_rive RiveComponent의 Flame 컴포넌트 트리 동작

```dart
// flame_rive 통합 패턴
class HandAnimationComponent extends RiveComponent {
  HandPhysicsBody? _physicsBody;

  @override
  Future<void> onLoad() async {
    // 1. Rive 파일 로드
    final riveFile = await RiveFile.asset('assets/hand.riv');
    final artboard = riveFile.mainArtboard;

    // 2. StateMachineController 연결 (입력 제어용)
    final controller = StateMachineController.fromArtboard(artboard, 'HandSM');
    artboard.addController(controller!);

    // 3. RiveComponent 초기화
    super.artboard = artboard;
  }

  @override
  void update(double dt) {
    super.update(dt);  // artboard.advance(dt) 실행 (bone 계산 완료)

    // bone 좌표 추출 (advance 완료 후)
    final bone = artboard.component<Bone>('hand_tip');
    final mat = bone.worldTransform;
    final worldPos = Vector2(mat[4], mat[5]);

    // forge2d body 업데이트
    _physicsBody?.syncToPosition(worldPos, dt);
  }
}
```

**중요: RiveComponent.update(dt)에서 `super.update(dt)` 호출 후에만 bone 좌표가 최신 상태.**
`super.update(dt)` 전에 읽으면 이전 프레임 값이 반환된다.

---

## Key Findings

1. **Rive bone API**: `artboard.component<Bone>(name).worldTransform` — Mat2D[4], Mat2D[5]가 x, y 위치. 공식 공개 API (rive ≥0.14).

2. **동기화 순서**: `RiveComponent.super.update(dt)` → bone 읽기 → `body.linearVelocity` 설정 → `world.stepDt(dt)` — 모두 동일 프레임 내 완료 가능. priority 설정으로 순서 보장.

3. **손 충돌체 타입**: KinematicBody가 유일한 적합 타입. StaticBody는 매 프레임 이동 불가. velocity 방식 업데이트 권장(터널링 방지).

4. **프레임 지연**: 최대 1프레임(16.7ms). 이는 업계 표준 게임 입력 지연과 동일 수준이며 조작감에 체감되지 않는 범위. 50ms 이상에서 체감 지연 발생.

5. **60fps 조건**: rive ≥0.14 + forge2d 단순 충돌 형상 + 비활성 카드 body off — 이 세 조건 충족 시 충분히 달성 가능.

6. **조작감 영향**: 1프레임(16.7ms) 지연은 일반적인 터치 지연(~30-50ms)보다 작음. 실질적으로 체감되지 않으며 타로 셔플 UX에 영향 없음.

---

## Recommendations

1. **bone 추출**: `artboard.component<Bone>('hand_tip').worldTransform` 사용. StateMachineController가 아닌 artboard 직접 접근.

2. **동기화 패턴**: RiveComponent를 상속하고 `super.update(dt)` 이후에 bone 읽기. priority 0 = Rive, priority 1 = 물리 동기화 컴포넌트.

3. **충돌체**: KinematicBody + linearVelocity 업데이트 방식 채택. `setTransform` 방식은 렌더 버그(Issue #3489) 회피 및 터널링 방지를 위해 지양.

4. **성능**: rive 패키지를 최신(0.14+)으로 유지. 화면 밖 카드는 `body.setActive(false)` 처리.

5. **좌표계 변환**: Rive artboard 좌표계와 Flame/forge2d 월드 좌표계 간 스케일/오프셋 변환 함수를 별도 유틸리티로 분리 — Forge2D는 미터 단위, Flame은 픽셀 단위 혼재 주의.

---

## References

- [flame_rive 공식 문서 — Flame Engine](https://docs.flame-engine.org/latest/bridge_packages/flame_rive/rive.html)
- [flame_forge2d 공식 문서 — Flame Engine](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/forge2d.html)
- [Forge2D Body Types (kinematic/static/dynamic) — Yayo Code](https://yayocode.com/post/7hp4dLXobT8GJ3NtzVOS)
- [Rive GameKit Fundamentals — worldTransform, component() API](https://help.rive.app/rive-gamekit/fundamentals)
- [Rive State Machines — StateMachineController](https://help.rive.app/runtimes/state-machines)
- [Rive Native for Flutter — C++ FFI 런타임](https://rive.app/docs/runtimes/flutter/rive-native)
- [flame-engine/flame Issue #3489 — BodyComponent setTransform 렌더 버그](https://github.com/flame-engine/flame/issues/3489)
- [RiveComponent class — Dart API](https://pub.dev/documentation/flame_rive/latest/flame_rive/RiveComponent-class.html)
- [BodyComponent class — Dart API](https://pub.dev/documentation/flame_forge2d/latest/body_component/BodyComponent-class.html)
- [Flame Components — update/priority 순서](https://docs.flame-engine.org/latest/flame/components.html)
- [Why we chose Flutter for the Rive GameKit](https://rive.app/blog/why-we-chose-flutter-for-the-rive-gamekit)

## Communication Log
| # | 방향 | 상대 | 내용 요약 | 시점(단계) |
|---|------|------|----------|-----------|
| 1 | 수신 | orchestrator | Rive bone→forge2d latency 조사 지시 | 조사 시작 |
| 2 | 송신 | orchestrator | 조사 완료 보고 (bone API, KinematicBody, 1프레임 지연, 60fps 조건) | 조사 완료 |

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
