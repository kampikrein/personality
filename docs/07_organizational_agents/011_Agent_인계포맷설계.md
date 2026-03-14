---
id: "011"
title: "인계 포맷 & 산출물 구조화 분석"
category: agent
status: archived
created: 2026-03-14
summary: >
  현재 에이전트 산출물 12개 파일의 구조 패턴을 분석하고, handover.yaml 템플릿의 필수/선택 필드를
  재설계하며, confidence/validation 수준 정의와 환각 캐스케이딩 방지 메커니즘, 3단계 컨텍스트
  압축 모델의 인계 포맷 적용 방안을 도출했다.
keywords: [agent-report, 인계포맷, handover, 산출물구조, 환각캐스케이딩, 3단계압축]
modules: [.claude/work-orders, docs]
---

# 인계 포맷 & 산출물 구조화 분석

## Progress
### Completed
- [x] docs/06_에이전트비평/ 6개 파일 구조 분석
- [x] docs/07_organizational_agents/ Agent_*.md 구조 분석
- [x] .claude/work-orders/_templates/handover.yaml 검토
- [x] docs/002_gemini_deep_research.md 환각 캐스케이딩 관련 추출
- [x] 인계 포맷 필수/선택 필드 분류
- [x] confidence/validation 필드 수준 정의
- [x] 3단계 압축의 인계 포맷 적용 설계
### Remaining
(없음)
### Current Status
분석 완료.

---

## Summary

현재 personality 프로젝트의 에이전트 산출물은 YAML frontmatter + Markdown body의 일관된 포맷을 따르며, 품질 높은 구조적 기반을 갖추고 있다. 그러나 인계 템플릿(handover.yaml)은 최소 구조만 정의된 상태로, **다음 에이전트가 작업을 시작하기에 충분한 정보 밀도가 부족**하다. 분석 결과, (1) 현재 산출물에서 인계에 필요한 5개 핵심 정보(출처 근거, 신뢰도, 검증 기준, 제약 조건, 컨텍스트 레벨)가 체계적으로 누락되어 있고, (2) confidence 필드는 3단계(high/medium/low)에서 **기준 정의 없이** 자기 평가에만 의존하여 환각 캐스케이딩 위험이 있으며, (3) 3단계 압축 모델(Level 1/2/3)이 인계 포맷에 구조적으로 매핑되지 않아 오케스트레이터의 컨텍스트 효율이 저하된다. 본 보고서에서는 이 세 가지 격차를 해소하는 상세 설계 방향을 제시한다.

---

## Details

### 1. 현재 산출물 패턴 분석

#### 1-1. docs/06_에이전트비평/ — 6개 파일 구조

6개 비평 문서(001~005: 개별 비평, 006: 종합)를 전수 분석한 결과, **모든 파일이 동일한 7-필드 frontmatter 스키마**를 따른다:

| 필드 | 존재 여부 | 일관성 | 비고 |
|------|----------|--------|------|
| `id` | 6/6 | 100% | 문자열 "001"~"006" |
| `title` | 6/6 | 100% | 한국어 제목 |
| `category` | 6/6 | 100% | `agent` (개별) 또는 `report` (종합) |
| `status` | 6/6 | 100% | 모두 `archived` |
| `created` | 6/6 | 100% | `YYYY-MM-DD` 포맷 |
| `summary` | 6/6 | 100% | 2-4줄 YAML 블록 스칼라 |
| `keywords` | 6/6 | 100% | YAML 배열 |
| `modules` | 6/6 | 100% | 분석 대상 코드 모듈 목록 |

**본문 구조 패턴** (5개 개별 비평에서 공통):

```
## Progress
### Completed / Remaining / Current Status

## Summary
## Details
  ### 1. {주제별 상세 분석}
  ### 2. ...
## Key Findings
## Recommendations
## References
```

**종합 문서(006)의 고유 구조**:

```
## Team Composition & Individual Reports  (테이블)
## Cross-Analysis
  ### 공통 발견사항
  ### 상충 의견
  ### 시너지 효과
## Comprehensive Conclusion
## References
```

**평가 — 인계 관점에서의 충분성**:

- **강점**: 일관된 frontmatter로 메타데이터 자동 파싱 가능. `summary` 필드가 Level 2 압축의 기초. `modules` 필드로 후속 에이전트가 관련 코드 범위를 파악 가능.
- **약점 1 — confidence 필드 부재**: 5개 에이전트가 각각 발견한 내용의 신뢰 수준이 명시되지 않음. 심리학 에이전트의 "recovery 도메인명 변경" 권고와 MBTI 에이전트의 동일 발견이 독립적으로 높은 신뢰도인지, 서로 참조한 결과인지 구분 불가.
- **약점 2 — 역방향 참조 없음**: 개별 비평에서 다른 비평을 참조하는 `related_documents` 필드 없음. 종합 문서가 개별 비평의 **특정 섹션**을 참조하는 앵커 없음(파일 단위 링크만).
- **약점 3 — next_steps 명시 부재**: 각 비평의 Recommendations가 "일반적 개선 방향"이지, "다음에 어떤 에이전트가 무엇을 해야 하는지" 구체적 지시가 아님.

#### 1-2. docs/07_organizational_agents/ — Agent_*.md 구조

6개 Agent_*.md 파일(003~006)의 frontmatter 구조:

| 필드 | 003 | 004 | 005 | 006 |
|------|-----|-----|-----|-----|
| `id` | O | O | O | O |
| `title` | O | O | O | O |
| `category` | `agent` | `agent` | `agent` | `agent` |
| `status` | `archived` | `archived` | `archived` | `archived` |
| `created` | O | O | O | O |
| `summary` | O | O | O | O |
| `keywords` | O | O | O | O |
| `modules` | O | O | O | O |

**관찰**: docs/06과 docs/07의 Agent_*.md가 **완전 동일한 frontmatter 스키마**를 사용한다. 이는 프로젝트 전체에 걸친 산출물 포맷 일관성이 높다는 것을 의미하며, 인계 포맷을 이 기반 위에 **확장**하는 설계가 자연스럽다.

**상위 연구 문서(008, 010)의 고유 필드**:

008과 010은 `traces_scope`, `parallel_plan` 등 추가 메타데이터를 포함하여 연구 기획 수준의 정보를 담고 있다. 이는 워크플로우 관리 목적의 필드로, 인계 포맷에서는 `workflow_id`와 `step_id`로 대체된다.

#### 1-3. 현재 산출물 간 상호 참조 패턴

| 참조 방향 | 현재 구현 | 평가 |
|----------|----------|------|
| 종합 → 개별 | 상대 경로 마크다운 링크 `[파일명](./파일명)` | 파일 단위만 가능, 섹션 앵커 없음 |
| 개별 → 개별 | 없음 | 에이전트 A가 에이전트 B의 발견을 참조할 방법 없음 |
| 개별 → 코드 | References 섹션에 절대 경로 나열 | 양호하나 줄 번호 참조 없음 |
| 연구문서 → 에이전트보고서 | Related Documents 섹션 | 양호 |

---

### 2. 인계 포맷 상세 설계

#### 2-1. 현재 handover.yaml 템플릿 검토

`.claude/work-orders/_templates/handover.yaml`의 현재 상태:

```yaml
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

**평가**: 사이클 1에서 R-006이 제안한 구조를 최소한으로 반영했으나, 다음 격차가 존재한다:

| 격차 | 설명 | 영향 |
|------|------|------|
| `confidence` 기준 미정의 | high/medium/low를 어떤 기준으로 판정하는지 없음 | 에이전트마다 주관적 기준 → 신뢰도 불균일 |
| `constraints` 필드 부재 | 수신 에이전트가 지켜야 할 제약 조건 없음 | 범위 이탈(scope creep) 위험 |
| `context_level` 부재 | 이 인계 파일이 Level 2인지 Level 3인지 표시 없음 | 오케스트레이터가 추가 파일을 읽어야 하는지 판단 불가 |
| `status` 부재 | 인계 상태(pending/accepted/completed) 추적 없음 | 워크플로우 중단/재개 시 진행 상태 파악 불가 |
| `created` 타임스탬프 부재 | 인계 생성 시점 없음 | 순서 추적, 만료 판단 불가 |
| Markdown body 미규정 | YAML-only 포맷 | 복잡한 배경 설명, 분석 근거를 담을 공간 없음 |

#### 2-2. 필수 vs 선택 필드 분류

**설계 원칙**: "최소 필수 필드로 모든 인계를 커버하되, 선택 필드로 정보 밀도를 높일 수 있게 한다."

R-006 보고서에서 인계 포맷이 복잡하면 에이전트가 제대로 생성하지 못할 위험이 있다고 경고했다(Caveats & Risks). 따라서 필수 필드는 10개 이하로 제한한다.

**필수 필드 (10개)**:

| # | 필드 | 타입 | 설명 | 근거 |
|---|------|------|------|------|
| 1 | `handover_id` | string | `WF-{id}-STEP-{N}` | 워크플로우 추적 |
| 2 | `workflow_id` | string | 상위 워크플로우 ID | manifest 연동 |
| 3 | `created` | datetime | ISO 8601 | 순서/만료 추적 |
| 4 | `status` | enum | `pending\|accepted\|completed\|rejected` | 상태 추적 |
| 5 | `source.agent` | string | 발신 에이전트명 | 출처 추적 |
| 6 | `source.confidence` | enum | `high\|medium\|low` | 환각 캐스케이딩 방지 |
| 7 | `target.agent` | string | 수신 에이전트명 | 라우팅 |
| 8 | `target.expected_action` | string | 기대 작업 1줄 | 작업 범위 명확화 |
| 9 | `summary` | text | 1-3줄 요약 | Level 3 컨텍스트 |
| 10 | `next_steps` | list | 수신 에이전트 할 일 목록 | 행동 지시 |

**선택 필드 (7개)**:

| # | 필드 | 타입 | 설명 | 사용 상황 |
|---|------|------|------|----------|
| 11 | `source.task` | string | 발신 에이전트가 수행한 작업 | 맥락 이해 필요 시 |
| 12 | `artifacts` | list | 참조 파일 + 섹션 목록 | 원본 추적 필요 시 |
| 13 | `constraints` | list | 수신 에이전트 제약 조건 | 범위 제한 필요 시 |
| 14 | `validation.criteria` | string | 검증 기준 | 평가루프 포함 시 |
| 15 | `validation.validator_agent` | string | 검증 담당 에이전트 | 평가루프 포함 시 |
| 16 | `context_level` | enum | `full\|summary\|handover` | 3단계 압축 명시 |
| 17 | `full_document` | string | Level 1 전문 파일 경로 | context_level이 summary/handover일 때 |

#### 2-3. 개선된 인계 파일 포맷

```yaml
---
# === 필수 ===
handover_id: "WF-20260314-문항추가-STEP-02"
workflow_id: "WF-20260314-문항추가"
created: "2026-03-14T10:30:00+09:00"
status: pending

source:
  agent: "psychology-expert"
  confidence: high              # 아래 2-4절 기준 참조

target:
  agent: "coding-expert"
  expected_action: "인사이트 모듈 3개의 recovery 점수 분기 방향 역전"

summary: >
  recovery 도메인의 높은 점수(>=65)는 P(유연성)을 의미하나, ConflictModule·RecoveryModule·
  CareerModule에서 "빠른 감정 회복"으로 오해석하고 있다. 분기 조건의 의미를 계획성-유연성
  축으로 수정해야 한다.

next_steps:
  - "conflict_module.rb line 25-40: recovery >= 65 분기의 텍스트를 '유연한 갈등 접근'으로 변경"
  - "recovery_module.rb: recovery 점수를 '회복 속도'가 아닌 '회복 활동 구조화 선호'로 재해석"
  - "career_module.rb: recovery <= 35의 '스타트업 부적합' 조언 삭제"
  - "수정 후 RSpec 테스트 추가"

# === 선택 ===
source.task: "문항 20개 및 인사이트 모듈 심리측정학적 분석"

