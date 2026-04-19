---
id: "049"
title: "셔플 알고리즘 수학적 균등성 조사"
category: agent
status: archived
created: 2026-03-17
summary: >
  78장 타로 덱의 완전 균등 셔플을 위한 알고리즘 분석. Fisher-Yates(Knuth) 셔플은 O(n)에
  완전 균등 분포(1/n!)를 수학적으로 보장. GSR 리플 셔플 모델은 (3/2)log2(n) ≈ 9.43회 필요하며
  현재 구현의 3회 리플은 TV distance ≈ 1.0으로 사실상 무작위화 효과 없음.
  권장: 내부 로직에 Fisher-Yates(CSPRNG) 적용 + 시각적으로 리플 애니메이션 유지하는 하이브리드 접근.
keywords: [agent-report, shuffle-algorithm, Fisher-Yates, GSR, Bayer-Diaconis, uniformity]
modules: [mobile/lib/features/shuffle]
---

# 셔플 알고리즘 수학적 균등성 조사

## Progress
### Completed
- [x] Fisher-Yates 균등 분포 증명 조사
- [x] Bayer-Diaconis GSR 모델 수렴 이론 조사
- [x] 78장 덱 최적 반복 횟수 계산
- [x] Fisher-Yates vs 리플 셔플 비교 분석
- [x] 현재 구현(3회 리플) 충분성 평가
- [x] 최종 결론 및 권장 사항
### Remaining
(없음)
### Current Status
조사 완료.

---

## Summary

78장 타로 카드 덱의 완전 균등 순열 보장을 위한 셔플 알고리즘을 조사했다.

**핵심 결론**: 현재 구현(3회 리플 셔플)은 수학적으로 **심각하게 불충분**하다. GSR 모델 기준 78장 덱은 최소 10회 리플 셔플이 필요하지만, 3회 후 total variation distance는 사실상 1.0(= 원래 순서와 거의 동일)이다. 내부 셔플 로직을 Fisher-Yates(CSPRNG 기반)로 교체하고, 리플 애니메이션은 시각 연출로만 유지하는 하이브리드 접근을 권장한다.

---

## Details

### 1. Fisher-Yates (Knuth) 셔플 알고리즘

#### 1.1 알고리즘 정의

Fisher-Yates 셔플(= Knuth 셔플, Durstenfeld 변형)은 유한 수열의 균등 랜덤 순열을 생성하는 알고리즘이다. Knuth의 *The Art of Computer Programming* Vol. 2, Section 3.4.2에 "Algorithm P (Shuffling)"로 수록되어 있다.

```
for i = n-1 downto 1:
    j = random integer in [0, i]  // 0 이상 i 이하
    swap(deck[i], deck[j])
```

시간복잡도: O(n), 공간복잡도: O(1) (in-place).

#### 1.2 균등 분포 수학적 증명

**정리**: Fisher-Yates 셔플은 n개 원소의 모든 n! 순열을 동일한 확률 1/n!로 생성한다.

**증명** (조건부 확률의 곱에 의한 귀납):

임의의 목표 순열 (a_1, a_2, ..., a_n)이 생성될 확률을 계산한다.

- **Step 1** (i = n-1): n개 원소 중 위치 n-1에 올 원소를 선택. j는 [0, n-1]에서 균등 → 특정 원소가 선택될 확률 = 1/n.
- **Step 2** (i = n-2): 남은 n-1개 중 위치 n-2에 올 원소를 선택. j는 [0, n-2]에서 균등 → 확률 = 1/(n-1).
- **Step k** (i = n-k): 남은 n-k+1개 중 하나 선택 → 확률 = 1/(n-k+1).
- ...
- **Step n-1** (i = 1): 남은 2개 중 하나 선택 → 확률 = 1/2.

전체 확률:
```
P(특정 순열) = (1/n) × (1/(n-1)) × ... × (1/2) = 1/n!
```

각 단계의 선택이 이전 단계와 독립(조건부 독립)이므로 확률의 곱이 성립한다. 모든 순열에 대해 이 확률이 동일하므로 분포는 완전 균등하다. **Q.E.D.**

