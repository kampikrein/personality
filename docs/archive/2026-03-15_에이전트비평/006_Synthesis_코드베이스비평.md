---
id: "006"
title: "코드베이스 비평 — 5개 전문 에이전트 종합 보고서"
category: report
status: archived
created: 2026-03-13
summary: >
  5개 전문 에이전트(심리학·MBTI·애니어그램·코딩·UI/UX)가 personality 코드베이스를 병렬 비평.
  서브에이전트 모드, 각 에이전트 sonnet 모델. 3개 에이전트가 독립적으로 발견한 "recovery 도메인명"
  문제를 필두로, 인사이트 모듈 점수 해석 오류, Fat Controller, 접근성 전반 미달 등 핵심 과제를 도출.
keywords: [parallel-synthesis, analyze, 코드비평, 심리학, mbti, 애니어그램, rails, uiux]
modules: [scoring, insights, profiles, compliance, views, controllers, models]
---

# 코드베이스 비평 — 5개 전문 에이전트 종합 보고서

## Team Composition & Individual Reports

| # | 역할 | Agent Type | 보고서 | 상태 |
|---|------|-----------|--------|------|
| 1 | 심리학 전문가 | general-purpose (sonnet) | [001_Agent_심리학비평.md](./001_Agent_심리학비평.md) | 완료 |
| 2 | MBTI 전문가 | general-purpose (sonnet) | [002_Agent_MBTI비평.md](./002_Agent_MBTI비평.md) | 완료 |
| 3 | 애니어그램 전문가 | general-purpose (sonnet) | [003_Agent_애니어그램비평.md](./003_Agent_애니어그램비평.md) | 완료 |
| 4 | 코딩 전문가 | general-purpose (sonnet) | [004_Agent_코딩비평.md](./004_Agent_코딩비평.md) | 완료 |
| 5 | UI/UX 전문가 | general-purpose (sonnet) | [005_Agent_UIUX비평.md](./005_Agent_UIUX비평.md) | 완료 |

---

## Cross-Analysis

### 공통 발견사항 — 3개 이상 에이전트가 독립 발견

#### 1. "recovery" 도메인명 문제 (심리학 + MBTI + 애니어그램)

가장 강력한 교차 발견. 세 에이전트가 **서로 다른 근거**로 동일한 결론에 도달했다.

| 에이전트 | 발견 근거 | 핵심 주장 |
|---------|----------|----------|
| **심리학** | P/J축은 "계획성-유연성"이지 "회복"이 아님. 인사이트 3개 모듈이 recovery 점수를 감정 회복 속도로 오해석 | 도메인명을 `planning_style`로 변경 |
| **MBTI** | MBTI 4축과 1:1 대응하여 독자 체계 주장이 취약. `recovery`가 `recovery_style` 콘텐츠 필드와 동명이의어 충돌 | 도메인명을 `rhythm_style`로 변경 |
| **애니어그램** | 애니어그램에서 recovery는 통합(integration) 방향 이동인데, 현재는 단순 에너지 충전 수준 | 더 깊은 성장 개념 필요 |

**리드 판단**: recovery 도메인명은 **코드베이스 전체의 개념 혼선 원인**이며, 인사이트 모듈의 점수 해석 오류를 유발하는 근본 원인이다. 이름 변경이 최우선 과제.

---

#### 2. suggested_actions / 인사이트 콘텐츠 품질 부족 (심리학 + MBTI + 애니어그램)

| 에이전트 | 발견 |
|---------|------|
| **심리학** | 인사이트 모듈 3개에서 점수 해석 방향 역전. `decision_making` 높은 점수(=N)에 "구조적 학습" 권고 |
| **MBTI** | `Composer#suggested_actions`가 영어 접두사("In teamwork: ...") 직접 생성 — 한국어 서비스에서 UX 버그 |
| **애니어그램** | suggested_actions가 PersonalityType 텍스트를 레이블만 붙여 재출력 — 실질적 "행동 제안"이 아님 |

**리드 판단**: 인사이트/추천행동 레이어는 **구조는 잘 설계되었으나 콘텐츠가 미완성**. 점수 해석 방향 수정(심리학), 영어 접두사 한국어화(MBTI), 동기 기반 성장 제안 추가(애니어그램)가 모두 필요.

---

#### 3. 결과 공유 기능 부재 (MBTI + UI/UX)

