---
id: "011"
type: plan
title: "Phase 2 — 셔플 엔진 + 엔트로피 코어"
created: 2026-03-15
phase: 2
parent: "009"
depends_on: ["010"]
parallel_with: []
traces_scope: "001"
traces_research: "008"
summary: >
  센서 수집(sensors_plus), SHA-256 엔트로피 풀, FortunaRandom CSPRNG,
  ShuffleStrategy 인터페이스 + 리플 셔플 구현, Repository 계층 전체.
  핵심 비즈니스 로직 — UI 없이 독립 테스트 가능.
keywords: [shuffle-engine, entropy, fortuna, sensors, strategy-pattern, repository]
---

# 011 — Phase 2: 셔플 엔진 + 엔트로피 코어

## Goal

PRD의 "사용자의 물리적 개입이 셔플에 반영"을 구현하는 코어 엔진을 작성한다. 센서 데이터 → SHA-256 엔트로피 풀 → FortunaRandom CSPRNG → Fisher-Yates 셔플 파이프라인을 완성하고, Strategy 패턴으로 향후 오버핸드/워시 셔플 확장에 대비한다.

## Scope

### Included
| # | Item | Description |
|---|------|-------------|
| 1 | SensorDataCollector | sensors_plus 래퍼, 가속도계/자이로 수집 |
| 2 | EntropyPool | SHA-256 누적 해시, 센서 + 시스템 CSPRNG 혼합 |
| 3 | FortunaRandomWrapper | PointyCastle FortunaRandom → Dart Random 어댑터 |
| 4 | ShuffleStrategy | 셔플 전략 인터페이스 (확장 대비) |
| 5 | RiffleShuffleStrategy | 리플 셔플 구현 (Fisher-Yates) |
| 6 | ShuffleResult, ShuffleConfig | 셔플 결과/설정 freezed 모델 |
| 7 | ShuffleDeckUseCase | 셔플 유스케이스 (엔트로피 → 전략 → 결과) |
| 8 | Repository 계층 | Deck, Shuffle, Reading repository 인터페이스 + 구현 |
| 9 | RWS 시드 서비스 | JSON → DB 시드 로직 |
| 10 | HapticService | 햅틱 피드백 래퍼 (50ms 쓰로틀링) |

### Excluded
| Item | Reason/Timeline |
|------|-----------------|
| 오버핸드/워시 셔플 전략 | Phase 2+ (Flame 도입 후) |
| UI/위젯 | Phase 3 |
| 카드 애니메이션 상태 | Phase 3 (CardPainter) |

## Structural Decisions

> No additional structural decisions required — all resolved in checkpoint (009).

---

## File Change Summary

### Modified Files
없음 (모두 신규 파일)

### New Files
| # | File Path | Description |
|---|-----------|-------------|
| 1 | mobile/lib/features/shuffle/data/datasources/sensor_data_collector.dart | 센서 수집기 |
| 2 | mobile/lib/features/shuffle/data/datasources/entropy_pool.dart | SHA-256 엔트로피 풀 |
| 3 | mobile/lib/features/shuffle/data/datasources/fortuna_random_wrapper.dart | FortunaRandom 어댑터 |
| 4 | mobile/lib/features/shuffle/domain/entities/shuffle_result.dart | ShuffleResult freezed |
| 5 | mobile/lib/features/shuffle/domain/entities/shuffle_config.dart | ShuffleConfig freezed |
| 6 | mobile/lib/features/shuffle/domain/strategies/shuffle_strategy.dart | Strategy 인터페이스 |
| 7 | mobile/lib/features/shuffle/domain/strategies/riffle_shuffle_strategy.dart | 리플 셔플 구현 |
| 8 | mobile/lib/features/shuffle/domain/repositories/shuffle_repository.dart | Shuffle repo 인터페이스 |
| 9 | mobile/lib/features/shuffle/domain/usecases/shuffle_deck_usecase.dart | 셔플 유스케이스 |
| 10 | mobile/lib/features/shuffle/data/repositories/shuffle_repository_impl.dart | Shuffle repo 구현 |
| 11 | mobile/lib/features/deck/domain/repositories/deck_repository.dart | Deck repo 인터페이스 |
| 12 | mobile/lib/features/deck/data/repositories/deck_repository_impl.dart | Deck repo 구현 |
| 13 | mobile/lib/features/deck/data/services/rws_seed_service.dart | RWS 시드 로직 |
| 14 | mobile/lib/features/reading/domain/repositories/reading_repository.dart | Reading repo 인터페이스 |
| 15 | mobile/lib/features/reading/data/repositories/reading_repository_impl.dart | Reading repo 구현 |
| 16 | mobile/lib/features/shuffle/data/services/haptic_service.dart | 햅틱 래퍼 |

