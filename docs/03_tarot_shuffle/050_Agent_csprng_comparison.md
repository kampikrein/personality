---
id: "050"
title: "CSPRNG 아키텍처 비교 분석"
category: agent
status: archived
created: 2026-03-17
summary: >
  Fortuna, ChaCha20, AES-CTR-DRBG, HMAC-DRBG, xoshiro256*, Dart Random.secure() 6종을
  암호학적 안전성, 통계 품질, 성능, Dart 구현체, 시드/상태 크기 기준으로 비교 분석.
  결론: Random.secure() 직접 사용이 최적이며, PointyCastle Fortuna 레이어는 제거 권장.
keywords: [agent-report, CSPRNG, Fortuna, ChaCha20, AES-CTR-DRBG, HMAC-DRBG, xoshiro256]
modules: [mobile/lib/features/shuffle/data/datasources]
---

# CSPRNG 아키텍처 비교 분석

## Progress
### Completed
- [x] Fortuna (PointyCastle) 현황 분석
- [x] ChaCha20 조사
- [x] AES-CTR-DRBG 조사
- [x] HMAC-DRBG 조사
- [x] xoshiro256* 조사
- [x] Dart Random.secure() 내부 구현 조사
- [x] 비교 테이블 작성
- [x] 최종 권장 사항
### Remaining
(없음)
### Current Status
조사 완료.

## Summary

78장 타로 덱의 완전 순열을 표현하려면 log2(78!) = 382.2비트의 엔트로피가 필요하다.
현재 구현은 Random.secure() 32바이트(256비트) + 센서 엔트로피 SHA-256 믹싱으로 시드를 생성한 뒤,
PointyCastle의 FortunaRandom에 공급하는 구조이다.

**핵심 결론**: PointyCastle의 Fortuna 구현은 Schneier 원안의 32-풀 엔트로피 누적기를 구현하지 않은
**불완전한 구현체**이며, 실질적으로 AES-CTR 모드 생성기만 제공한다. 이 경우 Fortuna 레이어는
Random.secure() 위에 추가적 보안 가치를 거의 제공하지 않으면서 ~7-30 MB/s의 순수 Dart AES 성능 병목과
유지보수 부담만 추가한다. **Random.secure() 직접 사용 또는 cryptography 패키지의 SecureRandom.fast
(ChaCha12 기반, ~250 MB/s)가 최적의 선택이다.**

---

## Details

### 1. 타로 셔플의 엔트로피 요구량

- 78장 덱 완전 순열: 78! = 1.13 x 10^115 가지
- 필요 엔트로피: log2(78!) = **382.2비트**
- 비교: 52장 포커 덱 log2(52!) = 225.6비트
- 현재 시드: 256비트 (Random.secure() 32바이트 + 센서 SHA-256)
- **256비트 시드로는 78!의 모든 순열을 이론적으로 커버 불가** (382.2비트 필요)
- 단, 실용적으로 256비트 = 2^256 = 1.16 x 10^77 가지 순열 표현 가능 — 편향은 78!/(2^256 x ceil(78!/2^256)) 수준으로 무시할 수 있음

### 2. Fortuna (PointyCastle 구현)

#### 설계 (Ferguson & Schneier, 2003)
- **구성**: 생성기(AES-256-CTR) + 엔트로피 누적기(32개 풀) + 시드 파일
- **키**: 256비트 AES 키 + 128비트 카운터
- **상태 크기**: 키 32바이트 + 카운터 16바이트 + 결과 버퍼 16바이트 = 64바이트 (생성기만) + 32개 풀 (누적기 포함 시 수 KB)
- **재시딩**: 32개 독립 엔트로피 풀, 풀 i는 2^i 회마다 재시딩에 참여, 초당 최대 10회
- **보안**: 256비트, 2^20 바이트(1MB) 출력마다 자동 키 변경, 전방 보안
- **채택**: FreeBSD /dev/random (11+), Apple OS (2020 Q1~)

#### PointyCastle Dart 구현의 문제점

**GitHub Issue #75 (bcgit/pc-dart)**: FortunaRandom은 Schneier 알고리즘을 **완전히 구현하지 않았다**.

- 32개 엔트로피 풀 **미구현**
- 엔트로피 누적기(accumulator) **미구현**
- 자동 재시딩 메커니즘 **미구현**
- **실체**: AES-256-CTR 모드 생성기만 존재, "Fortuna"라는 이름은 오해를 유발
- 사용자가 수동으로 시드 제공 필수 (Random.secure() 의존)
- 이슈 상태: **Open** (2021년 이후 미해결)

