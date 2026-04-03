---
id: "007"
type: research
title: "Personality 프로젝트 전문 에이전트 구성 연구 — 최종 통합"
created: 2026-03-11
summary: >
  5개 전문 에이전트(심리학, MBTI, 애니어그램, 코딩, UI/UX)의 최적 구성을 4개 관점에서
  병렬 연구한 결과를 통합. 시스템 설정(tools/model/permission), 페르소나 프롬프트 설계,
  도메인별 지식 체계, MVP 역할 매핑의 종합 결론과 구현 가능한 에이전트 사양을 도출.
  2026-03-13 업데이트: kampi 프로젝트의 검증된 2계층 기억 구조를 에이전트별 persistent memory로 적응하는 관점 5 추가.
keywords: [에이전트설계, 프롬프트엔지니어링, 페르소나, 심리학, MBTI, 애니어그램, Rails, UIUX, Claude Code, agent-memory, kampi-pattern]
---

# Personality 프로젝트 전문 에이전트 구성 연구 — 최종 통합

## Research Overview

### Background & Motivation

personality 웹 서비스는 성격 유형 탐색(MBTI 방식, 애니어그램 방식 등)을 통해 자기 이해와 타인 수용을 돕는 서비스이다. 이 프로젝트의 개발 과정에서 각 도메인 전문가의 관점을 반영하기 위해 Claude Code 커스텀 에이전트(`.claude/agents/*.md`)를 활용하려 한다.

5개 에이전트:
1. **심리학 전문가** — 학문적 근거 기반 성격 이론 자문
2. **MBTI 전문가** — 한국 MBTI 트렌드 + 서비스 설계
3. **애니어그램 전문가** — 애니어그램 체계 기반 설계
4. **코딩 전문가** — Rails 백엔드 구현
5. **UI/UX 전문가** — 프론트엔드 설계·구현

### Research Scope

5개 관점에서 연구 (관점 1-4: 병렬 연구, 관점 5: 후속 연구):
1. Claude Code 에이전트 시스템 설정 최적화
2. 전문가 페르소나 프롬프트 설계 방법론
3. 도메인별 핵심 지식 체계
4. 프로젝트 컨텍스트 정합성
5. 에이전트별 기억 체계 설계 (2026-03-13 추가)

### Related Documents

- 체크포인트: [001_Research_전문에이전트_구성.md](./001_Research_전문에이전트_구성.md)
- 에이전트 보고서:
  - [002_Agent_시스템최적화.md](./002_Agent_시스템최적화.md)
  - [003_Agent_페르소나설계.md](./003_Agent_페르소나설계.md)
  - [004_Agent_도메인지식.md](./004_Agent_도메인지식.md)
  - [005_Agent_프로젝트정합성.md](./005_Agent_프로젝트정합성.md)
- 종합: [006_Synthesis_전문에이전트구성.md](./006_Synthesis_전문에이전트구성.md)
- 기억 체계 scope: [008_Scope_에이전트_기억체계.md](./008_Scope_에이전트_기억체계.md)
- kampi 기억 연구 (외부 참조): `/Users/kampikrein/A/kampi/docs/01_memory_system/001_Research_memory_pipeline_design.md`

---

## 관점 1: Claude Code 에이전트 시스템 설정 최적화

### 현황 분석

Claude Code 커스텀 에이전트는 `.claude/agents/*.md` 파일로 정의되며, YAML frontmatter(name, description, tools, model, permissionMode, maxTurns, skills, memory 등) + Markdown body(시스템 프롬프트)로 구성된다. 현재 이 프로젝트에는 에이전트 파일이 없다(`.claude/agents/` 디렉토리 미존재).

### 상세 발견사항

#### 에이전트별 최적 시스템 설정

| 설정 항목 | 자문 에이전트 (심리학/MBTI/애니어그램) | 코딩 전문가 | UI/UX 전문가 |
|----------|-------------------------------------|-----------|-------------|
| **tools** | Read, Glob, Grep, Edit, Write | Read, Write, Edit, Bash, Glob, Grep | Read, Write, Edit, Bash, Glob, Grep |
| **model** | sonnet | sonnet | sonnet |
| **permissionMode** | acceptEdits | acceptEdits | acceptEdits |
| **maxTurns** | 15 | 25 | 20 |
| **skills** | 없음 | 없음 | ui-ux-pro-max |
| **memory** | 프롬프트 내장 규칙 (관점 5 참조) | 프롬프트 내장 규칙 (관점 5 참조) | 프롬프트 내장 규칙 (관점 5 참조) |

#### 핵심 설계 결정과 근거

1. **자문 에이전트에 Write/Edit 부여**: 문항 텍스트(`db/seeds/`), 점수 가중치(`app/services/scoring/`), 보고서 문구(`app/services/insights/`, `app/views/results/`)를 직접 수정해야 하므로 읽기 전용으로는 불충분. 단 **Bash는 제외**하여 셸 실행 위험 차단.

