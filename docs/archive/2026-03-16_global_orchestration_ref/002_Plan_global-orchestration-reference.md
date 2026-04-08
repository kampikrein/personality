---
id: "002"
type: plan
title: "글로벌 오케스트레이션 참조 문서 + 플러그인 생성"
created: 2026-03-16
traces_scope: "001"
summary: >
  personality 프로젝트의 오케스트레이션 시스템을 다른 프로젝트에서 재사용 가능하도록
  글로벌 참조 문서(~/.claude/docs/), 글로벌 CLAUDE.md 안내, kampi-plugins 플러그인(7개 파일)을 생성한다.
  총 8개 파일 생성/수정.
keywords: [orchestration-system, global-reference, plugin, reusable, kampi-plugins]
---

# 002 — 글로벌 오케스트레이션 참조 문서 + 플러그인 생성

## Goal

personality 프로젝트에서 완성된 오케스트레이션 시스템(에이전트 7종 + 통합 프로토콜)을 **재사용 가능한 아티팩트**로 만든다.

- 글로벌 참조 문서: 다른 프로젝트에서 이 시스템이 무엇인지, 어떻게 셋업하는지 안내
- 글로벌 CLAUDE.md: 에이전트 설정 부재 시 참조 경로 안내
- kampi-plugins: 설치 가능한 형태로 제네릭 버전 제공

## Scope

### Included
| # | Item | Description |
|---|------|-------------|
| 1 | `~/.claude/docs/05_orchestration_system/001_Reference_orchestration-system.md` | 전체 시스템 설명 + 셋업 가이드 |
| 2 | `~/.claude/CLAUDE.md` (EDIT) | 에이전트 설정 부족 → 참조 안내 섹션 추가 |
| 3 | `kampi-plugins/orchestration-system/README.md` | 플러그인 소개 + 설치법 |
| 4 | `kampi-plugins/orchestration-system/docs/orchestration-protocol.md` | 도메인 무관 제네릭 프로토콜 |
| 5 | `kampi-plugins/orchestration-system/docs/CLAUDE-snippet.md` | CLAUDE.md 붙여넣기용 스니펫 |
| 6 | `kampi-plugins/orchestration-system/agents/_domain-expert-template.md` | 도메인 에이전트 정의 템플릿 |
| 7 | `kampi-plugins/orchestration-system/commands/setup-orchestration.md` | /setup-orchestration 커맨드 |
| 8 | `kampi-plugins/marketplace.json` (EDIT) | orchestration-system 엔트리 추가 |

### Excluded
| Item | Reason/Timeline |
|------|-----------------|
| 에이전트 7종 복사 | 도메인 의존적 — 플러그인에 템플릿만 제공 |
| orchestration.md 직접 복사 | 플러그인에 제네릭 버전으로 별도 작성 |
| GitHub 저장소 푸시 | 사용자 직접 실행 |

## Structural Decisions

> No structural decisions required — straightforward implementation.

---

## File Change Summary

### Modified Files
| # | File Path | Change Description |
|---|-----------|-------------------|
| 1 | `~/.claude/CLAUDE.md` | 에이전트 설정 안내 섹션 추가 (마지막에 append) |
| 2 | `~/.claude/plugins/marketplaces/kampi-plugins/marketplace.json` | orchestration-system 플러그인 엔트리 추가 |

### New Files
| # | File Path | Description |
|---|-----------|-------------|
| 1 | `~/.claude/docs/05_orchestration_system/001_Reference_orchestration-system.md` | 시스템 전체 참조 문서 |
| 2 | `~/.claude/plugins/marketplaces/kampi-plugins/orchestration-system/README.md` | 플러그인 소개 |
| 3 | `~/.claude/plugins/marketplaces/kampi-plugins/orchestration-system/docs/orchestration-protocol.md` | 제네릭 오케스트레이션 프로토콜 |
| 4 | `~/.claude/plugins/marketplaces/kampi-plugins/orchestration-system/docs/CLAUDE-snippet.md` | CLAUDE.md 스니펫 |
| 5 | `~/.claude/plugins/marketplaces/kampi-plugins/orchestration-system/agents/_domain-expert-template.md` | 도메인 에이전트 템플릿 |
| 6 | `~/.claude/plugins/marketplaces/kampi-plugins/orchestration-system/commands/setup-orchestration.md` | /setup-orchestration 커맨드 |

---

## Step 1 — 글로벌 참조 문서 생성

### Approach

`~/.claude/docs/05_orchestration_system/` 폴더를 생성하고, personality 프로젝트의 오케스트레이션 시스템을 **있는 그대로 설명**하는 참조 문서를 작성한다.

- 시스템 개요 (왜 만들었나, 핵심 개념)
- 에이전트 7종 목록 + 각자의 전문 영역
- 워크플로우 패턴 A-E 요약
- personality 프로젝트의 실제 파일 경로 레퍼런스
- 다른 프로젝트에서 셋업할 때 참고할 가이드

### After Code

