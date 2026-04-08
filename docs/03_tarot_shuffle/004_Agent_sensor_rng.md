---
id: "004"
title: "센서 통합 & 난수 생성 기술 조사"
category: agent
status: archived
created: 2026-03-15
summary: >
  Flutter 센서 API, CSPRNG, 하이브리드 엔트로피 모델, 햅틱 피드백 기술 조사.
  sensors_plus 패키지로 가속도계/자이로스코프 수집, PointyCastle FortunaRandom으로
  시드 가능한 CSPRNG 구현, SHA-256 기반 엔트로피 풀로 센서 데이터 혼합,
  HapticFeedback 내장 클래스 + haptic_feedback 패키지로 햅틱 틱 구현 권장.
keywords: [agent-report, sensors, csprng, entropy, haptic, flutter]
modules: [mobile]
---

# 센서 통합 & 난수 생성 기술 조사

## Progress
### Completed
- [x] 센서 API 패키지 조사 (sensors_plus, motion_sensors)
- [x] CSPRNG 구현 방법 조사 (dart:math, pointycastle)
- [x] 하이브리드 엔트로피 모델 설계 조사
- [x] 햅틱 피드백 구현 조사
### Remaining
- (없음)
### Current Status
조사 완료. archived.

## Summary

Flutter 기반 타로 셔플 앱에서 "사용자 물리적 상호작용이 셔플에 반영되는 제의적 경험"을 구현하기 위한 기술 스택을 조사하였다.

**핵심 결론**: sensors_plus로 센서 데이터를 수집하고, SHA-256 해시로 엔트로피 풀에 축적한 뒤, PointyCastle의 FortunaRandom에 시드로 주입하여 Fisher-Yates 셔플을 구동하는 아키텍처가 최적이다. `dart:math`의 `Random.secure()`는 외부 시드를 주입할 수 없으므로 단독 사용 불가능하지만, 시스템 엔트로피 폴백으로 활용한다. 햅틱은 Flutter 내장 `HapticFeedback.selectionClick()`으로 카드 교차 틱을 구현하되, 고급 패턴이 필요하면 haptic_feedback 패키지를 도입한다.

## Details

### 1. 센서 API 패키지

#### 1.1 sensors_plus (권장)

| 항목 | 내용 |
|------|------|
| 패키지 | `sensors_plus` (pub.dev, Flutter Community 관리) |
| 최신 버전 | 5.0.1 (2025년 기준, 활발히 유지보수) |
| 지원 센서 | 가속도계(AccelerometerEvent), 사용자 가속도계(UserAccelerometerEvent), 자이로스코프(GyroscopeEvent), 자력계(MagnetometerEvent), 기압계(BarometerEvent) |
| 플랫폼 | Android, iOS, Web (Web은 샘플링 레이트 설정 불가) |
| 데이터 형식 | x, y, z (double) — 가속도계: m/s^2, 자이로스코프: rad/s |
| 스트림 방식 | BroadcastStream (`accelerometerEventStream()`, `gyroscopeEventStream()` 등) |

**샘플링 레이트 설정**: `samplingPeriod` 파라미터로 구성 가능.

```dart
accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
  .listen((AccelerometerEvent event) {
    // event.x, event.y, event.z
  });
```

**SensorInterval 상수** (Android 내부 매핑):

| SensorInterval | Duration | Android 상수 | 용도 |
|----------------|----------|-------------|------|
| `fastestInterval` | 0us | SENSOR_DELAY_FASTEST | 최대 속도 |
| `gameInterval` | 20,000us (20ms, ~50Hz) | SENSOR_DELAY_GAME | 게임/셔플 |
| `uiInterval` | 60,000us (60ms, ~16Hz) | SENSOR_DELAY_UI | UI 업데이트 |
| `normalInterval` | 200,000us (200ms, ~5Hz) | SENSOR_DELAY_NORMAL | 일반 모니터링 |

**타로 셔플 용도 권장**: `gameInterval` (20ms, ~50Hz). 셔플 인터랙션 중에만 활성화하여 배터리 소모를 제한한다.