2. **모든 에이전트 sonnet**: haiku는 복잡한 지시 수행이 부족하고, opus는 서브에이전트 수준에서 비용 대비 이점이 미미. 자문 에이전트의 높은 추론 요구는 프롬프트 품질로 보완.

3. **memory는 프롬프트 내장 규칙으로 구현**: `memory` frontmatter 필드 대신, 프롬프트에 기억 읽기/쓰기 규칙을 직접 포함. kampi 프로젝트에서 검증된 2계층 구조(인덱스+개별기억)를 `.claude/agent-memory/{agent-name}/`에 적용. docs/와는 보완 관계 — docs/는 공식 보고서, agent-memory/는 에이전트의 작업 맥락 축적. (관점 5 참조)

4. **WebSearch/WebFetch 전체 제외**: 외부 조사는 부모 세션의 `/research` 스킬이 담당. 서브에이전트에 부여하면 토큰 낭비와 작업 발산 초래.

5. **skills 최소화**: 기존 스킬 대부분은 독립 워크플로우를 가져 서브에이전트의 단발성 패턴과 충돌. 유일한 예외는 참조 데이터 성격의 `ui-ux-pro-max`.

### 주의사항 및 위험

- **isolation 미검토**: 코딩/UI/UX 에이전트가 동시에 같은 view 파일을 수정하면 충돌 가능. 필요 시 `isolation: worktree` 고려.
- **maxTurns 튜닝 필요**: 실사용 후 에이전트가 중간에 중단되거나 절반도 사용하지 않는 패턴을 관찰하여 조정.

### 요약

모든 에이전트에 sonnet + acceptEdits 기본 적용. 자문 에이전트는 Bash를 제외한 읽기/쓰기 도구, 구현 에이전트는 전체 도구를 부여. 스킬/memory/WebSearch는 최소화.

---

## 관점 2: 전문가 페르소나 프롬프트 설계

### 현황 분석

PromptHub 연구(2024-2025)와 Anthropic 공식 가이드에 따르면, 단순 역할 선언("너는 X 전문가야")은 사실 기반 과제에서 측정 가능한 성능 향상이 없다. **구체적 행동 규칙 + 판단 기준 + 출력 형식 제약**의 조합이 실질적 효과를 가져온다.

### 상세 발견사항

#### 페르소나 정의 프레임워크 (4축 모델)

| 축 | 내용 | 프롬프트 반영 방식 |
|----|------|-----------------|
| **WHO** (정체성) | 역할, 전문 분야, 자기 인식 경계 | `# Role` 섹션 — 1-2줄, 행동 중심 |
| **HOW** (사고 방식) | 분석 프레임워크, 우선순위, 판단 기준 | `# Analysis Framework` — 5단계 이내 |
| **STYLE** (소통) | 어조, 용어, 설명 깊이, 예시 패턴 | `# Communication Style` |
| **WHY** (가치관) | 핵심 가치, 레드라인, 프로젝트 정렬 | `# Boundaries & Red Lines` |

#### 고성능 프롬프트 패턴 6가지

1. **구체적 행동 규칙 > 추상적 성격 묘사**: "모든 주장에 학술 근거를 인용한다" > "깊은 통찰력을 가진 전문가"
2. **Chain-of-Thought 유도**: 분석 절차를 5단계로 내장
3. **전문가 관점 고정(Anchoring)**: 각 에이전트가 항상 특정 렌즈를 통해 먼저 봄
4. **할루시네이션 방지**: "모르겠다"를 명시적으로 허용
5. **관점 충돌 프로토콜**: 자기 영역 진술 → 다른 관점 인정 → 트레이드오프 명시 → 사용자에 위임
6. **Anthropic 권장 구조**: Role → Project Context → Core Principles → Analysis Framework → Communication Style → Boundaries → Collaboration의 7섹션

#### 프롬프트 안티패턴 6가지

1. 선언만 있고 행동 규칙 없음
2. 규칙 과잉(50개+)으로 에이전트 마비
3. 도메인 지식 과다 주입 → 컨텍스트 소모
4. 역할 겹침으로 에이전트 간 충돌
5. 비즈니스 맥락(법적 경계 등) 누락
6. 겸손함 없는 전지적 전문가 설정

#### 5개 에이전트별 페르소나 핵심 요약

