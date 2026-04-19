---
id: "048"
type: research
title: "카드 뽑기 난수 로직 — 수학적 최적화 방법론 조사"
created: 2026-03-17
status: in-progress
traces_scope: "047"
summary: >
  현재 Fortuna CSPRNG + 센서 엔트로피 + 리플 셔플 구현의 수학적 품질을 평가하고,
  최대 랜덤성을 보장하는 무료 방법론을 학술 논문/NIST 표준 기반으로 조사한다.
keywords: [CSPRNG, Fortuna, ChaCha20, Fisher-Yates, GSR, NIST, TestU01, entropy, shuffle]
parallel_plan:
  total_perspectives: 4
  phases:
    - phase: 1
      perspectives: [1, 2, 3, 4]
      status: completed
      agent_numbers: ["049", "050", "051", "052"]
  synthesis_number: "053"
  final_number: "054"
---

# 카드 뽑기 난수 로직 — 수학적 최적화 방법론 조사

## Research Overview

### Background & Motivation
타로 앱의 카드 셔플은 사용자 경험의 핵심이며, "정말 랜덤하게 뽑혔는가"에 대한 신뢰가 서비스 품질을 좌우한다.
현재 구현은 Fortuna CSPRNG + 센서 엔트로피 + SHA-256 믹싱 + 리플 셔플 시뮬레이션으로 구성되어 있다.
이 파이프라인의 각 단계가 수학적으로 최적인지 검증하고, 더 나은 무료 대안이 있는지 조사한다.

### Research Scope
- **포함**: 셔플 알고리즘 균등성, CSPRNG 비교, 엔트로피 품질, 난수 테스트 도구
- **제외**: 유료 하드웨어 난수 생성기(HSM, TRNG 칩), 서버 사이드 난수 (클라이언트 전용)

### Research Perspectives
1. **셔플 알고리즘 수학적 균등성** — GSR 모델 수렴 이론, Fisher-Yates 증명, 78장 덱 최적 방법
2. **CSPRNG 아키텍처 비교** — Fortuna/ChaCha20/AES-CTR-DRBG/HMAC-DRBG 무료 구현체 비교
3. **엔트로피 수집·추정·품질 보장** — NIST SP 800-90B, 센서 엔트로피, min-entropy 추정
4. **난수 품질 검증 도구** — NIST SP 800-22, TestU01, PractRand, Dieharder 테스트 스위트

## Preliminary Findings

### 현재 구현 구조 (Scope 047에서 확인)
- **엔트로피**: 센서(가속도계+자이로) → SHA-256 믹싱 + Random.secure() 32바이트 → 256비트 시드
- **PRNG**: Fortuna (PointyCastle ^3.7.0), 거부 샘플링으로 modulo bias 제거
- **셔플**: 리플 셔플 시뮬레이션 3회, 1-3장씩 교차 삽입
- **잠재 약점**: nextDouble 32비트 해상도, 리플 3회 충분성 미검증, 센서 기여도 가변

## Parallel Execution Instructions

### Perspective 1: 셔플 알고리즘 수학적 균등성

**조사 목표**: 78장 타로 덱을 완전 균등 순열로 셔플하는 최적 알고리즘과 수학적 근거 조사

**구체적 조사 항목**:
1. **Fisher-Yates (Knuth) 셔플 알고리즘**:
   - 균등 분포 수학적 증명 (Knuth TAOCP Vol.2)
   - 구현 요건: CSPRNG 필요 조건, modulo bias 회피
   - 78장 덱에서 필요한 총 엔트로피 비트 수 계산 (log2(78!) ≈ 358.6비트)

2. **리플 셔플 GSR 모델**:
   - Bayer-Diaconis 1992 논문 핵심 결과: n장 카드에 (3/2)log2(n) 회 필요
   - 78장에 대한 구체적 수렴 횟수 계산
   - "cut-off phenomenon" — 갑자기 랜덤해지는 임계점
   - 현재 구현(3회)이 충분한지 정량적 평가

3. **Fisher-Yates vs 리플 셔플 비교**:
   - Fisher-Yates: O(n) 보장, 완전 균등 (CSPRNG 사용 시)
   - 리플 셔플 시뮬레이션: 물리적 사실감 but 수학적 균등성 보장 어려움
   - 하이브리드 접근: 시각적으로 리플 + 내부 로직은 Fisher-Yates

4. **웹 검색 키워드**: "Fisher-Yates shuffle uniformity proof", "Bayer Diaconis riffle shuffle mixing time", "card shuffle mathematical analysis 78 cards", "Knuth shuffle algorithm correctness"

### Perspective 2: CSPRNG 아키텍처 비교

**조사 목표**: 무료로 사용 가능한 CSPRNG 중 수학적으로 가장 안전하고 성능 좋은 것 식별