artifacts:
  - path: "docs/06_에이전트비평/001_Agent_심리학비평.md"
    sections:
      - "### 5-5. RecoveryModule"
      - "## Key Findings"
  - path: "app/services/insights/conflict_module.rb"
    note: "line 25-40의 recovery_score >= 65 분기"

constraints:
  - "도메인명(recovery) 자체의 변경은 이 워크플로우 범위 밖"
  - "기존 RSpec 테스트를 깨뜨리지 말 것"
  - "decision_making 분기 방향은 별도 인계(STEP-03)에서 처리"

validation:
  criteria: "recovery >= 65일 때 '유연한 접근/즉흥적 회복' 관련 텍스트가 출력되어야 함"
  validator_agent: "psychology-expert"

context_level: summary
full_document: "docs/06_에이전트비평/001_Agent_심리학비평.md"
---

# 인계 상세

## 배경

사이클 1 비평에서 3개 에이전트(심리학, MBTI, 애니어그램)가 독립적으로 recovery 도메인의
개념 혼란을 발견했다. 이는 교차 검증된 가장 강력한 발견이다.

## 분석 근거

심리학적으로 P/J 축은 "계획성 vs 유연성"을 측정하며, 감정 회복 속도(resilience)와는
별도의 구성개념이다 (McCrae & Costa, 1989; Pittenger, 1993). 현재 코드의
`type_classifier.rb`에서 `"recovery" => { high: "P", low: "J" }`로 매핑되어 있어
높은 점수 = P(유연형)임이 확인된다.

## 예상 영향

- ConflictModule: "빠른 회복" → "유연한 갈등 접근"으로 메시지 변경
- RecoveryModule: "스트레스 빠른 회복" → "즉흥적 회복 활동 선호"로 재프레이밍
- CareerModule: "안정적 환경 추천" 로직에서 recovery 점수 기반 직업 처방 삭제
- 기존 테스트: context_engine_spec이 간접 커버하므로 출력 텍스트 변경 시 assertion 수정 필요
```

---

### 3. confidence/validation 필드 수준 정의

#### 3-1. confidence 필드: 3단계 기준 정의

현재 handover.yaml에 `confidence: high | medium | low`가 있으나 **기준이 미정의**다. 에이전트마다 주관적으로 판단하면 "모든 에이전트가 자기 결과에 high를 부여"하는 낙관 편향이 발생한다.

**제안: 구조화된 판정 기준**

| 수준 | 기준 | 오케스트레이터 행동 |
|------|------|-----------------|
| **high** | (a) 코드/데이터에서 직접 확인한 사실 **또는** (b) 2개 이상 독립 에이전트가 동일 발견(교차 검증) **또는** (c) 학술 문헌/공식 문서에 근거 | 추가 검증 없이 다음 단계 진행 |
| **medium** | (a) 코드 분석에 기반하되 해석이 포함된 판단 **또는** (b) 단일 에이전트의 독립 발견 **또는** (c) 비공식 자료/경험칙에 근거 | 검증 에이전트 1회 확인 후 진행 |
| **low** | (a) 추론/추정에 기반한 판단 **또는** (b) 불확실한 외부 정보에 의존 **또는** (c) 에이전트 자신이 확신 부족을 인지 | 반드시 검증 에이전트의 교차 검증 필요. 검증 없이 전달 금지 |

**에이전트 프롬프트에 인코딩할 규칙**:

```
confidence 판정 규칙:
- high: 코드에서 직접 확인 가능한 사실 기반 발견
- medium: 코드 분석 + 해석이 혼합된 판단
- low: 추론 또는 불확실한 근거에 기반한 판단
- 자기 발견에 대해 의문이 있으면 반드시 medium 이하로 설정
```

#### 3-2. validation 필드: 검증자 지정 패턴

**현재 상태**: `validation.validator_agent` 필드가 있으나 사용 패턴이 미정의.

**제안: 역할 기반 검증자 자동 매핑**

| 산출물 유형 | 생성 에이전트 | 기본 검증자 | 검증 기준 |
|------------|-------------|-----------|----------|
| 심리학적 판단 | psychology-expert | mbti-expert 또는 enneagram-expert | 도메인 이론 정합성 |
| 문항/콘텐츠 | mbti-expert, enneagram-expert | psychology-expert | 심리측정학적 타당성, 바넘효과 |
| 코드 변경 | coding-expert | psychology-expert (로직 의미) | 점수 해석 방향 정확성 |
| UI 변경 | uiux-expert | (선택적) 접근성 기준 | WCAG 2.1 준수 |

이 매핑은 오케스트레이터 프롬프트의 "에이전트 선택 가이드" 테이블과 **일치**한다. 오케스트레이터가 인계 파일 생성 시 이 매핑을 참조하여 `validator_agent`를 자동 지정할 수 있다.

#### 3-3. validation 결과의 인계 파일 반영

검증 에이전트가 평가를 완료하면, 인계 파일의 `status`를 갱신한다:

```yaml
status: completed   # pending → accepted → completed (검증 통과 시)
                    # pending → rejected (검증 실패 시)
