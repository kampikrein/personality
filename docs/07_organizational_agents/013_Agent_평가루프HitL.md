---
id: "013"
title: "평가루프 종료 조건 & Human-in-the-Loop 분석"
category: agent
status: archived
created: 2026-03-14
summary: >
  평가/정제 루프의 자동 종료 판정 메커니즘과 사용자 개입 지점을 구체적으로 설계하기 위한 조사.
  현재 orchestrator.md와 evaluation.yaml의 가드레일을 분석하고, verdict 판정 기준 구체화,
  역할별 검증 기준 세트, conditional_pass 처리 방안, HitL 개입 프로토콜, 비용/품질 트레이드오프를 설계한다.
keywords: [agent-report, 평가루프, 종료조건, Human-in-the-Loop, verdict, 비용품질트레이드오프]
modules: [.claude/agents, .claude/work-orders]
---

# 평가루프 종료 조건 & Human-in-the-Loop 분석

## Progress
### Completed
- [x] orchestrator.md Evaluation Loop Protocol 분석
- [x] evaluation.yaml 템플릿 분석
- [x] docs/002_gemini_deep_research.md 가드레일/종료조건/HitL 추출
- [x] docs/07_organizational_agents/004_Agent_오케스트레이터패턴.md 평가루프 참조
- [x] R-008-F6 상세 확인
- [x] 역할별 검증 기준 세트 설계
- [x] conditional_pass 처리 방안
- [x] Human-in-the-Loop 개입 지점 식별
- [x] 비용/품질 트레이드오프 분석
### Remaining
- (없음)
### Current Status
조사 완료. 최종 보고서 작성됨.

## Summary

현재 평가루프 구조(orchestrator.md + evaluation.yaml)는 `verdict: pass/fail/conditional_pass`와 `max_iterations: 3`의 기본 골격을 갖추고 있으나, **무엇이 pass이고 무엇이 fail인지**, **conditional_pass를 어떻게 처리하는지**, **점수 미개선을 어떻게 측정하는지**, **사용자에게 언제 어떤 형태로 개입을 요청하는지**가 미정의 상태이다. 본 보고서는 이 네 가지 빈 공간을 구체적 설계로 채운다.

---

## Details

### 1. 현재 평가루프 구조 분석

#### 1.1 orchestrator.md의 Evaluation Loop Protocol 현황

| 항목 | 현재 정의 | 구체성 수준 | 개선 필요 |
|------|----------|-----------|----------|
| verdict 유형 | `pass / fail / conditional_pass` | 열거만 있음, 판정 기준 없음 | **높음** |
| max_iterations | 3 (하드코딩) | 명확 | 낮음 |
| 평가 기준 구조 | criteria[].name/status/detail/fix_suggestion | 포맷 명확 | 기준 세트 부재 |
| 점수 미개선 중단 | "이전 반복 대비 개선이 없으면 즉시 중단" | 측정 방법 미정의 | **높음** |
| 턴 예산 관리 | "전체 워크플로우에서 평가루프는 1개만" | 정책 수준 | 중간 |
| 3회 실패 후 | "현재 최선 결과 + 미해결 사항 목록으로 진행" | 절차 명시 | 낮음 |

**핵심 문제**: 오케스트레이터가 비판 에이전트의 반환에서 verdict를 "파싱"하여 루프를 제어하는데, 이 파싱은 프롬프트 레벨 추론에 의존한다. 비판 에이전트가 예상 포맷을 벗어나면 루프 제어가 실패할 수 있다.

#### 1.2 evaluation.yaml 템플릿 현황

현재 템플릿의 구조:

```yaml
evaluation:
  verdict: pass | fail | conditional_pass
  iteration: 1
  max_iterations: 3
  workflow_id: ""
  step: 0
  evaluator: ""
  target_agent: ""
  criteria:
    - name: ""
      status: pass | fail
      detail: ""
      fix_suggestion: ""
  summary: "{1-2줄 종합 판단}"
  previous_iterations: []  # 이전 반복의 verdict 이력
```

