---
id: "001"
type: research
title: "CLI-first 최적 답변을 위한 Claude Code 지침 설계"
created: 2026-03-15
summary: >
  Xcode Platforms 탭 오안내 사례를 기반으로, Claude Code가 환경 설정/설치 안내 시 CLI 명령어를 우선
  제시하도록 하는 실용적 지침을 설계한다. 참조 문서(005, 006)의 4가지 기법을 Claude Code 맥락에
  적용성 평가하고, CLAUDE.md/memory에 추가할 구체적 지침 초안을 도출한다.
keywords: [CLI-first, anti-hallucination, RLHF-verbosity, guideline-design, CLAUDE.md]
---

# CLI-first 최적 답변을 위한 Claude Code 지침 설계

## Research Overview

### Background & Motivation

2026-03-15 세션에서 사용자가 Flutter 개발 환경 설정 중 Xcode iOS 시뮬레이터 다운로드 방법을
질문했다. Claude Code는 다음 순서로 답변했다:

1. **1차 답변**: "Xcode → Settings → Platforms 탭" GUI 경로 안내 (틀림)
2. **2차 답변**: "Components 탭을 클릭해보세요" 수정 안내 (부분 정확)
3. **3차 답변**: `xcodebuild -downloadPlatform iOS` 터미널 명령어 (최적해)

**최적 답변은 3차였지만 1차에 나왔어야 했다.**

이 실패는 LLM의 RLHF verbosity bias, sycophancy, autoregressive confabulation이
결합된 전형적 사례다 (docs/006 분석). 본 연구는 이를 방지할 지침을 설계한다.

### Research Scope

- **포함**: Claude Code의 CLAUDE.md/memory에 추가할 실용적 지침 설계
- **제외**: 시스템 프롬프트 변경 (사용자가 직접 수정 불가), 모델 fine-tuning

### Research Perspectives

1. **종합 분석** — 현행 갭 분석 + 참조 기법 평가 + 지침 초안 (단일 관점, 직접 연구)

---

## 종합 분석

### 1. 현행 지침 갭 분석

#### 조사 대상

| 파일 | 역할 | CLI-first 관련 지침 |
|------|------|-------------------|
| `~/.claude/CLAUDE.md` (global) | 전역 규칙 | **없음** — Pipeline/Agent 정책만 존재 |
| `CLAUDE.md` (project) | 프로젝트 규칙 | **없음** — 위임/에이전트/docs 관리만 존재 |
| 시스템 프롬프트 (내장) | Claude Code 기본 행동 | 부분적 — 아래 분석 참조 |
| memory (feedback) | 학습된 피드백 | 이번 세션에서 `feedback_cli_first.md` 신규 저장 |

#### 시스템 프롬프트에 이미 있는 관련 지침

시스템 프롬프트에는 CLI-first를 *간접적으로* 유도할 수 있는 지침이 존재한다:

1. **"Your responses should be short and concise"** — 간결성 원칙
2. **"Go straight to the point. Try the simplest approach first"** — 단순 우선 원칙
3. **"Keep your text output brief and direct"** — 직접성 원칙
4. **"You are an interactive CLI tool"** — CLI 정체성

**그러나 이것들은 실패를 방지하지 못했다. 이유:**

- "간결하게"는 *형식*을 제어하지만 *내용 선택*(CLI vs GUI)을 제어하지 않음
- "가장 단순한 접근"은 해석의 여지가 있음 — GUI가 "사용자에게 더 친숙하므로 단순하다"로 해석 가능
- "CLI tool"은 Claude Code 자체의 정체성이지, *안내 방식*에 대한 지침이 아님
- Explanatory output style("교육적 설명 제공")이 verbosity를 더 강화

#### 결론: 명시적 CLI-first 우선순위 지침이 완전히 부재

현행 지침 중 어떤 것도 "환경 설정 안내 시 CLI 명령어를 GUI보다 먼저 제시하라"를
직접적으로 규정하지 않는다. 이것이 핵심 갭이다.

---

### 2. 참조 문서 기법의 Claude Code 적용성 평가

docs/006 문서에서 제시한 4가지 기법을 Claude Code 맥락에서 평가한다.

#### 기법 1: Role Assignment (역할 부여)

| 항목 | 평가 |
|------|------|
| 원리 | "You are a senior DevOps engineer who communicates through terminal commands" |
| Claude Code 현황 | 시스템 프롬프트에 이미 "interactive CLI tool" 역할 존재 |
| 적용 가능성 | **낮음** — 역할은 이미 부여됨. 추가 역할 부여는 중복 |
| 효과 | 006 문서: "role prompting improves *tone and format* more reliably than *factual accuracy*" |
| 권장 | 추가 불필요. 기존 역할에 의존 |

