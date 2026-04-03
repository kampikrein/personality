---
id: "012"
title: "SOP 행동 루프 인코딩 분석"
category: agent
status: archived
created: 2026-03-14
summary: >
  MetaGPT의 Observe→Think→Act→Share SOP 철학을 Claude Code 에이전트 프롬프트에
  구조화하는 방안을 분석하고, 역할별 SOP 변형을 설계한다. 현재 Analysis Framework이
  암묵적으로 O→T→A→S를 포함하고 있으나 명시적 인코딩이 부재하며, 특히 Observe와
  Share 단계가 구조적으로 결여되어 있음을 발견했다.
keywords: [agent-report, SOP, Observe-Think-Act-Share, MetaGPT, 프롬프트매핑, 역할별변형]
modules: [.claude/agents]
---

# SOP 행동 루프 인코딩 분석

## Progress
### Completed
- [x] docs/002_gemini_deep_research.md에서 SOP 관련 내용 전체 추출
- [x] docs/001_gemini_deep_research.md에서 5개 핵심 계층 확인
- [x] 5개 에이전트 Analysis Framework 섹션 비교 분석
- [x] 오케스트레이터 프롬프트 현재 구조 분석
- [x] SOP 4단계를 기존 프롬프트에 매핑하는 방안 도출
- [x] 역할별 SOP 변형 설계 (psychology, mbti/enneagram, coding, uiux)
- [x] SOP와 인계/평가루프 통합 방안
### Remaining
(없음)
### Current Status
조사 완료.

## Summary

MetaGPT의 "Code = SOP(Team)" 철학이 제시하는 Observe→Think→Act→Share 행동 루프를 현재 personality 프로젝트의 5개 전문 에이전트 프롬프트에 매핑하는 방안을 분석했다. 핵심 발견은 다음과 같다: (1) 현재 에이전트 프롬프트는 "Analysis Framework" 섹션에서 Think→Act 단계만 암묵적으로 다루고 있으며, Observe(입력 읽기)와 Share(산출물 전달) 단계가 구조적으로 누락되어 있다. (2) 5개 에이전트의 Analysis Framework은 각각 5단계 체크리스트로 구성되어 있으나, 이것이 무엇을 읽고(Observe) 무엇을 남기는지(Share)를 명시하지 않는다. (3) SOP 4단계를 명시적으로 인코딩하면 에이전트의 행동 예측가능성을 높이고, 인계 파일과 자연스럽게 통합할 수 있다.

---

## Details

### 1. MetaGPT SOP 이론 분석

#### 1.1 핵심 철학: "Code = SOP(Team)"

docs/002_gemini_deep_research.md 섹션 4에서 MetaGPT의 핵심 철학을 다음과 같이 정의한다:

> 인간 사회의 업무 절차를 LLM 기반의 에이전트 팀에 그대로 물질화(Materialize)하여 적용한다.

이 철학의 실체는 에이전트들이 **무계획적으로 소통하는 것이 아니라**, 엄격한 행동 루프를 따르는 것이다.

#### 1.2 O→T→A→S 4단계 정의

| 단계 | 원문 정의 (002 문서 기반) | 목적 |
|------|--------------------------|------|
| **Observe** | 공유 환경에 게시된 이전 작업자의 결과물을 주의 깊게 읽어 들인다 | 컨텍스트 획득, 중복 방지, 연속성 보장 |
| **Think** | 자신의 역할과 목표에 비추어 무엇을 해야 할지 논리적으로 추론한다 | 역할 기반 판단, 범위 확인, 접근법 결정 |
| **Act** | 부여된 도구를 사용해 구체적인 작업을 수행한다 | 산출물 생산, 코드 작성, 검증 수행 |
| **Share** | 결과물을 다음 작업자를 위해 공유 환경에 브로드캐스팅한다 | 인계, 상태 갱신, 다음 단계 활성화 |

#### 1.3 SOP가 에이전트 품질에 미치는 영향

002 문서에서 제시하는 이론적 근거:

- **환각 캐스케이딩 방지**: 두 LLM이 순수 자연어로 대화하면 의미 없는 잡담이나 과장된 표현이 섞이며 환각이 증폭된다. SOP의 구조화된 출력(Structured Outputs)이 이를 차단한다.
- **예측 가능성 확보**: 에이전트의 행동이 O→T→A→S 순서를 따르므로 오케스트레이터가 상태를 추적하기 쉽다.
- **역할 이탈(Drift) 방지**: Think 단계에서 "자신의 역할과 목표에 비추어" 판단하므로 본연의 임무에서 벗어나는 것을 억제한다.

