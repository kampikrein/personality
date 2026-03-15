# 오케스트레이션 프로토콜

이 문서는 다중 에이전트 조율 시에만 로딩한다. 핵심 위임 규칙은 CLAUDE.md에 있다.

---

# 워크플로우 패턴

| 패턴 | 설명 | 사용 시기 |
|------|------|----------|
| **A (파이프라인)** | 순차 실행 | DB 마이그레이션, 단순 기능 추가 |
| **B (평가루프)** | 생성→검증→재생성 (최대 3회) | 콘텐츠 학술 검증 |
| **C (하이브리드)** | 파이프라인 + 특정 단계 검증 | 새 문항, 유형 설명 (가장 빈번) |
| **D (단일 위임)** | 에이전트 1개 | 리팩터링, 단순 분석 |

# 에이전트 조합 가이드

| 작업 유형 | 주 에이전트 | 검증 에이전트 |
|----------|-----------|-------------|
| 문항 개발/유형 설명 | mbti 또는 enneagram | psychology |
| 점수 엔진/로직 | coding | psychology |
| UI 컴포넌트 (웹) | uiux | — |
| DB/API 구현 | coding | — |
| 콘텐츠 + 구현 복합 | 도메인 + coding | psychology |
| Flutter 모바일 UI | flutter | uiux (평가 모드) |
| 타로 카드/덱/스프레드 콘텐츠 | tarot | psychology |
| 모바일 + 서버 API 연동 | flutter + coding | — |
| 타로 해석 + 성격 유형 교차 | tarot + mbti/enneagram | psychology |

# 에이전트 스폰 프로토콜

Agent tool로 워커를 스폰할 때, 프롬프트에 **반드시 5가지** 포함:

1. **작업 목표**: 무엇을 생산해야 하는지
2. **참조 파일 경로**: 이전 산출물, 관련 데이터
3. **산출물 저장 위치**: `docs/{NN_카테고리}/{NNN_Type_제목}.md`
4. **완료 기준**: 어떤 상태가 되면 완료인지
5. **이전 피드백** (재작업 시): 이전 evaluation의 fix_suggestion

에이전트 완료 후: frontmatter(summary + key_findings)를 우선 읽고, 상세 필요시만 전체 읽기.

---

# 평가루프 프로토콜

## 핵심 규칙

- 최대 반복 3회. 초과 시 현재 최선 + 미해결 목록으로 진행
- blocker/major fail → 재생성 (iteration++). minor만 → 1회 수정 후 자동 통과
- 점수 미개선(2회 연속 동일/하락) → 즉시 중단, 사용자 개입 요청

## 평가 결과 포맷

검증 에이전트에게 아래 포맷으로 평가 결과를 작성하도록 지시한다:

```yaml
---
evaluation:
  verdict: pass | fail | conditional_pass
  iteration: 1
  max_iterations: 3
  evaluator: ""
  target_agent: ""
  overall_score: 0.0          # count(pass) / count(total)
  criteria:
    - name: "{기준명}"
      severity: blocker | major | minor
      status: pass | fail
      detail: "{상세 설명}"
      fix_suggestion: "{수정 제안}"  # fail인 경우만
  summary: "{1-2줄 종합 판단}"
  previous_iterations:
    - iteration: 1
      overall_score: 0.0
      verdict: ""
      failed_criteria: []
---
```

## severity 기반 verdict 판정

| fail 항목 유형 | verdict | 후속 처리 |
|--------------|---------|----------|
| 없음 | **pass** | 다음 단계 진행 |
| minor만 | **conditional_pass** | 1회 수정, 재평가 없이 자동 통과 |
| major 포함 | **fail** | 재생성 (iteration++) |
| blocker 포함 | **fail** | 재생성 + blocker 우선 수정 명시 |

---

# 검증 기준 (Role-Specific)

검증 에이전트 스폰 시, 작업 유형에 따라 아래 기준 세트를 프롬프트에 포함한다.

## 학술 검증 기준 (PSY) — psychology-expert

| ID | 기준 | severity |
|----|------|----------|
| PSY-01 | 모든 성격 관련 주장에 학술 근거(이론명, 연구자, 연도)가 인용됨 | blocker |
| PSY-02 | 바넘 효과 문구 없음 (모든 유형에 적용되는 보편적 서술 배제) | blocker |
| PSY-03 | 결정론적 서술 없음 (유형을 고정 라벨이 아닌 스펙트럼으로 다룸) | blocker |
| PSY-04 | 구성 타당도 충족 (측정 대상과 문항 내용 일치) | blocker |
| PSY-05 | 변별력 확보 (유형 간 유의미한 차이를 만드는 문항/서술) | major |
| PSY-06 | 윤리 기준 준수 (낙인, 병리화, 진단적 표현 배제) | major |
| PSY-07 | 저작권/상표권 안전 (공식 검사 문항·브랜드 표현 미사용) | major |

