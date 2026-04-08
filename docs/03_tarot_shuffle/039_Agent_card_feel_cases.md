---
id: "039"
title: "카드 게임 손맛 구현 사례 조사"
category: agent
status: archived
created: 2026-03-16
summary: >
  실제 카드 앱(Marvel Snap, Hearthstone, Solitaire) 및 Flutter/iOS 구현 사례 조사.
  손맛에 가장 기여하는 상위 3개 기법은 (1) velocity 기반 fling + SpringSimulation 스냅백,
  (2) 카드 집기 시 다층 시각 피드백(elevation/shadow/scale/tilt), (3) 시점별 햅틱 레이어링.
keywords: [agent-report, haptic, drag, fling, card-game, tactile, gesture]
modules: []
---

# 카드 게임 손맛 구현 사례 조사

## Progress
### Completed
- [x] 드래그 반응 구현 패턴 조사
- [x] 햅틱 피드백 활용 방식 조사
- [x] 카드 집기/놓기 시각 피드백 조사
- [x] Flutter velocity 기반 fling 패턴 조사
- [x] 조작감 기여 상위 3개 기법 도출
### Remaining
- (없음)
### Current Status
조사 완료.

---

## Summary

카드 게임 손맛은 **드래그 물리(velocity fling + spring snap)**, **다층 시각 피드백(lift/shadow/tilt)**, **시점별 햅틱 레이어링** 세 기둥으로 구성된다. Marvel Snap은 카드마다 고유 햅틱+시각 이펙트를 결합해 "무게감"을 구현한 업계 레퍼런스다. Flutter는 `GestureDetector` + `AnimationController.animateWith(SpringSimulation)` 조합으로 이 세 기법을 모두 구현할 수 있다.

---

## Details

### 1. 드래그 반응 패턴 — velocity 기반 fling + snap

#### 핵심 구조
```
onPanStart  → 카드 상태 전환 (lifted=true), 햅틱 light
onPanUpdate → _pos += delta (1:1 추적)
onPanEnd    → velocity 판정:
               |velocity| > threshold → fling (AnimationController.fling)
               else                  → snap back (animateWith(SpringSimulation))
```

#### Flutter API
- `DragEndDetails.velocity` — 릴리즈 시점의 픽셀/초 벡터 제공
- `DragGestureRecognizer` — `minFlingVelocity`, `minFlingDistance` 설정 가능
- `AnimationController.animateWith(SpringSimulation(...))` — 속도를 초기값으로 넘겨 자연스러운 착지
- `SpringDescription(mass: 1, stiffness: 600, damping: 30)` — 카드 감각 기준값 (stiffness 높을수록 탄성 큼)

#### 업계 사례
- **Hearthstone**: 드래그 중 카드가 "공기 저항을 받는 느낌"으로 반응 — 손목 방향에 따른 미세 회전 적용
- **Solitaire류**: tap-or-drag 두 경로 지원; velocity 임계값 초과 시 자동 foundation 이동(fling to win)
- **Flutter 공식 Cookbook**: `GestureDetector` + `AnimationController` + `Tween<Alignment>` + `SpringSimulation` 조합 예제 제공

---

### 2. 카드 집기/놓기 시각 피드백 — 다층 lift effect

#### 집기(pick up) 시 변화 레이어

| 레이어 | 기법 | Flutter 구현 |
|--------|------|-------------|
| **그림자** | elevation 증가 (예: 4 → 24) | `Card(elevation: _isDragging ? 24 : 4)` 또는 `BoxShadow` blur/offset 애니메이션 |
| **크기** | scale 1.0 → 1.05~1.10 | `Transform.scale` + `AnimatedContainer` |
| **기울기** | 드래그 방향에 비례한 rotation | `Transform.rotate(angle: velocity.x * 0.002)` |
| **반투명 원본** | childWhenDragging: 흐릿한 잔상 | `Draggable.childWhenDragging` → opacity 0.3~0.5 위젯 |
| **피드백 위젯** | 실제 손가락 따라다니는 카드 + shadow 추가 | `Draggable.feedback` → shadow/scale 강화 버전 |

