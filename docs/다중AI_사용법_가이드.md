# 다중 AI 사용법 가이드

personality 프로젝트에 구현된 다중 AI 시스템의 실용적 사용법.

---

## 1. 시스템 구성 개요

```
사용자
  │
  ├─ [claude] ────────── 메인 Claude Code (Opus)
  │                          └─ [/스킬명] ── Skill 시스템 (메인 에이전트가 실행)
  │
  ├─ [claude --agent orchestrator] ── orchestrator (Opus, 메인 스레드)
  │                                       │ Agent tool로 워커 스폰
  │                                       ├── psychology-expert (Sonnet)
  │                                       ├── mbti-expert (Sonnet)
  │                                       ├── enneagram-expert (Sonnet)
  │                                       ├── coding-expert (Sonnet)
  │                                       └── uiux-expert (Sonnet)
  │
  └─ [claude --agent {name}] ──── 개별 에이전트 직접 실행
```

**중요**: 오케스트레이터가 워커를 스폰하려면 반드시 `claude --agent` 플래그로
메인 스레드에서 실행해야 합니다. 일반 대화 중 Agent tool로 오케스트레이터를
호출하면 서브에이전트로 실행되어 워커 스폰이 불가능합니다.

### 에이전트 역할 요약

| 에이전트 | 모델 | 핵심 역할 | maxTurns |
|---------|------|----------|----------|
| **orchestrator** | Opus | 작업 분해, 에이전트 조정, 품질 관리 | 30 |
| **psychology-expert** | Sonnet | 학술 검증, 바넘효과 검출, 윤리 검토 | 15 |
| **mbti-expert** | Sonnet | MBTI 문항/유형 설계, 저작권 안전 | 15 |
| **enneagram-expert** | Sonnet | 애니어그램 9유형·날개·본능 설계 | 15 |
| **coding-expert** | Sonnet | Rails 백엔드 구현, TDD | 25 |
| **uiux-expert** | Sonnet | 모바일 퍼스트 UI/UX, 접근성 | 20 |

---

## 2. 사용 방법 3가지

### 방법 A: 오케스트레이터에 위임 (복합 작업) — `claude --agent`

여러 도메인이 관련된 복합 작업에 적합.

**내부 동작**: 오케스트레이터가 Pattern C(하이브리드)를 선택 →
mbti-expert가 문항 초안 → psychology-expert가 검증 →
fail 시 재작업 → pass 시 coding-expert가 코드 반영

**호출 방법** (터미널에서 새 세션 시작):
```bash
# 인라인 프롬프트
claude --agent orchestrator "E-I 도메인 문항 5개 추가, 학술 검증까지"

# 대화형
claude --agent orchestrator
> E-I 도메인 문항 5개를 추가하고 학술 검증해줘
```

> **왜 `--agent` 플래그가 필요한가?**
> 서브에이전트는 다른 서브에이전트를 스폰할 수 없는 시스템 제약이 있다.
> `--agent` 플래그로 실행하면 메인 스레드에서 동작하여 Agent tool 사용이 가능해진다.

### 방법 B: 개별 에이전트 직접 실행 (단일 도메인) — `claude --agent`

하나의 전문 영역만 필요할 때.

```bash
# 코드 구현만 필요할 때
claude --agent coding-expert "assessment 컨트롤러에 show 액션 추가해줘"

# 학술 검토만 필요할 때
claude --agent psychology-expert "이 유형 설명에 바넘 효과가 있는지 확인해줘"

# UI 작업만 필요할 때
claude --agent uiux-expert "결과 페이지의 모바일 레이아웃을 개선해줘"
```

### 방법 C: 스킬(Skill) 시스템 활용

에이전트가 아닌 **워크플로우 스킬**. 메인 에이전트가 직접 실행.

