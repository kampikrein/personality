---
id: "030"
title: "video_player → Flame 전환 병목 & 동기화 오류 분석"
category: agent
status: archived
created: 2026-03-16
summary: >
  video_player 영상 종료 → Flame 물리 전환 시 알려진 오류 패턴과 해결법.
  블랙 플래시, 콜백 타이밍, 마지막 프레임 고정, 좌표 동기화 전략 포함.
keywords: [agent-report, transition, sync, video_player, Flame, black-flash, coordinate]
modules: []
---
# video_player → Flame 전환 병목 & 동기화 오류 분석

## Progress
### Completed
- [x] 블랙 플래시/프레임 점프 알려진 이슈
- [x] 마지막 프레임 고정 기법
- [x] AnimatedCrossFade vs AnimatedOpacity 비교
- [x] onComplete 콜백 신뢰성
- [x] 카드 좌표 동기화 패턴
- [x] 해결 가능 수준 판단
### Remaining
- (없음)
### Current Status
조사 완료. 해결 가능 수준 판단 포함.

---

## Summary

video_player → Flame 전환의 핵심 문제는 세 가지다.

1. **블랙 플래시**: iOS에서 영상 종료 직후 검은 프레임이 렌더링되는 알려진 버그
2. **콜백 타이밍 불신뢰**: `isCompleted` 감지 시점과 실제 마지막 프레임 표시 사이에 플랫폼별 편차 존재
3. **좌표 동기화**: 영상 마지막 프레임의 카드 위치 ↔ Flame 초기 좌표를 런타임에 일치시킬 공식 API 없음

**핵심 결론: 전환 오류는 해결 가능한 수준이다.** 다만 완전 자동화는 불가능하며, Blender 제작 시 Flame 좌표 기준으로 사전 정렬하는 설계 의존형 해결책이 필요하다.

---

## Details

### 1. 블랙 플래시 & 프레임 점프 알려진 이슈

#### 문제 현황
- **GitHub Issue #41156** (flutter/flutter): iOS에서 영상 루프 시 검은 첫 프레임이 번쩍이는 문제. P2 우선순위로 등록, 40+ 인터랙션. **현재도 미해결(Open)**.
- **GitHub Issue #140340**: 영상은 소리만 나고 화면이 검은 문제 — iOS 렌더링 파이프라인의 구조적 특성.
- **발생 조건**: `setLooping(true)` 환경에서 가장 현저, 단일 재생 종료 후도 발생 가능.
- **Android**: ExoPlayer 기반으로 동일 문제 없음(또는 미미).

#### 원인 분류
| 원인 | 플랫폼 | 빈도 |
|------|--------|------|
| AVPlayer 첫/마지막 프레임 렌더 지연 | iOS | 높음 |
| 위젯 트리 전환 시 배경 노출 | 양 플랫폼 | 중간 |
| Controller dispose 타이밍 | 양 플랫폼 | 낮음 |

#### 프레임 점프
- 영상 마지막 프레임 카드 위치 → Flame 초기 카드 위치가 픽셀 단위로 다를 경우 시각적 점프 발생.
- 이는 video_player 버그가 아니라 **좌표 동기화 설계 문제**이다.

---

### 2. 마지막 프레임 고정 기법

#### 공식 구현 (flutter/plugins PR #3727)
video_player 플러그인은 영상 완료 시 내부적으로 다음을 실행한다:

```dart
pause().then((void pauseResult) => seekTo(value.duration));
```

