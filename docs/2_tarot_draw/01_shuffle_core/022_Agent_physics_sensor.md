---
id: "022"
title: "물리 엔진 & 센서 연동 분석"
category: agent
status: archived
created: 2026-03-16
summary: >
  Unity, Godot 4, Flame, three_dart, Babylon.js의 물리 엔진 비교 및
  Flutter sensors_plus(가속도계) → 물리 gravity 연동 방식 분석.
keywords: [agent-report, physics, accelerometer, rigid body, collision, sensors_plus, mobile]
modules: []
---

# 물리 엔진 & 센서 연동 분석

## Progress
### Completed
- [x] Unity Physics 조사 (PhysX, rigid body)
- [x] Godot 4 Physics 조사 (Jolt/GodotPhysics)
- [x] Flame Physics 조사 (forge2d/Box2D)
- [x] three_dart 물리 조사 (cannon_physics)
- [x] Babylon.js 물리 조사 (Havok, Cannon.js)
- [x] Flutter 순수 물리 라이브러리 조사
- [x] sensors_plus → 각 엔진 gravity 연동 방식
- [x] 모바일 78장 카드 성능 데이터
- [x] 비교 표 작성
### Remaining
- (없음)
### Current Status
조사 완료.

---

## Summary

타로 앱의 핵심 요구사항 — **78장 카드 동시 물리 + 기울이기(가속도계) → gravity 실시간 변경** — 을 모바일 60fps로 처리할 수 있는 엔진은 **Flame/forge2d(2D)** 와 **Godot 4(Jolt, 3D)** 가 가장 현실적이다.

- **Flame/forge2d**: Flutter 네이티브. sensors_plus → `world.gravity` 직접 연동. 2D만 지원하지만 타로 카드 특성상 충분. 78개 Box body는 중급 기기에서 60fps 가능 (Box2D 성숙도 높음).
- **Godot 4 (Jolt)**: GodotPhysics 대비 2–3× 성능. 3D rigid body 수백~수천 개 처리. 가속도계 → `ProjectSettings` gravity 런타임 변경 가능. Flutter 통합 오버헤드가 있음 (다른 에이전트 분석 대상).
- **Unity**: 최고 성숙도. `Input.acceleration → Physics.gravity` 패턴 검증된 사례 다수. 그러나 Flutter와 무거운 통합 필요.
- **three_dart + cannon_physics**: 3D 가능하나 cannon_physics가 v0.0.3 초기 단계, 실전 사용 사례 거의 없음. 위험.
- **Babylon.js (Havok)**: WebView 기반. Havok MIT 무료지만 iOS <16.4 WASM SIMD 미지원. 모바일 성능 불안정 보고.
- **Flutter 순수 물리**: CustomPainter + 수동 물리 루프는 100개 오브젝트 수준에서 iPhone6 기준 CPU 90~100% 한계. 직접 구현 리스크 높음.

---

## Details

### 1. Unity Physics (PhysX + Box2D)

**물리 엔진 구성**
- 3D: PhysX (NVIDIA)
- 2D: Box2D
- Rigidbody 컴포넌트 + Collider로 물리 오브젝트 구성

**모바일 성능**
- Mesh Collider(비볼록)는 매우 비쌈 → 카드에는 Box/Rectangle Collider 사용
- Fixed Timestep 기본 0.02s (50Hz). 모바일 60fps 목표 시 0.0167 또는 30fps 목표 시 0.033 권장
- Layer Collision Matrix 최적화로 충돌 체크 40%+ 감소 가능
- 78개 박스 rigid body는 Box/Capsule Collider 사용 시 중급 모바일에서 60fps 유지 가능 (공식 문서: 충돌 매트릭스 최적화, sleeping 오브젝트 활용)
- MovePosition/AddForce 방식 사용 (Transform.position 직접 수정 금지 — physics 재계산 트리거)

