---
id: "006"
title: "상태 관리 및 컨텍스트 전달 메커니즘"
category: agent
status: archived
created: 2026-03-14
summary: >
  에이전트 간 상태/결과 전달의 현행 메커니즘을 조사하고 구조화된 설계 방향을 도출했다.
  현재는 docs/ 디렉토리에 YAML frontmatter + Markdown body 형태로 산출물을 저장하되 에이전트 간
  명시적 인계 프로토콜이 없고, agent-memory는 빈 상태이며, 워크플로우 추적은 .claude/tmp/의
  체크리스트 파일로 최소한만 수행 중이다. 구조화된 인계 파일 포맷, 공유 기억 계층(_shared/),
  워크플로우 상태 파일(.claude/workflows/), 컨텍스트 윈도우 압축 전략을 설계 방향으로 제시한다.
keywords: [agent-report, 상태관리, 컨텍스트전달, 인계포맷, 기억체계, 워크플로우추적]
modules: [.claude/agent-memory, docs]
---

# 상태 관리 및 컨텍스트 전달 메커니즘

## Progress
### Completed
- [x] 현재 에이전트 산출물 패턴 분석
- [x] agent-memory 구조 및 확장 가능성 분석
- [x] 구조화된 인계 파일 포맷 설계 방향 도출
- [x] 컨텍스트 윈도우 관리 전략 분석
- [x] 워크플로우 상태 추적 메커니즘 설계
- [x] 종합 정리 및 Key Findings 작성
### Remaining
(없음)
### Current Status
분석 완료.

---

## Summary

현재 personality 프로젝트의 에이전트 시스템은 **산출물 저장은 일관된 포맷**으로 이루어지나, **에이전트 간 명시적 인계 메커니즘이 부재**하다. 5개 에이전트가 생산한 비평 문서(docs/06_에이전트비평/)는 동일한 YAML frontmatter + Markdown body 구조를 따르며 품질이 높으나, 이 산출물이 다음 에이전트에게 어떻게 전달되어야 하는지 프로토콜이 정의되어 있지 않다. agent-memory 체계는 구조만 설계되었고 실제 기억은 0건이다. 워크플로우 추적은 `.claude/tmp/`의 체크리스트 파일로 최소한만 수행된다. 이 보고서에서는 (1) 구조화된 인계 파일 포맷, (2) 공유 기억 계층, (3) 워크플로우 상태 추적 파일, (4) 컨텍스트 윈도우 관리 전략의 구체적 설계 방향을 도출한다.

---

## Details

### 1. 현재 에이전트 산출물 패턴 분석

#### 1-1. 산출물 저장 위치 및 형태

현재 에이전트가 산출물을 저장하는 패턴은 두 가지다:

| 패턴 | 위치 | 형태 | 사용 사례 |
|------|------|------|----------|
| **문서 산출물** | `docs/{토픽폴더}/{NNN}_{Category}_{Slug}.md` | YAML frontmatter + Markdown body | 비평, 연구, 종합 보고서 |
| **기억 산출물** | `.claude/agent-memory/{agent-name}/memories/{NNN}_{키워드}.yaml` | YAML | 발견, 결정, 패턴 (현재 0건) |

#### 1-2. 문서 산출물의 공통 구조

6개 비평 문서(docs/06_에이전트비평/001~006)를 분석한 결과, **모든 문서가 동일한 구조**를 따른다:

```
---
id: "NNN"
title: "제목"
category: agent | report
status: archived
created: YYYY-MM-DD
summary: >
  한 문단 요약
keywords: [...]
modules: [...]
---

# 제목

## Progress
### Completed / Remaining / Current Status

## Summary
## Details
## (Comprehensive Conclusion — 종합 문서만)
## References
```

**관찰된 특성**:
- **일관된 frontmatter 스키마**: id, title, category, status, created, summary, keywords, modules가 모든 문서에 존재
- **Progress 추적 내장**: 각 문서가 자체 완료/잔여 체크리스트를 포함
- **modules 필드**: 분석 대상 코드 모듈을 명시하여 다른 에이전트가 관련 범위를 파악 가능

