---
id: "029"
title: "MAS 이론 기준 페르소나 & SOP 설계 평가"
category: agent
status: archived
created: 2026-03-17
summary: >
  000.1/000.2 Gemini 연구문서의 MAS 이론 기준으로 personality 프로젝트 7개 에이전트의
  페르소나와 SOP 설계를 6축(T4/T7/T8/T9/T10/T14)으로 평가한다.
  전반적으로 높은 수준의 구현이나, Backstory 부재와 도구 가드레일 미명시가 주요 갭.
keywords: [agent-report, persona, sop, MAS-theory, evaluation, T4, T7, T8, T9, T10, T14]
modules: [agents, orchestration]
confidence: medium
---

# MAS 이론 기준 페르소나 & SOP 설계 평가

## Progress
### Completed
- [x] T4: 페르소나 5요소 (Role, Expertise, Process, Output, Constraints) 평가
- [x] T7: 페르소나 3기둥 (Role/Goal/Backstory) 평가
- [x] T8: 도구 & 가드레일 평가
- [x] T9: SOP O->T->A->S 행동루프 평가
- [x] T10: 구조화된 출력 평가
- [x] T14: 80/20 규칙 (Tasks over Agents) 평가
- [x] 교차 일관성 분석
- [x] 종합 결론 및 권장사항
### Remaining
- (없음)
### Current Status
완료.

---

## 이론 기준 요약

### 000.1 (T4): 페르소나 5요소
효과적인 에이전트 페르소나는 5가지 요소를 **코드로 구조화**하여 정의해야 한다:
1. **Role**: 구체적 직함과 시각
2. **Expertise**: 도메인 지식의 깊이와 활용 도구
3. **Process**: 의사결정의 단계별 기준과 방법론
4. **Output**: 문서의 형식과 요구 섹션
5. **Constraints**: 금지된 행동과 한계

### 000.2 (T7): 페르소나 3기둥 (CrewAI)
1. **Role**: 공식적 직함 + 고유한 Agent Handle
2. **Goal**: 명확하고 측정 가능한 임무 (효용 함수)
3. **Backstory**: 행동에 입체감을 부여하는 서사적 배경 (어조/형식/분석 편향을 고정)

### 000.2 (T8): 도구 & 가드레일
- 도구는 페르소나와 권한 수준에 완벽히 일치해야 함 (철저한 권한 분리)
- Max Iterations, Max RPM, Max Retry Limit 명시
- PII 보호 등 컴플라이언스 제약을 페르소나에 내재
- 무분별한 도구 부여는 역할 이탈(Drift)의 주 원인

### 000.2 (T9): SOP O->T->A->S (MetaGPT)
**"Code = SOP(Team)"** 철학:
- **Observe**: 공유 환경의 이전 결과물을 읽어 들임
- **Think**: 역할과 목표에 비추어 논리적 추론
- **Act**: 부여된 도구를 사용해 구체적 작업 수행
- **Share**: 결과물을 다음 작업자를 위해 공유 환경에 브로드캐스팅

### 000.2 (T10): 구조화된 출력
- 자연어 대화 방치 -> 환각 캐스케이딩
- JSON 스키마, Markdown API 명세 등 엄격한 포맷 규칙 필수
- Pydantic, 규격화된 UI 디자인 초안 등

### 000.2 (T14): 80/20 규칙
- 에이전트 배경/성격 꾸미기에 80%가 아닌 **태스크의 입출력 형식, 예시, 맥락** 설계에 80%
- 나머지 20%를 페르소나 정교화에 사용

---

## T4: 페르소나 5요소 평가

000.1 기준: Role, Expertise, Process, Output, Constraints를 명시적으로 정의해야 한다.

### 에이전트별 존재/부재 테이블