**관찰**: `previous_iterations` 필드가 존재하여 이력 추적의 기반이 있으나, overall_score 같은 정량 지표가 없어 "점수 미개선"을 측정할 구조적 기반이 부족하다.

#### 1.3 004 오케스트레이터 패턴 문서의 평가루프 설계 현황

004 문서(4.2절)에서 종료 조건 판정 규칙과 overall_score(예: 2/3) 개념이 이미 제안되었으나, orchestrator.md와 evaluation.yaml에는 반영되지 않았다. 핵심 격차:

| 004에서 제안 | orchestrator.md 반영 여부 |
|-------------|-------------------------|
| `overall_score: N/M` | 미반영 |
| conditional_pass → 1회 추가 수정 후 통과 | 미반영 (열거만 있음) |
| 단조 개선 감시 | "개선 없으면 중단"만 명시, 측정법 없음 |
| 턴 소비: 평가루프 1회 = 4-6턴 | 미반영 |

#### 1.4 R-008-F6 상세

> "[High] R-008-F6: 구조화된 평가 포맷으로 평가루프 품질 보장 — verdict: pass/fail + max_iterations: 3 + 기준별 상태 추적."

R-008-F6은 포맷의 존재를 확인한 수준이며, **판정 로직의 구체성**은 후속 연구(본 보고서)에서 다루어야 할 범위였다.

---

### 2. 종료 조건 상세 설계

#### 2.1 verdict 판정 기준 구체화

**pass의 정의**: 모든 criteria의 status가 `pass`이다.

**fail의 정의**: 하나 이상의 criteria가 `fail`이고, 해당 fail이 **블로커(blocker)** 수준이다.

**conditional_pass의 정의**: fail 항목이 있으나 모두 **경미(minor)** 수준이어서, 1회 수정으로 해결 가능하다.

이를 위해 criteria에 **severity** 필드를 추가한다:

```yaml
criteria:
  - name: "학술 근거 충족"
    status: pass | fail
    severity: blocker | major | minor  # 신규 필드
    detail: ""
    fix_suggestion: ""
```

**verdict 자동 판정 규칙** (오케스트레이터 프롬프트에 인코딩):

```
IF all criteria.status == pass:
    verdict = pass
ELIF any criteria has (status == fail AND severity == blocker):
    verdict = fail
ELIF all fail criteria have severity in {major, minor}:
    IF count(severity == major) == 0:
        verdict = conditional_pass
    ELSE:
        verdict = fail
```

요약 테이블:

| fail 항목 유형 | verdict | 후속 처리 |
|--------------|---------|----------|
| 없음 | **pass** | 다음 단계 진행 |
| minor만 | **conditional_pass** | 1회 수정 후 자동 통과 |
| major 포함, blocker 없음 | **fail** | 재생성 (iteration++) |
| blocker 포함 | **fail** | 재생성 (iteration++), 우선 수정 대상 표시 |

#### 2.2 역할별 검증 기준 세트

**A. 학술 검증용 (psychology-expert가 평가자)**

적용 대상: 문항 텍스트, 유형 설명, 점수 해석 로직

| 기준 ID | 기준명 | 판정 기준 | severity |
|---------|-------|----------|----------|
| PSY-01 | 학술 근거 충족 | 핵심 주장에 이론명+연구자+연도 인용 존재 | blocker |
| PSY-02 | 바넘 효과 부재 | "모든 유형에 해당 가능한" 표현 없음 | blocker |
| PSY-03 | 결정론적 표현 배제 | "~할 수밖에 없다", "항상 ~하다" 등 절대적 표현 없음 | major |
| PSY-04 | 구성 타당도 | 문항이 측정하려는 구성 개념과 논리적으로 연결됨 | blocker |
| PSY-05 | 변별력 | 대부분의 응답자가 한쪽으로 몰리지 않을 표현 | major |
| PSY-06 | 윤리 기준 준수 | 낙인/진단적 표현 없음, 자기이해 포지셔닝 부합 | blocker |
| PSY-07 | 저작권 준수 | 공식 검사 문항/브랜드 표현 미사용 | blocker |

**B. 코드 검증용 (psychology-expert 또는 coding-expert가 교차 평가)**

