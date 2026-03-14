---
id: "008"
type: research
title: "조직 아키텍처 & 오케스트레이터 설계 연구 (최종)"
created: 2026-03-14
traces_scope: "001"
summary: >
  Claude Code 에이전트 프레임워크의 기술적 제약(서브에이전트 재귀 스폰 불가, 순차 실행, 파일 기반 통신)
  안에서 MAS 이론(계층형+파이프라인+평가루프)을 구현하는 오케스트레이터 설계 방안을 도출.
  오케스트레이터는 `claude --agent` 메인 스레드 실행 + Agent tool 워커 화이트리스트 구조를 채택하고,
  프롬프트 내 의사결정 트리로 워크플로우 유형별 패턴을 자동 선택한다. 현재 에이전트의 3대 격차
  (Goal/Backstory 부재, 기억 사문화, 인계 프로토콜 부재) 해결이 사이클 2-3의 핵심 과제.
keywords: [오케스트레이터, 조직아키텍처, Claude-Code-agents, MAS, 계층형, 파이프라인, 평가루프]
---

# 조직 아키텍처 & 오케스트레이터 설계 연구 (최종)

## Research Overview

### Background & Motivation

personality 프로젝트는 5개 독립 전문 에이전트(psychology, mbti, enneagram, coding, uiux)를 보유하고 있으나, 에이전트 간 조정은 전적으로 사용자 수동 중재에 의존한다. 이를 조직 에이전트 시스템으로 전환하기 위해 오케스트레이터 계층 도입이 필수적이며, 이 연구는 Claude Code 에이전트 프레임워크의 실제 제약 안에서 이를 어떻게 구현할 수 있는지를 조사한다.

### Research Scope

- Claude Code 에이전트 프레임워크의 기술적 제약 (에이전트 호출, 도구, 권한, 턴 수)
- 계층형+파이프라인+평가루프 하이브리드 패턴의 Claude Code 내 구현 방안
- 현재 5개 에이전트의 조직화 준비도와 격차
- 에이전트 간 상태/결과 전달 메커니즘

### Research Perspectives

1. Claude Code 에이전트 프레임워크 기술 제약
2. 오케스트레이터 설계 패턴 매핑
3. 현재 에이전트 조직화 격차 분석
4. 상태 관리 및 컨텍스트 전달

### Related Documents

- Checkpoint: [002_Research_조직아키텍처_오케스트레이터.md](./002_Research_조직아키텍처_오케스트레이터.md)
- Agent reports: [003](./003_Agent_프레임워크제약.md), [004](./004_Agent_오케스트레이터패턴.md), [005](./005_Agent_조직화격차.md), [006](./006_Agent_상태관리컨텍스트.md)
- Synthesis: [007_Synthesis_조직아키텍처연구.md](./007_Synthesis_조직아키텍처연구.md)

---

## Perspective 1: Claude Code 에이전트 프레임워크 기술 제약

### Status Analysis

Claude Code 에이전트 프레임워크는 `.claude/agents/*.md` 마크다운 파일로 에이전트를 정의하며, frontmatter에 12개 필드(name, description, model, tools, permissionMode, maxTurns, skills, disallowedTools, mcpServers, hooks, memory, background)를 지원한다. 마크다운 본문은 서브에이전트의 시스템 프롬프트로 주입된다.

### Detailed Findings

#### 핵심 제약: 서브에이전트 재귀 스폰 불가

> **"Subagents cannot spawn other subagents."** — Claude Code 공식 문서

이것이 오케스트레이터 설계의 가장 중요한 전제이다:
- `.claude/agents/`에 정의된 서브에이전트가 실행 중일 때 Agent tool을 사용할 수 없음
- psychology-expert가 coding-expert를 직접 호출하는 것은 **불가능**
- "infinite nesting" 방지를 위한 의도적 제한

#### 오케스트레이터 실행 모델: 3가지 옵션

