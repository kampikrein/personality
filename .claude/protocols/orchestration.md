# 오케스트레이션 프로토콜 (통합)

이 문서는 에이전트 조율 시에만 로딩한다. 핵심 위임 규칙은 CLAUDE.md에 있다.
단일 위임(D)부터 병렬 실행(E)까지, 모든 에이전트 사용 패턴을 이 프로토콜이 통합 관할한다.

## 아키텍처 진화 기록

| 시점 | 변경 | 근거 |
|------|------|------|
| 초기 설계 (docs/07 001-017) | `.claude/agents/orchestrator.md` 별도 에이전트 + `.claude/work-orders/` 인프라 | MAS 이론 기반 명시적 상태 관리 |
| 현재 | CLAUDE.md 위임 판단 + 이 프로토콜 (지연 로딩) + `docs/` 산출물 중심 | 토큰 절약(~2,500 vs ~8,000), 단순화, work-orders 상태 추적은 docs/ 산출물이 대체 |

**핵심 보존**: 패턴 A-D, SOP(O→T→A→S), severity 기반 평가루프, 페르소나, 기억 체계.
**합리적 확장**: 패턴 E 신설, TAROT 검증 기준, 에이전트 5→7개 확대.
**의도적 제거**: work-orders 디렉터리, manifest.yaml, handover.yaml — docs/ 산출물 프로토콜이 기능 대체.

---

# 워크플로우 패턴

| 패턴 | 설명 | 사용 시기 | 실행 모드 |
|------|------|----------|----------|
| **A (파이프라인)** | 순차 실행 | DB → 서비스 → 뷰, 단순 기능 추가 | 단일/순차 스폰 |
| **B (평가루프)** | 생성→검증→재생성 (최대 3회) | 콘텐츠 학술 검증 | 단일/순차 스폰 |
| **C (하이브리드)** | 파이프라인 + 특정 단계 검증 | 새 문항, 유형 설명 (가장 빈번) | 단일/순차 스폰 |
| **D (단일 위임)** | 에이전트 1개 | 리팩터링, 단순 분석 | 단일 스폰 |
| **E (병렬 실행)** | 독립 작업 동시 실행 + 종합 | 다관점 분석, 복합 구현, 가설 경쟁 | 서브에이전트 / Agent Teams |

## 패턴 선택 기준

| 상황 | 패턴 |
|------|------|
| 에이전트 1개로 완결 | D |
| 순서가 있는 2+ 에이전트 | A |
| 생성물 품질 검증 필요 | B |
| 순차 + 특정 단계 검증 | C |
| 독립적 작업 2+ 동시 실행 | E |
| A~C 중 독립 단계가 있음 | 해당 단계만 E로 병렬화 |

---

# 실행 모드 결정 (패턴 E)

패턴 E 선택 시, 아래 기준으로 서브에이전트 / Agent Teams를 결정한다.

| 작업 특성 | 실행 모드 | 이유 |
|----------|----------|------|
| 단순 조사·분석 (독립 관점) | **서브에이전트** | 팀 조율 오버헤드 불필요, 토큰 절약 |
| 복합 구현 (다층·다파일) | **Agent Teams** | 파일 충돌 방지, 의존성 관리 |
| 다관점 리뷰 | **Agent Teams** | 토론·반론을 통한 품질 향상 |
| 가설 경쟁 디버그 | **Agent Teams** | 앵커링 편향 방지, 가설 간 토론 |
| 독립 파일·모듈 분석 | **서브에이전트** | 독립 결과 수집으로 충분 |

**결정 규칙**: 조사·분석 → 서브에이전트. 구현·리뷰·디버그 → Agent Teams. 혼합 → 구현 포함 시 Agent Teams, 아니면 서브에이전트.

**Agent Teams 전제조건**:
```json
// settings.json
{ "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" } }
```
비활성 환경에서는 자동으로 서브에이전트 모드로 폴백.

---

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
| 다관점 분석/리뷰 (병렬) | 관점별 에이전트 배정 | — (종합 보고서로 대체) |

---

# 에이전트 스폰 프로토콜

Agent tool로 워커를 스폰할 때, 프롬프트에 아래 항목을 포함한다.
워크플로우 패턴에 따라 필수/선택이 다르다.

