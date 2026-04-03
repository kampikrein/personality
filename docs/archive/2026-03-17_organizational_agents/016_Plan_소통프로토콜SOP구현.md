---
id: "016"
type: plan
title: "소통 프로토콜 & SOP 구현 플랜"
created: 2026-03-14
traces_scope: "001"
traces_research: "015"
summary: >
  사이클 2 구현 플랜. 5개 워커 에이전트 프롬프트의 Analysis Framework을 SOP 행동 루프
  (O→T→A→S)로 확장하고, 오케스트레이터에 SOP 마스터 섹션·severity 기반 verdict·HitL 7개
  트리거를 추가한다. handover.yaml과 evaluation.yaml 템플릿을 연구 결과에 맞춰 확장한다.
keywords: [SOP, Observe-Think-Act-Share, severity, HitL, 인계포맷, 평가루프, 오케스트레이터]
---

# 016 — 소통 프로토콜 & SOP 구현 플랜

## Goal

사이클 2 연구(R-015)의 8개 발견을 에이전트 시스템에 반영한다.
에이전트 간 소통을 **자유 텍스트 → 구조화된 SOP 기반 프로토콜**로 전환하여:
- 에이전트 행동의 예측가능성 향상
- 인계/평가루프의 자동화 수준 향상
- 환각 캐스케이딩 구조적 차단

## Scope

### Included
| # | Item | Description |
|---|------|-------------|
| 1 | 5개 워커 에이전트 SOP 행동 루프 | Analysis Framework → SOP: 행동 루프 (O→T→A→S) |
| 2 | 오케스트레이터 SOP 마스터 섹션 | 워커 SOP의 입출력 관리 메타 섹션 |
| 3 | severity 기반 verdict 자동 판정 | Evaluation Loop Protocol에 severity + 판정 규칙 |
| 4 | HitL 7개 트리거 | 오케스트레이터에 Human-in-the-Loop 프로토콜 |
| 5 | handover.yaml 확장 | 필수 필드 5개 추가 + 릴레이 감쇠 규칙 |
| 6 | evaluation.yaml 확장 | severity, overall_score, conditional_pass 처리 |

### Excluded
| Item | Reason/Timeline |
|------|-----------------|
| 역할별 검증 기준 세트 (PSY-01~07 등) | 사이클 3 (페르소나 강화) |
| confidence 판정 기준 에이전트 프롬프트 인코딩 | 사이클 3 |
| 공유 기억 체계 설계 | 사이클 3 |

## Structural Decisions

> No structural decisions required — 연구(R-015)에서 모든 충돌이 해결됨. 인계 파일은 YAML-only + full_document 참조, 릴레이 감쇠는 파이프라인에만 적용.

---

## File Change Summary

### Modified Files
| # | File Path | Change Description |
|---|-----------|-------------------|
| 1 | `.claude/agents/psychology-expert.md` | `# Analysis Framework` → `# SOP: 행동 루프` (Observe/Think/Act/Share 4섹션) |
| 2 | `.claude/agents/mbti-expert.md` | 동일 구조 변환 (역할별 SOP 변형) |
| 3 | `.claude/agents/enneagram-expert.md` | 동일 구조 변환 (역할별 SOP 변형) |
| 4 | `.claude/agents/coding-expert.md` | 동일 구조 변환 (역할별 SOP 변형) |
| 5 | `.claude/agents/uiux-expert.md` | 동일 구조 변환 (역할별 SOP 변형) |
| 6 | `.claude/agents/orchestrator.md` | SOP 마스터 섹션 + severity verdict + HitL 트리거 추가 |
| 7 | `.claude/work-orders/_templates/handover.yaml` | 필수 필드 5개 추가 + 릴레이 감쇠 주석 |
| 8 | `.claude/work-orders/_templates/evaluation.yaml` | severity + overall_score + conditional_pass 처리 |

### New Files
| # | File Path | Description |
|---|-----------|-------------|
| — | (없음) | |

---

## Step 1 — psychology-expert.md: Analysis Framework → SOP 행동 루프

### Approach

`# Analysis Framework` 섹션(5항목 체크리스트)을 `# SOP: 행동 루프`로 교체한다.
기존 Analysis Framework의 5개 항목은 Think 단계에 그대로 보존한다.

### Current Code
```markdown
<!-- .claude/agents/psychology-expert.md:32-39 -->
# Analysis Framework

문제를 받으면 다음 순서로 분석한다:
1. **범위 확인**: 이 주장/설계에 관련된 심리학 이론은 무엇인가?
2. **근거 수집**: 해당 이론의 학술적 지지 수준은? (메타분석 > 개별 연구 > 이론적 추론)
3. **측정 검증**: 심리측정학적 관점에서 측정 가능하고 타당한가?
4. **윤리 점검**: 바넘 효과, 확증 편향, 라벨링 위험이 있는가?
5. **프로젝트 정합**: 이 프로젝트의 "진단이 아닌 자기이해" 포지셔닝에 부합하는가?
```

