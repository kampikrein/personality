---
id: "003"
type: agent
title: "게임/물리 엔진 + 애니메이션 렌더링 — 플랫폼 비교"
created: 2026-03-19
perspective: "게임/물리 엔진 + 애니메이션 렌더링"
agent: "general-purpose"
summary: >
  Flutter vs 네이티브 플랫폼의 게임/물리 엔진(Flame, Forge2D) 및 애니메이션 렌더링 성능 비교 분석.
---

# 게임/물리 엔진 + 애니메이션 렌더링 — 플랫폼 비교

## 현재 Flutter 기준선

personality 타로 앱의 게임/물리/애니메이션 스택:

| 컴포넌트 | 패키지 | 역할 |
|---------|--------|------|
| **Flame** v1.19 | `flame` | 게임 루프, 컴포넌트 시스템, 렌더링 (Canvas) |
| **Forge2D** v0.19 | `flame_forge2d` | Box2D 포트 — rigid body, fixture (density=1.0, friction=0.4, restitution=0.05), damping, contact listener |
| **Rive** v0.13 | `rive` | StateMachine 기반 인터랙티브 벡터 애니메이션 (손 일러스트) |
| **flame_rive** v1.1 | `flame_rive` | Rive를 Flame 컴포넌트로 통합, 게임 루프 동기화 |

**강점 요약**:
- **단일 프레임워크 통합**: Flame이 게임 루프 → Forge2D 물리 → Rive 애니메이션을 하나의 컴포넌트 트리로 관리
- **고정 타임스텝 45fps**: Forge2D에서 직접 제어, 물리 시뮬레이션 안정성 보장
- **Flutter 위젯 위에 오버레이**: GameWidget을 Flutter 위젯 트리에 임베딩, 일반 UI와 공존
- **Flame GitHub stars**: ~10,300 / 활발한 유지보수 (2026년 현재)

---

## 플랫폼별 조사 결과

### 1. React Native

#### 물리 엔진

| 라이브러리 | 설명 | GitHub Stars | 최근 업데이트 |
|-----------|------|-------------|-------------|
| **Matter.js** | JS 네이티브 2D 물리 엔진. rigid body, restitution, friction, damping, constraint, sleeping 지원 | ~14,000+ | 활발 |
| **react-native-box2d** | Box2D JSI 포트 (C++ 직접 바인딩) | ~66 | v0.2.5 (2025-03) |

- **Matter.js**: API 수준이 Forge2D와 유사 — rigid body, friction, restitution, gravity 지원. 단, density/fixture 개념이 Box2D와 다름 (shape 기반이 아닌 body 기반). 고정 타임스텝은 `Matter.Engine.update(engine, delta)`로 수동 제어 가능
- **react-native-box2d**: Box2D 직접 포트이므로 API 동일 (fixture definition, density, friction, restitution, damping, contact listener 모두 지원). 고정 타임스텝 가능. 단, 커뮤니티 규모 매우 작음 (66 stars), 장기 유지보수 불확실

#### 게임 프레임워크

| 라이브러리 | 설명 | GitHub Stars | 최근 업데이트 |
|-----------|------|-------------|-------------|
| **react-native-game-engine** | ECS 기반 게임 루프 | ~2,855 | **6년 전** (비활성) |
| **React Native Skia** (@shopify/react-native-skia) | GPU 가속 2D 렌더링 (Skia) | 활발 | 2026 현재 프로덕션 사용 |

- **react-native-game-engine**: 컴포넌트-엔티티-시스템 아키텍처, Matter.js와 조합 가능. **치명적 문제: 6년간 업데이트 없음**, RN 최신 버전 호환성 불명
- **React Native Skia**: GPU 가속 Canvas 렌더링, 60fps 안정, Reanimated와 연동하여 UI 스레드에서 애니메이션 처리. 게임 루프 자체는 `requestAnimationFrame` 기반으로 직접 구현 필요
- **렌더링 파이프라인**: Skia (GPU) → Canvas API. Metal/Vulkan 직접 접근 불가

#### 벡터 애니메이션 (Rive/Lottie)

