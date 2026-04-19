---
id: "052"
title: "난수 품질 검증 도구 비교 조사"
category: agent
status: archived
created: 2026-03-17
summary: >
  무료 난수 품질 테스트 스위트 4종(NIST SP 800-22, TestU01, PractRand, Dieharder)과
  보조 도구 3종(gjrand, ENT, RaBiGeTe)을 상세 비교 조사했다. PractRand + TestU01 BigCrush
  조합이 학술적 엄격도와 실용성 면에서 최적이며, Dart에서 바이너리 stdout 출력 후
  파이프라인으로 연결하는 구체적 CI/CD 통합 설계를 제시한다. NIST STS는 학술계에서
  "clearly obsolete, possibly harmful"로 평가받아 단독 사용을 권장하지 않는다.
keywords: [agent-report, NIST-SP-800-22, TestU01, PractRand, Dieharder, randomness-testing, gjrand, ENT, CI-CD]
modules: [mobile/lib/features/shuffle]
---

# 난수 품질 검증 도구 비교 조사

## Progress
### Completed
- [x] NIST SP 800-22 조사
- [x] TestU01 (SmallCrush/Crush/BigCrush) 조사
- [x] PractRand 조사
- [x] Dieharder 조사
- [x] 기타 도구 (gjrand, ENT, RaBiGeTe) 조사
- [x] Dart/Flutter 연동 파이프라인 설계
- [x] 비교 테이블 작성
- [x] 최종 권장 사항
### Remaining
(없음)
### Current Status
조사 완료.

---

## Summary

무료로 사용 가능한 난수 품질 테스트 스위트 4개(NIST SP 800-22, TestU01, PractRand, Dieharder)와 보조 도구 3개(gjrand, ENT, RaBiGeTe)를 조사했다. 결론적으로 **PractRand + TestU01 BigCrush** 조합이 타로 셔플 엔진의 난수 품질 검증에 가장 적합하다. PractRand는 스트리밍 방식으로 메모리 효율적이고 사용이 간편하며, TestU01 BigCrush는 학술적으로 가장 많이 인용되는 엄격한 표준이다. NIST SP 800-22는 2022년 학술 비판("clearly obsolete, possibly harmful") 이후 개정 중이므로 단독 사용은 권장하지 않는다.

---

## Details

### 1. NIST SP 800-22: Statistical Test Suite

#### 개요
- **정식 명칭**: NIST Special Publication 800-22 Revision 1a
- **최신 버전**: sts-2.1.2 (2014-07-09)
- **개발**: National Institute of Standards and Technology (NIST)
- **목적**: 암호학적 난수/의사난수 생성기의 통계적 검증
- **라이선스**: 퍼블릭 도메인 (미국 정부 저작물, 저작권 보호 대상 아님)

#### 15개 통계 테스트 항목

| # | 테스트명 | 설명 |
|---|---------|------|
| 1 | **Frequency (Monobit)** | 전체 시퀀스에서 0과 1의 비율이 1/2에 근접한지 검증 |
| 2 | **Block Frequency** | M-비트 블록 내에서 1의 빈도가 M/2에 근접한지 검증 |
| 3 | **Runs** | 연속된 동일 비트 시퀀스(run)의 총 개수가 기대값과 일치하는지 검증 |
| 4 | **Longest Run of Ones** | 블록 내 가장 긴 1의 연속 길이가 기대 패턴과 일치하는지 검증 |
| 5 | **Binary Matrix Rank** | 분리된 부분 행렬의 랭크를 통해 선형 의존성 검출 |
| 6 | **DFT (Spectral)** | 이산 푸리에 변환으로 주기적 특성/반복 패턴 검출 |
| 7 | **Non-overlapping Template Matching** | 비주기적 패턴의 과도한 출현 검출 |
| 8 | **Overlapping Template Matching** | 특정 길이의 1/0 연속 패턴에서 편차 검출 |
| 9 | **Maurer's Universal Statistical** | 시퀀스를 정보 손실 없이 유의미하게 압축할 수 있는지 검증 |
| 10 | **Linear Complexity** | 시퀀스가 랜덤으로 간주하기에 충분히 복잡한지 검증 |
| 11 | **Serial** | 모든 겹치는 m-비트 패턴의 빈도 비교 |
| 12 | **Approximate Entropy** | 연속 블록 길이(m과 m+1)의 빈도 패턴 비교 |
| 13 | **Cumulative Sums (Cusum)** | 누적합의 최대 이탈 검사 |
| 14 | **Random Excursions** | 랜덤 워크에서 특정 방문 빈도를 가진 사이클 수 검사 |
| 15 | **Random Excursions Variant** | 랜덤 워크 내 상태 발생 빈도 편차 검출 |

#### 필요 데이터량
- **최소**: 1,000,000 비트 (1 Mbit = 125 KB) per 시퀀스
- **권장**: 55개 이상의 시퀀스 (NIST SP 800-22 Section 4.2.2)
- **총 최소**: ~55 Mbit = ~6.9 MB

#### 설치 및 실행

