---
id: "019"
type: research
title: "오케스트레이션 시스템 현황 점검 — 설계 의도 vs 구현 상태"
created: 2026-03-17
status: in-progress
traces_scope: "018"
summary: >
  docs/07_organizational_agents의 원래 에이전트 조직 설계 의도와 현재 구현
  (.claude/protocols/, CLAUDE.md, agent-memory/, 스킬 시스템)을 3개 관점에서 비교하여
  본래 취지대로 작동하는지 평가하고 갭을 식별한다.
keywords: [orchestration, audit, gap-analysis, design-vs-implementation, SOP, evaluation-loop, agent-memory]
parallel_plan:
  total_perspectives: 3
  phases:
    - phase: 1
      perspectives: [1, 2, 3]
      status: completed
      agent_numbers: ["020", "021", "022"]
  synthesis_number: "023"
  final_number: "024"
---

# 오케스트레이션 시스템 현황 점검 — 설계 의도 vs 구현 상태

## Research Overview

### Background & Motivation
이 프로젝트는 personality 포탈의 7개 전문 에이전트(psychology, mbti, enneagram, coding, flutter, tarot, uiux)를
조율하는 오케스트레이션 시스템을 설계하고 구현했다. 원래 설계는 docs/07_organizational_agents/에 17개 문서로 기록되어 있으며,
이후 여러 차례 진화하여 현재의 .claude/protocols/orchestration.md + CLAUDE.md + 스킬 시스템으로 구현되었다.
최근 RNG 난수 최적화 연구에서 Pattern E(병렬 실행)를 사용했는데, 이것이 원래 설계 의도대로 작동하는지 검증이 필요하다.

### Research Scope
- **포함**: 원래 설계(07 폴더) vs 현재 구현의 갭 분석, 실제 실행 사례 검증
- **제외**: 코드 구현 변경, 새 기능 설계 (순수 감사/분석만)

### Research Perspectives
1. **구조·패턴 설계 대조** — 오케스트레이터 패턴(A-E), 위임 판단, 에이전트 조합 가이드의 설계 vs 구현
2. **SOP·프로토콜·기억 체계 대조** — SOP 행동루프, 평가루프 HitL, 인계포맷, 페르소나, 기억 체계의 설계 vs 구현
3. **실제 실행 검증 (RNG 사례)** — 최근 Pattern E 병렬 실행의 실제 동작을 설계 의도와 비교

## Preliminary Findings
Pending parallel investigation.

## Parallel Execution Instructions

### Perspective 1: 구조·패턴 설계 대조

**조사 목표**: 원래 설계 문서에서 제안한 오케스트레이터 아키텍처 및 워크플로우 패턴이 현재 어떻게 구현되어 있는지 1:1 대조

**원래 설계 문서 (반드시 읽기)**:
1. `docs/07_organizational_agents/001_Scope_조직에이전트_전환.md` — 전체 전환 범위
2. `docs/07_organizational_agents/002_Research_조직아키텍처_오케스트레이터.md` — 오케스트레이터 연구 체크포인트
3. `docs/07_organizational_agents/003_Agent_프레임워크제약.md` — 프레임워크 제약 분석
4. `docs/07_organizational_agents/004_Agent_오케스트레이터패턴.md` — 오케스트레이터 패턴 설계
5. `docs/07_organizational_agents/005_Agent_조직화격차.md` — 조직화 격차 식별
6. `docs/07_organizational_agents/007_Synthesis_조직아키텍처연구.md` — 종합
7. `docs/07_organizational_agents/008_Research_조직아키텍처_오케스트레이터_최종.md` — 최종 연구
8. `docs/07_organizational_agents/009_Plan_오케스트레이터_아키텍처.md` — 구현 계획

**현재 구현 (반드시 읽기)**:
9. `.claude/protocols/orchestration.md` — 통합 오케스트레이션 프로토콜
10. `CLAUDE.md` — 에이전트 테이블, 위임 판단, 오케스트레이션 트리거

**비교 포인트**:
- 워크플로우 패턴 A-E: 원래 설계에서 어떻게 정의됐고 현재는 어떻게?
- 에이전트 조합 가이드: 원래 매핑 vs 현재 매핑
- 위임 판단 기준: 원래 제안 vs 현재 CLAUDE.md의 위임 판단 트리
- 프레임워크 제약(003): 식별된 제약이 현재 해결됐는지
- 조직화 격차(005): 식별된 격차가 해소됐는지
- 에이전트 스폰 프로토콜: 원래 계획 vs 현재 구현

**산출물**: docs/07_organizational_agents/020_Agent_architecture_gap.md

### Perspective 2: SOP·프로토콜·기억 체계 대조

**조사 목표**: SOP, 소통 프로토콜, 평가루프, 페르소나, 기억 체계의 설계 vs 구현 비교