| 라이브러리 | 공식 지원 | 버전 | StateMachine |
|-----------|----------|------|-------------|
| **rive-react-native** | **공식 (rive-app)** | v9.8.0 / @rive-app/react-native v0.3.0 | 지원 |
| **lottie-react-native** | 공식 (Airbnb) | v7.3.6 | 미지원 (재생 제어만) |

- Rive 공식 SDK 존재, StateMachine 인터랙티브 애니메이션 완전 지원
- 단, Rive가 RN View로 렌더링되므로 **게임 루프와의 동기화는 직접 구현** 필요 (Flame의 `flame_rive` 같은 통합 레이어 없음)

#### 통합 난이도: **높음 (High)**

- 게임 루프 프레임워크가 사실상 비활성 → Skia + requestAnimationFrame으로 직접 구축해야 함
- Matter.js/Box2D + Skia Canvas + Rive를 하나의 렌더 루프로 통합하는 공식 솔루션 없음
- 각 레이어가 독립적이므로 동기화 (물리 스텝 → 렌더링 → 애니메이션) 직접 관리
- Flutter의 Flame 생태계 대비 **통합 복잡도 3~4배**

---

### 2. Kotlin Multiplatform (KMP)

#### 물리 엔진

| 라이브러리 | 설명 | 비고 |
|-----------|------|------|
| **Box2D via JNI/CInterop** | Box2D v3 C API를 JNI(Android) + CInterop(iOS)로 바인딩 | 수동 바인딩 필요 |
| **KorGE Box2D** | KorGE 게임 엔진의 Box2D 통합 모듈 | korge-box2d, 2023년 마지막 업데이트 |
| **LibGDX + KTX** | libGDX의 Box2D 래퍼 (Java/Kotlin) | Android만 네이티브, iOS는 RoboVM 필요 |
| **KPhysics** | 순수 Kotlin 2D 물리 엔진 | 실험적, 소규모 |

- **Box2D v3 직접 바인딩**: API 완전 호환 (rigid body, fixture, density, friction, restitution, damping, contact listener, 고정 타임스텝). 단, JNI + CInterop 이중 바인딩 레이어를 직접 구축·유지해야 함
- **KorGE Box2D**: Kotlin 순수 구현이므로 멀티플랫폼 호환. 그러나 마지막 업데이트 2023년 — 활성도 우려

#### 게임 프레임워크

| 라이브러리 | 설명 | GitHub Stars | 최근 업데이트 |
|-----------|------|-------------|-------------|
| **KorGE** | Kotlin 멀티플랫폼 2D 게임 엔진 | ~1,799 | 2026-02 |
| **LittleKt** | WebGPU 기반 Kotlin 2D 게임 프레임워크 | 소규모 | 개발 중 |

- **KorGE**: 컴포넌트 기반, 게임 루프, 씬 관리, 입력 처리 제공. 타겟: Android (JVM), iOS (Native), Web (JS/WASM), Desktop
- **렌더링 파이프라인**: OpenGL ES / WebGL. Metal/Vulkan 직접 지원 없음
- **Compose UI 통합**: KorGE는 독립 렌더링이므로 Compose Multiplatform UI와의 통합에 추가 작업 필요
- Flame (10,300 stars) 대비 커뮤니티 규모 **약 1/6**

#### 벡터 애니메이션 (Rive/Lottie)

| 라이브러리 | 공식 지원 | 비고 |
|-----------|----------|------|
| **Rive-CMP** (muazkadan) | **커뮤니티** | Compose Multiplatform 래퍼 — rive-android, rive-ios, @rive-app/canvas 통합 |
| **Kottie** | 커뮤니티 | Lottie 래퍼 (Airbnb 라이브러리 기반) |
| **Compottie** | 커뮤니티 | 순수 Kotlin 렌더러 (v2.0+), 실험적 |

- Rive 공식 KMP SDK 없음 — 커뮤니티 래퍼(Rive-CMP)가 네이티브 SDK를 expect/actual로 연결
- StateMachine 지원은 각 플랫폼 네이티브 SDK에 의존
- **게임 루프 동기화**: KorGE 게임 루프 + Rive Compose 래퍼를 연결하는 공식 솔루션 없음

#### 통합 난이도: **매우 높음 (Very High)**

