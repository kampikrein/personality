---
id: "056"
type: plan
title: "RNG 최적화 구현 — Fisher-Yates + Random.secure() 교체"
created: 2026-03-17
traces_scope: "055"
traces_research: "054"
summary: >
  연구 054의 3 Critical + 2 High 발견 구현. Fortuna/리플 셔플을 Fisher-Yates + Random.secure()로 교체.
  센서 엔트로피 결함 수정, 건강 테스트 추가, pointycastle 의존성 제거. 9개 파일 변경.
keywords: [Fisher-Yates, Random.secure, Fortuna-removal, sensor-fix, health-test]
---

# 056 — RNG 최적화 구현

## Goal

연구 054가 발견한 3개 Critical 문제(리플 3회 무효, Fortuna 불완전, 센서 곱셈 결함)와 2개 High 문제(건강 테스트 부재, 검증 파이프라인 부재)를 해결한다. 복잡한 4-레이어 파이프라인을 수학적으로 완벽한 2-레이어 구조로 교체하면서, 리플 애니메이션은 시각적 제의 경험으로 유지한다.

## Scope

### Included
| # | Item | Description |
|---|------|-------------|
| 1 | Fisher-Yates 셔플 전략 | Knuth 알고리즘, 1/n! 균등 분포 증명 |
| 2 | Random.secure() 직접 사용 | Fortuna 레이어 제거 |
| 3 | 센서 seedContribution 수정 | 곱셈→합산, gyroZ≈0 문제 해결 |
| 4 | 건강 테스트 추가 | RCT/APT 간이 구현, minSamples 증가 |
| 5 | pointycastle 의존성 제거 | pubspec.yaml에서 삭제 |

### Excluded
| Item | Reason/Timeline |
|------|-----------------|
| PractRand/TestU01 CI 파이프라인 | 인프라 작업, 별도 태스크로 분리 |
| 리플 애니메이션 수정 | 시각 전용으로 유지, 변경 불필요 |
| nextDouble 53비트 해상도 | Random.secure()가 내부 처리, 카드 셔플에 불필요 |

## Structural Decisions

No structural decisions required — 연구 054에서 접근법 확정, `shuffleCount`는 애니메이션용으로 유지.

---

## File Change Summary

### Modified Files
| # | File Path | Change Description |
|---|-----------|-------------------|
| 1 | `mobile/lib/features/shuffle/domain/usecases/shuffle_deck_usecase.dart` | Fortuna → Random.secure(), import 정리 |
| 2 | `mobile/lib/features/shuffle/data/datasources/sensor_data_collector.dart` | seedContribution 공식 수정 |
| 3 | `mobile/lib/features/shuffle/data/datasources/entropy_pool.dart` | 건강 테스트 추가, minSamples 50 |
| 4 | `mobile/lib/features/shuffle/presentation/providers/shuffle_providers.dart` | RiffleShuffleStrategy → FisherYatesShuffleStrategy |
| 5 | `mobile/pubspec.yaml` | pointycastle 제거 |

### New Files
| # | File Path | Description |
|---|-----------|-------------|
| 1 | `mobile/lib/features/shuffle/domain/strategies/fisher_yates_shuffle_strategy.dart` | Knuth Fisher-Yates 구현 |

### Deleted Files
| # | File Path | Reason |
|---|-----------|--------|
| 1 | `mobile/lib/features/shuffle/domain/strategies/riffle_shuffle_strategy.dart` | Fisher-Yates로 대체 |
| 2 | `mobile/lib/features/shuffle/data/datasources/fortuna_random_wrapper.dart` | Random.secure()로 대체 |

### Auto-regenerated Files
| # | File Path | Trigger |
|---|-----------|---------|
| 1 | `mobile/lib/features/shuffle/presentation/providers/shuffle_providers.g.dart` | providers 변경 |
| 2 | `mobile/pubspec.lock` | pubspec.yaml 변경 |

---

## Step 1 — Fisher-Yates 셔플 전략 생성

### Approach
Knuth Fisher-Yates 알고리즘을 `ShuffleStrategy` 인터페이스로 구현한다. 기존 `RiffleShuffleStrategy`와 동일한 시그니처를 유지하되, 내부 로직만 교체. `config.shuffleCount`는 사용하지 않는다 (애니메이션 전용).

### Current Code
```dart
// riffle_shuffle_strategy.dart — 삭제 예정
class RiffleShuffleStrategy implements ShuffleStrategy {
  @override
  ShuffleResult shuffle({
    required List<TarotCard> cards,
    required Random random,
    required ShuffleConfig config,
  }) {
    var deck = List<TarotCard>.from(cards);
    for (var i = 0; i < config.shuffleCount; i++) {
      deck = _riffleOnce(deck, random);
    }
    // ... reversal logic + ShuffleResult 생성
  }
}
```