이 동작은 플랫폼 레이어에 pause + seekTo를 명시적으로 전달하여 **마지막 프레임을 화면에 유지**한다. 단, iOS에서는 seekTo의 비동기 처리로 인해 콜백이 완료되지 않는 경우가 있었다 (Issue #124475, `video_player_avfoundation > 2.4.2`, **수정 완료**).

#### 애플리케이션 레벨 구현 패턴
```dart
_controller.addListener(() {
  if (_controller.value.isCompleted && !_hasTriggeredTransition) {
    _hasTriggeredTransition = true;
    // 1. 마지막 프레임 확실히 고정
    _controller.pause();
    // 2. 충분한 프레임 렌더링 대기 (iOS 안전 여유)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _beginTransition();
      });
    });
  }
});
```

**주의**: iOS에서 `value.isCompleted`가 true로 전환되는 시점에 아직 마지막 프레임이 화면에 보이지 않을 수 있다. 100ms 정도의 지연을 두는 것이 안전하다.

#### 마지막 프레임 캡처 (Image.memory 방식)
표준 video_player 패키지는 특정 프레임을 Image로 캡처하는 API를 제공하지 않는다. 대안:
- **video_thumbnail** 패키지: 특정 포지션의 썸네일 추출 가능 — 영상 종료 직전 마지막 프레임 썸네일을 미리 추출, 전환 중에 표시.
- **RepaintBoundary + RenderRepaintBoundary.toImage()**: VideoPlayer 위젯을 RepaintBoundary로 감싸고, 완료 시점에 현재 화면을 캡처. 성능 오버헤드 있음.

---

### 3. 전환 위젯 비교

#### AnimatedCrossFade
- 두 위젯(영상 위젯 + Flame 위젯)을 동시에 렌더링하며 opacity를 교차 변화.
- **장점**: 완전한 크로스페이드, 블랙 플래시가 이론적으로 없음.
- **단점**: 전환 중 두 위젯이 동시 렌더링 → Flame GameWidget이 함께 초기화되므로 불필요한 물리 계산 시작. `secondChild`(Flame)가 opacity 0 상태에서도 렌더링됨.

#### AnimatedOpacity + Stack
```dart
Stack(
  children: [
    GameWidget(game: _flameGame),          // 항상 렌더링
    AnimatedOpacity(
      opacity: _showVideo ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: VideoPlayer(_controller),
    ),
  ],
)
```
- **장점**: Flame을 미리 초기화하고 숨겨둘 수 있어 전환 시 준비 완료 상태.
- **단점**: Video 완전 재생 전부터 Flame이 메모리/GPU 점유.
- **블랙 플래시 위험**: opacity가 0으로 떨어질 때 배경이 검게 보일 수 있음. `backgroundColor` 설정으로 완화.

#### PageRouteBuilder (화면 전환)
- Navigator.push로 완전히 다른 화면으로 이동.
- **블랙 플래시**: iOS에서 `FadeForwardsPageTransitionsBuilder` 사용 시 검은 화면 버그 보고됨 (Issue #164535).
- **타로 UI**: 영상과 Flame이 같은 화면에 있어야 하므로 부적합.

#### 커스텀 FadeTransition + LayoutBuilder
- AnimatedOpacity Stack과 유사하지만 AnimationController를 직접 제어.
- `Curves.easeInOut`으로 부드러운 페이드.
- 가장 세밀한 제어 가능.

#### 비교 표

| 전환 방식 | 블랙 플래시 위험 | 메모리 이중 사용 | 구현 복잡도 | 추천 |
|---------|:------------:|:------------:|:--------:|:----:|
| AnimatedCrossFade | 낮음 | 높음(전환 중 이중) | 낮음 | 보통 |
| AnimatedOpacity + Stack | 중간(iOS) | 중간(Flame 항시 대기) | 낮음 | **권장** |
| PageRouteBuilder | 높음(iOS) | 낮음 | 중간 | 비권장 |
| 커스텀 FadeTransition | 낮음 | 중간 | 높음 | 대안 |

**권장**: `AnimatedOpacity + Stack` — Flame을 opacity 0 상태로 미리 준비시켜 두고, 영상 완료 신호를 받은 후 비디오 opacity를 0으로, Flame을 1로 교차. 이때 영상 위젯은 `isCompleted` 후 즉시 `dispose()`하지 말고, 페이드가 완료된 후 `dispose()`.

---

### 4. onComplete 콜백 신뢰성

#### 감지 방법
공식적으로 `onComplete` 콜백은 없다 — `addListener`를 사용한다.

```dart
_controller.addListener(() {
  if (_controller.value.isCompleted) {
    // 완료
  }
});
```

`VideoPlayerValue.isCompleted`는 내부적으로 `position >= duration`으로 판단한다.

#### iOS vs Android 차이

| 항목 | iOS (AVPlayer) | Android (ExoPlayer) |
|------|---------------|---------------------|
| position 업데이트 간격 | ~100ms | ~100ms |
| position 최종값 | duration보다 몇 ms 작을 수 있음 | 대체로 일치 |
| isCompleted 전환 타이밍 | 마지막 프레임 표시 이전일 수 있음 | 비교적 정확 |
| 알려진 버그 | #124475: position이 완료 시 업데이트 안 됨 (수정완료) | 없음 |

**핵심 위험**: iOS에서 `isCompleted`가 true가 되는 시점과 마지막 프레임이 화면에 표시되는 시점 사이에 1-2 프레임 차이 존재. 즉시 전환하면 마지막 프레임이 표시되기 전에 블랙이 노출될 수 있다.

#### 신뢰성 높이기 위한 대안 패턴
```dart
// 패턴 A: duration 기반 임박 감지 (100ms 전에 미리 준비)
_controller.addListener(() {
  final remaining = _controller.value.duration - _controller.value.position;
  if (remaining.inMilliseconds < 100 && !_preparedTransition) {
    _preparedTransition = true;
    _prepareFlameGame(); // Flame 미리 워밍업
  }
  if (_controller.value.isCompleted && !_startedTransition) {
    _startedTransition = true;
    // 100ms 추가 여유 (iOS 안전)
    Future.delayed(const Duration(milliseconds: 100), _beginFade);
  }
});
```

```dart
// 패턴 B: Timer 백업 (콜백 누락 대비)
final totalDuration = _controller.value.duration;
Timer(totalDuration - const Duration(milliseconds: 200), () {
  if (!_startedTransition) {
    _startedTransition = true;
    _beginFade();
  }
});
```

---

### 5. 카드 좌표 동기화 패턴

#### 문제 정의
영상 마지막 프레임에서 카드들의 픽셀 위치 = Flame 초기 카드 Vector2 좌표
이를 런타임에 자동으로 맞추는 공식 API는 존재하지 않는다.

#### 접근법 비교

**접근법 A: 사전 설계 의존형 (권장)**
1. Flame의 카드 초기 배치 좌표를 먼저 확정 (예: 화면 중앙 부채꼴 배치)
2. Blender 렌더 시 동일 좌표를 기준으로 카드를 배치하여 영상 제작
3. 영상 마지막 프레임 = Flame 초기 상태가 픽셀 단위로 일치

```
Flame 설계 먼저 → Blender에서 동일 위치 렌더 → 완벽 동기화
```

- **장점**: 런타임 동기화 로직 불필요, 가장 단순
- **단점**: Blender 렌더 수정이 어렵고, Flame 레이아웃 변경 시 영상 재제작 필요

**접근법 B: JSON 좌표 번들**
1. Flame 카드 초기 배치를 JSON으로 명세 (`card_positions.json`)
2. Blender Python 스크립트로 동일 좌표 사용하여 영상 렌더
3. 앱 번들에 JSON 포함, Flame 초기화 시 로드

```json
{
  "cards": [
    {"id": 0, "x": 0.5, "y": 0.7, "angle": -15.0},
    {"id": 1, "x": 0.5, "y": 0.7, "angle": 0.0},
    ...
  ]
}
```

- **장점**: 설계와 구현의 명시적 계약, 좌표 추적 가능
- **단점**: Blender-Flutter 좌표계 변환 필요 (Y축 반전 등)

**접근법 C: 화면 비율 고정 + 하드코딩**
- 영상 해상도와 Flutter의 논리 픽셀을 고정 비율로 맵핑
- Flame 카드 초기 위치를 하드코딩, Blender도 동일 위치로 고정
- MediaQuery로 화면 크기 변화에 대응하는 스케일 계수 적용

```dart
final screenWidth = MediaQuery.of(context).size.width;
final scaleFactor = screenWidth / kDesignWidth; // 예: 390.0
final cardX = kCardInitialX * scaleFactor;
```

#### 좌표계 변환 주의사항
- Blender: Y축 위가 양수 / Flutter/Flame: Y축 아래가 양수
- 영상 해상도(예: 1080x1920) → Flutter 논리 픽셀(예: 390x844): 스케일 변환 필수
- 카드 회전각: Blender의 라디안 → Flame의 라디안 (동일, 방향 주의)

---

## Key Findings

1. **블랙 플래시는 iOS 고질 문제**: flutter/flutter Issue #41156이 미해결로 남아 있으며, iOS AVPlayer의 렌더링 특성상 영상 경계에서 검은 프레임이 출현한다. `AnimatedOpacity + Stack` 전략으로 비디오 위에 페이드 레이어를 얹는 방식으로 완화 가능.

2. **`isCompleted` 콜백은 기능하지만 타이밍 여유 필요**: iOS에서 1-2 프레임(약 33-67ms) 여유를 두어야 마지막 프레임이 실제로 화면에 표시된 후 전환이 시작된다. `Future.delayed(100ms)` 패턴 사용.

3. **마지막 프레임 고정 표준 구현 존재**: `pause().then((_) => seekTo(duration))` — 플러그인 내부에서 이미 수행. 앱 레벨에서 별도로 구현하지 않아도 되지만, iOS에서는 `dispose()`를 페이드 완료 전까지 지연해야 한다.

4. **좌표 동기화는 런타임 API 없음**: 자동 동기화 불가. **사전 설계 의존형(접근법 A)**이 가장 신뢰할 수 있는 방법이다. Flame 레이아웃을 먼저 확정하고 Blender 렌더를 맞추는 순서가 필수.

5. **Flame overlayBuilderMap이 최적 아키텍처**: VideoPlayer를 Flame GameWidget의 overlay로 넣어 관리하면, `game.overlays.remove('video')` 한 번으로 전환이 완료되며 Flame 게임 루프는 그 전부터 실행 중 상태로 준비된다.

---

## Recommendations

### 권장 전환 아키텍처

```
GameWidget(
  game: _tarotGame,
  overlayBuilderMap: {
    'shuffleVideo': (context, game) => _buildVideoOverlay(),
  },
  initialActiveOverlays: ['shuffleVideo'],
)
```

```dart
Widget _buildVideoOverlay() {
  return AnimatedOpacity(
    opacity: _videoOpacity,  // 1.0 → 0.0으로 페이드
    duration: const Duration(milliseconds: 300),
    onEnd: () {
      if (_videoOpacity == 0.0) {
        game.overlays.remove('shuffleVideo');
        _controller.dispose();
      }
    },
    child: VideoPlayer(_controller),
  );
}
```

**흐름**:
1. 앱 시작 → Flame GameWidget 렌더링 (물리 엔진 대기 상태)
2. `overlays.add('shuffleVideo')` → 영상 오버레이 표시
3. 영상 재생 → `isCompleted` 감지 + 100ms 여유
4. `_videoOpacity = 0.0` → AnimatedOpacity 페이드 아웃 (300ms)
5. `onEnd` → `overlays.remove('shuffleVideo')` + `dispose()`
6. Flame 물리 활성화 (카드 초기 위치 = 사전 설계된 좌표)

### 좌표 동기화 구현 순서
1. Flame 카드 초기 배치 픽셀 좌표 확정 (논리 픽셀 기준)
2. `docs/` 또는 `assets/` 에 `card_initial_positions.json` 작성
3. Blender 담당자에게 좌표 전달 → 영상 마지막 2초 카드 위치 고정
4. Flame 초기화 시 JSON 로드, 동일 좌표로 카드 생성

### iOS 블랙 플래시 완화 체크리스트
- [ ] GameWidget의 `backgroundBuilder`로 검은 배경 대신 원하는 배경색 설정
- [ ] VideoPlayer 위젯을 Stack 최상위(overlay)에 배치
- [ ] `dispose()` 시점을 AnimatedOpacity onEnd 이후로 지연
- [ ] `Future.delayed(100ms)` 전환 시작 지연 추가
- [ ] iOS에서 실기기 테스트 필수 (시뮬레이터와 동작 다름)

---

## References

| 항목 | URL |
|------|-----|
| iOS 블랙 프레임 Issue #41156 (미해결) | https://github.com/flutter/flutter/issues/41156 |
| iOS position 미업데이트 Issue #124475 (수정완료) | https://github.com/flutter/flutter/issues/124475 |
| Pause on complete PR #3727 | https://github.com/flutter/plugins/pull/3727 |
| seekTo iOS 미작동 Issue #78998 (수정완료) | https://github.com/flutter/flutter/issues/78998 |
| onComplete 이벤트 요청 Issue #21929 (완료) | https://github.com/flutter/flutter/issues/21929 |
| iOS FadeRoute 블랙 Issue #164535 | https://github.com/flutter/flutter/issues/164535 |
| Flame Overlays 공식 문서 | https://docs.flame-engine.org/latest/flame/overlays.html |
| Flame GameWidget 공식 문서 | https://docs.flame-engine.org/latest/flame/game_widget.html |
| video_player pub.dev | https://pub.dev/packages/video_player |

---

## Communication Log
| # | 방향 | 상대 | 내용 요약 | 시점 |
|---|------|------|----------|------|
| 1 | 수신 | orchestrator | 전환 병목 & 동기화 오류 분석 요청 (관점 2) | 2026-03-16 |
| 2 | 발신 | orchestrator | 분석 완료, 해결 가능 판단, 권장 아키텍처 제시 | 2026-03-16 |

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