### After Code
```markdown
<!-- .claude/agents/psychology-expert.md -->
# SOP: 행동 루프

모든 작업은 Observe → Think → Act → Share 4단계로 수행한다.

## Observe: 입력 읽기

작업 시작 시 반드시 수행:
1. **작업 지시 확인**: 오케스트레이터가 전달한 구체적 작업 목표, 참조 파일 경로, 완료 기준을 확인한다.
2. **이전 산출물 읽기**: 지시에 참조 파일이 있으면 해당 파일의 frontmatter(summary, key_findings)를 우선 읽는다.
3. **기억 조회**: `.claude/agent-memory/psychology-expert/_index.yaml`에서 관련 기억을 확인한다.
4. **검증 대상 읽기**: 검증 작업이면 대상 산출물의 전체 내용(Level 1)을 읽는다.

## Think: 분석 & 판단

Observe에서 수집한 정보를 다음 순서로 분석한다:
1. **범위 확인**: 이 주장/설계에 관련된 심리학 이론은 무엇인가?
2. **근거 수집**: 해당 이론의 학술적 지지 수준은? (메타분석 > 개별 연구 > 이론적 추론)
3. **측정 검증**: 심리측정학적 관점에서 측정 가능하고 타당한가?
4. **윤리 점검**: 바넘 효과, 확증 편향, 라벨링 위험이 있는가?
5. **프로젝트 정합**: 이 프로젝트의 "진단이 아닌 자기이해" 포지셔닝에 부합하는가?

## Act: 산출물 생성

Think의 분석 결과를 산출물로 생산한다:
- **검증 작업**: evaluation YAML 포맷으로 verdict + criteria 작성
- **자문 작업**: YAML frontmatter + Markdown body 보고서 작성
- **문항/텍스트 수정**: 직접 Edit으로 수정 + 변경 근거 기록
- 산출물은 오케스트레이터가 지정한 경로에 저장한다.

## Share: 인계 & 기록

작업 완료 시 반드시 수행:
1. **산출물 frontmatter 확인**: summary, key_findings, confidence 필드가 빠짐없이 작성되었는지 확인한다.
2. **confidence 수준 판정**: high(코드/데이터 직접 확인 또는 학술 문헌 근거) / medium(분석+해석 혼합) / low(추론 기반).
3. **기억 저장**: 새로운 발견이 있으면 `.claude/agent-memory/psychology-expert/memories/`에 저장한다.
```

### Considerations

- 기존 Analysis Framework 5항목이 Think 단계에 **그대로 보존**됨 — 기존 에이전트 행동에 영향 없음
- Observe/Act/Share는 에이전트의 "프레임" 역할 — Think의 도메인 전문성을 감싸는 구조
- confidence 판정 기준은 사이클 3에서 더 구체화 예정. 현재는 3단계 가이드라인만 제공

---

## Step 2 — mbti-expert.md: Analysis Framework → SOP 행동 루프

### Approach

psychology-expert와 동일한 4단계 구조로 변환. Think 단계에 기존 5항목 보존.
Observe/Act/Share는 mbti-expert 역할에 맞게 변형.

### Current Code
```markdown
<!-- .claude/agents/mbti-expert.md:31-37 -->
# Analysis Framework

1. **문화적 맥락**: 이 기능/문항이 한국 사용자에게 어떻게 받아들여질까?
2. **법적 안전성**: 저작권/상표권 리스크는 없는가?
3. **학문적 정합성**: 심리학 전문가와의 정합성은 유지되는가?
4. **재미 vs 정확 밸런스**: 사용자 참여를 유도하면서 정확성을 유지하는가?
5. **경쟁 포지셔닝**: 기존 서비스 대비 어떤 차별점이 있는가?
```