```bash
# 다운로드 (공식 NIST)
wget https://csrc.nist.gov/CSRC/media/Projects/Random-Bit-Generation/documents/sts-2_1_2.zip
unzip sts-2_1_2.zip
cd sts-2.1.2

# 컴파일
make -f makefile

# 실행 (대화형)
./assess 1000000

# 또는 GitHub 포크 (더 나은 빌드 시스템)
git clone https://github.com/kravietz/nist-sts.git
cd nist-sts && make
```

**Python 래퍼** (PyPI):
```bash
pip install sp80022suite
```

#### 학술적 평가 (주의 사항)

2022년 Markku-Juhani O. Saarinen의 논문 "SP 800-22 and GM/T 0005-2012 Tests: Clearly Obsolete, Possibly Harmful" (IACR ePrint 2022/169)에서 심각한 비판이 제기되었다:

- **핵심 비판**: 가장 약한 PRNG도 쉽게 통과하여 잘못된 신뢰감을 조성
- **구체 사례**: NIST STS 참조 생성기 자체가 현대 기준으로 부적합
- **문제**: 통계적 블랙박스 테스팅이 암호 분석의 대체물로 오용됨
- **결과**: NIST가 2022년 SP 800-22 개정을 결정 (현재 진행 중)

> **결론**: 규제 준수(compliance) 목적 외에는 NIST STS 단독 사용을 권장하지 않음. PractRand/TestU01과 병행 사용 시 보완적 가치 있음.

---

### 2. TestU01 (Pierre L'Ecuyer, Universite de Montreal)

#### 개요
- **정식 명칭**: TestU01: A C Library for Empirical Testing of Random Number Generators
- **현재 버전**: TestU01-1.2.3 (2009-08-18)
- **개발**: Pierre L'Ecuyer & Richard Simard, Universite de Montreal
- **언어**: ANSI C
- **라이선스**: Apache License 2.0 (2020-11-09 업데이트)
- **저장소**: https://github.com/umontreal-simul/TestU01-2009/

#### 테스트 배터리 3단계

| 배터리 | 테스트 수 | 통계량 수 | 소요 시간 (참고: 1.7GHz Pentium 4) | 소비 난수 |
|--------|----------|----------|-----------------------------------|----------|
| **SmallCrush** | 10 | 15 | ~2분 | ~2^26 값 |
| **Crush** | 96 | 144 | ~1.7시간 | ~2^35 값 |
| **BigCrush** | 106 | 160+ | ~4시간 | ~2^38 값 (~274억) |

- 현대 CPU에서는 SmallCrush 수 초, BigCrush 1~2시간 내외

#### 설치

```bash
# 소스 빌드 (Unix/Linux/macOS)
mkdir TestU01 && cd TestU01
basedir=$(pwd)
curl -OL http://simul.iro.umontreal.ca/testu01/TestU01.zip
unzip -q TestU01.zip
cd TestU01-1.2.3
./configure --prefix="$basedir"
make -j$(nproc)
make install

# 동적 라이브러리 회피 (권장): .so 파일 제거 후 정적 링크 사용
rm -f "$basedir"/lib/*.so*
```

#### 사용법 (C 코드)

```c
#include "TestU01.h"

// 테스트 대상 RNG 함수
unsigned int my_rng(void) {
    // ... 32비트 값 반환
}

int main() {
    unif01_Gen *gen = unif01_CreateExternGenBits("MyRNG", my_rng);

    // 3단계 중 선택
    bbattery_SmallCrush(gen);   // 빠른 기본 검증
    // bbattery_Crush(gen);     // 중간 수준
    // bbattery_BigCrush(gen);  // 가장 엄격

    unif01_DeleteExternGenBits(gen);
    return 0;
}
```

```bash
# 컴파일 (정적 링크)
g++ -std=c++14 -O3 -o test_rng test_rng.c \
  -I/path/to/TestU01/include \
  -L/path/to/TestU01/lib \
  -ltestu01 -lprobdist -lmylib -lm
```

#### 주요 특성
- **입력**: 32비트 정수만 지원 (64비트 생성기는 상위/하위 32비트 각각 테스트)
- **감도 편향**: 최상위 비트에 더 민감 (값을 [0,1] 범위로 해석하므로)
- **학술 인용**: RNG 테스팅 분야에서 가장 많이 인용되는 표준
  - L'Ecuyer & Simard, "TestU01: A C Library for Empirical Testing of Random Number Generators", ACM Trans. Math. Softw., Vol.33, Art.22 (2007)
- **LinearComp 테스트**: BigCrush가 수 시간 걸릴 문제를 수 초 만에 탐지 (shift-register 계열 특화)

#### 학술 인용 기준 지위
TestU01 BigCrush는 RNG 품질 평가의 사실상 학술 표준(de facto academic standard)이다. 새로운 PRNG 알고리즘을 발표할 때 BigCrush 통과 여부를 보고하는 것이 학계 관행이다.

---

### 3. PractRand (Chris Doty-Humphrey)