validation_result:
  verdict: pass
  validated_by: "psychology-expert"
  validated_at: "2026-03-14T11:00:00+09:00"
  notes: "분기 방향 수정 확인. recovery >= 65 → 유연성 텍스트 출력 검증 완료."
```

---

### 4. 환각 캐스케이딩 방지 메커니즘

#### 4-1. docs/002_gemini_deep_research.md에서 추출한 핵심 원칙

doc 002(섹션 4, 87행 근방)의 핵심 경고:

> "두 LLM이 순수한 자연어로 대화하게 방치하면 의미 없는 잡담이나 과장된 표현이 섞이며 점진적으로 환각이 증폭되는 캐스케이딩(Cascading hallucinations) 현상이 발생한다. 이를 방지하기 위해 에이전트 간의 결과물 인계(Handover)는 반드시 엄격한 포맷 규칙에 따라 이루어져야 한다."

doc 002(섹션 6.1)의 안티 패턴:

- **보이지 않는 상태(Invisible State)**: 중간 산출물을 LLM 대화 내역에만 방치하는 것이 치명적
- **As-Is 정보의 임의 변형**: 원문 데이터를 자의적으로 요약/윤문하면 법적 리스크
- **비즈니스 프로세스 전가**: 에이전트가 프로세스를 "근사치로 유추"하게 두면 감사 불가

#### 4-2. 인계 포맷에 적용하는 3중 방지 메커니즘

| 메커니즘 | 인계 필드 | 방지 대상 | 작동 방식 |
|---------|----------|----------|----------|
| **자기 평가** | `source.confidence` | 낙관 편향 | 에이전트가 자기 발견의 근거 수준을 명시적으로 선언. 3-1절 기준 적용 |
| **원본 추적** | `artifacts[].path` + `artifacts[].sections` | As-Is 임의 변형 | 인계 요약이 참조하는 원본 위치를 명시. 수신 에이전트가 원본과 대조 가능 |
| **교차 검증** | `validation.criteria` + `validation.validator_agent` | 환각 캐스케이딩 | 제3 에이전트가 독립적으로 검증. confidence가 low이면 검증 필수 |

#### 4-3. 캐스케이딩 차단 규칙 (오케스트레이터 프롬프트에 인코딩)

```
환각 캐스케이딩 방지 규칙:

1. confidence가 low인 인계는 반드시 validation을 거쳐야 다음 에이전트에 전달 가능.
2. 인계 summary가 artifacts의 원본 내용과 모순되면 reject.
3. 에이전트가 이전 인계의 summary를 추가 해석하여 새로운 주장을 만들 때는
   confidence를 한 단계 낮추어야 한다 (high→medium, medium→low).