| 옵션 | 방법 | 장점 | 단점 |
|------|------|------|------|
| **A: `--agent` 플래그** | `claude --agent orchestrator` | Agent tool 사용 가능, 안정적 | 사용자가 CLI 명령 실행 필요 |
| B: Agent Teams | 환경변수로 활성화 | 에이전트 간 직접 메시징 | 실험적 기능, 세션 재개 불가 |
| C: 체이닝 | 메인 대화에서 순차 호출 | 추가 구성 불필요 | 오케스트레이션 로직이 사용자에 의존 |

**결론**: 옵션 A(`--agent` 플래그)가 유일한 안정적 선택지.

#### Agent tool 스폰 제어

```yaml
# 오케스트레이터 frontmatter 예시
tools:
  - Agent(psychology-expert, mbti-expert, enneagram-expert, coding-expert, uiux-expert)
  - Read
  - Write
  - Edit
  - Glob
  - Grep
```

- `Agent` (괄호 없음): 모든 서브에이전트 스폰 가능
- `Agent(a, b, c)`: 화이트리스트 — 지정된 에이전트만 스폰 가능
- Agent 생략: 스폰 불가

#### 실행 제약 상세

| 항목 | 값/동작 |
|------|--------|
| **maxTurns** | 도구 사용 턴만 카운트. 오케스트레이터와 워커의 턴은 계층적으로 독립 |
| **컨텍스트 윈도우** | 서브에이전트는 독립된 윈도우. ~95%에서 자동 컴팩션 |
| **동시 실행** | 백그라운드 모드로 가능. `isolation: worktree`로 파일 충돌 방지 |
| **permissionMode** | 5종(default, acceptEdits, dontAsk, bypassPermissions, plan). 부모가 bypass이면 자식에서 재정의 불가 |
| **skills** | 서브에이전트 시작 시 스킬 전체 내용을 컨텍스트에 주입. 부모 스킬 비상속 |

### Caveats & Risks

- `--agent` 실행은 사용자가 CLI 명령을 입력해야 하므로 UX 마찰 존재
- Agent Teams가 안정화되면 더 유연한 패턴 가능하나 현 시점에서 의존 불가
- maxTurns 30일 때 하이브리드 워크플로우에서 평가루프는 최대 1개만 포함 가능

### Summary

오케스트레이터는 `claude --agent orchestrator`로 메인 스레드에서 실행하고, `Agent(...)` 구문으로 5개 워커를 화이트리스트하는 구조가 유일한 안정적 해법이다.

---

## Perspective 2: 오케스트레이터 설계 패턴 매핑

### Status Analysis

doc 002에서 제시한 5가지 MAS 구조 중 3가지(계층형, 파이프라인, 평가/정제 루프)를 채택하고, 나머지 2가지(병렬/디스패처, 그룹 채팅)는 Claude Code 제약으로 기각했다.

### Detailed Findings

#### 계층형 패턴: Agent tool + 파일 기반 하이브리드

오케스트레이터가 작업을 분해하고 Agent tool로 워커를 스폰하되, 복잡한 지시/산출물은 파일에 기록:

```
사용자 → [오케스트레이터] 작업 분류 → 패턴 선택
         ↓
    Agent tool로 워커 스폰 (프롬프트에 작업 지시 포함)
         ↓
    워커가 산출물을 파일로 저장
         ↓
    [오케스트레이터] 산출물 파일 읽기 → 다음 단계 결정
```

**작업 분해 예시: "새 MBTI 문항 세트 추가"**

```
Step 1: [mbti-expert] 문항 초안 설계 (5개 문항 YAML)
Step 2: [psychology-expert] 학술 검증 (바넘효과, 구성타당도)
Step 2b: [mbti-expert] 수정 반영 (필요 시 반복, 최대 2회)
Step 3: [coding-expert] seeds 구현 + 테스트
Step 4: [uiux-expert] 표시 검토 (선택적)
```

#### 파이프라인 패턴: 순차 실행의 자연스러운 활용

Claude Code의 순차 실행 특성이 파이프라인과 자연 부합:
- Agent tool로 에이전트를 하나씩 스폰하면 파이프라인이 자동 성립
- 이전 단계 산출물은 파일로 릴레이
- 오류 시 동일 에이전트에 재지시 (max_retries 제한)

