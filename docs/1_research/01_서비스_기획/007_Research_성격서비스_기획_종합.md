---
id: "007"
type: research
title: "성격서비스 기획 종합 리서치"
created: 2026-03-15
status: in-progress
summary: >
  기존 6개 기획 문서(001-006)와 비전 메모, 코드베이스를 종합 분석하여
  성격서비스의 기획 현황을 4개 관점에서 점검. 문서 간 갭/비일관성, 기술 구현 정합성,
  비즈니스 모델 구체화, 사용자 리텐션 전략을 도출한다.
keywords: [성격서비스, 기획종합, 갭분석, 비즈니스모델, 수익화, 리텐션, MVP, 코드베이스]
parallel_plan:
  total_perspectives: 4
  phases:
    - phase: 1
      perspectives: [1, 2, 3, 4]
      status: completed
      agent_numbers: ["008", "009", "010", "011"]
  synthesis_number: "012"
  final_number: "013"
---

# 성격서비스 기획 종합 리서치

## Research Overview

### Background & Motivation

personality 프로젝트는 "자기 이해와 타인 수용의 자유"를 철학으로 하는 성격 서비스를 구축 중이다.
2026년 2월부터 시작된 기획 과정에서 시장 비교(001), 법률 분석(002, 003), 프로젝트 철학(004),
법률우선 MVP 설계(005), IP 검증 스코프(006) 등 6개 문서가 생산되었고,
Rails 코드베이스(모델 15개, 서비스 19개), 5+1개 전문 에이전트 조직이 구현되었다.

그러나 이 문서들은 각기 다른 시점에 독립적으로 작성되어 **종합적 정합성 검증**이 이루어지지 않았다.
또한 구체적인 **비즈니스 모델**, **사용자 획득/리텐션 전략**, **기술 구현 갭**이 체계적으로 다뤄지지 않았다.

### Research Scope

기존 기획 문서 6개 + 비전 메모(docs/memo.md) + 비즈니스 프레임워크(docs/001_gemini_deep_research.md) +
코드베이스(app/models, app/services, app/controllers) + 에이전트 설계(docs/05_agent_design) +
코드 점검(docs/02_코드점검)을 모두 포괄하는 종합 분석.

### Research Perspectives

1. **기존 기획 문서 종합 & 갭 분석** — 6개 문서 + 메모 간 일관성, 중복, 모순, 미해결 항목 도출
2. **코드베이스 vs MVP 설계 정합성** — 005 Plan의 구성요소별 실제 구현 현황 매핑
3. **비즈니스 모델 & 수익화 전략** — 경쟁 서비스 분석 기반 구체적 수익화 경로 설계
4. **사용자 여정 & 리텐션 전략** — memo.md의 "성격 포탈" 비전을 UX 전략으로 구체화

---

## Preliminary Findings

### 기존 문서 구조 현황

| # | 문서 | 유형 | 핵심 내용 | 상태 |
|---|------|------|----------|------|
| 001 | MBTI 서비스 비교 | Research | 국내외 8개 MBTI 서비스 비교 분석 | 완료 |
| 002 | 저작권 법적보호 | Research | MBTI/애니어그램 IP 체계 심층 분석 | 완료 |
| 003 | 저작권 비용 QA | Research | 상업적 사용 비용 체계 정리 | 완료 |
| 004 | 프로젝트 철학 | Memo | 자기이해/타인수용/자유 + 방법론 | 완료 |
| 005 | 법률우선 MVP | Plan | 8주 로드맵, 구성요소 A-F 설계 | 초안 |
| 006 | 저작권/상표권 검증 | Scope | 6개 미검증 항목 식별 | 미완료 |

### 코드베이스 현황

**모델 (15개)**: anonymous_session, user, consent, question_set, question, response,
personality_type, profile, deletion_request, audit_log, assessment, domain_score, insight, alert, application_record

**서비스 (19개)**:
- Scoring (5): domain_calculator, normalizer, type_classifier, reliability_adjuster, policy_checker
- Insights (7): explanation_builder, collaboration_module, conflict_module, learning_module, career_module, recovery_module, context_engine
- Compliance (3): text_policy_filter, deletion_processor, restricted_terms
- Quality (2): bot_detector, speed_analyzer
- Profiles (3): composer, type_content_service, tone_filter