#### 1-3. 종합 문서(Synthesis)의 교차 참조 패턴

`006_Synthesis_코드베이스비평.md`는 5개 개별 비평을 종합하는 패턴을 보여준다:
- **Team Composition 테이블**: 개별 보고서 링크
- **Cross-Analysis 섹션**: 공통 발견, 상충 의견, 시너지 효과
- **상대 경로 참조**: `[001_Agent_심리학비평.md](./001_Agent_심리학비평.md)`

**문제점**:
- 개별 비평 → 종합 문서 방향의 참조만 존재
- 개별 비평 문서에서 다른 비평을 참조하는 `related_documents` 같은 역방향 링크 없음
- 종합 문서가 개별 비평의 **어느 섹션**을 참조하는지 세밀한 앵커가 없음 (파일 단위 링크만)

#### 1-4. 에이전트 정의 파일의 산출물 명시 부재

5개 에이전트 정의 파일(`.claude/agents/*.md`)을 확인한 결과:
- **산출물 포맷**에 대한 명시적 규정이 없음
- **인계 절차**에 대한 규정이 없음
- `Collaboration Rules` 섹션에서 다른 에이전트와의 관계를 서술하나, 이는 역할 관계만 기술하고 **어떤 형태로 결과를 전달하는지**는 미정의

경로: `/Users/kampikrein/A/personality/.claude/agents/psychology-expert.md` (대표)

---

### 2. agent-memory 구조 및 확장 가능성 분석

#### 2-1. 현재 구조

```
.claude/agent-memory/
├── psychology-expert/
│   ├── _index.yaml          # index: [] (빈 배열)
│   └── memories/.gitkeep
├── mbti-expert/
│   ├── _index.yaml          # index: [] (빈 배열)
│   └── memories/.gitkeep
├── enneagram-expert/
│   ├── _index.yaml          # index: [] (빈 배열)
│   └── memories/.gitkeep
├── coding-expert/
│   ├── _index.yaml          # index: [] (빈 배열)
│   └── memories/.gitkeep
└── uiux-expert/
    ├── _index.yaml          # index: [] (빈 배열)
    └── memories/.gitkeep
```

**현황**: 5개 에이전트 모두 기억 0건. 구조만 설계되어 있고 실제로 사용된 적 없음.

#### 2-2. 기억 파일 스키마 분석

에이전트 프롬프트에 정의된 기억 파일 포맷:

```yaml
id: "NNN"
date: "YYYY-MM-DD"
type: finding | decision | pattern | review
keywords: ["키워드1", "키워드2"]
summary: "한 줄 요약"
context: |
  발견/결정이 이루어진 맥락
details: |
  구체적 내용
implications: |
  향후 작업에 미치는 영향
related_memories: []
```

**설계 의도**: 각 에이전트가 자신의 발견/결정을 누적하여, 다음 세션에서 `_index.yaml`의 keywords로 검색 후 관련 기억을 로드.

#### 2-3. 확장 가능성: 공유 기억 계층

현재 기억 체계는 **에이전트별 격리**만 존재한다. 조직 수준 공유 기억을 위한 설계 방향:

**제안 구조**:
```
.claude/agent-memory/
├── _shared/                          # 공유 기억 (조직 수준)
│   ├── _index.yaml                   # 공유 기억 인덱스
│   └── memories/
│       ├── 001_recovery_도메인명_변경.yaml
│       └── 002_인사이트_점수해석_방향.yaml
├── psychology-expert/                # 기존 개별 기억
│   ├── _index.yaml
│   └── memories/
...
```