### After Code
```dart
// fisher_yates_shuffle_strategy.dart — 신규
import 'dart:math';

import '../entities/shuffle_config.dart';
import '../entities/shuffle_result.dart';
import '../../../deck/domain/entities/tarot_card.dart';
import 'shuffle_strategy.dart';

class FisherYatesShuffleStrategy implements ShuffleStrategy {
  @override
  String get name => 'fisher_yates';

  @override
  String get displayName => 'Fisher-Yates 셔플';

  @override
  ShuffleResult shuffle({
    required List<TarotCard> cards,
    required Random random,
    required ShuffleConfig config,
  }) {
    final deck = List<TarotCard>.from(cards);

    // Knuth Fisher-Yates: O(n), 1/n! 균등 분포 (TAOCP Vol.2 §3.4.2)
    for (var i = deck.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = deck[i];
      deck[i] = deck[j];
      deck[j] = temp;
    }

    final shuffledCards = deck.map((card) {
      final isReversed = config.useReversals &&
          random.nextDouble() < config.reversalProbability;
      return ShuffledCard(card: card, isReversed: isReversed);
    }).toList();

    return ShuffleResult(
      cards: shuffledCards,
      entropyBits: 256,
      usedSensorEntropy: false,
      shuffledAt: DateTime.now(),
    );
  }
}
```

### Considerations
- `shuffleCount`를 의도적으로 무시: Fisher-Yates는 single-pass로 수학적 완벽성 달성. 리플 애니메이션이 별도로 `shuffleCount`회 재생.
- `entropyBits: 256`: Random.secure()가 OS CSPRNG 기반 256비트 엔트로피 제공.

---

## Step 2 — ShuffleDeckUseCase 단순화

### Approach
`FortunaRandomWrapper(seed)` 생성을 `Random.secure()` 직접 사용으로 교체. 센서/엔트로피 풀은 UX 용도로 유지하되 시드 생성에는 사용하지 않음.

### Current Code
```dart
// shuffle_deck_usecase.dart:5-6,31
import '../../data/datasources/fortuna_random_wrapper.dart';
import '../../data/datasources/sensor_data_collector.dart';
// ...
    final seed = usedSensor
        ? entropyPool.generateSeed()
        : entropyPool.generateFallbackSeed();
    final random = FortunaRandomWrapper(seed);
```

### After Code
```dart
// shuffle_deck_usecase.dart — 전체 교체
import 'dart:math';

import '../entities/shuffle_config.dart';
import '../entities/shuffle_result.dart';
import '../strategies/shuffle_strategy.dart';
import '../../../deck/domain/entities/tarot_card.dart';
import '../../data/datasources/entropy_pool.dart';
import '../../data/datasources/sensor_data_collector.dart';

class ShuffleDeckUseCase {
  ShuffleDeckUseCase({
    required this.sensorCollector,
    required this.entropyPool,
  });

  final SensorDataCollector sensorCollector;
  final EntropyPool entropyPool;

  ShuffleResult execute({
    required List<TarotCard> cards,
    required ShuffleStrategy strategy,
    ShuffleConfig config = const ShuffleConfig(),
  }) {
    entropyPool.addSamples(sensorCollector.samples);

    final usedSensor =
        sensorCollector.sensorsAvailable && entropyPool.isReady;

    final random = Random.secure();

    final result = strategy.shuffle(
      cards: cards,
      random: random,
      config: config,
    );

    entropyPool.reset();

    return result.copyWith(usedSensorEntropy: usedSensor);
  }
}
```

### Considerations
- `entropyPool.addSamples()` + `isReady` + `reset()`는 UX 용도(진행률 표시)로 유지.
- `usedSensorEntropy` 플래그도 유지 — UI에서 "센서 활용됨" 표시에 사용.
- `FortunaRandomWrapper` import 제거 → 해당 파일 삭제의 전제 조건.

---

## Step 3 — 센서 seedContribution 결함 수정

### Approach
`accelMagnitude * gyroZ`를 `accelMagnitude + gyroZ.abs()`로 변경. gyroZ≈0 시 엔트로피 기여가 0이 되는 Critical 결함 해결.

### Current Code
```dart
// sensor_data_collector.dart:17
  double get seedContribution => accelMagnitude * gyroZ;
```

### After Code
```dart
// sensor_data_collector.dart:17
  double get seedContribution => accelMagnitude + gyroZ.abs();
```

### Considerations
- 연구 054 (R-054-F3): "gyroZ ≈ 0일 때 (전체의 ~60%) 센서 엔트로피 기여가 0"
- 합산 방식: 각 센서 축이 독립적으로 엔트로피에 기여. 어느 축이 0이어도 다른 축의 기여 유지.
- `abs()` 사용: 자이로스코프 값의 부호는 회전 방향이므로, 엔트로피 관점에서 절댓값이 적절.

