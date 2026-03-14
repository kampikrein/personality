---
id: "015"
type: research
title: "소통 프로토콜 & SOP 설계 연구 (최종)"
created: 2026-03-14
traces_scope: "001"
summary: >
  사이클 2 연구. MetaGPT SOP(O→T→A→S)를 에이전트 프롬프트에 명시적으로 인코딩하고,
  Share 단계 산출물이 곧 인계 파일이 되는 통합 설계를 도출. 평가루프에 severity 필드
  (blocker/major/minor) + HitL 7개 트리거를 추가. 릴레이 감쇠 규칙으로 환각 캐스케이딩
  구조적 차단. 오케스트레이터에 SOP 마스터 섹션 + 역할별 검증 기준 세트 반영.
keywords: [SOP, Observe-Think-Act-Share, 인계포맷, 평가루프, HitL, severity, 릴레이감쇠]
---

# 소통 프로토콜 & SOP 설계 연구 (최종)

## Research Overview

### Background & Motivation

사이클 1에서 오케스트레이터 에이전트와 워크플로우 상태 관리 인프라를 구축했으나, 에이전트 간 소통의
구체적 프로토콜이 부재하다. 인계 파일의 상세 포맷이 템플릿 수준에 머물고, SOP 행동 루프가
에이전트 프롬프트에 인코딩되지 않으며, 평가루프의 종료 조건이 개략적으로만 정의되어 있다.

### Research Scope

- MetaGPT SOP 이론의 Claude Code 에이전트 프롬프트 매핑
- 인계 파일 포맷의 상세 설계 방향
- 평가루프 종료 조건 자동 판정 메커니즘
- Human-in-the-Loop 개입 지점 설계

### Research Perspectives

1. 인계 포맷 & 산출물 구조화
2. SOP 행동 루프 인코딩
3. 평가루프 종료 조건 & Human-in-the-Loop

### Related Documents

- Checkpoint: [010_Research_소통프로토콜_SOP.md](./010_Research_소통프로토콜_SOP.md)
- Agent reports: [011](./011_Agent_인계포맷설계.md), [012](./012_Agent_SOP행동루프.md), [013](./013_Agent_평가루프HitL.md)
- Synthesis: [014_Synthesis_소통프로토콜SOP.md](./014_Synthesis_소통프로토콜SOP.md)

---

## Perspective 1: 인계 포맷 & 산출물 구조화

### Status Analysis

현재 에이전트 산출물은 docs/06(에이전트비평)과 docs/07(조직 에이전트) 모두에서 동일한 7필드 YAML frontmatter + Markdown body 포맷을 따르며, 구조적 일관성이 높다. 그러나 인계 템플릿(`.claude/work-orders/_templates/handover.yaml`)은 최소 구조만 정의된 상태.

### Detailed Findings

#### 현재 산출물의 강점과 약점

**강점**: 모든 파일이 id, title, category, status, created, summary, keywords, modules의 동일 스키마를 사용. Level 2 압축의 기초가 이미 존재.

**약점 5가지**:
1. confidence 필드 부재 — 발견의 신뢰 수준 미명시
2. 역방향 참조 없음 — 에이전트 A가 에이전트 B의 발견을 참조할 방법 없음
3. next_steps 구체성 부족 — "일반적 개선 방향"이지 "다음 에이전트 지시"가 아님
4. constraints 부재 — 수신 에이전트의 제약 조건 미전달
5. context_level 부재 — Level 2인지 Level 3인지 표시 없음

#### 인계 포맷 필수/선택 필드

**필수 10필드**: handover_id, workflow_id, created, status, source.agent, source.confidence, target.agent, target.expected_action, summary, next_steps

**선택 7필드**: source.task, artifacts, constraints, validation.criteria, validation.validator_agent, context_level, full_document

#### confidence 3단계 판정 기준

| 수준 | 기준 | 오케스트레이터 행동 |
|------|------|-----------------|
| **high** | 코드/데이터에서 직접 확인 또는 2+ 에이전트 교차 확인 또는 학술 문헌 근거 | 추가 검증 없이 진행 |
| **medium** | 코드 분석 + 해석 혼합 또는 단일 에이전트 독립 발견 | 검증 에이전트 1회 확인 |
| **low** | 추론/추정 기반 또는 불확실한 정보 의존 | 반드시 교차 검증 |

#### 릴레이 감쇠 규칙

파이프라인에서 에이전트 간 전달 시 confidence가 한 단계씩 감쇠(high→medium→low). 3단계 이상 릴레이된 정보는 원본 직접 확인을 강제. 환각 증폭을 구조적으로 차단.

#### 3단계 압축의 인계 매핑