### 초기 관찰

1. **철학-설계 갭**: 004의 철학("저작권 우회", "서서히 뺏어오는 서비스")과 005의 설계("법적 경계 원칙")는
   방향이 일치하지만, memo.md의 비전("캐릭터", "커뮤니티", "소셜")은 005 MVP 범위에 없음
2. **006 미완료**: 저작권/상표권 검증 6개 항목이 아직 실행되지 않음
3. **코드-설계 매핑 미확인**: 005의 구성요소(A-F)가 코드에 어느 정도 구현되었는지 체계적 확인 필요

---

## Parallel Execution Instructions

### Perspective 1: 기존 기획 문서 종합 & 갭 분석

**목표**: docs/01_성격서비스_기획/ 폴더의 6개 문서(001-006) + docs/memo.md + docs/001_gemini_deep_research.md를
모두 읽고 종합하여, 문서 간 일관성·모순·중복·미해결 항목을 체계적으로 분류.

**구체적 분석 대상**:
1. 각 문서의 핵심 주장/결론을 1-2문장으로 요약
2. 문서 간 모순되는 주장 식별 (예: 004 "저작권 우회" vs 005 "법적 경계 원칙"의 실질적 차이)
3. 006의 6개 미검증 항목 현재 상태 확인
4. 기존 문서에서 다루지 않은 주제 영역 목록화
5. memo.md의 비전 항목 중 기존 기획 문서에 반영되지 않은 것들

**파일 경로**:
- docs/01_성격서비스_기획/001_Research_MBTI_서비스_비교.md
- docs/01_성격서비스_기획/002_Research_저작권_법적보호_조사.md
- docs/01_성격서비스_기획/003_Research_저작권_비용_Gemini_QA.md
- docs/01_성격서비스_기획/004_Memo_프로젝트_철학.md
- docs/01_성격서비스_기획/005_Plan_법률우선_MVP_설계.md
- docs/01_성격서비스_기획/006_Scope_저작권상표권_검증.md
- docs/memo.md
- docs/001_gemini_deep_research.md

### Perspective 2: 코드베이스 vs MVP 설계 정합성

**목표**: 005_Plan_법률우선_MVP_설계.md의 구성요소 A-F 각각에 대해,
실제 코드베이스(app/models, app/services, app/controllers, db/schema.rb, config/routes.rb, test/)의
구현 현황을 매핑하고, 미구현/부분구현/완료 상태를 판별.

**구체적 분석 대상**:
1. **A. 문항 엔진**: question_set, question 모델 + 관련 서비스. 버전 관리(qset_v1/v2) 구현 여부
2. **B. 점수 엔진**: scoring/ 서비스 5개. 0-100 정규화, 신뢰도 보정, 벡터 저장 구현 여부
3. **C. 프로필 컴포저**: profiles/ 서비스 3개. 강점/주의패턴/권장행동 구현 여부
4. **D. 인사이트 모듈**: insights/ 서비스 7개. 5개 맥락 모듈(협업/갈등/학습/커리어/회복) 매핑
5. **E. 신뢰/컴플라이언스**: compliance/ 서비스 3개. 익명 옵션, 고지, 삭제 요청 구현 여부
6. **F. 품질 운영**: quality/ 서비스 2개. 대시보드, 경보, 봇 탐지 구현 여부
7. **데이터 흐름**: 005 §4의 6단계 흐름이 실제로 작동하는지 (라우트, 컨트롤러, 뷰)
8. **DB 스키마**: db/schema.rb 또는 db/migrate/ 확인 — PII 분리, 동의 이력 구현 여부

**파일 경로**:
- docs/01_성격서비스_기획/005_Plan_법률우선_MVP_설계.md
- docs/02_코드점검/004_Synthesis_교차검증_종합.md
- docs/02_코드점검/005_Plan_수정계획.md
- app/models/*.rb (15개)
- app/services/**/*.rb (19개)
- app/controllers/**/*.rb
- db/schema.rb 또는 db/migrate/
- config/routes.rb
- test/ 또는 spec/

