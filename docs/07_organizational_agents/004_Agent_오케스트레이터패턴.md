---
id: "004"
title: "오케스트레이터 설계 패턴 매핑"
category: agent
status: archived
created: 2026-03-14
summary: >
  MAS 이론(계층형+파이프라인+평가루프)을 Claude Code 에이전트 프레임워크에 매핑하여
  오케스트레이터 설계 방안을 도출. 계층형 위임은 Agent tool의 subagent_type으로 커스텀
  에이전트를 스폰하거나 파일 기반 지시서로 구현 가능. 파이프라인은 오케스트레이터 프롬프트에
  단계별 체인을 인코딩하고 산출물 파일로 릴레이. 평가루프는 maxTurns 기반 가드레일과
  구조화된 평가 기준으로 종료 조건 판정. 하이브리드 통합 시 워크플로우 유형별 패턴 선택
  로직을 프롬프트에 의사결정 트리로 내장.
keywords: [agent-report, 오케스트레이터, 계층형, 파이프라인, 평가루프, 하이브리드, MAS패턴매핑]
modules: [.claude/agents]
---

# 오케스트레이터 설계 패턴 매핑

## Progress
### Completed
- [x] 참고 자료 분석 (doc 001, doc 002, scope 문서, 현재 에이전트 구조)
- [x] 계층형 패턴 구현 방안 도출
- [x] 파이프라인 패턴 구현 방안 도출
- [x] 평가/정제 루프 구현 방안 도출
- [x] 하이브리드 통합 설계
- [x] 종합 정리 및 Key Findings 작성
### Remaining
- (없음)
### Current Status
조사 완료. 최종 보고서 작성됨.

## Summary

MAS 이론의 세 가지 핵심 패턴(계층형, 파이프라인, 평가/정제 루프)을 Claude Code 에이전트 프레임워크의 제약 안에서 구현하는 구체적 방안을 도출했다. 핵심 제약은: (1) 에이전트 간 직접 통신 불가, (2) 순차 실행만 가능(병렬 불가), (3) 상태 전달은 파일 시스템 의존, (4) maxTurns 제한. 이 제약을 고려하여, 오케스트레이터가 프롬프트 내 의사결정 트리와 파일 기반 산출물 릴레이를 통해 세 패턴을 하이브리드로 운영하는 설계를 제안한다.

## Details

### 1. 참고 자료 분석 결과

#### doc 002 핵심 추출 (MAS 구조)

| 패턴 | 핵심 원리 | personality 프로젝트 적합성 |
|------|----------|-------------------------|
| 계층형 | 매니저가 하위 작업 분해 → 워커에 위임 → 결과 종합 | **높음** — 성격 서비스 SDLC가 명확한 단계적 구조 |
| 순차 파이프라인 | 에이전트 A → B → C 순차 릴레이, 이전 출력이 다음 입력 | **높음** — 문항설계→구현→검증 체인에 적합 |
| 병렬/디스패처 | 다수 에이전트 동시 수행 후 결과 취합 | **낮음** — Claude Code 동시 실행 불가 |
| 그룹 채팅 | 공유 대화 공간에서 자유 토론 | **낮음** — 토큰 비용 과도, 종료 조건 불명확 |
| 평가/정제 루프 | 생성 → 비판 → 수정 반복 | **높음** — 학술 검증/법적 검증 필수 |

#### doc 002 안티 패턴 3종

1. **모놀리식 (Monolithic)**: 단일 거대 프롬프트에 모든 책임 전가 → 환각, 컨텍스트 소실
2. **보이지 않는 상태 (Invisible State)**: 중간 산출물을 LLM 대화 내역에만 의존 → 컨텍스트 유실
3. **원형 변형 ("As-Is" 임의 변형)**: 원문 데이터를 LLM이 자의적으로 윤문 → 법적 리스크

#### doc 001 5개 핵심 계층

1. 인지(Perception) — 입력 수집 및 정형화
2. 기억(Memory) — 단기/장기 지식 관리
3. 추론(Planning) — 목표를 실행 가능한 워크플로우로 분해
4. 행동(Action) — 도구 사용 및 실행
5. 피드백(Feedback) — 결과 평가 및 방향 보정

