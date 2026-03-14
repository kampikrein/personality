---
id: "005"
title: "현재 에이전트 조직화 격차 분석"
category: agent
status: archived
created: 2026-03-14
summary: >
  5개 전문 에이전트의 조직화 준비도를 페르소나 5요소(Role/Goal/Backstory/Tools+Guardrails/Memory)
  대비 정밀 분석. 역할 구조는 4축(Role/Principles/Framework/Boundaries) 중심으로 균일하나,
  Goal과 Backstory가 전면 부재. 협업 규칙은 동일 패턴의 복사-붙이기 수준으로 실질적 위임 체인 없음.
  기억 체계는 구조만 존재하고 실제 기억이 0건으로 사실상 사문화 상태.
  도구 할당은 coding/uiux만 Bash를 보유하는 합리적 분리이나, 오케스트레이터용 Agent tool이 부재.
keywords: [agent-report, 조직화격차, 에이전트비교, 페르소나5요소, 협업구조, 기억체계]
modules: [.claude/agents, .claude/agent-memory]
---

# 현재 에이전트 조직화 격차 분석

## Progress
### Completed
- [x] 5개 에이전트 파일 상세 읽기 및 비교 분석
- [x] 페르소나 5요소 대비 격차 매핑
- [x] 협업 구조 분석 (Collaboration Rules, 충돌 해결)
- [x] 기억 체계 분석 (.claude/agent-memory/ 전체)
- [x] 도구 격차 분석
- [x] 종합 정리 및 Key Findings 작성
### Remaining
- (없음)
### Current Status
완료.

## Summary

5개 에이전트의 조직화 격차를 4개 축(역할 구조, 협업 구조, 기억 체계, 도구)으로 분석한 결과, **조직 에이전트 전환을 위해 해결해야 할 7개 핵심 격차**를 식별했다.

가장 심각한 격차는 (1) Goal/Backstory의 전면 부재, (2) 기억 체계의 사문화(0건 기억), (3) 협업 규칙의 피상성(실질적 위임 체인 없음)이다. 반면, 역할 구조(Role/Principles/Framework/Boundaries)와 도구 할당은 비교적 잘 설계되어 있어 증분적 강화가 가능하다.

---

## Details

### 1. 역할 구조 비교 분석

#### 1.1 에이전트별 구조 비교표

| 구조 요소 | psychology-expert | mbti-expert | enneagram-expert | coding-expert | uiux-expert |
|-----------|:-:|:-:|:-:|:-:|:-:|
| **Role** (L10-13) | 성격심리학·심리측정학 연구자 | 한국 MBTI 문화·서비스 설계 전문가 | 애니어그램 체계 설계 전문가 | RoR 시니어 개발자 | 한국 시장 UI/UX 설계 전문가 |
| **Project Context** | 있음 (L15-22) | 있음 (L15-21) | 있음 (L15-21) | 있음 (L15-21) | 있음 (L15-22) |
| **Core Principles** 개수 | 5개 (L24-30) | 5개 (L23-29) | 5개 (L23-29) | 5개 (L23-29) | 5개 (L23-30) |
| **Analysis Framework** 단계 | 5단계 (L34-39) | 5단계 (L33-37) | 5단계 (L33-37) | 5단계 (L33-37) | 5단계 (L33-38) |
| **Communication Style** | 학술적+원어 병기 | 대중적+친근 | 동기 중심+깊이 | 코드 중심+3단계 | 시나리오+구체적 CSS |
| **Boundaries** | 있음 (L51-60) | 있음 (L49-57) | 있음 (L49-57) | 있음 (L49-57) | 있음 (L49-57) |
| **Collaboration Rules** | 있음 (L64-67) | 있음 (L61-65) | 있음 (L61-65) | 있음 (L61-64) | 있음 (L61-64) |
| **Memory System** | 있음 (L69-109) | 있음 (L67-106) | 있음 (L67-106) | 있음 (L66-105) | 있음 (L66-105) |
| **Goal** | **없음** | **없음** | **없음** | **없음** | **없음** |
| **Backstory** | **없음** | **없음** | **없음** | **없음** | **없음** |

