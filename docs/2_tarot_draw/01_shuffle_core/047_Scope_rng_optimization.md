---
id: "047"
type: scope
title: "카드 뽑기 난수 로직 검토 및 최적화"
created: 2026-03-17
complexity: simple
research_needed: true
research_reason: "수학적으로 최대 랜덤성을 보장하는 무료 방법론을 학술 논문/NIST 표준 기반으로 조사 필요"
auto_run: true
intent: >
  현재 타로 카드 셔플의 난수 생성 파이프라인(센서 엔트로피 → SHA-256 → Fortuna CSPRNG → 리플 셔플)을
  수학적으로 검증하고, 더 높은 랜덤성을 보장하는 무료 방법론을 연구하여 적용 방안을 도출한다.
summary: >
  단일 영역(shuffle 난수 레이어). 현재 Fortuna CSPRNG + 센서 엔트로피 + SHA-256 믹싱 구조의
  수학적 품질을 평가하고, NIST/학술 논문 기반 최적 방법론을 조사하여 개선점을 식별한다.
keywords: [CSPRNG, Fortuna, entropy, Fisher-Yates, randomness, NIST, DIEHARD, TestU01]
---

# 카드 뽑기 난수 로직 검토 및 최적화

## 작업 목표
- 현재 셔플 난수 파이프라인의 수학적 품질 평가
- 최대 랜덤성을 보장하는 무료 방법론 조사 (논문/표준 기반)
- 비용 0으로 구현 가능한 개선 방안 도출
- 성공 기준: 수학적으로 증명된 균등 분포 보장

## 접근 방향
외부 학술 자료 및 NIST 표준을 조사하여 현재 구현의 강/약점을 식별하고,
무료로 적용 가능한 최적 방법론을 선택지로 제시한다.

## 현재 구현 분석

### 엔트로피 소스
| 소스 | 구현 | 비트 수 |
|------|------|---------|
| 센서 (가속도계+자이로) | `SensorDataCollector` → `EntropyPool` | 가변 (≥10 샘플) |
| OS CSPRNG | `Random.secure()` → 32바이트 | 256비트 |
| 믹싱 | SHA-256(pool ∥ systemBytes) | 256비트 시드 |

### PRNG
- **알고리즘**: Fortuna (PointyCastle ^3.7.0)
- **시드**: 32바이트 (256비트)
- **nextInt 편향 제거**: 거부 샘플링 적용 ✓
- **nextDouble 해상도**: 32비트 (2^32 구별값) — 53비트 mantissa 미활용

### 셔플 알고리즘
- **리플 셔플**: 덱 이분할 → 교차 삽입 (1-3장씩)
- **반복 횟수**: config.shuffleCount = 3 (기본값)
- **78장 덱에 3회가 충분한지**: GSR 모델 기준 검증 필요

### 식별된 잠재 약점
1. 리플 셔플 반복 횟수 — 78장에 대한 수학적 최적 횟수 미검증
2. nextDouble 32비트 해상도 — 카드 셔플에는 충분하나 일반적 품질 관점에서 차선
3. 센서 엔트로피 품질 — gyroZ ≈ 0일 때 기여도 저하
4. entropyBits 하드코딩 (256) — 실제 엔트로피 추정치 미반영

## Research 판단
- **판단**: 필요
- **근거**: 수학적으로 증명된 최적 셔플 방법론(Fisher-Yates 변형, 리플 셔플 수렴 이론),
  CSPRNG 비교(Fortuna vs ChaCha20 vs AES-CTR), 엔트로피 추정 방법 등
  외부 학술 자료 조사가 핵심
- **파이프라인**: S → R (research까지만, 사용자 요청)

## 연구 가이드
- **조사 대상 파일**: `fortuna_random_wrapper.dart`, `entropy_pool.dart`, `sensor_data_collector.dart`, `riffle_shuffle_strategy.dart`
- **핵심 질문**:
  1. 78장 카드 덱의 완전 균등 순열을 보장하는 셔플 알고리즘과 최소 반복 횟수는?
  2. Fortuna vs ChaCha20 vs 기타 CSPRNG — 무료 구현체 중 최적은?
  3. Fisher-Yates (Knuth) 셔플 vs 리플 시뮬레이션 — 균등성 관점 트레이드오프
  4. 센서 엔트로피 추정 및 품질 보장 방법론 (NIST SP 800-90B)
  5. nextDouble 53비트 해상도 구현 방법
  6. 무료로 사용 가능한 난수 품질 테스트 스위트 (TestU01, DIEHARD, NIST SP 800-22)

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