#### 평가/정제 루프: 구조화된 verdict와 하드 가드레일

```
[오케스트레이터] → [생성 에이전트] → 산출물 파일
              → [비판 에이전트] → 평가 결과 파일
              → verdict 판정 → pass: 진행 / fail: 재생성
              → (최대 3회 반복)
```

평가 결과 포맷:
```yaml
evaluation:
  verdict: pass | fail | conditional_pass
  iteration: 1
  max_iterations: 3
  criteria:
    - name: "학술 근거 충족"
      status: pass
    - name: "바넘 효과 없음"
      status: fail
      fix_suggestion: "구체적 행동 예시로 대체"
```

가드레일: (1) max_iterations: 3 하드코딩, (2) 점수 미개선 시 중단, (3) 턴 예산 관리

#### 하이브리드 통합: 프롬프트 내 의사결정 트리

오케스트레이터 프롬프트에 4가지 패턴 선택 로직을 인코딩:

| 패턴 | 트리거 조건 | 예시 |
|------|-----------|------|
| Pattern A: 파이프라인 | 명확한 단계, 검증 불필요 | DB 마이그레이션, 버그 수정 |
| Pattern B: 평가루프 | 콘텐츠 품질/학술 검증 필요 | 문항 텍스트 검토, 유형 설명 검증 |
| Pattern C: 하이브리드 | 파이프라인 내 특정 단계에서 검증 필요 | **새 문항 세트 추가 (가장 빈번)** |
| Pattern D: 단일 위임 | 단일 에이전트로 해결 가능 | 단순 코드 리팩터링, 스타일 수정 |

#### doc 001 5개 계층 매핑

| 계층 | 오케스트레이터 구현 |
|------|-----------------|
| 인지(Perception) | 사용자 요청 파싱, 작업 유형 분류 |
| 기억(Memory) | `.claude/work-orders/` manifest + `agent-memory/` |
| 추론(Planning) | 패턴 선택, 에이전트 체인 결정, 턴 예산 배분 |
| 행동(Action) | Agent tool로 서브에이전트 스폰 |
| 피드백(Feedback) | 평가루프 verdict 판정, 워크플로우 상태 갱신 |

### Caveats & Risks

- maxTurns 30일 때 하이브리드 워크플로우(Pattern C)에서 평가루프는 최대 1개만 포함 가능
- 오케스트레이터의 추론 능력이 전체 시스템의 단일 장애점(Single Point of Failure)
- 프롬프트 내 의사결정 트리가 복잡해지면 오케스트레이터 자체의 환각 위험 증가

### Summary

계층형+파이프라인+평가루프 하이브리드는 Claude Code의 순차 실행에 자연 부합하며, 프롬프트 내 의사결정 트리와 파일 기반 상태 관리로 구현 가능하다.

---

## Perspective 3: 현재 에이전트 조직화 격차 분석

### Status Analysis

5개 에이전트는 동일한 7개 섹션 구조(Role, Project Context, Core Principles, Analysis Framework, Communication Style, Boundaries & Red Lines, Collaboration Rules, Memory System)를 가지며, 구조적 일관성은 높다. 그러나 doc 002의 페르소나 5요소 대비 심각한 격차가 존재한다.

### Detailed Findings

#### 페르소나 5요소 격차 매핑

| 5요소 | 현재 대응 | 격차 수준 |
|-------|----------|----------|
| **Role** | Role 섹션 존재. 고유 핸들(@handle) 없음 | 경미 |
| **Goal** | **전면 부재**. Core Principles가 "지켜야 할 것"만 정의 | **Critical** |
| **Backstory** | **전면 부재**. 사고 편향을 고정하는 서사적 맥락 없음 | **Critical** |
| **Tools+Guardrails** | frontmatter tools + Boundaries로 구현. 양호 | 경미 |
| **Memory** | Memory System 섹션 + agent-memory/ 존재. **실제 기억 0건** | **Critical** |

#### 협업 구조의 피상성