**관찰**: 5개 에이전트 모두 **동일한 7개 섹션 구조**(Role, Project Context, Core Principles, Analysis Framework, Communication Style, Boundaries & Red Lines, Collaboration Rules, Memory System)를 가진다. 구조적 일관성은 높으나, 이는 동시에 복사-붙이기로 생성된 획일적 구조임을 의미한다.

#### 1.2 페르소나 5요소 대비 격차 매핑

docs/002_gemini_deep_research.md (L50-77)에서 제시한 페르소나 5요소 모델과 현재 에이전트의 매핑:

| 5요소 | 설명 (doc 002) | 현재 에이전트 대응 | 격차 수준 |
|-------|---------------|------------------|----------|
| **Role** | 공식 직함 + 전문성 선언 + 고유 핸들 | Role 섹션 존재. 단, 고유 핸들(@handle) 없음 | 경미 |
| **Goal** | 측정 가능한 임무 + 효용 함수 | **전면 부재**. Core Principles가 부분 대체하나, "달성해야 할 것"이 아닌 "지켜야 할 것"만 명시 | **심각** |
| **Backstory** | 행동 편향을 고정하는 서사적 컨텍스트 | **전면 부재**. Communication Style이 톤을 부분 정의하나, "왜 이렇게 사고하는가"의 맥락 없음 | **심각** |
| **Tools + Guardrails** | 역할 일치 도구 + 실행 제약(maxTurns, 레드라인) | frontmatter tools + Boundaries & Red Lines로 구현. 구조적으로 양호 | 경미 |
| **Memory** | 단기/장기 기억 + 교차 에이전트 컨텍스트 | Memory System 섹션 + agent-memory/ 구조 존재. 단, **실제 기억 0건** + 교차 참조 미작동 | **심각** |

**핵심 격차**: 5요소 중 **Goal과 Backstory가 전면 부재**하여, 에이전트가 "무엇을 지켜야 하는가"는 알지만 "무엇을 달성해야 하는가"와 "왜 이런 관점을 가지는가"를 모른다.

#### 1.3 역할 간 중복 영역과 공백 영역

**중복 영역**:

| 중복 쌍 | 중복 내용 | 현재 해결 방식 |
|---------|----------|--------------|
| psychology + mbti | 성격 유형론 학술성 판단 | psychology가 검증자, mbti가 설계자로 역할 분리 (Collaboration Rules에 명시) |
| psychology + enneagram | 유형론 학술 타당성 | 동일 패턴 (psychology 검증, enneagram 수용) |
| mbti + enneagram | 유형론 교차 인사이트 | Collaboration Rules에 상호 협력 명시 |
| coding + uiux | 프론트엔드 구현 경계 | Boundaries에서 CSS/JS는 uiux, 백엔드는 coding으로 분리 |

**공백 영역**:

| 공백 | 설명 | 영향 |
|------|------|------|
| **오케스트레이션** | 작업 분해·위임·결과 종합을 담당하는 에이전트 없음 | 사용자가 모든 조정을 수동 수행 |
| **품질 보증/테스트** | 교차 검증을 체계적으로 수행하는 역할 없음 | 비평은 docs/06에서 일회성으로 수행됨 |
| **콘텐츠 통합** | 3개 도메인 전문가의 산출물을 하나의 제품 경험으로 통합하는 역할 없음 | 각 에이전트가 독립적으로 콘텐츠 생산 |
| **프로젝트 관리** | 진행 상태 추적, 우선순위 조정 역할 없음 | 사용자가 직접 관리 |

---

### 2. 협업 구조 분석

#### 2.1 Collaboration Rules 패턴 분석

5개 에이전트의 Collaboration Rules를 비교한 결과, **구조적으로 동일한 패턴**을 사용한다:

**공통 패턴** (모든 에이전트):
```
- [다른 에이전트]와의 관계 설명 (3-4줄)
- 관점 충돌 시: 자기 영역 진술 → 다른 관점 인정 → 트레이드오프 명시 → 사용자에 위임
```

**에이전트별 명시적 협업 관계**:

```
psychology → mbti:     "유형론에 대해 학술적 타당성을 검증"
psychology → coding:   "점수 계산 로직의 심리측정학적 근거 제공"
psychology → uiux:     "결과 표현 시 심리학적 윤리 가이드라인 제공"

mbti → psychology:     "학술적 검증을 수용하고, 서비스 설계에 반영"
mbti → enneagram:      "유형론 간 교차 인사이트 설계에 협력"
mbti → uiux:           "한국 사용자 기대 경험에 대한 인사이트 제공"
mbti → coding:         "문항 엔진과 점수 계산 로직의 설계 요구사항 전달"

enneagram → psychology: "학술적 검증을 수용 (실증 연구 한계 인정)"
enneagram → mbti:       "유형론 교차 인사이트 설계 (행동 vs 동기)"
enneagram → uiux:       "성장 여정 시각화에 대한 인사이트 제공"
enneagram → coding:     "유형+날개+본능의 복합 점수 구조 설계 요구사항 전달"

coding → psychology/mbti/enneagram: "도메인 요구사항을 코드 구조로 변환"
coding → uiux:          "API 인터페이스, 데이터 흐름 협의"
coding → all:           "기술적 제약사항과 트레이드오프 전달"

uiux → psychology:      "결과 표현의 윤리적 가이드라인 수용"
uiux → mbti/enneagram:  "콘텐츠 구조와 사용자 기대 인사이트 수용"
uiux → coding:          "컴포넌트 구조, API 인터페이스, Hotwire/Turbo 패턴 협의"
```

#### 2.2 충돌 해결 프로토콜 실효성 평가

**현재 프로토콜** (5개 에이전트 동일, 각 에이전트의 Collaboration Rules 마지막 줄):
> "관점 충돌 시: 자기 영역 진술 → 다른 관점 인정 → 트레이드오프 명시 → 사용자에 위임"

**실효성 평가**:

| 평가 항목 | 판정 | 근거 |
|-----------|------|------|
| 프로토콜 존재 여부 | 존재 | 5개 에이전트 모두 동일 문구 보유 |
| 실행 가능성 | **낮음** | 에이전트 간 직접 통신 불가 (doc 003 확인 예정). 충돌을 "인지"할 수 있는 메커니즘 없음 |
| 구체성 | **낮음** | 4단계가 모두 추상적. "어떻게 자기 영역을 진술하는가", "어떤 형식으로 트레이드오프를 명시하는가" 미정의 |
| 자동 작동 여부 | **불가** | 오케스트레이터 없이는 사용자가 수동으로 충돌을 감지하고 중재해야 함 |
| 실제 작동 사례 | **있음** | docs/06_에이전트비평/006_Synthesis에서 recovery 도메인명에 대해 3개 에이전트가 각기 다른 관점을 제시하고, 리드(사용자)가 판단한 사례 확인 |

**핵심 문제**: 현재 충돌 해결 프로토콜은 "에이전트가 동시에 같은 문제를 보고 있을 때"를 가정하지만, Claude Code 에이전트는 순차 실행이므로 **실시간 충돌 자체가 발생하지 않는다**. 실제로는 "이전 에이전트의 산출물에 대한 다음 에이전트의 이의 제기" 패턴이 필요하다.

#### 2.3 협업 체인의 현재 정의 상태

현재 명시적으로 정의된 검증 체인:
```
psychology ──검증──→ mbti (유형론 학술 타당성)
psychology ──검증──→ enneagram (실증 연구 한계)
```

**부재한 체인**:

| 필요한 체인 | 설명 | 현재 상태 |
|------------|------|----------|
| coding ──검증──→ psychology | 구현된 점수 계산이 심리측정학적으로 타당한가? | 암시적. 명시적 트리거 없음 |
| uiux ──검증──→ psychology | 결과 표현이 윤리적 가이드라인을 준수하는가? | 단방향만 정의 (psychology→uiux) |
| enneagram ←→ mbti | MBTI-애니어그램 교차 프로필의 일관성 | "협력" 명시, 구체적 검증 절차 없음 |
| all ──인계──→ coding | 도메인 요구사항의 구조화된 전달 | "전달" 명시, 인계 포맷 미정의 |

#### 2.4 오케스트레이터 도입 시 필요한 Collaboration Rules 변경