적용 대상: 점수 계산 로직, 프로필 생성 로직

| 기준 ID | 기준명 | 판정 기준 | severity |
|---------|-------|----------|----------|
| CODE-01 | 도메인 정합성 | 심리측정학적 가정(정규분포, 표본 크기 등)이 코드에 반영 | blocker |
| CODE-02 | 테스트 커버리지 | 핵심 로직에 RSpec 테스트 존재 | major |
| CODE-03 | 엣지 케이스 처리 | 빈 응답, 부분 응답, 경계값 처리 | major |
| CODE-04 | Rails 컨벤션 | 서비스 객체 패턴, 네이밍 컨벤션 준수 | minor |
| CODE-05 | 보안/PII | 점수 데이터의 PII 분리, 암호화 기준 충족 | blocker |

**C. UX 검증용 (uiux-expert가 평가자)**

적용 대상: 결과 표시 UI, 문항 응답 UI

| 기준 ID | 기준명 | 판정 기준 | severity |
|---------|-------|----------|----------|
| UX-01 | 모바일 퍼스트 | 터치 타겟 44px 이상, 스크롤 깊이 적절 | blocker |
| UX-02 | 접근성 WCAG 2.1 | 색상 대비 4.5:1, 키보드 네비게이션, 스크린리더 | blocker |
| UX-03 | 감정 흐름 적합 | 해당 단계의 감정 상태(호기심/몰입/발견/성찰)에 부합 | major |
| UX-04 | 인지 부하 | 한 화면에 과도한 정보 없음, 점진적 공개 | major |
| UX-05 | 문화적 적합 | 한국 MZ세대 UX 기대에 부합 | minor |
| UX-06 | 부정적 감정 방지 | 결과 표현이 불안/열등감을 유발하지 않음 | blocker |

#### 2.3 overall_score 계산 및 "점수 미개선" 측정

**overall_score 정의**:

```
overall_score = count(criteria where status == pass) / count(total criteria)
```

이를 evaluation.yaml에 추가:

```yaml
evaluation:
  # ... 기존 필드 ...
  overall_score: 0.67  # 2/3 = 0.67
  previous_iterations:
    - iteration: 1
      verdict: fail
      overall_score: 0.33
      failed_criteria: ["PSY-02", "PSY-05"]
```

**"점수 미개선" 판정 규칙**:

```
IF current.overall_score <= previous.overall_score:
    → 즉시 루프 중단 (개선 없음)
    → 현재 최선 결과 + 미해결 사항 목록으로 진행

IF current.overall_score > previous.overall_score BUT still fail:
    → 개선 있음, 재생성 계속 (iteration++ if < max)
```

추가 세이프가드: **동일 criteria가 2회 연속 fail이면서 fix_suggestion이 실질적으로 동일**하면, 해당 문제는 자동 수정 불가로 간주하고 HitL 개입 트리거.

---

### 3. conditional_pass 처리 방안

#### 3.1 처리 흐름

```
[비판 에이전트] → verdict: conditional_pass
  │
  ├── 오케스트레이터가 minor fail 목록 추출
  │
  ├── 생성 에이전트에 minor fix만 지시 (1회)
  │     └── "다음 항목만 수정하라: [minor fail 목록]. 나머지는 변경 금지."
  │
  └── 수정 후 재평가 없이 자동 통과
      └── 이유: minor 수정은 재검증 비용 > 위험
```

#### 3.2 conditional_pass의 제약

1. **conditional_pass 후 수정은 최대 1회**: 추가 반복 없음
2. **minor fix 지시에 "나머지 변경 금지"를 명시적으로 포함**: 생성 에이전트가 다른 부분을 건드려 퇴행(regression)하는 것을 방지
3. **conditional_pass는 iteration 카운트에 포함**: 즉, iteration 3에서 conditional_pass가 나오면, 수정 1회 후 자동 통과. 추가 루프 없음

#### 3.3 evaluation.yaml 확장

