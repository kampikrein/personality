---
id: "010"
type: research
title: "소통 프로토콜 & SOP 설계 연구"
created: 2026-03-14
status: in-progress
traces_scope: "001"
summary: >
  사이클 2 연구. 오케스트레이터-워커 간 구조화된 인계 포맷, MetaGPT SOP 행동 루프의
  Claude Code 에이전트 프롬프트 인코딩 방안, 평가루프 종료 조건과 Human-in-the-Loop
  개입 지점 설계를 조사한다.
keywords: [인계포맷, SOP, Observe-Think-Act-Share, 평가루프, Human-in-the-Loop, 소통프로토콜]
parallel_plan:
  total_perspectives: 3
  phases:
    - phase: 1
      perspectives: [1, 2, 3]
      status: completed
      agent_numbers: ["011", "012", "013"]
  synthesis_number: "014"
  final_number: "015"
---

# 소통 프로토콜 & SOP 설계 연구

## Research Overview

### Background & Motivation

사이클 1에서 오케스트레이터 에이전트(`.claude/agents/orchestrator.md`)와 워크플로우 상태 관리 인프라
(`.claude/work-orders/`)를 구축했다. 그러나 현재 오케스트레이터는 에이전트를 스폰하고 결과를 읽는
기본 구조만 갖추고 있으며, 에이전트 간 소통의 **구체적 프로토콜**이 부재하다:

- 인계 파일의 상세 포맷이 템플릿 수준에 머무름 (`.claude/work-orders/_templates/handover.yaml`)
- 각 에이전트 프롬프트에 SOP 행동 루프가 인코딩되지 않음
- 평가루프의 종료 조건이 오케스트레이터 프롬프트에 개략적으로만 정의됨
- Human-in-the-Loop 개입 지점이 명시되지 않음

사이클 2에서는 이 격차를 해소하여 에이전트 간 **자동화된 구조적 소통**을 가능하게 한다.

### Research Scope

**포함**:
- 현재 에이전트 산출물의 구체적 패턴 분석 (docs/06_에이전트비평/ 참조)
- MetaGPT SOP 이론의 Claude Code 에이전트 프롬프트 매핑
- 인계 파일 포맷의 상세 설계 방향
- 평가루프 종료 조건 자동 판정 메커니즘
- Human-in-the-Loop 개입 지점 식별 및 설계
- 오케스트레이터 프롬프트에 추가할 SOP 섹션 구조

**제외**:
- 에이전트 프롬프트의 페르소나 강화 (사이클 3)
- 공유 기억 체계 설계 (사이클 3)
- 외부 런타임/MAS 도입 (scope에서 제외)

### Research Perspectives

1. **인계 포맷 & 산출물 구조화** — 현재 에이전트 산출물 패턴 분석, 구조화된 인계 파일 포맷 상세 설계, 환각 캐스케이딩 방지를 위한 confidence/validation 필드 설계
2. **SOP 행동 루프 인코딩** — MetaGPT의 Observe→Think→Act→Share를 Claude Code 에이전트 프롬프트에 구조화하는 방안, 각 에이전트 역할별 SOP 변형, 오케스트레이터 프롬프트에 추가할 SOP 섹션
3. **평가루프 종료 조건 & Human-in-the-Loop** — 자동 종료 판정 메커니즘 설계, 사용자 개입이 필요한 지점 식별, 개입 프로토콜 설계, 비용/품질 트레이드오프

## Preliminary Findings

사이클 1 연구(R-008)에서 도출된 관련 발견:
- R-008-F4: 파일 기반 상태 관리가 유일한 통신 채널
- R-008-F5: 3단계 컨텍스트 압축 모델 (Level 1/2/3)
- R-008-F6: 구조화된 평가 포맷 (`verdict: pass/fail` + `max_iterations: 3`)
- Synthesis 007의 충돌 해결: `.claude/work-orders/` 워크플로우 중심 구조 채택

오케스트레이터 프롬프트(`.claude/agents/orchestrator.md`)에 이미 존재하는 관련 섹션:
- Agent Delegation Protocol (에이전트 스폰 지침, 산출물 저장 규칙)
- Evaluation Loop Protocol (verdict 포맷, 가드레일)
- Workflow State Management (manifest, 워크플로우 ID 규칙)

## Parallel Execution Instructions

### Perspective 1: 인계 포맷 & 산출물 구조화

**조사 목표**: 에이전트 간 산출물 전달의 최적 포맷을 설계하기 위한 현황 분석과 설계 방향 도출.

**구체적 조사 항목**:
1. **현재 산출물 패턴 분석**:
   - `docs/06_에이전트비평/` 내 6개 파일의 구조(frontmatter 필드, 본문 섹션, 상호 참조 방식) 분석
   - `docs/07_organizational_agents/` 내 Agent_*.md 파일의 구조 분석
   - 현재 산출물이 다음 에이전트에 전달하기에 충분한 정보를 담고 있는지 평가

2. **인계 포맷 상세 설계**:
   - 현재 `.claude/work-orders/_templates/handover.yaml` 템플릿 검토
   - 사이클 1 연구의 인계 포맷 제안(R-008 관점 4)과 비교
   - 필수 필드 vs 선택 필드 구분
   - `confidence` 필드의 수준 정의 (high/medium/low 기준)
   - `validation` 필드의 검증자 지정 패턴

3. **환각 캐스케이딩 방지**:
   - docs/002_gemini_deep_research.md에서 환각 캐스케이딩 안티 패턴 관련 내용 확인
   - 산출물의 자기 평가(confidence) + 교차 검증(validation) 메커니즘
   - 원본 추적(artifacts) 필드의 구체적 활용 패턴