#### 1.4 5개 핵심 계층과의 매핑 (001 문서)

docs/001_gemini_deep_research.md에서 제시하는 에이전트 시스템의 5개 핵심 계층:

| 계층 | SOP 단계 매핑 |
|------|-------------|
| 인지 및 입력 모듈 (Perception Module) | **Observe** |
| 기억 및 지식 시스템 (Memory System) | **Observe** (기억 조회) + **Share** (기억 저장) |
| 추론 및 계획 엔진 (Planning Engine) | **Think** |
| 행동 실행 계층 (Action Execution Layer) | **Act** |
| 관찰 및 피드백 루프 (Feedback Loop) | **Share** → 다음 사이클의 **Observe** |

---

### 2. 현재 에이전트 프롬프트의 Analysis Framework 비교 분석

#### 2.1 5개 에이전트의 Analysis Framework 비교

| 에이전트 | Framework 단계 1 | 단계 2 | 단계 3 | 단계 4 | 단계 5 |
|---------|-----------------|--------|--------|--------|--------|
| psychology | 범위 확인 | 근거 수집 | 측정 검증 | 윤리 점검 | 프로젝트 정합 |
| mbti | 문화적 맥락 | 법적 안전성 | 학문적 정합성 | 재미 vs 정확 | 경쟁 포지셔닝 |
| enneagram | 동기 탐색 | 건강 수준 | 복합 프로필 | 성장 가이드 | 보완 관계 |
| coding | Rails 컨벤션 | 테스트 설계 | 데이터 모델 | 성능 | 보안/프라이버시 |
| uiux | 감정 상태 | 정보 구조 | 모바일 경험 | 접근성 | 문화적 적합 |

#### 2.2 구조적 분석: O→T→A→S 관점에서의 격차

**공통 패턴**:
- 모든 에이전트가 5단계 체크리스트를 가지고 있다.
- 이 체크리스트는 사실상 **Think 단계의 판단 기준**만을 나열한다.
- "문제를 받으면 다음 순서로 분석한다" (psychology-expert 원문)라는 트리거 문구만 존재한다.

**누락된 것**:

| SOP 단계 | 현재 상태 | 격차 |
|---------|----------|------|
| **Observe** | 암묵적. Memory System에서 "작업 시작 시 _index.yaml을 읽어라"라고만 명시. 이전 에이전트 산출물을 어떻게 읽는지 프로토콜 없음. | 무엇을 읽고, 어디서 읽고, 어떤 정보를 추출하는지 미정의 |
| **Think** | Analysis Framework이 사실상 Think 단계. 그러나 "입력에서 추출한 정보를 이 기준으로 판단한다"는 연결이 없음 | 입력→판단→결정의 흐름이 명시적이지 않음 |
| **Act** | Core Principles + Boundaries에서 간접적으로 행동 범위를 정의. 그러나 "무엇을 생산하는지"가 명시되지 않음 | 산출물 형태/포맷/저장 위치 미정의 |
| **Share** | 완전 누락. Memory System의 "작업 완료 시" 절차만 존재하며, 이것은 에이전트 자신의 기억 저장이지 다음 에이전트를 위한 인계가 아님 | 인계 산출물 생성 프로토콜 부재 |

#### 2.3 오케스트레이터 프롬프트 현재 구조

오케스트레이터(.claude/agents/orchestrator.md)에는 SOP와 관련된 간접적 요소들이 이미 존재한다:

- **Agent Delegation Protocol**: 에이전트 스폰 시 "구체적 작업 지시, 참조 파일 경로, 산출물 저장 위치, 완료 기준"을 포함하라고 명시 -- 이는 워커의 Observe 입력을 오케스트레이터가 구성해주는 것
- **산출물 저장 규칙**: `.claude/work-orders/{workflow-id}/step-{N}_{slug}.md` -- Share의 목적지
- **Evaluation Loop Protocol**: verdict 포맷 -- 평가루프에서의 Share 규격
- **Context Compression 3단계**: Level 1/2/3 읽기 -- Observe의 깊이 조절

그러나 이들은 **서로 연결되지 않은 개별 규칙**으로 존재하며, O→T→A→S라는 통합 프레임워크로 조직되어 있지 않다.

