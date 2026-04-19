---
id: "040"
title: "sensors_plus 가속도계 응답성 조사"
category: agent
status: archived
created: 2026-03-16
summary: >
  sensors_plus의 가속도계 스트림을 SensorInterval.gameInterval(20ms/50Hz)로 설정하고,
  Flame update() 루프에서 저장된 최신 값을 로우패스 필터(α≈0.15~0.25)로 스무딩 후
  world.gravity에 직접 대입하면 즉각적이고 자연스러운 기울기 반응이 가능하다.
  iOS는 기본 100Hz, Android는 gameInterval 기준 ~50Hz로 플랫폼 차이가 존재하나
  게임 용도로 충분하며, 최대 지연은 렌더링 파이프라인 포함 16~33ms 수준이다.
keywords: [agent-report, sensors_plus, accelerometer, forge2d, gravity, low-pass-filter, tilt]
modules: []
---

# sensors_plus 가속도계 응답성 조사

## Progress
### Completed
- [x] sensors_plus 샘플링 레이트 iOS/Android 조사
- [x] Flame update(dt)와 비동기 Stream 처리 방식
- [x] 로우패스 필터 구현법 조사
- [x] forge2d World.gravity 변경 API 조사
- [x] iOS vs Android 응답성 차이
- [x] 즉각적 반응 달성 조건 도출
### Remaining
- (없음)
### Current Status
조사 완료.

## Summary

sensors_plus + forge2d 조합으로 기울이기 중력 연동은 **현실적으로 즉각적 반응이 가능**하다.
핵심 구성: `SensorInterval.gameInterval`(20ms) 스트림 → 전역 변수 캐싱 → Flame `update()` 루프에서 로우패스 필터 적용 → `world.gravity = Vector2(smoothedX, smoothedY)` 직접 대입.
전체 체감 지연은 센서(10~20ms) + 렌더링(16ms) = **25~40ms** 수준으로 조작감 즉각성 임계치(50~80ms) 안에 들어온다.

---

## Details

### 1. sensors_plus 샘플링 레이트

#### SensorInterval 상수 (sensors_plus 내부 매핑)

| 상수 | Android 매핑 | 주기 | 실효 Hz |
|------|-------------|------|---------|
| `SensorInterval.fastest` | `SENSOR_DELAY_FASTEST` | ~0–2ms | 최대(하드웨어 한계) |
| `SensorInterval.gameInterval` | `SENSOR_DELAY_GAME` | **20,000 µs (20ms)** | **~50Hz** |
| `SensorInterval.uiInterval` | `SENSOR_DELAY_UI` | 66,667 µs (66ms) | ~15Hz |
| `SensorInterval.normalInterval` | `SENSOR_DELAY_NORMAL` | 200,000 µs (200ms) | ~5Hz |
| `Duration(microseconds: N)` | 커스텀 | 지정값 | 가변 |

#### 플랫폼별 기본 동작

- **iOS**: `CMMotionManager` 기반, 기본값 **100Hz(10ms 주기)**. `accelerometerUpdateInterval` 설정 가능. `CMBatchedSensorManager`를 쓰면 최대 800Hz까지 가능(고성능 용도).
- **Android**: `SENSOR_DELAY_GAME`이 사실상 게임 표준. 다만 Android는 "지정 속도를 보장하지 않음(not guaranteed)" — 디바이스/벤더/OS 버전에 따라 실제 도착 간격이 불규칙할 수 있음.
- **주의**: `samplingPeriod`는 hint 개념. Android에서 실제 이벤트 도달 간격이 요청값보다 길어질 수 있음.

#### API 호출 형태

```dart
accelerometerEventStream(
  samplingPeriod: SensorInterval.gameInterval, // 20ms ~50Hz
).listen((AccelerometerEvent event) {
  _rawX = event.x;
  _rawY = event.y;
});
```

---

### 2. Flame update(dt)와 비동기 Stream 처리

#### 핵심 구조: 스트림은 캐싱, update()에서 소비

센서 스트림과 Flame 게임 루프(60fps = 16ms/frame)는 서로 다른 주기로 동작한다. 두 루프를 직접 연결하면 안 되고, **공유 변수(캐시)** 를 통해 비동기 경계를 격리해야 한다.

```dart
class TarotGame extends Forge2DGame {
  // 캐시 변수 — 스트림 콜백이 언제든 덮어씌움
  double _rawX = 0.0;
  double _rawY = 0.0;
  double _smoothX = 0.0;
  double _smoothY = 0.0;

  StreamSubscription<AccelerometerEvent>? _accelSub;

  static const double _alpha = 0.2; // 로우패스 계수

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _accelSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((event) {
      _rawX = event.x;
      _rawY = event.y;
    });
  }

  @override
  void update(double dt) {
    // 로우패스 필터: 매 프레임 smooth값 갱신
    _smoothX = _smoothX + _alpha * (_rawX - _smoothX);
    _smoothY = _smoothY + _alpha * (_rawY - _smoothY);

    // forge2d에서 양의 y가 아래 방향 (Flame 좌표계)
    world.gravity = Vector2(_smoothX * 2.0, _smoothY * 2.0);

    super.update(dt);
  }

  @override
  void onRemove() {
    _accelSub?.cancel();
    super.onRemove();
  }
}
```