#### 개요
- **정식 명칭**: PractRand (Practically Random)
- **현재 버전**: 0.95 (pre-0.95 버전은 0.94)
- **개발**: Chris Doty-Humphrey
- **언어**: C++14
- **라이선스**: 퍼블릭 도메인 (작성자가 모든 권리를 공공에 헌납)
- **소스**: https://sourceforge.net/projects/pracrand/ / https://github.com/MartyMacGyver/PractRand (포크)

#### 핵심 특성: 스트리밍 방식 테스트
- 데이터를 stdin으로 파이프하여 실시간 테스트 (메모리 효율적)
- 2의 거듭제곱 간격으로 중간 결과 출력 (128MB, 256MB, 512MB, ...)
- **사실상 무제한 테스트 길이** 지원 (32TB까지 기본 지원, 설정으로 더 확장)
- 다른 어떤 테스트 스위트보다 더 많은 편향을 탐지 (논문 기준: PractRand 1TB에서 78개 PRNG 편향 탐지 vs BigCrush 50개)

#### 테스트 배터리 구성

| 모드 | 설명 | 최적화 방향 |
|------|------|------------|
| Normal tests, standard foldings | 기본 배터리 (`get_standard_tests()`) | 시간당 감도 |
| Expanded tests, standard foldings | 확장 배터리 (`get_expanded_standard_tests()`) | 비트당 감도 |
| Normal tests, extra foldings | 추가 폴딩 배터리 (`get_folded_tests()`) | 하위 비트 집중 |
| Expanded tests, extra foldings | 전체 확장 (`get_expanded_folded_tests()`) | 최대 감도 |

**폴딩(folding)**: 하위 비트 위치에 추가 테스트를 집중하는 기법. 8/16/32/64비트 형식별 변형 적용.

#### 설치

```bash
# 다운로드 및 빌드 (Linux/macOS)
mkdir PractRand && cd PractRand
curl -OL https://downloads.sourceforge.net/project/pracrand/PractRand_0.93.zip
unzip -q PractRand_0.93.zip

# 선택: 성능 패치 (stdin 버퍼 증가)
curl -sL http://www.pcg-random.org/downloads/practrand-0.93-bigbuffer.patch | patch -p0

# 컴파일
g++ -std=c++14 -O3 -c src/*.cpp src/RNGs/*.cpp src/RNGs/other/*.cpp -Iinclude -pthread
ar rcs libPractRand.a *.o
g++ -std=c++14 -O3 -o RNG_test tools/RNG_test.cpp libPractRand.a -Iinclude -pthread
```

**참고**: 최신 버전(0.95)은 Debian/Ubuntu에서 `practrand` 패키지로도 설치 가능할 수 있으나, 소스 빌드가 가장 확실함.

#### 사용법

```bash
# 파일에서 테스트
cat random_data.bin | ./RNG_test stdin

# 프로그램 출력을 직접 파이프 (32비트 값)
./my_rng_program | ./RNG_test stdin32

# 프로그램 출력을 직접 파이프 (64비트 값)
./my_rng_program | ./RNG_test stdin64

# 바이트 스트림 (가장 일반적)
./my_rng_program | ./RNG_test stdin

# 내장 생성기 테스트
./RNG_test mt19937

# 최대 테스트 길이 지정
./my_rng_program | ./RNG_test stdin -tlmax 1TB

# 확장 테스트 세트
./my_rng_program | ./RNG_test stdin -te 1

# 멀티스레드
./my_rng_program | ./RNG_test stdin -multithreaded
```

#### 필요 데이터량 및 시간

| 테스트 단계 | 데이터량 | 대략적 시간 |
|------------|---------|------------|
| 최소 의미 있는 결과 | ~128 MB | ~3초 |
| 기본 검증 | ~1 GB | ~30초 |
| 표준 검증 | ~16 GB | ~10분 |
| 철저한 검증 | ~1 TB | ~1시간 |
| 최대 감도 | ~32 TB | ~수일 |

#### NIST/TestU01과의 차별점
- **스트리밍 방식**: 메모리를 데이터 크기에 비례하여 사용하지 않음
- **점진적 결과**: 중간 결과를 실시간으로 확인 가능
- **더 높은 감도**: PractRand 1TB 테스트가 TestU01 BigCrush보다 더 많은 편향 탐지
- **사용 편의성**: stdin 파이프만으로 어떤 생성기든 테스트 가능 (C 코드 래핑 불필요)
- **단점**: TestU01보다 더 많은 데이터 필요 (느린 PRNG에는 부적합)

---

### 4. Dieharder (Robert G. Brown, Duke University)

#### 개요
- **정식 명칭**: DieHarder: A Random Number Test Suite
- **개발**: Robert G. Brown (Duke University), Dirk Eddelbuettel, David Bauer
- **기반**: George Marsaglia의 DIEHARD (1995) 확장
- **언어**: C (GNU Scientific Library 의존)
- **라이선스**: GNU GPL v2
- **홈페이지**: https://webhome.phy.duke.edu/~rgb/General/dieharder.php

#### 테스트 구성 (30+ 테스트)