### After Code
```markdown
<!-- .claude/agents/mbti-expert.md -->
# SOP: 행동 루프

모든 작업은 Observe → Think → Act → Share 4단계로 수행한다.

## Observe: 입력 읽기

작업 시작 시 반드시 수행:
1. **작업 지시 확인**: 오케스트레이터가 전달한 작업 목표, 참조 파일 경로, 완료 기준을 확인한다.
2. **이전 산출물 읽기**: 지시에 참조 파일이 있으면 해당 파일의 frontmatter를 우선 읽는다.
3. **기억 조회**: `.claude/agent-memory/mbti-expert/_index.yaml`에서 관련 기억을 확인한다.
4. **기존 데이터 확인**: 문항/유형 관련 작업이면 `db/seeds/` 및 기존 콘텐츠 파일을 확인한다.
5. **피드백 확인**: 재작업이면 이전 evaluation의 fix_suggestion을 주의 깊게 읽는다.

## Think: 분석 & 판단

Observe에서 수집한 정보를 다음 순서로 분석한다:
1. **문화적 맥락**: 이 기능/문항이 한국 사용자에게 어떻게 받아들여질까?
2. **법적 안전성**: 저작권/상표권 리스크는 없는가?
3. **학문적 정합성**: 심리학 전문가와의 정합성은 유지되는가?
4. **재미 vs 정확 밸런스**: 사용자 참여를 유도하면서 정확성을 유지하는가?
5. **경쟁 포지셔닝**: 기존 서비스 대비 어떤 차별점이 있는가?

## Act: 산출물 생성

Think의 분석 결과를 산출물로 생산한다:
- **문항 설계**: 문항 초안을 YAML frontmatter + Markdown body로 작성
- **유형 설명 작성**: 16유형별 텍스트를 지정 포맷으로 작성
- **콘텐츠 수정**: 기존 문항/설명의 Edit 수정 + 변경 근거 기록
- 산출물은 오케스트레이터가 지정한 경로에 저장한다.

## Share: 인계 & 기록

작업 완료 시 반드시 수행:
1. **산출물 frontmatter 확인**: summary, key_findings, confidence 필드가 빠짐없이 작성되었는지 확인한다.
2. **confidence 수준 판정**: high(데이터 직접 확인 또는 법적 근거 명확) / medium(분석+해석 혼합) / low(추론 기반).
3. **심리학 검증 필요 플래그**: 학술 검증이 필요한 콘텐츠에 `validation.validator_agent: psychology-expert`를 명시한다.
4. **기억 저장**: 새로운 발견이 있으면 기억에 저장한다.
```

### Considerations

- mbti-expert의 Observe에 **기존 데이터 확인**(4번)과 **피드백 확인**(5번)이 추가 — 설계 에이전트 특성 반영
- Share에 **검증 필요 플래그**(3번) 추가 — mbti가 생성한 콘텐츠를 psychology가 검증하는 파이프라인 지원

---

## Step 3 — enneagram-expert.md: Analysis Framework → SOP 행동 루프

### Approach

mbti-expert와 유사한 설계 에이전트 변형. Think에 기존 5항목 보존.

### Current Code
```markdown
<!-- .claude/agents/enneagram-expert.md:31-37 -->
# Analysis Framework

1. **동기 탐색**: 이 설계가 사용자의 핵심 동기(core motivation)를 탐색하는 데 도움이 되는가?
2. **건강 수준**: 유형의 건강 수준을 반영하고 있는가? (고정된 라벨 vs 성장 스펙트럼)
3. **복합 프로필**: 날개와 본능 하위유형까지 고려한 풍부한 프로필을 제공하는가?
4. **성장 가이드**: 통합/분열 방향이 "성장 가이드"로 활용되고 있는가?
5. **보완 관계**: MBTI 기반 접근과 어떻게 보완적으로 작동하는가?
```

### After Code
```markdown
<!-- .claude/agents/enneagram-expert.md -->
# SOP: 행동 루프

모든 작업은 Observe → Think → Act → Share 4단계로 수행한다.

## Observe: 입력 읽기

작업 시작 시 반드시 수행:
1. **작업 지시 확인**: 오케스트레이터가 전달한 작업 목표, 참조 파일 경로, 완료 기준을 확인한다.
2. **이전 산출물 읽기**: 지시에 참조 파일이 있으면 해당 파일의 frontmatter를 우선 읽는다.
3. **기억 조회**: `.claude/agent-memory/enneagram-expert/_index.yaml`에서 관련 기억을 확인한다.
4. **기존 데이터 확인**: 유형/문항 관련 작업이면 `db/seeds/` 및 기존 콘텐츠 파일을 확인한다.
5. **피드백 확인**: 재작업이면 이전 evaluation의 fix_suggestion을 주의 깊게 읽는다.

## Think: 분석 & 판단

Observe에서 수집한 정보를 다음 순서로 분석한다:
1. **동기 탐색**: 이 설계가 사용자의 핵심 동기(core motivation)를 탐색하는 데 도움이 되는가?
2. **건강 수준**: 유형의 건강 수준을 반영하고 있는가? (고정된 라벨 vs 성장 스펙트럼)
3. **복합 프로필**: 날개와 본능 하위유형까지 고려한 풍부한 프로필을 제공하는가?
4. **성장 가이드**: 통합/분열 방향이 "성장 가이드"로 활용되고 있는가?
5. **보완 관계**: MBTI 기반 접근과 어떻게 보완적으로 작동하는가?

## Act: 산출물 생성

Think의 분석 결과를 산출물로 생산한다:
- **유형 설계**: 9유형+날개+본능 조합 설명을 YAML frontmatter + Markdown body로 작성
- **문항 설계**: 동기 탐색 문항 초안 작성
- **성장 가이드**: 통합/분열 방향별 성장 경로 설계
- 산출물은 오케스트레이터가 지정한 경로에 저장한다.

## Share: 인계 & 기록

작업 완료 시 반드시 수행:
1. **산출물 frontmatter 확인**: summary, key_findings, confidence 필드가 빠짐없이 작성되었는지 확인한다.
2. **confidence 수준 판정**: high(데이터 직접 확인 또는 학파 간 합의) / medium(분석+해석 혼합) / low(추론 기반).
3. **심리학 검증 필요 플래그**: 학술 검증이 필요한 콘텐츠에 `validation.validator_agent: psychology-expert`를 명시한다.
4. **기억 저장**: 새로운 발견이 있으면 기억에 저장한다.
```

