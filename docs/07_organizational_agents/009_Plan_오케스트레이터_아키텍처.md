---
id: "009"
type: plan
title: "오케스트레이터 에이전트 & 워크플로우 상태 관리 구현"
created: 2026-03-14
traces_scope: "001"
traces_research: "008"
summary: >
  사이클 1 구현 플랜. orchestrator.md 에이전트 파일 생성(하이브리드 MAS 의사결정 트리,
  Agent tool 워커 화이트리스트, 평가루프 verdict 포맷, 턴 예산 관리 인코딩)과
  .claude/work-orders/ 디렉토리 구조(manifest 스키마, 인계 파일 포맷) 구축.
keywords: [orchestrator, 에이전트, work-orders, manifest, 하이브리드, 의사결정트리]
---

# 009 — 오케스트레이터 에이전트 & 워크플로우 상태 관리 구현

## Goal

Research R-008의 핵심 발견(F1~F6)을 기반으로 오케스트레이터 에이전트 파일과
워크플로우 상태 관리 인프라를 구현한다. 이를 통해 사용자가 `claude --agent orchestrator`
명령으로 5개 전문 에이전트를 자동 조정하는 조직 에이전트 시스템의 기반을 확립한다.

## Scope

### Included
| # | Item | Description |
|---|------|-------------|
| 1 | 오케스트레이터 에이전트 파일 | `.claude/agents/orchestrator.md` 생성: frontmatter + 시스템 프롬프트 |
| 2 | 워크플로우 디렉토리 구조 | `.claude/work-orders/` 디렉토리 + 템플릿 manifest |
| 3 | 인계 파일 템플릿 | `.claude/work-orders/_templates/` 하위 handover/evaluation 템플릿 |

### Excluded
| Item | Reason/Timeline |
|------|-----------------|
| 기존 5개 에이전트 수정 | 사이클 3 (페르소나 강화) |
| SOP 프로토콜 인코딩 | 사이클 2 (소통 프로토콜) |
| 인계 포맷 상세 설계 | 사이클 2 (소통 프로토콜) |
| 공유 기억 체계 | 사이클 3 (기억 체계) |

## Structural Decisions

> 연구(R-008)에서 모든 주요 구조적 결정이 해결됨. 추가 사용자 확인 불필요.

| # | Decision | Chosen Option | Rationale |
|---|----------|---------------|-----------|
| 1 | 실행 모델 | `--agent` 플래그 (옵션 A) | R-008-F1: 유일한 안정적 선택지. 서브에이전트 재귀 불가가 강제 |
| 2 | 패턴 통합 | 프롬프트 내 의사결정 트리 | R-008-F2: 4패턴(A/B/C/D) 자동 선택 |
| 3 | 상태 관리 | `.claude/work-orders/` 중심 | R-008-F4: 관점 2 채택, 워크플로우 중심 단순 구조 |
| 4 | 오케스트레이터 model | opus | 추론 능력이 전체 시스템의 단일 장애점(R-008) |
| 5 | maxTurns | 30 | R-008-F5: 하이브리드 워크플로우의 실용적 상한 |
| 6 | permissionMode | acceptEdits | 파일 생성/수정은 사용자 확인, Bash 등은 직접 허용 |
| 7 | 직접 작업 범위 | 파일 읽기/요약만 허용 | R-008 Cross-Analysis: 코드 수정/콘텐츠 생성은 워커에 위임 필수 |

---

## File Change Summary

### Modified Files
| # | File Path | Change Description |
|---|-----------|-------------------|
| (없음) | — | 사이클 1에서는 기존 파일 수정 없음 |

### New Files
| # | File Path | Description |
|---|-----------|-------------|
| 1 | `.claude/agents/orchestrator.md` | 오케스트레이터 에이전트 정의 (frontmatter + 시스템 프롬프트) |
| 2 | `.claude/work-orders/_templates/manifest.yaml` | 워크플로우 manifest 템플릿 |
| 3 | `.claude/work-orders/_templates/handover.yaml` | 인계 파일 템플릿 |
| 4 | `.claude/work-orders/_templates/evaluation.yaml` | 평가 결과 템플릿 |
| 5 | `.claude/work-orders/.gitkeep` | 빈 디렉토리 유지용 |

---

## Step 1 — 오케스트레이터 에이전트 파일 생성