---

### 3. SOP 4단계를 기존 프롬프트에 매핑하는 방안

#### 3.1 프롬프트 구조 변경 제안

현재 에이전트 프롬프트의 섹션 구조:
```
# Role
# Project Context
# Core Principles
# Analysis Framework    ← Think만 커버
# Communication Style
# Boundaries & Red Lines
# Collaboration Rules
# Memory System
```

제안하는 구조 (Analysis Framework을 SOP로 확장):
```
# Role
# Project Context
# Core Principles
# SOP: 행동 루프         ← 신규 섹션 (Analysis Framework 대체)
  ## Observe: 입력 읽기
  ## Think: 분석 & 판단
  ## Act: 산출물 생성
  ## Share: 인계 & 기록
# Communication Style
# Boundaries & Red Lines
# Collaboration Rules
# Memory System
```

#### 3.2 각 SOP 단계의 공통 골격

**Observe (모든 에이전트 공통)**:
```markdown
## Observe: 입력 읽기
1. 오케스트레이터가 전달한 작업 지시를 파악한다.
2. 지시에 포함된 참조 파일을 Read로 읽는다.
3. 이전 단계 산출물이 있으면 그 Key Findings와 산출물을 확인한다.
4. Memory System의 관련 기억을 조회한다.
5. 입력에서 추출한 핵심 정보를 정리한다:
   - 작업 목표: {무엇을 달성해야 하는가}
   - 입력 데이터: {어떤 파일/정보가 주어졌는가}
   - 제약 조건: {이전 단계 결정, 법적 제약 등}
```

**Think (역할별 변형 -- 기존 Analysis Framework 유지)**:
```markdown
## Think: 분석 & 판단
입력에서 추출한 정보를 다음 기준으로 분석한다:
1. {역할별 기준 1}
2. {역할별 기준 2}
...
분석 결과를 바탕으로 행동 계획을 수립한다.
```

**Act (역할별 변형)**:
```markdown
## Act: 산출물 생성
Think에서 수립한 계획에 따라 다음을 수행한다:
- {역할별 구체 행동}
- 산출물을 지정된 위치와 포맷으로 저장한다.
```

**Share (모든 에이전트 공통)**:
```markdown
## Share: 인계 & 기록
1. 산출물을 오케스트레이터가 지정한 경로에 저장한다.
2. 산출물의 frontmatter에 다음을 포함한다:
   - summary: 1-2줄 핵심 요약
   - key_findings: 주요 발견 bullet points
   - confidence: high | medium | low
   - next_steps: 다음 에이전트에 대한 제안
3. Memory System에 의미 있는 발견을 기록한다.
```

#### 3.3 오케스트레이터 SOP 마스터 섹션 추가 방안

오케스트레이터에는 워커의 SOP를 조율하는 **마스터 SOP 섹션**을 추가한다:

```markdown
# SOP 마스터: 워커 행동 루프 관리

## 원칙
모든 워커 에이전트는 Observe→Think→Act→Share 행동 루프를 따른다.
오케스트레이터는 이 루프의 입력(Observe 재료)과 출력(Share 목적지)을 관리한다.

## 에이전트 스폰 시 SOP 입력 구성
워커를 스폰할 때, Observe 단계의 재료를 프롬프트에 명시한다:
- 작업 목표 (무엇을 달성)
- 참조 파일 경로 (이전 단계 산출물)
- 산출물 저장 위치와 포맷
- 완료 기준
- 이전 평가 피드백 (재시도인 경우)

## Share 산출물 확인
워커 완료 후 산출물의 frontmatter를 Level 2로 읽어:
- summary와 key_findings로 다음 단계 결정
- confidence가 low이면 추가 검증 고려
- next_steps를 다음 워커의 Observe 입력에 포함
```

---

### 4. 역할별 SOP 변형 설계

#### 4.1 psychology-expert: 학술 검증 SOP