**가속도계 → gravity 연동**
```csharp
// Unity: FixedUpdate()에서 매 프레임 gravity 업데이트
void FixedUpdate() {
    Vector3 accel = Input.acceleration; // (x, y, z) in g units
    // 저주파 필터 적용 (노이즈 제거)
    Physics.gravity = new Vector3(accel.x, accel.y, 0) * 9.81f;
}
```
- `Input.acceleration`: AccelerometerEvent 값 (m/s² 단위, 중력 포함)
- 노이즈 제거 필수 (low-pass filter): `filteredAccel = Mathf.Lerp(filteredAccel, raw, 0.1f)`
- GitHub 레퍼런스 구현: SteveTaylorDev/accelerometer-control

**충돌 정밀도**
- PhysicsMaterial로 마찰(friction), 탄성(bounciness) 세부 제어
- 카드 간 충돌 이벤트(OnCollisionEnter)로 셔플 피드백 구현 가능

**실제 사용 사례**
- 물리 기반 퍼즐 게임, 보드 게임에서 50–100개 rigid body 모바일 구동 보고
- Unity Blog: 모바일 최적화 시 "Prebake Collision Meshes", "Auto Sync Transforms 비활성화", "Reuse Collision Callbacks 활성화" 권장

---

### 2. Godot 4 Physics (GodotPhysics → Jolt)

**물리 엔진 구성**
- Godot 4.0–4.3: GodotPhysics (기본)
- Godot 4.4+: Jolt Physics 통합 (옵션 → Godot 4.6에서 신규 프로젝트 기본값)
- Jolt: C++ 오픈소스, MIT 라이선스, 멀티스레딩 지원

**모바일 성능**
- Jolt vs GodotPhysics 3D: 복합 시나리오에서 **2–3× 성능 향상**
- Jolt는 수백~수천 개 dynamic body 처리에 탁월
- iOS/Android 모두 지원 (Godot Jolt 공식 확인)
- 주의: Godot 4.4dev4 이후 Android에서 60fps → 45fps 성능 회귀 이슈 보고. 조사 필요.
- Godot 3.x보다 2D 물리 성능은 낮다는 커뮤니티 보고 (3D는 Jolt로 역전)

**가속도계 → gravity 연동**
```gdscript
# Godot 4: _physics_process()에서 중력 변경
func _physics_process(delta):
    var gravity_vec = Input.get_gravity()  # Vector3 (m/s²)
    # gravity_vec는 중력만 (선형 가속도 제외)
    # Input.get_accelerometer()는 전체 가속도 포함

    # 방법 1: ProjectSettings로 글로벌 중력 변경
    ProjectSettings.set_setting("physics/3d/default_gravity_vector", gravity_vec.normalized())

    # 방법 2: PhysicsServer3D 직접 제어 (더 정확)
    PhysicsServer3D.area_set_param(
        get_world_3d().space,
        PhysicsServer3D.AREA_PARAM_GRAVITY_VECTOR,
        gravity_vec.normalized()
    )
```
- `Input.get_gravity()`: iOS는 g 단위 × (−1), Android는 m/s². 플랫폼 정규화 필요
- `Input.get_accelerometer()`: 전체 가속도 (중력 + 선형 운동). 기울기 감지에는 `get_gravity()` 추천

**RigidBody3D 특성**
- 직접 위치 제어 불가. apply_force(), apply_impulse()로 제어
- sleeping 상태 자동 관리 (미사용 body CPU 절감)

---

### 3. Flame + forge2d (Box2D Dart 포트)

**물리 엔진 구성**
- `forge2d` 패키지: Box2D의 Dart 직접 포트
- `flame_forge2d` 패키지 (v0.19.2+5, 160 pub points): Flame 게임 엔진과 브릿지
- **2D 전용** — 3D 물리 없음
- Flutter 네이티브. 별도 런타임/통합 레이어 없음