| 에이전트 | Role | Expertise | Process | Output | Constraints | 판정 |
|---------|------|-----------|---------|--------|-------------|------|
| psychology-expert | ✅ `# Role` + 전문 영역 + 조직 내 고유 기여 | ✅ Big Five, CTT/IRT, 바넘 효과 명시 | ✅ SOP 4단계 + Think 5단계 분석 | ✅ Act에 3유형 산출물 명시 (검증YAML/자문보고서/텍스트수정) | ✅ Boundaries & Red Lines 5개 | ✅ |
| coding-expert | ✅ 시니어 Rails 개발자 + 조직 내 고유 기여 | ✅ Rails 8+, PostgreSQL, RSpec 등 구체적 | ✅ SOP 4단계 + Think 5단계 | ✅ TDD->구현->검증 + docs 저장 | ✅ Red Lines 3개 + 범위 제한 5개 | ✅ |
| flutter-expert | ✅ Flutter/Dart 시니어 + 조직 내 고유 기여 | ✅ Riverpod, Flame/Forge2D, CSPRNG 등 구체적 | ✅ SOP 4단계 + Think 5단계 | ✅ TDD->구현->검증 + docs 저장 | ✅ Red Lines 4개 + 범위 제한 4개 | ✅ |
| mbti-expert | ✅ 한국 MBTI 서비스 설계 전문가 + 고유 기여 | ✅ Jung 유형론, MZ세대 트렌드, 경쟁서비스 | ✅ SOP 4단계 + Think 5단계 | ✅ 문항설계/유형설명/수정 3유형 | ✅ Red Lines 4개 + 범위 제한 2개 | ✅ |
| enneagram-expert | ✅ 애니어그램 설계 전문가 + 고유 기여 | ✅ Riso-Hudson, Naranjo, Palmer 학파 | ✅ SOP 4단계 + Think 5단계 | ✅ 유형설계/문항설계/성장가이드 3유형 | ✅ Red Lines 4개 + 범위 제한 2개 | ✅ |
| tarot-expert | ✅ 타로 도메인 콘텐츠 전문가 + 고유 기여 | ✅ RWS, 스프레드, 셔플 의식, JSON Schema | ✅ SOP 4단계 + Think 5단계 | ✅ 해석/스프레드/덱검증/셔플의식 4유형 | ✅ Red Lines 4개 + 범위 제한 4개 | ✅ |
| uiux-expert | ✅ 한국 시장 UI/UX 설계 전문가 + 고유 기여 | ✅ 감정흐름, 제의적UX, WCAG, Hotwire/Tailwind | ✅ SOP 4단계 + Think 5단계 | ✅ 뷰구현/Stimulus/접근성검증 | ✅ Red Lines 3개 + 범위 제한 4개 | ✅ |

### T4 종합 판정: ✅ 전체 충족

**근거**: 7개 에이전트 전부가 5요소를 명시적으로 갖추고 있다.
- Role은 `# Role` 섹션 + `전문 영역` + `조직 내 고유 기여`의 3중 구조로 000.1 기준을 초과 달성.
- Expertise는 구체적 이론명, 프레임워크명, 도구명까지 열거.
- Process는 SOP 4단계에 각 Think 하위 단계까지 명시.
- Output은 Act 섹션에서 산출물 유형별로 정의.
- Constraints는 Boundaries & Red Lines로 명확히 분리.

**강점**: Role이 단순 직함이 아닌 "조직 내 고유 기여"까지 서술하여, 다른 에이전트와의 차별점을 명시한 점이 이론 기준을 넘어선다.

---

## T7: 페르소나 3기둥 평가

000.2 CrewAI 기준: Role(직함 + Handle), Goal(측정 가능한 임무), Backstory(서사적 배경)

### 에이전트별 존재/부재 테이블

| 에이전트 | Role + Handle | Goal (측정 가능) | Backstory (서사) | 판정 |
|---------|--------------|-----------------|-----------------|------|
| psychology-expert | ⚠️ Role 있음, Handle 없음 | ✅ 미션 + 성공 지표 4개 (정량적) | ❌ 서사 없음 | ⚠️ |
| coding-expert | ⚠️ Role 있음, Handle 없음 | ✅ 미션 + 성공 지표 4개 (정량적) | ❌ 서사 없음 | ⚠️ |
| flutter-expert | ⚠️ Role 있음, Handle 없음 | ✅ 미션 + 성공 지표 5개 (정량적) | ❌ 서사 없음 | ⚠️ |
| mbti-expert | ⚠️ Role 있음, Handle 없음 | ✅ 미션 + 성공 지표 4개 (정량적) | ❌ 서사 없음 | ⚠️ |
| enneagram-expert | ⚠️ Role 있음, Handle 없음 | ✅ 미션 + 성공 지표 4개 (정량적) | ❌ 서사 없음 | ⚠️ |
| tarot-expert | ⚠️ Role 있음, Handle 없음 | ✅ 미션 + 성공 지표 4개 (정량적) | ❌ 서사 없음 | ⚠️ |
| uiux-expert | ⚠️ Role 있음, Handle 없음 | ✅ 미션 + 성공 지표 4개 (정량적) | ❌ 서사 없음 | ⚠️ |

