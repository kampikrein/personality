---
id: "002"
type: research
title: "LLM 최적 응답을 위한 범용 대원칙: 최소 검증 경로 (Minimum Verifiable Path)"
created: 2026-03-15
summary: >
  CLI-first 원칙을 상위 일반화하여, 모든 도메인에 적용 가능한 범용 대원칙 "최소 검증 경로(MVP)"를
  도출한다. 4개 하위 원칙(실행 가능, 검증 가능, 최소 단계, 확신 비례)이 RLHF verbosity bias,
  sycophancy, confabulation 각각을 구조적으로 차단함을 보인다.
keywords: [meta-principle, minimum-verifiable-path, anti-hallucination, RLHF, response-quality]
---

# LLM 최적 응답을 위한 범용 대원칙: 최소 검증 경로

## Research Overview

### Background & Motivation

이전 연구(001_Research_CLI-First-Guideline-Design)에서 환경 설정/설치 안내 시 CLI 명령어를
우선 제시하는 "CLI-first 원칙"을 도출했다. 그러나 이것은 특정 도메인(환경 설정)의 하위 규칙이다.

사용자의 질문: **"어떤 주제·상황에서든 최적 경로·최적 안내 방식을 선택하게 하는 상위 원칙,
대원칙 같은 건 없을까?"**

이 연구는 CLI-first를 포함하는 더 일반적인 범용 원칙을 도출하고, 다양한 도메인에서의
적용 가능성을 검증한다.

### Research Scope

- **포함**: LLM 응답 품질의 범용 원칙 도출, 다도메인 적용성 검증, CLAUDE.md 지침 초안
- **제외**: 모델 fine-tuning, 시스템 프롬프트 변경, 특정 도메인 전용 규칙

### Research Perspectives

1. **종합 분석** — 실패 모드 일반화 + 범용 원칙 도출 + 다도메인 검증 + 지침 초안

### Related Documents

- 선행 연구: [001_Research_CLI-First-Guideline-Design](./001_Research_CLI-First-Guideline-Design.md)
- 참조: docs/006_claude_compass_artifact (RLHF/sycophancy/confabulation 분석)
- 참조: docs/005_chatgpt_deep-research-report (프롬프트 설계 지침)

---

## 종합 분석

### 1. 실패 모드의 도메인 간 일반화

006 문서에서 식별된 3가지 LLM 실패 모드가 환경 설정 외 도메인에서 어떻게 발현되는지 분석한다.

#### RLHF Verbosity Bias — "길면 좋아 보인다"

| 도메인 | 발현 형태 | 실패 사례 |
|--------|----------|----------|
| 환경 설정 | 7단계 GUI 경로 vs 1줄 CLI | Xcode Platforms 탭 안내 |
| 코드 리뷰 | 장황한 설명 vs 직접 코드 수정 | "이 함수는... 따라서... 그러므로 수정하세요" vs `Edit` |
| 디버깅 | 가능한 원인 목록 나열 vs 재현+수정 | "원인 1:..., 원인 2:..., 원인 3:..." |
| 아키텍처 | 추상적 개념 설명 vs 코드 증거 | "일반적으로 MVC 패턴은..." vs `app/controllers/X:42` |
| API 안내 | 모든 옵션 나열 vs 필요한 것만 | 10개 파라미터 전부 설명 vs 필수 3개만 |

**공통 패턴**: LLM이 "더 많이 설명할수록 도움이 된다"고 학습했지만, 실제로는
사용자가 즉시 실행할 수 있는 최소 정보가 더 유용.

#### Sycophancy — "자신있게 답하면 좋아한다"

| 도메인 | 발현 형태 | 실패 사례 |
|--------|----------|----------|
| 환경 설정 | 확신 없는 GUI 경로를 자신있게 안내 | "Settings → Platforms 탭" (없는 탭) |
| 코드 리뷰 | 검증 안 된 수정을 확신있게 제안 | 존재하지 않는 메서드 호출 제안 |
| 디버깅 | 추측을 사실처럼 진단 | "이 버그는 X 때문입니다" (검증 없이) |
| API 안내 | 없는 API 파라미터를 자신있게 안내 | `--flag` (존재하지 않는 플래그) |

**공통 패턴**: 불확실성을 표현하지 않고, 확신있는 답변으로 신뢰를 얻으려 함.

#### Autoregressive Confabulation — "시작한 경로를 완성한다"

