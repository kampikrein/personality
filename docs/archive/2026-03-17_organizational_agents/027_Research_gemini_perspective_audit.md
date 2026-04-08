---
id: "027"
type: research
title: "Gemini MAS 이론 관점 오케스트레이션 재평가"
created: 2026-03-17
status: completed
traces_scope: "026"
summary: >
  000.1/000.2 Gemini 연구의 MAS 이론 프레임워크 15개 평가 축을 기준으로
  현재 오케스트레이션 시스템의 이론적 정합도를 3개 관점에서 병렬 평가.
keywords: [gemini, mas-theory, organizational-structure, persona-design, sop, anti-pattern, hitl, audit]
parallel_plan:
  total_perspectives: 3
  phases:
    - phase: 1
      perspectives: [1, 2, 3]
      status: pending
      agent_numbers: ["028", "029", "030"]
  synthesis_number: "031"
  final_number: "032"
---

# Gemini MAS 이론 관점 오케스트레이션 재평가

## Research Overview

### Background & Motivation
personality 프로젝트의 오케스트레이션 시스템은 7개 전문 에이전트를 조율하는 프로토콜 기반 MAS이다.
이전 감사(024)는 프로젝트 자체 설계 문서 대비 평가였으나, 이번은 외부 학술·산업 MAS 이론(Gemini Deep Research 2편)의
렌즈로 현재 구현의 이론적 정합도를 측정한다.

### Research Scope
- **포함**: 000.1/000.2의 MAS 이론 프레임워크 15개 축 vs 현재 구현 코드
- **제외**: 중간 과정 문서(001-025), 코드 변경, 새 기능 설계

### Research Perspectives
1. **구조·패턴·아키텍처** (T1, T2, T5, T6, T11, T12) — 시스템 조직 방식과 아키텍처 매핑
2. **페르소나·SOP·태스크 설계** (T4, T7, T8, T9, T10, T14) — 에이전트 정의와 작업 방식
3. **거버넌스·검증·기억** (T3, T13, T15) — 품질 보증, 인간 통제, 지식 보존

## Preliminary Findings
Pending parallel investigation.

## Parallel Execution Instructions

### 이론 기준 문서 (모든 관점 공통)
- `docs/07_organizational_agents/000.1_gemini_deep_research.md` — 비즈니스 발굴 MAS (5-layer, 탐색 알고리즘, 적대적 검증, 페르소나 5요소)
- `docs/07_organizational_agents/000.2_gemini_deep_research.md` — 조직 구조·페르소나·SOP (5가지 구조, O→T→A→S, 안티패턴, HitL, 동적 선택)

### 공통 평가 산출물 형식
각 평가 축(Tn)에 대해 아래 형식으로 판정:
```
| Tn | 이론 개념 | 판정 | 근거 (파일:라인) | 갭 심각도 |
```
판정: 구현(✅) / 부분구현(⚠️) / 미구현(❌) / 해당없음(➖)
갭 심각도: Critical / High / Medium / Low / None

---

### Perspective 1: 구조·패턴·아키텍처 (T1, T2, T5, T6, T11, T12)

**담당 평가 축:**

**T1 — 5-layer 아키텍처 매핑**
000.1이 제시한 5개 레이어: Perception Module, Memory System, Planning Engine, Action Execution, Feedback Loop.
- `.claude/protocols/orchestration.md` 전체 읽기 — 각 레이어에 해당하는 기능 식별
- `CLAUDE.md` 읽기 — 위임 판단 = Planning? Perception?
- `.claude/skills/` 디렉터리 구조 확인 — scope/research/makeplan/implementation/verify가 어떤 레이어에 매핑되는지
- `.claude/agent-memory/` 구조 — Memory System 레이어에 매핑
- 판정: 5개 레이어 중 몇 개가 존재하며, 누락된 레이어가 있는지

**T2 — 탐색-활용 균형**
000.1의 Simulated Annealing, 진화 알고리즘 개념. "미투 함정에서 탈출하는 메커니즘".
- `.claude/protocols/orchestration.md` — Pattern E(병렬 실행)에서 다양한 관점 탐색 메커니즘 확인
- `.claude/skills/research/SKILL.md` 읽기 — 다관점 연구가 탐색-활용 균형을 제공하는지
- 판정: 지역 최적해 탈출 메커니즘(다양한 관점, 의도적 불일치, 적대적 가설)이 있는지

**T5 — 가상 타깃 시뮬레이션 (Synthetic Users)**
000.1의 Stanford 연구 기반 가상 페르소나 군단 개념.
- 현재 시스템 전체에서 "가상 사용자" 또는 "합성 페르소나" 관련 기능 검색
- 판정: 해당 기능 존재 여부 (없으면 "해당없음" 또는 "미구현"으로 판정하되, 프로젝트 성격상 필요 여부 코멘트)