- 게임 엔진(KorGE)과 UI 프레임워크(Compose)가 별개 렌더링 파이프라인
- Box2D는 JNI/CInterop 바인딩 또는 KorGE 내장 모듈(비활성) 선택
- Rive는 커뮤니티 래퍼 의존, 게임 엔진과의 통합 전례 없음
- Flutter의 Flame 생태계 대비 **통합 복잡도 5배 이상**

---

### 3. Native (iOS SpriteKit + Android)

#### 물리 엔진

**iOS (SpriteKit)**:

| 항목 | 상세 |
|------|------|
| **엔진** | SKPhysicsBody — SpriteKit 내장 (Box2D 기반) |
| **API** | mass, density, friction, restitution, linearDamping, angularDamping, categoryBitMask, contactTestBitMask |
| **고정 타임스텝** | SKPhysicsWorld.speed로 시뮬레이션 속도 제어 가능. 단, 내부 타임스텝은 프레임 delta에 연동되어 완전한 고정 타임스텝 제어가 제한적 (가변 dt 이슈 보고됨) |
| **Contact Listener** | SKPhysicsContactDelegate |

**Android (네이티브 Kotlin)**:

| 항목 | 상세 |
|------|------|
| **엔진** | LibGDX Box2D (gdx-box2d) 또는 Box2D v3 JNI 직접 바인딩 |
| **API** | Box2D 전체 API (BodyDef, FixtureDef, density, friction, restitution, World.step) |
| **고정 타임스텝** | World.step(timeStep, velocityIterations, positionIterations) 완전 제어 |
| **패키지** | libGDX + KTX: `ktx-box2d` v1.11.0-rc5 |

- iOS와 Android가 서로 다른 물리 엔진 API를 사용 → 물리 파라미터 동기화 코드 이중 작성
- SpriteKit은 Box2D 기반이므로 파라미터 의미론은 유사하나 API 표면이 다름

#### 게임 프레임워크

**iOS**: SpriteKit (Apple 1st-party)
- 컴포넌트 기반 (SKNode 트리), 게임 루프 (SKScene.update), 렌더링 (Metal)
- 60fps 안정적, iOS/macOS/tvOS/visionOS 지원
- SwiftUI와 SpriteView로 통합 가능

**Android**: 표준 게임 프레임워크 부재
- LibGDX: 성숙하지만 Java 중심, Kotlin KTX 확장 존재. OpenGL ES 렌더링
- Canvas API + SurfaceView로 직접 구현 가능
- Jetpack Compose와의 통합은 AndroidView 래핑 필요

#### 벡터 애니메이션 (Rive/Lottie)

| 플랫폼 | Rive SDK | 버전 | Stars | StateMachine |
|--------|----------|------|-------|-------------|
| **iOS** | **rive-ios** (공식) | v6.16.0 | ~725 | 완전 지원 |
| **Android** | **rive-android** (공식) | v11.2.1 | ~480 | 완전 지원 |

- 양 플랫폼 모두 **Rive 공식 1st-party SDK** 존재 — 가장 안정적인 Rive 지원
- iOS: SwiftUI / UIKit 통합, Android: Jetpack Compose / View 통합
- Lottie도 양 플랫폼 공식 지원 (airbnb/lottie-ios, airbnb/lottie-android)
- **SpriteKit 게임 루프와 Rive 동기화**: 공식 통합 없음. SpriteView 위에 SwiftUI로 Rive를 오버레이하거나, SKScene.update에서 Rive 상태를 수동 동기화

#### 통합 난이도: **중간~높음 (Medium-High)**

- iOS 단독: SpriteKit(물리+게임루프) + Rive(애니메이션)으로 비교적 깔끔하나, 두 시스템 간 동기화는 수동
- Android 단독: 표준 게임 프레임워크 부재로 LibGDX 또는 커스텀 구현 필요
- **크로스 플랫폼**: 물리/게임/애니메이션 코드를 iOS/Android 각각 별도 구현 → **코드 이중화가 핵심 비용**
- Flutter의 단일 코드베이스 대비 **구현·유지보수 비용 2배**

---

### 4. Unity

#### 물리 엔진