**공유 기억 _index.yaml 스키마**:
```yaml
description: "조직 수준 공유 기억 인덱스"
storage_path: ".claude/agent-memory/_shared/memories/"
access_policy: read-all  # 모든 에이전트가 읽기 가능
write_policy: orchestrator-only  # 오케스트레이터만 쓰기 가능

index:
  - id: "001"
    date: "2026-03-13"
    type: decision
    source_agent: "orchestrator"        # 기억 생성 에이전트
    contributing_agents: ["psychology-expert", "mbti-expert", "enneagram-expert"]
    keywords: ["recovery", "도메인명", "교차발견"]
    summary: "recovery 도메인명을 변경하기로 결정"
    path: "memories/001_recovery_도메인명_변경.yaml"
```

**접근/수정 권한 관리**:
- **읽기**: 모든 에이전트가 작업 시작 시 `_shared/_index.yaml`도 함께 로드
- **쓰기**: 오케스트레이터만 공유 기억에 쓰기 가능 (환각 캐스케이딩 방지)
- **승격**: 개별 에이전트가 발견한 내용 중 교차 발견된 것을 오케스트레이터가 공유 기억으로 승격
- **에이전트 프롬프트 수정**: Memory System 섹션에 `_shared/` 참조 규칙 추가

**교차 참조 메커니즘**:
```yaml
# 개별 기억 파일에서 공유 기억 참조
related_memories:
  - "psychology-expert/002"
  - "_shared/001"            # 공유 기억 참조

# 공유 기억 파일에서 출처 기억 참조
source_memories:
  - agent: "psychology-expert"
    memory_id: "003"
  - agent: "mbti-expert"
    memory_id: "002"
```

---

### 3. 구조화된 인계 파일 포맷 설계 방향

#### 3-1. 설계 원칙

doc 002(Gemini Deep Research)에서 명시한 **구조화된 출력** 원칙:

> "두 LLM이 순수한 자연어로 대화하게 방치하면 의미 없는 잡담이나 과장된 표현이 섞이며 점진적으로 환각이 증폭되는 캐스케이딩(Cascading hallucinations) 현상이 발생한다. 이를 방지하기 위해 에이전트 간의 결과물 인계(Handover)는 반드시 엄격한 포맷 규칙에 따라 이루어져야 한다."

이를 Claude Code 에이전트 프레임워크에 적용할 때의 핵심 원칙:
1. **YAML frontmatter로 메타데이터 강제**: 소스/대상 에이전트, 작업 ID, 상태를 구조화
2. **Markdown body로 내용 전달**: 사람도 읽을 수 있는 형태 유지
3. **요약 + 상세 분리**: 컨텍스트 윈도우 효율을 위해 summary는 3줄 이내
4. **다음 단계 명시**: 수신 에이전트가 해야 할 작업을 구체적으로 기술

#### 3-2. 인계 파일 포맷 제안

```yaml
---
handover_id: "WF-001-STEP-02"           # 워크플로우ID-단계번호
workflow_id: "WF-001"                     # 상위 워크플로우 ID
created: "2026-03-14T10:30:00+09:00"
status: pending | accepted | completed | rejected

source:
  agent: "psychology-expert"
  task: "문항 20개 심리측정학적 분석"
  confidence: high | medium | low         # 자기 평가 신뢰도

target:
  agent: "coding-expert"
  expected_action: "점수 계산 로직 수정"

summary: >
  recovery 도메인의 점수 해석 방향이 역전되어 있음.
  높은 점수(>=75)가 P(유연성)인데 "구조적 계획" 행동을 추천하는 오류.
  InConflictModule, RecoveryModule, CareerModule의 분기 방향 수정 필요.

artifacts:                                # 참조할 산출물
  - path: "docs/06_에이전트비평/001_Agent_심리학비평.md"
    sections: ["### 3. 점수 엔진 분석", "### 4-3. RecoveryModule"]
  - path: "app/services/insights/conflict_module.rb"
    note: "line 25-40의 분기 조건 확인"

next_steps:                               # 수신 에이전트가 해야 할 것
  - "conflict_module.rb의 recovery 점수 분기 방향 역전"
  - "recovery_module.rb의 임계값 의미 재확인"
  - "수정 후 RSpec 테스트 추가"

constraints:                              # 수신 에이전트가 지켜야 할 것
  - "도메인명 자체 변경은 별도 워크플로우에서 진행"
  - "기존 테스트가 있다면 깨뜨리지 않을 것"

validation:                               # 검증 기준
  criteria: "높은 recovery 점수에 유연성 관련 행동 추천이 출력되어야 함"
  validator_agent: "psychology-expert"     # 검증 담당
---

# 인계 상세

## 배경
(자유 형식 Markdown — 필요한 경우 상세 설명)

## 분석 근거
(학술 근거, 코드 경로 등)

## 예상 영향
(수정 시 영향받는 다른 모듈)
```