**T6 — 5가지 조직 구조 매핑**
000.2의 5가지: 계층형, 순차 파이프라인, 병렬/디스패처, 협력 그룹채팅, 평가/정제 루프.
- `.claude/protocols/orchestration.md` — 패턴 A-E 테이블 읽기
- 각 패턴을 000.2의 5가지와 1:1 매핑:
  - A(파이프라인) ↔ 순차 파이프라인?
  - B(평가루프) ↔ 평가/정제 루프?
  - C(하이브리드) ↔ 조합?
  - D(단일위임) ↔ 계층형의 특수 케이스?
  - E(병렬실행) ↔ 병렬/디스패처?
- 판정: 5가지 중 몇 가지가 구현되었고, 협력 그룹채팅(Roundtable)이 빠져있는지

**T11 — 안티패턴 3종 진단**
000.2의 안티패턴: (1) Agent-as-Business-Process Fallacy, (2) Invisible State, (3) As-Is Mutation.
- `.claude/protocols/orchestration.md` — 오케스트레이터가 프로세스를 직접 제어하는지 vs 에이전트에 위임하는지
- 산출물 프로토콜 — 중간 상태가 명시적으로 저장되는지 (Invisible State 여부)
- 평가루프 — 원문 데이터가 임의 변형되는 경로가 있는지
- 판정: 3개 안티패턴 각각에 대해 해당/비해당/부분해당

**T12 — 동적 에이전트 선택**
000.2의 "Semantic Retrieval for Agent Narrowing" 개념.
- `CLAUDE.md` — 위임 판단 트리 분석. 인텐트 기반 라우팅인지, 규칙 기반인지
- `.claude/protocols/orchestration.md` — 에이전트 조합 가이드 분석
- 판정: 의미론적 검색 기반인지, 규칙 기반인지, 그 한계는

**읽어야 할 파일:**
- `.claude/protocols/orchestration.md` (전체)
- `CLAUDE.md` (전체)
- `.claude/skills/scope/SKILL.md` (구조 확인용, 앞부분만)
- `.claude/skills/research/SKILL.md` (구조 확인용, 앞부분만)
- `.claude/agent-memory/_shared/_index.yaml`

---

### Perspective 2: 페르소나·SOP·태스크 설계 (T4, T7, T8, T9, T10, T14)

**담당 평가 축:**

**T4 — 페르소나 5요소 (000.1 기준)**
000.1이 제시한 5요소: Role, Expertise, Process, Output, Constraints.
- `.claude/agents/psychology-expert.md` 전체 읽기 — 5요소 매핑
- `.claude/agents/coding-expert.md` 전체 읽기 — 5요소 매핑
- `.claude/agents/flutter-expert.md` 전체 읽기 — 5요소 매핑
- 나머지 4개 에이전트도 읽기 (mbti, enneagram, tarot, uiux)
- 7개 에이전트 모두에서 5요소 각각의 존재 여부를 테이블로 정리

**T7 — 페르소나 3기둥 (000.2 기준)**
000.2의 CrewAI 스타일 3기둥: Role(직함+핸들), Goal(측정 가능한 임무), Backstory(입체적 서사).
- 7개 에이전트 파일에서 각각:
  - Role: 명시적 직함이 있는가? 핸들(@Handle) 형태가 있는가?
  - Goal: "측정 가능한" 수준으로 구체적인가?
  - Backstory: 관점과 가치관을 결정하는 서사가 있는가?
- 000.2의 예시(소프트웨어 개발 조직 테이블)와 비교하여 구체성 수준 평가

**T8 — 도구 & 가드레일**
000.2가 강조: 도구 배정은 역할과 일치해야 함, 권한 분리 필수, Max Iterations/Max RPM/PII 보호.
- 7개 에이전트 파일에서 도구/권한 관련 지시사항 탐색
- `.claude/protocols/orchestration.md` — 평가루프의 Max Iterations, 가드레일 확인
- 시스템 설정에서 도구 권한 분리 메커니즘 확인
- 판정: 권한 분리 수준, 가드레일 구체성

**T9 — SOP: O→T→A→S 행동루프**
000.2의 MetaGPT 핵심: Observe → Think → Act → Share.
- 7개 에이전트 파일 모두에서 SOP/행동루프 섹션 찾기
- 각 에이전트의 SOP가 O→T→A→S 4단계를 모두 명시하고 있는지
- 단계별 구체적 행동이 정의되어 있는지 (추상적 vs 구체적)

**T10 — 구조화된 출력 (Structured Outputs)**
000.2가 경고: "자연어로만 소통하면 캐스케이딩 환각 발생". 구조화된 인계 포맷 필수.
- `.claude/protocols/orchestration.md` — 산출물 프로토콜의 frontmatter/마크다운 구조
- 에이전트 보고서 템플릿의 구조화 수준
- 평가 결과 포맷(evaluation YAML)의 구조화 수준
- 판정: JSON/YAML 스키마 강제 수준, 환각 캐스케이딩 방지 메커니즘