```yaml
evaluation:
  verdict: conditional_pass
  iteration: 2
  max_iterations: 3
  overall_score: 0.86  # 6/7 pass
  criteria:
    - name: "PSY-03"
      status: fail
      severity: minor
      detail: "'항상'이라는 표현이 1곳 남아있음"
      fix_suggestion: "'경향이 있다'로 교체"
  conditional_pass_instructions: |
    minor 수정만 수행하라:
    1. PSY-03: '항상'→'경향이 있다' 교체 (파일경로, 라인 명시)
    다른 부분은 변경하지 마라.
```

---

### 4. Human-in-the-Loop 개입 지점

#### 4.1 이론적 기반 (doc 002 추출)

docs/002_gemini_deep_research.md 6.3절의 핵심 원칙:

> "돌이킬 수 없고(Irreversible) 결과의 파급력이 거대한 '고위험(High-stakes)' 작업에 대해서는 에이전트의 완전 자율성을 허용해서는 안 된다."

> "에이전트 그룹은 Groundwork를 전담하지만, 실행 버튼을 누르기 직전 단계에서 워크플로우를 강제로 일시 정지(Pause)하고 인간 관리자에게 검토를 요청한다."

또한 orchestrator.md의 Red Lines에 이미:

> "사용자 확인 없이 파괴적 작업 금지: DB 변경, 파일 삭제 등은 사용자 확인 필수"

#### 4.2 HitL 개입 트리거 7가지

| # | 트리거 조건 | 이유 | 긴급도 |
|---|-----------|------|-------|
| H1 | max_iterations 도달 (3회 fail) | 자동 수정 한계 도달 | **필수** |
| H2 | 점수 미개선 (2회 연속 동일/하락) | 루프 수렴 실패 | **필수** |
| H3 | 동일 criteria가 2회 연속 동일 fix_suggestion으로 fail | 구조적 문제, 자동 수정 불가 | **필수** |
| H4 | blocker 기준에서 도메인 전문가 간 의견 충돌 | 예: psychology-expert가 fail 판정하나 mbti-expert가 필수라고 주장 | **높음** |
| H5 | 파괴적 작업 (DB 마이그레이션, 파일 삭제, 프로덕션 배포) | 되돌릴 수 없는 작업 | **필수** |
| H6 | 워크플로우 유형이 불명확하여 패턴 선택 불가 | 의사결정 트리의 "불명확?" 분기 | **높음** |
| H7 | 저작권/법적 판단이 필요한 경우 | PSY-07 fail이 반복되면 사용자의 법적 판단 필요 | **높음** |

#### 4.3 개입 요청 포맷

사용자에게 보여줄 구조화된 개입 요청:

```markdown
---
## [HUMAN INPUT REQUIRED] 평가루프 종료 판단 필요

**워크플로우**: WF-20260314-문항추가
**현재 상태**: 평가루프 iteration 3/3 — fail

### 상황 요약
MBTI 에너지(E-I) 도메인 5개 신규 문항에 대한 학술 검증에서
3회 반복 후에도 다음 기준이 미충족:

| 기준 | 상태 | 세부 |
|------|------|------|
| PSY-02 바넘 효과 부재 | fail (3회 연속) | 문항 3 "깊이 생각하는 편" |
| PSY-05 변별력 | fail → pass → fail | 문항 5 응답 편향 우려 |

### 반복 이력
| Iteration | Score | 변화 |
|-----------|-------|------|
| 1 | 4/7 (57%) | - |
| 2 | 5/7 (71%) | +14% |
| 3 | 5/7 (71%) | 0% (미개선) |

### 선택지
1. **현재 결과로 진행** — 미해결 사항을 기록하고 다음 단계로 (빠르지만 품질 타협)
2. **수동 수정 후 재평가** — 사용자가 문항을 직접 수정, 1회 추가 평가 실행
3. **워크플로우 중단** — 작업을 보류하고 추가 리서치 후 재시작
4. **기준 완화** — 해당 기준의 severity를 minor로 하향 조정 후 진행

어떤 선택지를 원하시나요? (1/2/3/4)
---
```

#### 4.4 개입 후 재개 프로토콜