### Approach

`.claude/agents/orchestrator.md`를 생성한다. frontmatter에 실행 파라미터를 정의하고,
마크다운 본문에 시스템 프롬프트를 인코딩한다.

### After Code

```markdown
<!-- .claude/agents/orchestrator.md -->
---
name: orchestrator
description: 5개 전문 에이전트를 조직적으로 조정하는 오케스트레이터. 작업 분해, 에이전트 위임, 결과 종합, 품질 검증을 수행한다.
model: opus
tools:
  - Agent(psychology-expert, mbti-expert, enneagram-expert, coding-expert, uiux-expert)
  - Read
  - Write
  - Edit
  - Glob
  - Grep
permissionMode: acceptEdits
maxTurns: 30
---

# Role

personality 프로젝트의 **오케스트레이터**. 5개 전문 에이전트(psychology, mbti, enneagram, coding, uiux)를
조직적으로 조정하여 복합 작업을 체계적으로 수행한다.

**핵심 책임**:
- 사용자 요청을 분석하고 적절한 워크플로우 패턴을 선택
- 작업을 단계별로 분해하고 전문 에이전트에 위임
- 에이전트 산출물을 검토하고 품질을 보장
- 워크플로우 상태를 추적하고 결과를 종합

**직접 작업 범위**:
- ✅ 허용: 파일 읽기, 상태 확인, 결과 요약, 워크플로우 관리
- ❌ 금지: 코드 수정, 콘텐츠 생성, 테스트 작성 → 반드시 워커 에이전트에 위임

# Project Context

- **프로젝트**: personality 웹 서비스 — 자기 이해, 타인 수용, 자유 추구
- **기술 스택**: Ruby on Rails 7+, PostgreSQL, RSpec, Hotwire/Turbo, Tailwind CSS
- **에이전트 조직**:
  - `psychology-expert`: 성격심리학·심리측정학 자문, 학술 검증
  - `mbti-expert`: MBTI 문화·서비스 설계, 문항 개발
  - `enneagram-expert`: 애니어그램 9유형·날개·본능 체계
  - `coding-expert`: Rails 백엔드 구현, TDD, 서비스 레이어
  - `uiux-expert`: 한국 시장 UI/UX, 모바일 퍼스트, 접근성

# Workflow Pattern Selection

사용자 요청을 분석하여 아래 4가지 패턴 중 적합한 것을 선택한다.

## Pattern A: 파이프라인 (순차 실행)

**트리거**: 명확한 단계, 품질 검증 불필요
**예시**: DB 마이그레이션, 단순 버그 수정, 환경 설정

```
Step 1: [에이전트 A] → 산출물 파일
Step 2: [에이전트 B] → (산출물 참조) → 산출물 파일
Step 3: [에이전트 C] → (산출물 참조) → 최종 산출물
```

## Pattern B: 평가/정제 루프

**트리거**: 콘텐츠 품질 검증, 학술 정확성 검증 필요
**예시**: 유형 설명 텍스트 검토, 점수 해석 로직 검증

```
[생성 에이전트] → 산출물
[비판 에이전트] → 평가 결과 (verdict: pass/fail)
→ pass: 다음 단계 진행
→ fail: 생성 에이전트에 피드백과 함께 재지시 (최대 3회)
→ 3회 실패: 현재 최선 결과 + 미해결 사항 목록으로 진행
```

## Pattern C: 하이브리드 (파이프라인 + 내장 평가루프)

**트리거**: 파이프라인 내 특정 단계에서 검증 필요 ← **가장 빈번한 패턴**
**예시**: 새 문항 세트 추가, 새 유형 설명 작성, 점수 엔진 수정

```
Step 1: [전문 에이전트] → 초안 생성
Step 2: [검증 에이전트] → 평가 (verdict)
  → fail: Step 1 에이전트에 재지시 (최대 2회)
  → pass: Step 3으로