**패턴 설명:**
- 스트림 리스너: 최신 raw 값만 저장, UI/물리 연산 없음 (이 콜백은 Dart 이벤트 루프에서 실행)
- `update(dt)`: 60fps 게임 루프에서 실행 — 필터 적용 + gravity 갱신

---

### 3. 로우패스 필터 (Low-Pass Filter)

#### 공식

```
smoothed[i] = smoothed[i-1] + α × (raw[i] − smoothed[i-1])
```

α (alpha)는 0~1 사이 값.

| α 값 | 특성 | 적합 상황 |
|------|------|----------|
| 0.05~0.10 | 매우 부드러움, 반응 느림 | 배경 시차 효과 |
| **0.15~0.25** | **자연스럽고 즉각적** | **타로 카드 기울기 (권장)** |
| 0.4~0.6 | 빠른 반응, 약간의 떨림 | 액션 게임 |
| 1.0 | 필터 없음 (raw) | 테스트용 |

#### α와 시간상수 관계

```
α = dt / (timeConstant + dt)
```
timeConstant = 0.1(부드러움) ~ 0.02(빠름) 초 수준.

#### 실용 권장값

타로 카드 씬에서 "카드가 중력 방향으로 자연스럽게 쏠리는" 느낌에는 **α = 0.18~0.22** 권장.
- 너무 작으면(< 0.1): 폰을 확 기울여도 카드 반응이 늦어 어색함
- 너무 크면(> 0.4): 손 떨림이 그대로 전달되어 카드가 미세하게 떨림

---

### 4. forge2d World.gravity 실시간 변경 API

#### API

```dart
// Forge2DGame 내부: world는 Forge2DWorld 인스턴스
world.gravity = Vector2(gx, gy);
```

- **비용**: `Vector2` 필드 setter 대입 — O(1) 연산, 사실상 무비용
- **즉각 반영**: `world.stepDt()` (= `update()` 호출 시점) 다음 스텝부터 모든 DynamicBody에 적용됨
- **좌표계 주의**: `flame_forge2d`는 Flame 좌표계와 통일을 위해 gravity의 y 방향이 뒤집혀 있음
  - `Vector2(0, 10)` → 화면 아래 방향으로 중력 (정상 중력)
  - `Vector2(5, 10)` → 오른쪽 아래 방향으로 중력 (오른쪽으로 기울인 효과)

#### 가속도계 축 → gravity 매핑

기기를 세로로 들었을 때 sensors_plus 좌표계:
- `event.x` → 좌우 기울기 (오른쪽으로 기울면 양수)
- `event.y` → 앞뒤 기울기 (앞으로 기울면 양수)
- `event.z` → 기기 평면 수직 방향 (바닥 방향이 약 9.8)

타로 씬(가로 스크롤 없음)에서 권장 매핑:
```dart
world.gravity = Vector2(smoothedX * scale, smoothedZ_or_Y * scale);
```
scale 값은 2.0~5.0 실험으로 결정.

---

### 5. iOS vs Android 응답성 차이

| 항목 | iOS | Android |
|------|-----|---------|
| 기본 센서 주기 | 100Hz (10ms) | NORMAL: 200ms (~5Hz) |
| 게임 권장 주기 | 100Hz (기본) | GAME: 20ms (~50Hz) |
| 최대 주기 | 100Hz (CMMotionManager) | 하드웨어 의존 (일부 200Hz+) |
| 주기 보장 여부 | 대체로 안정적 | **보장되지 않음** (벤더 차이 큼) |
| 필터링 필요성 | 낮음 (비교적 안정) | 높음 (노이즈, 불규칙 간격) |
| `samplingPeriod` 효과 | 동작 (CMMotionManager interval 설정) | Hint only — 실제는 디바이스 의존 |

**Android 실무 대응책:**
- `gameInterval` + 로우패스 필터로 불규칙한 이벤트 간격 완화
- `dt` 기반 로우패스 (고정 α 대신 `α = dt / (tc + dt)`) 사용 시 더 일관성 있음

---

### 6. 즉각적 반응 vs 부드러운 반응 트레이드오프

| | 즉각성 우선 | 부드러움 우선 |
|--|------------|-------------|
| α 값 | 0.4~0.6 | 0.08~0.15 |
| samplingPeriod | gameInterval (20ms) | normalInterval (200ms) |
| 체감 | 손 떨림 전달, 빠른 반응 | 느리지만 안정적 |
| 타로 카드 적합성 | △ (손 떨림 거슬림) | △ (반응 지연 어색) |
| **권장 (타로)** | **α 0.18~0.22 + gameInterval** | — |

**타로 씬의 목표 UX**: "폰을 기울이면 카드들이 중력 방향으로 자연스럽게 쏠린다" → 즉각성과 부드러움 둘 다 필요. α = 0.20이 균형점.

---

## Key Findings

