---
id: "024"
type: research
title: "오케스트레이션 시스템 현황 점검 — 설계 의도 vs 구현 상태 최종 연구"
created: 2026-03-17
traces_scope: "018"
summary: >
  docs/07 원래 설계(17개 문서) vs 현재 구현의 갭 분석 최종 보고. 설계 대비 반영율 ~85%.
  Critical 0건, High 4건. 핵심 철학(패턴 A-D, SOP O→T→A→S, severity 평가, 기억 체계)은
  충실히 구현. 3가지 구조적 진화(패턴 E 신설, 에이전트 7개 확대, 프로토콜 기반 전환)는
  합리적. RNG 병렬 연구에서 Pattern E 9단계 중 7단계 설계대로 작동 검증.
keywords: [orchestration, audit, gap-analysis, pattern-E, SOP, agent-memory, design-vs-implementation]
---

# 오케스트레이션 시스템 현황 점검 — 최종 연구

## Research Overview

### Background & Motivation
personality 프로젝트의 7개 전문 에이전트를 조율하는 오케스트레이션 시스템은 docs/07_organizational_agents에 17개 문서로 설계된 후, 여러 차례 진화하여 현재의 .claude/protocols/orchestration.md + CLAUDE.md + 스킬 시스템으로 구현되었다. 최근 RNG 난수 최적화 연구에서 Pattern E(병렬 실행)를 사용한 것을 계기로, 원래 설계 의도대로 시스템이 작동하는지 종합 점검하였다.

### Research Scope
- **포함**: 원래 설계(07 폴더 17개 문서) vs 현재 구현 1:1 대조, RNG 연구 실제 실행 검증
- **제외**: 코드 구현 변경, 새 기능 설계

### Research Perspectives
1. 구조·패턴 설계 대조 (아키텍처, 패턴 A-E, 위임 판단, 프레임워크 제약, 격차)
2. SOP·프로토콜·기억 체계 대조 (행동루프, 평가루프, 인계, 페르소나, agent-memory)
3. 실제 실행 검증 — RNG 병렬 연구 사례 (Pattern E 9단계, 산출물 프로토콜, 종합 보고서)

### Related Documents
- Scope: [018_Scope_orchestration_audit.md](./018_Scope_orchestration_audit.md)
- Checkpoint: [019_Research_orchestration_audit.md](./019_Research_orchestration_audit.md)
- Agent reports: [020](./020_Agent_architecture_gap.md), [021](./021_Agent_sop_memory_gap.md), [022](./022_Agent_rng_case_validation.md)
- Synthesis: [023_Synthesis_orchestration_audit.md](./023_Synthesis_orchestration_audit.md)

---

## Perspective 1: 구조·패턴 설계 대조

### Status Analysis
원래 설계(001, 003-009)에서 정의한 오케스트레이터 아키텍처의 핵심 아이디어는 현재 구현에 대부분 충실하게 반영되었다.

### Detailed Findings

**패턴 A-D**: 이름, 정의, 트리거 조건, 가드레일 모두 완전 보존. severity 기반 verdict 판정이 추가되어 정교화.

**패턴 E (병렬 실행)**: 원래 설계(004, 008)에서 "Claude Code 동시 실행 불가"로 기각했으나, 003(KF-6, KF-7)에서 기술적 가능성을 확인한 바탕으로 복원. 상세 9단계 실행 절차 + Agent Teams 폴백 메커니즘을 갖춤.

**에이전트 확대**: 5개(psychology, mbti, enneagram, coding, uiux) → 7개(+flutter-expert, +tarot-expert). 조합 가이드도 자연스럽게 확장.

**오케스트레이터 아키텍처 전환**: 별도 에이전트 파일(`.claude/agents/orchestrator.md`) → CLAUDE.md 위임 판단 + orchestration.md 프로토콜. 더 경량이고 지연 로딩으로 토큰 절약.

**프레임워크 제약 해결**: 003에서 식별한 8건 중 모두 해결 또는 적절히 우회.