| 도메인 | 발현 형태 | 실패 사례 |
|--------|----------|----------|
| 환경 설정 | "Settings >" 시작 → 나머지 메뉴 경로 생성 | Platforms 탭 confabulation |
| 코드 | `import` 시작 → 없는 모듈명 생성 | `from utils import non_existent_func` |
| 디버깅 | "원인은" 시작 → 그럴듯한 원인 생성 | 실제 코드를 안 읽고 원인 추론 |
| 문서 | 인용 시작 → 없는 문서 내용 생성 | 존재하지 않는 공식 문서 인용 |

**공통 패턴**: 한번 답변 방향을 잡으면 그 경로를 그럴듯하게 완성. 되돌아가지 않음.

---

### 2. 범용 대원칙 도출: 최소 검증 경로 (Minimum Verifiable Path)

#### 원칙의 근거

세 가지 실패 모드에는 하나의 공통 해법이 있다:

> **사용자가 가장 적은 단계로, 즉시 검증 가능한 결과를 얻는 경로를 선택하라.**

이것을 **"최소 검증 경로 (Minimum Verifiable Path, MVP)"** 원칙이라 명명한다.

이름의 유래:
- **Minimum** — RLHF verbosity bias 차단. "필요한 만큼만"
- **Verifiable** — Confabulation 차단. "확인할 수 있는 것만"
- **Path** — Sycophancy 차단. "목적지까지의 경로 자체를 최적화"
- **MVP** — Lean Startup의 MVP(Minimum Viable Product)와 구조적 유사성. "최소한으로 검증 가능한"

#### Anthropic의 공식 원칙과의 정합성

Anthropic 컨텍스트 엔지니어링 가이드에서 동일한 방향의 원칙을 발견:

| Anthropic 원칙 | MVP 대응 | 출처 |
|---------------|---------|------|
| *"find the smallest set of high-signal tokens"* | Minimum — 최소 고신호 토큰 | context engineering blog |
| *"do the simplest thing that works"* | Minimum — 작동하는 가장 단순한 것 | context engineering blog |
| *"say less, mean more"* | Verifiable — 적게 말하고 의미는 크게 | 01.me 분석 |
| *"every tool must justify its existence"* | Minimum — 모든 요소가 존재 이유 필요 | context engineering blog |

MVP 원칙은 Anthropic이 이미 맥락 엔지니어링에서 적용하는 사고방식의
**응답 품질 버전**이다.

#### 4개 하위 원칙

MVP 대원칙은 4개 하위 원칙으로 구체화된다:

```
MVP = Actionable + Verifiable + Minimal + Confident-only
```

| # | 하위 원칙 | 정의 | 차단하는 실패 모드 |
|---|----------|------|------------------|
| 1 | **실행 가능 (Actionable)** | 복사-붙여넣기, 바로 적용 가능한 형태 우선 | Verbosity (설명 대신 실행물) |
| 2 | **검증 가능 (Verifiable)** | 결과를 즉시 확인할 수 있는 방식 우선 | Confabulation (검증 불가 → 환각) |
| 3 | **최소 단계 (Minimal)** | 같은 결과의 경로 중 가장 짧은 것 | Verbosity (단계 축소) |
| 4 | **확신 있는 것만 (Confident-only)** | 불확실하면 제시하지 않거나 불확실성 명시 | Sycophancy + Hallucination |

#### 하위 원칙 간 우선순위

충돌 시 적용 순서: **Confident-only > Verifiable > Actionable > Minimal**

이유: 확신 없는 정보를 제공하는 것이 가장 위험(silent failure).
검증 불가한 정보는 그 다음으로 위험. 실행 불가한 정보는 비효율적이지만 무해.
단계가 많은 것은 가장 덜 위험.

---

### 3. 다도메인 적용성 검증

MVP 원칙이 다양한 도메인에서 어떻게 구체적 규칙으로 파생되는지 검증한다.

#### 파생 규칙 매트릭스

| 도메인 | MVP 적용 | 최적 응답 (MVP 준수) | 차선 응답 (MVP 위반) | 위반 원칙 |
|--------|---------|---------------------|---------------------|----------|
| **환경 설정** | CLI-first | `xcodebuild -downloadPlatform iOS` | "Xcode → Settings → Platforms 탭" | Verifiable, Confident-only |
| **코드 리뷰** | Diff-first | 직접 `Edit` 도구로 코드 수정 제시 | "이 함수를 리팩터링하는 것을 권장합니다..." | Actionable, Minimal |
| **디버깅** | Reproduce-first | 재현 명령 + 수정 코드 | "원인은 A, B, C 중 하나일 수 있습니다" | Actionable, Verifiable |
| **아키텍처 설명** | Evidence-first | `파일경로:줄번호` + 코드 인용 | "일반적으로 MVC 패턴에서는..." | Verifiable |
| **의존성 안내** | Install+Example | `npm install x` + 사용 코드 3줄 | "x 라이브러리가 좋습니다" | Actionable |
| **설정 변경** | Config-patch | 설정 파일 직접 Edit | "설정에서 Y를 Z로 바꾸세요" | Actionable, Verifiable |
| **에러 해결** | Fix-first | 수정 코드 + 원인 1줄 설명 | 에러 원인 5단락 설명 후 수정 제안 | Minimal |
| **API 사용법** | Example-first | 작동하는 코드 예제 | API 문서 전체 파라미터 나열 | Minimal, Actionable |