| 사용자 선택 | 오케스트레이터 행동 | manifest 업데이트 |
|-----------|-----------------|-----------------|
| 1 (현재 결과로 진행) | 미해결 사항을 `_manifest.yaml`의 `unresolved_items`에 기록, 다음 step 진행 | `verdict: pass_with_exceptions` |
| 2 (수동 수정 후 재평가) | 사용자 수정 대기 → 수정 완료 후 비판 에이전트 1회 추가 스폰 | `iteration: 4` (예외적 허용) |
| 3 (워크플로우 중단) | manifest `status: suspended`, checkpoint에 재개 지시 기록 | `status: suspended` |
| 4 (기준 완화) | 해당 criteria의 severity를 minor로 변경, conditional_pass로 재판정 | verdict 재계산 |

#### 4.5 자동 진행 vs 사용자 위임 의사결정 트리

```
평가 결과 수신
  │
  ├── verdict == pass → 자동 진행 (사용자 개입 없음)
  │
  ├── verdict == conditional_pass → 자동 수정 1회 후 진행 (사용자 개입 없음)
  │
  ├── verdict == fail
  │     ├── iteration < max_iterations AND overall_score 개선 중
  │     │     → 자동 재생성 (사용자 개입 없음)
  │     │
  │     ├── iteration < max_iterations AND overall_score 미개선
  │     │     → HitL 트리거 H2 (사용자 개입)
  │     │
  │     ├── iteration == max_iterations
  │     │     → HitL 트리거 H1 (사용자 개입)
  │     │
  │     └── 동일 criteria 2회 연속 동일 fail
  │           → HitL 트리거 H3 (사용자 개입)
  │
  └── 파괴적 작업 포함 → HitL 트리거 H5 (항상 사용자 개입)
```

---

### 5. 비용/품질 트레이드오프

#### 5.1 평가루프 1회 반복의 턴/토큰 비용 추정

**1회 반복 = 생성 에이전트 1회 + 비판 에이전트 1회 + 오케스트레이터 판정**

| 구성 요소 | 오케스트레이터 턴 소비 | 추정 토큰 (입력+출력) |
|----------|-------------------|-------------------|
| 생성 에이전트 스폰 | 1턴 | ~3,000-8,000 (프롬프트 + 산출물) |
| 산출물 파일 읽기 (오케스트레이터) | 1턴 | ~1,000-2,000 |
| 비판 에이전트 스폰 | 1턴 | ~3,000-8,000 (프롬프트 + 평가) |
| 평가 결과 읽기 + 판정 | 1턴 | ~500-1,000 |
| **소계 (1회 반복)** | **4턴** | **~7,500-19,000** |

서브에이전트 내부 턴 소비 (별도 maxTurns 카운트):
- 생성 에이전트(sonnet): 내부 3-8턴 x ~1,500 tok/턴 = 4,500-12,000
- 비판 에이전트(sonnet): 내부 2-5턴 x ~1,500 tok/턴 = 3,000-7,500

**총 토큰 추정 (1회 반복)**: ~15,000-38,500 토큰

**비용 추정** (Sonnet 4 기준, 입력 $3/M + 출력 $15/M):
- 보수적: ~$0.10-0.25/반복
- 3회 반복: ~$0.30-0.75

#### 5.2 반복 횟수와 품질 개선의 수확 체감

| Iteration | 전형적 개선율 | 누적 비용 (턴) | 가치 판단 |
|-----------|-------------|---------------|----------|
| 1 | 큰 결함 수정 (30-50% 개선) | 4턴 | **높음** — 대부분의 구조적 문제 해결 |
| 2 | 중간 결함 수정 (10-20% 추가) | 8턴 | **중간** — 세부 조정, 표현 개선 |
| 3 | 미세 조정 (0-10% 추가) | 12턴 | **낮음** — 수확 체감 진입, 비용 대비 효과 하락 |
| 4+ | 거의 없음 또는 퇴행 위험 | 16+턴 | **비추천** — 자동 수정의 한계 |

**관찰**: 경험적으로 LLM 기반 평가루프에서 2회 이후 수확 체감이 급격히 진행된다. 3회는 안전 마진을 포함한 합리적 상한.