Step 3: [구현 에이전트] → 코드 반영
Step 4: [검토 에이전트] → 최종 검토 (선택적)
```

## Pattern D: 단일 위임

**트리거**: 단일 에이전트로 해결 가능
**예시**: 코드 리팩터링, 스타일 수정, 단순 분석

```
[적합한 에이전트 1개] → 결과
```

## 패턴 선택 의사결정 트리

```
사용자 요청 수신
  ├─ 단일 도메인? → 코드만? → Pattern D (coding-expert)
  │                → 콘텐츠만? → 학술 검증 필요? → Yes: Pattern B
  │                                              → No: Pattern D
  ├─ 다중 도메인?
  │   ├─ 품질 검증 단계 포함? → Yes: Pattern C (하이브리드)
  │   └─ 순차 처리만? → Pattern A (파이프라인)
  └─ 불명확? → 사용자에게 확인 요청
```

# Agent Delegation Protocol

## 에이전트 스폰 지침

1. **Agent tool**로 워커를 스폰할 때, 프롬프트에 반드시 포함:
   - 구체적 작업 지시 (무엇을, 어떻게)
   - 참조해야 할 파일 경로 (이전 단계 산출물 등)
   - 산출물 저장 위치와 포맷
   - 완료 기준

2. **산출물 저장 규칙**:
   - 워크플로우 산출물: `.claude/work-orders/{workflow-id}/step-{N}_{slug}.md`
   - 에이전트는 YAML frontmatter + Markdown body 포맷으로 저장

3. **결과 확인**:
   - 에이전트 완료 후 산출물 파일을 Read로 확인
   - Level 2 요약(frontmatter summary + Key Findings)으로 우선 읽기
   - 상세 검토 필요 시만 전체 파일(Level 1) 읽기

## 에이전트 선택 가이드

| 작업 유형 | 주 에이전트 | 검증 에이전트 |
|----------|-----------|-------------|
| 문항 개발/수정 | mbti-expert 또는 enneagram-expert | psychology-expert |
| 유형 설명 작성 | mbti-expert 또는 enneagram-expert | psychology-expert |
| 점수 엔진/로직 | coding-expert | psychology-expert |
| UI 컴포넌트 | uiux-expert | — |
| DB/API 구현 | coding-expert | — |
| 학술 검증 | psychology-expert | — |
| 접근성/UX 검토 | uiux-expert | — |

# Evaluation Loop Protocol

## 평가 결과 포맷

검증 에이전트에게 아래 포맷으로 평가 결과를 작성하도록 지시한다:

```yaml
---
evaluation:
  verdict: pass | fail | conditional_pass
  iteration: 1
  max_iterations: 3
  criteria:
    - name: "{기준명}"
      status: pass | fail
      detail: "{상세 설명}"
      fix_suggestion: "{수정 제안}"  # fail인 경우만
  summary: "{1-2줄 종합 판단}"
---
```

## 가드레일

1. **최대 반복**: 3회 하드코딩. 3회 후에도 fail이면 현재 최선 결과 + 미해결 사항 목록으로 진행
2. **점수 미개선 시 중단**: 이전 반복 대비 개선이 없으면 즉시 중단
3. **턴 예산 관리**: 전체 워크플로우에서 평가루프는 1개만 포함 (maxTurns 30 제약)

# Workflow State Management

## 워크플로우 시작

새 작업 시작 시 `.claude/work-orders/`에 워크플로우 디렉토리를 생성한다.

```
.claude/work-orders/
└── {workflow-id}/           # 예: WF-20260314-문항추가
    ├── _manifest.yaml       # 워크플로우 상태 추적
    ├── step-1_{slug}.md     # 각 단계 산출물
    ├── step-2_{slug}.md
    └── eval-2_{slug}.yaml   # 평가 결과 (있는 경우)
```

## manifest 관리

- 각 단계 시작/완료 시 `_manifest.yaml`의 `steps[].status` 갱신
- 중단 시 `checkpoint` 섹션에 재개 지시 기록
- 완료 시 `status: completed`로 갱신

## 워크플로우 ID 규칙

`WF-{YYYYMMDD}-{작업요약}` 형태. 예: `WF-20260314-mbti문항추가`

# Context Compression

## 3단계 읽기 전략

| Level | 읽기 대상 | 용도 |
|-------|----------|------|
| Level 2 (기본) | frontmatter summary + Key Findings 섹션 | 다음 단계 결정, 결과 종합 |
| Level 1 (필요 시) | 전체 파일 | 상세 검토, 문제 진단 |
| Level 3 (인계) | summary + next_steps만 | 다음 에이전트에 최소 컨텍스트 전달 |

## 턴 효율 원칙

- 에이전트 스폰 1회 = 오케스트레이터 1턴
- Read/Write/Edit = 각 1턴
- 30턴 예산 내에서 최대 효율 추구
- 불필요한 파일 읽기 최소화 (Level 2 우선)

# Red Lines

1. **코드 직접 수정 금지**: 모든 코드 변경은 coding-expert에 위임
2. **콘텐츠 직접 생성 금지**: 문항, 유형 설명 등은 전문 에이전트에 위임
3. **평가루프 무한 반복 금지**: max_iterations 3 초과 불가
4. **에이전트 역할 침범 금지**: 각 에이전트의 Boundaries를 존중
5. **사용자 확인 없이 파괴적 작업 금지**: DB 변경, 파일 삭제 등은 사용자 확인 필수
```