**배터리/성능 영향**:
- 연속 리스닝은 배터리 소모를 유발함
- 네이티브 측에서 샘플링 레이트를 제한하는 것이 Dart 측 필터링보다 효율적
- Android에서 요청한 레이트가 정확히 보장되지 않음 (기기/OS 벤더 커스터마이징 의존)
- **대책**: `StreamSubscription`을 셔플 시작 시 subscribe, 셔플 완료 시 cancel. `dispose()`에서 반드시 해제.

**Android/iOS 플랫폼 차이**:

| 항목 | Android | iOS |
|------|---------|-----|
| 내부 API | SensorManager.registerListener() | CoreMotion (CMMotionManager) |
| 데이터 전달 | SensorEventListener 콜백 | push(handler block) / pull(property read) |
| 모션 코프로세서 | 기기마다 상이 | M-시리즈 Motion Coprocessor (저전력) |
| 샘플링 정확도 | 요청 레이트가 보장되지 않음 | 비교적 안정적 |
| sensors_plus 래핑 | SensorManager 직접 래핑 | CoreMotion 직접 래핑 |

#### 1.2 motion_sensors (대안)

| 항목 | 내용 |
|------|------|
| 패키지 | `flutter_motion_sensors` (pub.dev) |
| 추가 센서 | Orientation 센서 (sensors_plus에는 없음) |
| 플랫폼 | Android, iOS (Web 미지원) |
| 장점 | CoreMotion 기반 최적화, 오리엔테이션 지원 |
| 단점 | sensors_plus 대비 커뮤니티/유지보수 규모 작음, 바로미터 미지원 |

**결론**: sensors_plus가 커뮤니티 지원, 플랫폼 커버리지, 유지보수 활발성 면에서 우위. 오리엔테이션 센서가 필요하지 않으므로 sensors_plus 채택 권장.

#### 1.3 터치 이벤트 타임스탬프

`PointerEvent.timeStamp`은 `Duration` 타입으로, 마이크로초(us) 정밀도를 갖는다. 이벤트 디스패치 시점을 임의 기준점(arbitrary timeline) 기준으로 제공한다.

```dart
GestureDetector(
  onPanUpdate: (details) {
    // details 내부의 PointerEvent에서 timeStamp 추출 불가
    // → Listener 위젯을 직접 사용
  },
)

Listener(
  onPointerMove: (PointerMoveEvent event) {
    final Duration ts = event.timeStamp; // 마이크로초 정밀도
    final int microseconds = ts.inMicroseconds;
    // 엔트로피 소스로 활용 가능
  },
)
```

**PRD 시드 공식의 Ti (터치 타임스탬프)**: `event.timeStamp.inMicroseconds`를 사용. GestureDetector 대신 `Listener` 위젯을 사용해야 raw PointerEvent에 직접 접근 가능하다. 마이크로초 단위이므로 밀리초보다 높은 엔트로피를 제공한다.

#### 1.4 StreamSubscription 패턴

```dart
class ShuffleEntropyCollector {
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  void startCollecting() {
    _accelSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(_onAccelData);

    _gyroSub = gyroscopeEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(_onGyroData);
  }

  void stopCollecting() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
  }

  void _onAccelData(AccelerometerEvent e) {
    // 엔트로피 풀에 축적
  }

  void _onGyroData(GyroscopeEvent e) {
    // 엔트로피 풀에 축적
  }
}
```

---

### 2. CSPRNG 구현

#### 2.1 dart:math Random.secure()

| 항목 | 내용 |
|------|------|
| API | `Random.secure()` (dart:math) |
| 보안 수준 | 암호학적으로 안전 (CSPRNG) |
| 내부 구현 | OS 엔트로피 소스 활용. Android: /dev/urandom, iOS: SecRandomCopyBytes |
| 시드 주입 | **불가능** — 설계상 외부 시드를 받지 않음 |
| 출력 | `nextInt(max)`, `nextDouble()`, `nextBool()` |
| 예외 | 플랫폼이 CSPRNG을 지원하지 않으면 `UnsupportedError` 발생 |