**Diehard 원본 테스트 (16개)**:
Birthdays, OPERM5, Binary Rank, Bitstream, OPSO, OQSO, DNA, Count the 1s (stream/byte), Parking Lot, Minimum Distance, Sphere, Squeeze, Sums, Runs, Craps

**STS 테스트 (NIST에서 차용)**:
Monobit, Runs, Serial

**RGB 테스트 (Brown 추가)**:
Bit Distribution, Generalized Minimum Distance, Permutations, Lagged Sum, Kolmogorov-Smirnov

**총 30+ 개별 테스트** (`dieharder -l`로 전체 목록 확인)

#### 설치

```bash
# Debian/Ubuntu
sudo apt-get install dieharder

# Fedora/RHEL/Rocky
sudo dnf install dieharder-devel

# macOS (Homebrew)
brew install dieharder

# 소스 빌드
git clone https://github.com/seehuhn/dieharder.git
cd dieharder
./autogen.sh
./configure
make && sudo make install
```

#### 사용법

```bash
# 전체 테스트 실행
dieharder -a -g 200 < random_data.bin

# stdin에서 바이너리 입력
cat random_data.bin | dieharder -g 200 -a

# /dev/urandom에서 바로 테스트
cat /dev/urandom | dieharder -g 200 -a

# 특정 테스트만 실행 (예: Birthday Spacings)
dieharder -d 0 -g 200 < random_data.bin

# ASCII 파일 입력 (정수, 한 줄에 하나)
dieharder -g 202 -f random_ints.txt -a

# 바이너리 파일 입력
dieharder -g 201 -f random_data.bin -a

# 강도 증가 (psamples 10배)
dieharder -a -g 200 -m 10 < random_data.bin

# 사용 가능한 테스트 목록
dieharder -l

# 사용 가능한 생성기 목록
dieharder -g -1
```

#### 입력 형식
- **생성기 200**: stdin 원시 바이너리
- **생성기 201**: 파일 원시 바이너리 (32비트 unsigned int)
- **생성기 202**: ASCII 파일 (헤더 포함, 정수 또는 소수)

ASCII 파일 헤더 형식:
```
#==================================================================
# generator MyDartRNG  seed = 12345
#==================================================================
type: d
count: 1000000
numbit: 32
```

#### 주의 사항
- **파일 재사용 문제**: 파일 입력 시 데이터가 부족하면 자동으로 되감기(rewind)하여 재사용 → 결과 신뢰성 저하
- **권장**: stdin 파이프로 실시간 데이터 공급
- **판정 기준**: PASS (기본), WEAK (p < 0.005 또는 > 0.995), FAIL (p < 0.000001 또는 > 0.999999)

#### 현재 상태에 대한 평가
PractRand 저자의 평가: "Pretty bad at the moment" — 기본 테스트 세트가 약하고, 일부 테스트에 알려진 버그가 있음. 그러나 설치 편의성과 직관적인 CLI가 장점.

---

### 5. 기타 도구

#### 5.1 gjrand

- **개발**: Geronimo J. (소스포지)
- **최신 버전**: 4.x (개발 중), 3.4.0 (릴리스)
- **언어**: C
- **라이선스**: GNU GPL v2
- **특징**:
  - PractRand 저자 평가: "Very good. As good as PractRand, perhaps even a hair better."
  - 테스트 감도가 TestU01보다 높고, Dieharder/NIST보다 훨씬 우수
  - RNG 생성 라이브러리 + 통계 테스트 프로그램 동시 제공
  - 다양한 분포 지원: uniform, normal, binomial, Poisson, geometric, chi-squared, exponential, gamma 등
- **한계**:
  - 상대적으로 무명 (학술 인용 거의 없음)
  - 문서화 부족
  - 사용법이 PractRand에 비해 불편

#### 5.2 ENT (Fourmilab)

- **개발**: John Walker (Fourmilab)
- **언어**: C
- **라이선스**: 퍼블릭 도메인
- **홈페이지**: https://www.fourmilab.ch/random/
- **테스트 5종**:
  1. 엔트로피 (비트/문자 정보 밀도)
  2. 카이제곱 검정 (분포 균일성)
  3. 산술 평균 (바이트 평균값, 랜덤이면 ~127.5)
  4. 몬테카를로 Pi 추정 (바이트 좌표로 Pi 계산)
  5. 직렬 상관 계수 (인접 바이트 의존성)
- **사용법**: `ent [-b] input_file`
- **평가**: 빠른 1차 스크리닝 용도. 정밀 검증에는 부족.

#### 5.3 RaBiGeTe (Random Bit Generators Tester)

- **개발**: Cristiano (altervista)
- **플랫폼**: Windows 전용 (GUI 기반)
- **테스트**: AMLS, Blocks and Gaps, Windowed Autocorrelation 등
- **특징**: 높은 설정 자유도, 멀티스레드 지원
- **한계**:
  - Windows 전용
  - PractRand 저자 평가: "Not as good as TestU01 or PractRand or gjrand"
  - CI/CD 통합 불편 (GUI 의존)

---

### 6. Dart/Flutter 연동 파이프라인

#### 6.1 Dart에서 난수 시퀀스 출력