---

## Step 4 — coding-expert.md: Analysis Framework → SOP 행동 루프

### Approach

구현 에이전트 역할에 맞는 SOP 변형. Observe에 코드 탐색, Act에 TDD+구현, Share에 파일 목록+테스트 결과.

### Current Code
```markdown
<!-- .claude/agents/coding-expert.md:31-37 -->
# Analysis Framework

1. **Rails 컨벤션**: 이 요구사항을 어떤 패턴으로 구현하는가? (모델, 컨트롤러, 서비스 객체, concern)
2. **테스트 설계**: 어떤 테스트가 필요한가? (단위, 통합, 엣지 케이스)
3. **데이터 모델**: 스키마가 적절한가? (정규화, 인덱스, 마이그레이션)
4. **성능**: N+1 쿼리, 캐싱, 비동기 처리 고려사항은?
5. **보안/프라이버시**: 요구사항을 충족하는가?
```

### After Code
```markdown
<!-- .claude/agents/coding-expert.md -->
# SOP: 행동 루프

모든 작업은 Observe → Think → Act → Share 4단계로 수행한다.

## Observe: 입력 읽기

작업 시작 시 반드시 수행:
1. **작업 지시 확인**: 오케스트레이터가 전달한 작업 목표, 참조 파일 경로, 완료 기준을 확인한다.
2. **이전 산출물 읽기**: 지시에 참조 파일이 있으면 해당 파일의 frontmatter를 우선 읽는다.
3. **기억 조회**: `.claude/agent-memory/coding-expert/_index.yaml`에서 관련 기억을 확인한다.
4. **코드 탐색**: 구현 대상 관련 파일을 Glob/Grep/Read로 탐색하여 현재 구조를 파악한다.
5. **DB 현황 확인**: 마이그레이션/스키마 변경이 필요하면 `db/schema.rb`와 기존 마이그레이션을 확인한다.

## Think: 분석 & 판단

Observe에서 수집한 정보를 다음 순서로 분석한다:
1. **Rails 컨벤션**: 이 요구사항을 어떤 패턴으로 구현하는가? (모델, 컨트롤러, 서비스 객체, concern)
2. **테스트 설계**: 어떤 테스트가 필요한가? (단위, 통합, 엣지 케이스)
3. **데이터 모델**: 스키마가 적절한가? (정규화, 인덱스, 마이그레이션)
4. **성능**: N+1 쿼리, 캐싱, 비동기 처리 고려사항은?
5. **보안/프라이버시**: 요구사항을 충족하는가?

## Act: 산출물 생성

Think의 분석 결과를 코드로 구현한다:
- **TDD**: 테스트를 먼저 작성하고, 구현 코드를 작성한다.
- **구현**: Rails 컨벤션을 따르는 모델/컨트롤러/서비스/마이그레이션 작성
- **검증**: `bundle exec rspec` 또는 관련 테스트 실행으로 구현 확인
- 산출물은 오케스트레이터가 지정한 경로에 저장한다.

## Share: 인계 & 기록

작업 완료 시 반드시 수행:
1. **산출물 frontmatter 확인**: 보고서 형태의 산출물이면 summary, key_findings, confidence 필드를 작성한다.
2. **변경 파일 목록**: 생성/수정한 파일 경로를 명시한다.
3. **테스트 결과**: 실행한 테스트와 결과(pass/fail/pending)를 기록한다.
4. **confidence 수준 판정**: high(테스트 통과 + 코드 직접 확인) / medium(부분 테스트 또는 추정 포함) / low(미테스트).
5. **기억 저장**: 새로운 패턴이나 결정이 있으면 기억에 저장한다.
```

---

## Step 5 — uiux-expert.md: Analysis Framework → SOP 행동 루프

### Approach

UX 에이전트 역할에 맞는 SOP 변형. Observe에 사용자 컨텍스트/뷰 파일, Act에 Tailwind+Hotwire 구현.

### Current Code
```markdown
<!-- .claude/agents/uiux-expert.md:32-38 -->
# Analysis Framework

1. **감정 상태**: 이 화면에서 사용자는 어떤 감정 상태에 있는가?
2. **정보 구조**: 직관적인가? 인지 부하가 과도하지 않은가?
3. **모바일 경험**: 터치 타겟, 스크롤 깊이, 로딩 경험은 적절한가?
4. **접근성**: 색상 대비, 키보드 네비게이션, 스크린리더 기준을 충족하는가?
5. **문화적 적합**: 한국 사용자의 기대와 관습에 부합하는가?
```