#### 성능
- 순수 Dart AES 구현: **~7-30 MB/s** (PointyCastle 벤치마크)
- AES-NI 하드웨어 가속 불가 (순수 Dart)
- 비교: 네이티브 Java/Kotlin AES = 200-300+ MB/s (데스크톱), 80+ MB/s (모바일)
- AESFastEngine은 타이밍 공격 취약으로 deprecated, 현재 AESEngine = ~7 MB/s

**결론**: PointyCastle Fortuna는 Fortuna의 핵심 가치(자동 재시딩, 다중 풀)를 제공하지 않으면서
순수 Dart AES의 성능 비용만 부과한다.

### 3. ChaCha20

#### 설계 (Daniel J. Bernstein)
- Salsa20의 개선판, eSTREAM 선정 스트림 암호
- **구조**: 256비트 키 + 64비트 논스 + 64비트 카운터 = 512비트 내부 상태
- **라운드**: ChaCha20(20라운드), ChaCha12(12라운드), ChaCha8(8라운드)
- **보안**: 256비트 (20라운드 기준), 알려진 실용적 공격 없음
- **상태 크기**: 64바이트 (512비트)

#### 성능
- **ARM (하드웨어 가속 없음)**: ~92-160 MB/s — AES-GCM보다 2-3x 빠름
- **ARM Cortex-A9 1.2GHz**: ChaCha20 92 MB/s vs AES-128-GCM 25 MB/s
- **x86 (AES-NI)**: AES-GCM 892 MB/s vs ChaCha20 427 MB/s
- **모바일 결론**: AES 하드웨어 가속 없는 ARM에서 ChaCha20이 50-300% 빠름

#### 채택
- Linux 커널 /dev/urandom (4.8+): ChaCha20 기반
- Google TLS: 모바일 디바이스에서 ChaCha20-Poly1305 우선
- OpenBSD arc4random: ChaCha20 기반
- Rust `rand` 크레이트 기본 CSPRNG: ChaCha12

#### Dart/Flutter 구현체
- **`cryptography` 패키지** (Apache 2.0, v2.9.0): DartChacha20 순수 Dart 구현
  - `SecureRandom.fast`: ChaCha12 기반, **~250 MB/s**, OS 엔트로피 시드로 초기화 후 빠른 생성
  - Android/iOS/macOS/Linux/Windows/Web 모두 지원
  - `cryptography_flutter` 추가 시 플랫폼 네이티브 가속
- **`flutter_chacha20_poly1305`**: 네이티브 구현, 암호화 특화
- **`rusty_chacha_dart`**: Rust 기반 500-1000 MiB/s, 아직 프로덕션 미권장

### 4. AES-CTR-DRBG (NIST SP 800-90A)

#### 설계
- NIST SP 800-90A Rev.1 표준 (2015)
- AES-256을 CTR 모드로 사용하는 결정론적 난수 생성기
- **구조**: 256비트 키(K) + 128비트 카운터(V)
- **상태 크기**: 48바이트 (K 32바이트 + V 16바이트)
- **시드**: AES-256 사용 시 최소 48바이트 (엔트로피 32바이트 + 논스 16바이트)

#### 보안
- 256비트 보안 강도 (AES-256 사용 시)
- CMVP 검증 구현체의 67.8%가 CTR_DRBG 사용 (가장 널리 채택)
- **알려진 약점**: 블록 크기(128비트) 관련 이론적 불완전성 (Hoang & Shen, 2020)
- HMAC_DRBG와 달리 공식 보안 증명 없음

#### 성능
- **네이티브 (AES-NI 있을 때)**: ~190 MB/s
- **순수 Dart (PointyCastle)**: ~7-30 MB/s (AES 하드웨어 가속 불가)
- **ARM (하드웨어 Crypto Extensions 있을 때)**: ~100-140 MB/s
- **ARM (소프트웨어 전용)**: ~25-50 MB/s

#### Dart 구현체
- **`pointycastle`** (MIT): AES-CTR 모드 구현 존재, DRBG 래핑은 수동 필요
- **전용 AES-CTR-DRBG 패키지는 pub.dev에 없음**

### 5. HMAC-DRBG (NIST SP 800-90A)