**원래 설계 문서 (반드시 읽기)**:
1. `docs/07_organizational_agents/010_Research_소통프로토콜_SOP.md` — SOP 연구
2. `docs/07_organizational_agents/011_Agent_인계포맷설계.md` — 인계 포맷
3. `docs/07_organizational_agents/012_Agent_SOP행동루프.md` — Observe→Think→Act→Share
4. `docs/07_organizational_agents/013_Agent_평가루프HitL.md` — 평가루프 Human-in-the-Loop
5. `docs/07_organizational_agents/014_Synthesis_소통프로토콜SOP.md` — 종합
6. `docs/07_organizational_agents/015_Research_소통프로토콜_SOP_최종.md` — 최종 연구
7. `docs/07_organizational_agents/016_Plan_소통프로토콜SOP구현.md` — 구현 계획
8. `docs/07_organizational_agents/017_Plan_페르소나강화_기억체계.md` — 페르소나 + 기억 체계

**현재 구현 (반드시 읽기)**:
9. `.claude/protocols/orchestration.md` — SOP, 평가루프, 산출물 프로토콜 섹션
10. `.claude/agent-memory/` — 에이전트별 기억 구조
    - `_shared/_index.yaml` + `_shared/memories/001_*.yaml`
    - 각 에이전트별 `_index.yaml` + `memories/001_*.yaml`
11. 에이전트 정의 파일들: `.claude/agents/` 디렉토리 (존재 시)

**비교 포인트**:
- SOP Observe→Think→Act→Share 루프: 원래 설계 vs 현재 orchestration.md의 SOP 워커 참조
- 평가루프: 원래 HitL 설계 vs 현재 평가루프 프로토콜 (3회 제한, severity 기반)
- 인계 포맷: 원래 설계 vs 현재 에이전트 산출물 프로토콜
- 페르소나 강화: 원래 017 Plan의 도메인 전문성 → 현재 에이전트 설정(subagent_type별 tools/instructions)
- 기억 체계: 원래 017 Plan의 교차 세션 기억 → 현재 agent-memory/ YAML 구조
- 릴레이 감쇠: 원래 설계 vs 현재 구현
- 검증 기준(PSY, CODE, UX, TAROT): 원래 제안 vs 현재 구현

**산출물**: docs/07_organizational_agents/021_Agent_sop_memory_gap.md

### Perspective 3: 실제 실행 검증 (RNG 사례)

**조사 목표**: 방금 실행한 RNG 난수 최적화 연구(Pattern E 병렬)를 실제 케이스로 분석하여 설계 의도대로 작동한 것과 그렇지 않은 것 식별

**실행 사례 문서 (반드시 읽기)**:
1. `docs/11_tarot_shuffle/047_Scope_rng_optimization.md` — Scope
2. `docs/11_tarot_shuffle/048_Research_rng_optimization.md` — 체크포인트 (parallel_plan)
3. `docs/11_tarot_shuffle/049_Agent_shuffle_algorithm_uniformity.md` — P1 보고서
4. `docs/11_tarot_shuffle/050_Agent_csprng_comparison.md` — P2 보고서
5. `docs/11_tarot_shuffle/051_Agent_entropy_quality.md` — P3 보고서
6. `docs/11_tarot_shuffle/052_Agent_rng_test_tools.md` — P4 보고서
7. `docs/11_tarot_shuffle/053_Synthesis_rng_optimization.md` — 종합 보고서
8. `docs/11_tarot_shuffle/054_Research_rng_optimization_final.md` — 최종 연구

**설계 기준 (반드시 읽기)**:
9. `.claude/protocols/orchestration.md` — 패턴 E 절차, 에이전트 산출물 프로토콜
10. `CLAUDE.md` — 위임 판단, 에이전트 테이블

**검증 포인트**:
- Pattern E 절차 준수 여부: 작업 분해 → 에이전트 매핑 → 번호 배정 → 사용자 승인 → 컨텍스트 수집 → 스폰 → 모니터링 → 결과 종합
- 서브에이전트 vs Agent Teams 선택 기준 준수 여부
- 에이전트 산출물 프로토콜 준수: 스켈레톤 즉시 생성 → 점진적 업데이트 → 최종 정리
- 보고서 마커(---START_REPORT---/---END_REPORT---) 사용 여부
- 종합 보고서 품질: Cross-Analysis, Conflicting Opinions, Synergy Effects 포함 여부
- 에이전트 타입 선택: 전문 에이전트 7종 중 적절한 것이 배정됐는지
- 실제로 잘 작동한 점 vs 개선이 필요한 점

**산출물**: docs/07_organizational_agents/022_Agent_rng_case_validation.md

## Remaining Work
- [ ] Perspective 1: 구조·패턴 설계 대조
- [ ] Perspective 2: SOP·프로토콜·기억 체계 대조
- [ ] Perspective 3: 실제 실행 검증 (RNG 사례)
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