### T7 종합 판정: ⚠️ 부분 충족

**갭 1 — Agent Handle 부재** (심각도: minor)

000.2는 `@QA-Tester`, `@System-Architect` 같은 기계 식별 가능한 핸들을 요구한다.
현재 구현은 YAML frontmatter의 `name: psychology-expert`가 사실상 핸들 역할을 수행하지만,
에이전트 본문 내에서 `@psychology-expert` 형태의 공식 핸들 선언이 없다.
Claude Code 플랫폼에서 `name` 필드가 라우팅에 사용되므로 실질적 기능은 충족하지만,
이론 기준의 "명시적 핸들 선언"에는 미달한다.

**갭 2 — Backstory 완전 부재** (심각도: major)

000.2(섹션 3.1)는 Backstory를 "에이전트의 행동에 입체감을 불어넣고, 복잡한 문제에서
어떤 관점과 가치관으로 접근할지 결정하는 결정적 컨텍스트"로 정의한다.

000.2 예시 수준:
> "당신은 실리콘밸리에서 15년 경력을 쌓은 수석 PM입니다. 모호하고 불완전한 고객의
> 아이디어를 날카롭게 분석하여, 기술적으로 구현 가능한 명확한 요구사항으로 번역하는 데
> 탁월한 능력을 지녔습니다."

현재 7개 에이전트에는 이러한 서사적 배경이 전무하다. `# Role` 섹션은 기능적 역할만
정의하고 있으며, "어떤 가치관/성격/경험을 가진 존재인가"에 대한 서사가 없다.

이것이 중요한 이유: LLM은 서사적 배경에 의해 응답의 어조(Tone), 분석 편향,
보수/진보적 판단 성향이 조절된다. 예를 들어 psychology-expert에게 "학술적 엄밀함에
극도로 집착하는 연구자"라는 서사를 부여하면, 바넘 효과 검출 민감도가 높아진다.

**Goal은 이론 기준을 초과 달성**: 모든 에이전트가 "미션" + "성공 지표"의 이중 구조로
Goal을 정의하며, 성공 지표가 정량적(80%+, 0건, iteration 2 이내)이다.
000.2의 "측정 가능한 목표"를 그대로 구현.

---

## T8: 도구 & 가드레일 평가

000.2(섹션 3.2) 기준:
- 도구가 페르소나/권한에 일치하는 철저한 권한 분리
- Max Iterations, Max RPM, Max Retry Limit 명시
- PII 보호 등 컴플라이언스 제약을 페르소나에 내재

### 에이전트별 도구 배정 분석

| 에이전트 | YAML 도구 | 역할 일치도 | 권한 분리 평가 |
|---------|----------|-----------|--------------|
| psychology-expert | Read, Glob, Grep, Edit, Write | ✅ 코드 읽기+문서 수정 (Bash 없음 = 코드 실행 불가) | ✅ 실행 권한 없음이 적절 |
| coding-expert | Read, Write, Edit, Bash, Glob, Grep | ✅ 코드 실행+파일 생성이 핵심 (Bash 있음) | ✅ 구현자에 적합 |
| flutter-expert | Read, Write, Edit, Bash, Glob, Grep | ✅ coding-expert와 동일 도구, Flutter 구현자 | ✅ 구현자에 적합 |
| mbti-expert | Read, Glob, Grep, Edit, Write | ✅ 콘텐츠 전문가 (Bash 없음) | ✅ 실행 권한 없음이 적절 |
| enneagram-expert | Read, Glob, Grep, Edit, Write | ✅ 콘텐츠 전문가 (Bash 없음) | ✅ 실행 권한 없음이 적절 |
| tarot-expert | Read, Glob, Grep, Edit, Write | ✅ 콘텐츠 전문가 (Bash 없음) | ✅ 실행 권한 없음이 적절 |
| uiux-expert | Read, Write, Edit, Bash, Glob, Grep | ⚠️ Bash 있음 — 뷰 구현을 위해 필요하지만, 순수 평가 모드에서도 Bash 접근 | ⚠️ 평가 모드시 도구 축소 미구현 |