| 에이전트 | Core Anchoring Question | 핵심 행동 규칙 | 레드라인 |
|---------|------------------------|--------------|---------|
| **심리학** | "심리측정학적으로 타당한가?" | 모든 주장에 학술 근거 인용, 바넘 효과 즉시 지적 | 근거 없는 확정적 유형 서술 |
| **MBTI** | "한국 사용자가 어떻게 받아들일까?" | 독자적 문항/표현 설계, 저작권 리스크 항상 확인 | 공식 MBTI 문항 복제 |
| **애니어그램** | "사용자의 성장을 돕는가?" | 동기 중심 해석, 건강 수준 모델 활용, 성장 방향 강조 | 결정론적/병리적 유형 서술 |
| **코딩** | "Rails 컨벤션이며 테스트 가능한가?" | TDD 우선, Convention over Configuration | 테스트 없는 코드 추천 |
| **UI/UX** | "감정 흐름에서 어떤 경험인가?" | 모바일 퍼스트, WCAG 2.1 준수, 감정 여정 설계 | 접근성 무시 |

### 요약

프롬프트는 7섹션 구조(Role/Context/Principles/Framework/Style/Boundaries/Collaboration)로 구성. 핵심 원칙 3-5개 + 분석 절차 5단계로 제한하고, 도메인 지식은 참조 파일로 분리.

---

## 관점 3: 도메인별 핵심 지식 체계

### 현황 분석

5개 에이전트 각각이 고유한 이론적 기반, 실무적 판단 기준, 프로젝트 특화 맥락을 갖추어야 한다. 핵심 원칙: 도메인 지식은 프롬프트에 직접 삽입하지 않고 참조 파일로 분리.

### 상세 발견사항

#### 에이전트별 필수 지식 계층

**1. 심리학 전문가**
- L1 (핵심): Big Five(OCEAN) 5요인 × 6패싯 = 30차원, 연속 스펙트럼 모델
- L2 (도구): NEO-PI-R(금표준, alpha>0.85), HEXACO(6요인), TCI(기질+성격)
- L3 (측정): 신뢰도(내적일관성/재검사), 타당도(구성/수렴/변별/내용/안면)
- L4 (윤리): 바넘 효과, 확증 편향, 라벨링 위험, 자기예언적 효과
- 프로젝트 연결: domain_scores의 reliability_coefficient, consistency_index가 L3 반영

**2. MBTI 전문가**
- L1 (핵심): Jung 심리 유형론 → Myers-Briggs 발전, 4선호지표(E-I/S-N/T-F/J-P), 인지 기능 8가지
- L2 (문화): 한국 MZ세대 현상 — 글로벌 검색량 1위, 소개팅/채용/밈화
- L3 (비판): 재검사 신뢰도 ~50%, Forer 효과, 이분법 문제
- L4 (법률): The Myers-Briggs Company 상표권 + 문항 저작권 + 부정경쟁방지법 3중 리스크
- L5 (경쟁): 16personalities(무료/NERIS 체계), 어세스타(한국 공식)

**3. 애니어그램 전문가**
- L1 (핵심): 9유형 + 날개(wing) + 통합/분열 방향 + 3본능 하위유형(SP/SO/SX)
- L2 (학파): Riso-Hudson(9단계 건강 수준), Naranjo(심리역동), Palmer(직관적), Ichazo(영적)
- L3 (성장): 건강/보통/비건강 수준, 각 유형의 성장 방향과 스트레스 방향
- L4 (법률): 기본 구조 = 공공 도메인(public domain), 특정 검사 도구(RHETI 등)만 보호
- MBTI와 핵심 차이: 동기(motivation) 기반 vs 행동(behavior) 기반

**4. 코딩 전문가**
- L1 (핵심): Rails 8+ 컨벤션, ActiveRecord, MVC, RESTful API
- L2 (스택): PostgreSQL, RSpec/FactoryBot, Hotwire(Turbo/Stimulus), Tailwind CSS
- L3 (도메인): 14 테이블 데이터 흐름 — anonymous_sessions → assessments → responses → domain_scores → profiles → insights
- L4 (특화): 점수 정규화(0-100), 역채점, 신뢰도 보정, 정책 차단(ToneFilter/RestrictedTerms)

**5. UI/UX 전문가**
- L1 (핵심): 사용자 리서치, 정보 구조(IA), 인터랙션 디자인
- L2 (특화): 성격 검사 UI 패턴 — 진행률 표시, 결과 시각화(레이더/바 차트), 프로필 카드
- L3 (시장): 한국 UX — 카카오/토스 수준 기대, 모바일 퍼스트, Pretendard 서체
- L4 (접근성): WCAG 2.1, 색상 대비, 스크린리더, 키보드 네비게이션
- L5 (감정): 감정 흐름 설계 — 기대 → 집중 → 흥분 → 성찰

#### 차별화 매트릭스

| 판단 축 | 심리학 | MBTI | 애니어그램 | 코딩 | UI/UX |
|---------|-------|------|-----------|------|-------|
| **핵심 질문** | "타당한가?" | "공감되는가?" | "성장을 돕는가?" | "구현 가능한가?" | "좋은 경험인가?" |
| **판단 기준** | 학술 근거 | 문화적 적합성 | 성장 가능성 | 기술적 실용성 | 사용자 경험 |
| **레퍼런스** | 논문/메타분석 | 트렌드/경쟁사 | 학파/모델 | 컨벤션/패턴 | UX 원칙/데이터 |
| **어조** | 학술적-중립 | 대중적-친근 | 깊이있는-긍정적 | 실용적-직접적 | 시나리오-구조적 |