#### 5.3 워크플로우 유형별 최적 반복 횟수

| 워크플로우 유형 | 패턴 | 권장 max_iterations | 근거 |
|--------------|------|-------------------|------|
| 학술 콘텐츠 검증 (문항/유형설명) | B/C | **3** | blocker 기준(바넘, 학술근거)이 엄격, 재시도 가치 높음 |
| 코드 도메인 정합성 검증 | C | **2** | 코드 수정은 구체적 피드백에 즉시 반응, 2회면 충분 |
| UX 검토 | C | **1** | UX 피드백은 주관적 요소가 크고, 자동 재생성 효과 제한적 |
| 단순 포맷/스타일 검증 | B | **1** | conditional_pass로 처리 가능한 수준 |

#### 5.4 maxTurns 30 제약 하 현실적 한계

**시나리오 분석: Pattern C (하이브리드) — 가장 빈번한 패턴**

```
턴 예산 배분:
  초기화 (manifest 생성, 작업 분석): 2-3턴
  Step 1 생성 에이전트 스폰 + 결과 확인: 2턴
  Step 2 평가루프 (최대 3회):
    1회 반복: 4턴
    2회 반복: 4턴
    3회 반복: 4턴 = 최대 12턴
  Step 3 구현 에이전트 스폰 + 결과 확인: 2턴
  Step 4 UX 검토 (선택): 2턴
  종합 보고: 1-2턴

총: 2 + 2 + 12 + 2 + 2 + 2 = 22턴 (최악)
    2 + 2 + 4 + 2 + 2 + 2 = 14턴 (1회 통과)
```

**결론**:
- maxTurns 30에서 Pattern C + 평가루프 3회 = 22턴. 안전 마진 8턴.
- **평가루프 2개를 포함하는 워크플로우는 불가능**: 2개 루프 x 12턴 = 24턴 + 초기화/보고 = 30턴 초과
- 따라서 "전체 워크플로우에서 평가루프는 1개만"이라는 현재 가드레일은 정확하고 필수적

#### 5.5 비용 최적화 전략

1. **early exit**: 첫 번째 반복에서 overall_score >= 0.85이면 conditional_pass로 전환 검토
2. **선택적 재평가**: 전체 criteria 재평가 대신, 이전 fail 항목만 재검증 (비판 에이전트에 "이전 fail 항목만 재검증하라" 지시)
3. **severity 기반 우선순위**: blocker만 먼저 해결, major/minor는 후순위
4. **코드 검증은 2회로 제한**: coding-expert의 수정 능력이 높아 2회면 수렴

---

## Key Findings

1. **verdict 판정 기준이 미정의**: 현재 orchestrator.md에 pass/fail/conditional_pass가 열거만 되어 있고, "무엇이 pass인지"가 정의되지 않았다. severity 필드(blocker/major/minor) 추가와 판정 규칙의 명시적 인코딩이 필요하다.

2. **"점수 미개선" 측정 기반 부재**: evaluation.yaml에 overall_score 필드와 previous_iterations에 score 이력을 추가해야 단조 개선 감시가 가능하다. 현재는 "개선 없으면 중단"이라는 정책만 있고 측정 수단이 없다.

3. **conditional_pass는 "1회 수정 + 재평가 없이 자동 통과"로 처리**: minor fail만 있는 경우 추가 평가 루프 없이 수정 지시 후 진행하여 턴 예산을 절약한다.

4. **HitL 개입 트리거 7가지 식별**: max_iterations 도달, 점수 미개선, 동일 fail 반복, 도메인 충돌, 파괴적 작업, 패턴 불명확, 법적 판단. 이 중 H1/H2/H3/H5는 필수 개입.

5. **평가루프 1회 반복 = 오케스트레이터 4턴 + ~15,000-38,500 토큰**: 3회 반복 시 12턴 소비. maxTurns 30 하에서 Pattern C의 안전 마진은 8턴.

6. **수확 체감은 2회 이후 급격**: iteration 1에서 30-50% 개선, iteration 2에서 10-20%, iteration 3에서 0-10%. max_iterations 3은 합리적 상한이며, 워크플로우 유형에 따라 2 또는 1로 하향 조정 가능.