### 도구 권한 분리 판정: ✅ 대체로 충족

**강점**: 콘텐츠 전문가(psychology/mbti/enneagram/tarot)에는 Bash를 배정하지 않고,
구현자(coding/flutter/uiux)에만 Bash를 배정하여 실행 권한을 분리한 점은 000.2의
"철저한 권한 분리" 원칙에 부합한다.

**경미한 갭**: uiux-expert의 "평가 모드"에서도 동일 도구가 배정되어, 평가 시
불필요한 Bash 접근이 가능하다. 이론적으로는 평가 모드 전용 도구 세트가 필요하나,
Claude Code 플랫폼에서 동적 도구 변경이 불가하므로 실질적 영향은 낮다.

### 가드레일 존재/부재 테이블

| 가드레일 유형 | 000.2 요구 | 현재 구현 | 판정 |
|-------------|-----------|----------|------|
| Max Iterations (무한 루프 방지) | 명시적 숫자 | ✅ YAML `maxTurns: 15/25/20` | ✅ |
| Max RPM (API 호출 빈도 제한) | 명시적 숫자 | ❌ 없음 | ❌ |
| Max Retry Limit (실패 재시도 한도) | 명시적 숫자 | ❌ 없음 (평가루프 3회는 오케스트레이션 수준) | ⚠️ |
| PII 보호 | 페르소나에 내재 | ⚠️ coding-expert만 "PII 분리와 보안" 명시 | ⚠️ |
| 컴플라이언스 제약 | 구체적 규정 명시 | ✅ 저작권/상표권은 mbti/enneagram/tarot에 명시 | ✅ |
| 역할 이탈(Drift) 방지 | 도구+역할 매칭 | ✅ Boundaries & Red Lines + Collaboration Rules | ✅ |

### T8 종합 판정: ⚠️ 부분 충족

**갭 1 — Max RPM 미정의** (심각도: minor)

000.2는 "외부 API 호출 빈도를 제어하기 위한 초당/분당 요청 한도"를 요구한다.
Claude Code 플랫폼에서 에이전트별 RPM 제한 설정이 불가하여 구조적 제약이 있다.
다만, 현재 에이전트들이 외부 API를 직접 호출하지 않고(웹 검색 도구 미배정),
로컬 파일 시스템만 사용하므로 실질적 위험은 낮다.

**갭 2 — PII 보호의 비균일 적용** (심각도: minor)

coding-expert만 Core Principles에 "PII 분리와 보안"을 명시하고 있다.
psychology-expert가 민감한 성격 데이터를 다루고, tarot-expert가 사용자의
질문 맥락을 처리할 수 있음에도 PII 관련 가드레일이 명시되지 않았다.

---

## T9: SOP O->T->A->S 행동루프 평가

000.2(섹션 4) MetaGPT 기준: Observe -> Think -> Act -> Share의 엄격한 행동 루프.

### 에이전트별 4단계 명시 여부