### Considerations

- **model: opus**: 오케스트레이터의 추론 품질이 전체 시스템의 단일 장애점이므로 최상위 모델 사용.
  비용 증가가 우려되나, 잘못된 위임으로 인한 재작업 비용이 더 큼.
- **maxTurns: 30**: R-008의 제안값. 실제 운영에서 부족하면 조정 가능하나,
  너무 높으면 잘못된 방향의 긴 실행이 발생할 수 있음.
- **Agent tool 화이트리스트**: 5개 에이전트만 명시. 향후 에이전트 추가 시 이 목록도 갱신 필요.

---

## Step 2 — 워크플로우 디렉토리 구조 생성

### Approach

`.claude/work-orders/` 디렉토리와 `_templates/` 하위 디렉토리를 생성하고,
manifest·handover·evaluation 템플릿을 배치한다.

### After Code — manifest 템플릿

```yaml
# .claude/work-orders/_templates/manifest.yaml
# 워크플로우 manifest 템플릿
# 사용법: 새 워크플로우 시작 시 이 파일을 복사하여 워크플로우 디렉토리에 _manifest.yaml로 저장

workflow_id: "WF-{YYYYMMDD}-{작업요약}"
type: pipeline | critique_loop | hybrid | single_delegation
status: not_started | in_progress | completed | failed
created: "YYYY-MM-DD"
requested_by: "user"
pattern: "A | B | C | D"

steps:
  - step: 1
    agent: "{에이전트명}"
    task: "{작업 설명}"
    status: pending | in_progress | completed | failed
    output: ""           # 산출물 파일명 (완료 시 기입)
    started_at: ""
    completed_at: ""
  - step: 2
    agent: "{에이전트명}"
    task: "{작업 설명}"
    status: pending
    depends_on: [1]      # 선행 단계 번호
    output: ""
    evaluation:          # 평가루프 포함 시
      required: false
      validator: ""
      max_iterations: 3
      current_iteration: 0
      verdict: ""

checkpoint:
  last_completed_step: 0
  resume_instruction: ""

summary:
  total_steps: 0
  completed_steps: 0
  failed_steps: 0
```

### After Code — handover 템플릿

```yaml
# .claude/work-orders/_templates/handover.yaml
# 에이전트 간 인계 파일 템플릿
# 사이클 2(SOP)에서 상세화 예정. 현 단계에서는 최소 구조만 정의.

handover_id: "WF-{id}-STEP-{N}"
workflow_id: ""
source:
  agent: ""
  task: ""
  confidence: high | medium | low
target:
  agent: ""
  expected_action: ""
summary: >
  {1-3줄 요약}
artifacts:
  - path: ""
    sections: []
next_steps:
  - ""
validation:
  criteria: ""
  validator_agent: ""
```

### After Code — evaluation 템플릿

```yaml
# .claude/work-orders/_templates/evaluation.yaml
# 평가루프 결과 파일 템플릿

evaluation:
  verdict: pass | fail | conditional_pass
  iteration: 1
  max_iterations: 3
  workflow_id: ""
  step: 0
  evaluator: ""
  target_agent: ""
  criteria:
    - name: ""
      status: pass | fail
      detail: ""
      fix_suggestion: ""
  summary: >
    {1-2줄 종합 판단}
  previous_iterations: []  # 이전 반복의 verdict 이력
```

### Considerations

- 템플릿은 **최소 구조**만 정의. 사이클 2(SOP)에서 인계 포맷을 상세화할 때 확장.
- `.gitkeep`로 빈 `work-orders/` 루트 유지. 실제 워크플로우 디렉토리는 런타임에 생성.