| Level | 내용 | 인계 대응 | 읽는 주체 |
|-------|------|---------|----------|
| Level 1 | 원본 전체 (~10K) | `full_document` 또는 `artifacts` 참조 | 해당 에이전트, 검증자 |
| Level 2 | summary + Key Findings (~500) | 산출물 frontmatter 상단 | 오케스트레이터 |
| Level 3 | summary + next_steps (~200) | 인계 YAML 자체 | 수신 워커 |

### Caveats & Risks

- 인계 파일이 복잡해지면 에이전트가 올바르게 생성하지 못할 위험
- confidence 자기 평가의 주관성 — 기준 정의만으로는 불충분할 수 있음

### Summary

현재 산출물의 일관된 frontmatter를 기반으로 인계 필드를 확장하되, Share 단계의 산출물 자체가 인계 역할을 하는 통합 설계가 최적.

---

## Perspective 2: SOP 행동 루프 인코딩

### Status Analysis

MetaGPT의 "Code = SOP(Team)" 철학이 제시하는 O→T→A→S 4단계 중, 현재 에이전트 프롬프트는 **Think(Analysis Framework)만 명시적으로 다루고** Observe와 Share가 구조적으로 누락.

### Detailed Findings

#### 현재 에이전트 프롬프트의 SOP 격차

| SOP 단계 | 현재 상태 | 격차 |
|---------|----------|------|
| **Observe** | Memory System에 "시작 시 _index.yaml 읽기"만 명시. 이전 산출물 읽기 프로토콜 없음 | 무엇을, 어디서, 어떤 정보를 추출하는지 미정의 |
| **Think** | Analysis Framework 5단계 체크리스트 = Think 전체 | 입력→판단→결정 흐름이 암묵적 |
| **Act** | Core Principles + Boundaries로 간접 정의. "무엇을 생산하는지" 미명시 | 산출물 형태/포맷/저장 위치 미정의 |
| **Share** | 완전 누락. Memory 저장만 있음 (자기 기억 ≠ 다음 에이전트 인계) | 인계 산출물 생성 프로토콜 부재 |

#### 프롬프트 구조 변경 제안

```
현재:                              제안:
# Role                             # Role
# Project Context                  # Project Context
# Core Principles                  # Core Principles
# Analysis Framework  ←(Think만)   # SOP: 행동 루프  ←(4단계)
# Communication Style                ## Observe: 입력 읽기
# Boundaries & Red Lines              ## Think: 분석 & 판단  ←(기존 Framework 유지)
# Collaboration Rules                 ## Act: 산출물 생성
# Memory System                       ## Share: 인계 & 기록
                                   # Communication Style
                                   # Boundaries & Red Lines
                                   # Collaboration Rules
                                   # Memory System
```

#### 역할별 SOP 핵심 차이

| 역할 | Observe 특화 | Think 특화 | Act 특화 | Share 특화 |
|------|-------------|-----------|---------|-----------|
| psychology | 검증 대상 + 학술 기억 조회 | 5단계 학술 검증 체크리스트 | verdict + fix_suggestion | evaluation YAML + 학술 기억 |
| mbti/enneagram | 설계 요구 + 기존 데이터 + 피드백 | 역할별 5단계 설계 체크리스트 | 문항/유형 초안 | 초안 + "심리학 검증 필요" 플래그 |
| coding | 구현 요구 + 코드 탐색 + DB 현황 | Rails 컨벤션 5단계 | TDD + 구현 코드 | 파일 목록 + 테스트 결과 |
| uiux | UX 요구 + 뷰 파일 + 콘텐츠 구조 | 감정/접근성 5단계 | Tailwind + Hotwire 구현 | 뷰 목록 + 접근성 결과 |

#### 오케스트레이터 SOP 마스터 섹션

오케스트레이터에 "SOP 마스터" 섹션 추가:
- 워커 스폰 시 Observe 재료 구성 (작업 목표, 참조 파일, 산출물 위치, 완료 기준, 이전 피드백)
- Share 산출물 확인 프로토콜 (Level 2 읽기 → confidence 확인 → 다음 단계 결정)

#### SOP와 평가루프 통합

생성 에이전트 1st: O→T→A→S(초안) → 검증 에이전트: O(초안+기준)→T(평가)→A(verdict)→S(evaluation) → fail시 생성 에이전트 재시도: O(원래지시+초안+피드백)→T(반영계획)→A(수정)→S(수정본). **재시도의 Observe가 이전 사이클의 모든 Share를 입력으로 받는다.**

### Caveats & Risks

- SOP 인코딩으로 프롬프트 길이 ~300-500 토큰 증가 — 컨텍스트 윈도우 모니터링 필요
- 에이전트가 SOP를 기계적으로 따르면서 창의성이 저하될 수 있음

### Summary

