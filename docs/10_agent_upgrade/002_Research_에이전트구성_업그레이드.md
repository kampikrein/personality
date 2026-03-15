---
id: "002"
type: research
title: "에이전트 구성 업그레이드 — 타로 모바일 확장 연구"
created: 2026-03-15
status: completed
traces_scope: "001"
summary: >
  타로 모바일 앱 PRD 기반으로 현재 5개 에이전트 구성의 갭을 메우기 위한 외부 연구.
  타로앱 커뮤니티 페인포인트, 멀티에이전트 구성 사례, Flutter 에이전트 패턴,
  UX 평가 방법론, 타로 도메인 에이전트 필요성을 5개 관점에서 조사.
keywords: [tarot-app, community-painpoints, multi-agent, flutter, ux-evaluation, tarot-domain, agent-upgrade]
parallel_plan:
  total_perspectives: 5
  phases:
    - phase: 1
      perspectives: [1, 2, 3]
      status: completed
      agent_numbers: ["003", "004", "005"]
    - phase: 2
      perspectives: [4, 5]
      status: completed
      agent_numbers: ["006", "007"]
  synthesis_number: "008"
  final_number: "009"
---

# 에이전트 구성 업그레이드 — 타로 모바일 확장 연구

## Research Overview

### Background & Motivation

현재 personality 프로젝트는 5개 전문 에이전트(psychology-expert, mbti-expert, enneagram-expert, coding-expert, uiux-expert)로 구성되어 있다. 그러나 PRD(docs/003_gemini_deep_research.md)가 정의한 타로 모바일 앱 요구사항은 Flutter/Dart 모바일 개발, 물리 엔진/센서 API, 커스텀 덱/셔플, 소셜 커뮤니티, 타로 도메인 지식 등 현재 에이전트가 전혀 커버하지 못하는 영역을 포함한다.

스코프 문서(001)의 갭 분석 결과, 9개 PRD 영역 중 7개가 완전 공백(🔴)으로 확인되었다. 단순히 에이전트를 추가하는 것이 아니라, 커뮤니티 실제 불만, 업계 사례, 기술적 베스트 프랙티스를 기반으로 에이전트 구성을 설계해야 한다.

### Research Scope

**포함**: 타로앱 사용자 생태계, AI 멀티에이전트 구성 사례, Flutter 모바일 에이전트 패턴, UX 평가 자동화, 타로 도메인 에이전트 필요성
**제외**: 실제 에이전트 구현, 코드 작성, Rails 백엔드 변경 (사이클 2에서 수행)

### Research Perspectives

1. **타로 앱 커뮤니티 페인포인트** — 기존 타로 앱에 대한 실제 사용자 불만, 셔플 경험 수요, 커스텀 덱/소셜 기대
2. **멀티에이전트 시스템 구성 사례** — 모바일+서버 혼합 프로젝트의 에이전트 분리 패턴, 에이전트 수 확장 시 오케스트레이션 관리
3. **Flutter/모바일 개발 에이전트 패턴** — Flutter 전문 AI 에이전트의 필수 지식, 물리엔진/센서 분리 여부, 오프라인-퍼스트 패턴
4. **UX 평가/QA 에이전트 방법론** — 사용자 관점 품질 평가 에이전트의 역할 범위, 자동화 가능 영역, 피드백 루프 설계
5. **타로 도메인 에이전트 필요성 검증** — 타로 도메인 지식의 에이전트 분리 vs 참조 문서화, MBTI/애니어그램과의 관계

## Preliminary Findings

스코프 문서의 갭 분석에서 확인된 주요 사항:
- 현재 에이전트 중 Flutter/Dart를 지원하는 에이전트 없음 (coding-expert는 Rails 전용)
- uiux-expert는 웹(Hotwire/Turbo/Tailwind) 전용으로 모바일 네이티브 미지원
- 타로 도메인 지식은 프로젝트 내 어디에도 체계화되어 있지 않음
- PRD가 정의한 4가지 페르소나 (전통적 타로 리더, 크리에이터, 하이브리드 리더, 소셜 탐구자) 모두 현재 에이전트 구성에서 커버 불가