**구체적 조사 항목**:
1. **현재 사용 중: Fortuna**:
   - Ferguson & Schneier 설계 (Practical Cryptography, 2003)
   - 자동 재시딩 메커니즘, 다중 엔트로피 풀
   - PointyCastle 구현의 품질 및 알려진 이슈

2. **대안 CSPRNG**:
   - **ChaCha20**: Daniel J. Bernstein 설계, Linux /dev/urandom 채택, 속도·보안 우수
   - **AES-CTR-DRBG**: NIST SP 800-90A 표준, 하드웨어 가속(AES-NI) 지원
   - **HMAC-DRBG**: NIST SP 800-90A, 해시 기반, 소프트웨어 구현 용이
   - **xoshiro256**/xoroshiro: 비암호학적이나 통계적 품질 최상급
   - **Dart Random.secure()**: 플랫폼 OS CSPRNG 래퍼 (iOS: SecRandomCopyBytes, Android: /dev/urandom)

3. **비교 기준**:
   - 암호학적 안전성 수준 (비트 보안)
   - 통계적 품질 (TestU01 BigCrush 통과 여부)
   - 성능 (MB/s, 모바일 기기 기준)
   - Dart/Flutter 무료 구현체 존재 여부
   - 시드 크기 요건

4. **핵심 질문**: Random.secure()만으로 충분한가? Fortuna 레이어가 실질적 가치를 더하는가?

5. **웹 검색 키워드**: "ChaCha20 vs Fortuna CSPRNG comparison", "NIST SP 800-90A DRBG comparison", "best CSPRNG for card shuffling", "Dart secure random implementation", "pointycastle fortuna dart quality"

### Perspective 3: 엔트로피 수집·추정·품질 보장

**조사 목표**: 모바일 센서 엔트로피의 품질 보장 방법과 NIST 표준 준수 방안 조사

**구체적 조사 항목**:
1. **NIST SP 800-90B**: 엔트로피 소스 검증 표준
   - Min-entropy 추정 방법 (Most Common Value, Markov, Compression 등)
   - 건강 테스트 (반복 카운트 테스트, 적응 비율 테스트)
   - 모바일 센서에 적용 가능성

2. **NIST SP 800-90C**: 난수 생성 구조 권고
   - 엔트로피 소스 → conditioning → DRBG 파이프라인
   - 현재 구현(센서 → SHA-256 → Fortuna)이 이 구조에 부합하는지

3. **모바일 센서 엔트로피 관련 논문**:
   - 가속도계/자이로스코프 기반 엔트로피 수집 연구
   - 센서 데이터의 실제 min-entropy 측정 결과
   - 환경 조건별 엔트로피 가변성 (정지 상태, 움직임 중 등)

4. **현재 구현 분석 대상**:
   - `entropy_pool.dart`: SHA-256 믹싱, XOR 결합
   - `sensor_data_collector.dart`: `seedContribution = accelMagnitude * gyroZ`
   - `generateSeed()` vs `generateFallbackSeed()` 분기

5. **웹 검색 키워드**: "NIST SP 800-90B entropy estimation", "mobile sensor entropy collection paper", "accelerometer gyroscope random number generation", "min-entropy estimation smartphone sensors", "entropy source validation mobile"

### Perspective 4: 난수 품질 검증 도구

**조사 목표**: 무료로 사용 가능한 난수 품질 테스트 스위트 조사 및 적용 방법

**구체적 조사 항목**:
1. **NIST SP 800-22**: Statistical Test Suite
   - 15개 통계 테스트 항목 (빈도, 블록 빈도, 런, 행렬 순위 등)
   - 필요 데이터량, 실행 방법
   - Dart/Flutter에서 생성한 난수 시퀀스를 테스트하는 방법

2. **TestU01 (L'Ecuyer)**: 학술 표준 테스트
   - SmallCrush, Crush, BigCrush 구분
   - BigCrush: 106개 테스트, 가장 엄격
   - 설치 및 실행 방법 (C 라이브러리, 무료)

3. **PractRand**: 실용적 난수 테스트
   - 스트리밍 방식, 메모리 효율적
   - 설치 방법, 파이프라인 연결

4. **Dieharder**: George Marsaglia의 DIEHARD 확장
   - GNU/GPL, 무료
   - 30+ 통계 테스트

5. **적용 방법론**: Dart에서 난수 시퀀스를 파일로 출력 → 외부 테스트 도구에 입력하는 파이프라인

6. **웹 검색 키워드**: "TestU01 BigCrush how to use", "NIST SP 800-22 statistical test suite", "PractRand random number testing", "Dieharder random test", "best free randomness testing tools comparison"

## Remaining Work
- [ ] Perspective 1: 셔플 알고리즘 수학적 균등성
- [ ] Perspective 2: CSPRNG 아키텍처 비교
- [ ] Perspective 3: 엔트로피 수집·추정·품질 보장
- [ ] Perspective 4: 난수 품질 검증 도구
- [ ] Cross-Analysis
- [ ] Comprehensive Conclusion

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