**T14 — 80/20 규칙**
000.2의 CrewAI 철학: 에이전트 배경 꾸미기 20%, 태스크 정의 80%.
- 7개 에이전트 파일 전체에서 "페르소나 서사" vs "구체적 태스크/프로세스 정의"의 토큰 비율 추정
- 판정: 80/20 원칙에 부합하는지

**읽어야 할 파일:**
- `.claude/agents/psychology-expert.md` (전체)
- `.claude/agents/coding-expert.md` (전체)
- `.claude/agents/flutter-expert.md` (전체)
- `.claude/agents/mbti-expert.md` (전체)
- `.claude/agents/enneagram-expert.md` (전체)
- `.claude/agents/tarot-expert.md` (전체)
- `.claude/agents/uiux-expert.md` (전체)
- `.claude/protocols/orchestration.md` — 산출물 프로토콜, 평가 결과 포맷 섹션

---

### Perspective 3: 거버넌스·검증·기억 (T3, T13, T15)

**담당 평가 축:**

**T3 — 적대적 검증 (Red Teaming)**
000.1의 3단계 워크플로우 중 "적대적 검증": Devil's Advocate, Adversarial Attacker 에이전트가 가설을 무너뜨림.
000.2의 "평가 및 정제 루프": 생성-비판 짝, 품질 가이드라인 기반 결함 탐지.
- `.claude/protocols/orchestration.md` — 평가루프 프로토콜 전체 읽기
  - severity 기반 verdict 판정
  - 검증 기준 (PSY, CODE, UX, TAROT)
  - 비판 에이전트의 역할이 단순 체크리스트인지 vs 적대적 공격 시나리오까지 갖추고 있는지
- 판정: 현재 평가루프가 000.1의 "Red Teaming" 수준에 도달하는지, 아니면 000.2의 "Critique Loop" 수준인지

**T13 — HitL 패턴**
000.2 섹션 6.3: "돌이킬 수 없고 파급력이 거대한 고위험 작업에 대한 에이전트 완전 자율성 불허".
"에이전트 그룹은 Groundwork를 전담하되, 실행 직전 일시정지하고 인간 검토 요청".
- `.claude/protocols/orchestration.md` — "사용자 개입 트리거" 섹션 전체 읽기 (최근 H1-H7으로 확장)
- `CLAUDE.md` — Red Lines 확인
- 000.2의 요구사항과 대조:
  - 실제 코드 배포, 거액 재무 승인, 법적 계약 → personality 프로젝트 맥락에서의 동등물은?
  - "Groundwork 전담 + 실행 직전 일시정지" 패턴이 구현되어 있는가?
- 개입 요청 포맷의 구조화 수준 (000.2가 요구하는 "추론 과정 추적(Trace) + 승인/거절/수정")

**T15 — 메모리 & 컨텍스트 관리**
000.1의 Memory System: 단기 문맥 + 장기 지식 그래프. "과거 실패 기억으로 동일 오류 반복 방지".
000.2의 Memory & Context: 단기/장기 메모리, 슬라이딩 윈도우, 인지 과부하 방지.
- `.claude/agent-memory/` 전체 구조 탐색
  - `_shared/_index.yaml` 읽기
  - `psychology-expert/_index.yaml` 읽기
  - 실제 기억 파일 1개 읽기 (구조 확인)
- `.claude/protocols/orchestration.md` — "맥락 보전 프로토콜" + "에이전트 기억 체계 활용" 섹션
- 판정:
  - 단기 기억(대화 컨텍스트) vs 장기 기억(agent-memory 파일) 분리 여부
  - 과거 실패 기억 메커니즘 존재 여부
  - 슬라이딩 윈도우 또는 동등한 컨텍스트 관리 존재 여부
  - 지식 그래프 수준의 구조화 여부

**읽어야 할 파일:**
- `.claude/protocols/orchestration.md` — 평가루프, 사용자 개입 트리거, 맥락 보전, 기억 체계 섹션
- `CLAUDE.md` — Red Lines
- `.claude/agent-memory/_shared/_index.yaml`
- `.claude/agent-memory/psychology-expert/_index.yaml`
- `.claude/agent-memory/_shared/memories/001_파운더비전_성격포탈.yaml` (기억 파일 구조 확인)
- `.claude/agent-memory/psychology-expert/memories/001_학술차별화전략_핵심발견.yaml` (개별 기억 구조)

## Remaining Work
- [ ] Perspective 1: 구조·패턴·아키텍처 (T1, T2, T5, T6, T11, T12)
- [ ] Perspective 2: 페르소나·SOP·태스크 설계 (T4, T7, T8, T9, T10, T14)
- [ ] Perspective 3: 거버넌스·검증·기억 (T3, T13, T15)
- [ ] Cross-Analysis
- [ ] Comprehensive Conclusion

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