## 공통 필수 (모든 패턴 D~E)

| # | 항목 | 설명 |
|---|------|------|
| 1 | **작업 목표** | 무엇을 생산해야 하는지 |
| 2 | **참조 파일 경로** | 이전 산출물, 관련 데이터 |
| 3 | **산출물 저장 위치** | `docs/{NN_카테고리}/{NNN_Type_제목}.md` |
| 4 | **완료 기준** | 어떤 상태가 되면 완료인지 |
| 5 | **이전 피드백** | (재작업 시) 이전 evaluation의 fix_suggestion |
| 6 | **산출물 프로토콜** | 아래 "에이전트 산출물 프로토콜" 지침 전문 |

## 패턴 E 추가 필수

| # | 항목 | 설명 |
|---|------|------|
| 7 | **Your Scope** | 이 멤버의 담당 범위 + 수정 가능 파일 |
| 8 | **NOT Your Scope** | 다른 멤버들의 범위 요약. 이 영역 파일은 절대 수정 금지 |
| 9 | **프로젝트 컨텍스트** | CLAUDE.md 요약, 관련 파일 경로, 기존 코드 패턴 |
| 10 | **Coordination Rules** | SendMessage 규칙 + Communication Log 기록 지침 |

### 패턴 E — Coordination Rules 표준 텍스트

```
## Coordination Rules
- 다른 멤버의 작업에 영향을 주는 의존성 발견 시, 메시지로 알린다
- 예상치 못한 이슈 발견 시, 팀 전체에 즉시 브로드캐스트한다
- 작업 완료 시 TaskUpdate로 상태를 completed로 변경한다
- **SendMessage 송수신 즉시 기록**: 메시지를 보내거나 받을 때마다
  보고서의 `## Communication Log`에 행 1개 추가 (방향·상대·내용 요약·시점)
```

에이전트 완료 후: frontmatter(summary + key_findings)를 우선 읽고, 상세 필요시만 전체 읽기.

---

# 에이전트 산출물 프로토콜

**모든 에이전트**는 패턴(D~E)과 무관하게 이 프로토콜을 따른다.
스폰 프롬프트에 이 섹션 전문을 주입한다.

## 핵심 원칙

**스켈레톤 즉시 생성 → 점진적 업데이트 → 컨텍스트 복구 가능**

## 1. 스켈레톤 생성 (과제 수령 즉시)

**과제를 받은 즉시** 산출물 파일을 아래 템플릿으로 생성하라 (Write).
이것이 조사/구현보다 먼저 수행할 **첫 번째 행동**이다.

- Progress.Remaining에 과제를 하위 작업으로 분해하여 기입
- NNN은 오케스트레이터가 사전 배정 (또는 스폰 프롬프트에 명시)

## 2. 점진적 업데이트

작업 중 의미 있는 발견이나 하위 작업 완료 시마다 이 파일을 점진적으로 업데이트하라:
- `## Progress`의 Completed/Remaining 갱신
- `## Details`에 발견 사항 즉시 추가 (Edit 사용)
- **SendMessage 송신 직전 또는 수신 직후**: `## Communication Log`에 행 추가
- 이로써 컨텍스트 압축(compaction) 시에도 작업 내용과 소통 이력이 보존된다

## 3. 컨텍스트 복구 (압축/초기화 후)

**컨텍스트가 압축/초기화된 경우**: 자신의 보고서 파일을 먼저 Read하여 이전 발견과 진행 상태를 복구한 뒤, `## Progress`의 첫 미완료 항목부터 이어서 작업하라.

- Progress.Completed → 이미 수행한 작업 파악
- Progress.Remaining → 다음 할 일 파악
- Details → 이전 발견 사항 복구
- Communication Log → 이전 소통 이력 복구

## 4. 최종 정리 (모든 작업 완료 시)

- Progress.Current Status를 "완료"로 갱신
- Summary, Key Findings, Recommendations 섹션 최종 작성

## 5. confidence 판정 및 오케스트레이터 활용

에이전트는 산출물 frontmatter에 confidence 필드를 기재한다.

### confidence 수준 정의