- 5개 에이전트 모두 동일한 충돌 해결 프로토콜 복사: "자기 영역 진술 → 다른 관점 인정 → 트레이드오프 명시 → 사용자에 위임"
- Claude Code는 순차 실행이므로 **실시간 충돌 자체가 불가능** — 프로토콜이 실행 맥락에 부적합
- 명시적 검증 체인(psychology→mbti, psychology→enneagram)은 정의되어 있으나, 인계 포맷이 미정의
- 역방향 체인(coding→psychology 구현 검증, uiux→psychology 윤리 검증)은 암시적

#### 기억 체계: 구조만 설계, 실행 0%

```
.claude/agent-memory/
├── psychology-expert/ → _index.yaml (빈 배열), memories/ (빈 디렉토리)
├── mbti-expert/       → 동일
├── enneagram-expert/  → 동일
├── coding-expert/     → 동일
└── uiux-expert/       → 동일
```

원인: docs/06_에이전트비평/의 비평 작업이 `.claude/agents/*.md` 에이전트가 아닌 general-purpose 서브에이전트로 실행되어 Memory System 지시가 적용되지 않음.

#### 역할 공백: 오케스트레이션, 품질 보증, 콘텐츠 통합, 프로젝트 관리

### Caveats & Risks

- Goal/Backstory 추가 시 에이전트 프롬프트 길이 증가 → 컨텍스트 윈도우 압박
- 기억 체계 활성화에는 에이전트가 자기 페르소나로 실제 실행되어야 함

### Summary

5개 에이전트의 구조적 일관성은 높으나, Goal/Backstory 부재와 기억 사문화가 조직 에이전트 전환의 핵심 장벽이다. 사이클 3에서 해결.

---

## Perspective 4: 상태 관리 및 컨텍스트 전달

### Status Analysis

현재 에이전트 산출물은 일관된 YAML frontmatter + Markdown body 구조로 docs/ 디렉토리에 저장된다. 그러나 에이전트 간 명시적 인계 프로토콜이 없으며, 워크플로우 추적은 `.claude/tmp/` 체크리스트로 최소한만 수행된다.

### Detailed Findings

#### 현재 산출물 패턴의 강점과 약점

**강점**:
- 모든 문서가 동일한 frontmatter 스키마 (id, title, category, status, created, summary, keywords, modules)
- Progress 추적이 각 문서에 내장
- Synthesis 문서의 교차 분석 패턴이 오케스트레이터 결과 종합의 기초로 활용 가능

**약점**:
- 에이전트 간 전달 프로토콜 미정의 (다음 에이전트가 어떤 파일을 읽어야 하는지 모름)
- 역방향 참조 링크 없음
- 세밀한 섹션 앵커 없음 (파일 단위 링크만)

#### 인계 파일 포맷 설계 방향

```yaml
---
handover_id: "WF-001-STEP-02"
workflow_id: "WF-001"
source:
  agent: "psychology-expert"
  task: "문항 심리측정학적 분석"
  confidence: high | medium | low
target:
  agent: "coding-expert"
  expected_action: "점수 계산 로직 수정"
summary: >
  recovery 도메인의 점수 해석 방향이 역전되어 있음.
artifacts:
  - path: "docs/06_에이전트비평/001_Agent_심리학비평.md"
    sections: ["### 3. 점수 엔진 분석"]
next_steps:
  - "conflict_module.rb의 recovery 점수 분기 방향 역전"
validation:
  criteria: "높은 recovery 점수에 유연성 관련 행동 추천 출력"
  validator_agent: "psychology-expert"
---
```

핵심 원칙: `confidence` 필드로 자기 평가, `artifacts` 필드로 원문 추적, `validation` 필드로 검증자 지정 → **환각 캐스케이딩 방지**.

#### 3단계 컨텍스트 압축 모델

| Level | 내용 | 용도 | 토큰 추정 |
|-------|------|------|----------|
| Level 1: 전문 | 원본 산출물 전체 | 해당 에이전트가 이전 작업 복원 시 | ~10,000/문서 |
| Level 2: 요약 | frontmatter summary + Key Findings | 오케스트레이터가 여러 결과 종합 시 | ~500/문서 |
| Level 3: 인계 | 인계 파일의 summary + next_steps만 | 수신 에이전트가 작업 시작 시 | ~200/인계 |