### 요약

5개 에이전트는 동일 기능에 대해 학술근거/문화적합/성장가능/구현실용/사용자경험이라는 5개 축에서 각각 다른 판단을 내린다. 도메인 지식은 프롬프트에 넣지 않고 docs/ 참조 파일로 분리.

---

## 관점 4: 프로젝트 컨텍스트 정합성

### 현황 분석

기획 문서 5건, 코드점검 문서 6건, 코드베이스 분석 문서 4건, 실제 코드(14모델, 19서비스, 12컨트롤러)를 정독한 결과: **기술 인프라는 대부분 구현되어 있으나, 콘텐츠 레이어(학술 근거 있는 문항, 독자적 유형 해석, 인사이트)가 미완성**. 이것이 자문 에이전트 3인의 핵심 기여 영역이다.

### 상세 발견사항

#### MVP 구성요소별 에이전트 역할 매핑

| MVP 구성요소 | 심리학 | MBTI | 애니어그램 | 코딩 | UI/UX |
|------------|-------|------|-----------|------|-------|
| **문항 엔진** | 문항 설계 이론, 편향 검토 | 4차원별 문항 초안, 한국 트렌드 반영 | 동기 기반 문항 설계 | QuestionSet/Question 구현 | 리커트 선택 UI, 진행률 |
| **점수 엔진** | 정규화 방법론, 신뢰도 기준값 | 4차원 점수 분포, 임계값 검토 | 날개/통합분열 점수 산출 | Scoring 모듈 5개 서비스 | — |
| **프로필 컴포저** | 해석 근거, 낙인 금지 정책 | 16유형 독자 캐릭터/설명 | 9유형 동기/두려움/성장 해석 | Profiles 모듈 구현 | 프로필 카드, 스펙트럼 바 |
| **인사이트** | 심리학적 근거, 윤리 검토 | 유형별 한국 직장문화 조언 | 성장 방향, 학습 스타일 | Insights 모듈 구현 | 인사이트 카드 UI |
| **신뢰/컴플라이언스** | 윤리 검토, "진단 아님" 문구 | 상표 미사용 검증 | 공공 영역 범위 확인 | Compliance 모듈 구현 | 신뢰 고지 UI, 동의 폼 |

#### 콘텐츠 갭 (최대 병목)

| 영역 | 현황 | 필요 작업 | 담당 에이전트 |
|------|------|---------|-------------|
| 문항 | 20문항(4도메인 × 5) | 학술 근거 있는 문항 확대 | 심리학+MBTI+애니어그램 |
| 유형 해석 | seeds.rb에 기본 텍스트 존재 | 학술 검증 + 독자 표현 개선 | 심리학+MBTI+애니어그램 |
| 인사이트 | 5개 모듈 코드 존재 | 심리학적 타당성 검증 | 심리학 |
| 테스트 | 19서비스 중 12개 미테스트 | RSpec 작성 | 코딩 |
| UI 고도화 | 기본 뷰 완성 | 모바일 최적화, 애니메이션 | UI/UX |

#### 협업 시나리오

**순차 워크플로우 (기능 개발 시)**:
```
Phase 1: 이론 설계 (심리학)
  → 출력: 문항 설계 원칙, 점수 체계, 윤리 가이드

Phase 2: 콘텐츠 작성 (MBTI + 애니어그램 병렬)
  → 입력: Phase 1 가이드라인
  → 출력: 문항/콘텐츠, 법적 경계 준수 확인

Phase 3: 구현 (코딩 + UI/UX 병렬)
  → 입력: Phase 2 콘텐츠
  → 출력: 코드/테스트 + 뷰/CSS

Phase 4: 검증 (심리학)
  → 최종 산출물의 윤리/정확성 리뷰
```

**갈등 해소 우선순위**:
1. 법적 경계 원칙 위반 → **무조건 수정** (최우선)
2. 윤리 원칙 위반 (낙인 금지, 결정론 금지) → **반드시 수정**
3. 위 두 가지 미위반 시 → **대중 접근성 우선** + "참고용 인사이트, 진단 아님" 고지

#### 프로젝트 컨텍스트 체크리스트

**모든 에이전트 공통** (프롬프트 Project Context에 포함):
- [ ] 프로젝트 철학: 자기 이해, 타인 수용, 자유 추구
- [ ] 법적 경계: 공식 MBTI/애니어그램 검사 문항·브랜드 표현 미사용
- [ ] 제품 포지셔닝: 임상 진단이 아닌 자기이해 인사이트 서비스
- [ ] 콘텐츠 톤: 낙인 금지, 결정론 금지, 행동 지향