---

## Step 1 — SensorDataCollector

### Approach
sensors_plus의 가속도계/자이로스코프 스트림을 래핑. PRD 시드 공식 `S = Σ(√(Ax²+Ay²+Az²) × Gz) ⊕ Ti`의 입력 데이터를 수집. 폴백(센서 없음) 처리 포함.

### After Code
```dart
// mobile/lib/features/shuffle/data/datasources/sensor_data_collector.dart (new)
import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class SensorSample {
  const SensorSample({
    required this.accelMagnitude,
    required this.gyroZ,
    required this.timestampMicros,
  });

  final double accelMagnitude;  // √(Ax² + Ay² + Az²)
  final double gyroZ;
  final int timestampMicros;

  /// PRD 시드 공식: S = accelMagnitude × gyroZ ⊕ timestamp
  double get seedContribution => accelMagnitude * gyroZ;
}

class SensorDataCollector {
  final List<SensorSample> _samples = [];
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  AccelerometerEvent? _lastAccel;
  bool _isCollecting = false;
  bool _sensorsAvailable = true;

  int get sampleCount => _samples.length;
  bool get isCollecting => _isCollecting;
  bool get sensorsAvailable => _sensorsAvailable;
  List<SensorSample> get samples => List.unmodifiable(_samples);

  void startCollecting() {
    if (_isCollecting) return;
    _isCollecting = true;
    _samples.clear();

    try {
      _accelSub = accelerometerEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(
        (event) => _lastAccel = event,
        onError: (_) => _sensorsAvailable = false,
      );

      _gyroSub = gyroscopeEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(
        (event) {
          if (_lastAccel == null) return;
          final accel = _lastAccel!;
          _samples.add(SensorSample(
            accelMagnitude: sqrt(
              accel.x * accel.x + accel.y * accel.y + accel.z * accel.z,
            ),
            gyroZ: event.z,
            timestampMicros: DateTime.now().microsecondsSinceEpoch,
          ));
        },
        onError: (_) => _sensorsAvailable = false,
      );
    } catch (_) {
      _sensorsAvailable = false;
    }
  }

  void stopCollecting() {
    _isCollecting = false;
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _accelSub = null;
    _gyroSub = null;
  }

  void dispose() {
    stopCollecting();
    _samples.clear();
  }
}
```

### Considerations
- `SensorInterval.gameInterval` (20ms, ~50Hz): Research(008) 권장
- `_lastAccel` 패턴: 가속도계와 자이로스코프가 비동기 도착 → 최신 가속도계 값을 자이로 이벤트와 페어링
- 센서 미지원 시 `_sensorsAvailable = false` → EntropyPool에서 `Random.secure()` 폴백
- dispose()로 구독 정리 필수

---

## Step 2 — EntropyPool

### Approach
Research(008-F3, F7)의 하이브리드 엔트로피 모델 구현. 센서 샘플을 SHA-256으로 누적 해싱하고, 시스템 CSPRNG과 혼합하여 최종 시드 생성. 최소 10샘플 강제.

