---
id: "002"
type: research
title: "조직 아키텍처 & 오케스트레이터 설계 연구"
created: 2026-03-14
status: completed
traces_scope: "001"
summary: >
  Claude Code 에이전트 프레임워크의 기술적 제약을 파악하고, MAS 이론(계층형+파이프라인+평가루프)을
  이 제약 안에서 실현하는 오케스트레이터 설계 방안을 도출한다. 사이클 1 연구.
keywords: [Claude Code agents, 오케스트레이션, 계층형, 파이프라인, 평가루프, 제약분석, maxTurns]
parallel_plan:
  total_perspectives: 4
  phases:
    - phase: 1
      perspectives: [1, 2, 3, 4]
      status: pending
      agent_numbers: ["003", "004", "005", "006"]
  synthesis_number: "007"
  final_number: "008"
---

# 조직 아키텍처 & 오케스트레이터 설계 연구

## Research Overview

### Background & Motivation

현재 personality 프로젝트는 5개 독립 에이전트(psychology, mbti, enneagram, coding, uiux)가
사용자 수동 중재로 작동하고 있다. 이를 조직 에이전트 시스템으로 전환하기 위해,
오케스트레이터 계층 도입이 필수적이다.

그러나 Claude Code 에이전트 프레임워크는 일반적인 MAS 런타임(LangGraph, CrewAI 등)과 달리:
- `.claude/agents/*.md` 마크다운 파일로 에이전트 정의
- 별도 런타임 없이 Claude Code CLI 내부에서 실행
- 에이전트 간 직접 호출/통신 메커니즘이 범용 MAS와 상이

따라서 doc 001/002에서 제시한 MAS 이론을 그대로 적용할 수 없으며,
Claude Code의 실제 기술 제약 안에서 가능한 패턴을 정밀히 매핑해야 한다.

### Research Scope

**포함**:
- Claude Code 에이전트 프레임워크의 기술적 제약 (에이전트 호출, 도구, 권한, 턴 수)
- 오케스트레이터 에이전트의 설계 패턴 (계층형+파이프라인+평가루프)
- 현재 5개 에이전트의 조직화 격차 분석
- 에이전트 간 상태/결과 전달 메커니즘

**제외**:
- 외부 런타임 MAS 도입 (Python/LangGraph 등)
- SOP 인코딩 상세 설계 (사이클 2)
- 페르소나 강화 상세 (사이클 3)

### Research Perspectives

1. **Claude Code 에이전트 프레임워크 기술 제약** — 에이전트 간 호출 메커니즘, Agent tool 동작, 도구/권한 모델, maxTurns 등 프레임워크 레벨 제약 파악
2. **오케스트레이터 설계 패턴 매핑** — doc 002의 계층형+파이프라인+평가루프를 Claude Code 내에서 구현하는 구체적 방안. 작업 분해, 위임, 결과 종합 패턴
3. **현재 에이전트 조직화 격차 분석** — 5개 에이전트의 역할/도구/기억 구조 현황, 조직화에 필요한 변경점 식별
4. **상태 관리 및 컨텍스트 전달** — 파일 기반 인계, agent-memory 활용, 에이전트 간 정보 흐름 설계

## Preliminary Findings

### Claude Code 에이전트 파일 구조

현재 `.claude/agents/` 디렉토리에 5개 에이전트 정의:

| 에이전트 | model | maxTurns | 도구 | permissionMode |
|---------|-------|----------|------|----------------|
| psychology-expert | sonnet | 15 | Read, Glob, Grep, Edit, Write | acceptEdits |
| mbti-expert | sonnet | 15 | Read, Glob, Grep, Edit, Write | acceptEdits |
| enneagram-expert | sonnet | 15 | Read, Glob, Grep, Edit, Write | acceptEdits |
| coding-expert | sonnet | 25 | Read, Write, Edit, Bash, Glob, Grep | acceptEdits |
| uiux-expert | sonnet | 20 | Read, Write, Edit, Bash, Glob, Grep | acceptEdits |