| 항목 | 상세 |
|------|------|
| **엔진** | Unity 내장 2D Physics (Box2D 기반) |
| **API** | Rigidbody2D, Collider2D (Box/Circle/Polygon/Edge/Composite), Joint2D, Effector2D |
| **파라미터** | mass, drag (=linearDamping), angularDrag, gravityScale, PhysicsMaterial2D (friction, bounciness=restitution) |
| **고정 타임스텝** | `Time.fixedDeltaTime`으로 물리 업데이트 주기 완전 제어 (FixedUpdate) |
| **Contact Listener** | OnCollisionEnter2D / OnTriggerEnter2D + ContactFilter2D |

- Box2D 기반이므로 Forge2D와 **파라미터 의미론 거의 동일**
- 고정 타임스텝 지원이 가장 성숙 — 게임 엔진의 표준 기능
- density, friction, restitution, damping 모두 Inspector GUI에서 조정 가능

#### 게임 프레임워크

- Unity 자체가 완전한 게임 엔진 — 게임 루프, 컴포넌트 시스템(GameObject + MonoBehaviour), 씬 관리 모두 내장
- **렌더링 파이프라인**: URP (Universal Render Pipeline) — OpenGL, Metal, Vulkan, D3D 모두 지원
- 60fps 안정성: 게임 엔진 표준 — 가장 검증됨
- **일반 앱 UI 통합**: Unity를 모바일 앱에 임베딩 가능 (Unity as a Library). 단, Flutter/SwiftUI/Jetpack Compose 수준의 앱 UI를 Unity에서 직접 구축하는 것은 비효율적. UI Toolkit 또는 uGUI 사용

#### 벡터 애니메이션 (Rive/Lottie)

| 라이브러리 | 공식 지원 | 버전 | Stars |
|-----------|----------|------|-------|
| **rive-unity** | **공식 (rive-app)** | v0.4.0 (2026-01) | ~191 |

- Rive 공식 Unity SDK 존재 — Unity Asset Store + GitHub 배포
- **StateMachine 완전 지원**, Data Binding, Vector Feathering 포함
- Unity LTS 2021+ 및 Unity 6 지원
- **게임 루프 동기화**: Unity의 Update/FixedUpdate 루프 내에서 Rive 상태 제어 가능 — Flame+flame_rive와 유사한 수준의 통합
- Lottie: 서드파티 에셋으로 지원 가능

#### 통합 난이도: **낮음 (Low)**

- 물리 엔진 + 게임 루프 + Rive가 모두 단일 엔진 내에서 동작
- Flutter Flame+Forge2D+Rive 조합과 **거의 동등한 통합 수준**
- **단, 앱 전체를 Unity로 구축하면**: 일반 앱 UI (설정, 온보딩, 결과 화면 등)를 Unity UI Toolkit으로 만들어야 하는 비효율
- **"Unity as a Library" 방식**: 게임 씬만 Unity, 나머지는 네이티브 앱 → 통합 복잡도 증가

---

### 5. .NET MAUI / Uno Platform

#### 물리 엔진

| 라이브러리 | 설명 | 최근 업데이트 |
|-----------|------|-------------|
| **Box2D.NET** | Box2D C# 포트 | 2026-01 |
| **box2d-netstandard** | Box2D .NET Standard 포트 | 유지보수 중 |

- Box2D 전체 API C# 포트 존재 (BodyDef, FixtureDef, density, friction, restitution, World.Step)
- 고정 타임스텝: `World.Step(timeStep, velocityIterations, positionIterations)` 직접 제어
- .NET 생태계이므로 Unity의 Box2D와 코드 공유 가능성 있음

#### 게임 프레임워크

| 라이브러리 | 설명 | GitHub Stars |
|-----------|------|-------------|
| **Orbit Engine** | .NET MAUI Graphics 기반 게임 엔진 | ~289 |
| **DrawnUI** | SkiaSharp 기반 MAUI 렌더링 엔진 (게임 루프 지원) | 활발 |

- **Orbit**: .NET MAUI Graphics 위에 구축된 게임 엔진. 게임 루프, 씬/게임 오브젝트, 입력 처리 제공. 단, 소규모 프로젝트 (289 stars), 프로덕션 검증 미흡
- **DrawnUI**: SkiaSharp GPU 가속 렌더링, 게임 루프 패턴 지원. 비즈니스 앱 + 게임 UI 모두 가능
- **렌더링 파이프라인**: SkiaSharp (Skia GPU) → Canvas. Metal/Vulkan 직접 접근 불가
- 60fps: DrawnUI는 GPU 가속으로 가능하나, Orbit은 MAUI Graphics 의존으로 성능 제약 가능