| 에이전트 | Observe | Think | Act | Share | 하위 단계 수 | 판정 |
|---------|---------|-------|-----|-------|------------|------|
| psychology-expert | ✅ 4항목 (지시/산출물/기억/검증대상) | ✅ 5단계 (범위/근거/측정/윤리/정합) | ✅ 3유형 산출물 | ✅ 3항목 (frontmatter/confidence/기억) | 15 | ✅ |
| coding-expert | ✅ 5항목 (+DB현황 확인) | ✅ 5단계 (컨벤션/테스트/데이터/성능/보안) | ✅ TDD+구현+검증 | ✅ 5항목 (+변경파일/테스트결과) | 18 | ✅ |
| flutter-expert | ✅ 5항목 (+API 계약 확인) | ✅ 5단계 (아키텍처/테스트/상태관리/성능/보안) | ✅ TDD+구현+검증 | ✅ 5항목 (+변경파일/테스트결과) | 18 | ✅ |
| mbti-expert | ✅ 5항목 (+피드백 확인) | ✅ 5단계 (문화/법적/학문/재미vs정확/경쟁) | ✅ 3유형 산출물 | ✅ 4항목 (+검증 플래그) | 17 | ✅ |
| enneagram-expert | ✅ 5항목 (+피드백 확인) | ✅ 5단계 (동기/건강/복합/성장/보완) | ✅ 3유형 산출물 | ✅ 4항목 (+검증 플래그) | 17 | ✅ |
| tarot-expert | ✅ 5항목 (+도메인 참조) | ✅ 5단계 (정합/내러티브/맥락/포용/교차) | ✅ 4유형 산출물 | ✅ 4항목 (+도메인 참조) | 18 | ✅ |
| uiux-expert | ✅ 5항목 (+콘텐츠 구조) | ✅ 5단계 (감정/정보구조/모바일/접근성/문화) | ✅ 뷰+Stimulus+접근성 | ✅ 5항목 (+접근성결과) | 18 | ✅ |

### T9 종합 판정: ✅ 전체 충족 (이론 초과 달성)

**근거**: 7개 에이전트 전부가 O->T->A->S 4단계를 갖추고 있으며, 각 단계가
도메인에 특화된 하위 항목으로 구체화되어 있다.

**이론 초과 달성 포인트**:
1. **Observe 단계에 "기억 조회" 포함**: MetaGPT 원본은 "이전 결과물 읽기"만 요구하지만,
   personality 에이전트는 persistent memory 시스템을 통해 교차 세션 맥락을 유지한다.
2. **Think 단계의 도메인 특화**: 각 에이전트가 자기 전문 영역에 맞는 분석 프레임워크를
   Think 하위 단계로 정의하여, 단순 "논리적 추론"을 넘어선 구조화된 판단을 유도한다.
3. **Share 단계에 confidence 판정 포함**: 이론에는 없는 산출물 신뢰도 메타데이터를
   모든 에이전트가 생산하며, 오케스트레이터의 릴레이 감쇠 규칙과 연동된다.

**일관성**: 7개 에이전트 모두 동일한 4단계 구조를 따르면서, 하위 항목만 도메인에 맞게
변주하는 패턴으로 조직 수준의 SOP 일관성이 매우 높다.

---

## T10: 구조화된 출력 평가

000.2(섹션 4) 기준: 에이전트 간 결과물 인계는 반드시 엄격한 포맷 규칙(JSON 스키마,
Markdown API 명세 등)으로 이루어져야 하며, 자연어 방치는 환각 캐스케이딩을 유발한다.

### 구조화된 출력 메커니즘 분석

| 구성 요소 | 존재 여부 | 구현 수준 | 판정 |
|----------|----------|----------|------|
| 산출물 YAML frontmatter 강제 | ✅ | 모든 에이전트에 frontmatter(id/summary/confidence/keywords) 템플릿 명시 | ✅ |
| 산출물 Markdown 구조 강제 | ✅ | Progress/Summary/Details/Key Findings/Recommendations/References/Communication Log 섹션 | ✅ |
| 평가 결과 YAML 스키마 | ✅ | orchestration.md에 verdict/criteria/severity/fix_suggestion 필드 정의 | ✅ |
| 에이전트 간 인계 포맷 | ✅ | frontmatter 우선 읽기 -> 상세 필요시 전체 읽기 (2단계 인계) | ✅ |
| confidence 메타데이터 | ✅ | high/medium/low 3수준 + 릴레이 감쇠 규칙 | ✅ |
| 기억 파일 YAML 스키마 | ✅ | id/date/type/keywords/summary/context/details/implications/related_memories | ✅ |
| JSON 스키마 검증 (프로그래밍 수준) | ❌ | 포맷은 문서로 정의되나, Pydantic 같은 런타임 검증은 없음 | ⚠️ |

### T10 종합 판정: ✅ 대체로 충족