**조직화 격차 해소**: 005의 7대 격차 중 3건 해소, 2건 부분 해소, 1건 미확인, 1건 미해소(교차 기억 프로토콜 문서화).

### Summary
패턴 A-D 완전 보존, 패턴 E 합리적 확장, 에이전트 7개 확대, 프로토콜 기반 전환. Critical 갭 0건.

---

## Perspective 2: SOP·프로토콜·기억 체계 대조

### Status Analysis
설계 대비 구현 반영율 약 85%. 핵심 철학은 완전 보존, work-orders 인프라 제거가 가장 큰 구조적 변화.

### Detailed Findings

**SOP 행동루프 (O→T→A→S)**: 7개 에이전트 모두에 `# SOP: 행동 루프` 섹션이 존재. 4단계 각각의 구체적 동작이 역할별로 변형 적용됨. 완전 반영.

**평가루프 (HitL)**: severity 기반 verdict, overall_score, previous_iterations, conditional_pass 모두 구현. 검증 기준 PSY/CODE/UX 완전 일치 + TAROT 신설. **단, HitL 트리거가 7→4개 축소.** H3(동일 fail 반복 감지)와 H6(유형 불명확) 미명시.

**인계 포맷**: handover.yaml 독립 파일 대신 산출물 프로토콜이 인계 역할 흡수. 구조적 대체이며 기능적으로 동등하나, constraints/context_level/status 필드가 누락.

**페르소나 강화**: 7개 에이전트 모두 Goal(미션+성공지표) + Backstory(전문영역+조직기여) 완비. 설계 대비 완전 반영 + 초과 달성.

**기억 체계**: `_shared/` 공유 기억 + 개별 기억 모두 설계대로 구현. 실제 운영 중(공유 1건 + 개별 7건+). `related_memories` 교차 참조도 실제 사용됨.

**릴레이 감쇠**: confidence 한 단계 감쇠 + 3단계 원본 확인 + 파이프라인 전용. 완전 반영.

**맥락 보전**: 설계보다 발전적 — 4단계 복구 프로토콜 + 리드 감시 추가.

### Summary
SOP, 페르소나, 기억 체계는 완전 반영~초과 달성. HitL 트리거 축소(High)와 work-orders 인프라 제거(구조적 변화, 단순화 방향)가 주요 차이.

---

## Perspective 3: 실제 실행 검증 (RNG 사례)

### Status Analysis
RNG 난수 최적화 병렬 연구(047-054)를 Pattern E 9단계와 산출물 프로토콜 기준으로 검증.

### Detailed Findings

**Pattern E 9단계 준수 현황**:

| 단계 | 판정 | 비고 |
|------|------|------|
| 1. 작업 분해 | **일치** | research 유형, 관점별 분해, 4명(최적 범위 3-5) |
| 2. 에이전트 매핑 | **일치** | general-purpose 적절 (전문 에이전트 영역 밖) |
| 3. 번호 사전 배정 | **일치** | 049-054 연속 배정, 충돌 없음 |
| 4. 사용자 승인 | **조건부 일치** | auto_run과 승인 규칙 간 우선순위 미정의 |
| 5. 컨텍스트 수집 | **일치** | 관점별 파일 경로, 검색 키워드까지 제공 |
| 6. 팀 구성/스폰 | **일치** | 서브에이전트 모드 적절 (조사/분석) |
| 7. 모니터링 | **일치** | 서브에이전트 = 별도 모니터링 불필요 |
| 8. 결과 종합 | **부분 일치** | Communication Timeline 누락 |
| 9. 사용자 보고 | **일치** | 최종 문서에 모든 정보 포함 |

**에이전트 산출물 프로토콜**: 4개 보고서 모두 frontmatter, Progress, Summary, Details, Key Findings, Recommendations, References, Communication Log 완비. 높은 준수도.

**종합 보고서(053)**: Cross-Analysis의 실질적 가치 — Common Findings(Random.secure() 합의), Conflicting Opinions(센서 엔트로피 P2 vs P3 + 리드 절충), Synergy Effects(하이브리드 아키텍처 도출). Communication Timeline만 누락.