오케스트레이터는 Level 2를 기본으로 읽고, 상세 검토 필요 시만 Level 1로 확대.

#### 워크플로우 상태 추적

`.claude/work-orders/{workflow-id}/`에 manifest + 단계별 산출물 집중 관리:

```yaml
# _manifest.yaml
workflow_id: "WF-001"
type: hybrid  # pipeline | critique_loop | hybrid | single_delegation
status: in_progress | completed | failed
steps:
  - step: 1
    agent: "mbti-expert"
    task: "문항 초안 설계"
    status: completed
    output: "step-1_문항초안.md"
  - step: 2
    agent: "psychology-expert"
    task: "학술 검증"
    status: in_progress
checkpoint:
  last_completed_step: 1
  resume_instruction: "Step 2부터 재개. Step 1 산출물 참조."
```

### Caveats & Risks

- 비평 산출물 1개가 ~10,000 토큰 → 5개 에이전트 결과 종합 시 50,000+ 토큰 → Level 2 압축 필수
- `.claude/work-orders/` 디렉토리가 누적되면 관리 부담 → 완료된 워크플로우 아카이빙 필요
- 인계 파일 포맷이 복잡하면 에이전트가 제대로 생성하지 못할 위험 → 최소 필수 필드 우선

### Summary

파일 기반 상태 관리가 유일한 선택지이며, 3단계 압축 모델과 워크플로우 manifest로 컨텍스트 효율과 감사 추적을 동시에 달성한다.

---

## Cross-Analysis

### Inter-Perspective Relationships

```
관점 1 (프레임워크 제약)  ──기술적 제약 확인──→  관점 2 (패턴 매핑)
         │                                          │
         │ "서브에이전트 재귀 불가"가               │ 패턴 구현 방안이
         │ --agent 실행 모델을 강제                  │ 상태 관리 요구사항을 결정
         │                                          │
         ▼                                          ▼
관점 3 (격차 분석)  ──변경 대상 식별──→  관점 4 (상태 관리)
```

- 관점 1의 제약이 관점 2의 설계 공간을 한정 → 실현 가능한 패턴만 도출
- 관점 2의 패턴이 관점 4의 상태 관리 요구사항을 결정 (파이프라인 → 릴레이 파일, 평가루프 → verdict 파일)
- 관점 3의 격차가 사이클 2-3의 구체적 작업 범위를 결정

### Common Patterns

1. **파일 시스템 = 유일한 통신 채널**: 4개 관점 모두에서 확인. 에이전트 간 직접 통신 불가 → 모든 상태/산출물/인계가 파일을 통해야 함.
2. **YAML frontmatter + Markdown body = 프로젝트의 범용 포맷**: 에이전트 정의, 기억, 산출물, 인계 모두 이 포맷을 사용하거나 사용하도록 설계됨.
3. **구조화 = 환각 방지**: doc 002의 원칙이 4개 관점 모두에서 반복 확인. 자유 텍스트 소통 → 환각 캐스케이딩, 구조화된 포맷 → 방지.

### Conflicting Items

| 항목 | 관점 2 | 관점 4 | 해결 |
|------|--------|--------|------|
| 상태 파일 위치 | `.claude/work-orders/` (워크플로우 중심) | `.claude/handovers/` + `.claude/workflows/` (역할 분리) | 워크플로우 중심 채택 (단순성 우선) |
| 오케스트레이터 직접 작업 | 엄격한 금지 | 언급 없음 | "코드 수정/콘텐츠 생성은 위임 필수, 파일 읽기/요약은 직접 허용" |
| 공유 기억 쓰기 | 구체적 언급 없음 | 오케스트레이터만 쓰기 가능 | 오케스트레이터 독점 쓰기 채택 |

---

## Comprehensive Conclusion

### 핵심 발견 (우선순위 순)

1. **[Critical] R-008-F1: 오케스트레이터 실행 모델** — `claude --agent orchestrator`로 메인 스레드 실행 + `tools: Agent(5개 워커)` 화이트리스트가 유일한 안정적 구조. 서브에이전트 재귀 스폰 불가가 이를 강제. *(관점 1, 2)*