4. 3단계 이상 릴레이된 정보(A→B→C)는 원본(A)을 직접 확인한 후에만 수용.
```

**규칙 3이 핵심이다**: 에이전트 A가 "recovery 도메인명이 부적절하다"(confidence: high, 코드에서 직접 확인)고 인계하면, 에이전트 B가 이를 인용하여 "도메인명 변경 시 사용자 혼란이 예상된다"(confidence: medium, 해석 포함)고 확장할 수 있다. 그러나 에이전트 C가 B의 해석을 다시 인용하여 "사용자 혼란으로 인해 서비스 중단이 필요하다"로 확대하면 confidence: low가 되어야 한다. 이렇게 릴레이마다 confidence가 자연 감쇠하면 환각 증폭을 구조적으로 차단한다.

---

### 5. 3단계 압축의 인계 포맷 적용 설계

#### 5-1. 3단계 모델 재정의

R-006과 R-008에서 제안한 3단계 압축 모델을 인계 포맷에 구체적으로 매핑한다:

| Level | 내용 | 토큰 추정 | 인계 포맷 대응 | 읽는 주체 |
|-------|------|----------|--------------|----------|
| **Level 1: 전문** | 원본 산출물 전체 | ~10,000/문서 | `artifacts[].path`로 참조 | 해당 에이전트 자신(이전 작업 복원), 검증 에이전트(상세 검토) |
| **Level 2: 요약** | frontmatter `summary` + `Key Findings` 섹션 | ~500/문서 | 산출물 파일의 상단 2개 섹션 | 오케스트레이터(결과 종합, 다음 단계 결정) |
| **Level 3: 인계** | 인계 파일의 `summary` + `next_steps` + `constraints` | ~200/인계 | handover.yaml 자체 | 수신 워커 에이전트(작업 시작) |

#### 5-2. 오케스트레이터의 Level 2 읽기 최소 정보 요구사항

오케스트레이터가 에이전트 산출물을 Level 2로 읽을 때, 다음 **4가지 정보**가 있어야 "다음 단계를 결정"할 수 있다:

| # | 정보 | 현재 위치 | 충분? | 개선 |
|---|------|----------|-------|------|
| 1 | 무엇을 발견했는가 | `summary` 필드 | 부분적 | **Key Findings 섹션 필수화**로 보완 |
| 2 | 얼마나 확실한가 | 없음 | 불충분 | **frontmatter에 `confidence_overview` 필드 추가** |
| 3 | 다음에 무엇이 필요한가 | `Recommendations` 섹션 | 부분적 | Recommendations를 **next_agent_actions 서브섹션**으로 구조화 |
| 4 | 미해결 사항이 있는가 | `Progress > Remaining` | 충분 | 유지 |

**`confidence_overview` 필드 제안**:

```yaml
# frontmatter에 추가
confidence_overview:
  high_findings: 3    # 코드 직접 확인 기반 발견 수
  medium_findings: 2  # 해석 포함 발견 수
  low_findings: 0     # 추론 기반 발견 수
```

이 필드를 통해 오케스트레이터는 산출물 전체를 읽지 않고도 "이 보고서의 발견 중 몇 개가 높은 확신도인지"를 즉시 파악하여 검증 필요성을 판단할 수 있다.

#### 5-3. Level 3 인계 파일의 최소 구조

수신 에이전트가 작업을 시작하기 위한 **최소 필수 정보**:

```yaml
# Level 3 최소 인계 (~200 토큰)
handover_id: "WF-xxx-STEP-02"
source:
  agent: "psychology-expert"
  confidence: high
target:
  agent: "coding-expert"
  expected_action: "인사이트 모듈 recovery 분기 수정"
summary: >
  recovery >= 65를 '감정 회복 속도 빠름'이 아닌 '유연한 접근 선호'로 해석해야 한다.
  ConflictModule, RecoveryModule, CareerModule의 분기 텍스트 수정 필요.
next_steps:
  - "conflict_module.rb recovery 분기 텍스트 변경"
  - "recovery_module.rb 해석 프레이밍 변경"
  - "RSpec 테스트 추가"