#### 현재 에이전트 구조 현황

| 속성 | 현황 | 조직화 격차 |
|------|------|-----------|
| 역할 정의 | Role + Core Principles + Analysis Framework | Goal/Backstory 부재 (피상적) |
| 협업 규칙 | Collaboration Rules 섹션 존재 | 텍스트 기반, 구조화된 인계 포맷 없음 |
| 기억 체계 | 에이전트별 독립 memory | 교차 참조 없음, 조직 수준 공유 기억 부재 |
| 도구 | coding/uiux만 Bash | Agent tool 미보유, 오케스트레이션 도구 없음 |
| 위임 메커니즘 | 없음 | 사용자가 수동으로 에이전트 전환 |

---

### 2. 계층형 패턴 구현 방안

#### 2.1 위임의 실현 형태: 3가지 옵션 비교

Claude Code에서 오케스트레이터가 워커 에이전트에 "위임"을 수행하는 방법은 세 가지가 있다:

**옵션 A: Agent tool의 subagent_type으로 커스텀 에이전트 스폰**

```
tools: [Read, Write, Edit, Glob, Grep, Bash, Agent]
```

오케스트레이터 에이전트 파일에 Agent tool을 포함시키고, `subagent_type` 파라미터에 `.claude/agents/` 내 에이전트명을 지정하여 서브에이전트를 스폰한다. 이 경우:
- 오케스트레이터가 작업 지시를 Agent tool의 프롬프트로 전달
- 서브에이전트의 산출물은 Agent tool의 반환값으로 수신
- 각 서브에이전트 호출은 독립 컨텍스트에서 실행

**실현 가능성**: 높음. Claude Code의 Agent tool은 커스텀 에이전트를 `subagent_type`으로 지정 가능한 것으로 관찰됨. 단, 정확한 스펙은 003 문서의 프레임워크 제약 조사에서 확정 필요.

**옵션 B: 파일 기반 지시서 (File-based Dispatch)**

오케스트레이터가 작업 지시서를 구조화된 파일로 작성하고, 사용자가 해당 에이전트를 호출하여 지시서를 읽게 하는 간접 위임:

```markdown
<!-- .claude/work-orders/WO-001_문항설계.md -->
---
assigned_to: mbti-expert
priority: high
status: pending
depends_on: []
---
# 작업 지시서: 새 문항 세트 설계
## 목표
에너지 도메인(E-I)에 5개 추가 문항 설계
## 입력물
- 기존 문항: db/seeds/questions.rb 참조
- 심리학 검증 기준: .claude/agent-memory/psychology-expert/memories/001_문항기준.yaml
## 산출물 형식
(구조화된 YAML 포맷 지정)
```

**실현 가능성**: 높음. 파일 시스템 접근은 모든 에이전트가 보유. 단, 사용자 개입이 필요하여 자동화 수준 낮음.

**옵션 C: 오케스트레이터가 Agent tool로 직접 스폰 (하이브리드)**

옵션 A와 B의 결합. 오케스트레이터가 Agent tool로 서브에이전트를 스폰하되, 복잡한 작업 지시는 파일에 먼저 기록한 후 서브에이전트에게 해당 파일을 읽도록 지시. 이렇게 하면:
- 작업 지시가 컨텍스트 윈도우를 과도하게 소비하지 않음
- 작업 지시서가 파일로 남아 감사 추적(audit trail) 가능
- 보이지 않는 상태(Invisible State) 안티 패턴 방지

**실현 가능성**: 높음. **권장 방안.**

#### 2.2 작업 분해 로직의 프롬프트 인코딩

오케스트레이터의 프롬프트에 작업 분해 의사결정 트리를 명시적으로 인코딩한다:

```markdown
# Task Decomposition Protocol

사용자 요청을 받으면 다음 순서로 분해하라:

## Step 1: 작업 유형 분류
- **기능 개발**: 새 기능 추가, 기존 기능 수정 → 파이프라인 패턴
- **콘텐츠 검증**: 문항/설명 텍스트의 학술적 타당성 검증 → 평가루프 패턴
- **버그 수정**: 기존 코드의 오류 수정 → 단일 에이전트 위임
- **설계 논의**: 아키텍처, UX 방향 등 → 순차 자문 패턴

## Step 2: 필요 에이전트 식별
- 문항/유형론 관련 → mbti-expert 또는 enneagram-expert
- 학술 타당성 → psychology-expert
- 코드 구현 → coding-expert
- UI/UX → uiux-expert

## Step 3: 실행 순서 결정
- 도메인 전문가(문항/유형론) → 학술 검증(psychology) → 코드 구현(coding) → UI(uiux)
- 각 단계의 산출물이 다음 단계의 입력이 됨

## Step 4: 작업 지시서 작성
- 각 에이전트에 대한 구체적 지시를 .claude/work-orders/ 에 작성
- 입력물, 산출물 형식, 품질 기준을 명시
```

#### 2.3 작업 분해 트리 예시: "새 MBTI 문항 세트 추가"

```
사용자 요청: "에너지(E-I) 도메인에 5개 문항을 추가해 주세요"
│
├── [오케스트레이터] 작업 분류: 기능 개발 → 파이프라인 + 평가루프
│
├── Step 1: [mbti-expert] 문항 초안 설계
│   ├── 입력: 기존 E-I 문항(db/seeds/), 차별화 기준
│   └── 산출물: 5개 문항 초안 (YAML)
│
├── Step 2: [psychology-expert] 학술 검증 ← 평가루프 시작
│   ├── 입력: Step 1 산출물
│   ├── 검증: 바넘 효과, 구성 타당도, 변별력
│   └── 산출물: 검증 리포트 + 수정 권고
│
├── Step 2b: [mbti-expert] 수정 반영 (필요 시 Step 2 반복, 최대 2회)
│
├── Step 3: [coding-expert] 구현
│   ├── 입력: 검증 완료된 문항 YAML
│   ├── 작업: seeds 파일 추가, 테스트 작성
│   └── 산출물: 커밋 가능한 코드
│
├── Step 4: [uiux-expert] 표시 검토 (선택적)
│   ├── 입력: 문항 텍스트, UI 컴포넌트
│   └── 산출물: UI 조정 권고
│
└── [오케스트레이터] 결과 종합 및 사용자 보고
```

---

### 3. 파이프라인 패턴 구현 방안

#### 3.1 순차적 에이전트 호출 체인

Claude Code의 순차 실행 특성은 파이프라인 패턴에 자연스럽게 부합한다. 오케스트레이터가 Agent tool로 에이전트를 하나씩 스폰하면 자연스럽게 순차 파이프라인이 형성된다.

**표준 파이프라인 템플릿**:

| 단계 | 담당 에이전트 | 입력 | 산출물 | 다음 단계 전달 |
|------|------------|------|--------|-------------|
| 1. 요구사항 정의 | 도메인 전문가 (mbti/enneagram) | 사용자 요청 | 구조화된 요구사항 YAML | 파일 기반 |
| 2. 학술 검증 | psychology-expert | 요구사항 YAML | 검증 리포트 | 파일 기반 |
| 3. 기술 설계 | coding-expert | 검증된 요구사항 | 구현 계획 + 코드 | 파일 기반 |
| 4. UI 적용 | uiux-expert | 구현 결과 | UI 조정 | 파일 기반 |
| 5. 종합 검토 | 오케스트레이터 | 전 단계 산출물 | 최종 보고 | 사용자에게 |

#### 3.2 산출물 전달 메커니즘

**파일 기반 릴레이 (권장)**:

각 에이전트의 산출물을 구조화된 파일로 저장하고, 다음 에이전트에게 해당 파일 경로를 전달한다.