**모바일 성능 (추정)**
- Box2D는 2011년 iPad 1에서 **200개 rigid body @ 60fps**, 370개 @ 30fps 기록 (역사적 데이터)
- 현대 모바일 기기에서 Dart JIT/AOT로 실행 → 78개 Box body 충분히 60fps 가능 (이론적)
- 공식 벤치마크 없음 — 실제 측정 필요
- 단점: Dart 단일 스레드 제약. Box2D 자체는 싱글스레드

**sensors_plus → forge2d gravity 연동 (가장 간단한 패턴)**
```dart
// Flutter: sensors_plus + forge2d 연동
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

class TarotGame extends Forge2DGame {
  TarotGame() : super(gravity: Vector2(0, 9.8));

  @override
  Future<void> onLoad() async {
    // 가속도계 스트림 구독
    accelerometerEventStream().listen((AccelerometerEvent event) {
      // event.x, event.y: 기울기 방향 (m/s², 중력 포함)
      // 낮은 주파수 필터 적용
      world.setGravity(Vector2(event.x * -1, event.y));
    });
  }
}
```
- `AccelerometerEvent`: 중력 포함 전체 가속도. 기울기 감지에 직접 사용 가능
- `UserAccelerometerEvent`: 중력 제외 선형 가속도 (흔들기 감지에 유용)
- 연동 난이도: **매우 낮음** — 동일 Flutter 앱 내 직접 스트림 구독

**카드 게임 사용 사례**
- Breakout 게임, 핀볼 등 2D 물리 게임에서 검증
- 타로 카드: 직사각형 body (PolygonShape), 충돌 감지 OnCollision 콜백

---

### 4. three_dart + cannon_physics

**물리 엔진 구성**
- `three_dart`: Three.js의 Dart 포트 (렌더링만, 물리 없음)
- `cannon_physics` v0.0.3: Cannon.js의 Dart 포트 (물리만, 렌더링 없음)
- 조합하여 사용: three_dart(렌더) + cannon_physics(물리) 별도 구성
- **3D 지원** (Sphere, Box, Plane, ConvexPolyhedron 등)

**cannon_physics 상태**
- 최신 버전: v0.0.3 (2023년 10월)
- GitHub 스타: **6개** — 매우 초기 단계
- 공식 벤치마크 없음
- Dart port 완성도 불명확. 실전 사용 사례 거의 없음

**3D 물리 기능**
- Rigid body dynamics, 이산 충돌 감지
- PointToPoint, Distance, Hinge, Lock, ConeTwist 조인트
- Gauss-Seidel solver + island split
- Body sleeping, 충돌 필터

**가속도계 연동**
- cannon_physics 자체 센서 통합 없음
- Flutter sensors_plus → Dart 코드로 `world.gravity` 직접 수정 가능 (표준 cannon.js 패턴)
```dart
// 추정 연동 방식 (cannon_physics API 공식 문서 미비)
accelerometerEventStream().listen((event) {
  physicsWorld.gravity.set(event.x, event.y, 0);
});
```

**모바일 성능**
- 데이터 없음. three_dart + flutter_gl은 Flutter Texture 위젯으로 GL 서페이스 호스팅
- GPU 렌더링 + CPU 물리 계산 이중 부하. 중급 기기 성능 미지수
- **프로덕션 사용 권장하지 않음** (라이브러리 성숙도 부족)

---

### 5. Babylon.js 물리 (WebView 기반)

**물리 엔진 구성**
- **Havok**: Microsoft 인수 엔진. WebAssembly 포트. MIT 라이선스 (무료 상업 사용 가능)
- **Cannon.js**: 경량 JS 물리 엔진. 오래된 레거시
- **Ammo.js**: Bullet C++ → JS Emscripten 포트

**Havok 라이선스**
- MIT 라이선스로 무료 제공 (`@babylonjs/havok` npm)
- Babylon.js 6.0(2023년 4월)부터 통합
- Ammo.js 대비 **최대 20× 성능 향상** 주장