핵심 포인트: 이 증명은 **각 단계에서 올바른 범위** [0, i]를 사용해야만 성립한다. 흔한 실수인 [0, n-1] 고정 범위를 사용하면 n^n개의 동일 확률 경로가 생기지만 n^n이 n!로 나누어떨어지지 않으므로 균등성이 깨진다.

**출처**: Knuth, D.E. *The Art of Computer Programming*, Vol. 2: Seminumerical Algorithms, 3rd ed., Section 3.4.2; UMass CS590M Handout "Correctness Proof for Fisher-Yates Shuffle"; Archive of Formal Proofs (Isabelle/HOL 기계 검증 증명).

#### 1.3 구현 요건

**CSPRNG 필요 조건**:

균등 분포 보장은 난수 생성기(RNG)가 **진정한 균등 분포**를 제공한다는 전제 하에 성립한다.

| 요건 | 설명 |
|------|------|
| **충분한 상태 공간** | log2(78!) = **382.20비트**의 엔트로피 필요. 64비트 PRNG는 2^64개 순열만 생성 가능 → 78!의 2^(-148) 비율만 도달 가능 |
| **Modulo bias 회피** | `random.nextInt(n)` 구현에서 2^32 mod n ≠ 0이면 일부 값이 미세하게 편향. 해결: rejection sampling |
| **예측 불가능성** | 카지노급이 아니더라도, 타로 앱에서 사용자가 결과를 예측할 수 없어야 함 → CSPRNG(SecureRandom) 권장 |

**엔트로피 비트 계산** (참고: 과제 명세의 358.6비트는 오류, 정확한 값은 아래):
```
log2(78!) = sum_{i=2}^{78} log2(i) = 382.20 비트
```

Stirling 근사: n·log2(n) - n·log2(e) + 0.5·log2(2πn) = 382.20 (정확히 일치).

78!은 116자리 십진수(≈ 1.132 × 10^115)이다.

**실질적 고려사항**: Dart `SecureRandom`은 OS 엔트로피 풀에서 256비트 시드를 얻어 ChaCha20/AES-CTR 스트림을 생성한다. 시드 엔트로피 256비트는 78! ≈ 2^382보다 작아 이론적으로 모든 순열을 커버하지 못하지만, 편향은 2^(256-382) = 2^(-126)으로 **천문학적으로 작다**. 타로 앱 수준에서는 완전히 충분하다.

### 2. 리플 셔플 GSR 모델

#### 2.1 Gilbert-Shannon-Reeds (GSR) 모델 정의

GSR 모델은 인간의 리플 셔플을 수학적으로 모델링한 확률 분포이다.

**절차**:
1. n장 카드 덱을 Binomial(n, 1/2) 위치에서 컷 → 왼쪽 패킷 k장, 오른쪽 패킷 n-k장.
   - P(컷 위치 = k) = C(n,k) / 2^n
2. 교차 삽입: 각 단계에서 왼쪽/오른쪽 패킷에서 떨어질 확률은 각 패킷의 남은 카드 수에 비례.
   - 왼쪽 남은 l장, 오른쪽 남은 r장일 때: P(왼쪽에서 떨어짐) = l/(l+r)

이 모델은 실제 인간 셔플을 놀랍도록 잘 근사한다 (Diaconis, 1988).

**출처**: Gilbert, E.N. & Shannon, C.E. (1955); Reeds, J.A. (1981); Wikipedia "Gilbert-Shannon-Reeds model".

#### 2.2 Bayer-Diaconis 1992: 핵심 결과

Bayer와 Diaconis의 1992년 논문 "Trailing the Dovetail Shuffle to its Lair" (*Annals of Applied Probability*, Vol. 2, No. 2, pp. 294-313)는 GSR 리플 셔플의 혼합 시간(mixing time)을 정밀하게 분석했다.

**핵심 결과**: n장 카드에 대해 m번의 GSR 리플 셔플 후 total variation distance는:

```
TV(m,n) = (1/2) × Σ_{r=1}^{n} A(n,r) × |C(2^m + n - r, n) / 2^(mn) - 1/n!|
```

여기서 A(n,r)은 **Eulerian number** (정확히 r개의 오름 시퀀스를 가진 순열의 수).

**Cutoff 공식**: n장 카드의 혼합 임계점:
```
m* = (3/2) × log2(n)
```

**Cutoff Phenomenon** (컷오프 현상):
- m < m* - c: TV ≈ 1.0 (사실상 비무작위)
- m ≈ m*: TV가 급격히 감소 (0.5 부근 통과)
- m > m* + c: TV ≈ 0, 이후 매 셔플마다 TV가 약 1/2로 감소

이 "갑자기 랜덤해지는" 현상이 컷오프의 핵심이다. 점진적 수렴이 아니라 **임계점에서의 급변**이다.

**출처**: Bayer, D. & Diaconis, P. (1992). "Trailing the Dovetail Shuffle to its Lair." *Ann. Appl. Probab.* 2(2): 294-313.

#### 2.3 52장 덱 참조값 (Bayer-Diaconis 정확한 계산)

| 셔플 횟수 m | Total Variation Distance | 비고 |
|------------|------------------------|------|
| 1 | 1.000 | |
| 2 | 1.000 | |
| 3 | 1.000 | |
| 4 | 1.000 | |
| 5 | 0.924 | |
| 6 | 0.614 | |
| **7** | **0.334** | 유명한 "7번 셔플" 결과 |
| 8 | 0.167 | |
| 9 | 0.085 | |
| 10 | 0.043 | |
| 11 | 0.022 | |
| 12 | 0.011 | |

52장 cutoff: (3/2) × log2(52) = 8.55. TV < 0.5 도달: m = 7.

**출처**: pi.math.cornell.edu Numb3rs 수학 해설 페이지; Bayer-Diaconis (1992).

#### 2.4 78장 덱 수렴 횟수 계산

```
cutoff(78) = (3/2) × log2(78) = (3/2) × 6.2854 = 9.428
```

**78장 덱 예상 TV distance** (52장 데이터의 cutoff 보편성 원리를 적용한 추정):

| 셔플 횟수 m | theta (= m - 9.43) | TV distance (추정) | 판정 |
|------------|--------------------|--------------------|------|
| 1 ~ 6 | -8.43 ~ -3.43 | ≈ 1.000 | 무작위화 없음 |
| 7 | -2.43 | ≈ 0.58 | 매우 불충분 |
| 8 | -1.43 | ≈ 0.31 | 불충분 |
| 9 | -0.43 | ≈ 0.16 | 경계선 |
| **10** | **+0.57** | **≈ 0.08** | **수용 가능** |
| 11 | +1.57 | ≈ 0.04 | 양호 |
| 12 | +2.57 | ≈ 0.02 | 우수 |

**결론**: 78장 덱은 GSR 모델 기준 **최소 10회 리플 셔플**이 필요하다 (TV < 0.1). 현재 구현의 3회는 사실상 무작위화 효과가 없다.

#### 2.5 현재 구현의 3회 리플이 왜 불충분한가 — 정량적 분석

**Rising Sequences 관점**:
- m번 GSR 셔플 후, 결과 순열의 rising sequence 수는 최대 2^m개
- 3회 셔플: rising sequence ≤ 2^3 = 8개만 가능
- 78장 무작위 순열의 평균 rising sequence 수: ≈ 39.5개 (≈ n/2)
- **8/39.5 = 20%** — 도달 가능한 순열이 전체 순열의 극소 부분집합

**엔트로피 관점**:
- 3회 GSR 셔플이 생성할 수 있는 최대 결과 수: 2^(3×78) = 2^234
- 78! ≈ 2^382.20
- **2^234 / 2^382 = 2^(-148)**: 모든 순열의 10^(-45) 비율만 도달 가능