**방법 A: 바이너리 stdout 출력 (PractRand/Dieharder용 — 권장)**

```dart
// bin/generate_random_bytes.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// 센서 엔트로피 풀을 시뮬레이션하는 간단한 예시.
/// 실제 테스트에서는 앱의 실제 RNG 파이프라인을 사용해야 함.
void main(List<String> args) {
  final rng = Random.secure();
  final bufferSize = 1024 * 1024; // 1MB 버퍼
  final buffer = Uint8List(bufferSize);

  // stdout를 바이너리 모드로 사용
  while (true) {
    for (var i = 0; i < bufferSize; i++) {
      buffer[i] = rng.nextInt(256);
    }
    stdout.add(buffer);
  }
}
```

**방법 B: 바이너리 파일 출력 (NIST STS용)**

```dart
// bin/generate_random_file.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main(List<String> args) {
  final totalBytes = int.parse(args.isNotEmpty ? args[0] : '10000000'); // 기본 10MB
  final outputPath = args.length > 1 ? args[1] : 'random_output.bin';

  final rng = Random.secure();
  final file = File(outputPath);
  final sink = file.openWrite(mode: FileMode.write);

  final bufferSize = 65536; // 64KB 버퍼
  final buffer = Uint8List(bufferSize);
  var remaining = totalBytes;

  while (remaining > 0) {
    final count = remaining < bufferSize ? remaining : bufferSize;
    for (var i = 0; i < count; i++) {
      buffer[i] = rng.nextInt(256);
    }
    sink.add(Uint8List.view(buffer.buffer, 0, count));
    remaining -= count;
  }

  sink.close();
  stderr.writeln('Generated $totalBytes bytes -> $outputPath');
}
```

**방법 C: 실제 셔플 엔진의 RNG 파이프라인 테스트**

```dart
// bin/test_shuffle_rng.dart
import 'dart:io';
import 'dart:typed_data';
// 앱의 실제 엔트로피 풀과 RNG를 import
// import 'package:personality/features/shuffle/data/datasources/entropy_pool.dart';

void main() {
  // 실제 앱에서 사용하는 RNG 파이프라인 초기화
  // final entropyPool = EntropyPool();
  // entropyPool.addSensorEntropy(...);

  final bufferSize = 1024 * 1024;
  final buffer = Uint8List(bufferSize);

  while (true) {
    for (var i = 0; i < bufferSize; i++) {
      // buffer[i] = entropyPool.nextByte();
    }
    stdout.add(buffer);
  }
}
```

#### 6.2 각 도구에 입력하는 구체적 명령어

```bash
# ============================================================
# PractRand (권장 — 가장 간편하고 가장 강력)
# ============================================================

# 기본 테스트 (stdin 바이트 스트림)
dart run bin/generate_random_bytes.dart | ./RNG_test stdin

# 최대 1TB까지 테스트
dart run bin/generate_random_bytes.dart | ./RNG_test stdin -tlmax 1TB

# 확장 테스트 세트 + 멀티스레드
dart run bin/generate_random_bytes.dart | ./RNG_test stdin -te 1 -multithreaded

# ============================================================
# TestU01 (학술 표준)
# ============================================================

# 방법 1: C 래퍼 프로그램 작성 (Dart → 파일 → C 읽기)
dart run bin/generate_random_file.dart 2000000000 /tmp/random_for_testu01.bin
# C 래퍼에서 파일 읽어 unif01 생성기로 제공 후 BigCrush 실행

# 방법 2: Dart → stdout → C 래퍼가 stdin에서 읽기
# (TestU01용 stdin 래퍼 C 프로그램 필요)

# ============================================================
# NIST STS
# ============================================================

# 파일 생성 (최소 1Mbit = 125KB, 권장 55 시퀀스 × 1Mbit)
dart run bin/generate_random_file.dart 7000000 /tmp/random_for_nist.bin

# NIST STS 실행
cd /path/to/sts-2.1.2
./assess 1000000
# 대화형 프롬프트에서 파일 경로 지정

# ============================================================
# Dieharder
# ============================================================

# stdin 바이너리 파이프 (가장 권장)
dart run bin/generate_random_bytes.dart | dieharder -g 200 -a

# 강도 증가
dart run bin/generate_random_bytes.dart | dieharder -g 200 -a -m 10

# 파일 입력 (비권장 — rewind 문제)
dart run bin/generate_random_file.dart 100000000 /tmp/random.bin
dieharder -g 201 -f /tmp/random.bin -a

# ============================================================
# ENT (빠른 1차 스크리닝)
# ============================================================
dart run bin/generate_random_file.dart 10000000 /tmp/random.bin
ent /tmp/random.bin
ent -b /tmp/random.bin   # 비트 단위 분석
```

#### 6.3 CI/CD 파이프라인 통합

