---
id: "002"
title: "Claude Code 에이전트 시스템 설정 최적화"
category: agent
status: archived
created: 2026-03-11
summary: >
  5개 전문 에이전트의 Claude Code 기술적 설정(tools, model, permissionMode, memory, skills, maxTurns) 최적화 연구
keywords: [agent-report, 시스템설정, tools, model, permissionMode, general-purpose]
modules: [.claude/agents]
---

# Claude Code 에이전트 시스템 설정 최적화

## Summary

5개 전문 에이전트(심리학전문가, MBTI전문가, 애니어그램전문가, 코딩전문가, UI/UX전문가)의 Claude Code 기술적 설정을 프로젝트 코드베이스 구조와 기존 스킬 생태계를 기반으로 분석했다. 자문 역할과 구현 역할의 근본적 차이에 따라 도구 접근 권한, 모델 선택, 권한 모드를 차등 적용하는 것을 권장한다. 특히 자문 에이전트도 제한적 쓰기 권한이 필요하며, 기존 스킬 생태계와의 연동이 작업 품질을 크게 향상시킬 수 있다.

## Details

### 1. 도구(tools) 설정 최적화

#### 에이전트별 추천 도구 설정

| 에이전트 | tools (allowlist) | 근거 |
|---------|------------------|------|
| 심리학전문가 | Read, Glob, Grep, Edit, Write | 아래 상세 참조 |
| MBTI전문가 | Read, Glob, Grep, Edit, Write | 아래 상세 참조 |
| 애니어그램전문가 | Read, Glob, Grep, Edit, Write | 아래 상세 참조 |
| 코딩전문가 | Read, Write, Edit, Bash, Glob, Grep | 전체 도구 필요 |
| UI/UX전문가 | Read, Write, Edit, Bash, Glob, Grep | 전체 도구 필요 |

**자문 에이전트(심리학/MBTI/애니어그램)에 쓰기 권한이 필요한 이유:**

- **문항 설계**: `app/models/question.rb`, `db/seeds/` 등에 문항 데이터를 직접 작성/수정해야 한다.
- **점수 체계 검토/수정**: `app/services/scoring/` 하위 파일의 가중치, 임계값, 분류 로직을 수정해야 한다.
- **보고서 문구 작성**: `app/services/insights/`, `app/services/profiles/`의 텍스트 콘텐츠를 직접 수정해야 한다.
- **결과 화면 텍스트**: `app/views/results/` 하위 partial들의 사용자 표시 문구를 수정해야 한다.

단, Bash는 제외한다. 자문 에이전트가 셸 명령을 실행할 이유가 없으며, 의도치 않은 부작용을 방지한다.

**WebSearch/WebFetch 필요성:**

모든 에이전트에서 제외. 외부 조사는 부모 세션의 `/research` 스킬이 담당하며, 서브에이전트에 부여하면 토큰 낭비와 작업 발산을 초래한다.

### 2. 모델(model) 선택

| 에이전트 | 추천 모델 | 근거 |
|---------|----------|------|
| 심리학전문가 | **sonnet** | 비용 대비 성능 최적. 높은 추론 요구는 프롬프트 품질로 보완 |
| MBTI전문가 | **sonnet** | 동일 |
| 애니어그램전문가 | **sonnet** | 동일 |
| 코딩전문가 | **sonnet** | 코드 작성/수정은 sonnet이 가장 효율적 |
| UI/UX전문가 | **sonnet** | ui-ux-pro-max 스킬이 디자인 지식을 보완 |

- **haiku**: 서브에이전트용으로 부적합. 문맥 이해와 복잡한 지시 수행이 부족
- **opus**: 비용 대비 이점이 서브에이전트 수준에서 미미
- **inherit**: 명시적 모델 지정이 더 안정적

### 3. 권한(permissionMode) 설정

모든 에이전트: **acceptEdits** — Read/Write/Edit 자동 허용, Bash 등은 확인. 서브에이전트에 가장 적합한 균형점.

### 4. memory 설정

모든 에이전트: **미설정** — 기존 docs/ 문서 시스템이 더 효과적. memory의 암묵적 축적은 편향 위험.

### 5. skills 연동

| 에이전트 | 추천 skills | 근거 |
|---------|------------|------|
| 심리학/MBTI/애니어그램 | 없음 | 독립 워크플로우 스킬은 서브에이전트 패턴과 충돌 |
| 코딩전문가 | 없음 | TDD 원칙은 프롬프트에 내장 |
| UI/UX전문가 | `ui-ux-pro-max` | 참조 데이터 성격으로 충돌 없음 |

### 6. maxTurns 설정

| 에이전트 | 추천 maxTurns | 근거 |
|---------|-------------|------|
| 심리학/MBTI/애니어그램 | **15** | 코드 탐색(5-7턴) + 분석/수정(5-8턴) |
| 코딩전문가 | **25** | 코드 작성 + 테스트 + 리팩터링 |
| UI/UX전문가 | **20** | 디자인 참조 + 코드 작성 + 확인 |

### 종합 설정 테이블

```yaml
# 심리학전문가
name: psychology-expert
tools: [Read, Glob, Grep, Edit, Write]
model: sonnet
permissionMode: acceptEdits
maxTurns: 15

# MBTI전문가
name: mbti-expert
tools: [Read, Glob, Grep, Edit, Write]
model: sonnet
permissionMode: acceptEdits
maxTurns: 15

# 애니어그램전문가
name: enneagram-expert
tools: [Read, Glob, Grep, Edit, Write]
model: sonnet
permissionMode: acceptEdits
maxTurns: 15

# 코딩전문가
name: coding-expert
tools: [Read, Write, Edit, Bash, Glob, Grep]
model: sonnet
permissionMode: acceptEdits
maxTurns: 25

# UI/UX전문가
name: uiux-expert
tools: [Read, Write, Edit, Bash, Glob, Grep]
model: sonnet
permissionMode: acceptEdits
maxTurns: 20
skills: [ui-ux-pro-max]
```

## Key Findings

- **자문 에이전트도 쓰기 권한이 필요하다**: 문항 텍스트, 점수 가중치, 보고서 문구 등의 구체적 산출물을 코드에 반영해야 한다. 단 Bash는 제외.
- **모든 에이전트에 sonnet이 최적이다**: haiku는 부족하고 opus는 비용 과다.
- **memory보다 docs/ 문서 시스템이 우월하다**: 명시적이고 검증 가능한 맥락 전달.
- **스킬 연동은 최소화해야 한다**: 유일한 예외는 ui-ux-pro-max.
- **WebSearch/WebFetch는 모든 서브에이전트에서 제외한다**.

## Recommendations

1. 단계적 도입: 코딩/UI/UX 에이전트 먼저, 자문 에이전트는 프롬프트 완성 후
2. permissionMode 재평가: 신뢰도 축적 시 코딩전문가를 dontAsk로 전환 고려
3. maxTurns 튜닝: 실사용 패턴 관찰 후 조정
4. isolation 검토: 동시 수정 시나리오에서 worktree 격리 고려
5. 에이전트 프롬프트에 주요 파일 경로 명시

## References

- 프로젝트 설정: `.claude/settings.local.json`
- 에이전트 파일 위치: `.claude/agents/`
- 스킬 디렉터리: `~/.claude/skills/` (18개 스킬)
- 서비스 레이어: `app/services/` (scoring, insights, profiles, compliance, quality)
- 뷰 템플릿: `app/views/results/`
- 테스트: `spec/` (models, requests, services)