| 단계 | 구체적 행동 |
|------|-----------|
| **Observe** | (1) 검증 대상 파일(문항, 유형 설명, 점수 로직)을 읽는다. (2) 관련 학술 이론의 기억을 조회한다. (3) 이전 검증 결과가 있으면 미해결 사항을 확인한다. |
| **Think** | (1) 범위 확인: 관련 심리학 이론 식별. (2) 근거 수집: 학술적 지지 수준 평가. (3) 측정 검증: 심리측정학적 타당성. (4) 윤리 점검: 바넘 효과, 라벨링 위험. (5) 프로젝트 정합: "진단이 아닌 자기이해" 부합 여부. |
| **Act** | (1) 검증 보고서 작성 (verdict: pass/fail/conditional_pass). (2) fail 항목별 구체적 수정 제안(fix_suggestion) 포함. (3) 학술 근거를 APA 스타일로 인용. |
| **Share** | (1) 검증 결과를 지정 경로에 evaluation YAML로 저장. (2) 핵심 발견을 key_findings에 bullet point로 정리. (3) 관련 학술 발견을 Memory에 기록. |

#### 4.2 mbti-expert / enneagram-expert: 설계 SOP

| 단계 | 구체적 행동 |
|------|-----------|
| **Observe** | (1) 설계 요구사항(문항 추가, 유형 설명 작성 등)을 파악한다. (2) 기존 문항/유형 데이터(db/seeds/ 등)를 읽는다. (3) 이전 심리학 검증 피드백이 있으면 반영 사항을 확인한다. (4) Memory에서 관련 설계 결정 기억을 조회한다. |
| **Think** | **mbti**: (1) 문화적 맥락 (2) 법적 안전성 (3) 학문적 정합성 (4) 재미 vs 정확 밸런스 (5) 경쟁 포지셔닝. **enneagram**: (1) 동기 탐색 (2) 건강 수준 반영 (3) 복합 프로필(날개/본능) (4) 성장 가이드 (5) MBTI 보완. |
| **Act** | (1) 문항 초안 / 유형 설명 초안을 작성한다. (2) 법적 안전성 자가 점검 (공식 검사 문항 유사도 확인). (3) 지정 포맷(Markdown + YAML frontmatter)으로 저장. |
| **Share** | (1) 초안을 지정 경로에 저장. (2) frontmatter에 confidence와 검증 요청 사항 명시. (3) "심리학 검증 필요" 플래그를 next_steps에 포함. (4) 설계 결정의 근거를 Memory에 기록. |

#### 4.3 coding-expert: 구현 SOP

| 단계 | 구체적 행동 |
|------|-----------|
| **Observe** | (1) 구현 요구사항을 파악한다 (도메인 전문가의 설계 산출물 참조). (2) 관련 코드 탐색: Glob/Grep으로 기존 구현 확인. (3) DB 스키마와 서비스 레이어 현황 파악. (4) Memory에서 관련 기술적 결정/패턴 조회. |
| **Think** | (1) Rails 컨벤션: 모델/컨트롤러/서비스 패턴 선택. (2) 테스트 설계: 필요한 테스트 유형 결정. (3) 데이터 모델: 스키마 적절성. (4) 성능: N+1, 캐싱 고려. (5) 보안/프라이버시: PII 보호. |
| **Act** | (1) 테스트 코드 작성 (TDD). (2) 구현 코드 작성. (3) 테스트 실행 및 통과 확인. (4) 코드를 직접 파일에 Write/Edit. |
| **Share** | (1) 변경된 파일 목록과 요약을 산출물로 저장. (2) 테스트 결과(통과/실패)를 key_findings에 포함. (3) 기술적 결정의 근거를 Memory에 기록. (4) 통합 테스트 필요 여부를 next_steps에 명시. |

#### 4.4 uiux-expert: UX 설계/구현 SOP

| 단계 | 구체적 행동 |
|------|-----------|
| **Observe** | (1) UX 요구사항을 파악한다 (감정 여정의 어떤 단계인지). (2) 기존 뷰 파일(app/views/)을 읽는다. (3) 도메인 전문가의 콘텐츠 구조를 참조한다. (4) Memory에서 UX 결정 기억 조회. |
| **Think** | (1) 감정 상태: 이 화면에서의 사용자 감정. (2) 정보 구조: 인지 부하. (3) 모바일 경험: 터치/스크롤. (4) 접근성: WCAG 2.1. (5) 문화적 적합: 한국 UX 관습. |
| **Act** | (1) Tailwind CSS + Hotwire/Turbo로 뷰 구현. (2) 접근성 체크리스트 확인. (3) 모바일 퍼스트 반응형 확인. |
| **Share** | (1) 변경된 뷰 파일 목록과 UX 근거를 산출물으로 저장. (2) 접근성 준수 여부를 key_findings에 포함. (3) "감정 흐름 연결 여부"를 next_steps에 기록. (4) UX 결정을 Memory에 기록. |