1. **sensors_plus 샘플링 레이트**
   - iOS: 기본 100Hz (10ms), 안정적, 별도 설정 불필요
   - Android: `SensorInterval.gameInterval` 명시 필수 (기본 normalInterval은 ~5Hz로 게임 불가)
   - Android는 보장 없음 → 로우패스 필터로 보완 필수

2. **비동기 처리 패턴**
   - 스트림 리스너 → 전역 변수 캐싱만 수행
   - Flame `update(dt)` 루프 → 캐시 읽기 + 필터 + gravity 대입
   - 두 루프를 직접 연결하지 않는 것이 핵심

3. **로우패스 필터**
   - 공식: `smooth = smooth + α × (raw - smooth)`
   - 타로 카드 권장 α: **0.18~0.22**
   - Dart에서 update() 내 2줄로 구현 가능, 별도 패키지 불필요

4. **forge2d gravity 변경 비용**
   - `world.gravity = Vector2(x, y)` — O(1), 프레임당 1회 호출 무해
   - 다음 `update()` 스텝에 즉각 반영됨

5. **전체 지연 추정**
   - 센서 이벤트 도달: 10~20ms (iOS: ~10ms, Android: 20ms)
   - Flame 프레임 처리: 16ms (60fps)
   - 총 체감 지연: **25~40ms** → 인간 인지 임계값 (~50ms) 이하로 즉각적으로 느껴짐

6. **iOS vs Android**: iOS가 더 안정적이고 빠르지만, Android도 gameInterval + 로우패스로 충분히 즉각적 반응 달성 가능

---

## Recommendations

### 즉각적 반응 달성 최소 구성

```dart
// onLoad에서 스트림 구독 (gameInterval)
_accelSub = accelerometerEventStream(
  samplingPeriod: SensorInterval.gameInterval,
).listen((e) { _rawX = e.x; _rawY = e.y; });

// update(dt)에서 매 프레임
const _alpha = 0.20;
_smoothX += _alpha * (_rawX - _smoothX);
_smoothY += _alpha * (_rawY - _smoothY);
world.gravity = Vector2(_smoothX * 3.0, _smoothY * 3.0);
```

### 추가 권장 사항

1. **scale 값(3.0) 튜닝**: 타로 카드 질량/밀도에 따라 2.0~6.0 범위에서 실험
2. **deadzone 추가**: 기울기 미만 5° 이하는 gravity를 `(0, 9.8)` 기본값으로 유지 → 평평할 때 카드가 자연스럽게 정렬
3. **gyroscope 보완** (선택): 가속도계 단독 사용 시 진동 노이즈 있음. `userAccelerometerEventStream` (중력 제거된 가속도계) 사용 또는 자이로스코프와 센서 퓨전 고려
4. **Android 테스트 우선**: iOS는 기본 설정으로 동작, Android 중저가 기기에서 지연/노이즈 검증 필요

---

## References

- [sensors_plus pub.dev](https://pub.dev/packages/sensors_plus)
- [accelerometerEventStream API 문서](https://pub.dev/documentation/sensors_plus/latest/sensors_plus/accelerometerEventStream.html)
- [sensors_plus GitHub — samplingPeriod 관련 Issue #1345](https://github.com/fluttercommunity/plus_plugins/issues/1345)
- [Forge2D — Flame 공식 문서](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/forge2d.html)
- [flame_forge2d Forge2DWorld 클래스 문서](https://pub.dev/documentation/flame_forge2d/latest/forge2d_world/Forge2DWorld-class.html)
- [flame_forge2d gravity flip 커밋](https://github.com/flame-engine/flame/commit/bdb360f18128f9305baa0e6ca77ee6fcad496bc7)
- [Low-Pass Filter 이론 — Thom Nichols](http://blog.thomnichols.org/2011/08/smoothing-sensor-data-with-a-low-pass-filter)
- [Low-Pass Filter 실습 — Yellow Rabbit](https://yrabbit.github.io/blog/2017/low-pass-filter-android-practice/)
- [iOS CMMotionManager 100Hz 기본값 — Advanced Swift](https://www.advancedswift.com/get-motion-data-in-swift/)
- [Android SENSOR_DELAY_GAME 20,000µs — Android Sensors Overview](http://josejuansanchez.org/android-sensors-overview/sensor_rates/README.html)
- [Flutter 기울기 Euler 각도 — Medium](https://medium.com/@MostafaA.Shaban/flutter-access-the-real-time-tilt-euler-angles-roll-and-pitch-x-y-coordinates-of-the-device-b5709207e664)
- [Gyroscopic parallax Flutter — Medium](https://medium.com/@RuslanTsitser/gyroscopic-parallax-effect-in-flutter-43ceb53b1449)

## Communication Log
| # | 방향 | 상대 | 내용 요약 | 시점(단계) |
|---|------|------|----------|-----------|
| 1 | 수신 | orchestrator | sensors_plus+forge2d 가속도계 응답성 조사 위임 | 시작 |
| 2 | 반환 | orchestrator | 조사 완료, 즉각 반응 달성 조건 도출 | 완료 |

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