## Parallel Execution Instructions

### Perspective 1: 타로 앱 커뮤니티 페인포인트

**조사 목표**: 기존 타로 앱에 대한 실제 사용자 불만과 수요를 파악

**조사 방법** (외부 연구):
- WebSearch로 Reddit (r/tarot, r/tarotpractice, r/digitalwitchcraft), App Store 리뷰, Play Store 리뷰 검색
- "tarot app complaints", "tarot app problems", "digital tarot shuffle", "tarot app wish list" 등 키워드
- WebFetch로 유용한 스레드/리뷰 페이지 상세 읽기

**핵심 질문**:
1. 기존 타로 앱에서 사용자들이 가장 불만족하는 점은? (구체적 사례 수집)
2. "영적 연결감 부족"에 대한 구체적 불만 사례는?
3. 커스텀 덱/셔플에 대한 수요가 실제로 있는가? (증거 기반)
4. 소셜/커뮤니티 기능에 대한 기대와 우려는?
5. 기존 인기 타로 앱(Labyrinthos, Golden Thread, Galaxy Tarot 등)의 장단점은?

**산출물**: 사용자 불만 카테고리별 정리, 수요 우선순위, 경쟁앱 분석 요약

### Perspective 2: 멀티에이전트 시스템 구성 사례

**조사 목표**: 모바일+서버 혼합 프로젝트에서 AI 에이전트를 어떻게 분리/조합하는지 사례 조사

**조사 방법** (외부 연구):
- WebSearch로 "multi-agent system team composition", "AI agent team structure mobile backend", "Claude Code agent best practices", "multi-agent orchestration patterns" 검색
- WebSearch로 "evaluation agent QA agent pattern", "agent specialization vs generalization" 검색
- 기존 프로젝트 내부 에이전트 설계 문서 참조: docs/05_agent_design/, docs/07_organizational_agents/

**내부 참조 파일**:
- docs/05_agent_design/007_Research_전문에이전트_구성_최종.md — 기존 에이전트 설계 연구 결과
- docs/07_organizational_agents/008_Research_조직아키텍처_오케스트레이터_최종.md — 오케스트레이션 연구 결과
- .claude/protocols/orchestration.md — 현재 오케스트레이션 프로토콜

**핵심 질문**:
1. 모바일 + 서버 혼합 프로젝트에서 에이전트를 어떻게 분리하는가?
2. 도메인 전문가 vs 기술 전문가 에이전트의 최적 비율은?
3. 에이전트 수가 5개에서 7~8개로 늘어날 때 오케스트레이션 복잡도 관리 방법은?
4. 평가/QA 에이전트의 역할 정의 사례는?

**산출물**: 에이전트 분리 패턴 유형, 규모별 오케스트레이션 전략, 권장 구성안

### Perspective 3: Flutter/모바일 개발 에이전트 패턴

**조사 목표**: Flutter 전문 AI 에이전트에 필요한 핵심 지식과 모바일 특수 영역 커버리지 확인

**조사 방법** (외부 연구):
- WebSearch로 "Flutter AI agent", "Flutter development automation", "Flutter project AI assistant" 검색
- WebSearch로 "Flutter physics engine animation", "Flutter sensor API gyroscope", "Flutter offline first pattern" 검색
- WebSearch로 "Flutter MVVM clean architecture", "Flutter state management best practices 2025/2026" 검색

**핵심 질문**:
1. Flutter 전문 에이전트에 필요한 핵심 지식은? (Dart 언어, 위젯 시스템, 상태관리 등)
2. 물리 엔진/애니메이션 전문성을 별도 에이전트로 분리해야 하는가, 아니면 모바일 에이전트에 포함?
3. 오프라인-퍼스트, 센서 API 등 모바일 특수 영역의 에이전트 커버리지는?
4. Flutter + Rails API 연동에서 에이전트 간 협업 포인트는?
5. PRD의 CSPRNG, 자이로스코프, 물리 엔진 요구사항을 한 에이전트가 커버 가능한가?