### After Code
```dart
// mobile/lib/features/shuffle/data/datasources/entropy_pool.dart (new)
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

import 'sensor_data_collector.dart';

class EntropyPool {
  static const int minSamples = 10;

  Uint8List _pool = Uint8List(32); // 256-bit pool

  bool get isReady => _sampleCount >= minSamples;
  int get _sampleCount => _accumulatedSamples;
  int _accumulatedSamples = 0;

  double get progress => (_accumulatedSamples / minSamples).clamp(0.0, 1.0);

  /// 센서 샘플을 엔트로피 풀에 누적
  void addSamples(List<SensorSample> samples) {
    for (final sample in samples) {
      _accumulate(sample);
    }
  }

  void _accumulate(SensorSample sample) {
    // PRD 시드 공식: S = (accelMagnitude × gyroZ) XOR timestamp
    final contribution = sample.seedContribution;
    final timestamp = sample.timestampMicros;

    // contribution을 바이트로 변환
    final contributionBytes = ByteData(8)..setFloat64(0, contribution);
    final timestampBytes = ByteData(8)..setInt64(0, timestamp);

    // XOR로 결합
    final combined = Uint8List(16);
    for (var i = 0; i < 8; i++) {
      combined[i] = contributionBytes.getUint8(i) ^ timestampBytes.getUint8(i);
      combined[i + 8] = contributionBytes.getUint8(i);
    }

    // SHA-256 누적: pool = SHA256(pool || combined)
    final digest = sha256.convert([..._pool, ...combined]);
    _pool = Uint8List.fromList(digest.bytes);
    _accumulatedSamples++;
  }

  /// 최종 시드 생성: 센서 엔트로피 + 시스템 CSPRNG 혼합
  Uint8List generateSeed() {
    // 시스템 CSPRNG 32바이트
    final systemRandom = Random.secure();
    final systemBytes = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      systemBytes[i] = systemRandom.nextInt(256);
    }

    // 최종 시드 = SHA256(pool || systemBytes)
    final finalDigest = sha256.convert([..._pool, ...systemBytes]);
    return Uint8List.fromList(finalDigest.bytes);
  }

  /// 센서 없는 환경용 폴백: 시스템 CSPRNG만 사용
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
  }
}
```

### Considerations
- **SHA-256 avalanche effect**: 편향된 센서 데이터도 해시 후 균등 분포에 근접
- **시스템 CSPRNG 혼합 필수**: R-008-F7 — 센서 min-entropy만으로는 암호학적 안전성 미달
- **minSamples = 10**: 최소 200ms(10 × 20ms) 수집. UI에서 progress 표시
- `generateFallbackSeed()`: 에뮬레이터/센서 없는 기기용

---

## Step 3 — FortunaRandomWrapper

### Approach
PointyCastle의 `FortunaRandom`을 Dart `Random` 인터페이스로 래핑. `List.shuffle(random)` 직접 사용 가능 → Fisher-Yates 직접 구현 불필요.

### After Code
```dart
// mobile/lib/features/shuffle/data/datasources/fortuna_random_wrapper.dart (new)
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:pointycastle/api.dart' as pc;

class FortunaRandomWrapper implements Random {
  FortunaRandomWrapper(Uint8List seed) {
    _fortuna = FortunaRandom()
      ..seed(pc.KeyParameter(seed));
  }

  late final FortunaRandom _fortuna;

  @override
  int nextInt(int max) {
    if (max <= 0) throw ArgumentError('max must be positive');
    // FortunaRandom.nextUint32()는 0 ~ 2^32-1 범위
    // max 미만의 균등 분포를 위해 rejection sampling
    final limit = (0x100000000 ~/ max) * max;
    int value;
    do {
      value = _fortuna.nextUint32();
    } while (value >= limit);
    return value % max;
  }

  @override
  double nextDouble() {
    return _fortuna.nextUint32() / 0x100000000;
  }

  @override
  bool nextBool() {
    return _fortuna.nextUint32().isOdd;
  }
}
```

### Considerations
- **Rejection sampling**: `nextInt(max)`에서 modulo bias 방지. `limit`로 균등 분포 보장
- Dart의 `List.shuffle(random)` 내부적으로 Fisher-Yates 사용 → 이 래퍼만 있으면 됨
- FortunaRandom은 시드 주입 후 결정론적 → 같은 시드 = 같은 셔플 결과 (테스트 용이)

---

## Step 4 — ShuffleResult & ShuffleConfig

### After Code — ShuffleConfig
```dart
// mobile/lib/features/shuffle/domain/entities/shuffle_config.dart (new)
import 'package:freezed_annotation/freezed_annotation.dart';

part 'shuffle_config.freezed.dart';
part 'shuffle_config.g.dart';

@freezed
class ShuffleConfig with _$ShuffleConfig {
  const factory ShuffleConfig({
    @Default(3) int shuffleCount,     // 리플 반복 횟수 (3-7)
    @Default(true) bool useReversals, // 역방향 카드 허용
    @Default(0.5) double reversalProbability, // 역방향 확률
  }) = _ShuffleConfig;

  factory ShuffleConfig.fromJson(Map<String, dynamic> json) =>
      _$ShuffleConfigFromJson(json);
}
```