Analysis Framework을 O→T→A→S 4단계로 확장하면 에이전트 행동의 예측가능성이 높아지고, 인계/평가루프와 자연스럽게 통합된다.

---

## Perspective 3: 평가루프 종료 조건 & Human-in-the-Loop

### Status Analysis

현재 오케스트레이터의 Evaluation Loop Protocol은 `verdict: pass/fail/conditional_pass` + `max_iterations: 3`의 기본 골격을 갖추고 있으나, **판정 기준**, **conditional_pass 처리**, **점수 미개선 측정**, **HitL 개입 프로토콜**이 미정의.

### Detailed Findings

#### severity 기반 verdict 자동 판정

criteria에 `severity: blocker | major | minor` 필드 추가:

| fail 항목 유형 | verdict | 후속 처리 |
|--------------|---------|----------|
| 없음 | **pass** | 다음 단계 진행 |
| minor만 | **conditional_pass** | 1회 수정 후 자동 통과 |
| major 포함 | **fail** | 재생성 (iteration++) |
| blocker 포함 | **fail** | 재생성 + 우선 수정 대상 표시 |

#### 역할별 검증 기준 세트

**학술 검증 (PSY-01~07)**: 학술 근거 충족(blocker), 바넘 효과 부재(blocker), 결정론 배제(blocker), 구성 타당도(blocker), 변별력(major), 윤리 기준(major), 저작권(major).

**코드 검증 (CODE-01~05)**: 도메인 정합성(blocker), 테스트 커버리지(blocker), 엣지 케이스(major), Rails 컨벤션(major), 보안/PII(minor).

**UX 검증 (UX-01~06)**: 모바일 퍼스트(blocker), WCAG 접근성(blocker), 감정 흐름(blocker), 인지 부하(major), 문화적 적합(major), 부정적 감정 방지(minor).

#### overall_score + 점수 미개선 측정

`overall_score = count(pass) / count(total)`. 현재 score ≤ 이전 score이면 즉시 루프 중단 + HitL 트리거. 추가: 동일 criteria가 2회 연속 동일 fix_suggestion으로 fail이면 자동 수정 불가 판정.

#### conditional_pass 처리

minor fail만 있는 경우 → 1회 수정 지시(재평가 없이 자동 통과) + "나머지 변경 금지" 명시로 퇴행 방지.

#### HitL 7개 트리거

| # | 트리거 | 긴급도 |
|---|--------|-------|
| H1 | max_iterations 도달 (3회 fail) | 필수 |
| H2 | 점수 미개선 (2회 연속 동일/하락) | 필수 |
| H3 | 동일 criteria 2회 연속 동일 fix_suggestion으로 fail | 필수 |
| H4 | blocker에서 도메인 전문가 간 의견 충돌 | 높음 |
| H5 | 파괴적 작업 (DB 변경, 파일 삭제) | 필수 |
| H6 | 워크플로우 유형 불명확 | 높음 |
| H7 | 저작권/법적 판단 필요 | 높음 |

#### 개입 요청 포맷

구조화된 블록: (1) 상황 요약 1-2줄, (2) 반복 이력 테이블(iteration/score/변화), (3) 4개 선택지 — 현재 결과로 진행 / 수동 수정 후 재평가 / 워크플로우 중단 / 기준 완화.

#### 비용/품질 트레이드오프

- 1회 반복 = 오케스트레이터 4턴 + ~15K-38.5K 토큰 (~$0.10-0.25)
- 수확 체감: iter 1에서 30-50%, iter 2에서 10-20%, iter 3에서 0-10%
- maxTurns 30 하에서 Pattern C 최악: 22턴 (안전 마진 8턴)
- 워크플로우별 최적: 학술 콘텐츠 3회, 코드 2회, UX 1회

### Caveats & Risks

- severity 판정 자체도 LLM 추론에 의존 — 검증 에이전트의 severity 판정이 부정확할 수 있음
- HitL 개입이 빈번하면 자동화의 의미 감소

### Summary

severity 기반 verdict 자동 판정과 HitL 7개 트리거로 평가루프의 구체성과 안전성을 동시에 확보.

---

## Cross-Analysis

### Inter-Perspective Relationships

```
관점 2 (SOP)  ──Share 단계──→  관점 1 (인계 포맷)
     │                              │
     │ Think 체크리스트가             │ confidence/validation이
     │ 검증 기준의 미러                │ 평가 결과를 기록
     │                              │
     ▼                              ▼
관점 3 (평가루프)  ──verdict──→  관점 1 (인계 포맷)
```

### Common Patterns

1. 구조화 = 환각 방지 (3개 관점 모두)
2. frontmatter 4필드(summary, key_findings, confidence, next_steps)의 중심성 (관점 1, 2)
3. Think 단계 편중 — Observe/Share 부재 (관점 2, 3)