```yaml
# .github/workflows/rng-quality.yml
name: RNG Quality Test

on:
  push:
    paths:
      - 'mobile/lib/features/shuffle/data/**'
      - 'mobile/lib/features/shuffle/domain/**'
  workflow_dispatch:

jobs:
  rng-quick-check:
    name: Quick RNG Screening (ENT + PractRand 1GB)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install tools
        run: |
          sudo apt-get update
          sudo apt-get install -y ent
          # PractRand 빌드
          mkdir -p /tmp/practrand && cd /tmp/practrand
          curl -OL https://downloads.sourceforge.net/project/pracrand/PractRand_0.93.zip
          unzip -q PractRand_0.93.zip
          g++ -std=c++14 -O3 -c src/*.cpp src/RNGs/*.cpp src/RNGs/other/*.cpp -Iinclude -pthread
          ar rcs libPractRand.a *.o
          g++ -std=c++14 -O3 -o RNG_test tools/RNG_test.cpp libPractRand.a -Iinclude -pthread
          sudo cp RNG_test /usr/local/bin/

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'

      - name: ENT screening
        working-directory: mobile
        run: |
          dart run bin/generate_random_file.dart 10000000 /tmp/random.bin
          ent /tmp/random.bin | tee /tmp/ent_result.txt
          # 엔트로피 7.99+ 확인 (8비트 기준)
          ENTROPY=$(grep "Entropy" /tmp/ent_result.txt | awk '{print $3}')
          echo "Entropy: $ENTROPY bits/byte"

      - name: PractRand 1GB test
        working-directory: mobile
        timeout-minutes: 10
        run: |
          dart run bin/generate_random_bytes.dart | timeout 120 RNG_test stdin -tlmax 1GB 2>&1 | tee /tmp/practrand_result.txt
          # FAIL이 없으면 통과
          if grep -q "FAIL" /tmp/practrand_result.txt; then
            echo "::error::PractRand detected failures!"
            exit 1
          fi

  rng-thorough-check:
    name: Thorough RNG Test (PractRand 256GB)
    runs-on: ubuntu-latest
    if: github.event_name == 'workflow_dispatch'
    timeout-minutes: 360
    steps:
      - uses: actions/checkout@v4

      - name: Install PractRand
        run: |
          # (위와 동일한 빌드 단계)
          mkdir -p /tmp/practrand && cd /tmp/practrand
          curl -OL https://downloads.sourceforge.net/project/pracrand/PractRand_0.93.zip
          unzip -q PractRand_0.93.zip
          g++ -std=c++14 -O3 -c src/*.cpp src/RNGs/*.cpp src/RNGs/other/*.cpp -Iinclude -pthread
          ar rcs libPractRand.a *.o
          g++ -std=c++14 -O3 -o RNG_test tools/RNG_test.cpp libPractRand.a -Iinclude -pthread
          sudo cp RNG_test /usr/local/bin/

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'

      - name: PractRand 256GB test
        working-directory: mobile
        run: |
          dart run bin/generate_random_bytes.dart | RNG_test stdin -tlmax 256GB -multithreaded 2>&1 | tee /tmp/practrand_thorough.txt
          if grep -q "FAIL" /tmp/practrand_thorough.txt; then
            echo "::error::PractRand thorough test detected failures!"
            exit 1
          fi

      - name: Upload results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: rng-test-results
          path: /tmp/practrand_thorough.txt
```

#### 6.4 테스트 자동화 스크립트 구조

```
mobile/
  bin/
    generate_random_bytes.dart    # stdout 바이너리 출력 (PractRand/Dieharder용)
    generate_random_file.dart     # 파일 출력 (NIST/ENT용)
    test_shuffle_rng.dart         # 실제 셔플 엔진 RNG 테스트
  scripts/
    rng_test_all.sh               # 전체 도구 순차 실행 스크립트
    rng_test_quick.sh             # ENT + PractRand 1GB 빠른 검증
```

```bash
#!/bin/bash
# scripts/rng_test_quick.sh — 빠른 RNG 품질 검증 (~2분)

set -euo pipefail

echo "=== Step 1: ENT Screening ==="
dart run bin/generate_random_file.dart 10000000 /tmp/rng_test.bin
ent /tmp/rng_test.bin
echo ""

echo "=== Step 2: PractRand 1GB ==="
dart run bin/generate_random_bytes.dart | timeout 120 RNG_test stdin -tlmax 1GB
echo ""

echo "=== Quick RNG test complete ==="
```

```bash
#!/bin/bash
# scripts/rng_test_all.sh — 전체 RNG 품질 검증 (~수 시간)

set -euo pipefail

echo "=== Step 1: ENT ==="
dart run bin/generate_random_file.dart 10000000 /tmp/rng_test.bin
ent /tmp/rng_test.bin

echo "=== Step 2: PractRand 16GB ==="
dart run bin/generate_random_bytes.dart | RNG_test stdin -tlmax 16GB | tee /tmp/practrand.txt

echo "=== Step 3: Dieharder (all tests) ==="
dart run bin/generate_random_bytes.dart | dieharder -g 200 -a | tee /tmp/dieharder.txt

echo "=== Step 4: NIST STS ==="
dart run bin/generate_random_file.dart 7000000 /tmp/nist_input.bin
echo "Run manually: cd /path/to/sts-2.1.2 && ./assess 1000000"

echo "=== All RNG tests complete ==="
```