```

이 최소 구조로 수신 에이전트는:
1. **무엇을 해야 하는지** (`next_steps`) 즉시 파악
2. **왜 해야 하는지** (`summary`) 배경 이해
3. **누가 요청했는지** (`source.agent`) 질문 대상 파악
4. **얼마나 확실한지** (`confidence`) 추가 검증 필요 여부 판단

---

### 6. 현재 산출물의 인계 전달 충분성 종합 평가

#### 6-1. 5개 비평 문서의 인계 적합성 점수

| 비평 | Key Findings 명확성 | next_steps 구체성 | confidence 암시 | 인계 적합성 |
|------|-------------------|-----------------|----------------|-----------|
| 001 심리학 | 8개 bullet, 심각도 태그 포함 | Recommendations 3단계 분류 | "심각/중요/주의/양호" 태그 = 암시적 confidence | **높음** |
| 002 MBTI | 8개 bullet, 명확한 평가 | 즉시/단기/중장기 분류 | "법적 위험 낮음" 등 수준 명시 | **높음** |
| 003 애니어그램 | 8개 bullet | 단기/중기/장기 분류 | "전면 부재" 등 명확한 판단 | **중간** (코드 변경 지시 불구체적) |
| 004 코딩 | 12개, Critical~Low 심각도 | 즉시/단기/중기 분류, 코드 예시 포함 | 심각도 = 암시적 confidence | **매우 높음** |
| 005 UI/UX | 7개 핵심 | 우선순위별 체크리스트 | "미흡/부재" 등 직접 평가 | **높음** |

**관찰**: 5개 비평 모두 Key Findings와 Recommendations가 잘 구조화되어 있어 **Level 2 읽기의 기초**가 이미 마련되어 있다. 그러나 **명시적 confidence 필드**와 **수신 에이전트 지정**이 없어, 오케스트레이터가 "누구에게 어떤 인계를 만들어야 하는지"를 해석해야 한다.

#### 6-2. 종합 문서(006)의 오케스트레이터 대체 가능성

006 종합 문서는 사실상 오케스트레이터가 수행해야 할 **교차 분석 + 우선순위 결정**을 이미 수행한 형태다:
- "공통 발견사항" = 교차 검증된 high-confidence 발견
- "상충 의견" = 추가 해소가 필요한 항목
- "Recommended Actions Phase 1/2/3" = 워크플로우 단계 분해

이 패턴을 인계 포맷에 적용하면: 오케스트레이터가 여러 에이전트 결과를 종합할 때 **006과 동일한 구조의 종합 인계 파일**을 생성하되, 각 발견에 `confidence` 태그를 붙이고 각 Phase에 `target.agent`를 지정하면 된다.

---

## Key Findings

1. **현재 산출물의 구조적 일관성은 높다**: docs/06과 docs/07의 Agent_*.md가 완전 동일한 7-필드 frontmatter 스키마를 사용. 인계 포맷은 이 기반 위에 확장하는 것이 자연스럽다.

2. **인계에 필요한 5개 핵심 정보가 체계적으로 누락되어 있다**: (a) 명시적 confidence 수준, (b) 수신 에이전트 및 기대 행동, (c) 구체적 next_steps, (d) 제약 조건(constraints), (e) 컨텍스트 레벨(context_level). 현재 비평 문서는 Recommendations 섹션에서 이를 암시적으로 담고 있으나 구조화되지 않았다.

3. **confidence 필드에 구조화된 판정 기준이 필수적이다**: 기준 없이 자기 평가만 요구하면 낙관 편향으로 모든 인계가 high가 된다. "코드 직접 확인 = high, 해석 포함 = medium, 추론 = low"의 3단계 기준과 "릴레이마다 한 단계 감쇠" 규칙으로 환각 캐스케이딩을 구조적으로 차단해야 한다.

4. **3단계 압축 모델은 인계 포맷에 자연스럽게 매핑된다**: Level 1 = 원본 산출물(artifacts), Level 2 = frontmatter summary + Key Findings, Level 3 = 인계 파일 자체(summary + next_steps). 이 매핑을 `context_level` 필드로 명시하면 오케스트레이터의 읽기 전략이 자동화된다.

5. **현재 handover.yaml 템플릿은 10개 필드 중 5개만 존재한다**: `status`, `created`, `constraints`, `context_level`, `full_document`가 부재. 특히 `status` 없이는 워크플로우 중단/재개 시 인계 진행 상태를 파악할 수 없다.

6. **종합 문서(006)의 교차 분석 패턴이 오케스트레이터의 종합 인계 템플릿이 될 수 있다**: "공통 발견 = 교차 검증된 high 발견, 상충 의견 = 추가 해소 필요, Phase별 추천 = 워크플로우 단계"의 1:1 대응이 가능하다.

7. **"릴레이 감쇠 규칙"이 환각 캐스케이딩 방지의 핵심 신규 메커니즘이다**: 에이전트 A의 high-confidence 발견을 에이전트 B가 해석하면 medium, 에이전트 C가 재해석하면 low. 3단계 이상 릴레이된 정보는 원본 직접 확인을 강제함으로써 환각 증폭의 구조적 차단이 가능하다.

---

## Recommendations

### 즉시 적용 (handover.yaml 템플릿 개선)

1. **handover.yaml에 5개 필수 필드 추가**: `status`, `created`, `constraints`, `context_level`, `full_document`. 본 보고서 2-2절의 필수/선택 분류 기준 적용.

2. **confidence 3단계 판정 기준을 에이전트 프롬프트에 인코딩**: "코드 직접 확인 = high, 해석 포함 = medium, 추론 = low" + "자기 발견에 의문이 있으면 medium 이하" 규칙을 5개 에이전트 프롬프트의 Output Format 섹션에 추가.

3. **에이전트 산출물에 Key Findings 섹션 필수화**: 오케스트레이터의 Level 2 읽기를 위해 모든 에이전트 산출물에 `## Key Findings` (3-8개 bullet, 심각도 태그 포함) 섹션을 의무화.