```markdown
# 파일: ~/.claude/docs/05_orchestration_system/001_Reference_orchestration-system.md
---
id: "001"
type: reference
title: "오케스트레이션 시스템 참조 문서"
created: 2026-03-16
project: personality
source_protocol: /Users/kampikrein/A/personality/.claude/protocols/orchestration.md
---

# 오케스트레이션 시스템 참조 문서

## 시스템 개요

personality 프로젝트에서 구현된 에이전트 오케스트레이션 시스템.
...
(에이전트 7종, 패턴 A-E, 산출물 프로토콜, 평가루프 전체 설명)
...

## 신규 프로젝트 셋업 가이드

1. CLAUDE.md에 에이전트 테이블 + 오케스트레이션 트리거 추가
2. .claude/protocols/orchestration.md 복사 (또는 kampi-plugins 설치)
3. 도메인에 맞는 에이전트 정의 파일 생성
```

### Considerations

참조 문서는 personality의 구체적 구현을 있는 그대로 기록. 범용화는 플러그인(Step 3)에서 처리.

---

## Step 2 — 글로벌 CLAUDE.md 수정

### Approach

`~/.claude/CLAUDE.md` 마지막에 **오케스트레이션 시스템 설정 안내** 섹션을 추가한다.

조건: 새 프로젝트의 CLAUDE.md에 에이전트 설정이 없거나 부족해 보일 때, Claude가 이 글로벌 안내를 보고 사용자에게 제안한다.

### Current Code

```markdown
# 현재 ~/.claude/CLAUDE.md 마지막 줄
## 에이전트 도구 정책

- **general-purpose Agent**: orchestration protocol을 통해서만 사용.
- 직접 `Agent(subagent_type: "general-purpose")` 호출은 금지.
- `Explore`, `Plan` 타입 에이전트는 스킬 내에서 직접 사용 가능.
```

### After Code

```markdown
## 에이전트 도구 정책

- **general-purpose Agent**: orchestration protocol을 통해서만 사용.
- 직접 `Agent(subagent_type: "general-purpose")` 호출은 금지.
- `Explore`, `Plan` 타입 에이전트는 스킬 내에서 직접 사용 가능.

## 오케스트레이션 시스템 설정 안내

현재 프로젝트의 CLAUDE.md에 전문 에이전트 테이블 또는 오케스트레이션 프로토콜이 없을 때:

1. **참조 문서 확인**: `~/.claude/docs/05_orchestration_system/001_Reference_orchestration-system.md`
   - personality 프로젝트의 완성된 시스템 전체 설명
   - 에이전트 7종 구성, 패턴 A-E, 산출물 프로토콜
   - 신규 프로젝트 셋업 가이드 포함

2. **플러그인 설치**: kampi-plugins의 orchestration-system 플러그인
   - 위치: `~/.claude/plugins/marketplaces/kampi-plugins/orchestration-system/`
   - 제네릭 프로토콜 + 에이전트 템플릿 + /setup-orchestration 커맨드 제공

3. **사용자에게 제안**:
   > "이 프로젝트에 에이전트 오케스트레이션 설정이 없습니다.
   > kampi-plugins의 orchestration-system 플러그인으로 설치하거나,
   > ~/.claude/docs/05_orchestration_system/ 참조 문서를 바탕으로 직접 구성할 수 있습니다.
   > /setup-orchestration 을 실행하면 자동으로 설정됩니다."
```

---

## Step 3 — kampi-plugins orchestration-system 플러그인 생성

### Approach

`~/.claude/plugins/marketplaces/kampi-plugins/orchestration-system/` 폴더에 6개 파일 생성.

**설계 원칙**:
- `docs/orchestration-protocol.md`: personality의 orchestration.md에서 도메인 참조(PSY/CODE/UX/TAROT 기준, 에이전트 7종 테이블)를 제거한 **순수 메커니즘** 버전
- `docs/CLAUDE-snippet.md`: 새 프로젝트 CLAUDE.md에 붙여넣기만 하면 되는 스니펫 (에이전트 섹션 + 트리거 테이블)
- `agents/_domain-expert-template.md`: 새 도메인 에이전트 정의 시 복사해 쓰는 템플릿
- `commands/setup-orchestration.md`: `/setup-orchestration` 커맨드 — 대화형으로 도메인 파악 후 CLAUDE.md 스니펫 + 프로토콜 파일 자동 생성

### After Code (setup-orchestration.md 핵심 구조)

```markdown
# /setup-orchestration

새 프로젝트에 오케스트레이션 시스템을 설치한다.

## 실행 절차

1. 프로젝트 도메인 분석 (CLAUDE.md + 디렉터리 구조 파악)
2. 필요한 에이전트 역할 파악 (AskUserQuestion으로 확인)
3. 다음 파일 생성:
   - .claude/protocols/orchestration.md (kampi-plugins 버전 복사)
   - CLAUDE.md에 에이전트 테이블 + 트리거 섹션 append
4. 생성된 파일 경로 + 다음 단계 안내
```

### Considerations