| 수준 | 기준 | 예시 |
|------|------|------|
| **high** | 코드/데이터 직접 확인, 학술 문헌 근거, 테스트 통과 | 코드 읽고 확인한 사실, 논문 인용 |
| **medium** | 분석+해석 혼합, 부분 확인 | 패턴 추론, 일부만 테스트 |
| **low** | 추론 기반, 미확인 | 가설, 간접 정보 |

### 오케스트레이터의 confidence 활용 규칙

1. **릴레이 감쇠 적용**: 한 에이전트의 산출물을 다른 에이전트에 전달 시, confidence는 한 단계 감쇠 (high→medium→low)
2. **low confidence 산출물 처리**: 후속 에이전트에 "검증 필요" 플래그를 명시, 또는 원본 직접 읽기 지시
3. **종합 보고서 작성 시**: 개별 보고서의 confidence를 함께 기재하여 결론의 신뢰도 판단 가능하게 함
4. **평가루프 내**: confidence 감쇠 미적용 (검증 에이전트가 직접 확인하므로)

## 6. 원문 보존 규칙

다음 유형의 텍스트는 에이전트가 윤문·요약·의역하지 않고 **원형 그대로** 릴레이한다:

| 유형 | 예시 | 보호 방법 |
|------|------|----------|
| 학술 인용문 | "Costa & McCrae(1992)에 따르면..." | 인용 부분을 그대로 전달 |
| 저작권 원문 | 공식 검사 문항, 라이선스 텍스트 | 복사·변형 금지 (Red Line) |
| 사용자 원문 입력 | 사용자의 질문, 의도 설정 텍스트 | 의미 변형 없이 전달 |

에이전트 간 릴레이 시 원문이 포함되면 `> [ORIGINAL]` 블록으로 표시:
```
> [ORIGINAL] Costa & McCrae(1992)의 Five-Factor Model에 따르면...
```

## 산출물 문서 템플릿