**현재 구현의 특수성**:
현재 `RiffleShuffleStrategy`는 순수 GSR 모델이 아니다:
- 컷 위치: mid ± uniform[-2, 2] (GSR의 Binomial(n, 0.5) 대신)
- 드롭 패턴: 1~3장 균등(uniform) (GSR의 패킷 크기 비례 대신)

이 변형은 GSR보다 **약간 더 많은 혼합**을 제공하지만, 3회로는 근본적으로 불충분하다. 컷 변동이 ±2장으로 극히 제한적이고, 1~3장 드롭은 카드의 원래 순서를 대부분 보존한다.

### 3. Fisher-Yates vs 리플 셔플 비교

| 기준 | Fisher-Yates | GSR 리플 셔플 (10회) | 현재 구현 (3회 변형 리플) |
|------|-------------|---------------------|------------------------|
| **수학적 균등성** | 완벽 (1/n!, CSPRNG 전제) | 근사적 (TV ≈ 0.08) | 없음 (TV ≈ 1.0) |
| **시간 복잡도** | O(n) = O(78) | O(10n) = O(780) | O(3n) = O(234) |
| **필요 엔트로피** | 382.20비트 | ~62.85비트/회 × 10 = ~629비트 | ~19비트/회 × 3 = ~57비트 |
| **구현 난이도** | 매우 간단 (5줄) | 중간 (GSR 모델 정확 구현 필요) | 이미 구현됨 |
| **물리적 사실감** | 없음 (순수 계산) | 높음 (실제 셔플 모방) | 높음 |
| **검증 가능성** | 수학적 증명 존재 | 통계적 검증 필요 | 불충분이 증명됨 |

### 4. 다른 셔플 방법 비교

| 방법 | n=78장 혼합 시간 | 장점 | 단점 |
|------|-----------------|------|------|
| **Fisher-Yates** | 1회 (= 77 swaps) | 완전 균등, O(n), 단순 | 물리적 사실감 없음 |
| **GSR 리플** | ~10회 | 물리 모방, 잘 연구됨 | 많은 반복 필요 |
| **Overhand 셔플** | ~O(n^2 log n) ≈ 수만회 | 직관적 | 극도로 비효율 |
| **Pile 셔플** | ~5-8회 (무작위 쌓기 순서 시) | 시각적 | 단독으로는 불충분 |
| **Random transpositions** | O(n log n) ≈ ~340회 | 간단 | 비효율 |

**출처**: Pemantle (1989) overhand O(n^2 log n); Aldous & Diaconis (1986) random transpositions; blogs.sas.com 비교 분석.

### 5. 하이브리드 접근: 권장 아키텍처

디지털 카드 게임의 업계 모범 사례는 **하이브리드 접근**이다:

```
[사용자 경험 레이어]          [내부 로직 레이어]
 리플 애니메이션               Fisher-Yates (CSPRNG)
 (시각 + 촉각 피드백)          (수학적 균등성 보장)
         ↓                          ↓
   화면에 보여지는               실제 카드 순서를
   물리적 셔플 동작               결정하는 알고리즘
```

1. **사용자가 셔플 제스처를 수행** → 리플 애니메이션 재생 (제의적 경험)
2. **애니메이션 완료 시점에** → Fisher-Yates(SecureRandom)로 내부 덱 순서 결정
3. 사용자에게는 "물리적으로 셔플한 것처럼" 보이지만, 실제 결과는 **수학적으로 완전 균등**

이 접근의 장점:
- 제의적 UX 보존 (타로의 핵심 가치)
- 수학적 균등성 100% 보장
- 구현 단순 (Fisher-Yates는 5줄)
- CSPRNG 엔트로피만으로 충분 (리플 반복 횟수 무관)

### 6. 최신 연구 동향

#### 6.1 Diaconis & Fulman (2023): *The Mathematics of Shuffling Cards*
AMS 출판. 30년간의 셔플 수학 연구를 집대성. 2026년 1월 AMS Bulletin Vol. 63에 리뷰 게재.