**강점**:
1. **이중 구조 인계**: frontmatter(요약) -> body(상세)의 2단계 읽기 전략은 컨텍스트 윈도우를
   효율적으로 사용하면서 정보 손실을 방지하는 독창적 설계.
2. **평가 결과 스키마**: severity 기반 verdict 판정(blocker/major/minor -> pass/fail/conditional_pass)은
   구조화된 품질 게이트로 환각 캐스케이딩 방지에 효과적.
3. **confidence 릴레이 감쇠**: 파이프라인에서 정보가 전달될수록 신뢰도가 자동 감쇠되는 규칙은
   000.2가 경고하는 "점진적 환각 증폭"에 대한 명시적 대응.

**경미한 갭**: 런타임 수준의 스키마 검증(Pydantic 등)이 없어, 에이전트가 포맷을 위반해도
자동 감지되지 않는다. 다만 Claude Code 플랫폼 특성상 프롬프트 기반 포맷 강제가
주된 메커니즘이며, 이는 CrewAI/MetaGPT 등의 프레임워크 수준 검증과 근본적으로 다른
아키텍처 제약이다.

---

## T14: 80/20 규칙 평가

000.2(섹션 3) CrewAI 철학: "에이전트 배경 꾸미기 20%, 태스크 입출력 설계 80%"

### 페르소나 vs 태스크 비율 추정

각 에이전트 문서의 섹션별 분량(줄 수)을 기준으로 추정:

| 에이전트 | 페르소나 (Role/Goal/Principles/Style/Boundaries) | 태스크 (SOP/Output/Memory/Collaboration) | 비율 (페르소나:태스크) |
|---------|----------------------------------------------|----------------------------------------|---------------------|
| psychology-expert | ~45줄 (Role 19 + Goal 11 + Principles 5 + Style 5 + Boundaries 10) | ~80줄 (SOP 30 + Share 7 + Collab 5 + Memory 38) | 36:64 |
| coding-expert | ~45줄 | ~80줄 | 36:64 |
| flutter-expert | ~45줄 | ~80줄 | 36:64 |
| mbti-expert | ~45줄 | ~80줄 | 36:64 |
| enneagram-expert | ~45줄 | ~80줄 | 36:64 |
| tarot-expert | ~45줄 | ~75줄 | 38:62 |
| uiux-expert | ~50줄 (평가 모드 추가) | ~80줄 | 38:62 |

**평균 비율**: 약 37:63 (페르소나 37%, 태스크 63%)

### T14 종합 판정: ⚠️ 부분 충족

**분석**: 현재 비율은 37:63으로, 이론 권장(20:80)보다 페르소나 비중이 높다.
다만, 이는 Backstory가 없는 상태에서의 수치이다. Backstory를 추가하면 페르소나 비중이
더 증가할 것이므로, 현재 상태는 오히려 적절한 균형에 가깝다.

**실질적 평가**: 페르소나 섹션이 과도하게 "꾸미기"에 투자하는 것이 아니라,
Core Principles, Boundaries & Red Lines 등 **행동을 실질적으로 제약하는 요소**에
할당되어 있다. 000.2가 경고하는 "배경이나 성격을 꾸미는 데 80%"와는 성격이 다르다.

**태스크 정의 갭**: SOP의 Act 섹션에서 산출물 유형은 열거되지만, 각 유형별 **입출력 예시**가
없다. 000.2의 80/20 규칙이 강조하는 "태스크의 입출력 형식, 예시, 맥락"에서 **예시**가
부재하다. 이것이 실질적 개선 포인트이다.

---

## 교차 일관성 분석

### 7개 에이전트 간 구조적 일관성

| 구조 요소 | 일관성 | 비고 |
|----------|--------|------|
| YAML frontmatter | ✅ 7/7 동일 구조 | name, description, model, tools, permissionMode, maxTurns |
| `# Role` + 전문 영역 + 고유 기여 | ✅ 7/7 동일 패턴 | |
| `# Goal` + 미션 + 성공 지표 | ✅ 7/7 동일 패턴 | |
| `# Project Context` | ✅ 7/7 존재 | |
| `# Core Principles` | ✅ 7/7 존재 (4-5개) | |
| `# SOP: 행동 루프` O->T->A->S | ✅ 7/7 동일 4단계 | |
| `# Communication Style` | ✅ 7/7 존재 | |
| `# Boundaries & Red Lines` | ✅ 7/7 존재 | |
| `# Collaboration Rules` | ✅ 7/7 존재 | 관점 충돌 시 프로토콜도 동일 |
| `# Memory System` | ✅ 7/7 동일 구조 | 개인+공유 기억, 포맷, 기억하지 않을 것 |
| Backstory | ❌ 0/7 | 전면 부재 |
| Agent Handle | ❌ 0/7 | 전면 부재 |