\```markdown
---
id: "NNN"
title: "{Task Title}"
category: agent
status: archived
created: YYYY-MM-DD
summary: >
  {2-3 line summary}
keywords: [agent-report, {role}, {subagent_type}, {related keywords}]
modules: [{relevant module}]
---

# {Task Title}

## Progress
<!-- 하위 작업 완료 시마다 갱신. 컨텍스트 복구 시 이 섹션을 먼저 확인 -->
### Completed
- (아직 없음)
### Remaining
- [ ] {하위 작업 항목 — 스켈레톤 생성 시 과제를 분해하여 기입}
### Current Status
조사 시작 전.

## Summary
{2-3 line summary}

## Details
{Structured findings/results}

## Key Findings
{Key finding bullet points}

## Recommendations
{Next steps or suggestions}

## References
{Referenced files, URLs, sources}

## Communication Log
<!-- SendMessage 송수신 즉시 기록. 소통 흐름 재구성 및 추후 감사(audit)용 -->
<!-- 방향: →송신 / ←수신 -->
| # | 방향 | 상대 | 내용 요약 | 시점(단계) |
|---|------|------|----------|-----------|
| (아직 없음) | | | | |
\```

## 업데이트 빈도 가이드

| 상황 | 업데이트 시점 |
|------|-------------|
| 파일/모듈 분석 완료 | 즉시 Details에 추가 |
| 핵심 발견 | 즉시 Details에 추가 + Progress 갱신 |
| 하위 작업 완료 | Progress.Completed로 이동 |
| 방향 전환/계획 변경 | Progress.Current Status에 사유 기록 |
| 에러/장애 발생 | Details에 기록 (복구 시 재시도 방지) |
| SendMessage 송신 | 즉시 Communication Log에 →송신 행 추가 |
| SendMessage 수신 | 즉시 Communication Log에 ←수신 행 추가 |

## 서브에이전트 모드 추가 지침

서브에이전트 모드에서는 Agent Teams와 다른 규칙이 적용된다:

### Agent Teams와의 차이

| 항목 | Agent Teams | 서브에이전트 |
|------|-----------|------------|
| Coordination Rules | SendMessage 기반 소통 | 불필요 (독립 완료) |
| Communication Log | 필수 기록 | **생략** — 소통 상대 없음 |
| Communication Timeline (종합 보고서) | 필수 | **생략** — 소통 이력 없음 |
| 점진적 업데이트 | Edit으로 보고서 점진 갱신 | **동일** — 파일에 점진 기록 |
| Pattern E 4단계 승인 | 분해 결과 사용자 제시 | **동일** (auto_run 예외는 "4. 분해 결과 사용자 승인" 참조) |
| 모니터링 | 리드가 TaskList로 점검 | **불필요** — Agent tool 결과 대기 |

### 보고서 반환 규칙

작업 완료 시, 최종 보고서 내용을 아래 마커로도 반환 (리드 교차 검증용):

```
---START_REPORT---
{보고서 최종 상태 사본}
---END_REPORT---
```

마커 없으면 전체 응답을 결과로 사용. 보고서 파일이 존재하면 파일이 우선.

## code-reviewer 특수 처리

`code-reviewer`는 Write/Edit 도구가 차단됨:
- Report Instructions 대신: "작업 완료 후 리드에게 SendMessage로 결과 전달. 리드가 대신 보고서 저장."
- 리드가 code-reviewer의 메시지 내용을 보고서 파일로 Write.

---

# 평가루프 프로토콜

## 핵심 규칙

- 최대 반복 3회. 초과 시 현재 최선 + 미해결 목록으로 진행
- blocker/major fail → 재생성 (iteration++). minor만 → 1회 수정 후 자동 통과
- 점수 미개선(2회 연속 동일/하락) → 즉시 중단, 사용자 개입 요청

## 실패 패턴 기억 축적

평가루프가 **fail verdict 2회 이상** 또는 **HitL 개입**으로 종료될 때, 오케스트레이터는 실패 패턴을 기억에 저장한다:

1. **저장 위치**: 검증 에이전트의 `agent-memory/{agent}/memories/` (개별 기억)
2. **저장 조건**: iteration 2+ 도달 또는 HitL 개입 (iteration 1 pass는 저장 불필요)
3. **저장 내용**:
   ```yaml
   type: review
   keywords: ["평가루프", "실패패턴", "{실패 criteria ID}"]
   summary: "{대상 에이전트}의 {작업 유형}에서 {criteria}가 {N}회 fail"
   context: "평가루프 {iteration}회, verdict: {결과}"
   details: "반복 실패한 criteria: {목록}. fix_suggestion: {제안}"
   implications: "향후 동일 유형 검증 시 이 criteria를 우선 확인"
   ```
4. **활용**: 검증 에이전트 스폰 시, 해당 에이전트의 기억에서 `평가루프` 키워드로 과거 실패 패턴을 조회하여 스폰 프롬프트에 "이전에 반복 실패한 기준" 컨텍스트를 주입한다

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

# 병렬 실행 프로토콜 (패턴 E)

패턴 E 선택 시, 이 섹션의 절차를 따른다.

## 1. 작업 분해

1. **작업 유형 분류**: research / analyze / implement / review / debug / mixed
2. **유형별 분해 전략**:
   - research: 토픽·관점별 분해 (렌더링 / 번들 / 네트워크 / 메모리 전문가)
   - analyze: 파일·모듈별 분해 (컨트롤러 / 서비스 / 모델 / 라우트 분석가)
   - implement: 레이어별 + 파일 소유권 할당 (DB / 백엔드 / 프론트엔드 / 테스트)
   - review: 검증 관점별 분해 (보안 / 성능 / 테스트 / 유지보수성)
   - debug: 가설별 분해 (각 멤버가 다른 가설 검증)
3. **팀 규모**: 3-5명 (최적 범위)

## 2. 에이전트 매핑

각 하위 작업의 범위를 분석하여 프로젝트 에이전트 7종 중 적절한 것을 배정한다.
CLAUDE.md의 "전문 에이전트" 테이블 참조.

범용 작업(특정 도메인 전문성 불필요)에는 `general-purpose` 에이전트 사용 가능.

## 3. 저장 위치 & 번호 사전 배정

1. 토픽 폴더 식별 (불명확 시 사용자 확인)
2. 시퀀스 번호: 토픽 폴더 내 `[0-9][0-9][0-9]_*.md` 최대값 + 1
3. 에이전트별 max+1, +2, ..., +N. Synthesis = 마지막 + 1

## 4. 분해 결과 사용자 승인

분해 결과를 사용자에게 제시:
- 실행 모드 (서브에이전트 vs Agent Teams)
- 각 멤버의 역할, 범위, 에이전트 타입
- implement 타입: 파일 소유권 할당 테이블
- 의존성 그래프 (있는 경우)

### auto_run (--run) 모드의 승인 규칙

파이프라인 `--run` 모드에서도 Pattern E 실행 시, 작업 유형에 따라 승인 정책이 다르다:

| 작업 유형 | --run 시 승인 | 근거 |
|----------|-------------|------|
| research / analyze | **생략 가능** | 읽기 전용, 파괴적 변경 없음 |
| review | **생략 가능** | 읽기 전용, 코드 수정 없음 |
| implement | **축약 승인** | 분해 결과 1줄 요약 출력 후 진행 |
| debug | **축약 승인** | implement와 동일 |
| mixed (implement 포함) | **축약 승인** | implement 규칙 적용 |

**축약 승인 포맷**:
```
⚡ --run 병렬 실행: {작업 유형}, {N}명, 실행 모드: {서브에이전트/Agent Teams}
   파일 소유권: {멤버1}→{범위}, {멤버2}→{범위}