**Zellic 보안 연구 (2024.12)**: Dart SDK 내부에서 `Random()` (비보안)의 시드가 32비트에 불과하여 예측 가능성이 높다는 취약점이 발견됨. `Random.secure()`는 이 문제에 영향받지 않으나, 혼동 방지를 위해 보안 용도에서는 반드시 `.secure()`를 사용해야 한다. (2024.09.25 패치 완료)

**핵심 제약**: `Random.secure()`에 센서 데이터를 시드로 주입할 수 없다. 따라서 PRD의 "센서 엔트로피를 난수에 반영" 요구사항을 이것만으로는 충족할 수 없다.

#### 2.2 PointyCastle FortunaRandom (권장)

| 항목 | 내용 |
|------|------|
| 패키지 | `pointycastle` (pub.dev, Bouncy Castle의 Dart 포트) |
| 알고리즘 | Fortuna (Bruce Schneier 설계), AES-CTR 기반 DRBG |
| 시드 주입 | **가능** — `seed(KeyParameter(Uint8List))` 메서드로 32바이트 시드 주입 |
| Re-seeding | 런타임에 추가 시드 주입 가능 (엔트로피 풀에서 주기적으로 re-seed) |
| 출력 | `nextBytes(n)`, `nextUint8()`, `nextUint16()`, `nextUint32()` |
| 오버헤드 | AES 연산 기반으로 `Random.secure()`보다 약간 느리나, 셔플(78장) 수준에서는 무시할 수 있음 |

**초기화 패턴**:

```dart
import 'package:pointycastle/pointycastle.dart';
import 'dart:math';
import 'dart:typed_data';

FortunaRandom createSecureRandom(Uint8List sensorEntropy) {
  final secureRandom = FortunaRandom();

  // 기본 시드: OS CSPRNG에서 32바이트 수집
  final seedSource = Random.secure();
  final baseSeed = Uint8List(32);
  for (int i = 0; i < 32; i++) {
    baseSeed[i] = seedSource.nextInt(256);
  }

  // 센서 엔트로피와 XOR로 혼합
  final mixedSeed = Uint8List(32);
  for (int i = 0; i < 32; i++) {
    mixedSeed[i] = baseSeed[i] ^ sensorEntropy[i % sensorEntropy.length];
  }

  secureRandom.seed(KeyParameter(mixedSeed));
  return secureRandom;
}
```

**주의사항**: PointyCastle의 Fortuna 구현은 원본 Schneier 스펙과 일부 차이가 있음. 그러나 타로 셔플 용도(암호화 아님, 통계적 편향 없는 셔플이 목표)에는 충분한 품질.

#### 2.3 PRD 시드 공식 구현 가능성

PRD 공식: `S = Σ(sqrt(Ax^2 + Ay^2 + Az^2) * Gz) XOR Ti`

```dart
double computeSeedContribution(
  double ax, double ay, double az, // 가속도계
  double gz,                        // 자이로스코프 Z축
  int touchTimestampUs,             // 터치 타임스탬프 (마이크로초)
) {
  final magnitude = sqrt(ax * ax + ay * ay + az * az);
  final sensorValue = magnitude * gz;
  // XOR은 정수 연산이므로, double을 비트 변환 후 XOR
  final sensorBits = (sensorValue * 1e6).toInt();
  final xored = sensorBits ^ touchTimestampUs;
  return xored.toDouble();
}
```

**구현 실현 가능성**: 높음. 단, 다음 사항을 고려해야 한다:
- `double`과 `int` 간의 변환 시 정밀도 손실 발생 → 비트 단위 조작 전에 충분한 스케일링 필요
- 누적 합산 Σ는 셔플 동작 중 수집된 모든 센서 샘플에 대해 수행
- 최종 값을 SHA-256으로 해싱하여 32바이트 시드로 변환하는 것이 편향 방지에 유리

#### 2.4 두 난수원 결합 전략

`Random.secure()`에 외부 시드를 주입할 수 없으므로, 다음 전략을 사용:

**방법 A (권장): FortunaRandom + 혼합 시드**
1. `Random.secure()`로 32바이트 시스템 엔트로피 수집
2. 센서 엔트로피 풀에서 32바이트 추출
3. 두 소스를 XOR 또는 SHA-256으로 혼합하여 FortunaRandom 시드 생성
4. FortunaRandom으로 Fisher-Yates 셔플 구동

**방법 B: CSPRNG 출력 + 센서 XOR**
1. `Random.secure()`로 난수 시퀀스 생성
2. 센서 엔트로피에서 동일 길이의 바이트 시퀀스 생성
3. 두 시퀀스를 XOR하여 최종 난수 결정
4. 단점: 매 셔플마다 78번의 XOR 연산 필요 (오버헤드는 미미하나 아키텍처가 복잡)

---

### 3. 하이브리드 엔트로피 모델

#### 3.1 아키텍처 개요

```
┌──────────────────────────────────────────────────┐
│                 사용자 상호작용                      │
│   (흔들기, 터치, 스와이프)                           │
└──────────┬───────────┬───────────┬───────────────┘
           │           │           │
     가속도계      자이로스코프    터치 타임스탬프
     (x,y,z)      (x,y,z)       (us)
           │           │           │
           ▼           ▼           ▼
    ┌─────────────────────────────────────┐
    │         PRD 시드 공식 적용            │
    │  √(Ax²+Ay²+Az²) × Gz ⊕ Ti          │
    └──────────────┬──────────────────────┘
                   │ 누적 (Σ)
                   ▼
    ┌─────────────────────────────────────┐
    │         엔트로피 풀 (SHA-256)         │
    │    누적 해시: H(prev || new_data)    │
    └──────────────┬──────────────────────┘
                   │ 32바이트 다이제스트
                   ▼
    ┌─────────────────────────────────────┐
    │    시드 혼합                          │
    │  SHA-256(systemEntropy ∥ sensorPool) │
    └──────────────┬──────────────────────┘
                   │
                   ▼
    ┌─────────────────────────────────────┐
    │    FortunaRandom (CSPRNG)            │
    │    seed(mixedEntropy)               │
    └──────────────┬──────────────────────┘
                   │ nextUint32()
                   ▼
    ┌─────────────────────────────────────┐
    │    Fisher-Yates 셔플 (78장)          │
    │    for i = 77 downto 1:             │
    │      j = rng.nextUint32() % (i+1)   │
    │      swap(cards[i], cards[j])        │
    └─────────────────────────────────────┘
```

#### 3.2 엔트로피 풀 구현: 누적 해시 (권장)

**링 버퍼 vs 누적 해시 비교**:

| 방식 | 장점 | 단점 |
|------|------|------|
| 링 버퍼 | 구현 단순, 최근 N개 샘플 유지 | 고정 크기, 오래된 데이터 유실, 편향 가능 |
| 누적 해시 | 모든 데이터 반영, 편향 자연 분산, 고정 출력 크기(32B) | 되돌릴 수 없음 (장점이기도 함) |

**누적 해시 방식 권장 이유**:
- 센서 데이터가 특정 범위에 편중되더라도 SHA-256이 균일 분포로 분산
- 메모리 사용량 고정 (32바이트)
- 이전 모든 입력의 영향이 누적됨
- 암호학적 해시의 avalanche effect로 미세한 입력 차이도 출력을 크게 변화

```dart
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:typed_data';

class EntropyPool {
  Uint8List _state = Uint8List(32); // 256비트 상태
  int _sampleCount = 0;

  void addSensorData(double ax, double ay, double az,
                     double gz, int touchTimestampUs) {
    // PRD 공식 적용
    final magnitude = sqrt(ax * ax + ay * ay + az * az);
    final contribution = (magnitude * gz * 1e6).toInt() ^ touchTimestampUs;

    // 누적 해시: H(prevState || newData)
    final input = Uint8List(40); // 32 (prev) + 8 (new)
    input.setAll(0, _state);
    final bytes = ByteData(8)..setInt64(0, contribution);
    input.setAll(32, bytes.buffer.asUint8List());

    _state = Uint8List.fromList(sha256.convert(input).bytes);
    _sampleCount++;
  }

  bool get hasEnoughEntropy => _sampleCount >= 10; // 최소 10샘플

  Uint8List get seed => Uint8List.fromList(_state);
}
```