**자문 에이전트 추가**:
- [ ] MVP 6개 구성요소 이해
- [ ] 저작권 조사 결론 (MBTI 상표/문항 보호, 애니어그램 공공 도메인)
- [ ] 현재 콘텐츠 현황 (20문항, 16유형 기본 텍스트)

**구현 에이전트 추가**:
- [ ] 기술 스택: Rails 7+, PostgreSQL, RSpec, Hotwire/Turbo, Tailwind CSS
- [ ] 주요 파일 경로: app/services/(scoring|insights|profiles), app/views/results/, spec/
- [ ] DB 스키마: 14테이블, 데이터 흐름

### 요약

기술 인프라는 구현 완료, 콘텐츠 갭이 최대 병목. 자문 에이전트 3인이 콘텐츠 갭을 채우고, 구현 에이전트 2인이 테스트/UI를 고도화하는 구조.

---

## 관점 5: 에이전트별 기억 체계 설계 (2026-03-13 추가)

### 현황 분석

기존 연구(관점 1)에서 `memory: 미설정`으로 결론내렸으나, 에이전트가 반복 호출될수록 "이전에 어떤 발견/결정을 했는지" 컨텍스트 없이 시작하는 문제가 발생. kampi 프로젝트(`/Users/kampikrein/A/kampi/`)에서 검증된 2계층 기억 구조를 분석하여 에이전트용으로 적응한다.

### 상세 발견사항

#### kampi 기억 체계 분석

kampi는 "Kampi"라는 페르소나의 관계 기억을 관리하는 시스템으로, 다음 구조를 사용한다:

| 구성요소 | 파일 | 역할 |
|---------|------|------|
| **페르소나 + 인덱스** | `persona/kampi.yaml` → `memory.index` | 매 세션 CLAUDE.md에서 `@` 참조로 자동 로드. 기억 id/date/keywords/summary만 포함 |
| **개별 기억** | `persona/memories/NNN_키워드.yaml` | 필요할 때만 선택적 로드. summary/emotion/keywords(서두) + user_words/conversation/kampi_note(본문) |
| **저장 트리거** | `/kampi save` (실시간) + `/kampi digest` (사후 발굴) | 반자동: 후보 제안 → 사용자 승인 |

**핵심 설계 원리**:
1. **2계층 분리**: 인덱스(항상 스캔, 경량) + 본문(필요시 로드, 상세) → 컨텍스트 효율적
2. **선택적 로딩**: 인덱스의 keywords로 현재 대화와 관련 있는 기억만 선택적으로 읽기
3. **진화하는 표준**: 기억 포맷이 사용하면서 자연스럽게 표준화됨 (001 자유형식 → 002+ 구조화)
4. **출처 추적**: digest 기반 기억에 `source` 필드로 원본 추적 가능

#### personality 에이전트 적응 설계

**kampi와의 핵심 차이**:

| 항목 | kampi | personality 에이전트 |
|------|-------|---------------------|
| 주체 | 메인 세션 (사용자와 직접 대화) | 서브에이전트 (부모 세션이 호출) |
| 기억 유형 | 관계적/감정적 (교감 순간) | 전문적/도메인 (발견, 결정, 패턴) |
| 저장 트리거 | 사용자 승인 (`/kampi save`) | 에이전트가 작업 완료 시 자동 |
| 인덱스 로딩 | CLAUDE.md에서 `@persona/kampi.yaml` | 에이전트 프롬프트에 읽기 지시 포함 |
| 기억 포맷 | YAML (감정/키워드/대화 중심) | YAML (발견/결정/근거 중심) |

**디렉토리 구조**:

```
.claude/agent-memory/
├── psychology-expert/
│   ├── _index.yaml          ← 에이전트 시작 시 반드시 읽기
│   └── memories/
│       ├── 001_big5_문항검토.yaml
│       └── 002_측정학_신뢰도분석.yaml
├── mbti-expert/
│   ├── _index.yaml
│   └── memories/...
├── enneagram-expert/
│   ├── _index.yaml
│   └── memories/...
├── coding-expert/
│   ├── _index.yaml
│   └── memories/...
└── uiux-expert/
    ├── _index.yaml
    └── memories/...
```

**기억 인덱스 포맷** (`_index.yaml`):

```yaml
description: "{에이전트명} 전문 기억 인덱스"
storage_path: ".claude/agent-memory/{agent-name}/memories/"

index:
  - id: "001"
    date: "YYYY-MM-DD"
    type: finding | decision | pattern | review
    keywords: ["키워드1", "키워드2"]
    summary: "한 줄 요약"
    path: "memories/001_키워드.yaml"
```

**개별 기억 포맷** (`memories/NNN_키워드.yaml`):

```yaml
id: "NNN"
date: "YYYY-MM-DD"
type: finding | decision | pattern | review
keywords: [...]
summary: "한 줄 요약"

context: |
  발견/결정이 이루어진 맥락

details: |
  구체적 내용 (근거, 분석, 코드 경로 등)

implications: |
  이 발견이 향후 작업에 미치는 영향

related_memories: []
```