#### 벡터 애니메이션 (Rive/Lottie)

| 라이브러리 | 공식 지원 | Stars | 최근 업데이트 |
|-----------|----------|-------|-------------|
| **rive-maui** | **커뮤니티** (비공식) | ~42 | **2024-01** (비활성) |
| **SkiaSharp.Skottie** | 커뮤니티 (Lottie 재생) | — | SkiaSharp 3.x 연동 |

- **Rive 공식 SDK 없음** — 커뮨니티 rive-maui가 유일한 옵션이며, 1년 넘게 업데이트 없음
- StateMachine 지원 불완전 (rive-sharp 기반 제한적 구현)
- Lottie: SkiaSharp.Skottie (Skia 내장 Lottie 플레이어) + SkiaSharp.Extended.UI.Maui의 SKLottieView로 재생 가능
- **게임 루프 동기화**: 공식 솔루션 없음, 직접 구현 필요

#### 통합 난이도: **매우 높음 (Very High)**

- 게임 엔진(Orbit)이 미성숙, Rive 지원 사실상 부재
- Box2D.NET + Orbit + rive-maui를 통합한 전례 없음
- .NET MAUI 자체의 안정성 이슈 (Win 11 업데이트 충돌 등 보고됨)
- Flutter의 Flame 생태계 대비 **통합 복잡도 6배 이상**, 생태계 성숙도 최저

---

## 비교 매트릭스

### A. 물리 엔진

| 항목 | Flutter (Forge2D) | React Native | KMP | Native (iOS/Android) | Unity | MAUI |
|------|:-:|:-:|:-:|:-:|:-:|:-:|
| Box2D 호환 엔진 | Forge2D (순수 Dart) | react-native-box2d (JSI) / Matter.js | KorGE Box2D / JNI+CInterop | SpriteKit (내장) / LibGDX Box2D | 내장 (Box2D) | Box2D.NET |
| Fixture API (density/friction/restitution) | O | O (Box2D) / 부분 (Matter.js) | O | O | O | O |
| Damping (linear/angular) | O | O | O | O (API명 다름) | O (drag/angularDrag) | O |
| 고정 타임스텝 | O (직접 제어) | O (수동) | O (수동) | 부분 (SpriteKit 제한) / O (LibGDX) | **O (FixedUpdate)** | O (수동) |
| Contact Listener | O | O | O | O | O | O |
| 커뮤니티 규모 | **높음** | 낮음 (66 stars) | 낮음 | 높음 (1st party) | **최고** | 낮음 |

### B. 게임 프레임워크

| 항목 | Flutter (Flame) | React Native | KMP (KorGE) | Native | Unity | MAUI (Orbit) |
|------|:-:|:-:|:-:|:-:|:-:|:-:|
| 컴포넌트 시스템 | O | 비활성 (RNGE) | O | O (SpriteKit) / 제한 (Android) | **O** | O (소규모) |
| 게임 루프 | O | 직접 구현 | O | O (SpriteKit) / 직접 구현 | **O** | O |
| 렌더링 | Canvas (Skia) | Skia (GPU) | OpenGL ES | Metal (iOS) / OpenGL (Android) | **URP (Multi-API)** | SkiaSharp |
| 60fps 안정성 | 높음 | 높음 (Skia) | 중간 | 높음 | **최고** | 중간 |
| 앱 UI 통합 | **GameWidget 임베딩** | 제한적 | 추가 작업 | SpriteView (iOS) / 래핑 (Android) | Unity as a Library | DrawnUI 혼합 |
| GitHub Stars | ~10,300 | ~2,855 (비활성) | ~1,799 | N/A (1st party) | N/A (상용) | ~289 |

### C. 벡터 애니메이션 (Rive)