| 변경 항목 | 현재 | 필요 |
|-----------|------|------|
| 위임 수용 | 없음 | "오케스트레이터의 작업 위임을 수용하고, 지정된 범위 내에서 작업한다" |
| 산출물 보고 | 없음 | "작업 완료 시 구조화된 포맷으로 결과를 오케스트레이터에 반환한다" |
| 검증 요청 수용 | 암시적 | "다른 에이전트의 산출물 검증 요청을 받으면, 자기 영역의 관점에서 평가한다" |
| 충돌 에스컬레이션 | 사용자 위임 | "충돌 사항은 구조화된 형태로 오케스트레이터에 보고한다" |
| 인계 포맷 준수 | 없음 | "산출물은 지정된 인계 포맷(YAML frontmatter + Markdown)을 따른다" |

---

### 3. 기억 체계 분석

#### 3.1 디렉토리 구조

```
.claude/agent-memory/
├── psychology-expert/
│   ├── _index.yaml          (빈 인덱스, index: [])
│   └── memories/             (빈 디렉토리)
├── mbti-expert/
│   ├── _index.yaml          (빈 인덱스, index: [])
│   └── memories/             (빈 디렉토리)
├── enneagram-expert/
│   ├── _index.yaml          (빈 인덱스, index: [])
│   └── memories/             (빈 디렉토리)
├── coding-expert/
│   ├── _index.yaml          (빈 인덱스, index: [])
│   └── memories/             (빈 디렉토리)
└── uiux-expert/
    ├── _index.yaml          (빈 인덱스, index: [])
    └── memories/             (빈 디렉토리)
```

#### 3.2 _index.yaml 분석

5개 에이전트의 `_index.yaml`이 모두 **동일한 구조**이며, **모두 `index: []` (빈 배열)**이다.

파일 구조 (예: `.claude/agent-memory/psychology-expert/_index.yaml`):
```yaml
description: "심리학 전문가 기억 인덱스"
storage_path: ".claude/agent-memory/psychology-expert/memories/"
index: []
```

| 에이전트 | description | index 항목 수 | memories/ 파일 수 |
|---------|-------------|:---:|:---:|
| psychology-expert | "심리학 전문가 기억 인덱스" | **0** | **0** |
| mbti-expert | "MBTI 전문가 기억 인덱스" | **0** | **0** |
| enneagram-expert | "애니어그램 전문가 기억 인덱스" | **0** | **0** |
| coding-expert | "코딩 전문가 기억 인덱스" | **0** | **0** |
| uiux-expert | "UI/UX 전문가 기억 인덱스" | **0** | **0** |

#### 3.3 기억 파일의 실제 내용과 품질 평가

**실제 기억: 0건.**

5개 에이전트 모두 memories/ 디렉토리가 완전히 비어 있다. 에이전트 프롬프트(각 에이전트 L69-109 부근)에 상세한 기억 시스템 프로토콜이 정의되어 있으나, **단 한 번도 실제로 기억이 생성된 적이 없다**.

**기억 미생성의 원인 분석**:
1. docs/06_에이전트비평/ 의 비평 작업은 `.claude/agents/*.md` 에이전트가 아닌 `general-purpose` 서브에이전트로 실행됨 (006_Synthesis L20-25: "Agent Type: general-purpose (sonnet)")
2. 따라서 에이전트 프롬프트의 Memory System 지시가 적용되지 않았음
3. 에이전트가 실제로 자기 페르소나로 실행된 사례가 docs에서 확인되지 않음

**품질 평가**: 기억 시스템은 **설계는 양호하나 실행이 0%인 사문화 상태**.

#### 3.4 교차 에이전트 기억 참조 분석

**현재 상태**: `related_memories` 필드가 기억 포맷에 정의되어 있으나 (각 에이전트 L103), 기억 자체가 0건이므로 **교차 참조가 발생한 적 없음**.

**구조적 문제**: 현재 `related_memories` 필드는 **같은 에이전트 내** 기억 간 연결만을 암시한다. 에이전트 프롬프트에 "다른 에이전트의 기억을 참조하라"는 지시가 없다.

예: psychology-expert의 기억 시스템 프로토콜 (L74-83)은 자기 디렉토리(`.claude/agent-memory/psychology-expert/`)만 읽도록 지시한다. mbti-expert의 기억을 참조하는 메커니즘은 부재.

#### 3.5 조직 수준 공유 기억의 필요성

