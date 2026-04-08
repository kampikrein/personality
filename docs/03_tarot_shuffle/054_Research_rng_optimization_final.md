---
id: "054"
type: research
title: "카드 뽑기 난수 로직 — 수학적 최적화 방법론 최종 연구"
created: 2026-03-17
traces_scope: "047"
summary: >
  78장 타로 덱 셔플의 난수 파이프라인을 4개 관점에서 심층 조사한 최종 연구.
  현재 구현(3회 리플 + Fortuna + 센서 곱셈)에 3개 Critical급 문제를 발견.
  Fisher-Yates(Random.secure()) 교체가 가장 수학적으로 강력하고 비용 효율적인 해법.
  PractRand + TestU01 BigCrush 3-tier 검증 파이프라인으로 품질 보장 가능.
keywords: [Fisher-Yates, CSPRNG, Fortuna, ChaCha20, entropy, NIST, TestU01, PractRand, GSR, Bayer-Diaconis]
---

# 카드 뽑기 난수 로직 — 수학적 최적화 방법론 최종 연구

## Research Overview

### Background & Motivation
타로 앱의 카드 셔플은 "정말 랜덤하게 뽑혔는가"에 대한 사용자 신뢰가 서비스의 핵심 가치를 좌우한다. 현재 구현은 센서 엔트로피 → SHA-256 믹싱 → Fortuna CSPRNG → 리플 셔플 시뮬레이션으로 구성되어 있으며, 겉으로는 정교해 보이지만 각 레이어의 수학적 품질을 검증하지 않은 상태였다.

### Research Scope
- **포함**: 셔플 알고리즘 균등성, CSPRNG 비교, 엔트로피 품질, 난수 테스트 도구
- **제외**: 유료 하드웨어 난수 생성기(HSM, TRNG 칩), 서버 사이드 난수

### Research Perspectives
1. 셔플 알고리즘 수학적 균등성 (Fisher-Yates, GSR 리플 모델)
2. CSPRNG 아키텍처 비교 (Fortuna, ChaCha20, AES-CTR-DRBG, HMAC-DRBG, xoshiro256*, Random.secure())
3. 엔트로피 수집·추정·품질 보장 (NIST SP 800-90B/90C, 모바일 센서)
4. 난수 품질 검증 도구 (NIST SP 800-22, TestU01, PractRand, Dieharder)

### Related Documents
- Scope: [047_Scope_rng_optimization.md](./047_Scope_rng_optimization.md)
- Checkpoint: [048_Research_rng_optimization.md](./048_Research_rng_optimization.md)
- Agent reports: [049](./049_Agent_shuffle_algorithm_uniformity.md), [050](./050_Agent_csprng_comparison.md), [051](./051_Agent_entropy_quality.md), [052](./052_Agent_rng_test_tools.md)
- Synthesis: [053_Synthesis_rng_optimization.md](./053_Synthesis_rng_optimization.md)

---

## Perspective 1: 셔플 알고리즘 수학적 균등성

### Status Analysis

현재 구현 파일: `mobile/lib/features/shuffle/domain/strategies/riffle_shuffle_strategy.dart`

리플 셔플 시뮬레이션을 3회 반복하여 78장 덱을 셔플한다. 컷 위치는 mid ± uniform[-2,2], 교차 삽입은 1~3장씩 균등 드롭.

### Detailed Findings

#### Fisher-Yates (Knuth) 셔플: 수학적으로 완벽

Fisher-Yates 셔플은 n개 원소의 모든 n! 순열을 동일한 확률 1/n!로 생성함이 수학적으로 증명되어 있다 (Knuth, TAOCP Vol.2, Section 3.4.2).

**증명의 핵심**: 각 단계 k에서 남은 n-k+1개 원소 중 하나를 균등 확률로 선택하므로, 전체 확률 = (1/n)(1/(n-1))...(1/2) = 1/n!. Isabelle/HOL 기계 검증 증명도 존재.

**78장 덱 엔트로피 요구량**: log2(78!) = **382.20비트**. 256비트 CSPRNG 시드로는 이론적으로 모든 순열을 커버하지 못하나, 편향은 2^(-126)으로 천문학적으로 작아 실용적으로 완전히 충분.

