---
id: "051"
title: "엔트로피 수집·추정·품질 보장 조사"
category: agent
status: archived
created: 2026-03-17
summary: >
  NIST SP 800-90B/90C 관점에서 현재 모바일 센서 엔트로피 파이프라인을 평가한 결과,
  구조적으로 NIST 권고(Entropy Source → Conditioning → DRBG)에 부합하나,
  5가지 핵심 약점(gyroZ=0 엔트로피 붕괴, 건강 테스트 부재, 최소 샘플 수 부족,
  엔트로피 추정 없음, 풀 미재설정)이 식별되었다. 학술 연구에 따르면 정지 상태
  가속도계의 min-entropy는 샘플당 ~1.5-2.9비트이며, gyroZ=0일 때 곱셈 기반
  기여도 공식은 엔트로피를 0으로 만든다. 6가지 구체적 개선 권장사항을 제시한다.
keywords: [agent-report, entropy, NIST-SP-800-90B, NIST-SP-800-90C, min-entropy, sensor, accelerometer, gyroscope, health-test, conditioning]
modules: [mobile/lib/features/shuffle/data/datasources]
---

# 엔트로피 수집·추정·품질 보장 조사

## Progress
### Completed
- [x] NIST SP 800-90B 엔트로피 추정 방법 조사
- [x] NIST SP 800-90C 구조 권고 조사
- [x] 모바일 센서 엔트로피 논문 조사
- [x] 현재 구현(entropy_pool.dart, sensor_data_collector.dart) 분석
- [x] 엔트로피 추정 경량 알고리즘 조사
- [x] 최종 결론 및 권장 사항
### Remaining
(없음)
### Current Status
조사 완료.

---

## Summary

현재 구현의 센서 엔트로피 → SHA-256 믹싱 → Fortuna DRBG 파이프라인은 NIST SP 800-90C의 RBG2 구조(내부 엔트로피 소스 + 조건화 + DRBG)와 구조적으로 일치한다. 그러나 NIST SP 800-90B의 건강 테스트가 없고, 센서 기여도 공식(`accelMagnitude * gyroZ`)이 gyroZ 근사 0일 때 엔트로피를 사실상 소멸시키는 치명적 약점이 있다. 학술 연구(Shepherd et al. 2025)는 모바일 센서의 약 60% 자이로스코프 판독값이 0 근처에 집중되어 있음을 보고하며, 이 경우 센서 엔트로피 기여가 거의 없게 된다.

다행히 `generateSeed()`가 `Random.secure()` 32바이트를 항상 혼합하므로 OS CSPRNG이 안전망 역할을 하지만, 센서 엔트로피가 "추가 보안 레이어"라는 설계 의도를 달성하지 못하는 상황이 빈번할 수 있다.

---

## Details

### 1. NIST SP 800-90B: 엔트로피 소스 검증 표준

#### 1.1 Min-Entropy 정의

Min-entropy는 가장 보수적인 엔트로피 측정 지표로, 가장 가능성 높은 출력값의 확률에 기반한다:

```
H∞ = -log₂(max_x P(X = x))
```

Shannon 엔트로피가 평균적 불확실성을 측정하는 반면, min-entropy는 최악의 경우(가장 예측하기 쉬운 출력)를 측정한다. 암호학적 응용에서는 min-entropy가 표준이다.