| 공유 기억 유형 | 필요성 | 현재 대안 | 대안의 한계 |
|--------------|--------|----------|------------|
| **프로젝트 결정 기록** | 높음 | docs/ 문서 | 에이전트가 어떤 문서를 읽어야 하는지 모름 |
| **교차 검증 결과** | 높음 | docs/06_에이전트비평/ | 일회성, 구조화되지 않음 |
| **도메인 합의** | 중간 | 없음 | recovery→planning_style 같은 결정이 기록되지 않음 |
| **기술 부채 목록** | 중간 | 없음 | coding-expert가 발견한 부채를 다른 에이전트가 모름 |
| **사용자 선호** | 낮음 | CLAUDE.md에 일부 | 체계적이지 않음 |

**부재로 인한 구체적 문제**: docs/06_에이전트비평/에서 3개 에이전트가 독립적으로 "recovery 도메인명 변경"을 권고했으나, 이 합의가 어떤 에이전트의 기억에도 저장되지 않았다. 향후 에이전트가 코드 작업 시 여전히 recovery라는 이름을 사용할 가능성이 있다.

---

### 4. 도구 격차 분석

#### 4.1 현재 도구 할당 비교

| 도구 | psychology | mbti | enneagram | coding | uiux |
|------|:-:|:-:|:-:|:-:|:-:|
| Read | O | O | O | O | O |
| Write | O | O | O | O | O |
| Edit | O | O | O | O | O |
| Glob | O | O | O | O | O |
| Grep | O | O | O | O | O |
| **Bash** | **X** | **X** | **X** | **O** | **O** |
| **Agent** | **X** | **X** | **X** | **X** | **X** |

**참고**: 파일 경로 (frontmatter 위치)
- psychology-expert: `.claude/agents/psychology-expert.md` L5
- mbti-expert: `.claude/agents/mbti-expert.md` L5
- enneagram-expert: `.claude/agents/enneagram-expert.md` L5
- coding-expert: `.claude/agents/coding-expert.md` L6
- uiux-expert: `.claude/agents/uiux-expert.md` L6

#### 4.2 현재 도구 할당의 적절성 평가

| 할당 | 판정 | 근거 |
|------|------|------|
| 3개 자문 에이전트에 Bash 미할당 | **적절** | 심리학/MBTI/애니어그램 전문가는 코드 실행이 아닌 콘텐츠 검토·작성이 주 역할. Bash 부여 시 역할 이탈(drift) 위험 (doc 002 L71: "무분별한 도구의 부여는 에이전트가 본인의 역할을 이탈하게 만드는 주된 원인") |
| coding-expert에 Bash 할당 | **적절** | RSpec 실행, 마이그레이션, Rails console 등 필수. maxTurns도 25로 가장 높음 |
| uiux-expert에 Bash 할당 | **적절** | Tailwind 빌드, Stimulus 테스트 등 프론트엔드 도구 실행 필요 |
| 5개 에이전트 모두 Write/Edit 보유 | **적절** | docs/05_agent_design/006_Synthesis L37-39에서 확인: 자문 에이전트도 문항/유형 설명 텍스트 직접 수정 필요 |

#### 4.3 오케스트레이터에 필요한 도구 세트

| 도구 | 필요 여부 | 근거 |
|------|----------|------|
| **Agent** | **필수** | 하위 에이전트를 호출하여 작업을 위임하는 핵심 메커니즘. 단, Claude Code에서 커스텀 에이전트를 Agent tool로 호출 가능한지는 003_Agent_프레임워크제약.md 조사 결과에 의존 |
| Read/Glob/Grep | 필수 | 에이전트 산출물 읽기, 기억 참조, 프로젝트 상태 파악 |
| Write/Edit | 필수 | 작업 분해 결과 기록, 인계 파일 생성, 종합 보고서 작성 |
| Bash | 선택적 | 오케스트레이터가 직접 코드를 실행할 필요는 낮음. git status 등 제한적 용도 |

#### 4.4 각 에이전트에 추가/제거가 필요한 도구

| 에이전트 | 추가 필요 | 제거 필요 | 근거 |
|---------|----------|----------|------|
| psychology-expert | 없음 | 없음 | 현재 도구 세트 적절 |
| mbti-expert | 없음 | 없음 | 현재 도구 세트 적절 |
| enneagram-expert | 없음 | 없음 | 현재 도구 세트 적절 |
| coding-expert | 없음 | 없음 | 현재 도구 세트 적절 |
| uiux-expert | 없음 | 없음 | 현재 도구 세트 적절 |
| **orchestrator (신규)** | Agent, Read, Write, Edit, Glob, Grep | N/A | 작업 위임 + 산출물 관리 |