#### 3-3. 인계 파일 저장 위치 및 명명 규칙

**저장 위치**: `.claude/handovers/`

```
.claude/handovers/
├── active/                    # 진행 중인 인계
│   ├── WF-001-STEP-02.md
│   └── WF-001-STEP-03.md
├── completed/                 # 완료된 인계 (아카이브)
│   └── WF-001-STEP-01.md
└── _index.yaml                # 전체 인계 인덱스
```

**명명 규칙**: `{workflow_id}-STEP-{step_number}.md`

**인덱스 파일**:
```yaml
active_handovers:
  - id: "WF-001-STEP-02"
    source: "psychology-expert"
    target: "coding-expert"
    status: pending
    created: "2026-03-14"
completed_handovers:
  - id: "WF-001-STEP-01"
    source: "orchestrator"
    target: "psychology-expert"
    status: completed
    completed_at: "2026-03-14"
```

#### 3-4. 환각 캐스케이딩 방지 설계

현재 `006_Synthesis_코드베이스비평.md`에서 관찰된 종합 패턴은 우수하나, 환각 캐스케이딩 위험이 있는 지점:

| 위험 지점 | 현재 상태 | 방지 방안 |
|----------|----------|----------|
| 에이전트 A의 발견을 에이전트 B가 사실로 수용 | 참조 문서만 있고 신뢰도 메타데이터 없음 | `confidence` 필드 도입 (high/medium/low) |
| 종합 시 요약 과정에서 의미 변형 | 자유 형식 요약 | `artifacts` 필드로 원문 위치 명시, 검증 에이전트 지정 |
| 여러 단계 인계 시 오류 누적 | 단계 간 추적 없음 | `workflow_id`로 전체 체인 추적, `validation` 필드로 검증 기준 명시 |

---

### 4. 컨텍스트 윈도우 관리 전략

#### 4-1. 현재 상황 분석

Claude Code 에이전트의 컨텍스트 윈도우 사용 요소:

| 요소 | 추정 토큰 수 | 비고 |
|------|------------|------|
| 에이전트 프롬프트 (psychology-expert) | ~1,500 | 110줄 Markdown |
| 비평 산출물 1개 (001_심리학비평) | ~10,000+ | 32KB 파일 |
| 종합 보고서 (006_Synthesis) | ~4,000 | 11KB 파일 |
| agent-memory 기억 파일 1개 | ~200-500 | YAML 구조 |

**문제**: 오케스트레이터가 5개 에이전트의 결과를 모두 읽으면 ~50,000 토큰 이상 소비. 추가 작업 지시와 도구 사용을 고려하면 컨텍스트 윈도우의 상당 부분을 차지.

#### 4-2. 요약/압축 전략

**3단계 압축 모델**:

```
Level 1: 전문 (Full)
  → 원본 산출물 전체
  → 사용: 해당 에이전트 자신이 이전 작업 복원 시
  → 예: docs/06_에이전트비평/001_Agent_심리학비평.md (32KB)

Level 2: 요약본 (Summary)
  → YAML frontmatter의 summary + Key Findings만 추출
  → 사용: 오케스트레이터가 여러 에이전트 결과 종합 시
  → 예: ~500 토큰/에이전트 → 5개 에이전트 = ~2,500 토큰

Level 3: 인계 포커스 (Handover)
  → 인계 파일의 summary + next_steps + constraints만
  → 사용: 수신 에이전트가 자기 작업 시작 시
  → 예: ~200 토큰/인계
```