---

## Step 4 — EntropyPool 건강 테스트 추가

### Approach
NIST SP 800-90B 필수 테스트 2종을 간이 구현:
- **RCT (Repetition Count Test)**: 동일 값 연속 반복 탐지
- **APT (Adaptive Proportion Test)**: 엔트로피 대규모 손실 탐지
`minSamples`를 10 → 50으로 증가.

### Current Code
```dart
// entropy_pool.dart:9
  static const int minSamples = 10;

// (건강 테스트 없음)
```

### After Code
```dart
// entropy_pool.dart — 건강 테스트 추가
class EntropyPool {
  static const int minSamples = 50;

  Uint8List _pool = Uint8List(32);
  int _accumulatedSamples = 0;
  bool _healthTestPassed = true;

  // RCT: 동일 값 연속 반복 제한
  static const int _rctCutoff = 5;
  double? _lastContribution;
  int _repetitionCount = 0;

  // APT: 가장 빈번한 값의 비율 제한
  static const int _aptWindowSize = 64;
  static const int _aptCutoff = 48; // 64개 중 48개 이상 동일 → 실패
  final List<int> _aptBuckets = List.filled(8, 0);
  int _aptSampleCount = 0;

  bool get isReady => _accumulatedSamples >= minSamples;
  bool get isHealthy => _healthTestPassed;
  double get progress => (_accumulatedSamples / minSamples).clamp(0.0, 1.0);

  void addSamples(List<SensorSample> samples) {
    for (final sample in samples) {
      _accumulate(sample);
    }
  }

  void _accumulate(SensorSample sample) {
    final contribution = sample.seedContribution;
    _runHealthTests(contribution);

    final timestamp = sample.timestampMicros;

    final contributionBytes = ByteData(8)..setFloat64(0, contribution);
    final timestampBytes = ByteData(8)..setInt64(0, timestamp);

    final combined = Uint8List(16);
    for (var i = 0; i < 8; i++) {
      combined[i] = contributionBytes.getUint8(i) ^ timestampBytes.getUint8(i);
      combined[i + 8] = contributionBytes.getUint8(i);
    }

    final digest = sha256.convert([..._pool, ...combined]);
    _pool = Uint8List.fromList(digest.bytes);
    _accumulatedSamples++;
  }

  void _runHealthTests(double contribution) {
    // RCT: Repetition Count Test
    if (_lastContribution != null && contribution == _lastContribution) {
      _repetitionCount++;
      if (_repetitionCount >= _rctCutoff) {
        _healthTestPassed = false;
      }
    } else {
      _repetitionCount = 0;
    }
    _lastContribution = contribution;

    // APT: Adaptive Proportion Test (quantized to 8 buckets)
    if (_aptSampleCount < _aptWindowSize) {
      final bucket = (contribution.abs() % 8).toInt();
      _aptBuckets[bucket]++;
      _aptSampleCount++;

      if (_aptSampleCount == _aptWindowSize) {
        final maxCount = _aptBuckets.reduce((a, b) => a > b ? a : b);
        if (maxCount >= _aptCutoff) {
          _healthTestPassed = false;
        }
      }
    }
  }

  Uint8List generateSeed() {
    final systemRandom = Random.secure();
    final systemBytes = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      systemBytes[i] = systemRandom.nextInt(256);
    }

    final finalDigest = sha256.convert([..._pool, ...systemBytes]);
    return Uint8List.fromList(finalDigest.bytes);
  }

  Uint8List generateFallbackSeed() {
    final systemRandom = Random.secure();
    final bytes = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      bytes[i] = systemRandom.nextInt(256);
    }
    return bytes;
  }

  void reset() {
    _pool = Uint8List(32);
    _accumulatedSamples = 0;
    _healthTestPassed = true;
    _lastContribution = null;
    _repetitionCount = 0;
    _aptBuckets.fillRange(0, _aptBuckets.length, 0);
    _aptSampleCount = 0;
  }
}
```

### Considerations
- 건강 테스트는 보안용이 아닌 품질 모니터링 용도. 실패해도 Random.secure()가 실제 보안을 담당.
- `isHealthy` 플래그는 현재 UI에서 사용하지 않지만, 향후 센서 품질 경고에 활용 가능.
- APT는 양자화된 8-bucket 간이 구현. 정밀한 NIST 규격과 차이 있으나 실용적으로 충분.

---

## Step 5 — 프로바이더 업데이트

### Approach
`RiffleShuffleStrategy` → `FisherYatesShuffleStrategy` 교체.