#### GSR 리플 셔플: 78장에 최소 10회 필요

Bayer-Diaconis (1992) 논문의 핵심 결과: n장 카드의 혼합 임계점(cutoff) = (3/2)log2(n).

- **78장 cutoff**: (3/2) × log2(78) = **9.43회**
- **cutoff 현상**: m < 9.43이면 TV ≈ 1.0 (사실상 비무작위), m > 9.43이면 TV가 급격히 감소
- **TV < 0.1 (수용 가능) 도달**: 최소 **10회**

| 셔플 횟수 | TV distance (추정) | 판정 |
|----------|--------------------|------|
| **3 (현재)** | **≈ 1.0** | **사실상 무작위화 없음** |
| 7 | ≈ 0.58 | 불충분 |
| 10 | ≈ 0.08 | 수용 가능 |
| 12 | ≈ 0.02 | 우수 |

#### 현재 3회 리플의 정량적 불충분성

- **도달 가능 순열**: 2^234 / 2^382 = 2^(-148) — 전체 순열의 10^(-45) 비율
- **Rising sequences**: 최대 8개 (무작위 순열 평균 39.5개)
- **결론**: 3회 리플은 원래 순서와 거의 동일한 상태

### Caveats & Risks
- 현재 구현은 순수 GSR이 아니라 변형이므로 "약간 더 좋을 수 있다"고 주장할 여지가 있으나, 3회로는 근본적으로 불충분
- Fisher-Yates 교체 시 리플 애니메이션과의 시각적 불일치를 UX 관점에서 해결해야 함

### Summary
**현재 3회 리플 셔플은 수학적으로 무효하며, Fisher-Yates(CSPRNG) 교체가 필수적이다.** 리플 애니메이션은 시각적 제의 경험으로만 유지하는 하이브리드 접근을 권장.

---

## Perspective 2: CSPRNG 아키텍처 비교

### Status Analysis

현재 구현: `mobile/lib/features/shuffle/data/datasources/fortuna_random_wrapper.dart`에서 PointyCastle ^3.7.0의 FortunaRandom을 사용. 센서+Random.secure() 혼합 시드로 초기화.

### Detailed Findings

#### PointyCastle Fortuna: 불완전 구현

GitHub Issue #75 (bcgit/pc-dart, Open since 2021): Schneier 원안의 핵심인 **32-풀 엔트로피 누적기와 자동 재시딩이 미구현**. 실질적으로 AES-256-CTR 모드 생성기에 불과.

| 기능 | Schneier 원안 | PointyCastle 구현 |
|------|-------------|------------------|
| AES-CTR 생성기 | O | O |
| 32개 엔트로피 풀 | O | **X** |
| 자동 재시딩 | O | **X** |
| 1MB마다 키 변경 | O | **X** |
| 전방 보안 | O | **불완전** |

#### 6종 CSPRNG/RNG 비교 결과

| CSPRNG | 암호학적 안전 | Dart 구현체 | 성능 (ARM) | 권장 |
|--------|------------|-----------|-----------|------|
| **Random.secure()** | O (OS CSPRNG) | Dart SDK 내장 | OS 의존 | **1차 권장** |
| ChaCha20 (cryptography) | O | Apache 2.0 | ~92-160 MB/s | 2차 (대량 시) |
| PointyCastle Fortuna | 부분적 | MIT | ~5-20 MB/s | **미권장** |
| AES-CTR-DRBG | O | 전용 없음 | ~25-50 MB/s | 미권장 |
| HMAC-DRBG | O (기계 증명) | 전용 없음 | ~10-30 MB/s | 미권장 |
| xoshiro256** | **X** | MIT | ~1,000+ MB/s | 미권장 (비암호학적) |

#### 핵심: Random.secure()가 이미 최적

| 플랫폼 | OS 내부 CSPRNG |
|--------|---------------|
| Linux/Android | ChaCha20 기반 (getrandom()) |
| iOS/macOS | Fortuna (Apple 완전 구현) |
| Windows | AES-CTR-DRBG (BCrypt) |

78장 Fisher-Yates에 필요한 난수: **308바이트** — 모든 방식이 마이크로초 내 생성, 성능은 무관한 요소.