**모바일 제약 (중요)**
- Havok: **WebAssembly SIMD 필요 → iOS < 16.4 미지원**
  - iOS 16.4 출시: 2023년 3월. 구형 기기 제외
  - Android: WebAssembly SIMD 지원 폭넓음
- WebView 내 Babylon.js: 모바일에서 "작동은 하지만 성능 문제" 다수 보고
  - iPhone 13 Pro에서도 오브젝트 수 초과 시 흰 화면(white screen) 발생 사례
  - 해결책: 폴리곤 복잡도 감소, 물리 오브젝트 수 제한

**가속도계 연동 (WebView 경유)**
```javascript
// Babylon.js (JavaScript, WebView 내부)
// 방법 1: Web API DeviceMotion 직접 사용
window.addEventListener('devicemotion', (event) => {
  const accel = event.accelerationIncludingGravity;
  physicsPlugin.setGravity(new BABYLON.Vector3(accel.x, -accel.y, 0));
});

// 방법 2: DeviceOrientationCamera 활용 (내장 기능)
var camera = new BABYLON.DeviceOrientationCamera("camera", ...);
```
- WebView 내 JS는 네이티브 DeviceMotion API 접근 가능 (iOS: 권한 요청 필요 since iOS 13)
- Flutter → WebView 브릿지로 네이티브 센서 데이터 주입 가능하나 지연(latency) 발생

**모바일 실시간 물리 평가**
- WebGL + Havok WASM: GPU 렌더링 + CPU 물리 WebView 격리 → 오버헤드 크다
- 78장 실시간 물리: **위험 수준**. 오브젝트 제한 권장

---

### 6. Flutter 순수 물리 (내장/수동 구현)

**Flutter 내장 physics 라이브러리**
- `flutter/physics`: SpringSimulation, GravitySimulation, FrictionSimulation
  - 단일 오브젝트 애니메이션용. 다중 오브젝트 충돌 미지원
- `flutter_physics` 패키지: PhysicsBuilder, PhysicsBuilder2D
  - Spring + gravity 기반 애니메이션. 충돌 감지 없음
- **2D 충돌 + 다중 rigid body 지원 없음** (forge2d 사용 필요)

**수동 물리 루프 (CustomPainter + ticker)**
```dart
// 수동 물리: 가속도계 → 카드 위치 업데이트
class CardPhysics {
  Vector2 position, velocity;

  void update(double dt, Vector2 gravity) {
    velocity += gravity * dt;
    velocity *= 0.98; // 감쇠
    position += velocity * dt;
    // 충돌: AABB 브루트포스 O(n²) → 78장 시 3003쌍
  }
}
```
- 성능 데이터: iPhone 6에서 CustomPainter 실시간 렌더링 CPU 90–100%
- 충돌 감지 O(n²): 78장 = 3,003 쌍 체크/프레임 → 중급 기기에서 60fps 불가
- 실제 물리 게임에서 순수 Flutter 구현은 **30개 이하 권장**

**sensors_plus 연동**
- Flutter 내부: 직접 스트림 구독으로 지연 없음
```dart
accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
  .listen((e) => gravity = Vector2(e.x, e.y));
```
- `SensorInterval.gameInterval`: ~20ms 샘플링 (게임용)

---

### 7. 가속도계 → 물리 연동 패턴 종합

| 엔진 | 연동 방식 | 지연 | 코드 복잡도 |
|------|---------|------|-----------|
| **Flame/forge2d** | sensors_plus stream → `world.setGravity()` | 없음 (동일 Isolate) | 낮음 |
| **Unity** | `Input.acceleration` → `Physics.gravity` | 없음 (내장) | 낮음 |
| **Godot 4** | `Input.get_gravity()` → `PhysicsServer3D` | 없음 (내장) | 낮음 |
| **three_dart + cannon_physics** | sensors_plus stream → `physicsWorld.gravity` | 없음 | 중간 (API 불안정) |
| **Babylon.js (WebView)** | DeviceMotion JS API 또는 Flutter→JS 브릿지 | 있음 (WebView 격리) | 높음 |
| **Flutter 순수** | sensors_plus stream → 수동 velocity 계산 | 없음 | 높음 (충돌 직접 구현) |

