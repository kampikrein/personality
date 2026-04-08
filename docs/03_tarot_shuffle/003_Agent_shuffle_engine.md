---
id: "003"
title: "셔플 엔진 & 카드 애니메이션 기술 조사"
category: agent
status: archived
created: 2026-03-15
summary: >
  Flutter 기반 타로 카드 셔플 물리 엔진 및 애니메이션 기술 스택 비교 조사.
  하이브리드 접근(워시 셔플에만 Flame+Forge2D, 나머지는 순수 Flutter 애니메이션) 권장.
keywords: [agent-report, shuffle-engine, flutter, flame, forge2d, animation, performance]
modules: [mobile]
---

# 셔플 엔진 & 카드 애니메이션 기술 조사

## Progress
### Completed
- [x] 물리 엔진 비교 (Flame+Forge2D vs 자체 구현)
- [x] 셔플 모션별 구현 방식 조사
- [x] 애니메이션 도구 비교
- [x] 성능 최적화 전략 조사
### Remaining
- (없음)
### Current Status
조사 완료.

## Summary

78장 타로 카드의 물리 기반 셔플 애니메이션을 60fps로 구현하기 위한 최적 기술 스택을 조사한 결과, **하이브리드 접근법**을 권장한다.

- **리플 셔플 / 오버핸드 셔플**: 순수 Flutter `AnimationController` + `CustomPainter` 조합. 물리 엔진 불필요. cubic-bezier 곡선과 순차 딜레이로 충분히 구현 가능.
- **워시/메시 파일 셔플**: `Flame` + `Forge2D`(flame_forge2d 패키지). 78장 카드의 RigidBody 충돌/마찰 처리에 물리 엔진 필수. Flame의 GameWidget을 앱의 특정 화면에만 임베드하여 사용.
- **카드 플립 애니메이션**: `Transform` + `Matrix4.rotateY()` + perspective `setEntry(3,2,0.001)`. 400ms Y축 3D 회전.
- **Rive/Lottie**: 동적 물리 셔플에는 부적합. 카드 뒤집기 이펙트나 UI 전환 등 보조 애니메이션에만 제한적 활용 가능.

## Details

### 1. 물리 엔진 비교

#### A. Flame 게임 엔진

| 항목 | 평가 |
|------|------|
| **성격** | Flutter 위에 구축된 경량 2D 게임 엔진 |
| **게임 루프** | 위젯 트리 리빌드 대신 프레임 단위 update/render 루프 |
| **성능** | 벤치마크 기준 ~3,600개 엔티티까지 60fps 유지 (위젯 방식은 ~400개) |
| **카드 게임 적합성** | 공식 Klondike 솔리테어 튜토리얼 존재. 스프라이트 시트 기반 카드 렌더링 패턴 확립 |
| **Flutter UI 통합** | `GameWidget` + `overlays` API로 Flutter 위젯과 혼합 가능. 게임 화면 위에 UI 오버레이 지원 |
| **상태 관리 연동** | Riverpod, Bloc 등과 Bridge Package를 통해 통합 가능 |

**장점**: 게임 루프 아키텍처로 다수 스프라이트 렌더링에 최적. Forge2D와 원활한 통합.
**단점**: 앱 전체에 게임 엔진을 도입하는 것은 과잉. 학습 곡선 존재.

#### B. Forge2D (Box2D 포트)

| 항목 | 평가 |
|------|------|
| **성격** | Dart 기반 2D 물리 엔진 (Box2D 포트) |
| **핵심 기능** | RigidBody, 충돌 감지, 마찰/반발 계수, 조인트 |
| **바디 유형** | Static (고정), Dynamic (물리 시뮬레이션), Kinematic (사용자 제어) |
| **충돌 시스템** | sweep-and-prune broad phase + 연속 충돌 감지 + 선형 시간 접촉 솔버 |
| **Flame 통합** | `flame_forge2d` 패키지로 원활한 통합. `Forge2DGame`, `BodyComponent` 제공 |

**장점**: 워시 셔플의 78장 카드 충돌/마찰 시뮬레이션에 필수적. Box2D의 검증된 물리 모델.
**단점**: 리플/오버핸드 셔플처럼 사전 정의된 경로를 따르는 애니메이션에는 과잉.

#### C. 순수 Flutter (AnimationController + CustomPainter)