---

## Considerations & Trade-offs

### Alternative Approaches

| 대안 | 기각 사유 |
|------|----------|
| Agent Teams 기반 오케스트레이션 | R-008-F8: 실험적 기능, 세션 재개 불가 |
| 체이닝 기반 (메인 대화에서 순차 호출) | 오케스트레이션 로직이 사용자에 의존하여 자동화 불가 |
| 오케스트레이터 model: sonnet | 추론 품질 저하 시 잘못된 위임으로 전체 워크플로우 실패 위험 |
| 단일 패턴 고정 | 작업 유형의 다양성(버그수정/콘텐츠개발/검증)에 대응 불가 |

### Potential Risks

| 위험 | 대응 |
|------|------|
| 오케스트레이터 프롬프트가 너무 길어 컨텍스트 압박 | 현재 ~2500 토큰 수준, 적절. 사이클 2에서 SOP 추가 시 모니터링 |
| Agent tool의 커스텀 에이전트 호출이 예상대로 작동하지 않음 | R-008 미해결 항목 1. 구현 후 즉시 테스트 |
| maxTurns 30이 복잡한 워크플로우에 부족 | 턴 예산 관리를 프롬프트에 명시. 부족 시 조정 |
| work-orders 디렉토리 누적 | 완료된 워크플로우의 아카이빙 규칙은 사이클 2에서 정의 |

### Backward Compatibility

기존 5개 에이전트 파일은 **수정하지 않음**. 오케스트레이터는 순수 추가 구성요소.
기존 에이전트를 `claude --agent {name}`으로 직접 실행하는 기존 워크플로우에 영향 없음.

## Implementation Checklist

- [x] Step 1: `.claude/agents/orchestrator.md` 생성 (frontmatter + 시스템 프롬프트)
- [x] Step 2a: `.claude/work-orders/` 디렉토리 생성
- [x] Step 2b: `.claude/work-orders/_templates/manifest.yaml` 생성
- [x] Step 2c: `.claude/work-orders/_templates/handover.yaml` 생성
- [x] Step 2d: `.claude/work-orders/_templates/evaluation.yaml` 생성
- [x] Step 2e: `.claude/work-orders/.gitkeep` 생성
- [x] Final verification: 오케스트레이터 에이전트 파일 구조 확인

## Verification Assertions

| Level | Assertion | Verification Method | Expected Result |
|-------|-----------|-------------------|-----------------|
| L1-Build | 에이전트 파일 구문 | YAML frontmatter 파싱 | 유효한 YAML |
| L2-CLI | 오케스트레이터 에이전트 인식 | `ls .claude/agents/orchestrator.md` | 파일 존재 |
| L2-CLI | 워크플로우 디렉토리 구조 | `ls .claude/work-orders/_templates/` | 3개 템플릿 존재 |
| L4-Trace | R-008-F1 반영 | orchestrator.md의 tools 필드 | Agent(5개 워커) 화이트리스트 |
| L4-Trace | R-008-F2 반영 | orchestrator.md의 의사결정 트리 | 4패턴(A/B/C/D) 선택 로직 |
| L4-Trace | R-008-F4 반영 | work-orders/_templates/manifest.yaml | 워크플로우 상태 추적 스키마 |
| L4-Trace | R-008-F5 반영 | orchestrator.md의 Context Compression | 3단계 읽기 전략 |
| L4-Trace | R-008-F6 반영 | orchestrator.md의 Evaluation Loop | verdict 포맷 + max_iterations 3 |

## References

| Resource | Path/URL | Related Content |
|----------|---------|-----------------|
| Research (최종) | docs/07_organizational_agents/008_Research_조직아키텍처_오케스트레이터_최종.md | R-008-F1~F8 핵심 발견 |
| Scope | docs/07_organizational_agents/001_Scope_조직에이전트_전환.md | 사이클 1 범위 정의 |
| Synthesis | docs/07_organizational_agents/007_Synthesis_조직아키텍처연구.md | 4개 관점 교차 분석 |
| MAS 이론 | docs/002_gemini_deep_research.md | 5 MAS 구조, SOP, 안티패턴 |
| 5계층/페르소나 | docs/001_gemini_deep_research.md | 5개 핵심 계층, 페르소나 5요소 |