### After Code — ShuffleResult
```dart
// mobile/lib/features/shuffle/domain/entities/shuffle_result.dart (new)
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../deck/domain/entities/tarot_card.dart';

part 'shuffle_result.freezed.dart';
part 'shuffle_result.g.dart';

@freezed
class ShuffleResult with _$ShuffleResult {
  const factory ShuffleResult({
    required List<ShuffledCard> cards,
    required int entropyBits,       // 사용된 엔트로피 비트 수
    required bool usedSensorEntropy, // 센서 엔트로피 사용 여부
    required DateTime shuffledAt,
  }) = _ShuffleResult;

  factory ShuffleResult.fromJson(Map<String, dynamic> json) =>
      _$ShuffleResultFromJson(json);
}

@freezed
class ShuffledCard with _$ShuffledCard {
  const factory ShuffledCard({
    required TarotCard card,
    required bool isReversed,
  }) = _ShuffledCard;

  factory ShuffledCard.fromJson(Map<String, dynamic> json) =>
      _$ShuffledCardFromJson(json);
}
```

---

## Step 5 — ShuffleStrategy 인터페이스

### Approach
Strategy 패턴으로 셔플 알고리즘을 런타임 교체 가능하게 설계. MVP는 RiffleShuffleStrategy만 구현하지만, 인터페이스를 미리 정의하여 Phase 2+(오버핸드, 워시) 확장 대비.

### After Code
```dart
// mobile/lib/features/shuffle/domain/strategies/shuffle_strategy.dart (new)
import 'dart:math';
import '../entities/shuffle_config.dart';
import '../entities/shuffle_result.dart';
import '../../../deck/domain/entities/tarot_card.dart';

/// 셔플 전략 인터페이스
///
/// 각 구현체는 셔플 알고리즘과 애니메이션 설정을 캡슐화.
/// Phase 3의 CardPainter가 animationConfig를 읽어 렌더링에 반영.
abstract class ShuffleStrategy {
  String get name;
  String get displayName;

  /// 카드 목록을 셔플하여 결과 반환
  ShuffleResult shuffle({
    required List<TarotCard> cards,
    required Random random,
    required ShuffleConfig config,
  });
}
```

### Considerations
- `Random` 인터페이스로 받으므로 FortunaRandomWrapper든 테스트용 시드 고정 Random이든 주입 가능
- `name`/`displayName`: UI에서 셔플 타입 표시용
- 애니메이션 config는 Phase 3에서 추가 (현재 인터페이스는 로직에만 집중)

---

## Step 6 — RiffleShuffleStrategy

### Approach
전통적인 리플 셔플 시뮬레이션: 덱을 반으로 나누고 양 손의 카드를 교차 삽입. 이를 `shuffleCount`회 반복. 내부적으로 `List.shuffle(random)`(Fisher-Yates)을 사용하되, 리플 특유의 "반 나누기 → 인터리빙" 패턴을 시뮬레이션.

### After Code
```dart
// mobile/lib/features/shuffle/domain/strategies/riffle_shuffle_strategy.dart (new)
import 'dart:math';
import '../entities/shuffle_config.dart';
import '../entities/shuffle_result.dart';
import '../../../deck/domain/entities/tarot_card.dart';
import 'shuffle_strategy.dart';

class RiffleShuffleStrategy implements ShuffleStrategy {
  @override
  String get name => 'riffle';

  @override
  String get displayName => '리플 셔플';

  @override
  ShuffleResult shuffle({
    required List<TarotCard> cards,
    required Random random,
    required ShuffleConfig config,
  }) {
    var deck = List<TarotCard>.from(cards);

    // 리플 셔플 N회 반복
    for (var i = 0; i < config.shuffleCount; i++) {
      deck = _riffleOnce(deck, random);
    }

    // 역방향(reversed) 결정
    final shuffledCards = deck.map((card) {
      final isReversed = config.useReversals &&
          random.nextDouble() < config.reversalProbability;
      return ShuffledCard(card: card, isReversed: isReversed);
    }).toList();

    return ShuffleResult(
      cards: shuffledCards,
      entropyBits: 256,
      usedSensorEntropy: true,
      shuffledAt: DateTime.now(),
    );
  }

  /// 단일 리플 셔플: 덱을 반으로 나누고 인터리빙
  List<TarotCard> _riffleOnce(List<TarotCard> deck, Random random) {
    // 컷 포인트: 중앙 ± 랜덤 오프셋 (실제 리플의 비정확성 시뮬레이션)
    final mid = deck.length ~/ 2;
    final offset = random.nextInt(5) - 2; // -2 ~ +2
    final cutPoint = (mid + offset).clamp(1, deck.length - 1);

    final leftHalf = deck.sublist(0, cutPoint);
    final rightHalf = deck.sublist(cutPoint);

    // 인터리빙: 양쪽에서 1-3장씩 번갈아 떨어뜨리기
    final result = <TarotCard>[];
    var leftIdx = 0;
    var rightIdx = 0;

    while (leftIdx < leftHalf.length || rightIdx < rightHalf.length) {
      // 왼손에서 1-3장
      final leftDrop = random.nextInt(3) + 1;
      for (var j = 0; j < leftDrop && leftIdx < leftHalf.length; j++) {
        result.add(leftHalf[leftIdx++]);
      }
      // 오른손에서 1-3장
      final rightDrop = random.nextInt(3) + 1;
      for (var j = 0; j < rightDrop && rightIdx < rightHalf.length; j++) {
        result.add(rightHalf[rightIdx++]);
      }
    }

    return result;
  }
}
```