**출처**: NIST SP 800-90B Section 3.1 ([NIST](https://csrc.nist.gov/pubs/sp/800/90/b/final))

#### 1.2 IID vs Non-IID 트랙

SP 800-90B는 두 가지 평가 경로를 정의한다:

| 트랙 | 적용 조건 | 추정 방법 |
|------|----------|----------|
| **IID** | 출력이 독립적이고 동일 분포 | Most Common Value만 사용 |
| **Non-IID** | 출력 간 의존성 존재 | 10개 추정기 모두 사용, 최솟값 채택 |

**센서 데이터는 Non-IID**: 가속도계/자이로스코프 데이터는 시간 상관관계(temporal correlation)가 있어 반드시 Non-IID 트랙을 적용해야 한다.

#### 1.3 10개 엔트로피 추정 방법

| # | 추정기 | 원리 | 장점 | 단점 |
|---|--------|------|------|------|
| 1 | **Most Common Value (MCV)** | 가장 빈번한 심볼의 확률로 추정 | 단순, 빠름 | 상관관계 무시 |
| 2 | **Collision** | 연속 동일값 간 거리 측정 | 의존성 일부 포착 | 바이너리 소스에만 적용 |
| 3 | **Markov** | 상태 전이 확률로 추정 | 1차 의존성 모델링 | 바이너리 소스에만 적용, 고차 의존성 무시 |
| 4 | **Compression** | 압축률을 엔트로피 프록시로 사용 | 복잡한 패턴 탐지 | 계산 비용 높음 |
| 5 | **t-Tuple** | 길이 t 블록의 빈도 분포 분석 | 다중 심볼 소스 지원 | t 선택에 민감 |
| 6 | **LRS (Longest Repeated Substring)** | 최장 반복 패턴 길이 기반 | 장거리 패턴 탐지 | 샘플 수 많이 필요 |
| 7 | **MultiMCW** | 다양한 윈도우 크기에서 다중 연속 동일값 분석 | 다층적 분석 | 계산 비용 |
| 8 | **Lag** | 특정 간격의 자기상관 패턴 분석 | 주기성 탐지 | 래그 범위 제한 |
| 9 | **MultiMMC** | 다중 상태 전이에 걸친 Markov 확장 | 고차 의존성 포착 | 복잡도 높음 |
| 10 | **LZ78Y** | Lempel-Ziv 변형, 사전 구축 중 고유 패턴 수 | 압축 기반 실용적 | 짧은 시퀀스에 부정확 |

**핵심 원칙**: Non-IID 소스에서는 10개 추정기 모두를 실행하고, **최솟값을 보수적 min-entropy 추정치로 채택**한다.

**출처**: NIST SP 800-90B Section 6 ([NIST PDF](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-90B.pdf))

#### 1.4 건강 테스트 (Health Tests)

SP 800-90B는 두 가지 필수 연속 건강 테스트를 정의한다:

##### 반복 카운트 테스트 (Repetition Count Test, RCT)

- **목적**: 노이즈 소스가 단일 값에 고착되는 치명적 실패 탐지
- **동작**: 동일 값이 연속으로 C회 이상 나타나면 실패
- **임계값 공식**: `C = 1 + ⌈-log₂(α) / H⌉`
  - H = 샘플당 min-entropy (비트)
  - α = 허용 위양성률 (보통 2⁻²⁰)
  - 예: H=2 비트, α=2⁻²⁰ → C = 1 + ⌈20/2⌉ = 11
- **실시간 적용**: 모든 샘플에 대해 연속적으로 실행

##### 적응 비율 테스트 (Adaptive Proportion Test, APT)

- **목적**: 엔트로피의 대규모 손실 탐지 (물리적 실패, 환경 변화)
- **동작**: 윈도우 W 내에서 특정 값의 출현 빈도가 임계값 C를 초과하면 실패
- **윈도우 크기**: W = 1024 (바이너리 소스), W = 512 (비바이너리 소스)
- **임계값**: H와 α로부터 이항분포 기반 계산
- **실시간 적용**: 슬라이딩 윈도우로 연속 실행

##### 테스트 시점

| 시점 | 설명 |
|------|------|
| **시작 시** | 전원 투입 후 첫 사용 전 |
| **연속** | 정상 동작 중 무한히 |
| **요청 시** | 언제든 호출 가능 |

**센서 엔트로피에의 적용 가능성**: RCT와 APT 모두 센서 샘플 스트림에 직접 적용 가능하다. 양자화된 센서 값(예: float64를 8비트 버킷으로 양자화)에 대해 실행하면, 정지 상태에서 센서가 동일값을 반복 출력하는 상황을 탐지할 수 있다.

**출처**: NIST SP 800-90B Section 4.4 ([NIST PDF](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-90B.pdf)), [Lightship Security](https://lightshipsec.com/nist-800-90b-concepts/)

---

### 2. NIST SP 800-90C: 난수 생성 구조 권고

#### 2.1 RBG 구성 클래스

SP 800-90C (2025년 9월 최종 발간)는 4가지 RBG 구성을 정의한다:

| 클래스 | 설명 | 엔트로피 소스 | 재시딩 |
|--------|------|-------------|--------|
| **RBG1** | 외부 엔트로피로 1회 시딩 | 외부 | 없음 |
| **RBG2** | 내부 온디맨드 엔트로피 소스 | 내부, 요청 시 | 온디맨드 |
| **RBG3** | 전체 엔트로피 출력 보장 | 내부, 연속적 | 매 출력마다 |
| **RBGC** | 동일 플랫폼 내 RBG 체이닝 | 체이닝 | 체이닝 |

#### 2.2 표준 파이프라인 구조

```
Entropy Source → [Conditioning Component] → DRBG Mechanism → Output
     (SP 800-90B)                              (SP 800-90A)
```

- **Entropy Source**: 물리적 노이즈 소스 + 건강 테스트 (90B 준수)
- **Conditioning**: 바이어스 제거, 엔트로피 집중. 승인된 조건화 함수: SHA 해시, HMAC, CMAC
- **DRBG**: 시드로부터 결정론적 확장. 승인된 메커니즘: CTR_DRBG(AES), Hash_DRBG(SHA), HMAC_DRBG

#### 2.3 현재 구현과의 매핑

```
현재 구현                          NIST SP 800-90C 매핑
─────────────────────────────────────────────────────────
센서(가속도계+자이로)         →  Entropy Source (비승인)
Random.secure() 32바이트      →  Entropy Source (OS CSPRNG, 승인 가능)
SHA-256 믹싱                  →  Conditioning Component (승인 해시)
Fortuna CSPRNG                →  DRBG Mechanism (비승인*)
```

*Fortuna는 NIST 승인 DRBG(CTR_DRBG, Hash_DRBG, HMAC_DRBG)에 포함되지 않으나, AES-256 블록 암호 기반이며 학술적으로 검증됨 (Schneier & Ferguson 2003).

**구조적 평가**: 현재 파이프라인은 **RBG2 구조와 가장 유사**하다. 엔트로피 소스(센서+OS)가 내부에 존재하고, 조건화(SHA-256)를 거쳐 DRBG(Fortuna)에 시딩된다. 구조적 골격은 NIST 권고에 부합하나, 개별 컴포넌트의 NIST 승인 여부와 건강 테스트 부재가 차이점이다.

**출처**: [NIST SP 800-90C](https://csrc.nist.gov/pubs/sp/800/90/c/final), [SafeLogic SP 800-90 Series Overview](https://www.safelogic.com/blog/introduction-to-the-sp-800-90-series-requirements-on-random-number-generation)

---

### 3. 모바일 센서 엔트로피 관련 학술 연구

#### 3.1 센서별 엔트로피 측정 결과

##### Shepherd et al. (2025) — "Entropy Collapse in Mobile Sensors"

25개 센서 모달리티를 4개 데이터셋에서 분석한 대규모 연구:

| 센서 | Min-Entropy (비트) | Shannon Entropy (비트) | 비고 |
|------|-------------------|----------------------|------|
| 가속도계 각 축 | 2.889 — 6.020 | 훨씬 높음 | 축별 편차 큼 |
| 자이로스코프 각 축 | 1.929 — 4.993 | 훨씬 높음 | **~60% 판독값이 0 근처** |
| 자기장 각 축 | 4.254 — 7.148 | 훨씬 높음 | 가장 높은 min-entropy |
| 조도 센서 | 3.206 — 4.552 | — | 환경 의존적 |

**핵심 발견**:
- 단일 센서 평균 min-entropy: 3.408 — 4.483 비트 (데이터셋별)
- **다중 센서 조합의 한계**: 20개 모달리티 전체 결합해도 ~24비트 min-entropy
- 센서 간 상관관계로 인해 min-entropy 증가가 Shannon 엔트로피 대비 **40-75% 감소**
- **결론**: "보안 핵심 애플리케이션의 비예측성 소스로 상용 센서 의존을 권장하지 않음"

**출처**: [arXiv 2502.09535](https://arxiv.org/abs/2502.09535)

##### Li et al. (2020) — "Analysis on Entropy Sources based on Smartphone Sensors"

50Hz 샘플링 조건에서의 보수적 엔트로피 추정:

| 조건 | 가속도계 | 자이로스코프 | 자기장 |
|------|---------|------------|--------|
| **정지 상태** | ~189 bits/s (~3.8 bits/sample) | ~13 bits/s (~0.26 bits/sample) | ~254 bits/s |
| **이동 상태** | ~367 bits/s | 더 높음 | 더 높음 |

- Android 정지 상태: 가속도계 샘플당 최소 1.5비트
- Android 이동 상태: 가속도계 샘플당 최소 1.9비트
- iOS 자이로스코프: 샘플당 최소 27비트 (플랫폼별 큰 차이)

**출처**: [ACM ICCNS 2020](https://dl.acm.org/doi/10.1145/3442520.3442528)

##### SensoRNG (Sarkisyan et al. 2016, IEEE IoT Journal)

센서 기반 RNG 프레임워크 평가:
- 마이크, 자이로스코프, 가속도계를 가장 유망한 센서로 선정
- NIST SP 800-22 통계 테스트 스위트의 거의 모든 테스트 통과
- 센서 해상도와 샘플링 레이트가 엔트로피에 직접 영향

**출처**: [IEEE Xplore](https://ieeexplore.ieee.org/document/7477997/)

#### 3.2 환경 조건별 엔트로피 가변성

| 상태 | 가속도계 엔트로피 | 자이로스코프 엔트로피 | 특이사항 |
|------|-----------------|-------------------|---------|
| **정지 (탁자 위)** | ~1.5 bits/sample | **~0.26 bits/sample** | 자이로 대부분 0 근처 |
| **손에 들고 있음** | ~1.9 bits/sample | ~1-3 bits/sample | 미세 떨림으로 증가 |
| **적극적으로 흔듦** | ~3-6 bits/sample | ~3-5 bits/sample | 최대 엔트로피 |

**중요**: 자이로스코프는 정지 상태에서 엔트로피가 극적으로 낮아진다. 약 60%의 자이로스코프 판독값이 0 근처에 집중되어 있다 (Shepherd et al. 2025).

#### 3.3 터치스크린 이벤트 기반 엔트로피 (대안/보완)

터치 이벤트에서 추출 가능한 엔트로피 소스:

| 소스 | 엔트로피 기여 | 비고 |
|------|-------------|------|
| 터치 좌표 (x, y) | 중간 | 화면 크기, 터치 영역 제한 |
| 터치 간 시간 간격 | 높음 | 마이크로초 단위 불확실성 |
| 터치 압력/크기 | 낮음-중간 | 장치 의존적 |
| 스와이프 궤적 | 높음 | 연속적 좌표 시퀀스 |

타로 앱의 셔플 제스처는 이미 사용자 터치 상호작용을 포함하므로, 터치 타이밍 + 좌표를 추가 엔트로피 소스로 활용할 수 있다.

**출처**: [IACR ePrint 2011/359](https://eprint.iacr.org/2011/359.pdf)

---

### 4. 현재 구현 분석

#### 4.1 `entropy_pool.dart` 분석

**파일**: `mobile/lib/features/shuffle/data/datasources/entropy_pool.dart`

##### SHA-256 믹싱 (`_accumulate`)

```dart
final combined = Uint8List(16);
for (var i = 0; i < 8; i++) {
  combined[i] = contributionBytes.getUint8(i) ^ timestampBytes.getUint8(i);
  combined[i + 8] = contributionBytes.getUint8(i);
}
final digest = sha256.convert([..._pool, ...combined]);
_pool = Uint8List.fromList(digest.bytes);
```

**평가**:
- (+) SHA-256은 NIST 승인 조건화 함수. 편향 제거와 엔트로피 집중에 적합
- (+) 누적 해싱: 각 샘플이 이전 풀 상태와 혼합되어 엔트로피가 축적만 됨 (감소 불가)
- (-) XOR 결합 `contributionBytes ^ timestampBytes`는 한쪽이 0이면 다른 쪽이 그대로 노출됨
- (-) `combined[i + 8] = contributionBytes.getUint8(i)` — XOR 전 원본도 포함하므로 이 자체는 문제 없음

##### `generateSeed()` 평가

```dart
Uint8List generateSeed() {
  final systemRandom = Random.secure();
  final systemBytes = Uint8List(32); // 256비트 OS CSPRNG
  // ...
  final finalDigest = sha256.convert([..._pool, ...systemBytes]);
  return Uint8List.fromList(finalDigest.bytes);
}
```

**평가**:
- (+) `Random.secure()` 32바이트(256비트)가 항상 포함 → 센서 실패 시에도 최소 256비트 엔트로피 보장
- (+) SHA-256으로 최종 혼합 → 풀이 빈약해도 OS 엔트로피가 보호
- (-) 풀 상태가 `generateSeed()` 후에도 리셋되지 않음 → 같은 풀로 다중 시드 생성 시 연관성 가능
- (-) 실제 수집된 엔트로피 양에 대한 추정/검증 없이 고정적으로 시드 생성

##### `minSamples = 10` 충분성

**평가**: **부족할 가능성이 높다.**

- 정지 상태 가속도계: ~1.5 bits/sample → 10 샘플 = ~15 비트
- 정지 상태 자이로(gyroZ): ~0.26 bits/sample → 사실상 무시 가능
- seedContribution = accelMagnitude * gyroZ이므로, gyroZ ≈ 0이면 **전체 기여도 ≈ 0**
- `Random.secure()`가 안전망이지만, 센서 엔트로피의 목적을 달성하려면 최소 50-100 샘플이 필요
- NIST SP 800-90B 검증에는 1,000,000 샘플 필요 (오프라인 검증용), 런타임에는 실용적 최소치로 100+ 샘플 권장

#### 4.2 `sensor_data_collector.dart` 분석

**파일**: `mobile/lib/features/shuffle/data/datasources/sensor_data_collector.dart`

##### `seedContribution = accelMagnitude * gyroZ` 문제

```dart
double get seedContribution => accelMagnitude * gyroZ;
```

**치명적 약점**: 이것이 현재 구현의 **가장 심각한 문제**이다.

- `gyroZ`는 Z축 각속도. 장치가 정지 상태이면 ≈ 0
- Shepherd et al. (2025): "약 60%의 자이로스코프 판독값이 0 근처에 집중"
- `gyroZ ≈ 0` → `seedContribution ≈ 0` → 타임스탬프만 남음
- 타임스탬프의 엔트로피: 예측 가능한 등간격 샘플링이므로 매우 낮음
- 결과적으로 정지 상태에서 센서 엔트로피 기여가 **거의 0**

**대안 공식 (권장)**:
```
seedContribution = hash(accelX, accelY, accelZ, gyroX, gyroY, gyroZ)
```
모든 센서 축을 독립적으로 활용하여, 어느 한 축이 0이어도 다른 축에서 엔트로피를 확보한다.

##### 샘플링 주기: `SensorInterval.gameInterval`

- Flutter sensors_plus의 `gameInterval` ≈ 20ms (50Hz)
- 50Hz는 센서 엔트로피 연구에서 표준적 샘플링 레이트
- (+) 적절한 선택

##### 3초 타임아웃 폴백

```dart
_fallbackTimer = Timer(const Duration(seconds: 3), () {
  if (_samples.isEmpty) {
    _sensorsAvailable = false;
  }
});
```

**평가**:
- (+) 에뮬레이터/센서 미가용 시 합리적 폴백
- (-) `_sensorsAvailable = false` 설정만 하고, 이후 `generateFallbackSeed()`로의 명시적 연결이 코드에서 불분명
- (-) 센서가 있지만 정지 상태(gyroZ ≈ 0)인 경우는 탐지하지 못함 → 건강 테스트 필요

#### 4.3 식별된 약점 요약

| # | 약점 | 심각도 | 영향 |
|---|------|--------|------|
| 1 | `seedContribution = accelMagnitude * gyroZ` — gyroZ=0일 때 기여도 소멸 | **높음** | 정지 상태에서 센서 엔트로피 ≈ 0 |
| 2 | 건강 테스트 없음 (RCT, APT) | **중간** | 센서 실패/저하 미탐지 |
| 3 | `minSamples = 10` 부족 | **중간** | 축적 엔트로피 불충분 가능 |
| 4 | 런타임 엔트로피 추정 없음 | **중간** | 실제 엔트로피 양 불명 |
| 5 | `_pool` 시드 생성 후 미리셋 | **낮음** | 다중 시드 간 이론적 연관 가능성 |
| 6 | gyroZ만 사용 (X, Y축 미활용) | **중간** | 가용 엔트로피의 2/3 낭비 |

---

### 5. 엔트로피 추정 구현 방법론

#### 5.1 런타임 경량 Min-Entropy 추정 알고리즘

##### Most Common Value (MCV) 추정기 — 가장 간단

```
1. 양자화된 샘플 값의 빈도 테이블 유지
2. 최대 빈도 f_max 추적
3. min-entropy 추정: H∞ = -log₂(f_max / n)
```

- **복잡도**: O(1) per sample (해시맵 업데이트)
- **메모리**: O(k) (k = 고유 양자화 값 수)
- **한계**: 독립성 가정, Non-IID에서 과대추정 가능

##### 온라인 충돌 확률 기반 추정기 — 권장

Kelsey et al. (2020)의 온라인 추정기:

```
1. 이전 샘플과 현재 샘플의 충돌(동일값) 여부를 추적
2. 충돌 확률 p_c를 온라인으로 업데이트
3. min-entropy ≤ -log₂(p_c) (Renyi 엔트로피 order 2 기반)
```

- **복잡도**: O(1) per sample
- **메모리**: O(1) (이전 값, 충돌 카운트, 총 카운트만)
- **장점**: 폐쇄형 해(closed-form solution), NIST 압축 추정기 대비 동등 이상의 정확도
- **장점**: 샘플이 적어도 낮은 엔트로피 소스를 신뢰성 있게 탐지
- **적용**: 모바일 센서 스트림에 실시간 적용 가능

**출처**: [arXiv 2009.09570](https://arxiv.org/abs/2009.09570) — "On the Efficient Estimation of Min-Entropy"

#### 5.2 엔트로피 부족 시 경고/대체 전략

NIST와 보안 커뮤니티의 권장 전략:

```
1차: 강한 엔트로피 소스 사용 시도 (하드웨어 RNG, OS CSPRNG)
2차: 대안 소스로 폴백 (추가 센서, 터치 이벤트)
3차: 다수의 약한 소스를 혼합
4차: 최후 수단으로 저엔트로피 경고 후 OS CSPRNG만 사용
```

현재 구현의 `generateFallbackSeed()`는 4차에 해당하며 합리적이나, 1-3차 단계와 경고 메커니즘이 없다.

#### 5.3 조건부 Min-Entropy

조건부 min-entropy H∞(X|Y)는 추가 정보 Y가 주어졌을 때 X의 최악 예측 가능성을 측정한다:

```
H∞(X|Y) = -log₂(max_y Σ_x max P(X=x|Y=y) P(Y=y))
```

**실용적 의미**: 공격자가 장치 모델, 환경(정지/이동), 샘플링 시점 등을 알 수 있는 경우, 무조건 min-entropy보다 조건부 min-entropy가 더 보수적인(낮은) 추정치를 제공한다. 보안 분석에서는 조건부 min-entropy를 사용해야 한다.

---

## Key Findings

### F1. 구조적 NIST 부합성

현재 파이프라인(센서 → SHA-256 → Fortuna)은 NIST SP 800-90C의 RBG2 구조(Entropy Source → Conditioning → DRBG)와 구조적으로 일치한다. SHA-256은 NIST 승인 조건화 함수이며, Fortuna는 NIST 공식 승인 DRBG는 아니지만 AES-256 기반으로 학술적 검증이 되어 있다.

### F2. gyroZ 곱셈 공식의 치명적 결함

`seedContribution = accelMagnitude * gyroZ`는 정지 상태에서 센서 엔트로피를 사실상 0으로 만든다. 학술 연구에 따르면 자이로스코프 판독값의 약 60%가 0 근처에 집중되어 있다 (Shepherd et al. 2025). 이는 사용자가 타로 카드를 정적으로 탭만 하는 경우 센서 엔트로피가 거의 무의미해짐을 의미한다.

### F3. 모바일 센서의 실제 엔트로피는 생각보다 낮다

Shepherd et al. (2025)의 "Entropy Collapse" 연구는 다중 센서 조합에서도 min-entropy가 Shannon 엔트로피 대비 40-75% 낮다는 것을 보여준다. 20개 모달리티를 결합해도 약 24비트의 min-entropy만 달성 가능하다. 단일 가속도계의 min-entropy는 정지 상태에서 약 1.5-2.9비트/샘플이다.

### F4. `Random.secure()`가 효과적인 안전망

`generateSeed()`가 OS CSPRNG의 256비트를 항상 혼합하므로, 센서 엔트로피가 완전히 실패해도 암호학적 안전성은 유지된다. 현재 구현은 "센서가 추가 엔트로피를 제공하면 좋지만, 없어도 안전한" 설계이다. 이 설계 자체는 건전하다.

### F5. 건강 테스트와 엔트로피 추정의 부재

NIST SP 800-90B가 요구하는 RCT/APT 건강 테스트가 없어, 센서 실패나 저하를 런타임에 탐지할 수 없다. 또한 실제 수집된 엔트로피 양을 추정하지 않으므로, `minSamples` 임계값이 적절한지 검증 불가능하다.

---

## Recommendations

### R1. [높음] seedContribution 공식 개선

**현재**: `accelMagnitude * gyroZ`
**권장**: 모든 센서 축을 독립적으로 활용

```dart
// 6축 모두 사용: accelX, accelY, accelZ, gyroX, gyroY, gyroZ
// 곱셈 대신 바이트 연결 → SHA-256 입력으로 직접 공급
double get seedContribution {
  // LSB 기반: 각 축의 최하위 비트들이 가장 높은 엔트로피를 가짐
  // 곱셈은 0 전파 문제가 있으므로 피함
  return accelX + accelY * 1e6 + accelZ * 1e12
       + gyroX * 1e18 + gyroY * 1e24 + gyroZ * 1e30;
}
```

더 좋은 방법: `SensorSample`이 개별 축 값을 모두 `EntropyPool`에 전달하고, 풀에서 각 축의 float64 바이트를 직접 SHA-256에 투입하는 것이다.

### R2. [중간] 경량 건강 테스트 구현

센서 샘플 스트림에 RCT + APT를 적용:

```dart
class EntropyHealthMonitor {
  static const int rctThreshold = 11; // H=2, α=2^-20 기준
  static const int aptWindowSize = 64; // 모바일 경량화
  static const int aptThreshold = 48; // 윈도우의 75%

  int _rctCount = 0;
  int? _rctLastBucket;

  bool checkRepetitionCount(int quantizedValue) {
    if (quantizedValue == _rctLastBucket) {
      _rctCount++;
      return _rctCount < rctThreshold; // false = 실패
    }
    _rctLastBucket = quantizedValue;
    _rctCount = 1;
    return true;
  }
}
```

### R3. [중간] 최소 샘플 수 증가

`minSamples = 10` → `minSamples = 50` (최소) 또는 `minSamples = 100` (권장)

근거:
- 정지 상태 가속도계 ~1.5 bits/sample × 50 = 75 bits
- 이동 상태에서는 50 샘플로도 150+ bits 축적 가능
- UX 영향: 50Hz에서 50샘플 = 1초, 100샘플 = 2초 (셔플 애니메이션 중 자연스럽게 수집)

### R4. [중간] 런타임 엔트로피 추정기 추가

온라인 충돌 확률 기반 추정기 구현:

```dart
class OnlineEntropyEstimator {
  int _totalPairs = 0;
  int _collisions = 0;
  int? _previousBucket;

  void addSample(int quantizedValue) {
    if (_previousBucket != null) {
      _totalPairs++;
      if (quantizedValue == _previousBucket) {
        _collisions++;
      }
    }
    _previousBucket = quantizedValue;
  }

  double get estimatedMinEntropy {
    if (_totalPairs < 10) return 0.0;
    final collisionProb = _collisions / _totalPairs;
    if (collisionProb <= 0) return 8.0; // 최대 (8비트 양자화 기준)
    return -log2(collisionProb);
  }
}
```

이 추정기를 사용하여 "엔트로피 부족 시 추가 샘플 수집" 또는 "OS CSPRNG 폴백 전환" 전략을 구현할 수 있다.

### R5. [낮음] 터치 이벤트 엔트로피 보조 소스 추가

셔플 제스처 중 발생하는 터치 이벤트의 타이밍(마이크로초)과 좌표를 추가 엔트로피 소스로 활용:

```dart
void addTouchEntropy(double x, double y, int timestampMicros) {
  final touchBytes = ByteData(24)
    ..setFloat64(0, x)
    ..setFloat64(8, y)
    ..setInt64(16, timestampMicros);
  // SHA-256 풀에 혼합
}
```

### R6. [낮음] 시드 생성 후 풀 리셋

`generateSeed()` 호출 후 `_pool`을 초기화하여 다중 시드 간 독립성 보장:

```dart
Uint8List generateSeed() {
  // ... 기존 로직 ...
  reset(); // 풀 초기화
  return Uint8List.fromList(finalDigest.bytes);
}
```

---

## References

### NIST 표준 문서
1. NIST SP 800-90B — "Recommendation for the Entropy Sources Used for Random Bit Generation" (January 2018). [https://csrc.nist.gov/pubs/sp/800/90/b/final](https://csrc.nist.gov/pubs/sp/800/90/b/final)
2. NIST SP 800-90C — "Recommendation for Random Bit Generator (RBG) Constructions" (September 2025). [https://csrc.nist.gov/pubs/sp/800/90/c/final](https://csrc.nist.gov/pubs/sp/800/90/c/final)
3. NIST SP 800-90A Rev.1 — "Recommendation for Random Number Generation Using Deterministic Random Bit Generators". [https://csrc.nist.gov/pubs/sp/800/90/a/r1/final](https://csrc.nist.gov/pubs/sp/800/90/a/r1/final)
4. NIST SP 800-90B EntropyAssessment (C++ 구현). [https://github.com/usnistgov/SP800-90B_EntropyAssessment](https://github.com/usnistgov/SP800-90B_EntropyAssessment)

### 학술 논문
5. Shepherd, C. et al. (2025). "Entropy Collapse in Mobile Sensors: The Hidden Risks of Sensor-Based Security". [https://arxiv.org/abs/2502.09535](https://arxiv.org/abs/2502.09535)
6. Li, Y. et al. (2020). "Analysis on Entropy Sources based on Smartphone Sensors". ACM ICCNS 2020. [https://dl.acm.org/doi/10.1145/3442520.3442528](https://dl.acm.org/doi/10.1145/3442520.3442528)
7. Sarkisyan, A. et al. (2016). "Toward Sensor-Based Random Number Generation for Mobile and IoT Devices". IEEE Internet of Things Journal. [https://ieeexplore.ieee.org/document/7477997/](https://ieeexplore.ieee.org/document/7477997/)
8. Kelsey, J. et al. (2020). "On the Efficient Estimation of Min-Entropy". [https://arxiv.org/abs/2009.09570](https://arxiv.org/abs/2009.09570)
9. Barak, B. et al. (2014). "The Security of the Fortuna PRNG" — Schneier on Security. [https://www.schneier.com/blog/archives/2014/03/the_security_of_7.html](https://www.schneier.com/blog/archives/2014/03/the_security_of_7.html)

### 기술 가이드
10. SafeLogic — "Introduction to the SP 800-90 Series". [https://www.safelogic.com/blog/introduction-to-the-sp-800-90-series-requirements-on-random-number-generation](https://www.safelogic.com/blog/introduction-to-the-sp-800-90-series-requirements-on-random-number-generation)
11. Lightship Security — "NIST 800-90B Concepts". [https://lightshipsec.com/nist-800-90b-concepts/](https://lightshipsec.com/nist-800-90b-concepts/)
12. OWASP — "Insufficient Entropy". [https://owasp.org/www-community/vulnerabilities/Insufficient_Entropy](https://owasp.org/www-community/vulnerabilities/Insufficient_Entropy)

---

## Communication Log
| # | 방향 | 상대 | 내용 요약 | 시점(단계) |
|---|------|------|----------|-----------|
| 1 | 수신 | 오케스트레이터 | 엔트로피 품질 보장 방법 + NIST 표준 준수 방안 조사 의뢰 | 시작 |
| 2 | 발신 | 오케스트레이터 | NIST 90B(10개 추정기, 건강 테스트), 90C(RBG2 매핑), 센서 엔트로피 논문(정지시 ~1.5bits), gyroZ=0 치명적 결함, 6개 개선안 제시 | 완료 |

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