---

### 7. 비교 테이블

| 기준 | NIST SP 800-22 | TestU01 | PractRand | Dieharder |
|------|---------------|---------|-----------|-----------|
| **테스트 수** | 15 | 10/96/106 (SmallCrush/Crush/BigCrush) | 가변 (데이터 크기에 따라 ~150+) | 30+ |
| **엄격도** | 낮음 (obsolete 비판) | 높음 (BigCrush) | 가장 높음 | 중간 |
| **필요 데이터** | ~7 MB (55 시퀀스 x 125KB) | ~1 GB (BigCrush) | 128 MB ~ 32 TB (점진적) | 수백 MB ~ 수 GB |
| **실행 시간** | ~10분 | 2분 / 1.7h / 4h | 3초 ~ 수일 (점진적) | ~1시간 (-a 기본) |
| **설치 난이도** | 중 (C 소스 컴파일) | 중 (configure/make) | 중 (C++ 소스 컴파일) | 쉬움 (apt/brew) |
| **라이선스** | 퍼블릭 도메인 | Apache 2.0 | 퍼블릭 도메인 | GNU GPL v2 |
| **학술 인용도** | 높음 (규제 표준) | 최고 (de facto 학술 표준) | 중간 (급성장 중) | 중간 |
| **stdin 파이프** | 불가 (파일 입력) | 불가 (C API 링크) | 지원 (핵심 기능) | 지원 |
| **스트리밍** | 불가 | 불가 | 지원 (핵심 차별점) | 지원 |
| **중간 결과** | 불가 | 불가 | 지원 (2^n 간격) | 불가 |
| **멀티스레드** | 불가 | 불가 | 지원 | 불가 |
| **CI/CD 통합** | 어려움 (대화형) | 보통 (C 래핑 필요) | 쉬움 (파이프 + exit code) | 쉬움 (CLI) |

#### 보조 도구 비교

| 기준 | gjrand | ENT | RaBiGeTe |
|------|--------|-----|----------|
| **테스트 수** | 다수 (PractRand급) | 5 | 수 개 |
| **엄격도** | 매우 높음 | 낮음 | 중간 |
| **라이선스** | GPL v2 | 퍼블릭 도메인 | 비공개 |
| **플랫폼** | Unix/Linux | 크로스 플랫폼 | Windows 전용 |
| **사용 편의성** | 낮음 | 매우 높음 | 중간 (GUI) |
| **CI/CD 통합** | 가능하나 번거로움 | 매우 쉬움 | 불가 |
| **주요 용도** | 정밀 검증 | 빠른 스크리닝 | Windows 환경 전용 |

---

## Key Findings

1. **PractRand가 가장 실용적이고 강력하다**: 스트리밍 방식, stdin 파이프 지원, 점진적 결과, 멀티스레드 지원으로 CI/CD 통합이 가장 쉽고, 감도도 가장 높다 (1TB에서 78개 PRNG 편향 탐지 vs BigCrush 50개).

2. **TestU01 BigCrush는 학술적 필수 표준이다**: 새로운 RNG 알고리즘의 품질을 보고할 때 BigCrush 통과 여부를 명시하는 것이 학계 관행이다. L'Ecuyer & Simard (2007) 논문은 이 분야에서 가장 많이 인용되는 참조이다.

3. **NIST SP 800-22는 단독 사용을 권장하지 않는다**: Saarinen (2022)의 "clearly obsolete, possibly harmful" 비판 이후 NIST가 개정을 결정했다. 가장 약한 PRNG도 쉽게 통과하여 잘못된 신뢰감을 줄 수 있다.

4. **Dieharder는 설치가 가장 쉽지만 테스트 품질이 낮다**: PractRand 저자 평가 "Pretty bad at the moment". apt/brew로 즉시 설치 가능하다는 장점은 있다.

5. **ENT는 빠른 1차 스크리닝에 최적이다**: 5개의 간단한 테스트를 수 초 만에 실행. 정밀 검증에는 부족하지만, CI의 첫 번째 관문으로 유용하다.

6. **gjrand는 숨은 강자이다**: PractRand 저자가 "perhaps even a hair better"로 평가하지만, 학술 인용이 거의 없고 문서화가 부족하여 주 도구로 권장하기 어렵다.

7. **Dart → 외부 도구 연결은 stdout 바이너리 파이프가 가장 효율적이다**: `Random.secure()` 또는 앱의 실제 RNG 파이프라인으로 바이트를 생성하여 stdout에 출력하고, Unix 파이프(`|`)로 PractRand/Dieharder에 연결하는 패턴이 가장 범용적이다.

---

## Recommendations

### 타로 셔플 엔진 최적 조합

**3-tier 검증 파이프라인을 권장한다:**

| 단계 | 도구 | 목적 | 소요 시간 | CI/CD |
|------|------|------|----------|-------|
| **Tier 1 (스크리닝)** | ENT | 엔트로피/카이제곱 빠른 확인 | ~1초 | PR마다 자동 |
| **Tier 2 (표준 검증)** | PractRand 1~16 GB | 실질적 편향 탐지 | 30초~10분 | PR마다 자동 |
| **Tier 3 (정밀 검증)** | PractRand 256GB + TestU01 BigCrush | 학술 수준 완전 검증 | 수 시간 | 수동/릴리스 전 |