```
.claude/work-orders/
├── WO-2026-0314-001/           # 워크플로우 인스턴스
│   ├── _manifest.yaml           # 전체 워크플로우 상태
│   ├── step-1_요구사항.yaml      # mbti-expert 산출물
│   ├── step-2_검증리포트.yaml    # psychology-expert 산출물
│   ├── step-3_구현계획.yaml      # coding-expert 산출물
│   └── step-4_UI검토.yaml       # uiux-expert 산출물
```

**_manifest.yaml 구조**:

```yaml
workflow_id: "WO-2026-0314-001"
type: pipeline  # pipeline | evaluation_loop | hybrid
request: "에너지(E-I) 도메인에 5개 문항 추가"
created: "2026-03-14"
status: in_progress  # pending | in_progress | completed | failed

steps:
  - step: 1
    agent: mbti-expert
    status: completed
    output_file: step-1_요구사항.yaml
  - step: 2
    agent: psychology-expert
    status: in_progress
    input_files: [step-1_요구사항.yaml]
    output_file: step-2_검증리포트.yaml
  - step: 3
    agent: coding-expert
    status: pending
    input_files: [step-1_요구사항.yaml, step-2_검증리포트.yaml]
    output_file: step-3_구현계획.yaml

current_step: 2
max_retries_per_step: 2
```

이 구조는 doc 002의 "보이지 않는 상태" 안티 패턴을 방지한다. 모든 중간 상태가 명시적 파일로 존재하며 감사 추적이 가능하다.

#### 3.3 오류 복구 패턴

**에이전트 레벨 오류**:
- maxTurns 초과로 에이전트 중단 시: manifest에 `status: failed` 기록, 오케스트레이터가 재시도 또는 대체 전략 결정
- 산출물 포맷 불일치 시: 오케스트레이터가 포맷 검증 후 동일 에이전트에 재지시

**워크플로우 레벨 오류**:
- 이전 단계 결과가 부적합 시: 해당 단계로 롤백하여 재실행
- manifest의 `max_retries_per_step` 초과 시: 워크플로우를 `failed`로 마킹하고 사용자에게 보고

#### 3.4 구체적 워크플로우 예시: "유형 설명 텍스트 작성"

```
Pipeline: 16개 MBTI 유형 설명 텍스트 작성

Step 1: [mbti-expert] 유형별 핵심 특성 정리
  입력: 기존 유형 설명 (app/services/insights/)
  산출물: 16유형 × {핵심특성, 강점, 성장영역, 관계패턴} YAML

Step 2: [psychology-expert] 학술 검증
  입력: Step 1 산출물
  검증: 각 특성의 학술 근거, 바넘 효과 체크, 결정론적 표현 제거
  산출물: 검증 리포트 + 수정된 특성 YAML

Step 3: [coding-expert] 데이터 구조 구현
  입력: 검증된 특성 YAML
  작업: seeds 파일 생성, InsightService 확장
  산출물: 구현 코드 + 테스트

Step 4: [uiux-expert] 표현 검토
  입력: 유형 설명 텍스트 + UI 컨텍스트
  작업: 톤앤매너, 가독성, 반응형 레이아웃
  산출물: 최종 텍스트 + UI 권고
```

---

### 4. 평가/정제 루프 구현 방안

#### 4.1 반복 구조 설계

평가/정제 루프는 생성 에이전트와 비판 에이전트의 쌍으로 구성된다. Claude Code에서 이를 구현하는 방법:

```
오케스트레이터
  │
  ├─→ [생성 에이전트] 초안 작성
  │     └─→ 산출물 파일 저장
  │
  ├─→ [비판 에이전트] 검토
  │     ├─→ 산출물 파일 읽기
  │     ├─→ 평가 기준 대조
  │     └─→ 평가 결과 파일 저장 (pass/fail + 피드백)
  │
  ├─→ [오케스트레이터] 종료 조건 판정
  │     ├─→ pass → 다음 단계 진행
  │     └─→ fail → 생성 에이전트에 피드백 전달, 재생성 지시
  │
  └─→ (반복, 최대 N회)
```

오케스트레이터는 비판 에이전트의 반환값에서 `verdict: pass/fail`을 파싱하여 루프 제어를 수행한다. 이것은 프롬프트 레벨의 제어 흐름으로, 코드 레벨 런타임이 아닌 오케스트레이터의 추론 능력에 의존한다.