### Current Code
```dart
// shuffle_providers.dart:10,35
import '../../domain/strategies/riffle_shuffle_strategy.dart';
// ...
  return RiffleShuffleStrategy();
```

### After Code
```dart
// shuffle_providers.dart:10,35
import '../../domain/strategies/fisher_yates_shuffle_strategy.dart';
// ...
  return FisherYatesShuffleStrategy();
```

---

## Step 6 — Fortuna 래퍼 삭제 + pointycastle 제거

### Approach
1. `fortuna_random_wrapper.dart` 파일 삭제 (Step 2에서 import 이미 제거됨)
2. `riffle_shuffle_strategy.dart` 파일 삭제 (Step 1에서 대체됨)
3. `pubspec.yaml`에서 `pointycastle: ^3.7.0` 제거
4. `flutter pub get` 실행하여 `pubspec.lock` 갱신

### Current Code
```yaml
# pubspec.yaml:19
  pointycastle: ^3.7.0
```

### After Code
```yaml
# pubspec.yaml:19 — 해당 줄 삭제
```

---

## Step 7 — 코드 생성 + 빌드 검증

### Approach
1. `dart run build_runner build --delete-conflicting-outputs` — providers.g.dart 재생성
2. `flutter pub get` — pubspec.lock 갱신
3. `flutter analyze` — 정적 분석 통과 확인

---

## Considerations & Trade-offs

### Alternative Approaches
| 접근법 | 비채택 이유 |
|--------|-----------|
| 리플 10회로 증가 | TV≈0.08은 "수용 가능"이나 Fisher-Yates의 수학적 완벽(1/n!)에 미달 |
| ChaCha20 CSPRNG 직접 구현 | 78장에 308바이트만 필요 — Random.secure()와 성능 차이 무의미 |
| 센서 엔트로피 완전 제거 | 제의적 UX 가치 유지를 위해 수집은 유지 |

### Potential Risks
| 리스크 | 완화 |
|--------|------|
| Random.secure() 에뮬레이터 동작 | Dart SDK 내장, 에뮬레이터에서도 정상 작동 (Linux getrandom) |
| pointycastle 제거 시 다른 의존 | grep 확인 완료 — shuffle 외 사용처 없음 |

### Backward Compatibility
- `ShuffleResult` 모델 변경 없음 — 기존 데이터 호환
- `ShuffleConfig.shuffleCount` 유지 — 애니메이션 호환
- `ShuffleStrategy` 인터페이스 변경 없음 — 다른 전략 추가 가능

---

## Implementation Checklist

- [x] Step 1: `fisher_yates_shuffle_strategy.dart` 생성
- [x] Step 2: `shuffle_deck_usecase.dart` 수정 (Random.secure() 직접 사용)
- [x] Step 3: `sensor_data_collector.dart` seedContribution 수정
- [x] Step 4: `entropy_pool.dart` 건강 테스트 + minSamples 50
- [x] Step 5: `shuffle_providers.dart` 전략 교체
- [x] Step 6a: `riffle_shuffle_strategy.dart` 삭제
- [x] Step 6b: `fortuna_random_wrapper.dart` 삭제
- [x] Step 6c: `pubspec.yaml` pointycastle 제거
- [x] Step 7: 코드 생성 + 빌드 검증

## Verification Assertions

| Level | Assertion | Verification Method | Expected Result |
|-------|-----------|-------------------|-----------------|
| L1-Build | Dart 정적 분석 통과 | `flutter analyze` | 에러 0 |
| L1-Build | 코드 생성 성공 | `dart run build_runner build` | 에러 0 |
| L1-Build | pub get 성공 | `flutter pub get` | pointycastle 미포함 |
| L4-Trace | R-054-F1 리플→Fisher-Yates 교체 | Fisher-Yates 전략 존재 + 리플 전략 삭제 | 완료 |
| L4-Trace | R-054-F2 Fortuna→Random.secure() 교체 | FortunaRandomWrapper 삭제 + Random.secure() 사용 | 완료 |
| L4-Trace | R-054-F3 센서 곱셈 결함 수정 | seedContribution 합산 공식 | 완료 |
| L4-Trace | R-054-F4 건강 테스트 추가 | RCT/APT 구현 존재 | 완료 |

## References

| Resource | Path/URL | Related Content |
|----------|---------|-----------------|
| Research (최종) | `docs/11_tarot_shuffle/054_Research_rng_optimization_final.md` | 4관점 연구 결과 |
| Scope | `docs/11_tarot_shuffle/055_Scope_rng_implementation.md` | 구현 범위 정의 |
| 원본 Scope | `docs/11_tarot_shuffle/047_Scope_rng_optimization.md` | 연구 범위 정의 |