### 초기 관찰

1. **Agent tool 제약**: 시스템 프롬프트에 따르면 Agent tool의 `subagent_type`은 미리 정의된 타입(general-purpose, Explore, Plan 등)만 지원. 커스텀 에이전트(`.claude/agents/*.md`)를 programmatically 호출하는 메커니즘은 별도 조사 필요.

2. **기억 체계 격리**: 5개 에이전트 모두 독립적인 `_index.yaml` + `memories/` 구조. 교차 참조 없음.

3. **도구 권한 차이**: coding/uiux만 Bash 보유. 에이전트 간 역할 경계는 Collaboration Rules로 텍스트 정의.

4. **공통 패턴**: 모든 에이전트가 동일한 기억 포맷(id/date/type/keywords/summary/context/details/implications)과 분석 프레임워크(5단계) 구조.

## Parallel Execution Instructions

### Perspective 1: Claude Code 에이전트 프레임워크 기술 제약

**조사 목표**: Claude Code 에이전트 시스템의 정확한 기능과 한계를 파악한다.

**구체적 조사 항목**:
1. **에이전트 간 호출**:
   - `.claude/agents/*.md`의 에이전트가 Agent tool을 통해 다른 커스텀 에이전트를 호출할 수 있는가?
   - Agent tool의 `subagent_type` 외에 커스텀 에이전트를 지정하는 방법이 있는가?
   - 에이전트 frontmatter에서 `tools: [Agent]`를 포함시키면 sub-agent 스폰이 가능한가?

2. **도구 및 권한 모델**:
   - frontmatter의 `tools` 배열에 사용 가능한 전체 도구 목록은?
   - `permissionMode`의 각 옵션(acceptEdits, bypassPermissions, default, dontAsk, plan, auto)의 정확한 동작은?
   - `skills` 배열의 역할과 작동 방식은? (uiux-expert에 `skills: [ui-ux-pro-max]` 존재)

3. **실행 제약**:
   - `maxTurns`의 실질적 한계는? 오케스트레이터가 여러 에이전트를 순차 호출하면 각 호출마다 턴을 소비하는가?
   - 에이전트의 컨텍스트 윈도우 관리 방식은?
   - 에이전트 실행 중 다른 에이전트 동시 실행 가능 여부

4. **파일 기반 특성**:
   - 에이전트 파일의 마크다운 본문이 시스템 프롬프트로 주입되는 방식
   - frontmatter 필드의 전체 스펙 (name, description, model, tools, permissionMode, maxTurns, skills 외 추가 필드)

**조사 방법**:
- Claude Code 공식 문서/가이드 검색 (WebSearch)
- `.claude/` 디렉토리 구조 탐색
- 기존 에이전트 파일 분석
- GitHub anthropics/claude-code 리포지토리 참조

### Perspective 2: 오케스트레이터 설계 패턴 매핑

**조사 목표**: MAS 이론의 하이브리드 구조를 Claude Code 에이전트로 실현하는 구체적 설계 방안을 도출한다.

**구체적 조사 항목**:
1. **계층형 패턴 구현**:
   - 오케스트레이터가 작업을 분해하고 적절한 에이전트에 위임하는 방법
   - Claude Code에서 "위임"의 실현 형태: Agent tool 스폰? 파일 기반 지시? 사용자 중재?
   - 오케스트레이터의 작업 분해 로직을 프롬프트에 인코딩하는 방법

2. **파이프라인 패턴 구현**:
   - 순차적 에이전트 호출 체인 (요구사항→설계→구현→검증)
   - 이전 단계 산출물을 다음 단계에 전달하는 메커니즘
   - 에이전트 체인의 오류 복구 패턴

3. **평가/정제 루프 구현**:
   - 생성 에이전트 → 비판 에이전트 → 수정 피드백의 반복 구조
   - 종료 조건 판정 메커니즘
   - 무한 루프 방지를 위한 가드레일

