---
id: "007"
title: "조직 아키텍처 & 오케스트레이터 설계 — Synthesis Report"
category: report
status: archived
created: 2026-03-14
summary: >
  4개 관점(프레임워크 제약, 패턴 매핑, 조직화 격차, 상태 관리)의 병렬 조사 결과를 종합.
  핵심 결론: 오케스트레이터는 `claude --agent orchestrator`로 메인 스레드 실행 + Agent tool로
  워커 스폰하는 계층형 구조 채택. 파이프라인+평가루프 하이브리드를 프롬프트 내 의사결정 트리로
  구현. 현재 에이전트의 3대 격차(Goal/Backstory 부재, 기억 사문화, 인계 프로토콜 부재) 해결 필요.
keywords: [parallel-synthesis, research, 오케스트레이터, 조직아키텍처, Claude-Code-agents, MAS]
modules: [.claude/agents, .claude/agent-memory]
---

# 조직 아키텍처 & 오케스트레이터 설계 — Synthesis Report

## Team Composition & Individual Reports

| # | 관점 | Agent Type | Report | Status |
|---|------|-----------|--------|--------|
| 1 | Claude Code 프레임워크 기술 제약 | general-purpose | [003_Agent_프레임워크제약.md](./003_Agent_프레임워크제약.md) | complete |
| 2 | 오케스트레이터 설계 패턴 매핑 | general-purpose | [004_Agent_오케스트레이터패턴.md](./004_Agent_오케스트레이터패턴.md) | complete |
| 3 | 현재 에이전트 조직화 격차 분석 | general-purpose | [005_Agent_조직화격차.md](./005_Agent_조직화격차.md) | complete |
| 4 | 상태 관리 및 컨텍스트 전달 | general-purpose | [006_Agent_상태관리컨텍스트.md](./006_Agent_상태관리컨텍스트.md) | complete |

---

## Cross-Analysis

### Common Findings

다수 에이전트가 독립적으로 도달한 동일 결론:

1. **기억 체계 사문화** (관점 3, 4): 5개 에이전트 × 0건 = 총 0건. 구조는 설계되었으나 한 번도 실행된 적 없음. 관점 3은 "general-purpose 서브에이전트로 실행되어 에이전트 프롬프트가 적용되지 않았기 때문"이라는 원인까지 동일하게 분석.

2. **"보이지 않는 상태" 안티 패턴의 현실적 위험** (관점 2, 4): 중간 산출물이 파일로 명시되지 않으면 컨텍스트 유실 발생. 관점 2는 `.claude/work-orders/` 디렉토리를, 관점 4는 `.claude/handovers/` + `.claude/workflows/`를 독립적으로 제안.

3. **Agent tool이 오케스트레이터의 핵심 도구** (관점 1, 2): 관점 1은 기술 스펙에서, 관점 2는 설계 패턴에서 동일하게 Agent tool의 중심적 역할을 확인.

4. **구조화된 산출물 포맷의 일관성** (관점 3, 4): 현재 docs/ 문서의 YAML frontmatter + Markdown body 구조가 이미 일관적이며, 이를 인계 포맷의 기초로 활용 가능.

### Conflicting Opinions

1. **상태 파일 저장 위치**:
   - 관점 2: `.claude/work-orders/{workflow-id}/` — 워크플로우 중심의 평탄 구조
   - 관점 4: `.claude/handovers/active/` + `.claude/workflows/active/` — 인계와 워크플로우를 분리
   - **판단**: 관점 2의 워크플로우 중심 구조가 더 단순하고 실용적. 인계 파일도 워크플로우 디렉토리 안에 포함하는 것이 감사 추적에 유리. 사이클 2(SOP)에서 최종 결정.

2. **오케스트레이터의 직접 작업 허용 범위**:
   - 관점 2: "오케스트레이터의 직접 작업 금지를 레드라인으로 명시" (엄격한 위임 전용)
   - 관점 1: Agent tool의 스폰 제어 구문(`Agent(a, b, c)`)으로 유연하게 제어 가능
   - **판단**: 원칙적으로 직접 작업 금지가 맞으나, 단순 작업(파일 읽기/요약)은 허용하는 것이 턴 효율에 유리. "코드 수정, 콘텐츠 생성은 반드시 워커에 위임" 수준의 가드레일이 적절.

3. **공유 기억의 쓰기 권한**:
   - 관점 4: "오케스트레이터만 공유 기억에 쓰기 가능" (환각 캐스케이딩 방지)
   - 관점 3: 구체적 쓰기 권한 언급 없음, "공유 기억 공간 생성" 권장
   - **판단**: 관점 4의 "오케스트레이터만 쓰기" 원칙 채택. 개별 에이전트의 발견은 개별 기억에 기록 후, 오케스트레이터가 교차 검증을 거쳐 공유 기억으로 승격.

### Synergy Effects