#### 설계
- NIST SP 800-90A Rev.1 표준
- HMAC를 기반으로 한 결정론적 난수 생성기
- **구조**: HMAC 키(K) + 값(V), 해시 함수 의존
- **상태 크기**: SHA-256 사용 시 K 32바이트 + V 32바이트 = 64바이트
- **시드**: SHA-256 사용 시 최소 55바이트 (엔트로피 32바이트 + 논스 16바이트 + personalization)

#### 보안
- **기계 검증된 보안 증명 존재** (Princeton, Ye et al. — mbedTLS HMAC-DRBG)
- Woodage & Shumow (2019): 시드 생성 및 재시딩 포함 보안 증명
- CMVP 채택률: 37.0%
- Schneier: "HMAC-DRBG에 백도어가 없다는 증명" (2017)

#### 성능
- **네이티브**: ~45 MB/s (Hash_DRBG/CTR_DRBG의 ~1/4)
- HMAC = 해시 2회 적용 → 이론적으로 Hash_DRBG의 절반이지만 실측은 더 느림
- 재시딩(prediction resistance) 시 추가 오버헤드 큼

#### Dart 구현체
- **전용 HMAC-DRBG 패키지 없음**
- `crypto` 패키지(Google 공식)에 HMAC-SHA256 있으나 DRBG 래핑은 수동 구현 필요
- `pointycastle`에도 HMAC-DRBG 전용 클래스 없음 (Issue #75에서 대안으로 논의됨)

### 6. xoshiro256** / xoshiro256++ (Blackman & Vigna)

#### 설계
- **비암호학적** 의사난수 생성기 (PRNG, CSPRNG가 아님)
- **구조**: 256비트 내부 상태, xorshift + rotate + shift/multiply
- **주기**: 2^256 - 1
- **출력 함수**: `**` (starstar, multiply), `++` (plusplus, rotate+add)

#### 통계 품질
- TestU01 BigCrush **106개 전체 테스트 통과** (실패 0개)
- PractRand 통과
- 4차원 등분포(equidistribution) 달성 (xoshiro256**)
- Mersenne Twister (MT19937)보다 우수: MT는 LinearComp 실패

#### 성능
- **0.75 ns/64비트** (xoshiro256**) = ~7 GB/s 이상
- 비교: ChaCha20 ~1.8 GB/s, MT19937 1.36 ns/64비트
- **가장 빠른 통계적 고품질 PRNG**

#### 보안 한계
- **암호학적으로 안전하지 않음**: 출력에서 내부 상태 역추적 가능
- 카드 게임, 도박, 암호학적 용도에 **부적합**
- 시뮬레이션, 과학 계산, 게임 그래픽 등 통계 품질만 중요한 용도에 적합

#### Dart 구현체
- **`xrandom`** (MIT, v0.7.2): Xoshiro256pp, Xoshiro256ss 등 포함
  - 순수 Dart, 모든 플랫폼 지원
  - AOT 벤치마크: Random보다 ~30% 빠름
  - 마지막 업데이트: 2022-03-15, 11 likes, 890 downloads
  - JavaScript 환경 제한 (53비트 정수)

### 7. Dart Random.secure()

#### 내부 구현 (Dart SDK runtime)

Dart VM의 Random.secure()는 **각 플랫폼의 OS 레벨 CSPRNG을 직접 호출**한다:

| 플랫폼 | API | 소스 |
|--------|-----|------|
| **Linux/Android** | `getrandom()` 시스템콜 (fallback: `/dev/urandom`) | `runtime/bin/crypto_linux.cc` |
| **macOS/iOS** | `SecRandomCopyBytes(kSecRandomDefault, ...)` | `runtime/bin/crypto_macos.cc` |
| **Windows** | `BCryptGenRandom()` | `runtime/bin/crypto_win.cc` |
| **Fuchsia** | `zx_cprng_draw()` | (Fuchsia 전용) |
| **Web** | `crypto.getRandomValues()` (Web Crypto API) | Dart2JS/WASM |

#### 플랫폼별 백엔드 CSPRNG

| 플랫폼 | OS 내부 CSPRNG |
|--------|---------------|
| **Linux 4.8+** | ChaCha20 기반 (커널 CSPRNG) |
| **Android** | Linux getrandom() = ChaCha20 기반 |
| **iOS/macOS** | Fortuna (Apple 2020 Q1~, AES-256-CTR 생성기) |
| **Windows** | AES-CTR-DRBG (BCrypt) |

#### 성능
- OS 커널 호출 비용: 마이크로초 단위 오버헤드
- 대량 생성 시 시스템 콜 비용이 병목
- `cryptography` 패키지의 `SecureRandom.fast`는 OS 호출을 줄여 ~250 MB/s 달성

#### 보안
- 각 플랫폼 OS 벤더(Google, Apple, Microsoft)가 유지보수
- FIPS 140-2/3 인증된 구현 (Windows, iOS/macOS)
- **추가 레이어가 불필요한 이유**: OS CSPRNG이 이미 재시딩, 엔트로피 관리, 전방 보안을 처리

---

## 비교 테이블

### 암호학적 안전성 및 통계 품질

| CSPRNG/RNG | 암호학적 안전성 | 비트 보안 | 보안 증명 | TestU01 BigCrush | 알려진 공격 |
|------------|---------------|----------|----------|-----------------|-----------|
| **Fortuna** (원안) | O | 256 | 비공식 (Schneier 분석) | 통과 | 없음 |
| **PointyCastle Fortuna** | 부분적 | 256 (생성기만) | 없음 | 미검증 | 재시딩 없음 → 장기 사용 시 위험 |
| **ChaCha20** | O | 256 | eSTREAM 분석 | 통과 | 없음 (20라운드) |
| **AES-CTR-DRBG** | O | 256 (AES-256) | 없음 (이론적 약점 존재) | 통과 | 블록 크기 관련 이론적 편향 |
| **HMAC-DRBG** | O | 256 (SHA-256) | **기계 검증 증명** | 통과 | 없음 |
| **xoshiro256**** | X | 0 | 해당 없음 | **106/106 통과** | 상태 역추적 가능 |
| **Random.secure()** | O | 플랫폼 의존 (128-256) | 플랫폼 벤더 인증 | 통과 | 없음 |

### 성능 비교

| CSPRNG/RNG | 네이티브 (MB/s) | 순수 Dart (MB/s) | ARM 모바일 (MB/s) |
|------------|----------------|-----------------|------------------|
| **PointyCastle Fortuna** | N/A | **~7-30** | ~5-20 |
| **ChaCha20** (cryptography 패키지) | 427-560 | ~250 (SecureRandom.fast) | ~92-160 |
| **AES-CTR-DRBG** | ~190 (AES-NI) | ~7-30 (PointyCastle) | ~25-50 (sw) / ~100-140 (hw) |
| **HMAC-DRBG** | ~45 | ~5-15 (추정) | ~10-30 (추정) |
| **xoshiro256**** | ~7,000+ | ~600+ (xrandom) | ~1,000+ |
| **Random.secure()** | OS 의존 | 시스템콜 오버헤드 | OS 의존 |

### 구현체 및 실용성

| CSPRNG/RNG | Dart 패키지 | 라이선스 | 시드 크기 | 상태 크기 | 자동 재시딩 |
|------------|-----------|---------|----------|----------|-----------|
| **PointyCastle Fortuna** | `pointycastle` ^3.7.0 | MIT | 32바이트 (수동) | 64바이트 | **X** (미구현) |
| **ChaCha20** | `cryptography` ^2.9.0 | Apache 2.0 | OS 자동 | 64바이트 | O (SecureRandom.fast) |
| **AES-CTR-DRBG** | 전용 패키지 없음 | - | 48바이트 | 48바이트 | 수동 구현 필요 |
| **HMAC-DRBG** | 전용 패키지 없음 | - | 55바이트 | 64바이트 | 수동 구현 필요 |
| **xoshiro256**** | `xrandom` ^0.7.2 | MIT | 32바이트 | 32바이트 | X |
| **Random.secure()** | Dart SDK 내장 | BSD | OS 자동 | OS 관리 | **O** (OS 레벨) |

---

## 핵심 질문 분석

### Q1. Random.secure()만으로 충분한가?

**충분하다.** 근거:

1. **OS CSPRNG이 이미 최적**: Linux(ChaCha20), iOS(Fortuna), Android(ChaCha20), Windows(AES-CTR-DRBG) 모두
   NIST 표준 또는 동등 수준의 CSPRNG을 사용하며, 재시딩, 엔트로피 관리, 전방 보안을 OS 레벨에서 처리한다.
2. **PointyCastle Fortuna는 가치를 추가하지 않는다**: 32-풀 누적기가 없으므로 "Random.secure() 시드 → AES-CTR 생성기"일 뿐이다.
   이는 Random.secure() 위에 더 느린 순수 Dart AES를 얹는 것과 같다.
3. **센서 엔트로피의 실질적 가치**: 현재 EntropyPool은 센서 데이터를 SHA-256으로 Random.secure() 32바이트에 믹싱한다.
   센서 엔트로피는 "사용자 참여감"에 기여하지만, OS CSPRNG이 이미 하드웨어/환경 엔트로피를 충분히 수집하므로
   **보안적 추가 가치는 미미**하다.

### Q2. 카드 셔플에 암호학적 안전성이 필요한가?

**상황에 따라 다르다:**

- **오프라인 타로 앱 (현재 용도)**: 통계적 균등성만으로 충분. 사용자가 공격자가 아니므로 예측 불가능성은 UX 이슈.
  그러나 "진정한 랜덤"에 대한 사용자 신뢰가 중요하므로 CSPRNG 사용이 **마케팅/신뢰 측면에서 유리**.
- **온라인 도박/베팅**: 암호학적 안전성 필수 (공격자가 다음 카드를 예측 시도).
- **현재 앱의 결론**: Random.secure() (=OS CSPRNG)가 이미 암호학적으로 안전하므로, 별도 레이어 없이도 충분.

### Q3. 모바일 환경 성능 임팩트

78장 Fisher-Yates 셔플에 필요한 난수: 77개 정수 (각 최대 32비트).
총 필요 데이터: 77 x 4바이트 = **308바이트**.

| 방식 | 308바이트 생성 시간 (추정) |
|------|-------------------------|
| Random.secure() | ~10-50 us (시스템콜 1-2회) |
| PointyCastle Fortuna | ~10-50 us (순수 Dart AES) |
| SecureRandom.fast | < 1 us (ChaCha12 버퍼) |
| xoshiro256** | < 0.1 us |

**결론**: 308바이트 수준에서는 **모든 방식이 실용적으로 동일**하다.
차이는 마이크로초 단위이며 사용자가 체감할 수 없다.
성능은 CSPRNG 선택의 결정적 요인이 아니다.

---

## Key Findings

1. **PointyCastle Fortuna는 불완전한 구현**: Schneier 원안의 핵심인 32-풀 엔트로피 누적기와 자동 재시딩이
   미구현. 실질적으로 AES-CTR 생성기에 불과하며, "Fortuna"라는 이름은 오해를 유발한다 (GitHub Issue #75, Open).

2. **Random.secure()는 이미 최적의 OS CSPRNG을 사용**: iOS는 실제 Fortuna(Apple 구현),
   Linux/Android는 ChaCha20 기반, Windows는 AES-CTR-DRBG. 이들은 모두 벤더가 유지보수하고
   FIPS 인증을 받은 구현체이다.

3. **추가 CSPRNG 레이어는 보안을 개선하지 않는다**: Random.secure() → Fortuna(PointyCastle)는
   "강한 시드 → 약한 생성기" 패턴. OS CSPRNG이 이미 재시딩과 전방 보안을 보장하므로, 위에
   순수 Dart 구현을 얹으면 성능만 저하되고 공격 표면만 증가한다.

4. **78장 셔플에 필요한 난수량은 극소**: 308바이트로 모든 CSPRNG이 마이크로초 내 생성.
   성능은 CSPRNG 선택에 무관한 요소.

5. **xoshiro256**는 통계 최강이지만 암호학적 미안전**: 타로 앱에서 사용자 신뢰("진정한 랜덤")가
   중요하므로, 비암호학적 PRNG 채택은 기술적으로 가능하지만 리스크 대비 이점이 없다.

6. **HMAC-DRBG는 유일하게 기계 검증 보안 증명이 있지만**: Dart 전용 패키지가 없고
   성능이 가장 느리며, Random.secure()가 이미 동등한 보안을 제공하므로 별도 구현 필요성 없음.

## Recommendations

### 1차 권장: Random.secure() 직접 사용 (최소 변경)

```dart
// 기존: FortunaRandomWrapper(seed) 사용
// 권장: Random.secure() 직접 사용
final random = Random.secure();
final result = strategy.shuffle(cards: cards, random: random, config: config);
```

- FortunaRandomWrapper 제거
- PointyCastle 의존성 제거 가능 (다른 곳에서 미사용 시)
- 센서 엔트로피는 UX 연출용으로만 유지 (보안 목적 X)

### 2차 권장: 대량 난수 필요 시 SecureRandom.fast

```dart
// cryptography 패키지의 SecureRandom.fast
import 'package:cryptography/cryptography.dart';
final secureRandom = SecureRandom.fast;
final bytes = secureRandom.nextBytes(32);
```

- ChaCha12 기반, OS 시드 자동, ~250 MB/s
- 현재 78장 셔플에는 불필요하지만, 향후 대량 시뮬레이션/검증에 유용

### 미권장

| 방식 | 이유 |
|------|------|
| PointyCastle Fortuna 유지 | 불완전 구현, 성능 병목, 유지보수 부담 |
| AES-CTR-DRBG 직접 구현 | Dart에서 AES 하드웨어 가속 불가, 전용 패키지 없음 |
| HMAC-DRBG 직접 구현 | 전용 패키지 없음, 성능 최하, 이점 없음 |
| xoshiro256** | 암호학적 미안전, 사용자 신뢰 리스크 |

## References

### 논문 및 표준
- Ferguson, N. & Schneier, B. (2003). *Practical Cryptography*. Wiley. — Fortuna 원안
- Bernstein, D.J. (2008). "ChaCha, a variant of Salsa20." — ChaCha20 설계
- NIST SP 800-90A Rev.1 (2015). "Recommendation for Random Number Generation Using Deterministic Random Bit Generators" — CTR_DRBG, HMAC_DRBG, Hash_DRBG
- Hoang, V.T. & Shen, Y. (2020). "Security Analysis of NIST CTR-DRBG." IACR ePrint 2020/619
- Ye, K.Q. et al. "Verified Correctness and Security of mbedTLS HMAC-DRBG." Princeton — 기계 검증 증명
- Woodage, J. & Shumow, D. (2019). "An Analysis of the NIST SP 800-90A Standard." IACR ePrint 2018/349
- Blackman, D. & Vigna, S. (2021). "Scrambled Linear Pseudorandom Number Generators." ACM TOMS — xoshiro256

### Dart/Flutter 패키지
- [pointycastle (pub.dev)](https://pub.dev/packages/pointycastle) — MIT, Fortuna 구현 포함
- [cryptography (pub.dev)](https://pub.dev/packages/cryptography) — Apache 2.0, ChaCha20 + SecureRandom.fast
- [xrandom (pub.dev)](https://pub.dev/packages/xrandom) — MIT, xoshiro256++ 구현
- [crypto (pub.dev)](https://pub.dev/packages/crypto) — BSD, HMAC-SHA256

### 소스 코드 및 이슈
- [Dart SDK runtime/bin/crypto_linux.cc](https://github.com/dart-lang/sdk/blob/master/runtime/bin/crypto_linux.cc) — getrandom() 사용
- [Dart SDK runtime/bin/crypto_macos.cc](https://github.com/dart-lang/sdk/blob/master/runtime/bin/crypto_macos.cc) — SecRandomCopyBytes 사용
- [bcgit/pc-dart Issue #75](https://github.com/bcgit/pc-dart/issues/75) — FortunaRandom 불완전 구현 이슈
- [Zellic: Far From Random](https://www.zellic.io/blog/proton-dart-flutter-csprng-prng/) — Dart PRNG 보안 분석

### 벤치마크 및 분석
- [Cloudflare: Do the ChaCha](https://blog.cloudflare.com/do-the-chacha-better-mobile-performance-with-cryptography/) — ARM ChaCha20 성능
- [BearSSL Speed Benchmarks](https://www.bearssl.org/speed.html) — ARM 크로스 벤치마크
- [PRNG Shootout (Vigna)](https://prng.di.unimi.it/) — xoshiro BigCrush 결과
- [Illuminated Security: Performance of NIST DRBGs](https://buttondown.com/illuminatedsecurity/archive/performance-of-nist-drbgs/) — DRBG 성능 비교
- [PointyCastle AES Speed (Issue #173)](https://github.com/bcgit/pc-dart/issues/173) — 순수 Dart AES 벤치마크

## Communication Log
| # | 방향 | 상대 | 내용 요약 | 시점(단계) |
|---|------|------|----------|-----------|
| 1 | 수신 | orchestrator | CSPRNG 6종 비교 분석 위임 | 조사 시작 |
| 2 | 발신 | orchestrator | 조사 완료. Random.secure() 직접 사용 권장, PointyCastle Fortuna 제거 권장 | 조사 완료 |

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