### Considerations
- 순수 Fisher-Yates가 아닌 리플 시뮬레이션: 실제 카드 셔플의 물리적 특성 반영
- `cutPoint` 랜덤 오프셋: 사람이 덱을 정확히 반으로 나누지 않는 것을 모사
- 1-3장씩 떨어뜨리기: 실제 리플에서 한 번에 여러 장이 떨어지는 것을 모사
- `shuffleCount` 3-7회: Gilbert-Shannon-Reeds 모델에서 7회면 충분히 무작위

---

## Step 7 — ShuffleDeckUseCase

### Approach
센서 수집 → 엔트로피 풀 → CSPRNG → 셔플 전략의 전체 파이프라인을 조율. Clean Architecture의 UseCase 패턴.

### After Code
```dart
// mobile/lib/features/shuffle/domain/usecases/shuffle_deck_usecase.dart (new)
import '../entities/shuffle_config.dart';
import '../entities/shuffle_result.dart';
import '../strategies/shuffle_strategy.dart';
import '../../../deck/domain/entities/tarot_card.dart';
import '../../data/datasources/entropy_pool.dart';
import '../../data/datasources/fortuna_random_wrapper.dart';
import '../../data/datasources/sensor_data_collector.dart';

class ShuffleDeckUseCase {
  ShuffleDeckUseCase({
    required this.sensorCollector,
    required this.entropyPool,
  });

  final SensorDataCollector sensorCollector;
  final EntropyPool entropyPool;

  /// 센서 엔트로피로 셔플 실행
  ShuffleResult execute({
    required List<TarotCard> cards,
    required ShuffleStrategy strategy,
    ShuffleConfig config = const ShuffleConfig(),
  }) {
    // 1. 센서 샘플을 엔트로피 풀에 투입
    entropyPool.addSamples(sensorCollector.samples);

    // 2. 시드 생성 (센서 가용 여부에 따라 분기)
    final seed = sensorCollector.sensorsAvailable && entropyPool.isReady
        ? entropyPool.generateSeed()
        : entropyPool.generateFallbackSeed();

    // 3. FortunaRandom 생성
    final random = FortunaRandomWrapper(seed);

    // 4. 셔플 전략 실행
    final result = strategy.shuffle(
      cards: cards,
      random: random,
      config: config,
    );

    // 5. 엔트로피 풀 리셋 (다음 셔플 위해)
    entropyPool.reset();

    return result.copyWith(
      usedSensorEntropy: sensorCollector.sensorsAvailable && entropyPool.isReady,
    );
  }
}
```

### Considerations
- UseCase는 상태 비보유 (stateless) — SensorDataCollector와 EntropyPool은 외부에서 주입
- 센서 폴백: 센서 미지원 시 `generateFallbackSeed()` → UX에서 알림 (Phase 3)
- 셔플 후 `entropyPool.reset()` → 다음 셔플 시 새로운 엔트로피 축적 필요

---

## Step 8 — Repository 인터페이스 + 구현

### Approach
Clean Architecture: 도메인 레이어에 인터페이스 정의, 데이터 레이어에서 Drift DAO를 사용한 구현.