#### 기법 2: Explicit Constraints with Priority Ordering (명시적 우선순위)

| 항목 | 평가 |
|------|------|
| 원리 | CLI → script → multi-step CLI → GUI (last resort) 순서 강제 |
| Claude Code 현황 | **완전 부재** — 이것이 핵심 갭 |
| 적용 가능성 | **최고** — CLAUDE.md에 직접 추가 가능 |
| 효과 | 006 문서: "the structural backbone", "unambiguous priority hierarchy" |
| 권장 | **최우선 적용** |

#### 기법 3: Few-shot Examples (예시)

| 항목 | 평가 |
|------|------|
| 원리 | 입출력 예시 2-3개로 형식 고정 |
| Claude Code 현황 | 부재 |
| 적용 가능성 | **중간** — CLAUDE.md에 예시를 넣으면 토큰 비용 증가, 하지만 memory에 참조용으로 가능 |
| 효과 | 006 문서: "Anthropic calls 'your secret weapon'" |
| 권장 | **선택적 적용** — memory/feedback에 안티패턴 예시로 저장 |

#### 기법 4: Anti-hallucination Guardrails (환각 방지)

| 항목 | 평가 |
|------|------|
| 원리 | "확실하지 않으면 말하지 않기", "모르면 모른다고 하기" |
| Claude Code 현황 | **부재** |
| 적용 가능성 | **높음** — CLAUDE.md에 1-2줄 추가로 구현 가능 |
| 효과 | 006 문서: "disproportionately effective", "can drastically reduce false information" |
| 권장 | **필수 적용** |

#### 적용성 종합 매트릭스

| 기법 | 효과 | 적용 비용 | Claude Code 적합성 | 권장 |
|------|------|----------|------------------|------|
| Role assignment | 중 | 불필요 | 이미 존재 | ✗ 추가 불요 |
| Explicit constraints | 최고 | 낮음 (3-5줄) | 핵심 갭 해결 | ✓ **최우선** |
| Few-shot examples | 높음 | 중간 (토큰) | 선택적 | △ memory 활용 |
| Anti-hallucination | 높음 | 낮음 (1-2줄) | 핵심 갭 해결 | ✓ **필수** |

**최적 조합: Explicit Constraints + Anti-hallucination Guardrails**

이 두 기법은 CLAUDE.md에 5-7줄 추가만으로 구현 가능하며, 핵심 실패 모드를 직접 차단한다.

---

### 3. 실용적 지침 설계

#### 3a. 지침 배치 위치 결정

| 위치 | 적용 범위 | 장점 | 단점 |
|------|----------|------|------|
| `~/.claude/CLAUDE.md` (global) | 모든 프로젝트 | 어디서든 적용 | 프로젝트 무관한 규칙 증가 |
| `CLAUDE.md` (project) | 이 프로젝트만 | 프로젝트 맞춤 | 다른 프로젝트에서 반복 필요 |
| memory/feedback | 이 프로젝트 디렉토리 | 이미 저장됨 | 강제력 낮음 (참고 수준) |

**권장: `~/.claude/CLAUDE.md` (global)**

CLI-first 원칙은 프로젝트 무관한 범용 지침이다. Flutter 환경 설정이든, Rails 설치든,
어느 프로젝트에서나 동일하게 적용되어야 한다.

#### 3b. 지침 초안 (Global CLAUDE.md 추가용)

```markdown
## 환경 설정·설치 안내 원칙

1. **CLI 우선**: 터미널 명령어를 `bash` 코드 블록으로 먼저 제시. 복사-붙여넣기 즉시 실행 가능하게.
2. **GUI는 보조**: CLI가 불가능할 때만 GUI 경로 안내. 이유 명시 ("이 작업은 GUI에서만 가능").
3. **불확실한 UI 요소 금지**: 메뉴/탭/버튼 이름이 확실하지 않으면 안내하지 않음. 추측하지 말 것.
4. **버전 변동성 인지**: GUI 경로는 소프트웨어 버전마다 변경됨. CLI 명령어는 상대적으로 안정적.
```

#### 3c. 지침 초안 (간결 버전 — 토큰 최소화)

위 지침이 CLAUDE.md 토큰 예산에 부담이라면:

```markdown
## 설치·환경 안내

CLI 명령어 먼저, GUI는 CLI 불가 시만. 불확실한 메뉴/탭 이름은 안내하지 않음.
```

#### 3d. Memory feedback 보강 (이미 저장된 feedback_cli_first.md 개선안)

현재 저장된 memory는 적절하나, 006 문서의 핵심 인사이트를 한 줄 추가하면 더 효과적:

> "CLI 출력은 실패 시 에러가 보이지만, 잘못된 GUI 경로는 조용히 실패한다(silent failure).
> 따라서 CLI 안내가 구조적으로 더 안전하다."

---

### Caveats & Risks

1. **과도한 CLI 강제의 부작용**: 초보 사용자에게는 GUI가 더 접근성 높을 수 있음.
   → 해결: "사용자가 명시적으로 GUI를 요청하면 제공" 예외 조항 포함.

2. **CLAUDE.md 비대화**: 규칙이 많아지면 모델이 우선순위를 놓칠 수 있음.
   → 해결: 간결 버전(3c) 사용 권장. 2줄이면 충분.

3. **Explanatory style과의 긴장**: 교육적 설명을 요구하는 현재 output style이
   verbosity를 강화할 수 있음.
   → 이것은 별도 이슈. CLI-first 규칙이 있으면 "교육적이되 CLI 중심"으로 자연 균형.

4. **Memory feedback의 한계**: memory는 "권장" 수준이지 "강제" 수준이 아님.
   CLAUDE.md에 명시하는 것이 더 강한 구속력을 가짐.

---

## Comprehensive Conclusion

### 핵심 발견 (우선순위 순)

1. **[Critical] R-001-F1: 명시적 CLI-first 우선순위 부재** — 현재 CLAUDE.md(global/project 모두)에
   환경 설정 안내 시 CLI vs GUI 우선순위를 지정하는 지침이 전혀 없다. 시스템 프롬프트의 "간결하게"
   "단순하게" 원칙은 너무 간접적이어서 RLHF verbosity bias를 이기지 못한다.

2. **[Critical] R-001-F2: Anti-hallucination guardrail 부재** — "확실하지 않은 GUI 요소를
   안내하지 마라"는 규칙이 없어, Xcode 16에 존재하지 않는 "Platforms 탭"을 자신있게 안내했다.
   006 문서에 따르면 이 guardrail은 "disproportionately effective"하다.

3. **[High] R-001-F3: Explicit Constraints가 가장 비용 효과적** — 4가지 기법 중 "명시적
   우선순위 규칙"은 CLAUDE.md에 2-5줄 추가만으로 구현 가능하며, 핵심 실패 모드를 직접 차단한다.
   Role assignment는 이미 존재하고, few-shot은 토큰 비용이 높아 선택적이다.

4. **[High] R-001-F4: Global CLAUDE.md가 최적 배치 위치** — CLI-first는 프로젝트 무관
   범용 원칙이므로 `~/.claude/CLAUDE.md`에 배치하는 것이 적합. Memory feedback은 보조 수단.

5. **[Medium] R-001-F5: "CLI는 실패가 보이고, GUI는 조용히 실패한다"** — 006 문서의 핵심
   인사이트. CLI 명령어가 틀리면 에러 메시지가 즉시 나오지만, 잘못된 GUI 경로는 "메뉴를 못 찾겠다"는
   무응답 실패로 이어진다. 이것이 CLI-first가 단순 선호가 아닌 **구조적 안전성** 원칙인 이유.

### 최종 권장 액션

| 우선순위 | 액션 | 대상 파일 | 분량 |
|---------|------|----------|------|
| 1 | CLI-first 우선순위 규칙 추가 | `~/.claude/CLAUDE.md` | 4-5줄 |
| 2 | 기존 feedback_cli_first.md에 silent failure 인사이트 추가 | memory/ | 1줄 |
| 3 | (선택) 프로젝트 CLAUDE.md에도 축약 버전 추가 | `CLAUDE.md` | 1줄 |

## Unresolved Items

- **Explanatory style과 CLI-first의 균형점**: 교육적 설명과 간결한 CLI 안내를 어떻게 조화시킬지는
  추가 실험이 필요. 현재는 "Insight 블록에서 교육, 답변 본문에서 CLI 명령어"로 분리하는 것이 자연스러움.

## Referenced File List

| File Path | Role/Content |
|-----------|-------------|
| `~/.claude/CLAUDE.md` | Global 규칙 — Pipeline/Agent 정책만 존재, CLI-first 부재 |
| `CLAUDE.md` | Project 규칙 — 위임/에이전트/docs 관리, CLI-first 부재 |
| `docs/006_claude_compass_artifact_*.md` | 006 참조 — RLHF verbosity bias, 4가지 해결 기법 |
| `docs/005_chatgpt_deep-research-report.md` | 005 참조 — 프롬프트 설계 지침, 테스트 케이스 |
| `memory/feedback_cli_first.md` | 이번 세션 저장 — CLI 우선 피드백 |

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