**최종 연구(054)**: 자기 완결적. 개별 보고서 없이도 핵심 결론과 근거 파악 가능. Unresolved Items 3건 적절히 관리.

### Strengths (잘 작동한 점)
- 관점 분해의 독립성과 완전성 (RNG 파이프라인 4레이어에 정확히 매핑)
- 에이전트 보고서의 높은 품질 (학술 논문 수준 참조)
- 교차 분석의 실질적 가치 ("더 단순한 것이 더 강력하다" 공통 패턴 도출)
- 번호 사전 배정 시스템의 정확한 작동
- Scope → Research 자연스러운 전환

### Weaknesses (개선 필요 점)
- auto_run과 사용자 승인 규칙 간 우선순위 모호
- 서브에이전트 모드의 Communication Timeline 규칙 부재
- 점진적 업데이트의 서브에이전트 모드 특수 지침 미비

### Summary
**전체적으로 프로토콜 설계 의도가 잘 작동한 사례.** 9단계 중 7단계 완전 일치, 2단계에서 사소한 불일치. 실제 산출물의 품질이 높아 프로토콜의 실효성이 입증됨.

---

## Cross-Analysis

### Inter-Perspective Relationships

```
P1 (구조·패턴)             P2 (SOP·기억)
   패턴 A-E 완전 ────────→ SOP/평가루프가 패턴 내에서 작동
   에이전트 7개 ──────────→ 7개 모두 페르소나+기억 완비
         │                       │
         └──── 통합 관점 ────────┘
                    ↓
              P3 (실제 검증)
              Pattern E 실행으로
              P1의 설계 + P2의 프로토콜이
              실제로 작동함을 검증
```

### Common Patterns

1. **"설계보다 단순하게, 하지만 핵심은 보존"**: work-orders 인프라 제거, Level 1/2/3 번호 제거, handover.yaml 통합 — 모두 복잡도를 줄이면서 핵심 기능은 유지하는 방향
2. **"설계 초과 달성"**: 패턴 E 신설, TAROT 검증 기준, 맥락 보전 프로토콜 강화, 에이전트 2개 추가 — 설계에 없던 것이 실전에서 필요하여 추가
3. **"프로토콜이 문서화를 따라가지 못하는 지점"**: HitL 트리거 축소, confidence 기준 미기재, auto_run 승인 규칙 등 — 구현은 작동하지만 프로토콜 문서에 반영 안 됨

### Conflicting Items

**교차 기억의 해소 여부** — P1과 P2의 판단이 달랐으나, P2의 실증적 확인이 더 정확. 구조적으로는 해소되었으나 프로토콜 문서화가 부족.

---

## Comprehensive Conclusion

### 핵심 발견 (우선순위 순)

1. **[High] R-024-F1: HitL 트리거 축소** — 7→4개, 특히 H3(동일 fail 반복 감지) 누락으로 평가루프 수렴 실패 감지 약화 *(관점 2)*

2. **[High] R-024-F2: auto_run과 사용자 승인 우선순위 미정의** — `--run` 모드에서 orchestration.md 4단계(사용자 승인)와 충돌. implement 유형에서 위험 가능성 *(관점 3)*

3. **[High] R-024-F3: confidence 판정 기준 orchestration.md 미기재** — 에이전트 프롬프트에만 존재, 오케스트레이터 판단 시 참조 불가 *(관점 2)*

4. **[High] R-024-F4: 교차 기억 참조 프로토콜 문서화 부재** — _shared/ 구조와 기억 파일은 존재하나 orchestration.md에 설명 없음 *(관점 1, 2)*

5. **[Medium] R-024-F5: 오케스트레이터 전환 결정 미문서화** — `--agent orchestrator` → CLAUDE.md 프로토콜 전환의 근거 미기록 *(관점 1)*

6. **[Medium] R-024-F6: 서브에이전트 모드 예외 규칙 3건 부재** — Communication Timeline 생략, 점진적 업데이트 대체, 승인 생략 규칙이 프로토콜에 없음 *(관점 3)*