1. **프레임워크 제약 + 패턴 매핑 = 실현 가능한 오케스트레이터 설계**:
   - 관점 1의 `--agent` 플래그 + Agent tool 스폰 제어 구문이 관점 2의 계층형 패턴을 직접 뒷받침
   - 관점 1의 maxTurns 계층 분리(오케스트레이터/워커 턴 독립)가 관점 2의 평가루프 가드레일(max_iterations: 3)을 가능하게 함

2. **격차 분석 + 상태 관리 = 사이클 2-3의 구체적 변경 목록**:
   - 관점 3의 "Goal/Backstory 부재"와 관점 4의 "인계 프로토콜 부재"를 결합하면, 각 에이전트 프롬프트에 추가해야 할 섹션이 명확해짐: Goal, Backstory, Output Format, Handover Protocol
   - 관점 3의 "Collaboration Rules 재설계"와 관점 4의 "인계 파일 포맷"을 결합하면, 사이클 2(SOP)의 구체적 설계 범위가 도출됨

3. **3단계 압축 모델이 오케스트레이터 턴 효율을 결정**:
   - 관점 4의 Level 1/2/3 압축 모델이 관점 1의 maxTurns 병목(30턴)에 대한 해법
   - 오케스트레이터는 Level 2(요약)로 결과를 읽고, 상세 검토 필요 시만 Level 1로 확대

---

## Comprehensive Conclusion

### Key Findings (우선순위 순)

1. **[Critical] 오케스트레이터 실행 모델 확정**: `claude --agent orchestrator`로 메인 스레드 실행. `tools: Agent(psychology-expert, mbti-expert, enneagram-expert, coding-expert, uiux-expert)` 구문으로 워커 화이트리스트. 서브에이전트 재귀 스폰 불가가 이 설계를 강제함. *(관점 1, 2)*

2. **[Critical] 하이브리드 패턴은 프롬프트 내 의사결정 트리로 구현**: 워크플로우 유형(기능개발/콘텐츠검증/버그수정)에 따라 파이프라인, 평가루프, 단일위임 중 패턴을 자동 선택. 대부분의 실제 작업은 Pattern C(파이프라인 + 내장 평가루프). *(관점 2)*

3. **[Critical] 3대 격차 해결 없이 조직화 불가**: Goal 부재, 기억 사문화, 인계 프로토콜 부재. 이 중 Goal/Backstory는 사이클 3, 인계 프로토콜은 사이클 2에서 해결. *(관점 3, 4)*

4. **[High] 파일 기반 상태 관리가 유일한 선택지**: Claude Code에서 에이전트 간 직접 통신 불가 → 모든 상태/산출물/인계가 파일 시스템을 통해야 함. `.claude/work-orders/` 디렉토리에 manifest + 산출물 + 평가 결과를 집중 관리. *(관점 1, 2, 4)*

5. **[High] maxTurns 30이 실질적 병목**: 3단계 압축 모델(Level 1 전문/Level 2 요약/Level 3 인계)로 턴 효율 최적화. 오케스트레이터는 Level 2 우선 읽기. *(관점 1, 4)*

6. **[Medium] Agent Teams는 차세대 옵션**: 현재 실험적이나 안정화 시 에이전트 간 직접 메시징이 가능해져 평가루프의 효율이 크게 향상될 수 있음. *(관점 1)*

### Recommended Actions (우선순위 순)

1. **사이클 1 Plan에 반영**: 오케스트레이터 에이전트 파일 생성 (`model: opus`, `tools: Agent(...)`, `maxTurns: 30`)
2. **사이클 1 Plan에 반영**: `.claude/work-orders/` 디렉토리 구조 및 manifest 스키마 정의
3. **사이클 2 Research에 전달**: 인계 파일 포맷, SOP 행동 루프(Observe→Think→Act→Share), 평가 포맷 상세 설계
4. **사이클 3 Plan에 전달**: 5개 에이전트의 Goal/Backstory 추가, Collaboration Rules 재설계, Memory System에 `_shared/` 참조 추가

---

## References

- [003_Agent_프레임워크제약.md](./003_Agent_프레임워크제약.md) — Claude Code 에이전트 기술 스펙
- [004_Agent_오케스트레이터패턴.md](./004_Agent_오케스트레이터패턴.md) — MAS 패턴 매핑
- [005_Agent_조직화격차.md](./005_Agent_조직화격차.md) — 현재 에이전트 격차 7건
- [006_Agent_상태관리컨텍스트.md](./006_Agent_상태관리컨텍스트.md) — 상태/인계/컨텍스트 메커니즘
- docs/001_gemini_deep_research.md — 5개 핵심 계층, 페르소나 5요소
- docs/002_gemini_deep_research.md — MAS 구조 5종, 안티 패턴, SOP 철학
- docs/07_organizational_agents/001_Scope_조직에이전트_전환.md — 상위 Scope