#### 핵심 관찰: "CLI-first"는 MVP의 환경 설정 인스턴스

```
MVP (대원칙)
├── 환경 설정 → CLI-first (이미 도출, 001_Research)
├── 코드 리뷰 → Diff-first
├── 디버깅 → Reproduce-first
├── 아키텍처 → Evidence-first
├── 의존성 → Install+Example-first
├── 설정 변경 → Config-patch-first
├── 에러 해결 → Fix-first
└── API 사용법 → Example-first
```

모든 파생 규칙은 MVP의 4개 하위 원칙 조합으로 설명 가능하다.
개별 도메인 규칙을 10개 나열할 필요 없이, **MVP 대원칙 1개**면 모델이
각 상황에서 최적 경로를 스스로 유도할 수 있다.

---

### 4. CLAUDE.md 지침 설계

#### 4a. 설계 원칙

- **간결성**: CLAUDE.md 토큰 예산 최소화 (Anthropic: "say less, mean more")
- **파생 가능성**: 구체적 도메인 규칙을 일일이 나열하지 않고, 대원칙에서 유도되도록
- **비충돌**: 기존 지침(Pipeline, Agent 정책, CLI-first)과 충돌하지 않아야
- **계층 구조**: 대원칙 → 기존 CLI-first 규칙이 자연스럽게 하위로 편입

#### 4b. 지침 초안 — Global CLAUDE.md용

```markdown
## 응답 대원칙: 최소 검증 경로 (Minimum Verifiable Path)

모든 응답에서 사용자가 **가장 적은 단계로, 즉시 검증 가능한 결과**를 얻는 경로를 선택한다.

1. **실행 가능하게**: 바로 적용 가능한 형태 우선 (명령어, 코드, 설정값 > 설명)
2. **검증 가능하게**: 결과를 즉시 확인할 수 있는 방식 우선 (CLI > GUI, 코드 > 산문)
3. **최소 단계로**: 같은 결과를 얻는 경로 중 가장 짧은 것 선택
4. **확신 있는 것만**: 불확실한 정보(GUI 메뉴명, API 시그니처 등)는 제시하지 않거나 불확실성 명시
```

#### 4c. 기존 CLI-first 규칙과의 관계 정리

현재 Global CLAUDE.md에 이미 추가된 "환경 설정·설치 안내 원칙"은 MVP 대원칙의 하위 규칙이 된다.

**구조 옵션 A — 대원칙만 유지, CLI-first 제거:**
MVP가 충분히 구체적이므로 CLI-first를 별도로 두지 않아도 됨.
단, "환경 설정"이라는 구체적 트리거가 사라져 적용력이 약해질 수 있음.

**구조 옵션 B — 대원칙 + CLI-first 유지 (계층화):**
MVP 아래에 CLI-first를 하위 항목으로 편입. 대원칙이 일반 지침, CLI-first가 구체적 예시 역할.

**권장: 옵션 A** — CLI-first 4줄을 제거하고 MVP 4줄로 대체.
이유: MVP가 CLI-first를 포함하면서도 다른 모든 도메인까지 커버. 규칙 수 증가 없이 적용 범위 확대.

---

### Caveats & Risks

1. **추상성의 함정**: MVP가 너무 추상적이면 모델이 구체적 상황에서 적용을 못할 수 있음.
   → 완화: 4개 하위 원칙이 충분히 구체적이고, memory/feedback에 실패 사례가 보조.

2. **교육적 설명과의 긴장**: Explanatory output style은 교육적 insight를 요구.
   MVP의 "최소 단계"와 충돌 가능.
   → 완화: "답변 본문"은 MVP 준수, "Insight 블록"에서 교육적 설명 분리.
   즉, **what은 최소로, why는 Insight에서**.

3. **초보 사용자 배려**: 숙련자에게는 MVP가 최적이지만, 초보자는 더 많은 맥락이 필요할 수 있음.
   → 완화: 하위 원칙 4번 "확신 있는 것만"이 보호. 불확실한 설명을 늘리는 것보다
   확실한 명령어 1줄이 초보자에게도 더 안전.