### 오케스트레이터 프롬프트 반영

4. **환각 캐스케이딩 방지 4개 규칙을 오케스트레이터 프롬프트에 추가**: 본 보고서 4-3절의 규칙. 특히 "릴레이 감쇠 규칙"과 "3단계 이상 릴레이 시 원본 확인 강제".

5. **검증자 자동 매핑 테이블을 오케스트레이터의 Agent Delegation Protocol에 추가**: 본 보고서 3-2절의 "역할 기반 검증자 자동 매핑" 테이블.

6. **`confidence_overview` 필드를 산출물 frontmatter 표준에 추가**: 오케스트레이터가 Level 2에서 검증 필요성을 즉시 판단할 수 있도록.

### 관점 2/3 연계 (SOP·평가루프와의 통합)

7. **SOP의 Share 단계가 인계 파일 생성과 동일시되어야 한다**: 관점 2(SOP 행동 루프)에서 Observe-Think-Act-**Share** 루프를 설계할 때, Share = "본 보고서의 인계 포맷으로 산출물 저장"으로 정의.

8. **평가루프의 verdict가 인계 파일의 `validation_result`로 기록되어야 한다**: 관점 3(평가루프 종료 조건)에서 verdict 판정 후 해당 인계 파일의 status를 `completed` 또는 `rejected`로 갱신하는 프로토콜 정의.

---

## References

### 분석 대상 파일
- `/Users/kampikrein/A/personality/docs/06_에이전트비평/001_Agent_심리학비평.md` ~ `006_Synthesis_코드베이스비평.md` — 현행 에이전트 산출물 6개
- `/Users/kampikrein/A/personality/docs/07_organizational_agents/003_Agent_프레임워크제약.md` ~ `006_Agent_상태관리컨텍스트.md` — Agent_*.md 4개
- `/Users/kampikrein/A/personality/docs/07_organizational_agents/008_Research_조직아키텍처_오케스트레이터_최종.md` — 사이클 1 최종 연구
- `/Users/kampikrein/A/personality/docs/07_organizational_agents/010_Research_소통프로토콜_SOP.md` — 사이클 2 연구 기획
- `/Users/kampikrein/A/personality/.claude/work-orders/_templates/handover.yaml` — 현행 인계 템플릿
- `/Users/kampikrein/A/personality/.claude/agents/orchestrator.md` — 오케스트레이터 에이전트 정의

### 이론적 근거
- `/Users/kampikrein/A/personality/docs/002_gemini_deep_research.md` — MAS 구조, SOP, 환각 캐스케이딩 방지 원칙 (섹션 4, 6.1)
- `/Users/kampikrein/A/personality/docs/07_organizational_agents/006_Agent_상태관리컨텍스트.md` — 인계 파일 포맷 초안, 3단계 압축 모델