```
/scope          # 작업 범위 정의 (구현 전 필수)
/makeplan       # 구현 계획 문서 작성
/implementation # 계획 기반 구현
/verify         # 변경사항 검증
/tdd            # TDD 워크플로우
/research       # 심층 조사
/parallel-execute  # 병렬 에이전트 실행
/session-report    # 세션 보고서 생성
```

---

## 3. 오케스트레이터 워크플로우 패턴

오케스트레이터가 요청을 분석해 자동 선택하는 4가지 패턴:

### Pattern A: 파이프라인 (순차 실행)
```
[에이전트 A] → 산출물 → [에이전트 B] → 산출물 → [에이전트 C]
```
**적합**: DB 마이그레이션, 단순 버그 수정, 환경 설정

### Pattern B: 평가/정제 루프
```
[생성 에이전트] → 초안 → [검증 에이전트] → pass/fail
                    ↑                         │ fail
                    └─────── 피드백 ──────────┘  (최대 3회)
```
**적합**: 콘텐츠 품질 검증, 학술 정확성 검증

### Pattern C: 하이브리드 (가장 빈번)
```
Step 1: [전문 에이전트] → 초안
Step 2: [검증 에이전트] → 평가 (fail → Step 1 재작업, 최대 2회)
Step 3: [구현 에이전트] → 코드 반영
Step 4: [검토 에이전트] → 최종 검토 (선택)
```
**적합**: 새 문항 추가, 유형 설명 작성, 점수 엔진 수정

### Pattern D: 단일 위임
```
[에이전트 1개] → 결과
```
**적합**: 코드 리팩터링, 스타일 수정, 단순 분석

### 패턴 자동 선택 기준
```
단일 도메인? → 코드만 → Pattern D (coding-expert)
             → 콘텐츠만 → 학술 검증 필요? → Yes: Pattern B / No: Pattern D
다중 도메인? → 품질 검증 포함? → Yes: Pattern C / No: Pattern A
```

---

## 4. 에이전트 조합 가이드

자주 발생하는 작업별 에이전트 조합:

| 작업 | 주 에이전트 | 검증 에이전트 | 패턴 |
|------|-----------|-------------|------|
| 문항 개발/수정 | mbti / enneagram | psychology | C |
| 유형 설명 작성 | mbti / enneagram | psychology | C |
| 점수 엔진/로직 | coding | psychology | C |
| UI 컴포넌트 | uiux | — | D |
| DB/API 구현 | coding | — | D |
| 학술 검증 | psychology | — | D |
| 접근성/UX 검토 | uiux | — | D |
| 전체 기능 추가 | 전체 조합 | psychology | C |

---

## 5. 산출물과 파일 구조

### 산출물 저장 위치: `docs/` (중앙화)
```
docs/
├── {NN_카테고리}/                    # 주제별 폴더
│   ├── {NNN}_Scope_{제목}.md        # 범위 정의
│   ├── {NNN}_Research_{제목}.md     # 조사/분석
│   ├── {NNN}_Agent_{제목}.md        # 에이전트 관점 분석
│   ├── {NNN}_Synthesis_{제목}.md    # 종합 문서
│   └── {NNN}_Plan_{제목}.md         # 실행 계획
└── INDEX.md
```

### 산출물 포맷 (YAML frontmatter + Markdown body)
```yaml
---
summary: "한 줄 요약"
key_findings:
  - "핵심 발견 1"
  - "핵심 발견 2"
confidence: high | medium | low
next_steps:
  - "다음 단계 1"
---

# 본문 내용...
```

### 에이전트 기억 저장 위치 (산출물과 별도)
```
.claude/agent-memory/
├── _shared/              # 조직 공유 기억 (교차 도메인 결정/패턴)
│   ├── _index.yaml
│   └── memories/
├── psychology-expert/    # 개별 에이전트 기억 (도메인 학습)
├── mbti-expert/
├── enneagram-expert/
├── coding-expert/
└── uiux-expert/
```