**기억 유형 분류**:

| type | 설명 | 예시 |
|------|------|------|
| `finding` | 조사/분석에서 발견한 사실 | "Big Five 문항 신뢰도 분석 결과" |
| `decision` | 설계/구현에서 내린 결정과 근거 | "점수 엔진에 IRT 대신 CTT 채택" |
| `pattern` | 코드베이스에서 발견한 반복 패턴 | "Rails 모델에서 concern 사용 패턴" |
| `review` | 기존 코드/문항/콘텐츠 검토 결과 | "현재 MBTI 문항 12개 중 3개 편향 의심" |

#### 에이전트 프롬프트에 포함할 기억 규칙

각 `.claude/agents/{agent-name}.md`에 Memory System 섹션을 추가:

```markdown
## Memory System

이 에이전트는 persistent memory를 사용한다.
기억 디렉토리: `.claude/agent-memory/{agent-name}/`

### 작업 시작 시
1. `.claude/agent-memory/{agent-name}/_index.yaml`을 읽어라
2. 현재 작업과 관련된 keywords가 있는 기억이 있으면 해당 파일을 추가로 읽어라
3. 이전 기억의 implications를 현재 작업의 컨텍스트로 활용하라

### 작업 완료 시
1. 이 작업에서 새로운 발견(finding), 결정(decision), 패턴(pattern), 검토 결과(review)가 있는가?
2. 있다면 `.claude/agent-memory/{agent-name}/memories/NNN_키워드.yaml`로 저장하라
3. `_index.yaml`을 업데이트하라
4. 기존 기억과 연결점이 있으면 related_memories에 기록하라

### 기억하지 않을 것
- 단순 코드 실행 결과 (git log로 추적 가능)
- 일회성 작업 디테일 (docs/ 보고서에 기록됨)
- 이미 기억에 있는 내용의 중복
```

#### 시스템 설정 업데이트

관점 1의 설정 테이블을 업데이트하여 memory 관련 변경 반영:

| 설정 항목 | 자문 에이전트 (심리학/MBTI/애니어그램) | 코딩 전문가 | UI/UX 전문가 |
|----------|-------------------------------------|-----------|-------------|
| **tools** | Read, Glob, Grep, Edit, Write | Read, Write, Edit, Bash, Glob, Grep | Read, Write, Edit, Bash, Glob, Grep |
| **model** | sonnet | sonnet | sonnet |
| **permissionMode** | acceptEdits | acceptEdits | acceptEdits |
| **maxTurns** | 15 | 25 | 20 |
| **skills** | 없음 | 없음 | ui-ux-pro-max |
| **기억 디렉토리** | `.claude/agent-memory/{name}/` | `.claude/agent-memory/coding-expert/` | `.claude/agent-memory/uiux-expert/` |

> 참고: `memory` frontmatter 필드는 공식 동작이 불투명하므로 사용하지 않음. 대신 프롬프트에 기억 읽기/쓰기 규칙을 직접 포함하여 동작을 보장.

### 주의사항 및 위험

- **에이전트 지시 준수율**: 서브에이전트가 "기억 저장" 지시를 항상 따르는지 실사용 후 검증 필요. 특히 작업이 복잡해지면 기억 저장을 건너뛸 가능성.
- **기억 충돌**: 심리학 에이전트와 MBTI 에이전트가 같은 주제(예: "문항 편향")에 대해 상반된 기억을 저장할 수 있음. → 각 에이전트의 기억은 독립적이며, 교차 검증은 부모 세션이 담당.
- **기억 비대화**: 기억이 50개+ 쌓이면 인덱스 자체가 커져 컨텍스트 소모 → kampi처럼 인덱스는 summary 1줄로 제한하여 방지.
- **초기 빈 기억**: 처음에는 기억이 없어 에이전트가 빈 인덱스를 읽게 됨 → 정상 동작. "기억 없음, 새로 시작" 상태를 프롬프트에서 안내.

### 요약

kampi의 2계층 기억 구조(인덱스 + 개별 기억)를 에이전트용으로 적응. 기억 유형을 finding/decision/pattern/review로 분류하고, 프롬프트에 읽기/쓰기 규칙을 직접 포함하여 동작을 보장. `memory` frontmatter 대신 프롬프트 지시 방식 채택.

---

## Cross-Analysis

### 관점 간 관계

1. **관점 1(시스템) + 관점 2(페르소나)**: frontmatter 설정과 body 프롬프트가 `.claude/agents/*.md` 파일의 두 부분으로 정확히 매핑됨. 시스템 설정이 프롬프트의 효과를 뒷받침(적절한 도구 없으면 행동 규칙 실행 불가).