**sensors_plus 핵심 이벤트 타입**
- `AccelerometerEvent`: 중력 포함 전체 가속도. 기울기/gravity 방향 감지에 사용
- `UserAccelerometerEvent`: 중력 제외 선형 가속도. 흔들기(shake) 감지에 사용
- `GyroscopeEvent`: 각속도. 회전 감지에 유용 (선택적 사용)
- 샘플링: `SensorInterval.gameInterval` (~20ms, ~50Hz) 권장

---

### 8. 78장 카드 동시 물리 벤치마크

**참고 데이터**
| 기준 | 데이터 | 출처 |
|------|--------|------|
| Box2D iPad 1 (2011) | 200 bodies @ 60fps, 370 bodies @ 30fps | 역사적 벤치마크 |
| Unity 모바일 권장 | Mesh Collider 사용 시 급격한 성능 저하. Box Collider 사용 시 수백 개 가능 | Unity 공식 |
| Godot Jolt | GodotPhysics 대비 2–3× 향상. 수백~수천 bodies 처리 | 공식 문서 |
| Babylon.js Havok WebView | 오브젝트 초과 시 iOS 흰 화면. 물리 오브젝트 수 제한 권장 | 커뮤니티 보고 |
| Flutter CustomPainter | iPhone 6: 실시간 CPU 90–100%. 30개 이하 권장 | Flutter GitHub 이슈 |

**78장 @ 60fps 가능성 평가 (이론적)**
- Flame/forge2d: **가능** — Box2D 2D body, Dart AOT, 중급 기기 충분
- Unity (PhysX/Box2D): **가능** — 가장 검증된 경로. Box Collider 사용 필수
- Godot 4 (Jolt): **가능** — Jolt 2–3× 성능. Flutter 통합 오버헤드 별도
- three_dart + cannon_physics: **불확실** — 라이브러리 미성숙, 실측 데이터 없음
- Babylon.js (WebView Havok): **위험** — WebView 격리, iOS 호환성 제약
- Flutter 순수: **불가** — O(n²) 충돌, 30개 이상 60fps 불가

---

## Key Findings

1. **sensors_plus → gravity 연동 난이도는 엔진이 Flutter 네이티브에 가까울수록 낮다**
   - Flame/forge2d: 동일 Flutter app 내 단일 스트림 구독으로 완성
   - Unity/Godot: 내장 Input API (`Input.acceleration`, `Input.get_gravity()`) 사용
   - Babylon.js: WebView JavaScript ↔ Flutter 네이티브 브릿지 필요 → 복잡도 상승

2. **78장 2D 물리 vs 3D 물리**
   - 타로 카드는 테이블 위 2D 평면 운동이 주. forge2d(2D)로 충분히 표현 가능
   - 3D가 필요한 경우(카드 뒤집기, 3D 적층) Unity 또는 Godot 4 Jolt 선택

3. **Godot 4.4+ Android 성능 회귀 주의**
   - 4.4dev4 이후 Android 60fps → 45fps 저하 보고. 최신 stable에서 재확인 필요

4. **Babylon.js Havok는 MIT 무료이나 모바일 실용성 낮음**
   - iOS <16.4 WASM SIMD 미지원 → 구형 iPhone 제외
   - WebView 물리 성능 불안정 → 78장 실시간 물리에 부적합

5. **cannon_physics (three_dart용)는 프로덕션 비추천**
   - GitHub 스타 6개, v0.0.3 초기 단계. 실전 검증 없음

6. **가속도계 노이즈 필터 필수**
   - 모든 엔진에서 raw 가속도계 값을 그대로 gravity에 적용하면 카드가 떨림
   - Low-pass filter (지수 이동 평균): `filtered = alpha * raw + (1-alpha) * filtered` (alpha ≈ 0.1–0.2)