**산출물**: Flutter 에이전트 역할 정의안, 기술 스택 요약, 에이전트 분리 권장안

### Perspective 4: UX 평가/QA 에이전트 방법론

**조사 목표**: 사용자 관점 품질 평가를 담당하는 에이전트의 역할 범위와 방법론 조사

**조사 방법** (외부 연구):
- WebSearch로 "UX evaluation automation", "heuristic evaluation checklist", "usability testing methodology" 검색
- WebSearch로 "AI UX review agent", "automated accessibility testing", "emotional design evaluation" 검색
- WebSearch로 "QA agent mobile app", "evaluation agent feedback loop design" 검색

**핵심 질문**:
1. 사용자 관점 평가 에이전트의 역할 범위는? (UX 감사, 접근성, 성능, 감정 흐름)
2. 평가 에이전트와 구현 에이전트의 피드백 루프 설계는?
3. 자동화 가능한 평가 항목 vs 수동 검증이 필요한 항목은?
4. 닐슨 히유리스틱, WCAG 등 표준 평가 체크리스트 중 에이전트화할 수 있는 것은?
5. 타로 앱 특수 맥락(영적 연결감, 몰입도, 제의적 UX)에 대한 평가 기준은?

**산출물**: 평가 에이전트 역할 정의안, 평가 체크리스트 프레임워크, 피드백 루프 설계안

### Perspective 5: 타로 도메인 에이전트 필요성 검증

**조사 목표**: 타로 도메인 지식을 별도 에이전트로 분리해야 하는지, 참조 문서로 충분한지 검증

**조사 방법** (외부 + 내부 연구):
- WebSearch로 "tarot reading structure", "tarot spread types", "tarot shuffle ritual significance" 검색
- WebSearch로 "tarot app market analysis 2025 2026", "digital tarot industry" 검색
- 내부 에이전트 설계 원칙 확인: docs/05_agent_design/ 내 "행동 규칙 > 역할 선언" 원칙
- 기존 MBTI/애니어그램 에이전트의 도메인 지식 배치 방식 참조

**내부 참조 파일**:
- .claude/agents/mbti-expert.md — MBTI 에이전트의 도메인 지식 배치 방식
- .claude/agents/enneagram-expert.md — 애니어그램 에이전트의 도메인 지식 배치 방식
- docs/05_agent_design/004_Agent_도메인지식.md — 도메인 지식 외부 배치 원칙

**핵심 질문**:
1. 타로 도메인 지식을 별도 에이전트로 분리해야 하는가, 아니면 참조 문서로 충분한가?
2. MBTI/애니어그램 에이전트와 타로 에이전트의 관계는? (보완? 독립? 통합?)
3. 타로 에이전트가 커버해야 할 도메인 범위는? (전통 해석, 현대 해석, 셔플 의식 등)
4. 도메인 지식 외부 배치 원칙을 타로에 어떻게 적용할 것인가?
5. 타로 시장 규모와 트렌드가 별도 에이전트 투자를 정당화하는가?

**산출물**: 에이전트 분리 vs 문서화 비교 분석, 도메인 범위 정의안, 시장 검증 결과

## Remaining Work

- [ ] Perspective 1: 타로 앱 커뮤니티 페인포인트
- [ ] Perspective 2: 멀티에이전트 시스템 구성 사례
- [ ] Perspective 3: Flutter/모바일 개발 에이전트 패턴
- [ ] Perspective 4: UX 평가/QA 에이전트 방법론
- [ ] Perspective 5: 타로 도메인 에이전트 필요성 검증
- [ ] Cross-Analysis
- [ ] Comprehensive Conclusion