#### 6.2 Cutoff 보편성 (2025)
Sellke, Shi, Wang (2025). "Universality of Cutoff for Riffle Shuffling" (arXiv:2510.22783). GSR 모델뿐 아니라 일반적인 리플 셔플 분포에서도 cutoff 현상이 보편적으로 나타남을 증명.

#### 6.3 비대칭 리플 셔플 (2022)
"Cutoff for the Asymmetric Riffle Shuffle" (*Annals of Probability*, Vol. 50, No. 6). 비대칭 이항 컷(p ≠ 0.5)에서도 cutoff가 발생함을 증명.

#### 6.4 Lemire의 Modulo Bias 회피 (2019)
Daniel Lemire. "Fast Random Integer Generation in an Interval" (*ACM Trans. on Modeling and Computer Simulation*, 2019). Modulo 연산 없이 rejection sampling의 기대 재시도 < 1회인 효율적 방법 제시.

---

## Key Findings

1. **log2(78!) = 382.20비트** (과제 명세의 358.6비트는 오류). 78장 덱의 완전 균등 셔플에는 최소 382비트의 엔트로피가 필요.

2. **현재 3회 리플 셔플은 수학적으로 무효**: GSR 모델 기준 78장에 (3/2)log2(78) ≈ 9.43회 필요. 3회는 cutoff 이전 6.4단계나 떨어져 있어 TV ≈ 1.0 (사실상 원래 순서 유지). 도달 가능한 순열은 전체의 2^(-148) 비율에 불과.

3. **Fisher-Yates는 수학적으로 완벽**: 조건부 확률의 곱 (1/n)(1/(n-1))...(1/2) = 1/n!로 모든 순열이 동일 확률. O(n), in-place, CSPRNG와 결합 시 완전 균등 보장.

4. **하이브리드 접근이 최적**: 시각적 리플 애니메이션(제의적 UX) + 내부 Fisher-Yates(수학적 보장). 디지털 카드 게임의 업계 표준.

5. **CSPRNG 256비트 시드는 실용적으로 충분**: 이론적으로 382비트 미만이지만, 편향은 2^(-126)으로 감지 불가능한 수준.

---

## Recommendations

### 즉시 적용 (Critical)

1. **내부 셔플 로직을 Fisher-Yates로 교체**
   - `ShuffleStrategy` 인터페이스에 `FisherYatesShuffleStrategy` 추가
   - `SecureRandom` 사용 (현재 프로젝트에 이미 존재)
   - 리플 애니메이션은 순수 시각 효과로 분리

2. **하이브리드 아키텍처 구현**
   - 애니메이션 레이어: 기존 `RiffleShuffleStrategy` 기반 (시각용)
   - 로직 레이어: `FisherYatesShuffleStrategy` (실제 순서 결정)
   - 애니메이션 완료 → Fisher-Yates 결과로 덱 교체

### 권장 (Important)

3. **기존 리플 전략을 시뮬레이션 전용으로 리팩토링**
   - `RiffleShuffleStrategy`의 `shuffle()` 반환값은 애니메이션 시퀀스 생성용으로만 사용
   - 실제 카드 선택에는 Fisher-Yates 결과를 사용

4. **entropyBits 필드 정확도 개선**
   - 현재 `entropyBits: 256` 하드코딩 → 실제 사용된 엔트로피 비트 수 계산
   - Fisher-Yates 사용 시: sum(log2(i) for i in 2..78) = 382.20비트 기록

### 향후 고려 (Nice-to-have)

5. **리플 횟수를 10회로 증가하는 대안**
   - Fisher-Yates 교체 대신 리플 횟수만 10으로 증가하는 것은 차선책
   - GSR 모델을 정확히 구현해야 하며 (현재 구현은 변형), 검증 비용 높음
   - Fisher-Yates 교체가 더 단순하고 더 강력한 보장 제공

6. **셔플 품질 통계 테스트 추가**
   - Chi-squared test: 작은 덱(n=5)에서 모든 120 순열의 균등성 검증
   - Kolmogorov-Smirnov test: 위치별 분포 균등성

---

## References