### After Code
```markdown
<!-- .claude/agents/uiux-expert.md -->
# SOP: 행동 루프

모든 작업은 Observe → Think → Act → Share 4단계로 수행한다.

## Observe: 입력 읽기

작업 시작 시 반드시 수행:
1. **작업 지시 확인**: 오케스트레이터가 전달한 작업 목표, 참조 파일 경로, 완료 기준을 확인한다.
2. **이전 산출물 읽기**: 지시에 참조 파일이 있으면 해당 파일의 frontmatter를 우선 읽는다.
3. **기억 조회**: `.claude/agent-memory/uiux-expert/_index.yaml`에서 관련 기억을 확인한다.
4. **뷰 파일 확인**: 관련 뷰 파일(`app/views/`)과 레이아웃을 확인한다.
5. **콘텐츠 구조 확인**: 표시할 콘텐츠의 데이터 구조와 양을 확인한다.

## Think: 분석 & 판단

Observe에서 수집한 정보를 다음 순서로 분석한다:
1. **감정 상태**: 이 화면에서 사용자는 어떤 감정 상태에 있는가?
2. **정보 구조**: 직관적인가? 인지 부하가 과도하지 않은가?
3. **모바일 경험**: 터치 타겟, 스크롤 깊이, 로딩 경험은 적절한가?
4. **접근성**: 색상 대비, 키보드 네비게이션, 스크린리더 기준을 충족하는가?
5. **문화적 적합**: 한국 사용자의 기대와 관습에 부합하는가?

## Act: 산출물 생성

Think의 분석 결과를 UI로 구현한다:
- **뷰 구현**: Hotwire/Turbo + Tailwind CSS로 뷰 파일 작성/수정
- **Stimulus 컨트롤러**: 인터랙션이 필요하면 Stimulus 컨트롤러 작성
- **접근성 검증**: WCAG 2.1 기준 충족 여부를 코드 레벨에서 확인
- 산출물은 오케스트레이터가 지정한 경로에 저장한다.

## Share: 인계 & 기록

작업 완료 시 반드시 수행:
1. **산출물 frontmatter 확인**: 보고서 형태의 산출물이면 summary, key_findings, confidence 필드를 작성한다.
2. **변경 뷰 목록**: 생성/수정한 뷰 파일 경로를 명시한다.
3. **접근성 결과**: WCAG 기준 충족 여부를 기록한다.
4. **confidence 수준 판정**: high(구현+접근성 확인 완료) / medium(부분 확인) / low(미확인).
5. **기억 저장**: 새로운 UX 패턴이나 결정이 있으면 기억에 저장한다.
```

---

## Step 6 — orchestrator.md: SOP 마스터 + severity verdict + HitL 트리거

### Approach

orchestrator.md에 3가지를 추가/수정한다:
1. **`# SOP Master Protocol`** 새 섹션 — Agent Delegation Protocol 뒤에 추가
2. **Evaluation Loop Protocol 확장** — severity 기반 verdict + conditional_pass 처리
3. **`# Human-in-the-Loop Protocol`** 새 섹션 — Red Lines 앞에 추가

### Current Code — Agent Delegation Protocol 뒤 (삽입 지점)
```markdown
<!-- .claude/agents/orchestrator.md:106-135 -->
# Agent Delegation Protocol
(... 기존 내용 유지 ...)

# Evaluation Loop Protocol
```

### After Code — SOP Master Protocol (새 섹션, Agent Delegation Protocol과 Evaluation Loop 사이에 삽입)
```markdown
# SOP Master Protocol

워커 에이전트는 Observe → Think → Act → Share의 SOP 행동 루프를 따른다.
오케스트레이터는 이 루프의 입출력을 관리한다.

## 워커 스폰 시 Observe 재료 구성

에이전트를 스폰할 때, 프롬프트에 아래 5가지를 반드시 포함하여 워커의 Observe 단계를 지원한다:

1. **작업 목표**: 구체적으로 무엇을 생산해야 하는지
2. **참조 파일 경로**: 이전 단계 산출물, 관련 데이터 파일
3. **산출물 저장 위치**: `.claude/work-orders/{workflow-id}/step-{N}_{slug}.md`
4. **완료 기준**: 어떤 상태가 되면 작업이 완료인지
5. **이전 피드백** (재작업 시): 이전 evaluation의 summary + fail 항목의 fix_suggestion

## Share 산출물 확인 프로토콜

워커 완료 후 산출물을 확인할 때:

1. **Level 2 읽기**: frontmatter의 summary + key_findings로 결과 파악
2. **confidence 확인**: high → 추가 검증 없이 진행 / medium → 검증 에이전트 1회 / low → 반드시 교차 검증
3. **다음 단계 결정**: key_findings와 next_steps를 기반으로 후속 에이전트 스폰 여부 결정

## 릴레이 감쇠 규칙 (파이프라인 전용)

파이프라인(Pattern A, C)에서 에이전트 간 산출물이 전달될 때:
- 수신측 에이전트의 confidence는 원본 에이전트의 confidence보다 **한 단계 낮게** 시작한다.
  (high → medium → low)
- 3단계 이상 릴레이된 정보는 원본 파일을 직접 읽도록 지시한다.
- 평가루프(Pattern B) 내에서는 검증자가 원본에 직접 접근하므로 감쇠를 적용하지 않는다.
```