플러그인의 `orchestration-protocol.md`는 패턴 A-E, 산출물 프로토콜, 평가루프 **메커니즘**은 유지하되, 검증 기준(PSY/CODE/UX/TAROT)은 "도메인별 기준을 여기에 정의하라"는 안내 텍스트로 대체.

---

## Step 4 — marketplace.json 업데이트

### Current Code

```json
// ~/.claude/plugins/marketplaces/kampi-plugins/marketplace.json
{
  "name": "Kampi Claude Plugins",
  "owner": { "name": "kampikrein", "url": "https://github.com/kampikrein" },
  "plugins": [
    {
      "name": "project-boundary-guard",
      "version": "1.0.0",
      "description": "프로젝트 경계 보호 — 외부 파일 수정 방지 훅 + 소프트 가드레일",
      "source": "./project-boundary-guard"
    }
  ]
}
```

### After Code

```json
{
  "name": "Kampi Claude Plugins",
  "owner": { "name": "kampikrein", "url": "https://github.com/kampikrein" },
  "plugins": [
    {
      "name": "project-boundary-guard",
      "version": "1.0.0",
      "description": "프로젝트 경계 보호 — 외부 파일 수정 방지 훅 + 소프트 가드레일",
      "source": "./project-boundary-guard"
    },
    {
      "name": "orchestration-system",
      "version": "1.0.0",
      "description": "에이전트 오케스트레이션 시스템 — 패턴 A-E, 산출물 프로토콜, 평가루프, /setup-orchestration 커맨드",
      "source": "./orchestration-system"
    }
  ]
}
```

---

## Considerations & Trade-offs

### 참조 문서 vs 플러그인 역할 분리

참조 문서는 personality 프로젝트의 **구체적 구현을 설명**하는 역할이고, 플러그인은 **어떤 프로젝트에도 설치 가능한 제네릭 버전**을 제공한다. 이 분리를 유지하면:

- 참조 문서는 "왜 이렇게 설계했나"를 이해하는 데 도움
- 플러그인은 "어떻게 새 프로젝트에 적용하나"에 집중

### 에이전트 정의 방식

에이전트 7종은 도메인 전문성이 핵심이므로 플러그인에서 복사 배포하면 의미가 없다. 대신 `_domain-expert-template.md` 하나로 "에이전트 정의 패턴"만 전달하고, 사용자가 자신의 도메인에 맞게 채우도록 한다.

### /setup-orchestration 자동화 범위

완전 자동화(프롬프트 없이 파일 생성)보다 **대화형 설정**이 더 적절하다 — 프로젝트마다 도메인이 다르므로 에이전트 역할명, 에이전트 수를 사용자가 결정해야 한다. 프로토콜 파일 생성은 자동, 에이전트 테이블 채우기는 대화형.

## Implementation Checklist

- [x] Step 1: `~/.claude/docs/05_orchestration_system/` 폴더 생성 + 참조 문서 작성
- [x] Step 2: `~/.claude/CLAUDE.md`에 오케스트레이션 설정 안내 섹션 추가
- [x] Step 3a: `orchestration-system/README.md` 생성
- [x] Step 3b: `orchestration-system/docs/orchestration-protocol.md` 생성 (제네릭)
- [x] Step 3c: `orchestration-system/docs/CLAUDE-snippet.md` 생성
- [x] Step 3d: `orchestration-system/agents/_domain-expert-template.md` 생성
- [x] Step 3e: `orchestration-system/commands/setup-orchestration.md` 생성
- [x] Step 4: `marketplace.json` orchestration-system 엔트리 추가
- [x] 최종 검증: 생성 파일 목록 확인

## Verification Assertions

| Level | Assertion | Verification Method | Expected Result |
|-------|-----------|-------------------|-----------------|
| L2-CLI | 참조 문서 존재 | `ls ~/.claude/docs/05_orchestration_system/` | `001_Reference_orchestration-system.md` 확인 |
| L2-CLI | 플러그인 폴더 구조 | `ls ~/.claude/plugins/marketplaces/kampi-plugins/orchestration-system/` | README.md + docs/ + agents/ + commands/ 존재 |
| L2-CLI | marketplace.json 업데이트 | `cat ~/.claude/plugins/marketplaces/kampi-plugins/marketplace.json` | orchestration-system 엔트리 포함 |
| L2-CLI | 글로벌 CLAUDE.md 수정 | `grep -n "오케스트레이션 시스템 설정 안내" ~/.claude/CLAUDE.md` | 해당 섹션 존재 |

## References

| Resource | Path/URL | Related Content |
|----------|---------|-----------------|
| 현재 오케스트레이션 프로토콜 | `.claude/protocols/orchestration.md` | 플러그인 제네릭화 원본 |
| Scope 문서 | `docs/14_global_orchestration_ref/001_Scope_global-orchestration-reference.md` | 작업 목표 및 설계 원칙 |
| 기존 플러그인 | `~/.claude/plugins/marketplaces/kampi-plugins/project-boundary-guard/` | 플러그인 구조 참조 |
| 글로벌 CLAUDE.md | `~/.claude/CLAUDE.md` | 수정 대상 |

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