#### 놓기(put down) 확인 애니메이션
- 유효 드롭: 작은 bounce 또는 색상 플래시 + `HapticFeedback.mediumImpact()`
- 무효 드롭(snap-back): SpringSimulation으로 원위치 복귀 + `HapticFeedback.lightImpact()`

#### 업계 사례
- **Marvel Snap**: 카드를 보드에 올리면 카드별 고유 그래픽 이펙트(Ant-Man 축소, Cap 방패 튕김) + 대응 햅틱 동시 발생
- **Drag&Drop UX 원칙 (Pencil & Paper, Smart Interface Design)**: "item을 잡으면 z-dimension으로 들어올려야 한다" — shadow + elevation + tilt 세트가 표준
- **Trello**: 드래그 시 카드 약 5° 회전 (tilt) — 물리 오브젝트 감각

---

### 3. 햅틱 피드백 — 시점별 레이어링

#### Flutter `HapticFeedback` API

| 메서드 | 강도 | iOS 내부 | Android 내부 | 카드 게임 적용 시점 |
|--------|------|----------|-------------|-------------------|
| `lightImpact()` | 약 | UIImpactFeedbackStyleLight | CLOCK_TICK | 카드 선택/hover |
| `mediumImpact()` | 중 | UIImpactFeedbackStyleMedium | KEYBOARD_TAP | 카드 집기(pick up), 유효 드롭 |
| `heavyImpact()` | 강 | UIImpactFeedbackStyleHeavy | - | 카드 충돌, 스택 착지 |
| `selectionClick()` | 틱 | UISelectionFeedbackGenerator | - | 카드 스택 탐색, 페이지 전환 |
| `vibrate()` | 롱 바이브레이션 | - | - | 특수 이벤트(에러, 매칭) |

#### 권장 시점별 매핑 (타로 앱 적용 기준)

```
카드 터치 시작 (onPanStart)       → lightImpact()     [선택 확인]
카드 들어올림 (lifted=true 전환)  → mediumImpact()    [집기 감각]
유효 영역 진입 (DragTarget hover) → selectionClick()  [snap point 감지]
카드 내려놓기 성공 (onAccept)     → mediumImpact()    [착지 확인]
snap-back (무효 드롭)             → lightImpact()     [되돌아감]
카드 뒤집기 완료 (flip done)      → heavyImpact()     [공개 충격]
```

#### 업계 사례
- **Marvel Snap**: "every time there's feedback, you can really feel the weight of each move" — 이벤트별 고유 햅틱 패턴 설계. 턴 종료 임박 시 경고 햅틱도 별도 존재.
- **Hearthstone**: Magnetic minion attach 시 시각+햅틱 동시 — 유효 target 진입 순간 선택 틱 피드백
- **학술/UX 연구**: "velocity threshold를 넘는 순간 sharp snap 햅틱" — pull-to-refresh 패턴에서 확립된 임계점 햅틱 패러다임

#### 플랫폼 주의사항
- iOS 10 미만: HapticFeedback 미지원 (무시됨)
- Samsung 일부 기기: Android HapticFeedback 구현 버그 존재 (`flutter/flutter#73987`)
- 크로스플랫폼 일관성 필요 시: `haptic_feedback` 패키지 (`pub.dev/packages/haptic_feedback`) 사용

---

### 4. 스택 분리감 — 카드 한 장 뽑기

#### 문제: 밀집 스택에서 한 장이 분리되는 느낌

구현 패턴:
1. **터치 포인트 히트테스트**: 스택 최상단 카드만 드래그 가능하게 GestureDetector 래핑
2. **분리 시 cascaded offset 애니메이션**: 아래 카드들이 미세하게 재배치 (50ms staggered)
3. **분리 순간 selectionClick()**: "딱" 떨어지는 분리감
4. **z-order 전환**: 드래그 중 카드를 Stack 최상위로 재배치 (`Overlay` 또는 `Stack` reorder)