#### 4.2 종료 조건 판정

**정량적 기준**:

비판 에이전트의 평가 결과를 구조화된 형태로 요구한다:

```yaml
# 평가 결과 파일 포맷
evaluation:
  verdict: pass | fail | conditional_pass
  iteration: 1
  max_iterations: 3

  criteria:
    - name: "학술 근거 충족"
      status: pass
      details: "Costa & McCrae(1992) 참조 확인"
    - name: "바넘 효과 없음"
      status: fail
      details: "'당신은 깊이 생각하는 편입니다'는 모든 유형에 해당 가능"
      fix_suggestion: "구체적 행동 예시로 대체"
    - name: "결정론적 표현 배제"
      status: pass

  overall_score: 2/3  # pass 기준: 3/3

  feedback_for_revision: |
    1. 문항 3의 바넘 효과 표현을 행동 기반으로 수정
    2. (구체적 수정 지시)
```

**종료 조건 판정 규칙** (오케스트레이터 프롬프트에 인코딩):

```markdown
## 평가 루프 종료 조건

1. verdict가 "pass"이면 즉시 종료, 다음 단계 진행
2. verdict가 "conditional_pass"이면:
   - 경미한 수정만 필요 → 1회 추가 수정 후 통과 처리
3. verdict가 "fail"이면:
   - iteration < max_iterations → 피드백 전달 후 재생성
   - iteration >= max_iterations → 워크플로우 중단, 사용자에게 보고
4. 어떤 경우에도 max_iterations(기본: 3)를 초과하지 않는다
```

#### 4.3 무한 루프 방지 가드레일

1. **최대 반복 횟수 하드코딩**: 오케스트레이터 프롬프트에 `max_iterations: 3`을 명시. 이는 에이전트의 maxTurns 제약과도 연동.
2. **단조 개선 감시**: 이전 iteration의 평가 점수와 현재를 비교. 점수가 개선되지 않으면 루프 중단.
3. **턴 예산 관리**: 오케스트레이터의 maxTurns를 30으로 설정하고, 평가루프 1회에 약 4-6턴(스폰 2회 + 판정)을 소비하므로 최대 5회 루프 가능. 안전 마진을 고려해 3회로 제한.
4. **manifest에 반복 이력 기록**: 매 반복의 평가 결과와 점수를 manifest에 누적하여 추적.

#### 4.4 구체적 예시: coding → psychology 학술 검증 루프

```
시나리오: coding-expert가 작성한 점수 계산 로직의 심리측정학적 타당성 검증

Iteration 1:
  [coding-expert]
    → PercentileScoreCalculator 구현 (z-score 기반 백분위 산출)
    → 산출물: scoring_logic_v1.yaml

  [psychology-expert] 평가:
    ├── 검증 항목:
    │   ├── 정규분포 가정의 적절성: pass
    │   ├── 표본 크기 고려: fail ("초기 데이터 부족 시 z-score 불안정")
    │   └── 문항반응이론(IRT) 적용 가능성: conditional
    └── verdict: fail
    └── fix_suggestion: "최소 표본 크기 임계값(N≥30) 검사 로직 추가"

Iteration 2:
  [coding-expert]
    → 표본 크기 검사 가드 추가, N<30일 때 단순 합산 점수로 폴백
    → 산출물: scoring_logic_v2.yaml

  [psychology-expert] 평가:
    ├── 표본 크기 가드: pass
    ├── 폴백 로직 적절성: pass
    └── verdict: pass

→ 루프 종료, 다음 파이프라인 단계로 진행
```

---

### 5. 하이브리드 통합 설계

#### 5.1 세 패턴의 단일 오케스트레이터 통합

오케스트레이터 에이전트는 하나의 프롬프트에 세 패턴의 실행 로직을 모두 포함하되, 워크플로우 유형에 따라 적절한 패턴을 선택한다.

**오케스트레이터 에이전트 설계 골격**:

```markdown
# .claude/agents/orchestrator.md (설계 골격)

---
name: orchestrator
description: 작업 분해, 에이전트 위임, 결과 종합을 담당하는 조직 지휘 에이전트
model: opus  # 추론 능력이 중요하므로 상위 모델
tools: [Read, Write, Edit, Glob, Grep, Bash, Agent]
permissionMode: acceptEdits
maxTurns: 30
---

# Role
성격 서비스 개발 프로젝트의 오케스트레이터.
사용자 요청을 분석하여 적절한 전문 에이전트에 위임하고,
결과를 종합하여 보고한다. 직접 도메인 작업을 수행하지 않는다.

# Workflow Pattern Selection

사용자 요청을 분석하여 아래 중 적합한 패턴을 선택한다:

## Pattern A: 파이프라인 (순차 위임)
적용 조건:
- 새 기능 개발 (문항 추가, 유형 설명 작성, 서비스 구현)
- 명확한 단계가 존재하는 작업
실행: 도메인 전문가 → 학술 검증 → 코드 구현 → UI 검토

## Pattern B: 평가/정제 루프
적용 조건:
- 콘텐츠 품질 검증 (기존 문항/설명 텍스트 검토)
- 코드의 도메인 정합성 검증
- 학술 근거 확인이 필요한 모든 텍스트
실행: 생성 에이전트 → 비판 에이전트 → 재생성 (최대 3회)

## Pattern C: 하이브리드 (파이프라인 + 내장 루프)
적용 조건:
- 새 기능 개발 중 콘텐츠 검증이 포함된 경우
실행: 파이프라인 진행 중 특정 단계에서 평가루프 삽입

## Pattern D: 단일 위임
적용 조건:
- 단일 도메인 전문가로 해결 가능한 작업
- 버그 수정, 간단한 코드 변경
실행: 해당 에이전트에 직접 위임

# Agent Registry (워커 에이전트 목록)
- psychology-expert: 학술 근거 검증, 심리측정학, 윤리 검토
- mbti-expert: MBTI 문항 설계, 유형 설명, 한국 문화 맥락
- enneagram-expert: 애니어그램 문항 설계, 유형 설명
- coding-expert: Rails 구현, TDD, 데이터 모델
- uiux-expert: UI/UX 설계, 접근성, 반응형

# Execution Protocol
1. 사용자 요청 수신 → 작업 유형 분류 → 패턴 선택
2. manifest 파일 생성 (.claude/work-orders/)
3. 에이전트 순차 스폰 (Agent tool 사용)
4. 각 단계 산출물 수신 → 품질 1차 확인 → 다음 단계 투입
5. 평가루프 필요 시 루프 실행 (가드레일 준수)
6. 전체 완료 후 결과 종합 → 사용자에게 보고
```

#### 5.2 워크플로우 유형별 패턴 선택 로직

| 사용자 요청 유형 | 선택 패턴 | 에이전트 체인 | 평가 루프 포함 |
|---------------|----------|------------|-------------|
| 새 문항 세트 추가 | 하이브리드(C) | mbti/ennea → psychology → coding → uiux | psychology 검증 루프 |
| 유형 설명 텍스트 작성 | 하이브리드(C) | mbti/ennea → psychology → coding → uiux | psychology 검증 루프 |
| 기존 문항 검토 | 평가루프(B) | psychology ↔ mbti/ennea (루프) | 있음 |
| 점수 계산 로직 변경 | 하이브리드(C) | coding → psychology → coding | psychology 검증 루프 |
| UI 개선 | 파이프라인(A) | uiux → coding | 없음 |
| 버그 수정 | 단일 위임(D) | coding | 없음 |
| 학술 근거 조사 | 단일 위임(D) | psychology | 없음 |

#### 5.3 doc 001 5개 핵심 계층과의 매핑

오케스트레이터의 워크플로우를 doc 001의 5개 계층에 매핑한다:

| 계층 | 오케스트레이터에서의 실현 | 구현 위치 |
|------|---------------------|----------|
| **인지 (Perception)** | 사용자 요청 파싱, 작업 유형 분류, 필요 에이전트 식별 | 프롬프트의 Task Decomposition Protocol |
| **기억 (Memory)** | manifest 파일로 워크플로우 상태 관리, agent-memory에서 과거 패턴 참조 | `.claude/work-orders/`, `.claude/agent-memory/orchestrator/` |
| **추론 (Planning)** | 패턴 선택, 에이전트 체인 결정, 실행 순서 최적화 | 프롬프트의 Workflow Pattern Selection |
| **행동 (Action)** | Agent tool로 서브에이전트 스폰, 파일 I/O로 산출물 관리 | Agent tool + Read/Write |
| **피드백 (Feedback)** | 평가루프의 verdict 판정, 단조 개선 감시, 워크플로우 성공/실패 판정 | 프롬프트의 평가루프 종료 조건 |

#### 5.4 안티 패턴 방지 전략

**1. 모놀리식 안티 패턴 방지**:
- 오케스트레이터는 **직접 도메인 작업을 수행하지 않음** — 이를 프롬프트의 레드라인으로 명시
- 모든 실질적 작업은 전문 에이전트에 위임
- 에이전트 레지스트리에 각 에이전트의 역할 경계를 명확히 정의

```markdown
# Red Lines (오케스트레이터 프롬프트)
- 직접 코드를 작성하지 않는다 (coding-expert에 위임)
- 직접 문항을 설계하지 않는다 (mbti/enneagram-expert에 위임)
- 직접 학술 판단을 내리지 않는다 (psychology-expert에 위임)
- 직접 UI를 설계하지 않는다 (uiux-expert에 위임)
```

**2. 보이지 않는 상태 안티 패턴 방지**:
- 모든 중간 산출물은 `.claude/work-orders/` 하위에 파일로 명시적 저장
- manifest 파일로 워크플로우 전체 상태 추적
- 에이전트 간 인계는 반드시 파일 경로 참조로 수행 (LLM 대화 내역에 의존하지 않음)

**3. 원형 변형 안티 패턴 방지**:
- 학술 인용, 법적 텍스트, 기존 검증된 문항은 `preserve: true` 플래그로 보호
- 오케스트레이터가 서브에이전트에 전달 시 원문 보존 지시를 명시
- 비판 에이전트가 원문 변형 여부를 검증 항목에 포함

---

### 6. 실현 가능성 종합 평가

| 구현 요소 | 실현 가능성 | 근거 | 리스크 |
|----------|-----------|------|-------|
| Agent tool로 커스텀 에이전트 스폰 | **높음 (확인 필요)** | 프레임워크 지원 관찰, 003 문서에서 확정 예정 | 미지원 시 파일 기반 간접 위임으로 전환 |
| 파일 기반 산출물 릴레이 | **매우 높음** | 모든 에이전트가 Read/Write 보유, 파일 시스템 접근 자유 | 없음 |
| 프롬프트 내 의사결정 트리 | **높음** | LLM의 추론 능력으로 패턴 선택 가능 | 복잡한 경우 오분류 가능 |
| 평가루프 종료 조건 판정 | **중간~높음** | 구조화된 평가 포맷으로 자동 판정 가능 | verdict 파싱 실패 시 무한 루프 위험 |
| 워크플로우 상태 관리 | **높음** | YAML manifest로 명시적 관리 | 파일 I/O 오버헤드 |
| maxTurns 내 완료 | **중간** | 오케스트레이터 30턴에서 3-4개 에이전트 스폰 + 루프 가능 | 복잡한 하이브리드 시 턴 부족 가능 |

---

## Key Findings

1. **계층형 위임은 Agent tool + 파일 기반 하이브리드가 최적**: 오케스트레이터가 Agent tool로 서브에이전트를 스폰하되, 작업 지시서와 산출물은 파일로 관리하여 감사 추적과 상태 가시성을 확보한다.

2. **파이프라인은 Claude Code의 순차 실행 특성에 자연 부합**: 별도 런타임 없이 오케스트레이터 프롬프트에 단계별 체인을 인코딩하고, 파일 릴레이로 산출물을 전달하면 파이프라인 패턴이 성립한다.