#### 3.3 센서 없는 기기/에뮬레이터 폴백

```
센서 가용성 체크
  │
  ├─ 가속도계 + 자이로스코프 모두 존재
  │   → 정상 모드: 센서 엔트로피 + 시스템 CSPRNG 혼합
  │
  ├─ 가속도계만 존재 (일부 저가형 기기)
  │   → 축소 모드: 가속도계 + 터치 타임스탬프만 사용
  │
  └─ 센서 없음 (에뮬레이터, 태블릿 등)
      → 폴백 모드: Random.secure() 단독 사용
      → UX 알림: "센서 없는 기기에서는 시스템 난수만 사용됩니다"
```

sensors_plus는 센서 미지원 기기에서 스트림이 에러를 발생시키므로, `onError` 콜백으로 감지 가능:

```dart
accelerometerEventStream().listen(
  (event) { /* 정상 */ },
  onError: (error) {
    // 센서 미지원 → 폴백 모드 전환
    _fallbackToSystemRng();
  },
);
```

#### 3.4 Fisher-Yates 셔플 + 커스텀 난수원

Dart의 `List.shuffle([Random? random])`은 내부적으로 Fisher-Yates(Durstenfeld) 알고리즘을 사용하며, 커스텀 `Random` 객체를 인자로 받는다.

**접근법**: `Random` 인터페이스를 구현하는 래퍼 클래스를 만들어 FortunaRandom을 연결.

```dart
import 'dart:math';
import 'package:pointycastle/pointycastle.dart';

class HybridRandom implements Random {
  final FortunaRandom _fortuna;

  HybridRandom(this._fortuna);

  @override
  int nextInt(int max) {
    // 편향 방지: rejection sampling
    final bitsNeeded = max.bitLength;
    final mask = (1 << bitsNeeded) - 1;
    int result;
    do {
      result = _fortuna.nextUint32() & mask;
    } while (result >= max);
    return result;
  }

  @override
  double nextDouble() => _fortuna.nextUint32() / 0xFFFFFFFF;

  @override
  bool nextBool() => _fortuna.nextUint32().isOdd;
}

// 사용:
final hybridRng = HybridRandom(fortunaRandom);
cards.shuffle(hybridRng); // Dart 내장 Fisher-Yates 활용
```

이 방식의 장점:
- Dart 내장 `List.shuffle()`이 이미 검증된 Fisher-Yates 구현이므로 직접 구현할 필요 없음
- `Random` 인터페이스 래퍼만 만들면 깔끔하게 연결
- rejection sampling으로 modulo bias 방지

#### 3.5 편향(Bias) 방지

**센서 데이터 편향 문제** (학술 근거):
- Shepherd & Hurley (2025) "Entropy Collapse in Mobile Sensors" 연구에 따르면:
  - 단일 센서의 min-entropy: 3.4~4.5비트 (Shannon entropy보다 현저히 낮음)
  - 센서 22개를 결합해도 min-entropy는 8.1~23.9비트에 수렴 (entropy collapse)
  - 센서 간 상관관계로 인해 Shannon entropy 대비 ~75% 감소
- 가속도계의 특정 축은 중력 방향으로 편중 (정적 상태에서 ~9.8 m/s^2)
- 자이로스코프는 정적 상태에서 0에 가까운 값으로 수렴

**대책**:
1. **SHA-256 해싱**: 누적 해시로 편향을 균일 분포로 분산 (avalanche effect)
2. **시스템 CSPRNG 혼합**: 센서 엔트로피를 유일한 소스로 사용하지 않음. 반드시 `Random.secure()` 출력과 혼합
3. **사용자 동작 유도**: 셔플 시 "기기를 흔들어주세요" 같은 UX 유도로 정적 상태 최소화
4. **최소 샘플 수 요구**: 엔트로피 풀에 최소 10~20개 센서 샘플이 축적된 후에만 셔플 허용
5. **정규화 불필요**: SHA-256이 입력 분포와 무관하게 균일 출력을 생성하므로, 센서 값 정규화는 불필요