### Summary
**PointyCastle Fortuna 레이어를 제거하고 Random.secure()를 직접 사용하는 것이 최적.** 더 단순하고, 더 안전하고, 더 빠르다.

---

## Perspective 3: 엔트로피 수집·추정·품질 보장

### Status Analysis

현재 구현 파일:
- `mobile/lib/features/shuffle/data/datasources/entropy_pool.dart` — SHA-256 믹싱, 시드 생성
- `mobile/lib/features/shuffle/data/datasources/sensor_data_collector.dart` — 센서 수집

### Detailed Findings

#### NIST SP 800-90C 매핑

현재 파이프라인은 **RBG2 구조**(Entropy Source → Conditioning → DRBG)와 구조적으로 일치:
- 센서 + Random.secure() = Entropy Source
- SHA-256 = Conditioning (NIST 승인)
- Fortuna = DRBG (비승인이지만 AES-256 기반)

#### 치명적 결함: seedContribution = accelMagnitude * gyroZ

`sensor_data_collector.dart:17` — **gyroZ ≈ 0일 때 센서 엔트로피 기여가 0**

Shepherd et al. (2025, arXiv 2502.09535): "약 60%의 자이로스코프 판독값이 0 근처에 집중." 사용자가 폰을 정적으로 탭만 하면 센서 엔트로피가 사실상 무의미.

#### 모바일 센서 실제 엔트로피

| 조건 | 가속도계 | 자이로스코프 |
|------|---------|------------|
| 정지 | ~1.5 bits/sample | **~0.26 bits/sample** |
| 손에 들고 있음 | ~1.9 bits/sample | ~1-3 bits/sample |
| 적극적으로 흔듦 | ~3-6 bits/sample | ~3-5 bits/sample |

20개 센서 모달리티를 결합해도 ~24비트 min-entropy (Shepherd et al. 2025). "보안 핵심 애플리케이션의 비예측성 소스로 상용 센서 의존을 권장하지 않음."

#### 건강 테스트 부재

NIST SP 800-90B 필수 테스트가 없음:
- **RCT (Repetition Count Test)**: 동일 값 연속 반복 탐지
- **APT (Adaptive Proportion Test)**: 엔트로피 대규모 손실 탐지

#### 안전망: Random.secure() 항상 혼합

`generateSeed()`: 센서 풀 + Random.secure() 32바이트(256비트)를 SHA-256으로 최종 혼합. 센서가 완전 실패해도 OS CSPRNG의 256비트가 보장됨. 이 설계 자체는 건전.

### Summary
**센서 엔트로피는 제의적 UX에 기여하지만 보안적 가치는 제한적.** gyroZ 곱셈 공식 수정, 건강 테스트 추가, minSamples 증가가 권장되며, 보안은 Random.secure()에 의존해야 한다.

---

## Perspective 4: 난수 품질 검증 도구

### Status Analysis

현재 프로젝트에 난수 품질 검증 파이프라인이 없음.

### Detailed Findings

#### 4대 테스트 스위트 비교

| 기준 | NIST SP 800-22 | TestU01 BigCrush | PractRand | Dieharder |
|------|---------------|-----------------|-----------|-----------|
| 테스트 수 | 15 | 106 | 가변 (~150+) | 30+ |
| 엄격도 | **낮음** (obsolete 비판) | 높음 | **가장 높음** | 중간 |
| 필요 데이터 | ~7 MB | ~1 GB | 128 MB ~ 32 TB | 수백 MB |
| CI 통합 | 어려움 (대화형) | 보통 (C 래핑) | **쉬움** (stdin) | 쉬움 |
| 학술 인용 | 높음 (규제) | **최고** (학계 표준) | 급성장 중 | 중간 |
| 라이선스 | 퍼블릭 도메인 | Apache 2.0 | 퍼블릭 도메인 | GPL v2 |

#### NIST STS의 한계

Saarinen (2022, IACR ePrint 2022/169): "clearly obsolete, possibly harmful" — 가장 약한 PRNG도 쉽게 통과하여 잘못된 신뢰감 조성. NIST가 개정 결정 (진행 중).