### After Code — ShuffleRepository (인터페이스)
```dart
// mobile/lib/features/shuffle/domain/repositories/shuffle_repository.dart (new)
import '../entities/shuffle_result.dart';

abstract class ShuffleRepository {
  /// 최근 셔플 결과 저장 (현재 세션)
  void cacheLastResult(ShuffleResult result);

  /// 최근 셔플 결과 조회
  ShuffleResult? getLastResult();
}
```

### After Code — ShuffleRepositoryImpl
```dart
// mobile/lib/features/shuffle/data/repositories/shuffle_repository_impl.dart (new)
import '../../domain/entities/shuffle_result.dart';
import '../../domain/repositories/shuffle_repository.dart';

class ShuffleRepositoryImpl implements ShuffleRepository {
  ShuffleResult? _lastResult;

  @override
  void cacheLastResult(ShuffleResult result) {
    _lastResult = result;
  }

  @override
  ShuffleResult? getLastResult() => _lastResult;
}
```

### After Code — DeckRepository (인터페이스)
```dart
// mobile/lib/features/deck/domain/repositories/deck_repository.dart (new)
import '../entities/deck_metadata.dart';
import '../entities/tarot_card.dart';

abstract class DeckRepository {
  Future<List<DeckMetadata>> getAllDecks();
  Stream<List<DeckMetadata>> watchAllDecks();
  Future<DeckMetadata?> getDeckById(String id);
  Future<List<TarotCard>> getCardsByDeckId(String deckId);
  Future<void> seedRwsDeck();
  Future<bool> hasAnyDecks();
}
```

### After Code — DeckRepositoryImpl
```dart
// mobile/lib/features/deck/data/repositories/deck_repository_impl.dart (new)
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/decks_table.dart' show SyncStatus;
import '../../domain/entities/card_meanings.dart';
import '../../domain/entities/deck_metadata.dart';
import '../../domain/entities/tarot_card.dart';
import '../../domain/repositories/deck_repository.dart';

class DeckRepositoryImpl implements DeckRepository {
  DeckRepositoryImpl({required this.db});

  final AppDatabase db;

  @override
  Future<List<DeckMetadata>> getAllDecks() async {
    final rows = await db.deckDao.getAllDecks();
    return rows.map(_toDeckMetadata).toList();
  }

  @override
  Stream<List<DeckMetadata>> watchAllDecks() {
    return db.deckDao.watchAllDecks().map(
      (rows) => rows.map(_toDeckMetadata).toList(),
    );
  }

  @override
  Future<DeckMetadata?> getDeckById(String id) async {
    final row = await db.deckDao.getDeckById(id);
    return row != null ? _toDeckMetadata(row) : null;
  }

  @override
  Future<List<TarotCard>> getCardsByDeckId(String deckId) async {
    final rows = await db.cardDao.getCardsByDeckId(deckId);
    return rows.map(_toTarotCard).toList();
  }

  @override
  Future<bool> hasAnyDecks() async {
    final decks = await db.deckDao.getAllDecks();
    return decks.isNotEmpty;
  }

  @override
  Future<void> seedRwsDeck() async {
    final hasDecks = await hasAnyDecks();
    if (hasDecks) return;

    final jsonStr = await rootBundle.loadString('assets/data/rws_deck.json');
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final deckData = data['deck'] as Map<String, dynamic>;
    final cardsData = data['cards'] as List;

    final now = DateTime.now();
    final deckCompanion = DecksCompanion.insert(
      id: deckData['id'] as String,
      name: deckData['name'] as String,
      isStandardTarot: Value(deckData['isStandardTarot'] as bool),
      totalCards: deckData['totalCards'] as int,
      creator: Value(deckData['creator'] as String?),
      createdAt: now,
      updatedAt: now,
    );

    final cardCompanions = cardsData.map((c) {
      final card = c as Map<String, dynamic>;
      return CardsCompanion.insert(
        id: '${deckData['id']}-${card['cardId']}',
        deckId: deckData['id'] as String,
        cardId: card['cardId'] as String,
        name: card['name'] as String,
        arcana: card['arcana'] as String,
        suit: Value(card['suit'] as String?),
        number: card['number'] as int,
        imagePath: card['imagePath'] as String,
        meanings: CardMeanings.fromJson(card['meanings'] as Map<String, dynamic>),
        createdAt: now,
        updatedAt: now,
      );
    }).toList();

    await db.deckDao.insertDeckWithCards(deckCompanion, cardCompanions);
  }

  DeckMetadata _toDeckMetadata(Deck row) => DeckMetadata(
        id: row.id,
        name: row.name,
        isStandardTarot: row.isStandardTarot,
        totalCards: row.totalCards,
        creator: row.creator,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  TarotCard _toTarotCard(Card row) => TarotCard(
        id: row.id,
        deckId: row.deckId,
        cardId: row.cardId,
        name: row.name,
        arcana: row.arcana,
        suit: row.suit,
        number: row.number,
        imagePath: row.imagePath,
        meanings: row.meanings,
      );
}
```