#### 4.5 추가 Frontmatter 차이

| 설정 | psychology | mbti | enneagram | coding | uiux |
|------|:-:|:-:|:-:|:-:|:-:|
| model | sonnet | sonnet | sonnet | sonnet | sonnet |
| maxTurns | 15 | 15 | 15 | **25** | **20** |
| permissionMode | acceptEdits | acceptEdits | acceptEdits | acceptEdits | acceptEdits |
| skills | 없음 | 없음 | 없음 | 없음 | **[ui-ux-pro-max]** |

**관찰**:
- coding-expert의 maxTurns가 25로 가장 높은 것은 적절 (코드 작성·테스트·수정 반복에 더 많은 턴 필요)
- uiux-expert만 skills 필드 보유. 이 기능의 정확한 동작은 003 문서 조사 범위
- 오케스트레이터는 여러 에이전트를 순차 호출해야 하므로 **maxTurns를 가장 높게 설정**해야 함 (30-50 권장)

---

## Key Findings

### 격차 1: Goal 부재 [심각도: Critical]

5개 에이전트 모두 **"무엇을 달성해야 하는가"(Goal)**가 정의되어 있지 않다. Core Principles는 "지켜야 할 규칙"이지 "달성해야 할 목표"가 아니다.

- **영향**: 에이전트가 작업을 받았을 때 "이 작업이 내 목표에 부합하는가?"를 판단할 수 없음
- **조직화 시 필요**: 오케스트레이터가 작업을 위임할 때, 각 에이전트의 Goal을 기준으로 적합한 에이전트를 선택해야 함
- **파일 위치**: `.claude/agents/*.md` 5개 파일 모두 Role 섹션 직후에 Goal 섹션 추가 필요

### 격차 2: Backstory 부재 [심각도: High]

에이전트의 사고 편향을 고정하는 서사적 배경이 없다. Communication Style이 톤을 부분적으로 정의하지만, "왜 이 관점을 가지는가"의 깊은 맥락이 부재하다.

- **영향**: doc 002 L64-65가 경고하듯, Backstory는 "모델의 응답에 내재된 어조, 형식, 분석의 편향성을 의도한 방향으로 고정"하는 역할
- **우선순위**: Goal보다 낮음. doc 002 L53의 80/20 규칙에 따라 Task 설계에 80%, 페르소나에 20% 투입

### 격차 3: 기억 체계 사문화 [심각도: Critical]

기억 시스템이 설계만 되고 실행이 0%이다. 5개 에이전트 x 0건 = 총 0건의 기억.

- **근본 원인**: 에이전트가 실제로 자기 페르소나로 실행된 적이 거의 없음. 비평 작업은 general-purpose 서브에이전트로 수행됨
- **조직화 시 필요**: 기억이 없으면 에이전트 간 학습 축적 불가. 특히 교차 검증 결과, 프로젝트 결정, 도메인 합의의 기록이 필수

### 격차 4: 교차 에이전트 기억 참조 부재 [심각도: High]

각 에이전트의 Memory System 프로토콜이 **자기 디렉토리만 읽도록** 지시한다. 다른 에이전트의 기억을 참조하는 메커니즘이 없다.

- **필요**: `.claude/agent-memory/shared/` 또는 유사한 조직 수준 공유 기억 공간
- **영향**: recovery 도메인명 변경 같은 프로젝트 전체 결정이 개별 에이전트에 전파되지 않음

### 격차 5: 협업 규칙의 피상성 [심각도: High]

Collaboration Rules가 "관계 설명 + 충돌 시 4단계 프로토콜"의 획일적 구조로, 실질적 위임 체인이 없다.

- **문제**: "어떤 상황에서 누가 누구에게 무엇을 요청하는가"가 구체적이지 않음
- **문제**: 충돌 해결 프로토콜이 동시 실행을 가정하나, Claude Code는 순차 실행
- **조직화 시 필요**: 오케스트레이터 중심의 위임·보고·검증 체인으로 재설계