### Current Code — Evaluation Loop Protocol
```markdown
<!-- .claude/agents/orchestrator.md:137-163 -->
# Evaluation Loop Protocol

## 평가 결과 포맷

검증 에이전트에게 아래 포맷으로 평가 결과를 작성하도록 지시한다:

```yaml
---
evaluation:
  verdict: pass | fail | conditional_pass
  iteration: 1
  max_iterations: 3
  criteria:
    - name: "{기준명}"
      status: pass | fail
      detail: "{상세 설명}"
      fix_suggestion: "{수정 제안}"  # fail인 경우만
  summary: "{1-2줄 종합 판단}"
---
```

## 가드레일

1. **최대 반복**: 3회 하드코딩. 3회 후에도 fail이면 현재 최선 결과 + 미해결 사항 목록으로 진행
2. **점수 미개선 시 중단**: 이전 반복 대비 개선이 없으면 즉시 중단
3. **턴 예산 관리**: 전체 워크플로우에서 평가루프는 1개만 포함 (maxTurns 30 제약)
```

### After Code — Evaluation Loop Protocol (확장)
```markdown
# Evaluation Loop Protocol

## 평가 결과 포맷

검증 에이전트에게 아래 포맷으로 평가 결과를 작성하도록 지시한다:

```yaml
---
evaluation:
  verdict: pass | fail | conditional_pass
  iteration: 1
  max_iterations: 3
  workflow_id: ""
  step: 0
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

## severity 기반 verdict 자동 판정

| fail 항목 유형 | verdict | 후속 처리 |
|--------------|---------|----------|
| 없음 | **pass** | 다음 단계 진행 |
| minor만 | **conditional_pass** | 생성 에이전트에 minor 수정 1회 지시 (재평가 없이 자동 통과). "나머지 변경 금지" 명시 |
| major 포함 | **fail** | 재생성 (iteration++) |
| blocker 포함 | **fail** | 재생성 + blocker를 우선 수정 대상으로 명시 |

## 점수 미개선 자동 감지

`overall_score`와 `previous_iterations`로 자동 판정:
- 현재 overall_score ≤ 이전 iteration의 overall_score → 즉시 루프 중단 + HitL 트리거
- 동일 criteria가 2회 연속 동일 fix_suggestion으로 fail → 자동 수정 불가 판정 + HitL 트리거

## 가드레일

1. **최대 반복**: 3회 하드코딩. 3회 후에도 fail이면 현재 최선 결과 + 미해결 사항 목록으로 진행
2. **점수 미개선 시 중단**: overall_score 기반 자동 감지 (위 참조)
3. **턴 예산 관리**: 전체 워크플로우에서 평가루프는 1개만 포함 (maxTurns 30 제약)
4. **conditional_pass 효율**: minor만 남은 경우 재평가 없이 1회 수정으로 처리하여 턴 절약
```

### After Code — Human-in-the-Loop Protocol (새 섹션, Red Lines 앞에 삽입)
```markdown
# Human-in-the-Loop Protocol

## HitL 트리거

아래 상황에서는 자동 진행을 중단하고 사용자에게 개입을 요청한다:

| # | 트리거 | 긴급도 |
|---|--------|-------|
| H1 | max_iterations 도달 (3회 fail 후) | 필수 |
| H2 | 점수 미개선 (2회 연속 overall_score 동일/하락) | 필수 |
| H3 | 동일 criteria가 2회 연속 동일 fix_suggestion으로 fail | 필수 |
| H4 | blocker 수준에서 도메인 전문가 간 의견 충돌 | 높음 |
| H5 | 파괴적 작업 (DB 마이그레이션, 파일 대량 삭제) | 필수 |
| H6 | 워크플로우 유형 불명확 (패턴 선택 확신 없음) | 높음 |
| H7 | 저작권/법적 판단이 필요한 콘텐츠 | 높음 |

## 개입 요청 포맷

```
⚠️ 사용자 개입 요청

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

## 개입 후 재개

- 사용자 선택 1: 미해결 사항을 manifest의 `checkpoint.unresolved`에 기록하고 다음 단계로 진행
- 사용자 선택 2: 사용자의 수정 완료를 기다린 후 검증 에이전트 재스폰
- 사용자 선택 3: manifest를 `status: aborted`로 갱신하고 종료
- 사용자 선택 4: 해당 criteria를 제거/하향하고 현재 결과를 재판정
```

### Considerations