### After Code — ReadingRepository (인터페이스)
```dart
// mobile/lib/features/reading/domain/repositories/reading_repository.dart (new)
import '../entities/reading.dart';
import '../entities/spread_type.dart';

abstract class ReadingRepository {
  Future<List<Reading>> getAllReadings();
  Stream<List<Reading>> watchAllReadings();
  Future<void> saveReading(Reading reading);
  Future<void> deleteReading(String id);
}
```

### After Code — ReadingRepositoryImpl
```dart
// mobile/lib/features/reading/data/repositories/reading_repository_impl.dart (new)
import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/reading.dart' as domain;
import '../../domain/entities/spread_type.dart';
import '../../domain/repositories/reading_repository.dart';

class ReadingRepositoryImpl implements ReadingRepository {
  ReadingRepositoryImpl({required this.db});

  final AppDatabase db;

  @override
  Future<List<domain.Reading>> getAllReadings() async {
    final readings = await db.readingDao.getAllReadings();
    return Future.wait(readings.map(_toDomainReading));
  }

  @override
  Stream<List<domain.Reading>> watchAllReadings() {
    return db.readingDao.watchAllReadings().asyncMap(
      (readings) => Future.wait(readings.map(_toDomainReading)),
    );
  }

  @override
  Future<void> saveReading(domain.Reading reading) async {
    final readingCompanion = ReadingsCompanion.insert(
      id: reading.id,
      deckId: reading.deckId,
      spreadType: reading.spreadType.name,
      question: Value(reading.question),
      notes: Value(reading.notes),
      createdAt: reading.createdAt,
      updatedAt: reading.createdAt,
    );

    final drawnCardCompanions = reading.drawnCards.map((dc) {
      return DrawnCardsCompanion.insert(
        id: '${reading.id}-${dc.position}',
        readingId: reading.id,
        cardId: dc.cardId,
        position: dc.position,
        isReversed: dc.isReversed,
        createdAt: reading.createdAt,
      );
    }).toList();

    await db.readingDao.insertReading(readingCompanion, drawnCardCompanions);
  }

  @override
  Future<void> deleteReading(String id) async {
    await db.readingDao.deleteReading(id);
  }

  Future<domain.Reading> _toDomainReading(Reading row) async {
    final drawnCards = await db.readingDao.getDrawnCardsForReading(row.id);
    return domain.Reading(
      id: row.id,
      deckId: row.deckId,
      spreadType: SpreadType.values.byName(row.spreadType),
      question: row.question,
      notes: row.notes,
      drawnCards: drawnCards
          .map((dc) => domain.DrawnCardInfo(
                cardId: dc.cardId,
                position: dc.position,
                isReversed: dc.isReversed,
              ))
          .toList(),
      createdAt: row.createdAt,
    );
  }
}
```

---

## Step 9 — HapticService

### Approach
Flutter 내장 HapticFeedback을 래핑. 50ms 쓰로틀링으로 워시 셔플(Phase 2+) 대비. MVP에서는 셔플 완료/카드 뒤집기 시 사용.

### After Code
```dart
// mobile/lib/features/shuffle/data/services/haptic_service.dart (new)
import 'package:flutter/services.dart';

class HapticService {
  DateTime _lastHaptic = DateTime.fromMillisecondsSinceEpoch(0);
  static const _throttleDuration = Duration(milliseconds: 50);

  /// 카드 교차 틱 (경량)
  void selectionClick() => _throttled(HapticFeedback.selectionClick);

  /// 카드 접촉 (경량 임팩트)
  void lightImpact() => _throttled(HapticFeedback.lightImpact);

  /// 셔플 완료 (중간 임팩트)
  void mediumImpact() => _throttled(HapticFeedback.mediumImpact);

  void _throttled(Future<void> Function() action) {
    final now = DateTime.now();
    if (now.difference(_lastHaptic) >= _throttleDuration) {
      _lastHaptic = now;
      action();
    }
  }
}
```