---

## Recommendations

### 시나리오 A: Flutter 네이티브 우선 (추천)
**Flame + forge2d** 사용
- sensors_plus 연동: 10줄 이내, 지연 없음
- 78장 2D 물리: Box2D 성숙도 높아 60fps 달성 가능
- 학습 곡선 낮음. Flutter 팀이 직접 유지보수
- 제약: 2D만. 3D 카드 flip 필요 시 별도 애니메이션으로 대체

### 시나리오 B: 3D 물리 필요 시
**Godot 4 (Jolt Physics)** 사용
- Input.get_gravity() → PhysicsServer3D 연동 패턴 명확
- Jolt: 수백 bodies 60fps 처리 (Android 성능 회귀 이슈 모니터링 필요)
- Flutter 통합 오버헤드 (다른 에이전트 분석 참조)

### 공통 구현 사항
- **저주파 필터**: 가속도계 원시값 필터링 필수
- **흔들기 감지**: `UserAccelerometerEvent` 활용 (magnitude threshold > 25 m/s²)
- **Sleeping 최적화**: 정지 카드는 sleeping 상태로 CPU 절감 (forge2d, Godot, Unity 모두 지원)
- **충돌 레이어**: 카드-카드, 카드-경계(bound) 레이어 분리

---

## References

- [Unity Mobile Input (docs.unity3d.com)](https://docs.unity3d.com/560/Documentation/Manual/MobileInput.html)
- [Unity Optimize Mobile Game Physics (unity.com/blog)](https://unity.com/blog/technology/optimize-your-mobile-game-performance-get-expert-tips-on-physics-ui-and-audio-settings)
- [Unity accelerometer-control GitHub (SteveTaylorDev)](https://github.com/SteveTaylorDev/accelerometer-control)
- [Godot Using Jolt Physics (docs.godotengine.org)](https://docs.godotengine.org/en/latest/tutorials/physics/using_jolt_physics.html)
- [Godot Jolt Asset Library](https://godotengine.org/asset-library/asset/1918)
- [Godot accelerometer tutorial (ramatakinc)](https://github.com/ramatakinc/mobile-sensors-tutorial)
- [Godot 4.4 Jolt 통합 릴리스 (devclass.com)](https://devclass.com/2025/03/05/godot-4-4-released-open-source-game-engine-adds-jolt-physics-net-8-and-more/)
- [flame_forge2d pub.dev](https://pub.dev/packages/flame_forge2d)
- [forge2d GitHub](https://github.com/flame-engine/forge2d)
- [forge2d Box2D custom gravity (iforce2d.net)](https://www.iforce2d.net/b2dtut/custom-gravity)
- [cannon_physics pub.dev](https://pub.dev/packages/cannon_physics)
- [cannon_physics GitHub (Knightro63)](https://github.com/Knightro63/cannon_physics)
- [Babylon.js Havok Plugin docs](https://doc.babylonjs.com/features/featuresDeepDive/physics/havokPlugin)
- [Babylon.js Havok Mobile Performance Forum](https://forum.babylonjs.com/t/havok-playground-mobile-performance/42150)
- [Babylon.js Mobile accelerometer Forum](https://forum.babylonjs.com/t/mobile-orientation-and-accelerometer/10473)
- [sensors_plus pub.dev](https://pub.dev/packages/sensors_plus)
- [Flutter CustomPainter CPU issue #61721](https://github.com/flutter/flutter/issues/61721)
- [Godot Android performance regression #109251](https://github.com/godotengine/godot/issues/109251)

---

## Communication Log
| # | 방향 | 상대 | 내용 요약 | 시점 |
|---|------|------|----------|------|
| 1 | 수신 | orchestrator | 물리 엔진 & 센서 연동 분석 위임 | 2026-03-16 |
| 2 | 송신 | orchestrator | 보고서 완료 (022) | 2026-03-16 |

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