7. **[Medium] R-024-F7: 일부 에이전트 기억 미활성** — flutter-expert, tarot-expert의 기억이 아직 0건 *(관점 1)*

8. **[Low] R-024-F8: work-orders 인프라 제거** — 의도적 단순화, 현재 docs/ 중심 방식으로 기능 대체 *(관점 1, 2)*

### 종합 평가

| 영역 | 반영율 | 주요 갭 |
|------|--------|---------|
| 패턴 A-D | ~100% | 없음 |
| 패턴 E | 신규 추가 | auto_run 승인 규칙 모호 |
| SOP 행동루프 | ~100% | 오케스트레이터 SOP 마스터 축소 |
| 평가루프 | ~90% | HitL 트리거 축소 |
| 인계 포맷 | ~75% (구조적 대체) | constraints/status 필드 누락 |
| 페르소나 | 100%+ | 없음 (초과 달성) |
| 기억 체계 | 100% | 프로토콜 문서화 갭 |
| 릴레이 감쇠 | 100% | 없음 |
| 맥락 보전 | 100%+ | 없음 (초과 달성) |
| **종합** | **~85%** | **Critical 0, High 4, Medium 3** |

**결론: 본래 취지의 에이전트 조직이 잘 구현되어 작동하고 있다.** 핵심 설계 철학은 충실히 보존되었고, 실제 실행에서도 프로토콜의 실효성이 입증되었다. 남은 갭은 대부분 "구현은 작동하지만 프로토콜 문서가 따라가지 못한" 문서화 수준의 이슈이며, 구현 자체의 결함이 아니다.

---

## Unresolved Items

1. **에이전트 프롬프트 내 Goal/Backstory 상세 확인** — P2에서 7개 에이전트 모두 존재 확인했으나, 005에서 요구한 "측정 가능한 성공 지표"의 구체적 충족 여부는 개별 에이전트 심층 감사가 필요. *(이유: 본 연구의 범위를 넘어서는 개별 에이전트 프롬프트 품질 감사)*

2. **Agent Teams 모드의 실전 검증** — 본 연구의 RNG 사례는 서브에이전트 모드만 사용. Agent Teams 모드(implement/review/debug)의 실전 검증은 아직 미수행. *(이유: 해당 유형의 실행 사례 부재)*

---

## Referenced File List

| File Path | Related Perspective | Role/Content |
|-----------|-------------------|--------------|
| `docs/07_organizational_agents/001_Scope_조직에이전트_전환.md` | P1 | 전체 전환 범위 정의 |
| `docs/07_organizational_agents/003_Agent_프레임워크제약.md` | P1 | 프레임워크 제약 8건 |
| `docs/07_organizational_agents/004_Agent_오케스트레이터패턴.md` | P1 | 패턴 A-D 정의, 병렬 기각 |
| `docs/07_organizational_agents/005_Agent_조직화격차.md` | P1 | 7대 격차 식별 |
| `docs/07_organizational_agents/009_Plan_오케스트레이터_아키텍처.md` | P1 | 구현 계획, work-orders |
| `docs/07_organizational_agents/012_Agent_SOP행동루프.md` | P2 | O→T→A→S 설계 |
| `docs/07_organizational_agents/013_Agent_평가루프HitL.md` | P2 | 평가루프, HitL 7트리거 |
| `docs/07_organizational_agents/017_Plan_페르소나강화_기억체계.md` | P2 | 페르소나 + agent-memory |
| `.claude/protocols/orchestration.md` | P1, P2, P3 | 현재 통합 프로토콜 |
| `CLAUDE.md` | P1, P2, P3 | 위임 판단, 에이전트 테이블 |
| `.claude/agent-memory/_shared/_index.yaml` | P2 | 공유 기억 구조 |
| `.claude/agents/psychology-expert.md` | P2 | 에이전트 정의 예시 |
| `docs/11_tarot_shuffle/047~054` | P3 | RNG 연구 실행 사례 |

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