---

## Considerations & Trade-offs

### Alternative Approaches
| Approach | 불채택 이유 |
|----------|-----------|
| Random.secure() 직접 사용 | 외부 시드 주입 불가 → 센서 엔트로피 반영 불가 |
| Fisher-Yates 직접 구현 | Dart List.shuffle()이 이미 Fisher-Yates. Random 인터페이스 래퍼면 충분 |
| BLoC으로 셔플 상태 관리 | 셔플 로직은 순수 함수. 상태 관리 불필요. Riverpod Provider로 결과만 캐시 |

### Potential Risks
| Risk | Mitigation |
|------|-----------|
| PointyCastle FortunaRandom API 변경 | 버전 ^3.7.0 고정, FortunaRandomWrapper로 격리 |
| 센서 샘플링 레이트 비보장 (Android) | minSamples=10으로 최소 보장, 부족 시 폴백 |
| TypeConverter 순환 의존 | card_meanings.dart는 features/ 도메인에, converter는 core/에 위치. import 방향 단방향 |

### Backward Compatibility
- Phase 1의 DB 스키마/모델에 의존하지만 수정 없음
- 모든 파일이 신규 생성

## Implementation Checklist

- [ ] Step 1: SensorDataCollector (센서 수집기)
- [ ] Step 2: EntropyPool (SHA-256 엔트로피 풀)
- [ ] Step 3: FortunaRandomWrapper (CSPRNG 어댑터)
- [ ] Step 4: ShuffleResult, ShuffleConfig (freezed 모델)
- [ ] Step 5: ShuffleStrategy (인터페이스)
- [ ] Step 6: RiffleShuffleStrategy (리플 셔플 구현)
- [ ] Step 7: ShuffleDeckUseCase (유스케이스)
- [ ] Step 8: Repository 계층 (Deck, Shuffle, Reading — 인터페이스 + 구현)
- [ ] Step 9: HapticService (햅틱 래퍼)
- [ ] build_runner 코드 생성 확인
- [ ] Final verification

## Verification Assertions

| Level | Assertion | Verification Method | Expected Result |
|-------|-----------|-------------------|-----------------|
| L1-Build | build_runner 성공 | `dart run build_runner build` | ShuffleResult, ShuffleConfig 생성 |
| L1-Build | flutter analyze 통과 | `flutter analyze` | 에러 0 |
| L2-CLI | 리플 셔플 결정론성 | 유닛 테스트: 시드 고정 → 동일 결과 | 2회 실행 결과 동일 |
| L2-CLI | 엔트로피 풀 최소 샘플 | 유닛 테스트: 9샘플 → isReady=false, 10 → true | threshold 동작 |
| L2-CLI | FortunaRandom 균등 분포 | 유닛 테스트: nextInt(78) 10만회 → chi-squared | p > 0.01 |
| L2-CLI | RWS 시드 데이터 로드 | 유닛 테스트: seedRwsDeck() → 78장 확인 | 78 cards in DB |
| L4-Trace | R-008-F3 FortunaRandom | 코드 검증 | PointyCastle FortunaRandom 사용 확인 |
| L4-Trace | R-008-F7 센서 편향 방지 | 코드 검증 | SHA-256 + Random.secure() 혼합 확인 |
| L4-Trace | R-008-F8 햅틱 쓰로틀링 | 코드 검증 | 50ms throttle 확인 |

## References

| Resource | Path/URL | Related Content |
|----------|---------|-----------------|
| Research | docs/11_tarot_shuffle/008_Research_tarot_shuffle_tech.md | 엔트로피 모델, 셔플 엔진 |
| Sensor Agent | docs/11_tarot_shuffle/004_Agent_sensor_rng.md | sensors_plus, FortunaRandom 상세 |
| Shuffle Agent | docs/11_tarot_shuffle/003_Agent_shuffle_engine.md | 리플 셔플 구현 패턴 |
| Checkpoint | docs/11_tarot_shuffle/009_Plan_flutter_mvp_checkpoint.md | 플랜 마스터 |