### Conflicting Items

| 항목 | 해결 |
|------|------|
| 인계 파일 Markdown body | YAML-only 유지 + full_document 참조로 원본 접근 |
| 릴레이 감쇠 적용 범위 | 파이프라인에만 적용, 평가루프에서는 원본 직접 접근 |

---

## Comprehensive Conclusion

### 핵심 발견 (우선순위 순)

1. **[Critical] R-015-F1: SOP O→T→A→S 4단계 명시적 인코딩** — Analysis Framework을 SOP 행동 루프로 확장. Observe(입력 읽기) + Think(기존 체크리스트) + Act(산출물 생성) + Share(인계+기록). 에이전트 행동 예측가능성 향상 + 인계 자동 통합. *(관점 2)*

2. **[Critical] R-015-F2: Share = 인계 통합 설계** — Share 단계 산출물의 frontmatter에 인계 필수 4필드(summary, key_findings, confidence, next_steps)를 포함시키면 별도 인계 파일 불필요. *(관점 1, 2)*

3. **[Critical] R-015-F3: severity 기반 verdict 자동 판정** — criteria에 severity(blocker/major/minor) 추가. blocker/major → fail, minor만 → conditional_pass(1회 수정 후 자동 통과). *(관점 3)*

4. **[High] R-015-F4: HitL 7개 트리거 + 구조화된 개입 포맷** — max_iterations 도달, 점수 미개선, 동일 실패 반복, 도메인 충돌, 파괴적 작업, 유형 불명확, 법적 판단. 상황 요약 + 이력 + 4개 선택지. *(관점 3)*

5. **[High] R-015-F5: 릴레이 감쇠 규칙** — 파이프라인에서 confidence 한 단계씩 감쇠. 3단계 이상 릴레이 시 원본 직접 확인 강제. 환각 캐스케이딩 구조적 차단. *(관점 1)*

6. **[High] R-015-F6: 역할별 검증 기준 세트** — PSY-01~07(학술), CODE-01~05(코드), UX-01~06(UX). 검증 에이전트에 명시적 체크리스트. *(관점 3)*

7. **[Medium] R-015-F7: overall_score + previous_iterations** — 점수 미개선 자동 감지를 위한 정량 지표. *(관점 3)*

8. **[Medium] R-015-F8: 오케스트레이터 SOP 마스터 섹션** — 워커 SOP의 입출력을 관리하는 메타 섹션. *(관점 2)*

## Unresolved Items

1. **에이전트의 severity 판정 정확도**: severity 자체가 LLM 추론에 의존하므로, 검증 에이전트가 blocker/major/minor를 올바르게 분류하는지는 실제 운영에서 확인 필요. *(구현 후 테스트로만 검증 가능)*

2. **SOP 인코딩 후 프롬프트 길이 영향**: 5개 에이전트에 Observe/Act/Share 섹션 추가 시 각 ~300-500 토큰 증가. 컨텍스트 윈도우 압박 여부는 실측 필요.

3. **conditional_pass의 "나머지 변경 금지" 강제력**: 프롬프트 레벨 지시이므로 에이전트가 무시할 수 있음. 구조적 강제는 불가.

## Referenced File List

| File Path | Related Perspective | Role/Content |
|-----------|-------------------|--------------|
| `.claude/agents/orchestrator.md` | 관점 2, 3 | 오케스트레이터 현재 구조 |
| `.claude/agents/psychology-expert.md` | 관점 2 | Analysis Framework 비교 |
| `.claude/agents/mbti-expert.md` | 관점 2 | Analysis Framework 비교 |
| `.claude/agents/enneagram-expert.md` | 관점 2 | Analysis Framework 비교 |
| `.claude/agents/coding-expert.md` | 관점 2 | Analysis Framework 비교 |
| `.claude/agents/uiux-expert.md` | 관점 2 | Analysis Framework 비교 |
| `.claude/work-orders/_templates/handover.yaml` | 관점 1 | 인계 템플릿 현황 |
| `.claude/work-orders/_templates/evaluation.yaml` | 관점 3 | 평가 템플릿 현황 |
| `docs/002_gemini_deep_research.md` | 관점 1, 2, 3 | MetaGPT SOP, 안티패턴, 가드레일 |
| `docs/001_gemini_deep_research.md` | 관점 2 | 5개 핵심 계층 |
| `docs/06_에이전트비평/001~006` | 관점 1 | 현행 산출물 패턴 |
| `docs/07_organizational_agents/004_Agent_오케스트레이터패턴.md` | 관점 3 | 평가루프 기존 설계 |
| `docs/07_organizational_agents/008_Research_조직아키텍처_오케스트레이터_최종.md` | 관점 3 | R-008-F6 |