### 교과서 & 학술 논문
1. Knuth, D.E. *The Art of Computer Programming*, Vol. 2: Seminumerical Algorithms, 3rd ed., Section 3.4.2 "Algorithm P (Shuffling)".
2. Bayer, D. & Diaconis, P. (1992). "[Trailing the Dovetail Shuffle to its Lair](https://projecteuclid.org/journals/annals-of-applied-probability/volume-2/issue-2/Trailing-the-Dovetail-Shuffle-to-its-Lair/10.1214/aoap/1177005705.full)." *Ann. Appl. Probab.* 2(2): 294-313.
3. Diaconis, P. & Fulman, J. (2023). *The Mathematics of Shuffling Cards*. AMS. ISBN: 9781470463038.
4. Trefethen, L.N. & Trefethen, L.M. (2000). "[How Many Shuffles to Randomize a Deck of Cards?](https://people.maths.ox.ac.uk/trefethen/publication/PDF/2000_87.pdf)" *Proc. Royal Soc. London A*, 456: 2561-2568.
5. Sellke, M., Shi, J. & Wang, J. (2025). "[Universality of Cutoff for Riffle Shuffling](https://arxiv.org/abs/2510.22783)." arXiv:2510.22783.
6. Lemire, D. (2019). "Fast Random Integer Generation in an Interval." *ACM Trans. on Modeling and Computer Simulation* 29(1): 1-12.
7. Pemantle, R. (1989). "Randomization time for the overhand shuffle." *J. Theor. Probab.* 2(1): 37-49. [O(n^2 log n)]

### 온라인 리소스
8. [Correctness Proof for Fisher-Yates Shuffle](https://people.cs.umass.edu/~phaas/CS590M/handouts/Fisher-Yates-proof.pdf) — UMass CS590M Handout.
9. [Fisher-Yates shuffle — Archive of Formal Proofs](https://www.isa-afp.org/entries/Fisher_Yates.html) — Isabelle/HOL 기계 검증 증명.
10. [The intuition behind Fisher-Yates shuffling](https://eli.thegreenplace.net/2010/05/28/the-intuition-behind-fisher-yates-shuffling) — Eli Bendersky.
11. [Shuffling (Coding Horror)](https://blog.codinghorror.com/shuffling/) — 디지털 카드 게임 셔플 보안 사례.
12. [Card shuffling algorithms, good and bad](https://possiblywrong.wordpress.com/2014/12/01/card-shuffling-algorithms-good-and-bad/) — 시각화를 통한 bias 분석.
13. [Overhand shuffle vs riffle shuffle (SAS)](https://blogs.sas.com/content/iml/2018/09/19/overhand-shuffle-riffle.html) — 혼합 효율 비교.
14. [Cornell/Numb3rs: Card Shuffling Mathematics](https://pi.math.cornell.edu/~numb3rs/spulido/Numb3rs_season5/Numb3rs_519.html) — 52장 TV distance 표, GSR 모델 설명.
15. [Card Shuffling — LibreTexts Statistics](https://stats.libretexts.org/Bookshelves/Probability_Theory/Introductory_Probability_(Grinstead_and_Snell)/03:_Combinatorics/3.03:_Card_Shuffling) — Eulerian number 기반 정확한 TV 공식.

### 현재 구현 파일
16. `mobile/lib/features/shuffle/domain/strategies/riffle_shuffle_strategy.dart` — 3회 변형 리플 셔플.
17. `mobile/lib/features/shuffle/domain/strategies/shuffle_strategy.dart` — ShuffleStrategy 인터페이스.
18. `mobile/lib/features/shuffle/domain/entities/shuffle_config.dart` — shuffleCount 기본값 3.

---

## Communication Log
| # | 방향 | 상대 | 내용 요약 | 시점(단계) |
|---|------|------|----------|-----------|
| 1 | 수신 | orchestrator | 78장 타로 덱 셔플 균등성 조사 과제 수령 | 시작 |
| 2 | 발신 | orchestrator | 조사 완료: Fisher-Yates 권장, 3회 리플 불충분, 하이브리드 접근 제안 | 완료 |

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