2. **[Critical] R-008-F2: 하이브리드 패턴은 프롬프트 내 의사결정 트리** — 워크플로우 유형별(기능개발/콘텐츠검증/버그수정) 패턴 자동 선택. Pattern C(파이프라인 + 내장 평가루프)가 대부분의 실제 작업. *(관점 2)*

3. **[Critical] R-008-F3: 3대 격차 해결 필수** — Goal/Backstory 전면 부재, 기억 체계 사문화(5×0=0건), 인계 프로토콜 부재. 이것 없이 조직화 불가. *(관점 3, 4)*

4. **[High] R-008-F4: 파일 기반 상태 관리가 유일한 통신 채널** — `.claude/work-orders/`에 manifest + 산출물 + 평가 결과 집중 관리. "보이지 않는 상태" 안티 패턴 방지. *(관점 1, 2, 4)*

5. **[High] R-008-F5: 3단계 컨텍스트 압축이 maxTurns 병목의 해법** — Level 2(요약) 우선 읽기로 오케스트레이터 턴 효율 최적화. *(관점 1, 4)*

6. **[High] R-008-F6: 구조화된 평가 포맷으로 평가루프 품질 보장** — `verdict: pass/fail` + `max_iterations: 3` + 기준별 상태 추적. *(관점 2)*

7. **[Medium] R-008-F7: doc 001의 5개 계층이 오케스트레이터에 직접 매핑** — 인지→기억→추론→행동→피드백의 자연스러운 대응. 설계 검증의 이론적 근거. *(관점 2)*

8. **[Medium] R-008-F8: Agent Teams는 차세대 옵션** — 안정화 시 에이전트 간 직접 메시징으로 평가루프 효율 대폭 향상 가능. 현 시점에서는 의존 불가. *(관점 1)*

## Unresolved Items

1. **Agent tool에서 커스텀 에이전트 이름을 subagent_type으로 지정하는 정확한 구문**: 관점 1에서 `agent_type` 파라미터로 지정 가능하다고 보고했으나, 실제 코드 레벨 검증은 사이클 1 구현 단계에서 확인 필요. *(Claude Code 내부 구현에 의존, 외부 검증 불가)*

2. **오케스트레이터의 최적 maxTurns 값**: 30턴이 제안되었으나, 실제 하이브리드 워크플로우에서의 턴 소비 패턴은 구현 후 실측 필요.

3. **memory frontmatter 필드와 커스텀 기억 체계의 공존 가능성**: Claude Code 공식 `memory: project` 필드와 현재 커스텀 YAML 기억 체계를 동시에 사용할 때의 충돌 여부 미확인.

## Referenced File List

| File Path | Related Perspective | Role/Content |
|-----------|-------------------|--------------|
| `.claude/agents/psychology-expert.md` | 관점 3 | 심리학 전문가 에이전트 정의 |
| `.claude/agents/mbti-expert.md` | 관점 3 | MBTI 전문가 에이전트 정의 |
| `.claude/agents/enneagram-expert.md` | 관점 3 | 애니어그램 전문가 에이전트 정의 |
| `.claude/agents/coding-expert.md` | 관점 3 | 코딩 전문가 에이전트 정의 |
| `.claude/agents/uiux-expert.md` | 관점 3 | UI/UX 전문가 에이전트 정의 |
| `.claude/agent-memory/*/` | 관점 3, 4 | 에이전트별 기억 디렉토리 (전체 빈 상태) |
| `docs/001_gemini_deep_research.md` | 관점 2 | 5개 핵심 계층, 페르소나 5요소 |
| `docs/002_gemini_deep_research.md` | 관점 2 | MAS 구조 5종, 안티 패턴, SOP 철학 |
| `docs/06_에이전트비평/001~006` | 관점 4 | 현행 에이전트 산출물 패턴 |
| `docs/07_organizational_agents/001_Scope_*.md` | 전체 | 상위 Scope 문서 |
| Claude Code 공식 문서 | 관점 1 | 에이전트 시스템 기술 스펙 |