| 항목 | 평가 |
|------|------|
| **성격** | Flutter 프레임워크 내장 애니메이션 시스템 |
| **핵심 구성** | `AnimationController` + `Tween` + `Curves` + `CustomPainter` |
| **물리 시뮬레이션** | `SpringSimulation`, `FrictionSimulation`, `GravitySimulation` 내장 |
| **패키지** | `flutter_physics`: `PhysicsController` (AnimationController 대체, 속도 보존), `PhysicsController2D` (2D 자유 운동) |
| **성능** | 위젯 방식 ~400개 한계. CustomPainter + Canvas 직접 그리기 시 수천 개 가능 |

**장점**: 추가 의존성 없음. Flutter 생태계와 완전 통합. 학습 비용 최소.
**단점**: 다수 오브젝트 간 충돌 처리를 직접 구현해야 함 (워시 셔플).

#### D. 실제 카드 게임 구현 사례

| 프로젝트 | 접근법 | 특징 |
|---------|--------|------|
| [Solitaire_Flutter](https://github.com/AadumKhor/Solitaire_Flutter) | 순수 Flutter (게임 엔진 없음) | 위젯 기반 카드 렌더링 |
| [Quards](https://github.com/jeffsieu/quards) | 순수 Flutter | 솔리테어 구현 |
| [Flame Klondike 튜토리얼](https://docs.flame-engine.org/latest/tutorials/klondike/step1.html) | Flame 엔진 | 공식 튜토리얼. 스프라이트 시트 기반 |
| [The Deck](https://github.com/xajik/thedeck) | Flutter | 크로스 플랫폼 카드 게임 엔진 |
| [Flutter I/O FLIP](https://github.com/flutter/io_flip) | Flutter + Firebase | Google I/O 2023 공식 카드 게임 |
| [flutter-cardgame](https://github.com/tylersavery/flutter-cardgame) | Flutter | 카드 게임 엔진 강좌 코드 |

**핵심 관찰**: 대부분의 Flutter 카드 게임은 **게임 엔진 없이 순수 Flutter**로 구현됨. 물리 충돌이 필요한 경우에만 Flame+Forge2D를 도입하는 패턴.

---

### 2. 셔플 모션별 구현 방식

#### A. 리플 셔플 (Riffle Shuffle)

**기술적 난이도**: 중 (★★★☆☆)

**구현 접근법**:
- 덱을 상하 두 뭉치로 분할 (List를 반으로 나눔)
- 각 카드에 `AnimationController`의 `Tween<Offset>` 적용
- cubic-bezier 커브 (`Curves.easeInOut` 또는 커스텀 `Cubic(x1, y1, x2, y2)`)로 호(arc) 경로 생성
- 카드별 150~200ms 순차 딜레이 (`Future.delayed` 또는 `Interval` 커브)
- 20ms 간격 순차 시작으로 물 흐르듯 교차되는 시각적 효과

**구현 스택**: 순수 Flutter
- `AnimationController` + `CurvedAnimation`
- `CustomPainter`로 Canvas에 카드 이미지 직접 그리기
- `Staggered Animation` 패턴 (카드별 시작 시간 오프셋)

**주요 고려사항**:
- 78장 전체가 아닌 "보이는 카드"만 애니메이션 (상단 10~15장만 시각화)
- `AnimationController`를 풀링하여 재사용 (78개 개별 컨트롤러는 낭비)

#### B. 오버핸드 셔플 (Overhand Shuffle)

**기술적 난이도**: 중 (★★★☆☆)

**구현 접근법**:
- 덱에서 랜덤 크기의 청크(5~15장)를 분리
- Z축 이동으로 깊이감 표현: `Transform` + `Matrix4`의 `setEntry(3,2,0.001)` perspective
- 청크가 위에서 아래로 떨어지는 모션: Y축 `Tween` + `Curves.easeIn`(중력 가속)
- 카드 겹침 순서: `Stack` 위젯의 인덱스 또는 CustomPainter 내 paint 순서로 관리

**구현 스택**: 순수 Flutter
- `AnimationController` + `Transform` (3D 깊이감)
- `flutter_physics`의 `GravitySimulation` 또는 커스텀 물리
- 센서 데이터(상하 흔들기)와 연동 시 청크 분리 타이밍 조절

**주요 고려사항**:
- Z축 깊이감이 핵심 차별화. `setEntry(3,2, value)`의 perspective 값 조정으로 3D 효과 강도 제어
- 청크 크기를 센서 강도에 비례시키면 사용자 개입감 향상

#### C. 워시/메시 파일 (Wash/Messy Pile)

**기술적 난이도**: 상 (★★★★★)

**구현 접근법**:
- 78장 카드를 화면 전체에 랜덤 위치/각도로 흩뿌리기
- 각 카드를 `Dynamic BodyComponent` (Forge2D RigidBody)로 생성
- 화면 경계를 `Static Body`로 설정 (카드가 화면 밖으로 나가지 않도록)
- 사용자 손가락 터치/드래그를 `Kinematic Body`로 변환하여 카드와 충돌
- 카드 간 충돌 시 마찰 계수/반발 계수로 자연스러운 밀림/회전 표현
- 드래그 궤적의 속도/방향을 `applyForce`/`applyLinearImpulse`로 전달

**구현 스택**: Flame + Forge2D (flame_forge2d)
- `Forge2DGame` 확장 클래스
- 각 카드 = `BodyComponent` (Dynamic, 사각형 Shape)
- 손가락 = `Kinematic Body` (원형, 터치 좌표 추적)
- `ContactListener`로 충돌 이벤트 감지 → 햅틱 피드백 트리거

**주요 고려사항**:
- **78장 동시 물리 시뮬레이션**: Box2D 기반 Forge2D는 수백 개 바디를 안정적으로 처리 가능
- **성능 병목**: 물리 연산보다 **렌더링**이 병목. 78장 카드 이미지를 매 프레임 그리는 것이 비용
- **스프라이트 시트**: 78장 카드를 단일 텍스처 아틀라스로 묶어 draw call 최소화
- **충돌 최적화**: Forge2D의 broad-phase (sweep-and-prune)가 자동으로 불필요한 충돌 쌍 제거

---

### 3. 애니메이션 도구 비교

| 도구 | 적합도 | 용도 | 비고 |
|------|--------|------|------|
| **AnimationController + Tween** | ★★★★★ | 리플/오버핸드 셔플의 카드 이동/회전 | 가장 유연하고 성능 좋음. 핵심 도구 |
| **CustomPainter + Canvas** | ★★★★★ | 78장 카드 동시 렌더링 | 위젯 트리 오버헤드 없이 직접 그리기. 필수 |
| **Transform + Matrix4** | ★★★★★ | 카드 플립 3D 회전, Z축 깊이감 | `rotateY()` + `setEntry(3,2,0.001)` perspective |
| **Rive** | ★★☆☆☆ | 보조 이펙트 (카드 뒤집기 광채 등) | 인터랙티브 상태 머신 강점이나, 동적 물리 셔플에는 부적합 |
| **Lottie** | ★☆☆☆☆ | 사전 정의 이펙트 (파티클, 빛 효과) | 프리셋 애니메이션 전용. 동적 카드 위치 제어 불가 |
| **flutter_physics** | ★★★★☆ | 물리 기반 모션 (스프링, 마찰, 중력) | `PhysicsController` = AnimationController 대체. 속도 보존으로 제스처 연속성 우수 |
| **Flame SpriteComponent** | ★★★★☆ | 워시 셔플의 카드 렌더링 | 스프라이트 시트 기반. `drawAtlas` 최적화 |

#### 카드 플립 3D Y축 회전 (400ms) 구현 패턴

```dart
// 핵심 패턴 (의사 코드)
AnimationController _controller = AnimationController(
  duration: Duration(milliseconds: 400),
  vsync: this,
);

Widget build(context) {
  return AnimatedBuilder(
    animation: _controller,
    builder: (context, child) {
      final angle = _controller.value * pi; // 0 → 180도
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)  // perspective
          ..rotateY(angle),
        child: _controller.value < 0.5
          ? cardBack    // 전반부: 뒷면
          : Transform(  // 후반부: 앞면 (좌우 반전 보정)
              transform: Matrix4.identity()..rotateY(pi),
              alignment: Alignment.center,
              child: cardFront,
            ),
      );
    },
  );
}
```

#### Rive vs Lottie 상세 비교

| 기준 | Rive | Lottie |
|------|------|--------|
| **FPS 성능** | ~60fps (양 쓰레드) | ~17fps (양 쓰레드) |
| **파일 크기** | 10-15x 작음 (바이너리 포맷) | 상대적 큼 (JSON) |
| **인터랙티브** | State Machine으로 실시간 입력 반응 | 사전 정의된 재생만 가능 |
| **도구 의존성** | 자체 에디터 | After Effects 필요 |
| **동적 물리** | 불가 (사전 디자인된 모션만) | 불가 |
| **적합 용도** | 카드 뒤집기 이펙트, 버튼 반응 | 로딩 스피너, 성공/실패 이펙트 |

**결론**: 셔플 코어 로직에는 Rive/Lottie 모두 부적합. 카드 위치가 런타임에 동적으로 결정되므로 프로그래매틱 애니메이션(`AnimationController`)이 필수.

---

### 4. 성능 최적화 전략

#### A. 렌더링 엔진: Impeller (Flutter 3.29+)

Flutter의 새 렌더링 엔진 Impeller이 성능에 핵심적 영향:
- **셰이더 사전 컴파일 (AOT)**: Skia의 JIT 셰이더 컴파일로 인한 첫 애니메이션 재생 시 jank 제거
- **프레임 래스터화 50% 향상**: 복잡한 씬에서 평균 프레임 시간 ~6.57ms (Skia ~7.71ms)
- **120fps 목표 달성률**: Impeller 91.6% vs Skia 67.1% (8.33ms 기준)
- **드롭 프레임 감소**: Lottie + 커스텀 스크롤 앱에서 Skia 12% 드롭 → Impeller 1.5%
- **플랫폼 지원**: iOS 기본 활성화, Android API 29+ Vulkan 기반 기본 활성화

#### B. RepaintBoundary 전략

```
[전체 셔플 화면]
  ├─ RepaintBoundary: [덱 영역 - 카드 애니메이션] ← 매 프레임 다시 그림
  ├─ RepaintBoundary: [UI 컨트롤 - 셔플 버튼 등] ← 거의 변경 없음
  └─ RepaintBoundary: [상태 표시 - 카드 수 등] ← 가끔 변경
```

- 카드 애니메이션 영역과 정적 UI를 RepaintBoundary로 분리
- 카드 영역 내부에서는 `CustomPainter`의 단일 paint() 호출로 전체 카드 그리기 (개별 RepaintBoundary 과다 사용 금지)
- `shouldRepaint()` 오버라이드로 불필요한 리페인트 방지

**주의**: RepaintBoundary 과용은 메모리/GPU 업로드 비용 증가. Flutter DevTools로 프로파일링 후 적용.

#### C. 카드 이미지 렌더링 최적화

| 전략 | 설명 |
|------|------|
| **스프라이트 시트** | 78장 카드를 단일 PNG 아틀라스로 병합. `drawAtlas()` 단일 호출로 렌더링 |
| **precacheImage** | 앱 시작 시 카드 이미지 사전 로드. 첫 셔플 시 지연 방지 |
| **해상도 관리** | 카드 크기 기준 2x-3x 해상도만 유지. 과도한 원본 이미지는 리사이징 |
| **텍스처 캐시** | Flutter `ImageCache` 크기 조정. 78장 카드 + 뒷면 = 79개 이미지 캐시 유지 |
| **지연 로드** | 워시 셔플 시에만 전체 78장 로드. 리플/오버핸드는 상단 카드만 |

#### D. 78장 개별 상태 관리

```
CardState {
  x: double       // 화면 X 좌표
  y: double       // 화면 Y 좌표
  z: int          // 레이어 순서 (Z-index)
  rotation: double // 회전 각도
  faceUp: bool    // 앞면/뒷면
  reversed: bool  // 역방향 여부
}
```

- **위젯 방식 (비추천)**: 78개 `AnimatedPositioned` → Stack 리빌드 매 프레임 → ~400개 한계
- **CustomPainter 방식 (권장)**: `List<CardState>` 배열을 단일 `paint()` 호출에서 순회하며 Canvas에 그리기
- **Flame 방식 (워시 전용)**: 각 카드 = `SpriteComponent` + `BodyComponent`, Flame 게임 루프가 자동 관리

#### E. 구형 디바이스 테스트 전략

| 전략 | 세부 사항 |
|------|----------|
| **프로파일 모드 테스트** | `flutter run --profile` (debug 모드는 실제 성능과 괴리) |
| **타겟 디바이스** | Android 8-9 (API 26-28), RAM 2-3GB 저사양 폰 |
| **프레임 목표** | 16.67ms/프레임 (60fps). DevTools 프레임 타임라인으로 검증 |
| **통합 테스트** | `flutter test --profile`로 `average_frame_build_time_millis < 16ms` 자동 검증 |
| **Impeller 폴백** | Android API 28 이하는 Vulkan 미지원 → OpenGL ES 폴백. 별도 성능 검증 필요 |
| **메모리 모니터링** | 78장 고해상도 이미지 동시 로드 시 OOM 주의. 2-3GB RAM 기기에서 검증 |

## Key Findings

1. **하이브리드 접근이 최적**: 셔플 유형별로 다른 기술 스택 사용이 최선. 리플/오버핸드는 순수 Flutter, 워시/메시는 Flame+Forge2D.

2. **Flame은 전체 앱이 아닌 특정 화면에만 임베드**: `GameWidget`을 앱의 워시 셔플 화면에만 사용하고, 나머지는 일반 Flutter 위젯 트리로 구성.

3. **CustomPainter가 핵심 성능 열쇠**: 위젯 방식은 ~400개 한계이나, Canvas 직접 그리기는 수천 개 처리 가능. 78장은 여유로운 수준.

4. **Impeller가 게임 체인저**: AOT 셰이더 컴파일로 첫 애니메이션 jank 제거, 프레임 드롭 70%+ 감소. Flutter 3.29+ 기본 활성화.

5. **Rive/Lottie는 핵심 셔플에 부적합**: 카드 위치가 런타임 동적 결정이므로, 프로그래매틱 애니메이션만 가능. 보조 이펙트에만 활용.

6. **flutter_physics 패키지 활용 가치**: `PhysicsController`의 속도 보존 기능은 제스처 → 애니메이션 전환의 자연스러움에 핵심적.

7. **스프라이트 시트 + drawAtlas가 렌더링 최적화 핵심**: 78장 개별 이미지 로드 대신 단일 아틀라스에서 `drawAtlas()` 호출.

## Recommendations

### 권장 기술 스택

```
┌─────────────────────────────────────────────────┐
│                셔플 엔진 기술 스택                  │
├─────────────────────────────────────────────────┤
│                                                 │
│  [리플 셔플]  [오버핸드 셔플]                       │
│  ├─ AnimationController + Tween                 │
│  ├─ CustomPainter (Canvas 직접 그리기)             │
│  ├─ Curves.cubicBezier / 커스텀 곡선               │
│  ├─ flutter_physics (PhysicsController)          │
│  └─ Staggered Animation 패턴                     │
│                                                 │
│  [워시/메시 셔플]                                  │
│  ├─ Flame (GameWidget, SpriteComponent)          │
│  ├─ Forge2D (BodyComponent, ContactListener)     │
│  ├─ flame_forge2d 패키지                          │
│  └─ 화면 경계 Static Body + 카드 Dynamic Body      │
│                                                 │
│  [공통]                                          │
│  ├─ 카드 플립: Transform + Matrix4.rotateY()      │
│  ├─ 이미지: 스프라이트 시트 + precacheImage        │
│  ├─ 렌더링: Impeller (Android API 29+)            │
│  └─ 성능: RepaintBoundary + shouldRepaint 최적화  │
│                                                 │
└─────────────────────────────────────────────────┘
```

### pubspec.yaml 의존성 제안

```yaml
dependencies:
  flame: ^1.22.0           # 워시 셔플 전용 게임 엔진
  flame_forge2d: ^0.18.0   # 2D 물리 (워시 셔플 충돌)
  flutter_physics: ^1.1.0  # 물리 기반 애니메이션 (리플/오버핸드)
  # rive: ^0.13.0          # 선택 - 보조 이펙트용
```

### 구현 우선순위

1. **Phase 1**: 리플 셔플 (순수 Flutter) — 기본 카드 렌더링 파이프라인 구축
2. **Phase 2**: 오버핸드 셔플 (순수 Flutter) — 3D 깊이감 추가
3. **Phase 3**: 카드 플립 애니메이션 — Transform + Matrix4
4. **Phase 4**: 워시/메시 셔플 (Flame+Forge2D) — 가장 높은 난이도, 마지막 구현

## References

### 공식 문서
- [Flutter 애니메이션 물리 시뮬레이션 쿡북](https://docs.flutter.dev/cookbook/animation/physics-simulation)
- [Flutter 성능 프로파일링](https://docs.flutter.dev/perf/ui-performance)
- [Flutter 성능 베스트 프랙티스](https://docs.flutter.dev/perf/best-practices)
- [Flame 엔진 공식 문서](https://docs.flame-engine.org/)
- [Flame Klondike 튜토리얼](https://docs.flame-engine.org/latest/tutorials/klondike/step1.html)
- [Flame Forge2D 문서](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/forge2d.html)
- [Flame Overlays API](https://docs.flame-engine.org/latest/flame/overlays.html)
- [Flutter Impeller 렌더링 엔진](https://docs.flutter.dev/perf/impeller)
- [RepaintBoundary 클래스](https://api.flutter.dev/flutter/widgets/RepaintBoundary-class.html)
- [precacheImage 함수](https://api.flutter.dev/flutter/widgets/precacheImage.html)
- [Flutter Casual Games Toolkit](https://flutter.dev/games)
- [Google Codelabs: Flame 소개](https://codelabs.developers.google.com/codelabs/flutter-flame-brick-breaker)

### 패키지
- [forge2d (pub.dev)](https://pub.dev/packages/forge2d)
- [flame_forge2d (pub.dev)](https://pub.dev/packages/flame_forge2d)
- [flutter_physics (pub.dev)](https://pub.dev/packages/flutter_physics)

### 벤치마크 & 비교
- [Flutter/Flame/Unity/Godot 벤치마크](https://filiph.net/text/benchmarking-flutter-flame-unity-godot.html)
- [Comparing Flutter game engines (LogRocket)](https://blog.logrocket.com/comparing-flutter-game-engines/)
- [Flame 2025 경쟁력 분석](https://genieee.com/flutter-game-development-is-flame-a-real-competitor-in-2025/)
- [Impeller vs Skia 비교 (2026)](https://dev.to/eira-wexford/how-impeller-is-transforming-flutter-ui-rendering-in-2026-3dpd)
- [Rive vs Lottie 비교 (2025)](https://dev.to/uianimation/rive-vs-lottie-which-animation-tool-should-you-use-in-2025-p4m)

### 카드 게임 오픈소스
- [Solitaire_Flutter (순수 Flutter)](https://github.com/AadumKhor/Solitaire_Flutter)
- [Quards (Flutter 솔리테어)](https://github.com/jeffsieu/quards)
- [The Deck (카드 게임 엔진)](https://github.com/xajik/thedeck)
- [Flutter I/O FLIP (Google 공식)](https://github.com/flutter/io_flip)
- [flutter-cardgame 엔진](https://github.com/tylersavery/flutter-cardgame)

### 기술 아티클
- [Flutter 60fps 애니메이션 마스터리](https://medium.com/@mohamedyousufdev/flutter-animation-mastery-creating-smooth-60fps-animations-that-users-love-dc3d31d4716d)
- [GPU-Friendly CustomPainter 애니메이션](https://medium.com/@workflow094093/gpu-friendly-animations-in-flutter-building-60-fps-parallax-with-custompainter-c8555e6734e9)
- [Flutter 카드 플립 3D 애니메이션](https://medium.com/flutter-community/flutter-flip-card-animation-eb25c403f371)
- [Flutter 카드 플립 perspective](https://medium.com/flutter/perspective-on-flutter-6f832f4d912e)
- [Forge2D와 Flutter 물리 게임](https://medium.com/@ogbonnaijeoma871/why-forge2d-is-bridging-the-gap-for-physics-in-flutter-games-9fdf6c97966b)
- [Flame 최적화 기법](https://asgalex.medium.com/flutter-flame-simplest-optimization-techniques-372dbe6815f)
- [저사양 디바이스 Flutter 최적화](https://medium.com/@mohantaankit2002/optimizing-flutter-apps-for-low-end-devices-without-compromising-features-3163dcc1f570)
- [Rive가 Flutter에서 Lottie보다 나은 이유](https://medium.com/@imaga/rive-animation-for-flutter-apps-why-we-prefer-it-over-lottie-when-to-use-it-and-key-features-to-c412154449bc)
- [flutter_physics 패키지 소개](https://roszkowski.dev/2025/flutter-physics/)

### 프로젝트 내부 참조
- `docs/003_gemini_deep_research.md` — PRD 원본 (셔플 시스템 요구사항)
- `docs/11_tarot_shuffle/001_Scope_platform_strategy.md` — 플랫폼 전략 (Android Flutter 먼저)

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