| 에이전트 | 발견 |
|---------|------|
| **MBTI** | 한국 MBTI 문화의 핵심인 "공유"와 "궁합" 콘텐츠 전무 — 전략적 공백 |
| **UI/UX** | 결과 공유(SNS) 기능 없음 — 한국 MZ의 바이럴 기회 손실. 카카오 공유 SDK 연동 권장 |

**리드 판단**: 비즈니스 성장을 위한 **가장 즉각적인 기능 추가** 후보.

---

### 상충 의견

#### 도메인명 변경 방향

- **심리학**: `planning_style` 또는 `structure_preference` (심리측정학적 정확성 우선)
- **MBTI**: `rhythm_style` (독자성·브랜딩 우선)
- **애니어그램**: 도메인명 자체보다 콘텐츠 깊이가 중요

**리드 판단**: 네 도메인 모두 동시에 재명명하는 것이 일관성 확보에 유리. MBTI 에이전트의 제안(`connection_mode`, `focus_style`, `value_base`, `rhythm_style`)이 독자성과 직관성의 균형이 가장 좋다. 단, 심리학 에이전트의 "측정 구성개념을 반영해야 한다"는 원칙을 존중하여 최종 결정 시 두 관점을 절충할 것.

---

### 시너지 효과 — 개별 보고서 결합으로 도출된 새 통찰

#### 1. "recovery 오해석" → Fat Controller → 접근성 부재의 연쇄

심리학(recovery 점수 오해석) + 코딩(파이프라인이 컨트롤러에 위치) + UI/UX(스펙트럼 바 의미 설명 부재)가 결합되면:

> 잘못된 개념(recovery=회복)이 → 테스트 없는 컨트롤러 파이프라인을 통해 → 의미 설명 없이 사용자에게 전달된다.

이 3단계 연쇄를 끊으려면 **서비스 추출 → 점수 해석 수정 → UI 설명 보강**을 함께 진행해야 한다.

#### 2. caution_patterns의 다면적 개선 기회

- **심리학**: 자기예언적 효과 위험 → 성찰 질문 형식으로 전환
- **애니어그램**: 건강 수준 개념 도입 → "스트레스 상황에서" 맥락화
- **MBTI**: 경쟁사 대비 차별화 → "이럴 때 특히 주의" 서사 추가
- **UI/UX**: trust_notice 위치 재배치로 성찰 감정 마무리 개선

4개 관점을 결합하면: caution_patterns를 **맥락화된 성찰 질문 + 건강 수준 프레임**으로 재설계하고, trust_notice를 접이식으로 이동하여 **성찰 → 긍정적 CTA**로 마무리하는 종합 개선안이 도출된다.

#### 3. Composer#suggested_actions의 근본 재설계

- **MBTI**: 영어 접두사 한국어화
- **애니어그램**: PersonalityType 텍스트 재출력이 아닌 실질적 성장 행동
- **심리학**: 점수 기반 분기(>=75, <=25)의 임계값 근거 문서화 필요
- **코딩**: Composer 내 하드코딩된 문자열을 i18n 또는 별도 콘텐츠 소스로 분리

결합 결론: suggested_actions를 **점수 기반 동적 생성 + 동기 연결 + 한국어 네이티브**로 재설계해야 한다.

---

## Comprehensive Conclusion

### 핵심 발견 (우선순위 순)

1. **[Critical] recovery 도메인명과 인사이트 점수 해석 오류** — 3개 에이전트 교차 발견. P/J축을 "회복"으로 명명하여 ConflictModule, RecoveryModule, CareerModule이 감정 회복 속도로 오해석. LearningModule과 CollaborationModule에서 decision_making 분기 방향도 역전. *(심리학, MBTI, 애니어그램)*

2. **[Critical] Fat Controller (ResultsController)** — 50줄 8단계 파이프라인이 컨트롤러에 위치. SRP 위반, 단위 테스트 불가, rescue 내 이중 렌더 위험. `Scoring::AssessmentPipeline` 서비스로 이전 필요. *(코딩)*

3. **[Critical] 접근성(WCAG 2.1) 전반 미달** — 스펙트럼 바, 인사이트 탭, 라이커트 폼 모두 ARIA 없음. `text-warm-gray/60` 색상 대비 4.5:1 미달. `prefers-reduced-motion` 미지원. *(UI/UX)*

4. **[High] 보안 — 세션 고정 공격 + Admin HTTP Basic** — `reset_session` 미호출, Admin 전체가 HTTP Basic만으로 보호. *(코딩)*