4. **하이브리드 통합**:
   - 세 패턴을 단일 오케스트레이터로 통합하는 방안
   - 워크플로우 유형에 따른 패턴 선택 로직
   - doc 001의 5개 핵심 계층(인지/기억/추론/행동/피드백)과의 매핑

**참고 자료**:
- docs/002_gemini_deep_research.md: MAS 구조 모델 5종, 안티 패턴, SOP 철학
- docs/001_gemini_deep_research.md: 5개 핵심 계층, 페르소나 5요소
- docs/05_agent_design/010_Scope_조직에이전트_전환.md: 초기 scope
- docs/07_organizational_agents/001_Scope_조직에이전트_전환.md: 현재 scope

### Perspective 3: 현재 에이전트 조직화 격차 분석

**조사 목표**: 5개 에이전트의 현재 구조를 분석하고, 조직 에이전트 전환에 필요한 구체적 변경점을 식별한다.

**구체적 조사 항목**:
1. **역할 구조 분석**:
   - 각 에이전트의 Role/Core Principles/Analysis Framework 비교
   - 역할 간 중복과 공백 영역 식별
   - doc 002의 페르소나 5요소(Role/Goal/Backstory/Tools+Guardrails/Memory) 대비 현재 구조 격차

2. **협업 구조 분석**:
   - 현재 Collaboration Rules 섹션의 패턴 분석
   - "관점 충돌 시" 프로토콜의 현재 형태와 개선 필요점
   - 에이전트 간 영역 경계(Boundaries)의 명확성 평가

3. **기억 체계 분석**:
   - `.claude/agent-memory/*/` 디렉토리 구조와 내용 확인
   - `_index.yaml` 포맷과 기억 파일 간 관계
   - 교차 에이전트 기억 참조의 부재로 인한 문제점

4. **도구 격차 분석**:
   - 현재 도구 할당의 적절성 (coding/uiux만 Bash 보유)
   - 오케스트레이터에 필요한 추가 도구
   - Agent tool 접근 권한이 필요한 에이전트 식별

**조사 방법**:
- `.claude/agents/*.md` 5개 파일 상세 비교 분석
- `.claude/agent-memory/*/` 전체 구조 탐색
- docs/06_에이전트비평/ 교차 비평 결과 참조
- docs/05_agent_design/ 기존 설계 문서 참조

### Perspective 4: 상태 관리 및 컨텍스트 전달

**조사 목표**: 에이전트 간 상태/결과 전달의 구체적 메커니즘을 설계한다.

**구체적 조사 항목**:
1. **파일 기반 인계**:
   - 에이전트 산출물의 현재 저장 위치/형태
   - 구조화된 인계 파일 포맷 설계 방향 (YAML frontmatter + Markdown body?)
   - 인계 파일의 위치/명명 규칙

2. **기억 체계 활용**:
   - 현재 `agent-memory` 구조의 확장 가능성
   - 조직 수준 공유 기억의 저장 위치와 접근 패턴
   - 에이전트 간 기억 인덱스 교차 참조 설계

3. **컨텍스트 윈도우 관리**:
   - 오케스트레이터가 여러 에이전트의 결과를 종합할 때 컨텍스트 한계
   - 요약/압축 전략
   - 단계별 컨텍스트 전달량 최적화

4. **상태 추적 패턴**:
   - 워크플로우 전체 진행 상태 추적 방법
   - 중단/재개 지원
   - 실패 시 롤백 메커니즘

**조사 방법**:
- `.claude/agent-memory/` 전체 구조와 기존 기억 내용 분석
- 기존 에이전트가 생산한 산출물 패턴 분석
- Claude Code의 파일 시스템 활용 패턴 조사

## Remaining Work

- [ ] Perspective 1: Claude Code 에이전트 프레임워크 기술 제약
- [ ] Perspective 2: 오케스트레이터 설계 패턴 매핑
- [ ] Perspective 3: 현재 에이전트 조직화 격차 분석
- [ ] Perspective 4: 상태 관리 및 컨텍스트 전달
- [ ] Cross-Analysis
- [ ] Comprehensive Conclusion
