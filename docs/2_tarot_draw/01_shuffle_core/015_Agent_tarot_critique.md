---
id: "015"
title: "타로 도메인 비평 — RWS 카드 데이터, 셔플 의식, 스프레드 설계"
category: agent
status: archived
created: 2026-03-16
summary: >
  RWS 78장 카드 데이터 정확성 확인(Major/Minor 구조 올바름). 리플 셔플 물리적 타당성
  확인. 단, 컷(cut) 의식 누락(Critical), 질문/의도 설정 프레임워크 부재(Critical),
  역방향 확률 0.5 도메인 근거 없음(Warning), 스프레드 포지션 의미 미정의(Major).
keywords: [agent-report, tarot-domain, rws, shuffle-ritual, spread, reversal]
modules: [mobile]
---

# 타로 도메인 비평

## Summary

기술 기반은 견고하나 제의적 의식 스캐폴딩이 부재. 카드 데이터 78장 정확, 리플 셔플 물리적 타당, 역방향 타이밍 올바름. 그러나 전통 타로 리딩의 필수 요소(질문 설정, 컷 의식, 포지션 해석 가이드, 봉헌/마감)가 구현되지 않음.

## Key Findings

| Finding | Severity |
|---------|----------|
| RWS 78장 구조 정확 (Major 0-21, Minor 4벌×14) | Pass |
| Strength(8)/Justice(11) RWS 표준 준수 | Pass |
| Meanings 키워드 적절하나 generic | Pass (Enhancement 권장) |
| 리플 셔플 알고리즘 물리적 타당 | Pass |
| 역방향 타이밍(post-shuffle) 올바름 | Pass |
| **컷(cut) 의식 누락** | **Critical** |
| **질문/의도 설정 프레임워크 부재** | **Critical** |
| **역방향 확률 0.5 도메인 근거 없음** | **Warning** (0.33 또는 설정 가능 권장) |
| **스프레드 포지션 의미 미정의** | **Major** |
| 스프레드 종류 2개만 (single, threeCard) | Minor |

## Recommendations

1. [P0] 셔플 후 컷 의식 추가 (CutStrategy)
2. [P0] ReadingSession 엔티티 + 질문/의도 설정 워크플로우
3. [P0] 역방향 확률 0.33 기본값 또는 사용자 설정 가능
4. [P1] 스프레드 포지션에 해석 가이드 메타데이터 추가
5. [P1] 엔트로피 모델에 제의적 내러티브 문구 연결
6. [P2] 카드 meanings에 1-2문장 해석 앵커 추가
7. [P2] 5장 스프레드 추가
8. [P3] 리딩 저널/성찰 기능

## References

- mobile/assets/data/rws_deck.json
- mobile/lib/features/shuffle/domain/strategies/
- mobile/lib/features/reading/domain/entities/spread_type.dart
- mobile/lib/features/shuffle/data/datasources/entropy_pool.dart

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