### 격차 6: 오케스트레이터 에이전트 부재 [심각도: Critical]

작업 분해, 에이전트 선택, 결과 종합, 품질 판정을 담당하는 지휘 계층이 없다.

- **현재**: 사용자가 모든 조정을 직접 수행
- **필요**: `.claude/agents/orchestrator.md` 신규 생성 (Agent tool 포함)

### 격차 7: 구조화된 인계 포맷 부재 [심각도: Medium]

에이전트 간 산출물 전달이 자유 텍스트(docs/ 마크다운 문서)로만 이루어진다. 구조화된 인계 포맷이 없어 다음 에이전트가 이전 에이전트의 산출물을 체계적으로 파싱할 수 없다.

- **doc 002 L87**: "에이전트 간의 결과물 인계는 반드시 엄격한 포맷 규칙에 따라 이루어져야 한다"
- **필요**: YAML frontmatter + Markdown body 형태의 표준 인계 포맷

---

## Recommendations

### 즉시 조치 (사이클 3 페르소나 강화)

1. **Goal 섹션 추가**: 5개 에이전트 모두에 측정 가능한 목표를 정의. 예:
   - psychology-expert: "성격 서비스의 모든 콘텐츠가 학술적 근거를 갖추도록 검증하고, 심리측정학적 타당성을 보장한다"
   - coding-expert: "personality 서비스의 Ruby on Rails 백엔드를 TDD 기반으로 구현하고, 기술 부채를 최소화한다"

2. **Backstory 섹션 추가**: 각 에이전트의 사고 편향을 고정하는 간결한 서사. 단, 80/20 규칙에 따라 과도하지 않게.

3. **Collaboration Rules 재설계**: 오케스트레이터 중심의 위임·보고 패턴으로 전환. 충돌 해결을 "순차 실행" 맥락에 맞게 수정.

4. **Memory System 프로토콜에 교차 참조 추가**: "관련 작업 시 `.claude/agent-memory/shared/` 공유 기억도 참조하라" 지시 추가.

### 사이클 1-2 의존 조치

5. **오케스트레이터 에이전트 생성**: `.claude/agents/orchestrator.md` — Agent tool 포함, 작업 분해·위임·종합 로직 인코딩 (사이클 1 결과에 의존).

6. **인계 포맷 표준화**: YAML frontmatter + Markdown body 포맷 정의 (사이클 2 범위).

7. **공유 기억 공간 생성**: `.claude/agent-memory/shared/` 디렉토리 + `_index.yaml` 생성. 프로젝트 결정, 교차 검증 결과, 도메인 합의를 기록.

---

## References

### 분석 대상 파일

| 파일 | 역할 |
|------|------|
| `.claude/agents/psychology-expert.md` | 심리학 전문가 에이전트 정의 |
| `.claude/agents/mbti-expert.md` | MBTI 전문가 에이전트 정의 |
| `.claude/agents/enneagram-expert.md` | 애니어그램 전문가 에이전트 정의 |
| `.claude/agents/coding-expert.md` | 코딩 전문가 에이전트 정의 |
| `.claude/agents/uiux-expert.md` | UI/UX 전문가 에이전트 정의 |
| `.claude/agent-memory/*/\_index.yaml` | 5개 에이전트 기억 인덱스 (모두 빈 상태) |

### 참조 문서

| 문서 | 참조 내용 |
|------|----------|
| `docs/002_gemini_deep_research.md` (L50-87) | 페르소나 5요소 모델, SOP 철학, 구조화된 출력 |
| `docs/05_agent_design/003_Agent_페르소나설계.md` | 4축 모델, 고성능 프롬프트 패턴, 안티패턴 |
| `docs/05_agent_design/006_Synthesis_전문에이전트구성.md` | 에이전트 설계 종합 결론, 자문 에이전트 쓰기 권한 |
| `docs/06_에이전트비평/006_Synthesis_코드베이스비평.md` | 5개 에이전트 실제 비평 사례, 교차 발견 패턴 |
| `docs/07_organizational_agents/001_Scope_조직에이전트_전환.md` | 조직 에이전트 전환 스코프, 3개 사이클 |
| `docs/07_organizational_agents/002_Research_조직아키텍처_오케스트레이터.md` | 연구 개요, 4개 관점, Perspective 3 지침 |