2. **관점 2(페르소나) + 관점 3(도메인)**: 안티패턴 3번("도메인 지식 과다 주입")과 관점 3의 방대한 지식 체계가 긴장 관계. 해결: 프롬프트에는 HOW(사고 방식)만, WHAT(지식)은 docs/ 참조.

3. **관점 3(도메인) + 관점 4(프로젝트)**: 5축 차별화 매트릭스와 MVP 매핑이 결합되어 "누가 어떤 관점에서 무엇을 하는가"가 명확해짐.

4. **관점 4(프로젝트) + 관점 1(시스템)**: 자문 에이전트의 쓰기 권한 필요성은 관점 4의 "콘텐츠 갭" 발견과 관점 1의 "도구 설정"이 결합되어 도출.

5. **관점 5(기억) + 관점 1(시스템)**: 기존 "memory 미설정" 결론을 수정. `memory` frontmatter는 여전히 미사용하되, 프롬프트에 기억 읽기/쓰기 규칙을 포함하는 방식으로 persistent context를 구현. kampi의 검증된 구조를 차용.

6. **관점 5(기억) + 관점 4(프로젝트)**: 에이전트가 콘텐츠 갭을 채우면서 발견한 사항(문항 편향, 유형 해석 개선점 등)이 기억으로 축적되어, 다음 호출 시 반복 조사 없이 이어서 작업 가능.

### 공통 패턴

- **"행동 규칙 > 역할 선언"**: 5개 관점 모두에서 일관되게 지지
- **"법적 경계는 공통 레드라인"**: 모든 에이전트의 프롬프트에 필수 포함
- **"2계층 분리 원칙"**: 도메인 지식(프롬프트 HOW vs docs/ WHAT)과 기억 체계(인덱스 vs 개별 기억) 모두 동일한 패턴 적용
- **"점진적 복잡도"**: kampi 기억도 001→006으로 자연 진화. personality 에이전트 기억도 빈 상태에서 시작하여 자연 축적

### 상충 항목

- **에이전트 간 직접 통신**: 관점 4의 협업 시나리오는 에이전트 간 소통을 전제하나, 관점 1에서 확인한 시스템 제약(서브에이전트 간 직접 통신 불가)과 충돌. → **해결: 부모 세션이 중재, docs/ 문서를 통한 비동기 협업**

- **기존 R-007-F4와 관점 5의 긴장**: 기존 결론은 "memory보다 docs/ 시스템이 우월"이었으나, 관점 5는 에이전트별 persistent memory를 도입. → **해결: 둘은 보완 관계. docs/는 공식 보고서·연구 결과 보관용, agent-memory/는 에이전트의 작업 맥락·발견 축적용. 용도가 다름.**

---

## Comprehensive Conclusion

### 핵심 발견 (우선순위 순)

1. **[Critical] R-007-F1: 구체적 행동 규칙이 성능의 핵심** — 단순 역할 선언이 아닌 "검증 가능한 행동 규칙 + 판단 프레임워크 + 레드라인"의 3요소가 에이전트 성능을 결정. PromptHub 연구와 Anthropic 공식 가이드가 일관 지지. *(관점 2, 1)*

2. **[Critical] R-007-F2: 콘텐츠 갭이 최대 병목** — 기술 인프라(14모델, 19서비스)는 구현되어 있으나 학술 근거 있는 문항·유형 해석·인사이트가 부족. 자문 에이전트 3인의 즉시 기여 가능 영역. *(관점 4, 3)*

3. **[High] R-007-F3: 자문 에이전트도 쓰기 권한 필요** — 문항/점수/보고서 문구를 코드에 직접 반영해야 하므로 Read/Write/Edit/Glob/Grep (Bash 제외) 필요. *(관점 1, 4)*

4. **[High] R-007-F4: 도메인 지식과 기억은 프롬프트 외부 배치** — 프롬프트에는 HOW(사고 방식)만 포함, WHAT(지식)은 docs/ 참조 파일로, 작업 맥락은 `.claude/agent-memory/`로 분리. 2계층 구조(인덱스+본문)로 컨텍스트 효율성 확보. *(관점 2, 3, 5)*

5. **[High] R-007-F5: 5축 차별화 구조** — 학술근거/문화적합/성장가능/구현실용/사용자경험 5개 축에서 각각 다른 판단을 내리는 구조가 멀티에이전트의 핵심 가치. *(관점 3, 4)*

6. **[Medium] R-007-F6: 7섹션 프롬프트 구조** — Role → Project Context → Core Principles → Analysis Framework → Communication Style → Boundaries & Red Lines → Collaboration Rules. *(관점 2)*

7. **[Medium] R-007-F7: 프롬프트 안티패턴 6가지** — 선언만/규칙과잉/지식과다/역할겹침/맥락누락/겸손함부재. 작성 후 체크리스트로 점검 필요. *(관점 2)*