## 코드 검증 기준 (CODE) — coding-expert

| ID | 기준 | severity |
|----|------|----------|
| CODE-01 | 도메인 정합성 (도메인 전문가 설계와 코드 구현의 일치) | blocker |
| CODE-02 | 테스트 커버리지 (핵심 로직에 RSpec 테스트 존재) | blocker |
| CODE-03 | 엣지 케이스 처리 (nil, 빈 배열, 경계값 등) | major |
| CODE-04 | Rails 컨벤션 준수 (모델/컨트롤러/서비스 패턴) | major |
| CODE-05 | 보안/PII 기준 (개인정보 분리, 암호화, 인젝션 방지) | minor |

## UX 검증 기준 (UX) — uiux-expert

| ID | 기준 | severity |
|----|------|----------|
| UX-01 | 모바일 퍼스트 (375px 이상, 터치 타겟 44px+) | blocker |
| UX-02 | WCAG 2.1 AA 접근성 (색상 대비, 키보드, 스크린리더) | blocker |
| UX-03 | 감정 흐름 일관성 (해당 화면의 감정 단계에 맞는 UI 톤) | blocker |
| UX-04 | 인지 부하 최소화 (한 화면에 의사결정 1-2개 이하) | major |
| UX-05 | 문화적 적합성 (한국 사용자 UX 관습 준수) | major |
| UX-06 | 부정적 감정 방지 (결과 표현에서 불안/열등감 유발 배제) | minor |

## 타로 콘텐츠 검증 기준 (TAROT) — psychology-expert가 검증

| ID | 기준 | severity |
|----|------|----------|
| TAROT-01 | 예측적/결정론적 서술 없음 (내러티브 형식만 허용) | blocker |
| TAROT-02 | 진단적 표현 없음 (심리 진단, 의료 조언 배제) | blocker |
| TAROT-03 | 위기 상황 키워드 감지 시 전문 리소스 안내 포함 | blocker |
| TAROT-04 | 전통/현대 해석 구분이 명확함 | major |
| TAROT-05 | 카드 조합 맥락이 반영됨 (개별 의미 나열이 아닌 교차 해석) | major |
| TAROT-06 | 비표준 오라클 덱의 창작자 의도 존중 | minor |

## 기준 선택 가이드

| 검증 대상 | 적용 기준 | 검증 에이전트 |
|----------|----------|-------------|
| 문항/유형 설명 콘텐츠 | PSY 전체 | psychology-expert |
| 점수 계산/API 구현 | CODE 전체 | coding-expert 또는 psychology-expert |
| UI 컴포넌트/화면 (웹) | UX 전체 | uiux-expert |
| Flutter 모바일 화면 | UX 전체 + 타로 체크리스트 | uiux-expert (평가 모드) |
| 타로 카드/해석 콘텐츠 | TAROT 전체 | psychology-expert |
| 콘텐츠 + 구현 (복합) | PSY + CODE | psychology → coding 순차 |
| 타로 + 성격 교차 콘텐츠 | TAROT + PSY | psychology-expert |

---

# 사용자 개입 트리거

다음 상황에서 자동 진행을 중단하고 사용자에게 확인한다:
- 평가루프 3회 도달 또는 점수 미개선
- 파괴적 작업 (DB 마이그레이션, 파일 대량 삭제)
- 저작권/법적 판단이 필요한 콘텐츠
- 도메인 전문가 간 blocker 수준 의견 충돌

## 개입 요청 포맷

```
사용자 개입 요청

**상황**: {1-2줄 요약}

**반복 이력**:
| Iteration | Score | 변화 |
|-----------|-------|------|
| 1 | 0.43 | — |
| 2 | 0.43 | 미개선 |

**선택지**:
1. 현재 결과로 진행 (미해결 사항 목록 첨부)
2. 수동 수정 후 재평가
3. 워크플로우 중단
4. 기준 완화 (특정 criteria 삭제/severity 하향)
```

---

# SOP 워커 스폰 참조

워커 에이전트는 Observe → Think → Act → Share 루프를 따른다.

**릴레이 감쇠** (파이프라인 전용):
- 수신측 confidence는 원본보다 한 단계 낮게 시작 (high→medium→low)
- 3단계 이상 릴레이된 정보는 원본 직접 읽기 지시
- 평가루프 내에서는 감쇠 미적용
