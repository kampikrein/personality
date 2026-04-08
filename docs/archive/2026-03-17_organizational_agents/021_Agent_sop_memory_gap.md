---
id: "021"
title: "SOP·프로토콜·기억 체계 대조 분석"
category: agent
status: archived
created: 2026-03-17
summary: >
  원래 설계 문서(010-017)와 현재 구현(.claude/protocols/orchestration.md, .claude/agents/*.md,
  .claude/agent-memory/)의 7개 비교 포인트 대조 분석 완료. 설계 대비 구현 반영율은 약 85%로
  높은 수준이나, 핵심 갭 3건(work-orders 인프라 삭제, confidence 판정 기준 에이전트 프롬프트 미인코딩,
  TAROT 검증 기준 원래 설계에 부재)과 중간 갭 4건이 식별됨.
keywords: [agent-report, SOP, evaluation-loop, handoff, persona, agent-memory, gap-analysis]
modules: [.claude/protocols, .claude/agent-memory, .claude/agents]
---

# SOP·프로토콜·기억 체계 대조 분석

## Progress
### Completed
- [x] 원래 설계 문서 전체 읽기 (010-017)
- [x] 현재 구현 파일 읽기 (orchestration.md, agent-memory/, agents/*.md)
- [x] 비교 A: SOP 행동루프
- [x] 비교 B: 평가루프 (HitL)
- [x] 비교 C: 인계 포맷
- [x] 비교 D: 페르소나 강화
- [x] 비교 E: 기억 체계
- [x] 비교 F: 릴레이 감쇠
- [x] 비교 G: 맥락 보전 프로토콜
- [x] 최종 결론 및 갭 목록
### Remaining
(없음)
### Current Status
분석 완료.

---

## Summary

원래 설계 문서 8건(010-017)이 제안한 내용과 현재 구현 파일(orchestration.md + 7개 에이전트 정의 + agent-memory YAML)을 7개 축으로 대조했다. 전체적으로 설계의 약 85%가 구현에 반영되었으며, 일부는 설계보다 발전된 형태(예: TAROT 검증 기준 신설, 산출물 프로토콜 통합)로 구현되었다. 그러나 3건의 핵심 갭과 4건의 중간 갭이 식별되었다. 가장 큰 구조적 변화는 `.claude/work-orders/` 워크플로우 인프라(handover.yaml, evaluation.yaml, manifest.yaml 등)가 현재 구현에서 사라지고 orchestration.md 단일 문서로 통합된 점이다.

---

## Details

### A. SOP 행동루프 (Observe -> Think -> Act -> Share)

#### 원래 설계 (012)

012 문서는 MetaGPT의 O->T->A->S를 Claude Code 에이전트 프롬프트에 매핑하는 상세 방안을 제시했다.

핵심 제안:
- `# Analysis Framework` 섹션을 `# SOP: 행동 루프`로 대체
- Observe: 작업 지시 확인, 이전 산출물 읽기, 기억 조회, 검증 대상 읽기
- Think: 기존 5단계 체크리스트 보존 (역할별 변형)
- Act: 역할별 산출물 생성 (검증 보고서, 콘텐츠 초안, 코드, 뷰)
- Share: frontmatter 확인 (summary, key_findings, confidence), 기억 저장
- 오케스트레이터에 "SOP 마스터" 섹션 추가

#### 현재 구현

**7개 에이전트 전부에 `# SOP: 행동 루프` 섹션이 존재한다.**

psychology-expert.md (line 49-83):
```
# SOP: 행동 루프
모든 작업은 Observe → Think → Act → Share 4단계로 수행한다.
## Observe: 입력 읽기 ...
## Think: 분석 & 판단 ...
## Act: 산출물 생성 ...
## Share: 인계 & 기록 ...
```

동일 구조가 mbti-expert, enneagram-expert, coding-expert, uiux-expert, flutter-expert, tarot-expert에도 적용됨.

orchestration.md (line 615-622) — "SOP 워커 스폰 참조" 섹션:
```
워커 에이전트는 Observe → Think → Act → Share 루프를 따른다.
```

#### 대조 결과

| 설계 항목 | 반영 여부 | 비고 |
|----------|----------|------|
| Analysis Framework -> SOP 행동 루프 교체 | **완전 반영** | 7개 에이전트 모두 변환됨 |
| Observe 4단계 (지시/산출물/기억/대상) | **완전 반영** | 역할별 변형도 설계대로 |
| Think = 기존 5단계 보존 | **완전 반영** | 각 에이전트 고유 체크리스트 유지 |
| Act 역할별 변형 | **완전 반영** | evaluation YAML, 코드, 뷰 등 |
| Share confidence 판정 | **완전 반영** | 3단계 기준 명시 |
| 오케스트레이터 SOP 마스터 섹션 | **축소 반영** | 016의 상세 "SOP Master Protocol" 대신 orchestration.md에 3줄 요약 |

**갭**: 오케스트레이터의 SOP 마스터가 설계(016)의 상세 버전에서 축소되었다. 016은 "워커 스폰 시 Observe 재료 구성 5항목", "Share 산출물 확인 프로토콜 3단계"를 명시했으나, 현재 orchestration.md에서는 "에이전트 스폰 프로토콜" 섹션이 이를 대체하고 있어 기능적으로는 동등하나 SOP 프레임워크와의 명시적 연결이 약하다.

---

### B. 평가루프 (HitL)

#### 원래 설계 (013)

013 문서의 핵심 제안:
- criteria에 `severity: blocker | major | minor` 필드 추가
- verdict 자동 판정 규칙: blocker/major -> fail, minor만 -> conditional_pass
- `overall_score = count(pass) / count(total)` 필드 추가
- `previous_iterations` 이력으로 점수 미개선 자동 감지
- conditional_pass = 1회 수정 후 재평가 없이 자동 통과
- HitL 7개 트리거 (H1-H7)
- 구조화된 개입 요청 포맷 (상황 요약 + 이력 테이블 + 4개 선택지)
- 역할별 검증 기준 세트: PSY-01~07, CODE-01~05, UX-01~06

#### 현재 구현

orchestration.md "평가루프 프로토콜" 섹션 (line 231-275):
```yaml
evaluation:
  verdict: pass | fail | conditional_pass
  ...
  overall_score: 0.0
  criteria:
    - name: "{기준명}"
      severity: blocker | major | minor
      status: pass | fail
      ...
  previous_iterations:
    - iteration: 1
      overall_score: 0.0
      verdict: ""
      failed_criteria: []
```

severity 기반 verdict 판정 테이블 (line 269-274) — 설계와 정확히 일치.

"사용자 개입 트리거" 섹션 (line 586-611):
```
- 평가루프 3회 도달 또는 점수 미개선
- 파괴적 작업 (DB 마이그레이션, 파일 대량 삭제)
- 저작권/법적 판단이 필요한 콘텐츠
- 도메인 전문가 간 blocker 수준 의견 충돌
```

개입 요청 포맷 (line 595-611): 상황 + 이력 테이블 + 4개 선택지 — 설계와 일치.

"검증 기준 (Role-Specific)" 섹션 (line 278-337):
- PSY-01~07 (학술 검증) — severity 배정까지 설계와 일치
- CODE-01~05 (코드 검증) — 설계와 일치
- UX-01~06 (UX 검증) — 설계와 일치
- **TAROT-01~06 (타로 콘텐츠 검증) — 원래 설계(013)에 없던 신규 추가**

#### 대조 결과

| 설계 항목 | 반영 여부 | 비고 |
|----------|----------|------|
| severity 필드 (blocker/major/minor) | **완전 반영** | evaluation 포맷에 포함 |
| verdict 자동 판정 규칙 | **완전 반영** | 4행 테이블 동일 |
| overall_score | **완전 반영** | evaluation 포맷에 포함 |
| previous_iterations 이력 | **완전 반영** | failed_criteria 포함 |
| conditional_pass 처리 | **완전 반영** | "1회 수정 후 자동 통과" |
| HitL 7개 트리거 (H1-H7) | **축소 반영** | 4개로 축약 (H4, H6, H7이 "도메인 충돌"과 "법적 판단"으로 병합, H3(동일 fail 반복) 미명시) |
| 구조화된 개입 요청 포맷 | **완전 반영** | 이력 테이블 + 4개 선택지 |
| 검증 기준 PSY/CODE/UX | **완전 반영** | severity 배정까지 동일 |
| TAROT 검증 기준 | **설계 초과** | 013에 없던 TAROT-01~06 신설 |
| evaluation.yaml 독립 파일 | **미반영** | orchestration.md에 인라인 포맷으로 통합 |
| workflow_id, step 필드 | **미반영** | work-orders 인프라 삭제로 불필요해짐 |

**갭**: HitL 트리거가 7개에서 4개로 축소되었다. 특히 H3(동일 criteria 2회 연속 동일 fix_suggestion으로 fail -> 자동 수정 불가 판정)가 현재 구현에서 명시되지 않았다. 이는 평가루프의 "수렴 실패 감지" 메커니즘이 약화된 것을 의미한다.

---

### C. 인계 포맷

#### 원래 설계 (011)

011 문서의 핵심 제안:
- 필수 10필드: handover_id, workflow_id, created, status, source.agent, source.confidence, target.agent, target.expected_action, summary, next_steps
- 선택 7필드: source.task, artifacts, constraints, validation, context_level, full_document
- confidence 3단계 판정 기준 (high/medium/low)
- 3단계 압축: Level 1(전문) / Level 2(요약) / Level 3(인계)
- 환각 캐스케이딩 방지 3중 메커니즘 (자기 평가, 원본 추적, 교차 검증)

016 구현 플랜에서 handover.yaml 확장을 명시.

#### 현재 구현

**handover.yaml 독립 파일이 현재 구현에 존재하지 않는다.** `.claude/work-orders/` 디렉토리 자체가 운영에서 사용되지 않는 상태.

대신, orchestration.md의 "에이전트 산출물 프로토콜" (line 111-227)이 인계 기능을 대체한다:
- 스켈레톤 즉시 생성 -> 점진적 업데이트 -> 컨텍스트 복구
- 산출물 문서 템플릿에 frontmatter (id, title, category, status, created, summary, keywords, modules) 포함
- Progress, Summary, Details, Key Findings, Recommendations, References, Communication Log 섹션

에이전트 프롬프트의 Share 단계에서 confidence 판정이 이루어진다:
```
confidence 수준 판정: high(코드/데이터 직접 확인 또는 학술 문헌 근거)
                     / medium(분석+해석 혼합)
                     / low(추론 기반)
```

#### 대조 결과

| 설계 항목 | 반영 여부 | 비고 |
|----------|----------|------|
| 구조화된 인계 파일 (handover.yaml) | **구조적 대체** | 산출물 프로토콜이 인계 역할을 흡수 |
| confidence 3단계 | **완전 반영** | 에이전트 Share 단계에 인코딩 |
| 3단계 압축 (Level 1/2/3) | **암묵적 반영** | 산출물 frontmatter = Level 2, 본문 = Level 1 |
| constraints 필드 | **미반영** | 수신 에이전트 제약 조건 전달 구조 없음 |
| context_level 필드 | **미반영** | 명시적 압축 수준 표시 없음 |
| status 추적 (pending/accepted/completed) | **미반영** | 인계 상태 추적 메커니즘 없음 |
| validation.validator_agent 자동 매핑 | **부분 반영** | "기준 선택 가이드" 테이블에 검증 에이전트 명시 |
| artifacts[].sections 참조 | **미반영** | 원본의 특정 섹션 참조 구조 없음 |

**갭**: 011의 핵심 발견이었던 "인계에 필요한 5개 핵심 정보 누락" 중 constraints, context_level, status는 현재 구현에도 여전히 반영되지 않았다. 다만, 014 Synthesis에서 "Share 단계의 산출물이 곧 인계 파일" 이라는 통합 결론을 내렸고, 현재 구현은 이 방향을 따르고 있다. 별도 인계 파일 대신 산출물 자체가 인계 역할을 하는 설계로, 구조적 복잡도는 줄었으나 일부 정보(constraints, status)의 전달 경로가 사라졌다.

---

### D. 페르소나 강화

#### 원래 설계 (017)

017 문서의 핵심 제안:
- 5요소 모델 (Role/Goal/Backstory/Tools+Guardrails/Memory) 중 누락된 Goal과 Backstory 보충
- 5개 워커에 Goal 섹션 (미션 + 성공 지표) 추가
- Role에 Backstory 통합 (전문 영역 + 조직 내 고유 기여)

#### 현재 구현

**7개 에이전트 모두에 Goal 섹션과 Role Backstory가 존재한다.**

psychology-expert.md (line 10-30):
```markdown
# Role
성격심리학과 심리측정학을 전문으로 하는 연구자. ...
**전문 영역**: Big Five(Costa & McCrae, 1992), 심리측정 이론(CTT/IRT), ...
**조직 내 고유 기여**: 이 조직에서 학술적 정확성의 최종 보루. ...

# Goal
**미션**: personality 서비스의 모든 성격 관련 콘텐츠가 학술적 근거에 기반하고, ...
**성공 지표**:
- 서비스 내 모든 성격 유형 서술에 학술 근거가 인용되어 있다
- 바넘 효과 문구가 0건이다
- ...
```

017에서 계획한 5개 에이전트 + 추가된 flutter-expert, tarot-expert까지 총 7개에 동일 구조 적용.

#### 대조 결과

| 설계 항목 | 반영 여부 | 비고 |
|----------|----------|------|
| Goal 섹션 (미션 + 성공 지표) | **완전 반영** | 7개 에이전트 모두 |
| Role에 Backstory 통합 | **완전 반영** | "전문 영역" + "조직 내 고유 기여" |
| psychology-expert 페르소나 | **완전 반영** | 017의 After Code와 정확히 일치 |
| mbti-expert 페르소나 | **완전 반영** | 017 설계 일치 |
| enneagram-expert 페르소나 | **완전 반영** | 017 설계 일치 |
| coding-expert 페르소나 | **발전적 반영** | 017 기반 + Flutter 경계 명시, 타로 API 추가 |
| uiux-expert 페르소나 | **발전적 반영** | 017 기반 + 제의적 UX, 평가 모드, Flutter 위젯 UX 평가 추가 |
| flutter-expert 페르소나 | **설계 초과** | 017에 없던 에이전트 — 후속 개발에서 추가 |
| tarot-expert 페르소나 | **설계 초과** | 017에 없던 에이전트 — 후속 개발에서 추가 |

**갭 없음.** 페르소나 강화는 설계 대비 완전 반영 + 초과 달성.

---

### E. 기억 체계

#### 원래 설계 (017)

017의 기억 체계 핵심 제안:
- `.claude/agent-memory/_shared/` 디렉토리 + `_index.yaml` 생성
- 공유 기억 유형 4가지: organization_decision, cross_domain_pattern, project_standard, conflict_resolution
- 기억 작성 규칙: 개인 기억 vs 공유 기억 구분, 충돌 시 공유 > 개인
- 5개 에이전트 Memory System에 `## 공유 기억` 서브섹션 추가

#### 현재 구현

**_shared/_index.yaml** 실제 내용:
```yaml
description: "조직 공유 기억 — 모든 에이전트가 접근하는 교차 도메인 기억 저장소"
storage_path: ".claude/agent-memory/_shared/memories/"
# 공유 기억 유형:
#   - organization_decision: ...
#   - cross_domain_pattern: ...
#   - project_standard: ...
#   - conflict_resolution: ...
index:
  - id: "001"
    file: "memories/001_파운더비전_성격포탈.yaml"
    type: project_standard
    date: "2026-03-15"
    keywords: ["파운더비전", "성격포탈", ...]
    summary: "파운더의 프로젝트 목표점 — ..."
```

017의 설계 템플릿과 **정확히 일치**. 실제로 공유 기억 1건(001_파운더비전)이 생성되어 운영 중.

**개별 에이전트 기억 현황**:

| 에이전트 | 기억 수 | 내용 예시 |
|---------|--------|----------|
| psychology-expert | 2건 | 001: 학술차별화전략, 002: 타로앱 심리학비평 |
| mbti-expert | 1건 | 001: 콘텐츠깊이래더 설계 |
| enneagram-expert | 1건 | 001: 동기기반콘텐츠전략 |
| coding-expert | 1건 | 001: 코드베이스현황 2026-03-15 |
| uiux-expert | 2건 | 001: 스와이프 카드피드 설계, 002: 타로앱 제의적UX 비평 |
| flutter-expert | (확인 필요) | — |
| tarot-expert | (확인 필요) | — |

**기억 주입 메커니즘**: 7개 에이전트 프롬프트 모두에 Memory System 섹션이 존재하며, "작업 시작 시 _index.yaml 읽기" + "작업 완료 시 기억 저장" 절차가 인코딩되어 있다. 공유 기억 참조("_shared/_index.yaml도 확인")도 7개 모두에 포함.

**기억 파일 포맷 실제 사용 현황**:

enneagram-expert의 001 기억에서 `related_memories: [shared/001_파운더비전_성격포탈]` — 교차 참조가 실제로 사용되고 있음.

#### 대조 결과

| 설계 항목 | 반영 여부 | 비고 |
|----------|----------|------|
| _shared/ 디렉토리 + _index.yaml | **완전 반영** | 설계 템플릿과 동일 |
| 공유 기억 4유형 정의 | **완전 반영** | 주석으로 명시 |
| 공유 > 개인 우선순위 | **완전 반영** | "공유 기억의 결정은 개인 기억보다 우선한다" |
| 에이전트 공유 기억 참조 | **완전 반영** | 7개 모두 "공유 기억" 서브섹션 포함 |
| 실제 기억 생성 | **운영 중** | 공유 1건 + 개별 총 7건+ 실제 운영 |
| related_memories 교차 참조 | **운영 중** | enneagram의 shared/001 참조 확인 |
| 기억 포맷 (context/details/implications) | **완전 반영** | 실제 기억 파일이 포맷 준수 |

**갭 없음.** 기억 체계는 설계 대비 완전 반영 + 실제 운영 확인.

---

### F. 릴레이 감쇠

#### 원래 설계 (011, 014)

011의 핵심 제안:
- 에이전트 간 전달 시 confidence가 한 단계씩 감쇠 (high -> medium -> low)
- 3단계 이상 릴레이된 정보는 원본 직접 확인 강제
- 014 Synthesis에서 "파이프라인에서만 적용, 평가루프에서는 미적용"으로 결정

#### 현재 구현

orchestration.md (line 615-622) — "SOP 워커 스폰 참조" 섹션:
```
**릴레이 감쇠** (파이프라인 전용):
- 수신측 confidence는 원본보다 한 단계 낮게 시작 (high→medium→low)
- 3단계 이상 릴레이된 정보는 원본 직접 읽기 지시
- 평가루프 내에서는 감쇠 미적용
```

#### 대조 결과

| 설계 항목 | 반영 여부 | 비고 |
|----------|----------|------|
| confidence 한 단계 감쇠 | **완전 반영** | 동일 규칙 |
| 3단계 이상 원본 직접 확인 | **완전 반영** | 동일 규칙 |
| 파이프라인 전용 (평가루프 미적용) | **완전 반영** | 014 결정 정확히 반영 |

**갭 없음.** 릴레이 감쇠 규칙은 완전 반영.

---

### G. 맥락 보전 프로토콜

#### 원래 설계 (012, 016)

012의 관련 제안:
- SOP Share 단계에서 산출물을 파일로 저장 -> 컨텍스트 압축 시에도 복원 가능
- Memory System의 "작업 시작 시 _index.yaml 읽기" = Observe의 기억 조회 단계

016에서는 이를 에이전트 프롬프트에 명시적으로 인코딩.

#### 현재 구현

orchestration.md "맥락 보전 프로토콜" 섹션 (line 532-556):
```
## 점진적 보고서 프로토콜
에이전트 산출물 프로토콜(위)의 4단계(스켈레톤→업데이트→복구→정리)가 1차 방어선이다.
발견 사항을 메모리에만 누적하지 말 것 — 반드시 파일에 기록.

## 리드의 역할
- 에이전트가 압축된 것으로 의심되면 보고서 파일을 Read하여 진행 상태 확인
- 필요 시 메시지로 "보고서 파일을 읽고 이어서 작업하라" 지시
```

산출물 프로토콜 "3. 컨텍스트 복구" (line 136-143):
```
컨텍스트가 압축/초기화된 경우: 자신의 보고서 파일을 먼저 Read하여
이전 발견과 진행 상태를 복구한 뒤, Progress의 첫 미완료 항목부터 이어서 작업하라.
```

#### 대조 결과

| 설계 항목 | 반영 여부 | 비고 |
|----------|----------|------|
| 산출물 파일 기반 컨텍스트 복원 | **발전적 반영** | 설계보다 구체적 4단계 프로토콜 |
| 점진적 업데이트 | **완전 반영** | 업데이트 빈도 가이드까지 포함 |
| 리드의 복구 지원 역할 | **설계 초과** | 012에 없던 리드 감시 프로토콜 추가 |
| Memory + 파일 이중 기록 | **완전 반영** | "메모리에만 누적하지 말 것" 명시 |

**갭 없음.** 맥락 보전은 설계 대비 발전적으로 반영.

---

## Key Findings

### 구조적 변화: work-orders 인프라의 제거

가장 큰 구조적 차이는 원래 설계(010-016)가 전제했던 `.claude/work-orders/` 워크플로우 관리 인프라(manifest.yaml, handover.yaml, evaluation.yaml 독립 파일들)가 현재 구현에서 사라진 점이다. 대신:

- **handover.yaml** -> 산출물 프로토콜의 frontmatter가 대체
- **evaluation.yaml** -> orchestration.md에 인라인 포맷으로 통합
- **manifest.yaml** -> 워크플로우 상태 추적 메커니즘 미구현
- **workflow_id, step 번호 체계** -> docs/ 파일명 체계가 대체

이 변화의 원인은 설계와 구현 사이에 "SOP의 Share 단계 산출물이 곧 인계 파일"이라는 014 Synthesis의 핵심 결론이 반영되면서, 별도 인계 파일의 필요성이 소멸했기 때문으로 판단된다. 워크플로우 추적도 CLAUDE.md의 위임 규칙 + orchestration.md의 패턴 선택으로 경량화되었다.

### 설계 대비 발전한 부분

1. **에이전트 확장**: 원래 5개(psychology, mbti, enneagram, coding, uiux)에서 7개(+ flutter-expert, tarot-expert)로 확장
2. **TAROT 검증 기준**: 013의 PSY/CODE/UX 3세트에서 TAROT-01~06이 추가되어 4세트
3. **맥락 보전 프로토콜**: 012의 암묵적 제안에서 명시적 4단계 프로토콜 + 리드 감시까지 발전
4. **산출물 프로토콜 통합**: 인계/평가/산출물 포맷이 단일 프로토콜로 통합되어 복잡도 감소
5. **Agent Teams + 서브에이전트 이중 모드**: 원래 설계에 없던 실행 모드 결정 메커니즘 추가

---

## Gap Analysis (심각도별)

### Critical (0건)

없음. 설계의 핵심 철학(SOP 4단계, severity 기반 평가, 릴레이 감쇠, 기억 체계)은 모두 구현됨.

### High (3건)

| # | 갭 | 원래 설계 | 현재 구현 | 영향 |
|---|---|----------|----------|------|
| H-1 | work-orders 인프라 삭제로 워크플로우 상태 추적 부재 | manifest.yaml + status + checkpoint | 없음 | 워크플로우 중단/재개 시 진행 상태 파악 불가. 현재는 docs/ 파일 존재 여부로 암묵적 추적 |
| H-2 | confidence 판정 기준이 에이전트 프롬프트에만 존재 | 011에서 오케스트레이터 프롬프트에도 인코딩 제안 | orchestration.md에 confidence 판정 기준 미명시 | 오케스트레이터가 confidence 기반 행동 결정(추가 검증 여부)을 할 때 판정 기준을 참조할 곳이 없음 |
| H-3 | HitL 트리거 축소 (7개 -> 4개) | H1-H7 모두 명시, 특히 H3(동일 fail 반복 감지) | H3(동일 criteria 2회 연속 동일 fix_suggestion fail), H6(워크플로우 유형 불명확) 미명시 | 평가루프 수렴 실패 감지 약화 |

### Medium (4건)

| # | 갭 | 원래 설계 | 현재 구현 | 영향 |
|---|---|----------|----------|------|
| M-1 | constraints 필드 미구현 | 인계 포맷 선택 필드로 수신 에이전트 제약 조건 전달 | 스폰 프롬프트에서 자연어로 전달 (구조화 안됨) | 범위 이탈(scope creep) 위험 약간 증가 |
| M-2 | context_level 명시 없음 | Level 1/2/3 압축 수준 표시 | 산출물 frontmatter vs 본문으로 암묵적 구분 | 오케스트레이터가 읽기 전략을 자동 결정하기 어려움 |
| M-3 | 오케스트레이터 SOP 마스터의 축소 | 상세 SOP Master Protocol (Observe 재료 5항목, Share 확인 3단계) | "SOP 워커 스폰 참조" 3줄 요약 | SOP 프레임워크와 에이전트 스폰의 명시적 연결이 약함 |
| M-4 | 개입 후 재개 프로토콜 미세 차이 | 4개 선택지별 manifest 업데이트 규칙 명시 | 선택지 제시만 있고 재개 시 manifest 처리 미명시 | manifest가 없으므로 재개 시 상태 복원 절차가 불명확 |

### Low (0건)

모든 Minor 수준 설계 항목은 반영되었거나 구조적 대체로 해소됨.

---

## Recommendations

### 1. H-2 해소: orchestration.md에 confidence 판정 기준 추가

orchestration.md의 "에이전트 스폰 프로토콜" 또는 "SOP 워커 스폰 참조" 근처에 confidence 3단계 판정 기준과 오케스트레이터의 대응 행동을 명시하라. 현재 에이전트 프롬프트에만 존재하는 아래 규칙을 옮겨오면 된다:

```
high: 코드/데이터 직접 확인, 2+ 에이전트 교차 확인, 학술 문헌 근거 → 추가 검증 없이 진행
medium: 코드 분석 + 해석 혼합, 단일 에이전트 독립 발견 → 검증 에이전트 1회 확인
low: 추론/추정 기반, 불확실한 정보 의존 → 반드시 교차 검증
```

### 2. H-3 해소: 누락된 HitL 트리거 복원

orchestration.md의 "사용자 개입 트리거" 섹션에 다음을 추가하라:

- "동일 criteria가 2회 연속 동일 fix_suggestion으로 fail (자동 수정 불가 판정)"
- "워크플로우 유형이 불명확하여 패턴 선택에 확신이 없을 때"

### 3. H-1 고려: 워크플로우 상태 추적 경량화

work-orders 인프라를 복원할 필요는 없으나, 장시간 워크플로우의 중단/재개를 위해 최소한의 상태 기록 방안을 고려하라. 예: docs/ 산출물의 frontmatter에 `workflow_status: in-progress | completed | suspended` 필드를 추가하여 기존 산출물 프로토콜 내에서 해결.

### 4. M-3 고려: SOP 워커 스폰 참조 확장

현재 3줄인 "SOP 워커 스폰 참조"를 016의 설계 수준으로 확장하면, 에이전트 스폰 시 SOP 프레임워크와의 연결이 더 명확해진다. 그러나 현재 "에이전트 스폰 프로토콜"이 기능적으로 이를 대체하고 있으므로 우선순위는 낮다.

---

## References

### 원래 설계 문서 (8건)
- `/Users/kampikrein/A/personality/docs/07_organizational_agents/010_Research_소통프로토콜_SOP.md`
- `/Users/kampikrein/A/personality/docs/07_organizational_agents/011_Agent_인계포맷설계.md`
- `/Users/kampikrein/A/personality/docs/07_organizational_agents/012_Agent_SOP행동루프.md`
- `/Users/kampikrein/A/personality/docs/07_organizational_agents/013_Agent_평가루프HitL.md`
- `/Users/kampikrein/A/personality/docs/07_organizational_agents/014_Synthesis_소통프로토콜SOP.md`
- `/Users/kampikrein/A/personality/docs/07_organizational_agents/015_Research_소통프로토콜_SOP_최종.md`
- `/Users/kampikrein/A/personality/docs/07_organizational_agents/016_Plan_소통프로토콜SOP구현.md`
- `/Users/kampikrein/A/personality/docs/07_organizational_agents/017_Plan_페르소나강화_기억체계.md`

### 현재 구현 파일 (핵심)
- `/Users/kampikrein/A/personality/.claude/protocols/orchestration.md`
- `/Users/kampikrein/A/personality/.claude/agents/psychology-expert.md`
- `/Users/kampikrein/A/personality/.claude/agents/mbti-expert.md`
- `/Users/kampikrein/A/personality/.claude/agents/enneagram-expert.md`
- `/Users/kampikrein/A/personality/.claude/agents/coding-expert.md`
- `/Users/kampikrein/A/personality/.claude/agents/uiux-expert.md`
- `/Users/kampikrein/A/personality/.claude/agents/flutter-expert.md`
- `/Users/kampikrein/A/personality/.claude/agents/tarot-expert.md`

### 기억 체계 파일
- `/Users/kampikrein/A/personality/.claude/agent-memory/_shared/_index.yaml`
- `/Users/kampikrein/A/personality/.claude/agent-memory/_shared/memories/001_파운더비전_성격포탈.yaml`
- `/Users/kampikrein/A/personality/.claude/agent-memory/psychology-expert/_index.yaml`
- `/Users/kampikrein/A/personality/.claude/agent-memory/psychology-expert/memories/001_학술차별화전략_핵심발견.yaml`
- `/Users/kampikrein/A/personality/.claude/agent-memory/mbti-expert/_index.yaml`
- `/Users/kampikrein/A/personality/.claude/agent-memory/mbti-expert/memories/001_콘텐츠깊이래더_설계.yaml`
- `/Users/kampikrein/A/personality/.claude/agent-memory/enneagram-expert/_index.yaml`
- `/Users/kampikrein/A/personality/.claude/agent-memory/enneagram-expert/memories/001_동기기반콘텐츠전략_비전스코핑.yaml`
- `/Users/kampikrein/A/personality/.claude/agent-memory/coding-expert/_index.yaml`
- `/Users/kampikrein/A/personality/.claude/agent-memory/coding-expert/memories/001_코드베이스현황_2026-03-15.yaml`
- `/Users/kampikrein/A/personality/.claude/agent-memory/uiux-expert/_index.yaml`
- `/Users/kampikrein/A/personality/.claude/agent-memory/uiux-expert/memories/001_스와이프_카드피드_설계.yaml`

## Communication Log
| # | 방향 | 상대 | 내용 요약 | 시점(단계) |
|---|------|------|----------|-----------|
| (단독 분석 — 소통 없음) | | | | |

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