4. **3단계 압축 적용**:
   - Level 1(전문)/Level 2(요약)/Level 3(인계)가 인계 포맷에 어떻게 반영되는지
   - 오케스트레이터가 Level 2로 읽을 때의 최소 정보 요구사항

**조사 방법**:
- `docs/06_에이전트비평/` 전체 파일 읽기 (구조 분석)
- `.claude/work-orders/_templates/` 템플릿 파일 읽기
- `docs/07_organizational_agents/006_Agent_상태관리컨텍스트.md` 관련 섹션 참조
- `.claude/agents/orchestrator.md`의 Agent Delegation Protocol 섹션 참조
- `docs/002_gemini_deep_research.md`의 구조화된 출력 / 환각 방지 섹션 참조

### Perspective 2: SOP 행동 루프 인코딩

**조사 목표**: MetaGPT의 Observe→Think→Act→Share SOP 철학을 Claude Code 에이전트 프롬프트에 구조화하는 구체적 방안 도출.

**구체적 조사 항목**:
1. **MetaGPT SOP 이론 분석**:
   - `docs/002_gemini_deep_research.md`에서 SOP 관련 내용 전체 추출
   - Observe→Think→Act→Share 각 단계의 정의와 목적
   - SOP가 에이전트 품질에 미치는 영향 (이론적 근거)

2. **Claude Code 에이전트 프롬프트 매핑**:
   - 현재 5개 에이전트 프롬프트의 Analysis Framework 섹션 비교 분석
   - SOP 4단계를 기존 프롬프트 구조에 매핑하는 방안
   - 오케스트레이터 프롬프트에 SOP 마스터 섹션 추가 방안

3. **역할별 SOP 변형**:
   - 연구/검증 에이전트(psychology): Observe→(학술 검색)→Think→(근거 평가)→Act→(검증 보고서)→Share
   - 설계 에이전트(mbti, enneagram): Observe→(문항 분석)→Think→(설계 원칙)→Act→(초안 생성)→Share
   - 구현 에이전트(coding): Observe→(코드 탐색)→Think→(설계)→Act→(구현+테스트)→Share
   - UX 에이전트(uiux): Observe→(사용자 컨텍스트)→Think→(UX 원칙)→Act→(UI 구현)→Share

4. **SOP와 인계의 통합**:
   - Share 단계에서 생성되는 산출물이 곧 인계 파일
   - Observe 단계에서 이전 에이전트의 산출물을 읽는 프로토콜
   - SOP 루프가 평가루프의 피드백 수신과 어떻게 통합되는지

**조사 방법**:
- `docs/002_gemini_deep_research.md` 전체 읽기 (SOP 관련 섹션 중심)
- `.claude/agents/*.md` 5개 파일의 Analysis Framework 섹션 비교
- `.claude/agents/orchestrator.md`의 현재 구조 분석
- `docs/001_gemini_deep_research.md`의 5개 핵심 계층 참조 (행동 계층과 SOP 매핑)

### Perspective 3: 평가루프 종료 조건 & Human-in-the-Loop

**조사 목표**: 평가/정제 루프의 자동 종료 판정 메커니즘과 사용자 개입 지점을 구체적으로 설계.

**구체적 조사 항목**:
1. **현재 평가루프 구조 분석**:
   - `.claude/agents/orchestrator.md`의 Evaluation Loop Protocol 현황
   - `.claude/work-orders/_templates/evaluation.yaml` 템플릿 분석
   - 현재 가드레일: max_iterations 3, 점수 미개선 시 중단, 턴 예산 관리

2. **종료 조건 상세 설계**:
   - verdict 판정 기준의 구체화 (무엇이 pass이고 무엇이 fail인지)
   - 역할별 검증 기준 세트 (학술 검증, 코드 검증, UX 검증)
   - conditional_pass의 처리 방안 (일부 기준만 통과한 경우)
   - "점수 미개선"의 구체적 측정 방법 (정량화 가능한지?)

3. **Human-in-the-Loop 개입 지점**:
   - docs/002_gemini_deep_research.md의 Human-in-the-Loop 관련 이론
   - 어떤 상황에서 자동 진행하고 어떤 상황에서 사용자에 위임하는지
   - 개입 요청의 포맷 (사용자에게 무엇을 보여주고 어떤 선택지를 제시하는지)
   - 개입 후 재개 프로토콜

4. **비용/품질 트레이드오프**:
   - 평가루프 1회 반복의 토큰 비용 추정
   - 반복 횟수와 품질 개선의 한계 수확 체감 분석
   - 워크플로우 유형별 최적 반복 횟수 (문항 검증 vs 코드 검증)
   - maxTurns 30 제약 하에서 평가루프의 현실적 한계

**조사 방법**:
- `.claude/agents/orchestrator.md` Evaluation Loop 섹션 상세 분석
- `.claude/work-orders/_templates/evaluation.yaml` 분석
- `docs/002_gemini_deep_research.md`의 가드레일, 종료 조건, Human-in-the-Loop 관련 내용
- `docs/07_organizational_agents/004_Agent_오케스트레이터패턴.md`의 평가루프 패턴 참조
- `docs/07_organizational_agents/008_Research_조직아키텍처_오케스트레이터_최종.md`의 R-008-F6 상세

## Remaining Work

- [ ] Perspective 1: 인계 포맷 & 산출물 구조화
- [ ] Perspective 2: SOP 행동 루프 인코딩
- [ ] Perspective 3: 평가루프 종료 조건 & Human-in-the-Loop
- [ ] Cross-Analysis
- [ ] Comprehensive Conclusion