#### PractRand: 가장 실용적이고 강력

- 스트리밍 방식, stdin 파이프, 점진적 결과, 멀티스레드
- 1TB에서 78개 PRNG 편향 탐지 vs BigCrush 50개
- Dart → stdout 바이너리 → `| RNG_test stdin`으로 즉시 연결

#### TestU01 BigCrush: 학술적 필수 표준

- 106개 테스트, ~1-2시간 (현대 CPU)
- 새 RNG 발표 시 BigCrush 통과 보고가 학계 관행

### Summary
**PractRand + TestU01 BigCrush 조합이 최적.** 3-tier 파이프라인(ENT 스크리닝 → PractRand CI → BigCrush 릴리스) 권장.

---

## Cross-Analysis

### Inter-Perspective Relationships

```
P1 (셔플 알고리즘)           P2 (CSPRNG)
    Fisher-Yates 필요 ────→ Random.secure() 충분
         ↑                       ↑
    "CSPRNG 전제"           "Fortuna 불필요"
         │                       │
P3 (엔트로피)              P4 (테스트 도구)
    센서 UX + 건강 테스트 ──→ PractRand CI로 검증
```

- P1이 "Fisher-Yates에는 CSPRNG 필요"라고 결론 → P2가 "Random.secure()가 이미 CSPRNG"라고 답
- P3이 "센서 엔트로피 품질 불확실"이라고 경고 → P4가 "PractRand로 정량 검증 가능"이라고 해법 제시
- P1 + P2를 합치면 가장 단순한 아키텍처 도출: `Fisher-Yates(Random.secure())`

### Common Patterns

1. **"더 단순한 것이 더 강력하다"**: 4개 관점 모두 현재의 복잡한 파이프라인(센서→SHA-256→Fortuna→리플)보다 단순한 대안(Random.secure()→Fisher-Yates)이 수학적으로 더 우수하다는 결론
2. **"겉으로 정교하지만 실질적으로 불충분"**: 리플 셔플은 물리적으로 보이지만 3회는 무효, Fortuna는 이름만 Fortuna, 센서 곱셈은 60% 상황에서 0

### Conflicting Items

**센서 엔트로피의 유지 여부**:
- P2: 완전 제거 가능 (보안 가치 없음)
- P3: 개선하여 유지 (NIST 구조 부합, 제의적 UX)

→ **종합 판단**: 센서 수집 자체는 유지하되 (타로의 제의적 경험), 보안 의존은 Random.secure()로 이관. 센서는 "있으면 좋은" 추가 엔트로피이지 필수가 아님.

---

## Comprehensive Conclusion

### 핵심 발견 (우선순위 순)

1. **[Critical] R-054-F1: 3회 리플 셔플 수학적 무효** — GSR 모델 기준 78장 cutoff = 9.43회, 현재 3회는 TV≈1.0으로 원래 순서와 거의 동일. 도달 가능 순열은 전체의 2^(-148) 비율. *(관점 1)*