7. **역할별 검증 기준 세트 필요**: 학술 검증(PSY-01~07), 코드 검증(CODE-01~05), UX 검증(UX-01~06)으로 분류하여 비판 에이전트에 명시적 체크리스트를 제공해야 일관된 평가가 가능하다.

8. **HitL 개입 요청은 구조화된 포맷 필수**: 상황 요약, 반복 이력, 선택지(진행/수정/중단/완화)를 포함한 표준 포맷으로 사용자의 의사결정 부담을 최소화한다.

## Recommendations

### 즉시 반영 (orchestrator.md + evaluation.yaml 수정)

1. **evaluation.yaml에 severity 필드와 overall_score 추가**:
   ```yaml
   criteria:
     - name: ""
       status: pass | fail
       severity: blocker | major | minor  # 추가
       detail: ""
       fix_suggestion: ""
   overall_score: 0.0  # 추가
   previous_iterations:
     - iteration: 1
       verdict: fail
       overall_score: 0.33
       failed_criteria: ["PSY-02"]  # 추가
   ```

2. **orchestrator.md의 Evaluation Loop Protocol에 verdict 판정 규칙 인코딩**: 본 보고서 2.1절의 판정 규칙을 프롬프트에 명시.

3. **orchestrator.md에 HitL 트리거 조건 7가지와 개입 요청 포맷 추가**: 본 보고서 4.2~4.3절을 프롬프트에 인코딩.

4. **orchestrator.md에 "점수 미개선" 판정 규칙 추가**: `current.overall_score <= previous.overall_score`이면 즉시 중단 + HitL 트리거.

### 사이클 2에서 처리

5. **역할별 검증 기준 세트를 각 에이전트의 프롬프트에 인코딩**: psychology-expert의 PSY-01~07, coding-expert의 CODE-01~05, uiux-expert의 UX-01~06을 해당 에이전트 파일에 "평가자 역할 시 사용할 기준"으로 추가.

6. **워크플로우 유형별 max_iterations 차등화**: manifest.yaml 템플릿에 `evaluation.recommended_max_iterations` 필드를 추가하고, 워크플로우 유형에 따라 오케스트레이터가 자동 설정.

7. **HitL 개입 후 재개 프로토콜의 manifest 반영**: `status: suspended`, `resume_instruction`, `user_decision` 필드 확장.

## References

| 문서 | 참조 내용 | 경로 |
|------|----------|------|
| 오케스트레이터 에이전트 | Evaluation Loop Protocol, Red Lines, 패턴 A-D | `.claude/agents/orchestrator.md` |
| 평가 결과 템플릿 | verdict/criteria/previous_iterations 포맷 | `.claude/work-orders/_templates/evaluation.yaml` |
| manifest 템플릿 | 워크플로우 상태 관리, evaluation 섹션 | `.claude/work-orders/_templates/manifest.yaml` |
| 인계 파일 템플릿 | validation 섹션 | `.claude/work-orders/_templates/handover.yaml` |
| MAS 이론 리포트 | 2.5 평가/정제 루프, 6.3 HitL 패턴 | `docs/002_gemini_deep_research.md` |
| 오케스트레이터 패턴 매핑 | 4.1-4.4 평가루프 구현 방안, 종료 조건, 무한루프 방지 | `docs/07_organizational_agents/004_Agent_오케스트레이터패턴.md` |
| 연구 종합(R-008) | F6: 구조화된 평가 포맷 | `docs/07_organizational_agents/008_Research_조직아키텍처_오케스트레이터_최종.md` |
| 구현 계획(009) | maxTurns 30, 턴 예산, 평가루프 가드레일 | `docs/07_organizational_agents/009_Plan_오케스트레이터_아키텍처.md` |
| psychology-expert | Core Principles, Analysis Framework (검증 기준의 원천) | `.claude/agents/psychology-expert.md` |
| coding-expert | Core Principles, Analysis Framework | `.claude/agents/coding-expert.md` |
| uiux-expert | Core Principles, Analysis Framework | `.claude/agents/uiux-expert.md` |