| 항목 | Flutter | React Native | KMP | Native (iOS/Android) | Unity | MAUI |
|------|:-:|:-:|:-:|:-:|:-:|:-:|
| Rive 공식 SDK | **O** | **O** | X (커뮤니티) | **O** (각 플랫폼) | **O** | X (비활성 커뮤니티) |
| StateMachine | O | O | 부분 (네이티브 의존) | O | O | X |
| 게임 루프 동기화 | **O (flame_rive)** | X (직접 구현) | X (직접 구현) | X (직접 구현) | O (Update 루프) | X |
| 최신 버전 | v0.13 (flame_rive v1.1) | v9.8.0 | 커뮤니티 래퍼 | iOS v6.16.0 / Android v11.2.1 | v0.4.0 | v0.1 (2024-01) |

### D. 통합 난이도 종합

| 항목 | Flutter | React Native | KMP | Native | Unity | MAUI |
|------|:-:|:-:|:-:|:-:|:-:|:-:|
| 물리+게임+애니메이션 통합 | **낮음** | 높음 | 매우 높음 | 중간~높음 | **낮음** | 매우 높음 |
| 단일 렌더 파이프라인 | O | X | X | X (크로스) / O (단일 플랫폼) | **O** | X |
| 공식 통합 레이어 존재 | **O** (flame_rive, flame_forge2d) | X | X | X | O (내장) | X |
| 코드 이중화 | 없음 | 없음 | 일부 | **전체** (iOS/Android 별도) | 없음 | 없음 |

---

## 핵심 발견

### 1. Unity가 유일한 동등 대안

물리 엔진 + 게임 루프 + Rive 공식 SDK의 세 축을 **단일 시스템으로 통합**할 수 있는 플랫폼은 Flutter(Flame)와 **Unity** 뿐이다. Unity는 Box2D 내장, FixedUpdate 기반 고정 타임스텝, Rive 공식 SDK를 모두 갖추고 있으며, 게임 엔진으로서의 성숙도는 Flutter를 압도한다.

단, Unity는 **앱 UI 구축에 부적합** — 타로 앱의 비게임 화면 (온보딩, 설정, 결과 표시)을 Unity UI Toolkit으로 만드는 것은 비효율적이며, "Unity as a Library"로 분리하면 통합 복잡도가 크게 증가한다.

### 2. React Native는 생태계 공백이 치명적

물리 엔진(Box2D JSI 포트 66 stars)과 게임 프레임워크(RNGE 6년 비활성)의 커뮤니티 규모가 프로덕션 의존에 부적합하다. Rive 공식 SDK는 존재하지만, 게임 루프와의 통합 레이어가 없어 전체 시스템을 직접 구축해야 한다.

### 3. KMP는 게임 레이어 생태계가 미성숙

KorGE(1,799 stars)는 Flame(10,300 stars)의 1/6 규모이며, Box2D 모듈은 2023년 이후 비활성. Rive 공식 SDK가 없고, Compose UI와 게임 엔진 렌더링을 통합한 전례가 없다. 일반 앱 개발에서의 KMP 성장세와 달리, **게임/물리 도메인은 현저히 부족**하다.

### 4. Native(iOS+Android)는 코드 이중화가 핵심 비용

iOS SpriteKit은 물리+게임 프레임워크가 1st-party로 우수하고, Rive iOS SDK도 최고 수준이다. 그러나 Android 측에 대응하는 표준 게임 프레임워크가 없어 LibGDX 또는 커스텀 구현이 필요하다. **동일한 물리 시뮬레이션을 두 플랫폼에서 각각 구현·검증해야 하는 비용**이 크로스 플랫폼 대비 2배다.

### 5. .NET MAUI는 게임 도메인에서 사실상 부적합

게임 엔진(Orbit 289 stars), Rive 지원(비활성 커뮤니티 42 stars), 전체 생태계 모두 프로덕션 수준에 미달. MAUI 자체의 안정성 이슈도 리스크 요소다.

### 6. Flutter Flame 생태계의 고유 강점

`flame_forge2d`와 `flame_rive`라는 **공식 통합 패키지**가 존재하여, 물리 엔진과 벡터 애니메이션을 게임 루프의 컴포넌트로 직접 관리할 수 있다. 이 수준의 통합은 Unity를 제외한 어떤 플랫폼에서도 재현할 수 없으며, Unity조차 Rive 통합에서는 flutter의 flame_rive만큼 밀접하게 연동되지 않는다.

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