**중요**: 센서 데이터는 보안 목적이 아닌 "제의적 경험" 제공이 주 목적이다. 사용자의 물리적 행동이 결과에 영향을 준다는 심리적 연결감이 핵심이므로, 암호학적 수준의 엔트로피 품질이 반드시 필요하지는 않다. 다만 통계적 편향 없는 공정한 셔플은 반드시 보장해야 한다 (Fisher-Yates + CSPRNG 기반으로 달성).

---

### 4. 햅틱 피드백

#### 4.1 Flutter 내장 HapticFeedback 클래스

| 메서드 | 강도 | iOS | Android | 용도 |
|--------|------|-----|---------|------|
| `selectionClick()` | 가장 약함 | UISelectionFeedbackGenerator | View.performHapticFeedback | 카드 교차 틱 |
| `lightImpact()` | 약함 | UIImpactFeedbackGenerator(.light) | VibrationEffect | 카드 가벼운 접촉 |
| `mediumImpact()` | 중간 | UIImpactFeedbackGenerator(.medium) | VibrationEffect | 카드 스택 |
| `heavyImpact()` | 강함 | UIImpactFeedbackGenerator(.heavy) | VibrationEffect | 덱 낙하 |
| `vibrate()` | 기본 진동 | 기본 진동 | 기본 진동 | 범용 |

**카드 교차/충돌 시 틱 구현 (PRD 요구사항)**:

```dart
import 'package:flutter/services.dart';

void onCardCross() {
  HapticFeedback.selectionClick(); // 가장 미세한 틱
}

void onCardDrop() {
  HapticFeedback.lightImpact(); // 약한 충격
}

void onDeckComplete() {
  HapticFeedback.mediumImpact(); // 셔플 완료
}
```

**장점**: 별도 패키지 불필요, 퍼미션 불필요 (Android에서 HapticFeedbackConstants 사용 시), 플랫폼 최적화된 피드백.

**한계**: 커스텀 패턴 불가, 강도/지속시간 세밀 제어 불가.

#### 4.2 서드파티 패키지 비교

| 패키지 | 커스텀 패턴 | AHAP 지원 | Android 지원 | 비고 |
|--------|------------|-----------|-------------|------|
| `haptic_feedback` | API 30+ 프리미티브 | 미지원 | API 30+ high-fidelity, 26-29 waveform 폴백, <26 legacy | iOS 햅틱을 Android에서도 에뮬레이션 시도 |
| `gaimon` | .ahap 파일 지원 | 지원 | ahap → waveform 변환 | iPhone 8+ 전용 커스텀, Android 커스텀 패턴 가능 |
| `flutter_vibrate` | 패턴 리스트 | 미지원 | 지원 | 진동/일시정지 시퀀스, iOS 커스텀 패턴 제한적 |
| `vibration` | 패턴 + 강도 | 미지원 | 지원 | `Vibration.vibrate(pattern: [...], intensities: [...])` |

#### 4.3 Android 플랫폼별 햅틱 지원

| API Level | 지원 내용 |
|-----------|----------|
| < 26 (Android 8 미만) | 기본 Vibrator API만 (on/off) |
| 26-29 (Android 8-10) | VibrationEffect (CLICK, TICK, DOUBLE_CLICK), waveform 패턴 |
| 30 (Android 11) | VibrationEffect.Composition 프리미티브 (high-fidelity) |
| 31+ (Android 12+) | SPIN 등 추가 프리미티브, 개선된 햅틱 API |

**참고**: VibrationEffect.Composition 프리미티브는 기기 하드웨어 지원에 의존하며, 시스템 레벨 폴백이 없다. haptic_feedback 패키지는 이 차이를 자동 처리한다.

#### 4.4 카드 교차/충돌 햅틱 구현 전략