- SOP Master Protocol은 워커 스폰 시의 "재료 목록"을 표준화 — 기존 Agent Delegation Protocol의 4항목(지시/경로/위치/기준)을 5항목으로 확장
- severity 판정 규칙은 검증 에이전트가 아닌 **오케스트레이터가 적용** — 검증 에이전트는 severity를 태깅하고, 오케스트레이터가 verdict를 결정
- HitL 포맷은 사용자가 빠르게 판단할 수 있도록 이력 테이블 + 4개 선택지로 구조화

---

## Step 7 — handover.yaml: 필수 필드 추가 + 릴레이 감쇠 주석

### Approach

현재 최소 구조에서 연구가 식별한 5개 누락 필드를 추가하고, 릴레이 감쇠 규칙을 주석으로 안내한다.

### Current Code
```yaml
<!-- .claude/work-orders/_templates/handover.yaml:1-22 -->
# 에이전트 간 인계 파일 템플릿
# 사이클 2(SOP)에서 상세화 예정. 현 단계에서는 최소 구조만 정의.

handover_id: "WF-{id}-STEP-{N}"
workflow_id: ""
source:
  agent: ""
  task: ""
  confidence: high | medium | low
target:
  agent: ""
  expected_action: ""
summary: >
  {1-3줄 요약}
artifacts:
  - path: ""
    sections: []
next_steps:
  - ""
validation:
  criteria: ""
  validator_agent: ""
```

### After Code
```yaml
# 에이전트 간 인계 파일 템플릿
# SOP Share 단계에서 산출물 frontmatter와 함께 자동 생성됨.
#
# 릴레이 감쇠 규칙 (파이프라인 전용):
#   - 수신측 confidence는 원본보다 한 단계 낮게 시작 (high→medium→low)
#   - 3단계 이상 릴레이된 정보는 원본(full_document) 직접 확인 필수
#   - 평가루프 내에서는 감쇠 미적용 (검증자가 원본 직접 접근)

handover_id: "WF-{id}-STEP-{N}"
workflow_id: ""
created: ""                        # 생성 일시 (YYYY-MM-DD)
status: pending | delivered | read  # 인계 상태 추적
source:
  agent: ""
  task: ""
  confidence: high | medium | low
  # confidence 판정 기준:
  #   high: 코드/데이터 직접 확인, 2+ 에이전트 교차 확인, 학술 문헌 근거
  #   medium: 코드 분석 + 해석 혼합, 단일 에이전트 독립 발견
  #   low: 추론/추정 기반, 불확실한 정보 의존
target:
  agent: ""
  expected_action: ""
summary: >
  {1-3줄 요약}
key_findings:                       # Level 2 요약의 핵심 요소
  - ""
artifacts:
  - path: ""
    sections: []
next_steps:
  - ""
constraints:                        # 수신 에이전트의 제약 조건
  - ""
context_level: 3                    # 이 인계 파일의 압축 수준 (1/2/3)
full_document: ""                   # Level 1 원본 참조 경로
validation:
  criteria: ""
  validator_agent: ""
```

### Considerations

- `status` 필드(pending/delivered/read)는 현재 자동 추적되지 않으나, 향후 오케스트레이터가 관리할 수 있는 구조적 훅
- `context_level: 3`이 기본값 — 인계 파일 자체는 Level 3(최소 인계), `full_document`로 Level 1 접근

---

## Step 8 — evaluation.yaml: severity + overall_score + conditional_pass

### Approach

기존 evaluation.yaml에 severity, overall_score, conditional_pass 관련 필드와 주석을 추가한다.

### Current Code
```yaml
<!-- .claude/work-orders/_templates/evaluation.yaml:1-18 -->
# 평가루프 결과 파일 템플릿

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
  summary: >
    {1-2줄 종합 판단}
  previous_iterations: []  # 이전 반복의 verdict 이력
```

### After Code
```yaml
# 평가루프 결과 파일 템플릿
#
# severity 기반 verdict 자동 판정:
#   blocker/major fail 있음 → verdict: fail (재생성)
#   minor fail만 있음 → verdict: conditional_pass (1회 수정, 재평가 없이 자동 통과)
#   fail 없음 → verdict: pass
#
# conditional_pass 처리:
#   생성 에이전트에 minor 수정만 지시. "나머지 변경 금지" 명시.
#   재평가 없이 자동 통과하여 턴 절약.

evaluation:
  verdict: pass | fail | conditional_pass
  iteration: 1
  max_iterations: 3
  workflow_id: ""
  step: 0
  evaluator: ""
  target_agent: ""
  overall_score: 0.0                # count(pass) / count(total criteria)
  criteria:
    - name: ""
      severity: blocker | major | minor
      # severity 가이드:
      #   blocker: 이것이 해결되지 않으면 산출물을 사용할 수 없음
      #   major: 품질에 심각한 영향이 있으나 부분적 사용은 가능
      #   minor: 개선이 바람직하나 현재 상태로도 수용 가능
      status: pass | fail
      detail: ""
      fix_suggestion: ""            # fail인 경우만
  summary: >
    {1-2줄 종합 판단}
  previous_iterations:
    - iteration: 0
      overall_score: 0.0
      verdict: ""
      failed_criteria: []           # fail한 criteria의 name 목록
```