2. **[Critical] R-054-F2: PointyCastle Fortuna 불완전 구현** — 32-풀 엔트로피 누적기, 자동 재시딩 미구현 (GitHub #75, 2021~ Open). 실질적으로 AES-CTR 생성기에 불과하며, Random.secure() 위에 성능 저하만 추가. *(관점 2)*

3. **[Critical] R-054-F3: 센서 기여도 곱셈 결함** — `accelMagnitude * gyroZ`에서 gyroZ≈0 시 (전체의 ~60%) 센서 엔트로피 기여가 0. 정지 상태에서 센서 레이어가 무의미. *(관점 3)*

4. **[High] R-054-F4: 건강 테스트 부재** — NIST SP 800-90B 필수 RCT/APT 없음. 센서 실패/저하 런타임 미탐지. *(관점 3)*

5. **[High] R-054-F5: 난수 품질 검증 파이프라인 부재** — 현재 RNG 출력의 통계적 품질을 검증하는 자동화 도구/프로세스가 없음. *(관점 4)*

6. **[Medium] R-054-F6: minSamples=10 불충분** — 정지 상태에서 10샘플 × ~1.5비트 = 15비트 축적. 50~100 이상 필요. *(관점 3)*

7. **[Medium] R-054-F7: Fisher-Yates가 수학적 최적해** — O(n), 완전 균등(1/n!), CSPRNG 결합 시 증명 완료. Knuth TAOCP + Isabelle/HOL 기계 검증. *(관점 1)*

8. **[Medium] R-054-F8: Random.secure()가 이미 최적** — iOS=Apple Fortuna, Android/Linux=ChaCha20, Windows=AES-CTR-DRBG. 추가 CSPRNG 레이어 불필요. *(관점 2)*

9. **[Low] R-054-F9: PractRand + TestU01 BigCrush 최적 조합** — PractRand는 CI 통합 최적(stdin 파이프), BigCrush는 학계 de facto 표준. 3-tier 검증 파이프라인 가능. *(관점 4)*

### 권장 아키텍처

```
[현재]                              [권장]
센서 → SHA-256 → Fortuna → 리플3회   →   Random.secure() → Fisher-Yates
(복잡, 3개 Critical 문제)              (단순, 수학적 완벽)
                                      + 리플 애니메이션(시각 전용)
                                      + 센서(UX + 선택적 추가 믹싱)
                                      + PractRand CI 검증
```

### 무료 방법론 선택지 요약

| 방법론 | 비용 | 수학적 보장 | 구현 복잡도 | 비고 |
|--------|------|-----------|-----------|------|
| **Fisher-Yates + Random.secure()** | 무료 | 완벽 (1/n! 증명) | 5줄 | **1차 권장** |
| Fisher-Yates + cryptography SecureRandom.fast | 무료 | 완벽 | 10줄 | 대량 난수 시 |
| 리플 10회 + Random.secure() | 무료 | 근사 (TV≈0.08) | 기존 코드 수정 | 차선책 |
| 리플 12회 + 정확한 GSR 모델 | 무료 | 근사 (TV≈0.02) | 중간 | 물리 시뮬레이션 중시 시 |

---

## Unresolved Items

1. **Apple Fortuna 구현 세부**: iOS/macOS의 `SecRandomCopyBytes()` 내부 Fortuna 구현의 정확한 재시딩 주기는 Apple의 비공개 정보. 그러나 FIPS 인증 사실로 품질은 보장됨. *(이유: Apple 내부 구현 비공개)*

2. **PractRand 최신 버전(0.95) 안정성**: SourceForge에서 0.95 pre-release만 존재. 0.93이 가장 널리 테스트된 안정 버전. *(이유: 릴리스 상태 불확실)*

3. **Dart Random.secure() 웹 환경 엔트로피**: Web Crypto API의 `crypto.getRandomValues()` 구현이 브라우저별로 다를 수 있음. 현재 Flutter 모바일 전용이므로 당장 영향 없음. *(이유: 웹 환경 미사용)*

---

## Referenced File List

| File Path | Related Perspective | Role/Content |
|-----------|-------------------|--------------|
| `mobile/lib/features/shuffle/domain/strategies/riffle_shuffle_strategy.dart` | P1 | 현재 리플 셔플 구현 (3회, 변형 GSR) |
| `mobile/lib/features/shuffle/domain/strategies/shuffle_strategy.dart` | P1 | ShuffleStrategy 추상 인터페이스 |
| `mobile/lib/features/shuffle/domain/entities/shuffle_config.dart` | P1 | shuffleCount 기본값 3 |
| `mobile/lib/features/shuffle/data/datasources/fortuna_random_wrapper.dart` | P2 | Fortuna CSPRNG 래퍼 (PointyCastle) |
| `mobile/lib/features/shuffle/data/datasources/entropy_pool.dart` | P3 | SHA-256 믹싱, 시드 생성, minSamples=10 |
| `mobile/lib/features/shuffle/data/datasources/sensor_data_collector.dart` | P3 | 센서 수집, seedContribution 곱셈 |
| `mobile/lib/features/shuffle/domain/usecases/shuffle_deck_usecase.dart` | P1,P2,P3 | 셔플 유스케이스 (엔트로피→시드→PRNG→셔플) |
| `mobile/lib/features/shuffle/presentation/game/tarot_game.dart` | P1 | 게임 내 Random.secure() 사용 |

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