### 구체적 권장 사항

1. **PractRand를 1차 도구로 채택**: 스트리밍 방식으로 CI에서 1GB 테스트를 ~30초에 실행 가능. FAIL이 없으면 통과.

2. **ENT를 빠른 스크리닝 게이트로 사용**: 엔트로피가 7.99 bits/byte 미만이면 즉시 실패 처리.

3. **TestU01 BigCrush는 릴리스 전 또는 RNG 로직 변경 시 실행**: C 래퍼 프로그램 작성이 필요하나, 학술적 신뢰도 확보를 위해 한 번은 실행해야 한다.

4. **NIST STS는 규제 준수가 필요한 경우에만**: 타로 앱에서는 암호학적 인증이 불필요하므로 우선순위 낮음.

5. **Dieharder는 선택 사항**: 설치가 쉬우므로 로컬 개발 시 빠르게 돌려볼 수 있으나, PractRand가 모든 면에서 우위.

6. **실제 RNG 파이프라인을 테스트하라**: `Random.secure()` 단독이 아니라, 센서 엔트로피 풀 → 해싱 → CSPRNG 전체 파이프라인의 출력을 테스트해야 한다 (051_Agent_entropy_quality.md 참조).

---

## References

### 공식 사이트 및 저장소
- [NIST SP 800-22 소프트웨어 다운로드](https://csrc.nist.gov/projects/random-bit-generation/documentation-and-software)
- [NIST SP 800-22 Rev 1a 문서](https://csrc.nist.gov/pubs/sp/800/22/r1/upd1/final)
- [NIST STS GitHub 포크 (kravietz)](https://github.com/kravietz/nist-sts)
- [TestU01 공식 페이지](https://simul.iro.umontreal.ca/testu01/tu01.html)
- [TestU01 GitHub 저장소](https://github.com/umontreal-simul/TestU01-2009/)
- [TestU01 라이선스 (Apache 2.0)](https://simul.iro.umontreal.ca/testu01/copyright.html)
- [PractRand SourceForge](https://pracrand.sourceforge.net/)
- [PractRand GitHub 포크 (MartyMacGyver)](https://github.com/MartyMacGyver/PractRand)
- [Dieharder 홈페이지](https://webhome.phy.duke.edu/~rgb/General/dieharder.php)
- [Dieharder GitHub (seehuhn)](https://github.com/seehuhn/dieharder)
- [gjrand SourceForge](https://gjrand.sourceforge.net/)
- [ENT (Fourmilab)](https://www.fourmilab.ch/random/)
- [RaBiGeTe](http://cristianopi.altervista.org/RaBiGeTe_MT/)

### 학술 논문 및 핵심 참조
- P. L'Ecuyer and R. Simard, "TestU01: A C Library for Empirical Testing of Random Number Generators", ACM Trans. Math. Softw., Vol.33, Art.22 (2007)
- M.-J. O. Saarinen, "SP 800-22 and GM/T 0005-2012 Tests: Clearly Obsolete, Possibly Harmful", IACR ePrint 2022/169 — https://eprint.iacr.org/2022/169
- NIST, "Decision to Revise NIST SP 800-22 Rev. 1a" (2022) — https://csrc.nist.gov/news/2022/decision-to-revise-nist-sp-800-22-rev-1a
- PractRand Tests Overview — https://pracrand.sourceforge.net/Tests_overview.txt

### 튜토리얼 및 실용 가이드
- [PCG: How to Test with TestU01](https://www.pcg-random.org/posts/how-to-test-with-testu01.html)
- [PCG: How to Test with PractRand](https://www.pcg-random.org/posts/how-to-test-with-practrand.html)
- [PractRand RNG_test man page](https://www.mankier.com/1/practrand-RNG_test)
- [Dieharder Ubuntu man page](https://manpages.ubuntu.com/manpages/xenial/man1/dieharder.1.html)
- [NIST STS Python 래퍼 (PyPI)](https://pypi.org/project/sp80022suite/)

### 관련 프로젝트 내 문서
- `docs/11_tarot_shuffle/051_Agent_entropy_quality.md` — 엔트로피 수집/추정/품질 보장 조사
- `docs/11_tarot_shuffle/050_Agent_csprng_comparison.md` — CSPRNG 비교 조사
- `docs/11_tarot_shuffle/049_Agent_shuffle_algorithm_uniformity.md` — 셔플 알고리즘 균일성 조사

## Communication Log
| # | 방향 | 상대 | 내용 요약 | 시점(단계) |
|---|------|------|----------|-----------|
| 1 | 수신 | 오케스트레이터 | 난수 품질 테스트 도구 비교 조사 요청 | 작업 시작 |
| 2 | 발신 | 오케스트레이터 | 4개 주요 + 3개 보조 도구 비교 완료, PractRand + TestU01 BigCrush 조합 권장 | 작업 완료 |

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