**구현 방안**:

1. **오케스트레이터 프롬프트에 압축 규칙 인코딩**:
   - "5개 이상 산출물을 종합할 때는 각 문서의 frontmatter summary + Key Findings 섹션만 읽어라"
   - "상세 내용이 필요하면 특정 섹션만 Grep으로 검색하라"

2. **인계 파일에 Level 정보 포함**:
   ```yaml
   context_level: summary    # full | summary | handover
   full_document: "docs/06_에이전트비평/001_Agent_심리학비평.md"
   ```

3. **docs/ 문서에 Key Findings 섹션 필수화**:
   - 현재 비평 문서에는 독립적인 Key Findings 섹션이 없음 (Comprehensive Conclusion이 유사 역할)
   - 모든 에이전트 산출물에 `## Key Findings` (3-5개 bullet) 섹션 필수

#### 4-3. 단계별 컨텍스트 전달량 최적화

| 워크플로우 단계 | 오케스트레이터 필요 컨텍스트 | 워커 에이전트 필요 컨텍스트 |
|---------------|------------------------|------------------------|
| 작업 분해 | 각 에이전트의 역할 요약 (~500 토큰) | - |
| 작업 위임 | 인계 파일 summary (~200 토큰) | 인계 파일 전문 (~500 토큰) + 참조 파일 |
| 결과 수집 | 각 에이전트 결과의 Level 2 요약 | - |
| 교차 검증 | 검증 대상 결과의 Level 1 전문 (1개) | 검증 대상 결과 전문 + 자기 도메인 기억 |
| 최종 종합 | Level 2 요약 전체 + 상충점만 Level 1 | - |

---

### 5. 워크플로우 상태 추적 메커니즘

#### 5-1. 현재 상태

현재 워크플로우 추적은 `.claude/tmp/pipeline_{topic}_checklist.md`로 이루어진다:

경로: `/Users/kampikrein/A/personality/.claude/tmp/pipeline_organizational_agents_checklist.md`

```
topic: organizational_agents
scope: docs/07_organizational_agents/001_Scope_조직에이전트_전환.md
auto_run: true

[cycle-1] research | docs/07_organizational_agents/001_Scope_...md
[cycle-1] makeplan | (pending)
[cycle-1] implementation | (pending)
...
```

**제한점**:
- 사이클/단계 레벨만 추적하며 에이전트별 작업 상태는 미포함
- 실패/재시도 이력 없음
- 체크포인트 데이터 없음 (어디까지 완료되었는지만 표시)
- 에이전트 간 인계 상태 추적 불가

#### 5-2. 워크플로우 상태 파일 설계

**저장 위치**: `.claude/workflows/`

```
.claude/workflows/
├── active/
│   └── WF-001.yaml           # 활성 워크플로우
├── completed/
│   └── WF-000.yaml           # 완료된 워크플로우
└── _registry.yaml             # 워크플로우 목록
```

**워크플로우 상태 파일 스키마**:

```yaml
workflow_id: "WF-001"
title: "recovery 도메인명 변경 및 인사이트 수정"
created: "2026-03-14T09:00:00+09:00"
updated: "2026-03-14T11:30:00+09:00"
status: in_progress | completed | failed | paused
initiated_by: "orchestrator"

# 단계 정의
steps:
  - step_id: "STEP-01"
    title: "심리측정학적 분석"
    assigned_to: "psychology-expert"
    status: completed
    started_at: "2026-03-14T09:10:00+09:00"
    completed_at: "2026-03-14T09:45:00+09:00"
    output: "docs/06_에이전트비평/001_Agent_심리학비평.md"
    handover: ".claude/handovers/completed/WF-001-STEP-01.md"

  - step_id: "STEP-02"
    title: "점수 분기 로직 수정"
    assigned_to: "coding-expert"
    status: in_progress
    started_at: "2026-03-14T10:00:00+09:00"
    depends_on: ["STEP-01"]
    input_handover: ".claude/handovers/active/WF-001-STEP-02.md"

  - step_id: "STEP-03"
    title: "수정 검증"
    assigned_to: "psychology-expert"
    status: pending
    depends_on: ["STEP-02"]

# 체크포인트 (중단/재개 지원)
checkpoint:
  last_completed_step: "STEP-01"
  last_updated: "2026-03-14T10:00:00+09:00"
  context_restore_files:
    - "docs/06_에이전트비평/001_Agent_심리학비평.md"
    - ".claude/handovers/active/WF-001-STEP-02.md"
  resume_instruction: >
    STEP-02부터 재개. coding-expert에게 WF-001-STEP-02.md를
    전달하고 점수 분기 로직 수정 작업 위임.

# 실패/재시도 이력
error_log:
  - step_id: "STEP-02"
    attempt: 1
    error: "conflict_module.rb에서 테스트 실패"
    timestamp: "2026-03-14T10:30:00+09:00"
    resolution: "분기 조건 >= 75를 <= 25로 변경 후 재시도"
```

#### 5-3. 중단/재개 지원 (체크포인트 패턴)

Claude Code 에이전트는 세션 간 상태를 유지하지 않으므로, 중단/재개를 위해 **파일 기반 체크포인트**가 필수적이다.

**체크포인트 설계**:

1. **체크포인트 저장 시점**: 각 step 완료 시 자동으로 워크플로우 상태 파일 업데이트
2. **복원 정보**:
   - `last_completed_step`: 마지막 완료 단계
   - `context_restore_files`: 재개 시 읽어야 할 파일 목록
   - `resume_instruction`: 재개 시 오케스트레이터에게 전달할 지시문
3. **재개 프로세스**:
   - 오케스트레이터가 `.claude/workflows/active/WF-001.yaml` 로드
   - `checkpoint.last_completed_step` 확인
   - `context_restore_files` 읽기
   - `resume_instruction` 따라 다음 단계 실행

#### 5-4. 실패 시 롤백/재시도 메커니즘

**재시도 전략**:
```yaml
retry_policy:
  max_attempts: 2                    # 최대 재시도 횟수
  on_failure: "escalate_to_human"    # 최대 초과 시 사용자 개입 요청
```

**롤백은 불필요**: Claude Code 에이전트의 특성상 파일 수정은 git으로 추적되므로, 실패 시:
1. `git diff`로 변경 사항 확인
2. `git checkout -- {files}`로 개별 파일 복원 (사용자 승인 하에)
3. error_log에 실패 원인 기록
4. 재시도 또는 사용자 개입 요청

이 접근법은 doc 002에서 경고한 "보이지 않는 상태(Invisible State)" 안티패턴을 방지한다. 모든 상태가 파일로 명시적으로 존재하며 git으로 추적 가능하다.

---

## Key Findings

1. **산출물 포맷은 일관되나 인계 프로토콜 부재**: 5개 에이전트 비평 문서는 동일한 YAML frontmatter + Markdown body 구조를 따르나, 에이전트 A의 산출물이 에이전트 B에게 어떻게 전달되어야 하는지 정의된 프로토콜이 없다. 현재는 사용자가 수동으로 중재.

2. **agent-memory 체계는 미사용 상태**: 5개 에이전트 모두 기억 0건. 설계는 잘 되어 있으나 실제 기억이 축적되지 않아, 세션 간 학습이 발생하지 않는다. 공유 기억(`_shared/`) 계층 추가 전에 **개별 기억 활용부터 실현**해야 한다.

3. **종합 문서(Synthesis) 패턴이 인계 포맷의 기초가 될 수 있음**: `006_Synthesis_코드베이스비평.md`의 교차 분석 패턴(공통 발견, 상충 의견, 시너지)은 오케스트레이터의 결과 종합 방식으로 채택 가능. 단, confidence 필드와 검증 에이전트 지정이 추가되어야 환각 캐스케이딩 방지.