#### Flutter 구현 힌트
- `Stack` + `Positioned`로 카드 z-순서 명시적 제어
- 드래그 시작 → `setState` 로 드래그 카드를 `Stack` 최후미(최상위)로 이동
- `childWhenDragging`에 희미한 잔상 표시 → 원래 자리 명확히

---

### 5. Flutter GestureDetector velocity 기반 fling — 구현 패턴 요약

```dart
GestureDetector(
  onPanStart: (d) {
    HapticFeedback.lightImpact();
    setState(() => _isDragging = true);
  },
  onPanUpdate: (d) {
    setState(() => _offset += d.delta);
  },
  onPanEnd: (d) {
    final velocity = d.velocity.pixelsPerSecond;
    final speed = velocity.distance;

    if (speed > kFlingThreshold) {          // 예: 800 px/s
      HapticFeedback.mediumImpact();
      _controller.fling(velocity: speed / 1000);
    } else {
      // snap-back with spring
      final simulation = SpringSimulation(
        SpringDescription(mass: 1, stiffness: 600, damping: 30),
        _offset.distance,  // start
        0,                 // end (center)
        -speed / 1000,     // initial velocity (negative = toward center)
      );
      _controller.animateWith(simulation);
      HapticFeedback.lightImpact();
    }
    setState(() => _isDragging = false);
  },
)
```

---

## Key Findings

### 조작감 기여 상위 3개 기법

#### 1위: velocity 기반 fling + SpringSimulation 스냅백
**기여도: 최상**
드래그 릴리즈 시 속도를 읽어 "던지기(fling)"와 "내려놓기(snap)"를 자동 판별하고, SpringSimulation에 릴리즈 속도를 초기값으로 주입하면 물리적으로 자연스러운 착지 곡선이 생성된다. 이것이 없으면 카드가 "텔레포트"처럼 느껴진다. 구현 핵심: `DragEndDetails.velocity` → `AnimationController.animateWith(SpringSimulation)`.

#### 2위: 카드 집기 시 다층 시각 피드백 (lift + shadow + scale + tilt)
**기여도: 높음**
elevation/shadow 증가 + 1.05 scale + 미세 rotation 세 가지가 동시에 적용될 때 "카드를 실제로 집었다"는 지각이 형성된다. 셋 중 하나만 있으면 효과가 크게 감소한다. `Draggable.feedback`에 shadow/scale 강화 버전, `childWhenDragging`에 반투명 잔상.

#### 3위: 시점별 햅틱 레이어링
**기여도: 높음**
단일 강도 햅틱보다 집기(medium) → 유효영역 진입(selection) → 착지(medium) → 뒤집기(heavy)처럼 강도를 달리하는 레이어링이 체험 품질을 수직 상승시킨다. Marvel Snap이 이 방식으로 업계 최고 수준 햅틱 평가를 받은 사례. iOS에서는 UIImpactFeedbackGenerator가 세밀하게 작동하며 Android는 보완 패키지 필요.

---

## Recommendations

타로 셔플 앱 (Flame + forge2d + Rive) 적용 우선순위:

1. **즉시 적용 (MVP+)**: `HapticFeedback.mediumImpact()` — 카드 터치 시작, 뒤집기 완료 두 시점만 추가해도 체감 차이가 크다.

2. **카드 선택 시각 피드백**: forge2d body에 선택 상태를 추가해, 터치 시 scale 1.05 + BoxShadow blur 증가를 CustomPainter에서 반영. tilt는 드래그 velocity.x 비례 rotation.

3. **velocity 기반 fling**: forge2d body에 `applyLinearImpulse(velocity * flingFactor)`로 릴리즈 속도를 물리 엔진에 직접 전달 → 카드가 물리 법칙에 따라 날아가는 효과.