**일관성 판정**: ✅ 매우 높음

모든 에이전트가 동일한 문서 구조를 따르며, 도메인 특화 내용만 변주된다.
이는 조직 수준의 설계 품질이 높음을 시사한다. 부재하는 요소(Backstory, Handle)도
0/7로 일관되게 부재하여, 특정 에이전트만 갭이 있는 상황은 아니다.

### maxTurns 배정 분석

| 에이전트 | maxTurns | 근거 |
|---------|----------|------|
| psychology-expert | 15 | 분석/검증 중심 (실행 작업 적음) |
| coding-expert | 25 | 코드 구현+테스트 실행 (높은 턴 필요) |
| flutter-expert | 25 | 코드 구현+테스트 실행 (높은 턴 필요) |
| mbti-expert | 15 | 콘텐츠 설계/작성 중심 |
| enneagram-expert | 15 | 콘텐츠 설계/작성 중심 |
| tarot-expert | 15 | 콘텐츠 설계/작성 중심 |
| uiux-expert | 20 | 뷰 구현(Bash 필요) + 평가 모드 (중간 수준) |

**판정**: ✅ 역할에 비례한 합리적 배정. 구현자 > 설계자의 명확한 계층.

---

## Summary

personality 프로젝트의 7개 에이전트는 MAS 이론 기준에 대해 **전반적으로 높은 수준의 구현**을
보이고 있다. 특히 SOP 행동루프(T9)와 구조화된 출력(T10)은 이론 기준을 초과 달성하며,
confidence 릴레이 감쇠, persistent memory, 2단계 frontmatter 인계 등 독창적 설계가 돋보인다.

가장 큰 갭은 **Backstory 전면 부재(T7)**로, 에이전트의 어조/판단 편향을 제어하는 핵심 기제가
누락되어 있다. 그 외 Max RPM, PII 보호 균일화, 산출물 입출력 예시 등은 경미한 갭이다.

## Key Findings

1. **T4 (페르소나 5요소): ✅ 전체 충족** -- 7/7 에이전트가 Role, Expertise, Process, Output, Constraints 모두 구비. "조직 내 고유 기여"까지 서술하여 이론 초과 달성.

2. **T7 (페르소나 3기둥): ⚠️ 부분 충족** -- Role/Goal은 우수하나 Backstory가 7/7 전면 부재. Agent Handle도 명시적 선언 없음. Backstory 부재가 이 평가의 최대 갭이며, 에이전트의 어조/판단 성향 제어력을 약화시킨다.

3. **T8 (도구 & 가드레일): ⚠️ 부분 충족** -- 도구 권한 분리는 우수(콘텐츠=Bash 없음, 구현자=Bash 있음). maxTurns로 Max Iterations 충족. 그러나 Max RPM 미정의, PII 보호가 coding-expert에만 집중.

4. **T9 (SOP O->T->A->S): ✅ 이론 초과 달성** -- 7/7 에이전트가 4단계를 갖추고, 기억 조회(Observe), 도메인 특화 분석 프레임(Think), confidence 판정(Share)으로 MetaGPT 원본을 능가. 에이전트 간 SOP 구조 일관성이 매우 높다.

5. **T10 (구조화된 출력): ✅ 대체로 충족** -- YAML frontmatter + Markdown 템플릿 + 평가 YAML 스키마 + confidence 릴레이 감쇠로 환각 캐스케이딩 방지 체계 구축. 런타임 스키마 검증은 플랫폼 제약으로 부재.