8. **[Medium] R-007-F8: 에이전트 간 협업은 부모 세션 중재** — 시스템 제약상 서브에이전트 간 직접 통신 불가. docs/ 문서 기반 비동기 협업이 현실적. *(관점 1, 4)*

9. **[High] R-007-F9: 에이전트별 persistent memory 도입** — kampi 프로젝트에서 검증된 2계층 기억 구조(인덱스 + 개별 기억)를 에이전트용으로 적응. `.claude/agent-memory/{agent-name}/` 디렉토리에 `_index.yaml`(항상 스캔) + `memories/NNN_키워드.yaml`(선택적 로드) 구조. `memory` frontmatter 대신 프롬프트에 기억 읽기/쓰기 규칙을 직접 포함하여 동작 보장. *(관점 5)*

10. **[Medium] R-007-F10: 기억 유형 4분류** — finding(발견)/decision(결정)/pattern(패턴)/review(검토)로 분류하여 에이전트의 전문적 맥락 축적을 체계화. kampi의 감정 중심 기억과 달리 근거/맥락/영향 중심의 포맷. *(관점 5)*

## Unresolved Items

1. **isolation(worktree) 설정의 실효성**: 코딩/UI/UX 에이전트 동시 실행 시 파일 충돌 가능성이 있으나, 실제 발생 빈도와 worktree 격리의 효과는 실사용 후에야 판단 가능. (실험 필요)

2. **도메인 지식 참조 파일의 최적 형태**: docs/ 하위에 Markdown으로 두는 것과 .claude/skills/ 하위에 두는 것 중 어떤 방식이 에이전트의 참조 효율성이 높은지 미검증. (실험 필요)

3. **에이전트 프롬프트 버전 관리 전략**: 프롬프트 변경 시 이력 관리 방법 (git commit으로 충분한지, 별도 변경 로그가 필요한지) 미확정.

4. **기억 저장 지시 준수율**: 서브에이전트가 프롬프트의 "작업 완료 시 기억 저장" 지시를 얼마나 일관되게 따르는지 실사용 후 검증 필요. (실험 필요)

5. **기억 비대화 관리**: 기억이 50개+ 쌓였을 때 인덱스 스캔의 컨텍스트 비용과 정리(pruning) 전략 미확정. kampi는 현재 6개로 아직 문제 미발생. (규모 확장 시 필요)

## Referenced File List

| File Path | 관련 관점 | 역할/내용 |
|-----------|----------|----------|
| `docs/05_agent_design/001_Research_전문에이전트_구성.md` | 전체 | 체크포인트 문서 |
| `docs/05_agent_design/002_Agent_시스템최적화.md` | 관점 1 | 시스템 설정 연구 |
| `docs/05_agent_design/003_Agent_페르소나설계.md` | 관점 2 | 페르소나 프롬프트 연구 |
| `docs/05_agent_design/004_Agent_도메인지식.md` | 관점 3 | 도메인 지식 체계 연구 |
| `docs/05_agent_design/005_Agent_프로젝트정합성.md` | 관점 4 | 프로젝트 정합성 연구 |
| `docs/05_agent_design/006_Synthesis_전문에이전트구성.md` | 전체 | 종합 보고서 |
| `docs/01_성격서비스_기획/004_Memo_프로젝트_철학.md` | 관점 4 | 프로젝트 철학 |
| `docs/01_성격서비스_기획/005_Plan_법률우선_MVP_설계.md` | 관점 4 | MVP 설계 |
| `app/services/scoring/` | 관점 1, 4 | 점수 엔진 서비스 |
| `app/services/insights/` | 관점 1, 4 | 인사이트 모듈 서비스 |
| `app/services/profiles/` | 관점 1, 4 | 프로필 컴포저 서비스 |
| `app/views/results/` | 관점 1, 4 | 결과 페이지 뷰 |
| `db/migrate/` | 관점 4 | 14테이블 마이그레이션 |
| `.claude/agents/` (생성 예정) | 관점 1, 2 | 에이전트 정의 파일 |
| `docs/05_agent_design/008_Scope_에이전트_기억체계.md` | 관점 5 | 기억 체계 scope 문서 |
| `/Users/kampikrein/A/kampi/persona/kampi.yaml` | 관점 5 | kampi 페르소나 + 기억 인덱스 |
| `/Users/kampikrein/A/kampi/persona/memories/*.yaml` | 관점 5 | kampi 개별 기억 파일 (6개) |
| `/Users/kampikrein/A/kampi/docs/01_memory_system/001_Research_memory_pipeline_design.md` | 관점 5 | kampi 기억 파이프라인 연구 |
| `/Users/kampikrein/A/kampi/docs/01_memory_system/002_Plan_memory_pipeline_implementation.md` | 관점 5 | kampi 기억 파이프라인 구현 계획 |
| `/Users/kampikrein/A/kampi/CLAUDE.md` | 관점 5 | kampi 프로젝트 정의 (`@persona/kampi.yaml` 참조) |