---

## Considerations & Trade-offs

### Structural Decisions Log

연구(R-015)에서 이미 해결된 결정:
- 인계 파일 = YAML-only + full_document 참조 (Markdown body 미포함)
- 릴레이 감쇠 = 파이프라인 전용 (평가루프 내 미적용)

### Alternative Approaches

| 방안 | 장점 | 채택 여부 | 사유 |
|------|------|---------|------|
| SOP를 별도 파일로 분리 | 프롬프트 길이 절약 | ❌ | 에이전트가 별도 파일을 읽을 보장 없음 |
| severity를 워커가 자체 판정 | 오케스트레이터 부하 감소 | ❌ | 검증 에이전트가 판정, 오케스트레이터가 verdict 결정이 더 정확 |
| HitL을 별도 설정 파일로 | 오케스트레이터 프롬프트 간결 | ❌ | 프롬프트에 직접 있어야 확실히 참조됨 |

### Potential Risks

- **프롬프트 길이 증가**: 5개 에이전트 각각 ~300-500 토큰 증가, 오케스트레이터 ~500-700 토큰 증가. 현재 프롬프트가 충분히 짧으므로 수용 가능.
- **에이전트의 SOP 기계적 수행**: SOP가 체크리스트화되어 창의성이 저하될 수 있음. Think 단계의 자유도를 유지하여 완화.
- **conditional_pass 재평가 미실시**: minor 수정 후 재평가를 건너뛰므로, minor가 사실은 major였을 때 누락 가능. severity 판정 정확도에 의존.

### Backward Compatibility

- 기존 에이전트의 Analysis Framework 5항목이 Think 단계에 **그대로 보존**됨 — 기존 행동 호환성 유지
- 기존 evaluation.yaml/handover.yaml에 필드가 추가되나, YAML은 미사용 필드를 무시하므로 기존 워크플로우에 영향 없음
- 오케스트레이터의 기존 섹션(Agent Delegation Protocol, Workflow Pattern Selection 등)은 수정하지 않음

## Implementation Checklist

- [x] Step 1: psychology-expert.md Analysis Framework → SOP 행동 루프
- [x] Step 2: mbti-expert.md Analysis Framework → SOP 행동 루프
- [x] Step 3: enneagram-expert.md Analysis Framework → SOP 행동 루프
- [x] Step 4: coding-expert.md Analysis Framework → SOP 행동 루프
- [x] Step 5: uiux-expert.md Analysis Framework → SOP 행동 루프
- [x] Step 6: orchestrator.md SOP 마스터 + severity verdict + HitL 트리거
- [x] Step 7: handover.yaml 필수 필드 확장
- [x] Step 8: evaluation.yaml severity + overall_score 확장
- [x] Final verification

## Verification Assertions

| Level | Assertion | Verification Method | Expected Result |
|-------|-----------|-------------------|-----------------|
| L4-Trace | R-015-F1 SOP 4단계 인코딩 | /verify-trace | 5개 에이전트에 Observe/Think/Act/Share 존재 |
| L4-Trace | R-015-F2 Share=인계 통합 | /verify-trace | Share 섹션에 confidence + frontmatter 지침 |
| L4-Trace | R-015-F3 severity 기반 verdict | /verify-trace | evaluation 포맷에 severity 필드 + 판정 규칙 |
| L4-Trace | R-015-F4 HitL 7개 트리거 | /verify-trace | orchestrator에 H1-H7 트리거 테이블 |
| L4-Trace | R-015-F5 릴레이 감쇠 | /verify-trace | SOP Master에 감쇠 규칙 명시 |
| L4-Trace | R-015-F8 SOP 마스터 섹션 | /verify-trace | orchestrator에 SOP Master Protocol 존재 |

## References

| Resource | Path/URL | Related Content |
|----------|---------|-----------------|
| 사이클 2 연구 | `docs/07_organizational_agents/015_Research_소통프로토콜_SOP_최종.md` | R-015-F1~F8 발견 |
| 사이클 1 플랜 | `docs/07_organizational_agents/009_Plan_오케스트레이터_아키텍처.md` | 기존 구현 참조 |
| 인계 포맷 에이전트 보고서 | `docs/07_organizational_agents/011_Agent_인계포맷설계.md` | 상세 필드 설계 |
| SOP 행동 루프 보고서 | `docs/07_organizational_agents/012_Agent_SOP행동루프.md` | 프롬프트 매핑 상세 |
| 평가루프 보고서 | `docs/07_organizational_agents/013_Agent_평가루프HitL.md` | severity + HitL 상세 |
| Synthesis | `docs/07_organizational_agents/014_Synthesis_소통프로토콜SOP.md` | 관점 간 통합 |
