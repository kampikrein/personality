---
id: "026"
type: scope
title: "Gemini MAS 이론 관점 오케스트레이션 재평가"
created: 2026-03-17
complexity: simple
research_needed: true
research_reason: "7개 에이전트 파일 + orchestration.md + 스킬 시스템을 000.1/000.2의 이론 프레임워크와 1:1 대조 필요"
auto_run: false
intent: >
  Gemini Deep Research 두 문서(000.1: 비즈니스 발굴 MAS 아키텍처, 000.2: 조직 구조·페르소나·SOP 설계)가
  제시하는 MAS 이론/베스트프랙티스를 기준으로, 현재 personality 프로젝트의 오케스트레이션 시스템
  (orchestration.md, 7개 에이전트, agent-memory, 스킬 시스템)을 재평가한다.
  이전 감사(024)는 "원래 설계 vs 현재 구현" 비교였고, 이번은 "학술·산업 MAS 이론 vs 현재 구현"이라는
  다른 렌즈. 중간 과정 문서(018-025)는 참조하지 않고, 두 Gemini 문서와 현재 코드만 대조한다.
summary: >
  000.1/000.2 Gemini 연구의 MAS 이론 프레임워크(5가지 조직 구조, 5-layer 아키텍처, 페르소나 3기둥+도구/가드레일,
  SOP O→T→A→S, 안티패턴 3종, HitL, 동적 에이전트 선택)를 기준으로 현재 구현의 이론적 정합도 평가.
keywords: [gemini, mas-theory, organizational-structure, persona-design, sop, anti-pattern, hitl, audit]
---

# Gemini MAS 이론 관점 오케스트레이션 재평가

## 작업 목표
- 000.1/000.2의 MAS 이론 프레임워크를 체크리스트화하여 현재 구현과 1:1 대조
- 이론적으로 권장되지만 현재 미구현된 영역 식별
- 이론적으로 경고하는 안티패턴에 현재 시스템이 해당하는지 평가
- 성공 기준: 이론 프레임워크 항목별 "구현/부분구현/미구현/해당없음" 판정 + 갭 심각도

## 접근 방향
두 Gemini 문서에서 추출한 이론 프레임워크를 평가 축으로 삼고, 현재 구현 파일들을 직접 읽어 대조.
중간 과정 문서(018-025)는 의도적으로 배제하여 순수 이론 vs 구현 비교.

## Research 판단
- **판단**: 필요
- **근거**: 7개 에이전트 프롬프트의 페르소나 구조(Role/Goal/Backstory), 도구 배정, 가드레일을 하나씩 분석해야 하고, orchestration.md의 SOP/패턴/평가루프를 이론과 정밀 대조해야 함
- **파이프라인**: S → R (research까지만, 사용자 요청 `--res`)

## 연구 가이드

### 평가 축 (000.1 관점 — 비즈니스 발굴 MAS 아키텍처)

| # | 이론 개념 | 평가 대상 | 핵심 질문 |
|---|----------|----------|----------|
| T1 | 5-layer 아키텍처 (Perception→Memory→Planning→Action→Feedback) | 전체 시스템 | 5개 레이어가 어떻게 매핑되는가? 누락 레이어는? |
| T2 | 탐색-활용 균형 (Exploration vs Exploitation) | Pattern E, research 스킬 | 지역 최적해 탈출 메커니즘이 있는가? (Simulated Annealing 개념) |
| T3 | 적대적 검증 (Red Teaming) | 평가루프 | 비판 에이전트가 "악마의 대변인" 수준인가? 공격 시나리오 다양성은? |
| T4 | 페르소나 5요소 (Role, Expertise, Process, Output, Constraints) | 7개 에이전트 파일 | 5요소 모두 명시되어 있는가? |
| T5 | 가상 타깃 시뮬레이션 (Synthetic Users) | 전체 시스템 | 가상 사용자/페르소나 시뮬레이션이 존재하는가? |

### 평가 축 (000.2 관점 — 조직 구조·페르소나·SOP)

| # | 이론 개념 | 평가 대상 | 핵심 질문 |
|---|----------|----------|----------|
| T6 | 5가지 조직 구조 (계층/순차/병렬/협력채팅/평가루프) | orchestration.md 패턴 A-E | 5가지 중 어떤 것이 구현되었고, 어떤 것이 빠졌는가? |
| T7 | 페르소나 3기둥 (Role/Goal/Backstory) | 7개 에이전트 | CrewAI 권장 수준의 구체성이 있는가? |
| T8 | 도구 & 가드레일 (권한 분리, Max Iterations, Max RPM, PII 보호) | 에이전트 프롬프트 + 시스템 설정 | 도구 배정이 역할과 일치하는가? 권한 분리는? |
| T9 | SOP: O→T→A→S 행동루프 | 에이전트 SOP 섹션 | MetaGPT의 관찰→사고→행동→공유가 인코딩되어 있는가? |
| T10 | 구조화된 출력 (Structured Outputs) | 산출물 프로토콜, frontmatter | 에이전트 간 인계가 규격화되어 있는가? 환각 캐스케이딩 방지는? |
| T11 | 안티패턴 3종 (Business Process Fallacy, Invisible State, As-Is Mutation) | 전체 시스템 | 현재 시스템에 해당하는 안티패턴이 있는가? |
| T12 | 동적 에이전트 선택 (Semantic Retrieval) | CLAUDE.md 위임 판단 | 런타임 인텐트 기반 에이전트 라우팅이 존재하는가? |
| T13 | HitL 패턴 (고위험 작업 일시정지) | 사용자 개입 트리거 | 돌이킬 수 없는 작업에 대한 안전망이 충분한가? |
| T14 | 80/20 규칙 (Tasks over Agents) | 에이전트 프롬프트 전체 | 페르소나 꾸미기 vs 태스크 정의의 비율이 적절한가? |
| T15 | 메모리 & 컨텍스트 관리 (단기/장기 기억, 슬라이딩 윈도우) | agent-memory, 맥락 보전 프로토콜 | 단기/장기 기억 분리가 되어 있는가? |

### 현재 구현 파일 (연구에서 읽어야 할 파일)

- `.claude/protocols/orchestration.md` — 통합 프로토콜
- `.claude/agents/*.md` — 7개 에이전트 정의 (psychology, mbti, enneagram, coding, flutter, tarot, uiux)
- `CLAUDE.md` — 위임 판단, 에이전트 테이블, 오케스트레이션 트리거
- `.claude/agent-memory/` — 기억 체계 구조
- `.claude/skills/` — 스킬 시스템 (scope, research, makeplan, implementation, verify, parallel-execute)

### 비교 기준 (000.1/000.2에서만)

- `docs/07_organizational_agents/000.1_gemini_deep_research.md` — 비즈니스 발굴 MAS 아키텍처
- `docs/07_organizational_agents/000.2_gemini_deep_research.md` — 조직 구조·페르소나·SOP 설계

### 의도적 배제

- `docs/07_organizational_agents/001-025` — 원래 설계 문서 및 이전 감사 과정 산출물
- `docs/002_gemini_deep_research.md` — 다른 Gemini 연구 (루트 docs/)

## 체크포인트 & 컨텍스트 관리

| 체크포인트 | 산출물 | 컨텍스트 조치 |
|-----------|--------|-------------|
| /scope 완료 | 이 문서 | /clear 권장 — research가 독립적 넓은 탐색 수행 |
| /research 완료 | Research 문서 | 사용자 판단 대기 (--res 모드) |

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