3. **평가/정제 루프의 핵심은 구조화된 평가 포맷과 하드 가드레일**: `verdict: pass/fail` + `max_iterations: 3`의 조합으로 종료 조건을 명확히 하고, 단조 개선 감시로 무한 루프를 방지한다.

4. **하이브리드 통합은 프롬프트 내 의사결정 트리로 구현**: 워크플로우 유형별 패턴 선택 로직을 오케스트레이터 프롬프트에 명시적으로 인코딩한다. 대부분의 실제 작업은 "파이프라인 + 내장 평가루프" 하이브리드(Pattern C)에 해당한다.

5. **안티 패턴 방지가 설계의 핵심 원칙**: 모놀리식(오케스트레이터의 직접 작업 금지), 보이지 않는 상태(파일 기반 명시적 상태 관리), 원형 변형(preserve 플래그)의 세 가지 방지 전략을 아키텍처 레벨에서 강제한다.

6. **maxTurns 30이 오케스트레이터의 실질적 병목**: 하이브리드 워크플로우에서 4-5개 에이전트 스폰 + 1-2회 평가루프를 수행하면 약 20-25턴을 소비하므로, 최대 1개의 평가루프만 워크플로우에 포함할 수 있다.

7. **doc 001의 5개 계층이 오케스트레이터 구조에 직접 매핑됨**: 인지(요청 파싱) → 기억(manifest) → 추론(패턴 선택) → 행동(Agent tool) → 피드백(평가루프)의 자연스러운 대응 관계가 성립한다.

## Recommendations

1. **오케스트레이터 에이전트를 `model: opus`로 설정**: 작업 분해, 패턴 선택, 평가 판정 등 고차원 추론이 요구되므로 상위 모델 사용을 권장한다.

2. **Agent tool 지원 여부를 003 문서에서 우선 확정**: 커스텀 에이전트를 Agent tool로 스폰할 수 있는지 여부가 전체 설계의 분기점이다. 미지원 시 파일 기반 간접 위임(옵션 B)으로 전환해야 한다.

3. **`.claude/work-orders/` 디렉토리 구조를 사이클 2(SOP)에서 정교화**: manifest 포맷, 산출물 포맷, 평가 결과 포맷의 상세 스키마를 사이클 2에서 확정한다.

4. **오케스트레이터 전용 기억 체계 신설**: `.claude/agent-memory/orchestrator/`에 워크플로우 패턴, 에이전트 성능 이력, 반복 빈도 등을 장기 기억으로 축적하여 패턴 선택을 점진적으로 개선한다.

5. **단계적 도입 전략**: 먼저 Pattern D(단일 위임)와 Pattern A(단순 파이프라인)부터 구현하여 검증한 후, Pattern B(평가루프)와 Pattern C(하이브리드)를 추가한다.

## References

| 문서 | 참조 내용 |
|------|----------|
| `docs/002_gemini_deep_research.md` | MAS 구조 5종(2.1~2.5), 안티패턴(6.1), SOP 철학(4), 페르소나 5요소(3.1~3.3) |
| `docs/001_gemini_deep_research.md` | 5개 핵심 계층(인지/기억/추론/행동/피드백), 페르소나 5요소(역할/전문성/프로세스/산출물/제약) |
| `docs/07_organizational_agents/001_Scope_조직에이전트_전환.md` | 계층형+평가루프 채택 근거, 기각된 대안, 사이클 구조, 성공 기준 |
| `docs/07_organizational_agents/002_Research_조직아키텍처_오케스트레이터.md` | 연구 전체 구조, 4개 조사 관점, 초기 관찰(에이전트 현황 테이블) |
| `docs/07_organizational_agents/003_Agent_프레임워크제약.md` | 프레임워크 제약 조사(병렬 진행 중, 결과 참조 예정) |
| `.claude/agents/*.md` (5개) | 현재 에이전트 구조: frontmatter, 역할, 기억 체계, 협업 규칙 |
