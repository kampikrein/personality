---
id: "053"
title: "카드 뽑기 난수 최적화 — Synthesis Report"
category: report
status: archived
created: 2026-03-17
summary: >
  4개 관점(셔플 알고리즘, CSPRNG, 엔트로피, 테스트 도구) 병렬 조사의 종합 보고서.
  현재 구현에 3개 Critical급 문제(3회 리플 불충분, Fortuna 불완전, gyroZ 곱셈 결함)를 발견.
  Fisher-Yates 교체 + Random.secure() 직접 사용 + 센서 공식 수정이 핵심 권장 사항.
keywords: [parallel-synthesis, research, RNG, shuffle, CSPRNG, entropy, testing]
modules: [mobile/lib/features/shuffle]
---

# 카드 뽑기 난수 최적화 — Synthesis Report

## Team Composition & Individual Reports

| # | Role | Agent Type | Report | Status |
|---|------|-----------|--------|--------|
| 1 | 셔플 알고리즘 수학적 균등성 | general-purpose | [049_Agent_shuffle_algorithm_uniformity.md](./049_Agent_shuffle_algorithm_uniformity.md) | complete |
| 2 | CSPRNG 아키텍처 비교 | general-purpose | [050_Agent_csprng_comparison.md](./050_Agent_csprng_comparison.md) | complete |
| 3 | 엔트로피 수집·추정·품질 | general-purpose | [051_Agent_entropy_quality.md](./051_Agent_entropy_quality.md) | complete |
| 4 | 난수 품질 검증 도구 | general-purpose | [052_Agent_rng_test_tools.md](./052_Agent_rng_test_tools.md) | complete |

---

## Cross-Analysis

### Common Findings

1. **Random.secure()의 충분성**: P1(셔플), P2(CSPRNG), P3(엔트로피) 모두 독립적으로 "Random.secure()가 이미 최적의 OS CSPRNG"이라는 결론에 도달. Fortuna 레이어가 추가 가치 없음에 합의.

2. **현재 구현의 근본적 문제**: P1은 셔플 알고리즘 자체가, P3는 엔트로피 소스가 각각 독립적으로 치명적 문제를 지님. 두 문제가 합산되어 현재 시스템은 "겉으로는 정교하지만 실질적으로 불충분"한 상태.

3. **78장 덱의 엔트로피 요구량 일관성**: P1은 log2(78!) = 382.20비트, P2는 382.2비트로 일치. 현재 256비트 시드의 이론적 한계를 인정하되, 편향 2^(-126)은 실용적으로 무시 가능하다는 점에도 합의.

### Conflicting Opinions

**센서 엔트로피의 존재 가치**:
- P2: "보안적 추가 가치는 미미, UX 연출용으로만 유지"
- P3: "NIST 구조에 부합하는 좋은 설계, 개선하면 실질적 가치"

→ **리드 판단**: 센서 엔트로피는 타로 앱의 "제의적 경험"과 연결되므로 완전 제거보다는 **P3의 개선안(6축 독립, 건강 테스트)을 적용하되, 보안 의존도는 낮추는** 것이 최선. Random.secure()를 주 엔트로피원으로 사용하고 센서는 보조+UX 역할.

### Synergy Effects

1. **P1 + P2 시너지**: P1의 "Fisher-Yates + CSPRNG" 권장과 P2의 "Random.secure() 직접 사용" 권장을 결합하면, `Random.secure()`를 Fisher-Yates의 난수원으로 직접 사용하는 가장 단순한 아키텍처가 도출된다. Fortuna 래퍼, 센서 엔트로피 풀, 리플 셔플 로직 모두 교체 가능.

2. **P3 + P4 시너지**: P3의 "센서 엔트로피 품질 모니터링 필요"와 P4의 "PractRand CI 파이프라인"을 결합하면, 센서 엔트로피 유무에 따른 RNG 출력 품질 차이를 정량적으로 검증할 수 있다.

3. **하이브리드 아키텍처의 전체상**: P1(Fisher-Yates 내부 로직) + P2(Random.secure() 직접 사용) + P3(센서 UX 유지, 건강 테스트 추가) + P4(PractRand 검증)을 통합하면:
   ```
   [UX 레이어]                    [로직 레이어]
   리플 애니메이션 +               Fisher-Yates(Random.secure())
   센서 수집 UI(제의적 경험)       + 선택적 센서 추가 믹싱
         ↓                              ↓
   시각·촉각 피드백               수학적 균등 순열 보장
                                        ↓
                                 PractRand CI 검증
   ```

---

## Comprehensive Conclusion

현재 타로 셔플 엔진은 구조적으로 정교하지만(센서→SHA-256→Fortuna→리플), 수학적 검증 결과 3개 Critical급 문제를 포함하고 있다. 가장 비용 효율적인 해결은 **내부 로직 단순화**(Fisher-Yates + Random.secure())이며, 이는 현재보다 더 단순하면서 수학적으로 더 강력한 보장을 제공한다.

### Key Findings

1. **[Critical] 3회 리플 셔플은 수학적으로 무효** — TV distance ≈ 1.0, 최소 10회 필요 (P1)
2. **[Critical] PointyCastle Fortuna는 불완전 구현** — 32-풀 누적기 미구현, 실질적 AES-CTR에 불과 (P2)
3. **[Critical] seedContribution 곱셈 결함** — gyroZ≈0 시 센서 엔트로피 소멸, ~60% 상황 (P3)
4. **[High] 건강 테스트 부재** — 센서 실패/저하 런타임 미탐지 (P3)
5. **[High] NIST STS 단독 사용 부적합** — 학계 "clearly obsolete" 비판 (P4)
6. **[Medium] minSamples=10 불충분** — 정지 상태에서 축적 엔트로피 미달 (P3)
7. **[Medium] nextDouble 32비트 해상도** — 카드 셔플에 실용적 영향 없으나 차선 (P2)

### Recommended Actions (우선순위순)

1. **Fisher-Yates(Random.secure()) 교체** — 리플 셔플을 애니메이션 전용으로 분리, 실제 카드 순서는 Fisher-Yates로 결정
2. **Fortuna 레이어 제거** — Random.secure() 직접 사용, pointycastle 의존성 제거
3. **센서 기여도 공식 수정** — 6축 독립 활용, 곱셈 제거
4. **경량 건강 테스트 추가** — RCT + APT 실시간 적용
5. **PractRand CI 파이프라인 구축** — PR마다 ENT + PractRand 1GB 자동 검증
6. **minSamples 증가** — 10 → 50~100

---

## References

개별 보고서 참조 중복 제거 통합:

### 핵심 학술 논문
- Bayer & Diaconis (1992). "Trailing the Dovetail Shuffle to its Lair." Ann. Appl. Probab. 2(2): 294-313
- Knuth, D.E. TAOCP Vol. 2, Section 3.4.2 "Algorithm P (Shuffling)"
- Ferguson & Schneier (2003). Practical Cryptography — Fortuna 설계
- Shepherd et al. (2025). "Entropy Collapse in Mobile Sensors." arXiv 2502.09535
- L'Ecuyer & Simard (2007). "TestU01." ACM Trans. Math. Softw. 33(4): Art.22
- Saarinen (2022). "SP 800-22: Clearly Obsolete, Possibly Harmful." IACR ePrint 2022/169

### NIST 표준
- SP 800-90A (DRBG), SP 800-90B (엔트로피 소스), SP 800-90C (RBG 구조), SP 800-22 (통계 테스트)

### Dart/Flutter 패키지
- pointycastle ^3.7.0 (Fortuna), cryptography ^2.9.0 (ChaCha20), Dart SDK Random.secure()

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