**docs/ vs agent-memory/ 구분**:
- `docs/` = 프로젝트 지식 (사용자가 보는 영구 기록, 상세 보고서)
- `agent-memory/` = 에이전트 도메인 기억 (교차 세션 학습, 10~30줄 요약)
- agent-memory에 docs/ 산출물 본문을 복제하지 않는다. 경로만 `related_docs`로 참조

---

## 6. 실전 사용 예시

### 예시 1: 새 MBTI 문항 추가 (복합 작업)

```bash
# 1단계: 일반 claude 세션에서 범위 정의
claude
> /scope MBTI E-I 도메인 문항 5개 추가

# 2단계: 새 터미널에서 오케스트레이터 실행
claude --agent orchestrator "scope 문서 기반으로 E-I 문항 5개를 추가해줘. 학술 검증 + 코드 반영까지."

# 내부 동작:
# orchestrator → mbti-expert(문항 초안) → psychology-expert(검증)
# → pass → coding-expert(seeds 반영 + 테스트 작성)

# 3단계: 일반 claude 세션에서 검증
claude
> /verify
```

### 예시 2: 버그 수정 (단순 작업)

```bash
# 개별 에이전트로 직접 실행
claude --agent coding-expert "scoring 서비스에서 nil 점수 처리 버그 수정해줘"

# 또는 일반 세션에서 직접 요청 (에이전트 안 써도 됨)
claude
> scoring 서비스의 nil 점수 버그 수정해줘
```

### 예시 3: UI 개선 (단일 도메인)

```bash
claude --agent uiux-expert "결과 페이지의 유형 카드를 모바일에 맞게 리디자인해줘"
```

### 예시 4: 학술 검증 (검토 전용)

```bash
claude --agent psychology-expert "db/seeds/ 의 유형 설명 텍스트를 검토해줘. 바넘 효과와 결정론적 서술이 있는지 확인."
```

### 예시 5: 병렬 조사 (리서치)

```bash
# 스킬 시스템의 parallel-execute 활용
> /parallel-execute "MBTI 저작권 현황" "애니어그램 학술 근거" "경쟁 서비스 분석"

# 또는 리서치 스킬
> /research MBTI 서비스의 저작권 리스크 분석
```

---

## 7. 핵심 제약사항

| 제약 | 설명 |
|------|------|
| **오케스트레이터 30턴** | 전체 워크플로우가 30턴 내 완료되어야 함 |
| **워커 15-25턴** | 각 에이전트별 턴 제한 있음 |
| **순차 실행** | 에이전트는 병렬 실행 불가, 순차적으로 스폰됨 |
| **파일 기반 소통** | 에이전트 간 직접 대화 불가, 산출물 파일로만 인계 |
| **평가루프 최대 3회** | 검증 실패 시 최대 3회 재시도 후 사용자 개입 요청 |
| **모델 비용** | orchestrator=Opus, 워커=Sonnet (비용 최적화) |

---

## 8. 판단 기준: 에이전트 vs 직접 작업

```
작업이 단순하고 단일 도메인?
  → claude (일반 세션)에서 직접 요청하세요.
  → 또는 claude --agent {전문가} 로 단일 에이전트 실행.

작업이 복합적이고 검증이 필요?
  → claude --agent orchestrator 로 실행하세요.

작업이 워크플로우(scope→plan→impl→verify)?
  → claude (일반 세션)에서 /스킬을 순서대로 사용하세요.
```

**간단한 규칙**: 단순 → `claude`, 복합 → `claude --agent orchestrator`, 프로세스 → `/스킬`.

---

## 9. 자주 쓰는 스킬 워크플로우

### 표준 개발 파이프라인
```
/scope → /makeplan → /implementation → /verify → /session-report
```

### TDD 개발
```
/scope → /makeplan → /tdd → (반복: "go") → /verify
```

### 심층 조사 후 구현
```
/research → /scope → /makeplan → /implementation → /verify
```

### 에이전트 리뷰/비평
```
claude → /scope
claude --agent orchestrator (Pattern B 또는 C)
```