5. **[High] Tailwind 동적 클래스 purge 위험** — `bg-<%= domain_colors[...] %>` 패턴으로 `lavender` 관련 클래스가 빌드에서 제거될 수 있음. *(UI/UX)*

6. **[High] 콘텐츠 품질 — 행동 묘사만, 동기 부재** — 16유형 설명 100%가 행동 묘사 수준. 내면 동기/두려움/핵심 욕구 0건. suggested_actions에 영어 접두사 혼입. *(애니어그램, MBTI)*

7. **[High] 테스트 공백** — 12개 컨트롤러 request spec 없음, 다수 모델 spec 없음, Insights 개별 모듈 spec 없음. *(코딩)*

8. **[High] ConsentsController 파라미터 버그** — `:version` vs `consent_version` 불일치로 consent_version 업데이트 불가. *(코딩)*

9. **[Medium] reliability_adjuster split-half 알고리즘 결함** — 5문항 홀/짝 분할 시 position 5 버려짐. *(심리학)*

10. **[Medium] 동의 페이지 정보 빈곤 + 결과 공유 부재** — 신뢰 구축 실패 + 바이럴 기회 손실. *(UI/UX, MBTI)*

11. **[Medium] Stimulus 컨트롤러 3개 미완성** — `type_reveal`, `questionnaire`, `autosave` 빈 메서드 상태. *(UI/UX)*

12. **[Medium] 캐릭터명 3개 문법/뉘앙스 문제** — "따뜻한 이끌림", "자유로운 무대", "고요한 몽상가". *(MBTI)*

### Recommended Actions

#### Phase 1: 긴급 수정 (기능 오류 + 보안)

| # | 작업 | 근거 에이전트 | 예상 영향 |
|---|------|-------------|----------|
| 1 | `recovery` 도메인명 변경 + 인사이트 점수 해석 수정 | 심리학+MBTI+애니어그램 | 사용자에게 잘못된 조언 제공 차단 |
| 2 | `ResultsController#run_scoring_pipeline!` → `Scoring::AssessmentPipeline` 서비스 이전 | 코딩 | 테스트 가능성·유지보수성 확보 |
| 3 | `SessionsController`에 `reset_session` 추가 | 코딩 | 세션 고정 공격 방어 |
| 4 | `ConsentsController` 파라미터명 수정 (`:version` → `:consent_version`) | 코딩 | 실질 버그 해소 |
| 5 | `Composer#suggested_actions` 영어 접두사 한국어화 | MBTI | 사용자 대면 UX 버그 해소 |

#### Phase 2: 접근성 + 테스트 (품질 기반)

| # | 작업 | 근거 에이전트 |
|---|------|-------------|
| 6 | 스펙트럼 바/인사이트 탭/라이커트 폼 ARIA 추가 | UI/UX |
| 7 | `text-warm-gray/60` 색상 대비 개선 | UI/UX |
| 8 | 컨트롤러 request spec 추가 (Results, Consents, DeletionRequests) | 코딩 |
| 9 | Tailwind 동적 클래스 safelist 등록 | UI/UX |
| 10 | `reliability_adjuster` split-half 알고리즘 수정 | 심리학 |

#### Phase 3: 콘텐츠 고도화 (차별화)

| # | 작업 | 근거 에이전트 |
|---|------|-------------|
| 11 | 16유형 콘텐츠에 동기/두려움/성장방향 레이어 추가 | 애니어그램 |
| 12 | caution_patterns 맥락화 + 성찰 질문 형식 전환 | 심리학+애니어그램 |
| 13 | 캐릭터명 3개 교정 | MBTI |
| 14 | 결과 공유 기능 (링크 복사 + 카카오 공유) | MBTI+UI/UX |
| 15 | 동의 페이지 정보 보강 | UI/UX |

---

## References

- [001_Agent_심리학비평.md](./001_Agent_심리학비평.md) — 심리측정학적 타당성, 문항 분석, 점수 해석 오류
- [002_Agent_MBTI비평.md](./002_Agent_MBTI비평.md) — 법적 안전성, 독자성, 문화 적합성, 경쟁사 분석
- [003_Agent_애니어그램비평.md](./003_Agent_애니어그램비평.md) — 성장 지향, 동기 기반, 통합 가능성
- [004_Agent_코딩비평.md](./004_Agent_코딩비평.md) — Rails 코드 품질, 아키텍처, 테스트, 보안
- [005_Agent_UIUX비평.md](./005_Agent_UIUX비평.md) — 감정 흐름, 접근성, 모바일, 한국 UX