4. **스냅 포인트**: 타로 선택 단계에서 카드 한 장을 선택 위치로 이동할 때 SpringSimulation 착지 사용 — "자석 끌림" 감각.

5. **장기**: `haptic_feedback` 패키지로 Android 크로스플랫폼 일관성 확보.

---

## References

- [Flutter 공식: Physics Simulation Animation](https://docs.flutter.dev/cookbook/animation/physics-simulation)
- [Flutter SpringSimulation API](https://api.flutter.dev/flutter/physics/SpringSimulation-class.html)
- [Flutter SpringDescription API](https://api.flutter.dev/flutter/physics/SpringDescription-class.html)
- [Flutter GestureDetector — 공식 문서](https://docs.flutter.dev/ui/interactivity/gestures)
- [Flutter DragGestureRecognizer API](https://api.flutter.dev/flutter/gestures/DragGestureRecognizer-class.html)
- [Flutter HapticFeedback.mediumImpact API](https://api.flutter.dev/flutter/services/HapticFeedback/mediumImpact.html)
- [Flutter Draggable class API](https://api.flutter.dev/flutter/widgets/Draggable-class.html)
- [Flutter LongPressDraggable API](https://api.flutter.dev/flutter/widgets/LongPressDraggable-class.html)
- [flutter_physics package](https://pub.dev/packages/flutter_physics)
- [haptic_feedback package](https://pub.dev/packages/haptic_feedback)
- [Marvel Snap 햅틱 분석 — XDA Developers](https://www.xda-developers.com/marvel-snap-mobile-game-haptics/)
- [Marvel Snap — Apple Developer Behind the Design](https://developer.apple.com/news/?id=sosm2p7q)
- [Hearthstone Card CSS 3D Click/Drag — CodePen](https://codepen.io/jackrugile/pen/zqJdXM)
- [Card Game Engine with UIKit: Animations — kazaimazai.com](https://kazaimazai.com/card-game-animations/)
- [UIImpactFeedbackGenerator — Apple Developer](https://developer.apple.com/documentation/uikit/uiimpactfeedbackgenerator)
- [Drag & Drop UX Best Practices — Pencil & Paper](https://www.pencilandpaper.io/articles/ux-pattern-drag-and-drop)
- [Smart Interface Design Patterns: Drag and Drop UX](https://smart-interface-design-patterns.com/articles/drag-and-drop-ux/)
- [Mobile Gaming UX: Haptic Feedback — Interhaptics Medium](https://interhaptics.medium.com/mobile-gaming-ux-how-haptic-feedback-can-change-the-game-3ef689f889bc)
- [Mastering Haptic Feedback in Flutter — Easy Flutter Medium](https://medium.com/easy-flutter/mastering-haptic-feedback-in-flutter-elevate-your-apps-user-experience-9880b3517ad4)
- [DHiWise: Creating Haptic Feedback in Flutter](https://www.dhiwise.com/post/creating-haptic-feedback-in-flutter-application)
- [Flutter Gestures — DHiWise](https://www.dhiwise.com/post/an-in-depth-dive-into-flutter-gestures-amplifying-your-ui-ux)
- [Flame Engine Drag Events](https://docs.flame-engine.org/latest/flame/inputs/drag_events.html)
- [Handling gestures in Flutter — LogRocket](https://blog.logrocket.com/handling-gestures-flutter-gesturedetector/)
- [Flutter Explicit Animations: Springs — Medium](https://medium.com/@punithsuppar7795/flutter-explicit-animations-curves-vs-physics-vs-springs-6dcf3a55aea4)

## Communication Log
| # | 방향 | 상대 | 내용 요약 | 시점(단계) |
|---|------|------|----------|-----------|
| 1 | 수신 | orchestrator | 카드 손맛 기법 조사 요청, 8개 키워드, 산출물 경로 지정 | 시작 |
| 2 | 완료 | orchestrator | 드래그/햅틱/시각/fling/상위3기법 조사 완료, 039 파일 업데이트 | 완료 |

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