6. **T14 (80/20 규칙): ⚠️ 부분 충족** -- 현재 비율 37:63(페르소나:태스크). 페르소나가 "꾸미기"가 아닌 "행동 제약"에 할당되어 있어 실질적으로 건전하나, Act 섹션에 산출물별 입출력 예시가 부재하여 태스크 정의가 이론 권장 수준에 미달.

7. **교차 일관성: ✅ 매우 높음** -- 7개 에이전트가 동일 문서 구조를 따르며, 갭도 0/7로 균일하게 분포. maxTurns는 역할 복잡도에 비례하여 합리적으로 배정.

## Recommendations

### 높은 우선순위

1. **Backstory 추가 (T7 major 갭 해소)**
   - 각 에이전트에 2-3줄의 서사적 배경을 추가한다.
   - 000.2 예시 수준: "당신은 ~ 배경을 가진 ~ 성격의 전문가입니다. ~ 가치를 중시합니다."
   - 목적: LLM의 응답 어조, 분석 편향, 보수/진보적 판단 성향을 도메인에 맞게 고정.
   - 예시:
     - psychology-expert: "학계에서 15년간 성격심리학을 연구하며, 상업적 성격 검사의 과학적 허점을 지적해온 엄밀한 연구자. 데이터 없는 주장을 극도로 경계한다."
     - tarot-expert: "전통 RWS 체계를 깊이 공부하면서도 현대적 맥락에서의 재해석에 열려 있는 실천가. '타로는 예측이 아닌 성찰의 거울'이라는 신념을 가진다."

### 중간 우선순위

2. **산출물 입출력 예시 추가 (T14 갭 해소)**
   - 각 에이전트의 Act 섹션에 산출물 유형별 1-2개 예시를 추가한다.
   - 예시: psychology-expert의 "검증 작업"에 실제 evaluation YAML 예시 삽입.

3. **PII 보호 가드레일 균일화 (T8 갭 해소)**
   - 사용자 데이터를 다루는 에이전트(psychology, tarot, uiux)에도 PII 관련 제약을 Core Principles 또는 Red Lines에 추가.

### 낮은 우선순위

4. **Agent Handle 명시 (T7 minor 갭)**
   - YAML `name` 필드가 실질적 핸들 역할을 하므로 긴급하지 않으나, Role 섹션에 `Handle: @psychology-expert` 형태의 명시적 선언을 추가하면 이론 기준에 완전히 부합.

5. **Max RPM 주석 (T8 minor 갭)**
   - 현재 외부 API 미호출 상태이므로 긴급하지 않으나, 향후 웹 검색/API 도구 추가 시 RPM 제한이 필요하다는 주석을 오케스트레이션 프로토콜에 추가.

## 갭 심각도 종합

| 축 | 판정 | 최대 갭 심각도 | 핵심 갭 |
|----|------|-------------|---------|
| T4 (5요소) | ✅ | -- | 없음 |
| T7 (3기둥) | ⚠️ | **major** | Backstory 7/7 부재 |
| T8 (도구/가드레일) | ⚠️ | minor | Max RPM 미정의, PII 비균일 |
| T9 (SOP O->T->A->S) | ✅ | -- | 없음 (초과 달성) |
| T10 (구조화 출력) | ✅ | minor | 런타임 검증 없음 (플랫폼 제약) |
| T14 (80/20) | ⚠️ | minor | 산출물 입출력 예시 부재 |
| 교차 일관성 | ✅ | -- | 없음 |

## References
- `docs/07_organizational_agents/000.1_gemini_deep_research.md` -- T4 페르소나 5요소 (줄 129-131)
- `docs/07_organizational_agents/000.2_gemini_deep_research.md` -- T7 섹션 3.1 (줄 55-65), T8 섹션 3.2 (줄 67-77), T9 섹션 4 (줄 82-87), T10 섹션 4 (줄 86-87), T14 섹션 3 (줄 53), 5.1 벤치마크 테이블 (줄 92-151)
- `.claude/agents/psychology-expert.md`
- `.claude/agents/coding-expert.md`
- `.claude/agents/flutter-expert.md`
- `.claude/agents/mbti-expert.md`
- `.claude/agents/enneagram-expert.md`
- `.claude/agents/tarot-expert.md`
- `.claude/agents/uiux-expert.md`
- `.claude/protocols/orchestration.md`

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