---

### 5. SOP와 인계/평가루프 통합 방안

#### 5.1 Share → Observe 연결: 인계의 자연스러운 흐름

SOP의 가장 강력한 효과는 **Share 단계의 산출물이 곧 다음 에이전트의 Observe 입력**이 되는 구조에 있다.

```
[에이전트 A]                    [오케스트레이터]                [에이전트 B]
  Act → Share                       ↓                           ↓
  (산출물 저장) ──→ Read(Level 2) ──→ 다음 단계 결정 ──→ Observe
                   (summary,                            (산출물 읽기)
                    key_findings,
                    confidence)
```

이 흐름에서:
- **에이전트 A의 Share**: `.claude/work-orders/{wf}/step-1_xxx.md`에 frontmatter 포함 저장
- **오케스트레이터의 중계**: Level 2로 읽어 다음 에이전트 결정, 스폰 시 참조 파일 경로 전달
- **에이전트 B의 Observe**: 전달받은 경로의 파일을 Read하여 컨텍스트 획득

#### 5.2 평가루프에서의 SOP 통합

평가/정제 루프(Pattern B, C)에서 SOP는 다음과 같이 작동한다:

**생성 에이전트의 첫 번째 사이클**:
```
Observe: 작업 지시 읽기 → Think: 분석 → Act: 초안 생성 → Share: 초안 저장
```

**검증 에이전트의 사이클**:
```
Observe: 초안 + 검증 기준 읽기 → Think: 기준 대비 평가 → Act: verdict 판정 → Share: evaluation 저장
```

**생성 에이전트의 재시도 사이클** (fail인 경우):
```
Observe: 원래 지시 + 자신의 초안 + 검증 피드백 읽기 → Think: 피드백 반영 계획 → Act: 수정 → Share: 수정본 저장
```

핵심은 **재시도의 Observe가 이전 사이클의 모든 Share를 입력으로 받는다**는 점이다. 이것이 SOP가 평가루프와 자연스럽게 통합되는 메커니즘이다.

#### 5.3 SOP와 기억 체계의 연결

현재 에이전트의 Memory System은 이미 O→T→A→S와 부분적으로 정렬되어 있다:
- **Observe 시작**: "작업 시작 시 _index.yaml을 읽어라" = SOP Observe의 기억 조회 단계
- **Share 완료**: "작업 완료 시 기억 저장" = SOP Share의 장기 기억 갱신 단계

SOP를 명시적으로 인코딩하면 이 기억 체계가 더 자연스럽게 작동한다.

---

## Key Findings

1. **Observe/Share 구조적 부재**: 현재 5개 에이전트 프롬프트에는 Think(Analysis Framework)만 명시되어 있고, Observe(무엇을 읽는가)와 Share(무엇을 남기는가)가 구조적으로 누락되어 있다. Memory System의 읽기/쓰기 절차가 Observe/Share의 일부를 대체하고 있으나, 이전 에이전트 산출물을 읽는 프로토콜은 전혀 없다.

2. **오케스트레이터의 암묵적 SOP 중계**: 오케스트레이터의 Agent Delegation Protocol이 사실상 워커의 Observe 입력을 구성해주는 역할을 하고 있으나, 이것이 SOP 프레임워크로 명시적으로 연결되어 있지 않다. 오케스트레이터가 "참조할 파일 경로"를 전달하는 것은 Observe 재료를 공급하는 것이고, "산출물 저장 위치"를 지정하는 것은 Share 목적지를 설정하는 것이다.

3. **Analysis Framework = Think only**: 5개 에이전트 모두 5단계 체크리스트 형태의 Analysis Framework을 가지고 있으며, 이것은 순수하게 Think 단계에 해당한다. 역할별로 상이한 판단 기준(학술/법적/기술/UX)을 담고 있어 역할 분화가 잘 되어 있으나, 입력→판단→산출의 전체 흐름이 연결되지 않는다.

4. **SOP 인코딩의 핵심 이점 3가지**: (a) 에이전트 행동의 예측가능성 증대 -- 오케스트레이터가 각 단계에서 에이전트의 행동을 예측할 수 있다. (b) 인계 파일과의 자연 통합 -- Share의 산출물이 곧 인계 파일이 된다. (c) 평가루프와의 자연 통합 -- 재시도 시 이전 사이클의 Share가 새로운 Observe 입력이 된다.