### Perspective 3: 비즈니스 모델 & 수익화 전략

**목표**: 004/memo.md의 비전과 001의 경쟁 서비스 분석을 기반으로,
이 성격 서비스의 구체적 수익화 경로를 설계.

**구체적 분석 대상**:
1. **경쟁 서비스 수익 모델 분류**: 001에서 분석된 8개 서비스의 수익 모델 재정리
   - 프리미엄(freemium), 광고, 유료 리포트, 기업 B2B, 코칭, 데이터 판매
2. **이 서비스의 차별화 가능한 수익 경로**:
   - memo.md의 비전: "고급 성격 서비스", "커뮤니티", "타로/사주 확장"
   - 005의 제약: "AI 진단 서사 없음", "소셜/바이럴 없음", "마켓플레이스 없음" (MVP 한정)
3. **단계별 수익화 로드맵**:
   - Phase 1 (MVP): 무료 검사 → 트래픽 확보
   - Phase 2: 프리미엄 인사이트 → 개인화 → 유료 전환
   - Phase 3: 커뮤니티/소셜/캐릭터 → 구독 모델
   - Phase 4: B2B/기업 솔루션 → 규모 수익
4. **법률 제약과 수익화의 교차점**: 002/003의 법률 분석이 수익화에 미치는 영향
5. **KPI 프레임워크 확장**: 005 §8의 신뢰 우선 KPI에 수익/성장 KPI 보완

**참고 파일**:
- docs/01_성격서비스_기획/001_Research_MBTI_서비스_비교.md (경쟁 서비스 수익 모델)
- docs/01_성격서비스_기획/004_Memo_프로젝트_철학.md (비전)
- docs/01_성격서비스_기획/005_Plan_법률우선_MVP_설계.md (MVP 제약)
- docs/memo.md (확장 비전)
- docs/001_gemini_deep_research.md (비즈니스 프레임워크)

### Perspective 4: 사용자 여정 & 리텐션 전략

**목표**: memo.md의 "성격 포탈" 비전을 체계적 사용자 여정으로 구체화하고,
리텐션(재방문/중독) 메커니즘을 설계.

**구체적 분석 대상**:
1. **사용자 여정 매핑** (As-Is vs To-Be):
   - As-Is: 검사 → 결과 → 이탈 (일반 성격 서비스 패턴)
   - To-Be: 검사 → 결과 → 인사이트 탐색 → 캐릭터 대화 → 커뮤니티 → 재검사
2. **리텐션 레버**:
   - memo.md 키워드: "스와이프", "쇼츠처럼", "중독", "호기심과 기대감"
   - 구체화: 일일 성격 인사이트, 상황별 조언, 성격 매칭, 성장 트래킹
3. **캐릭터 시스템 설계**:
   - memo.md: "메인 캐릭터", "대화를 나누는 캐릭터", "각 페르소나"
   - 단계별: Phase 1 규칙 기반 → Phase 2 AI 에이전트 개인화
4. **커뮤니티 전환 전략**:
   - memo.md: "소셜", "교감", "공동체", "커뮤니티 그룹"
   - 성격 유형 기반 그룹, 고민 공유, 멘토링
5. **MVP 제약과 비전의 조화**: 005의 "비목표"와 장기 비전의 우선순위 정리

**참고 파일**:
- docs/memo.md (비전의 핵심 소스)
- docs/01_성격서비스_기획/004_Memo_프로젝트_철학.md
- docs/01_성격서비스_기획/005_Plan_법률우선_MVP_설계.md (MVP 범위/비목표)
- docs/001_gemini_deep_research.md (JTBD, 블루오션 프레임워크)
- app/services/insights/ (현재 인사이트 모듈 구현 현황)

---

## Remaining Work

- [ ] Perspective 1: 기존 기획 문서 종합 & 갭 분석
- [ ] Perspective 2: 코드베이스 vs MVP 설계 정합성
- [ ] Perspective 3: 비즈니스 모델 & 수익화 전략
- [ ] Perspective 4: 사용자 여정 & 리텐션 전략
- [ ] Cross-Analysis
- [ ] Comprehensive Conclusion