4. **컨텍스트 윈도우 압박이 실질적 제약**: 비평 산출물 1개가 ~10,000 토큰. 5개를 모두 읽으면 오케스트레이터의 컨텍스트 윈도우 대부분을 소비. **3단계 압축 모델**(전문/요약/인계)과 **Key Findings 섹션 필수화**가 필요.

5. **워크플로우 추적은 최소한만 존재**: `.claude/tmp/` 체크리스트는 사이클/단계만 추적하고 에이전트별 상태, 실패 이력, 체크포인트를 포함하지 않는다. `.claude/workflows/` 디렉토리로 이전하여 YAML 기반 상태 추적 도입이 필요.

6. **"보이지 않는 상태" 안티패턴 회피가 핵심 설계 원칙**: Claude Code 에이전트는 세션 간 메모리를 공유하지 않으므로, 모든 상태가 파일로 명시적으로 존재해야 한다. 인계 파일, 워크플로우 상태 파일, 기억 파일의 세 축이 이를 보장.

---

## Recommendations

### 즉시 적용 가능 (기존 구조 활용)

1. **에이전트 프롬프트에 산출물 포맷 규정 추가**: 각 에이전트의 `.claude/agents/*.md`에 "Output Format" 섹션을 추가하여 YAML frontmatter 필수 필드와 Key Findings 섹션을 강제.

2. **agent-memory 활성화**: 다음 에이전트 작업 시 기억 생성을 의무화. 최소 1건의 finding/decision을 기록하도록 오케스트레이터가 지시.

3. **docs/ 문서에 Key Findings 섹션 필수화**: 오케스트레이터가 Level 2 요약으로 효율적으로 종합할 수 있도록.

### 사이클 2에서 구현 (소통 프로토콜 & SOP)

4. **`.claude/handovers/` 디렉토리 및 인계 파일 포맷 도입**: 본 보고서 3-2절의 스키마를 기반으로.

5. **`.claude/workflows/` 디렉토리 및 워크플로우 상태 파일 도입**: 본 보고서 5-2절의 스키마를 기반으로.

6. **공유 기억 계층(`_shared/`) 도입**: 교차 발견 사항을 조직 수준으로 승격하는 메커니즘.

### 오케스트레이터 프롬프트에 반영할 규칙

7. **컨텍스트 관리 규칙 인코딩**: "5개 이상 산출물 종합 시 Level 2(summary + Key Findings)만 읽고, 상세 필요 시 특정 섹션만 Grep"

8. **인계 시 confidence 필드 필수**: 환각 캐스케이딩 방지를 위해 모든 인계에 자기 평가 신뢰도를 포함.

---

## References

- `/Users/kampikrein/A/personality/docs/06_에이전트비평/001_Agent_심리학비평.md` ~ `006_Synthesis_코드베이스비평.md` — 현행 에이전트 산출물 6개
- `/Users/kampikrein/A/personality/.claude/agent-memory/` — 5개 에이전트 기억 구조 (전체 빈 상태)
- `/Users/kampikrein/A/personality/.claude/agents/psychology-expert.md` — 대표 에이전트 정의 (Memory System 섹션)
- `/Users/kampikrein/A/personality/.claude/tmp/pipeline_organizational_agents_checklist.md` — 현행 워크플로우 추적 파일
- `/Users/kampikrein/A/personality/docs/002_gemini_deep_research.md` (87행) — 구조화된 출력 및 환각 캐스케이딩 방지 원칙
- `/Users/kampikrein/A/personality/docs/07_organizational_agents/001_Scope_조직에이전트_전환.md` — 상위 Scope 문서
- `/Users/kampikrein/A/personality/docs/07_organizational_agents/002_Research_조직아키텍처_오케스트레이터.md` — 연구 총괄 문서
- `/Users/kampikrein/A/personality/docs/05_agent_design/006_Synthesis_전문에이전트구성.md` — 에이전트 설계 종합 보고서