**타이밍 설계**:
- 리플 셔플: 카드 교차 시마다 `selectionClick()` (150-200ms 간격, PRD 명세)
- 오버핸드 셔플: 청크 분리 시 `lightImpact()`, 합칠 때 `selectionClick()`
- 워시/메시: 카드 충돌 시 `selectionClick()`, 과도한 호출 방지를 위해 쓰로틀링(50ms 최소 간격)

**쓰로틀링 구현**:

```dart
DateTime _lastHaptic = DateTime.now();
static const _minInterval = Duration(milliseconds: 50);

void triggerHapticTick() {
  final now = DateTime.now();
  if (now.difference(_lastHaptic) >= _minInterval) {
    HapticFeedback.selectionClick();
    _lastHaptic = now;
  }
}
```

**배터리/성능 영향**:
- 햅틱 피드백 자체의 배터리 소모는 미미
- 과도한 호출 (< 20ms 간격)은 진동 모터 수명과 UX에 부정적
- 50ms 쓰로틀링으로 충분한 체감과 성능 균형 달성

#### 4.5 권장 접근

1단계 (MVP): Flutter 내장 `HapticFeedback` 클래스만 사용. `selectionClick()`, `lightImpact()`, `mediumImpact()`로 3단계 피드백.
2단계 (고도화): `haptic_feedback` 패키지 도입하여 Android API 30+ 고품질 프리미티브 활용. 커스텀 패턴으로 셔플 방식별 차별화된 햅틱 경험 제공.

---

## Key Findings

1. **센서 API**: sensors_plus가 성숙하고 안정적. gameInterval(20ms, ~50Hz)로 셔플 인터랙션 중 충분한 센서 데이터 수집 가능. 반드시 셔플 진행 시에만 구독하고, 완료 시 해제하여 배터리 보호.

2. **CSPRNG**: `Random.secure()`는 외부 시드 주입 불가. PointyCastle의 `FortunaRandom`이 시드 주입을 지원하므로, 센서 엔트로피를 반영하는 유일한 실용적 방법이다. `Random` 인터페이스 래퍼를 만들면 Dart 내장 `List.shuffle()`과 호환 가능.

3. **엔트로피 모델**: 센서 데이터를 SHA-256 누적 해시로 축적하고, 시스템 CSPRNG 출력과 혼합하여 FortunaRandom에 시드하는 아키텍처가 최적. 센서 데이터 단독은 min-entropy가 낮으므로(3.4~4.5비트/센서) 반드시 시스템 엔트로피와 혼합 필수.

4. **햅틱**: Flutter 내장 HapticFeedback으로 MVP 구현 충분. `selectionClick()`이 카드 교차 틱에 적합. 50ms 쓰로틀링으로 과도한 호출 방지.

5. **PRD 시드 공식**: Dart로 구현 가능. `sqrt(Ax^2+Ay^2+Az^2) * Gz XOR Ti` 계산 후 SHA-256으로 해싱하여 32바이트 시드 생성. PointerEvent.timeStamp 마이크로초 정밀도 활용.

6. **편향 방지**: SHA-256의 avalanche effect가 센서 데이터 편향을 분산. 센서 데이터를 유일한 엔트로피 소스로 사용하지 않고 시스템 CSPRNG과 혼합하는 것이 핵심.

## Recommendations

### 패키지 선정

| 용도 | 패키지 | 버전 | 비고 |
|------|--------|------|------|
| 센서 데이터 | `sensors_plus` | ^5.0.0 | 가속도계 + 자이로스코프 |
| CSPRNG | `pointycastle` | ^3.7.0 | FortunaRandom |
| 해싱 | `crypto` | ^3.0.0 | SHA-256 엔트로피 풀 |
| 햅틱 (MVP) | Flutter 내장 | — | HapticFeedback 클래스 |
| 햅틱 (고도화) | `haptic_feedback` | ^1.0.0 | API 30+ 고품질 |

### 아키텍처 권장 구조