4. **지나친 간결화 위험**: "최소 단계"를 극단적으로 적용하면 필요한 맥락까지 생략.
   → 완화: 우선순위 순서에서 "Minimal"이 가장 마지막. 안전성과 정확성이 항상 우선.

---

## Comprehensive Conclusion

### 핵심 발견 (우선순위 순)

1. **[Critical] R-002-F1: 3가지 LLM 실패 모드는 도메인 무관하게 반복된다** —
   RLHF verbosity, sycophancy, confabulation은 환경 설정뿐 아니라 코드 리뷰, 디버깅,
   아키텍처 설명 등 모든 기술 안내 도메인에서 동일한 패턴으로 나타난다. *(관점 1: 실패 모드 일반화)*

2. **[Critical] R-002-F2: "최소 검증 경로(MVP)" 대원칙이 모든 실패 모드를 구조적으로 차단한다** —
   4개 하위 원칙(실행 가능, 검증 가능, 최소 단계, 확신 비례)이 각각 verbosity, confabulation,
   verbosity, sycophancy를 1:1로 차단한다. Anthropic의 컨텍스트 엔지니어링 원칙
   ("find the smallest set of high-signal tokens", "do the simplest thing that works")과도
   정합한다. *(관점 1: 원칙 도출)*

3. **[High] R-002-F3: CLI-first는 MVP의 "환경 설정" 인스턴스일 뿐이다** —
   MVP에서 Diff-first(코드 리뷰), Reproduce-first(디버깅), Evidence-first(아키텍처),
   Example-first(API) 등 8개+ 도메인별 파생 규칙이 자연스럽게 유도된다. 개별 규칙 10개를
   나열하는 것보다 대원칙 1개가 토큰 효율적이고 범용적이다. *(관점 1: 다도메인 검증)*

4. **[High] R-002-F4: MVP 4줄이 기존 CLI-first 4줄을 대체할 수 있다** —
   Global CLAUDE.md에서 "환경 설정·설치 안내 원칙" 4줄을 "응답 대원칙: MVP" 4줄로
   교체하면, 적용 범위가 환경 설정 → 전 도메인으로 확대되면서 규칙 수는 동일하게 유지된다.
   *(관점 1: 지침 설계)*

5. **[Medium] R-002-F5: 하위 원칙 간 우선순위가 중요하다** —
   충돌 시 Confident-only > Verifiable > Actionable > Minimal 순서 적용.
   안전성(확신 있는 것만)이 항상 효율성(최소 단계)보다 우선해야 한다.
   *(관점 1: 설계 고려사항)*

### 최종 권장 액션

| 우선순위 | 액션 | 대상 | 효과 |
|---------|------|------|------|
| 1 | Global CLAUDE.md의 "환경 설정·설치 안내 원칙"을 "응답 대원칙: MVP"로 교체 | `~/.claude/CLAUDE.md` | 전 도메인 커버, 규칙 수 동일 |
| 2 | memory/feedback_cli_first.md 유지 (MVP의 구체적 실패 사례로 보조) | memory/ | 환경 설정 도메인 강화 |

## Unresolved Items

- **MVP 원칙의 실효성 검증**: 실제 다양한 도메인 대화에서 MVP 지침이 응답 품질을 개선하는지는
  추가 실험이 필요. 현재는 이론적 분석과 1개 실패 사례(Xcode)에 기반한 설계.
  사유: 동일 세션에서 A/B 테스트 불가.

## Referenced File List

| File Path | Related Perspective | Role/Content |
|-----------|-------------------|--------------|
| `docs/12_cli_first_guideline/001_Research_CLI-First-Guideline-Design.md` | 전체 | 선행 연구 — CLI-first 원칙 도출 |
| `docs/006_claude_compass_artifact_*.md` | 실패 모드 분석 | RLHF/sycophancy/confabulation 메커니즘 |
| `docs/005_chatgpt_deep-research-report.md` | 프롬프트 설계 | 테스트 케이스, 프롬프트 예시 |
| `~/.claude/CLAUDE.md` | 지침 배치 | Global 규칙 파일 |
| `memory/feedback_cli_first.md` | 보조 | CLI-first 구체적 실패 사례 기록 |

## External Sources

- [Anthropic: Effective Context Engineering for AI Agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Claude's Context Engineering Secrets (01.me)](https://01.me/en/2025/12/context-engineering-from-claude/)
- [Lakera: Prompt Engineering Guide 2026](https://www.lakera.ai/blog/prompt-engineering-guide)
- [LLM Reliability Framework (Medium)](https://medium.com/@knbrahmbhatt_4883/how-to-make-llms-reliable-a-practical-framework-for-prompt-context-engineering-that-delivers-2-5x-ba9acca1d18d)

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