```

**주의**: H5(파괴적 작업) 트리거는 auto_run과 무관하게 항상 발동한다.

## 5. 컨텍스트 수집 (Context Engineering)

팀 멤버는 리드의 대화 이력을 상속하지 않으므로, **필요한 모든 컨텍스트를 스폰 프롬프트에 주입**한다.

수집 대상:
- **CLAUDE.md** → 프로젝트 구조, 컨벤션 요약
- **관련 파일 탐색** (Glob/Grep) → 태스크별 핵심 파일 경로
- **기존 코드 패턴** → 동일 모듈의 기존 구현 예시 (Read)

공유 컨텍스트 블록으로 구성:
```
## Project Context
- Structure: {모노레포 레이아웃 요약}
- Conventions: {이 태스크에 관련된 컨벤션만 발췌}
- Related files: {이 멤버가 참조해야 할 파일 경로 목록}
- Existing patterns: {동일 모듈의 기존 코드 패턴 예시}
```

## 6. 팀 구성 & 멤버 스폰

### Agent Teams 모드

1. TeamCreate로 팀 생성
2. 각 멤버를 Agent tool로 스폰 (에이전트 스폰 프로토콜 전체 적용)
3. 스폰 직후 SendMessage로 배정 번호 전달:
   ```
   "Your assigned report number is {NNN}. After completing work, create file
    docs/NN_{topic}/{NNN}_Agent_{slug}.md."
   ```
4. TaskCreate로 공유 작업 목록 + 의존성(blockedBy) 설정

### 서브에이전트 모드

Agent tool로 동시 스폰. 별도 모니터링 불필요.

## 7. 모니터링 & 조율 (리드 역할)

### Agent Teams — 리드의 5가지 의무

1. **진행 점검**: TaskList 주기적 확인
2. **방향 수정**: 잘못된 방향의 멤버에게 메시지
3. **교착 해소**: 작업 상태 정체 시 nudge, 필요 시 재배정
4. **발견 릴레이**: 한 멤버의 발견이 다른 멤버에 영향 → 브로드캐스트
5. **플랜 승인** (implement): 멤버 구현 계획 리뷰 + 승인/거절

**핵심: 리드는 구현하지 않는다** — Delegate mode로 조율에만 집중.

### 서브에이전트 모드

Agent tool 결과 대기. 독립 완료이므로 별도 모니터링 불필요.

## 8. 에이전트 간 통신 프로토콜 (Agent Teams)

### 발견 공유
멤버가 예상치 못한 의존성·이슈 발견 → 팀 전체 브로드캐스트
예: "Note: users 테이블에 email 컬럼 unique 제약이 없습니다."

### 인터페이스 합의
구현 멤버 간 API 인터페이스 합의 → 직접 메시지 교환
예: Backend → Frontend: "POST /api/users 응답 스키마는 { id, name, email, createdAt }."

### 경쟁 토론 (debug)
각 가설 멤버가 증거 제시 + 다른 가설 반론. 리드가 최종 판정.

### 진행 신호
블로킹 작업 완료 → 의존 멤버에게 메시지
예: "DB 마이그레이션 완료. 모델 구현 시작 가능."

## 9. 결과 종합

### 개별 보고서 수집

- **Agent Teams**: 각 멤버가 `docs/NN_{topic}/{NNN}_Agent_{slug}.md`에 직접 저장한 파일 확인. code-reviewer는 리드가 대신 저장.
- **서브에이전트**: 점진적으로 작성된 파일 확인. 파일 없거나 불완전하면 `---START_REPORT---` / `---END_REPORT---` 마커에서 추출. 마커도 없으면 전체 응답을 본문으로 사용.

### 충돌 점검 (implement)

`git diff --stat`으로 파일 충돌 확인. 같은 파일 다중 수정 시 리드가 수동 머지.

### 종합 보고서

2개+ 에이전트 결과물이 있을 때만 작성. 단일 에이전트면 생략.

개별 보고서 내용을 **반복하지 않는다** — 상대경로 링크로 참조.
교차 분석, 공통 패턴, 상충 발견, 종합 결론에만 집중.

종합 보고서 파일명: `{NNN}_Synthesis_{goal-slug}.md` (사전 배정 번호 사용)

\```markdown
---
id: "NNN"
title: "{goal} — Synthesis Report"
category: report
status: archived
created: YYYY-MM-DD
summary: >
  {2-3 sentence conclusion. 실행 모드, 에이전트 수, 핵심 발견 포함}
keywords: [parallel-synthesis, {task type}, {related keywords}]
modules: [{relevant modules}]
---

# {goal} — Synthesis Report

## Team Composition & Individual Reports

| # | Role | Agent Type | Report | Status |
|---|------|-----------|--------|--------|
| 1 | {role1} | {subagent_type} | [{NNN}_{slug}.md](./{NNN}_{slug}.md) | {complete/failed} |

---

## Cross-Analysis

### Common Findings
{여러 에이전트가 독립적으로 발견한 공통 사항}

### Conflicting Opinions
{상이한 결론에 대한 리드의 판단}

### Synergy Effects
{개별 보고서 결합으로 도출된 새 인사이트}

---

## Communication Timeline
<!-- 각 멤버의 Communication Log를 시간순으로 재구성 -->
| # | 송신자 | 수신자 | 내용 요약 | 시점(단계) |
|---|--------|--------|----------|-----------|

---

## Comprehensive Conclusion
{3-5줄 핵심 결론}

### Key Findings
{우선순위 정렬 bullet points}

### Recommended Actions
{다음 단계 제안 — 우선순위 정렬}

---

## References
{개별 보고서 참조 중복 제거 통합}
\```

### 사용자 보고

출력 항목:
- 생성된 보고서 파일 경로 (개별 + 종합)
- 실행 모드, 에이전트 타입, 멤버 수
- 각 멤버의 핵심 결과 요약 (1줄씩)
- implement 타입: 변경 파일 목록

---

# 에이전트 기억 체계 활용

## 구조

```
.claude/agent-memory/
├── _shared/                    # 조직 공유 기억 (모든 에이전트 접근)
│   ├── _index.yaml
│   └── memories/
├── {agent-name}/               # 개별 에이전트 기억
│   ├── _index.yaml
│   └── memories/
```

## 기억 유형 분류

| 저장소 | 유형 | 설명 |
|--------|------|------|
| _shared/ | organization_decision | 조직 전체 결정 (용어 표준, API 규격) |
| _shared/ | cross_domain_pattern | 2+ 도메인 교차 패턴 |
| _shared/ | project_standard | 프로젝트 수준 기준 (윤리 가이드라인) |
| _shared/ | conflict_resolution | 에이전트 간 관점 충돌 해결 기록 |
| {agent}/ | finding \| decision \| pattern \| review | 개별 도메인 발견 및 결정 |

## 오케스트레이터의 기억 활용 규칙

1. **스폰 시 기억 주입**: 에이전트 스폰 프롬프트에 관련 기억 요약을 포함한다
   - `_shared/_index.yaml` 스캔 → 작업과 관련된 공유 기억 경로 제공
   - `{agent}/_index.yaml` 스캔 → 해당 에이전트의 관련 기억 경로 제공
2. **교차 참조(related_memories)**: 기억 파일의 `related_memories` 필드가 다른 에이전트의 기억을 참조할 수 있다. 관련 에이전트 스폰 시 이 참조도 포함한다
3. **기억 우선순위**: 공유 기억 > 개별 기억 (조직 일관성 우선)
4. **기억 갱신**: 에이전트가 새 발견을 기억에 저장하면, 오케스트레이터는 공유 기억 해당 여부를 판단하여 _shared/에 승격할 수 있다

---

# 맥락 보전 프로토콜

## 점진적 보고서 프로토콜

에이전트 산출물 프로토콜(위)의 4단계(스켈레톤→업데이트→복구→정리)가 1차 방어선이다.
발견 사항을 메모리에만 누적하지 말 것 — 반드시 파일에 기록.

## 리드의 역할

- 에이전트가 압축된 것으로 의심되면 (응답 지연, 반복 행동), 해당 에이전트의 보고서 파일을 Read하여 진행 상태 확인
- 필요 시 메시지로 "보고서 파일을 읽고 이어서 작업하라" 지시
- 서브에이전트 모드에서는 자동 — 보고서 파일 존재 여부로 진행도 판단

---

# 오류 처리

| 상황 | 대응 |
|------|------|
| 멤버 실패 | 나머지 결과로 진행, 실패 섹션 표시 |
| 작업 상태 정체 | 리드가 nudge, 필요 시 재배정 |
| 파일 충돌 | 파일 소유권으로 예방; 발생 시 리드가 수동 머지 |
| 범위 위반 | 스폰 프롬프트 배제 범위로 예방; 발견 시 메시지로 수정 |
| Agent Teams 비활성 | 서브에이전트 모드로 자동 폴백 |
| 에이전트 컨텍스트 압축 | 보고서 파일 Read로 진행 복구, 마지막 체크포인트부터 재개 |
| 마커 누락 (서브에이전트) | 전체 응답을 결과로 사용 |
| code-reviewer Write 차단 | 리드가 메시지 수신 후 대신 저장 |
| 보고서 번호 충돌 | 사전 배정으로 예방 |

---

# 품질 게이트

## 플랜 승인 게이트 (implement)

멤버가 Plan Mode로 구현 계획 작성 → 리드가 리뷰.
승인 기준을 스폰 프롬프트에 명시:
```
Only approve plans that:
- Follow existing project conventions
- Stay within file ownership scope
- Include test strategy
```
거절 시 피드백과 함께 재작성 요청.

## 작업 완료 게이트

- implement: 린터/테스트 통과 확인
- review: High+ severity 항목 누락 점검
- research: 최소 출처 수 확인

---

# 사용자 개입 트리거

다음 상황에서 자동 진행을 중단하고 사용자에게 확인한다:

| # | 트리거 | 긴급도 | 설명 |
|---|--------|--------|------|
| H1 | 평가루프 max_iterations 도달 | 필수 | 3회 fail 후 자동 수정 한계 |
| H2 | 점수 미개선 (2회 연속 동일/하락) | 필수 | overall_score ≤ 이전값 → 루프 수렴 실패 |
| H3 | 동일 criteria 2회 연속 동일 fix_suggestion으로 fail | 필수 | 구조적 문제, 자동 수정 불가 |
| H4 | 도메인 전문가 간 blocker 수준 의견 충돌 | 높음 | 생성-검증 에이전트 간 판단 불일치 |
| H5 | 파괴적 작업 (DB 마이그레이션, 파일 대량 삭제) | 필수 | 되돌릴 수 없는 작업 |
| H6 | 패턴 선택 불가 (위임 판단의 "확신 없음" 분기) | 높음 | CLAUDE.md 오케스트레이션 트리거 "확신 없음" 항목과 연동 |
| H7 | 저작권/법적 판단이 필요한 콘텐츠 | 높음 | PSY-07 반복 fail 등 법적 판단 필요 |

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