```
mobile/lib/
  core/
    entropy/
      entropy_pool.dart         # SHA-256 누적 해시 엔트로피 풀
      sensor_collector.dart     # sensors_plus StreamSubscription 관리
      hybrid_random.dart        # Random 인터페이스 래퍼 (FortunaRandom)
    haptic/
      haptic_manager.dart       # 쓰로틀링 + 셔플 유형별 햅틱 매핑
  feature/
    shuffle/
      shuffle_engine.dart       # Fisher-Yates + HybridRandom 연결
```

### 구현 우선순위

1. `EntropyPool` (SHA-256 누적 해시) + `SensorCollector` (sensors_plus 래핑)
2. `HybridRandom` (FortunaRandom + Random 인터페이스)
3. `ShuffleEngine` (Fisher-Yates via `List.shuffle(hybridRandom)`)
4. `HapticManager` (HapticFeedback.selectionClick + 쓰로틀링)
5. 폴백 로직 (센서 미지원 → Random.secure() 단독)
6. (고도화) haptic_feedback 패키지 도입

## References

### 공식 문서 / API
- [sensors_plus | pub.dev](https://pub.dev/packages/sensors_plus)
- [sensors_plus 5.0.1 | pub.dev](https://pub.dev/packages/sensors_plus/versions/5.0.1)
- [Random.secure() | Dart API](https://api.flutter.dev/flutter/dart-math/Random/Random.secure.html)
- [FortunaRandom | PointyCastle API](https://pub.dev/documentation/pointycastle/latest/impl.secure_random.fortuna_random/FortunaRandom-class.html)
- [SecureRandom | PointyCastle API](https://pub.dev/documentation/pointycastle/latest/api/SecureRandom-class.html)
- [pointycastle | pub.dev](https://pub.dev/packages/pointycastle)
- [HapticFeedback class | Flutter API](https://api.flutter.dev/flutter/services/HapticFeedback-class.html)
- [PointerEvent.timeStamp | Flutter API](https://api.flutter.dev/flutter/gestures/PointerEvent/timeStamp.html)
- [List.shuffle() | Dart API](https://api.flutter.dev/flutter/dart-core/List/shuffle.html)
- [crypto | pub.dev](https://pub.dev/packages/crypto)

### 서드파티 패키지
- [haptic_feedback | pub.dev](https://pub.dev/packages/haptic_feedback)
- [gaimon | pub.dev](https://pub.dev/packages/gaimon)
- [flutter_vibrate | pub.dev](https://pub.dev/packages/flutter_vibrate)
- [vibration | pub.dev](https://pub.dev/packages/vibration)
- [flutter_motion_sensors | GitHub](https://github.com/zesage/motion_sensors)

### 학술 연구 / 보안 분석
- [Shepherd & Hurley (2025) "Entropy Collapse in Mobile Sensors: The Hidden Risks of Sensor-Based Security"](https://arxiv.org/abs/2502.09535)
- [Zellic (2024) "Far From Random: Three Mistakes From Dart/Flutter's Weak PRNG"](https://www.zellic.io/blog/proton-dart-flutter-csprng-prng/)
- [IEEE IoT Journal — "Toward Sensor-Based Random Number Generation for Mobile and IoT Devices"](https://static1.squarespace.com/static/53065911e4b0cca0183fc14a/t/57fabdaa6a496306c83ca9a5/1476050348493/SensoRNG-preprint.pdf)
- [ACM (2020) "Analysis on Entropy Sources based on Smartphone Sensors"](https://dl.acm.org/doi/fullHtml/10.1145/3442520.3442528)

### Android 플랫폼
- [Android Haptics API Reference](https://developer.android.com/develop/ui/views/haptics/haptics-apis)
- [Android Haptic Feedback Guide](https://developer.android.com/develop/ui/views/haptics/haptic-feedback)
- [Android SensorManager](https://developer.android.com/reference/android/hardware/SensorManager)
- [CoreMotion | Apple Developer](https://developer.apple.com/documentation/coremotion)

### 프로젝트 내부 참조
- docs/003_gemini_deep_research.md (PRD)
- docs/11_tarot_shuffle/001_Scope_platform_strategy.md (플랫폼 전략)
- docs/11_tarot_shuffle/002_Research_tarot_shuffle_tech.md (기술 연구 마스터)

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