5. **역할별 SOP 변형의 핵심 차이**: Observe와 Share는 공통 골격을 공유할 수 있으나, Think와 Act는 역할 고유의 변형이 필수적이다. 특히 Act 단계에서 psychology는 "검증 보고서 생성", mbti/enneagram은 "콘텐츠 초안 생성", coding은 "코드+테스트 작성", uiux는 "뷰 구현"으로 본질적으로 다른 행동을 한다.

6. **5개 핵심 계층과의 정렬**: 001 문서의 인지/기억/추론/행동/피드백 5계층은 O→T→A→S와 1:1로 매핑된다. 특히 기억 계층은 Observe(조회)와 Share(저장) 양쪽에 걸쳐 있어, 현재 Memory System 설계와 자연스럽게 통합된다.

---

## Recommendations

### 즉시 적용 가능한 변경 (사이클 2 구현)

1. **에이전트 프롬프트의 "# Analysis Framework" 섹션을 "# SOP: 행동 루프"로 확장**: 기존 5단계 체크리스트를 Think 하위로 유지하면서, Observe/Act/Share 단계를 추가한다. 기존 프롬프트 구조를 파괴하지 않고 확장하는 형태.

2. **오케스트레이터에 "# SOP 마스터" 섹션 추가**: 워커 스폰 시 Observe 재료 구성, Share 산출물 확인, 평가루프에서의 SOP 순환을 명시하는 마스터 프로토콜 추가.

3. **Share 단계의 frontmatter 표준화**: 모든 에이전트 산출물에 `summary`, `key_findings`, `confidence`, `next_steps` 필드를 필수로 포함하도록 SOP Share 단계에 명시. 이는 관점 1(인계 포맷 설계)과 통합하여 설계.

### 후속 연구 필요 사항

4. **SOP 인코딩 후 실제 워크플로우 테스트**: SOP를 적용한 프롬프트로 실제 작업(문항 추가 등)을 실행하여 행동 변화를 관찰하고, 산출물 품질 개선 여부를 검증할 필요가 있다.

5. **관점 1(인계 포맷)과의 통합**: Share 단계의 산출물 포맷이 곧 인계 파일 포맷이므로, 011 보고서의 인계 포맷 설계와 본 보고서의 Share 단계 설계를 통합해야 한다.

6. **관점 3(평가루프)과의 통합**: 재시도 사이클에서 Observe가 이전 evaluation을 입력으로 받는 메커니즘이 013 보고서의 종료 조건 설계와 정합적이어야 한다.

---

## References

- `/Users/kampikrein/A/personality/docs/002_gemini_deep_research.md` -- 섹션 4 "에이전트 소통 프로토콜 및 SOP 내재화 전략", MetaGPT "Code = SOP(Team)" 철학, O→T→A→S 정의
- `/Users/kampikrein/A/personality/docs/001_gemini_deep_research.md` -- "에이전트 시스템의 핵심 컴포넌트" 5개 계층 (인지/기억/추론/행동/피드백)
- `/Users/kampikrein/A/personality/.claude/agents/orchestrator.md` -- Agent Delegation Protocol, Evaluation Loop Protocol, Workflow State Management
- `/Users/kampikrein/A/personality/.claude/agents/psychology-expert.md` -- Analysis Framework (학술 검증 5단계)
- `/Users/kampikrein/A/personality/.claude/agents/mbti-expert.md` -- Analysis Framework (서비스 설계 5단계)
- `/Users/kampikrein/A/personality/.claude/agents/enneagram-expert.md` -- Analysis Framework (동기 중심 5단계)
- `/Users/kampikrein/A/personality/.claude/agents/coding-expert.md` -- Analysis Framework (Rails 구현 5단계)
- `/Users/kampikrein/A/personality/.claude/agents/uiux-expert.md` -- Analysis Framework (UX 설계 5단계)
- `/Users/kampikrein/A/personality/docs/07_organizational_agents/010_Research_소통프로토콜_SOP.md` -- 상위 연구 계획, Perspective 2 조사 항목
- MetaGPT 논문 (Hong et al., 2023) -- "MetaGPT: Meta Programming for A Multi-Agent Collaborative Framework" arXiv:2308.00352
