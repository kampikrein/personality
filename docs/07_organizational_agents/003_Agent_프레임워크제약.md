---
id: "003"
title: "Claude Code 에이전트 프레임워크 기술 제약 분석"
category: agent
status: archived
created: 2026-03-14
summary: >
  Claude Code 에이전트 프레임워크의 기술적 제약을 정밀 분석. 서브에이전트는 다른 서브에이전트를 스폰할 수 없으며(핵심 제약),
  오케스트레이터 패턴은 --agent 플래그로 메인 스레드에서 실행하거나 Agent Teams(실험적)를 사용해야 한다.
  frontmatter 필드 12개 전체 스펙, permissionMode 5종, 도구 25종, maxTurns 동작 방식을 문서화.
keywords: [agent-report, 프레임워크제약, claude-code-agents, Agent-tool, maxTurns, permissionMode]
modules: [.claude/agents]
---

# Claude Code 에이전트 프레임워크 기술 제약 분석

## Progress
### Completed
- [x] 에이전트 간 호출 메커니즘 조사 (Agent tool, subagent_type, 커스텀 에이전트)
- [x] 도구 및 권한 모델 조사 (tools, permissionMode, skills)
- [x] 실행 제약 조사 (maxTurns, 컨텍스트, 동시 실행)
- [x] 파일 기반 특성 조사 (frontmatter 스펙, 시스템 프롬프트 주입)
- [x] 종합 정리 및 Key Findings 작성
### Remaining
(없음)
### Current Status
조사 완료.

## Summary

Claude Code 에이전트 프레임워크는 `.claude/agents/` 디렉토리에 마크다운 파일로 정의된 서브에이전트를 통해 작업을 위임하는 구조이다. **핵심 제약은 "서브에이전트는 다른 서브에이전트를 스폰할 수 없다"는 것**이다. 이로 인해 오케스트레이터-워커 패턴을 구현하려면 `--agent` 플래그로 오케스트레이터를 메인 스레드에서 실행하고, 오케스트레이터가 Agent tool로 워커 서브에이전트들을 호출하는 구조가 필요하다. 또는 실험적 기능인 Agent Teams를 사용할 수 있다.

## Details

### 1. 에이전트 간 호출 메커니즘

#### 1.1 Agent tool (구 Task tool)

- **Agent tool**은 서브에이전트를 스폰하는 핵심 도구이다.
- v2.1.63에서 Task tool이 Agent tool로 리네임됨. 기존 `Task(...)` 참조는 별칭으로 계속 작동.
- Agent tool은 별도의 컨텍스트 윈도우에서 서브에이전트를 실행하고, 결과를 호출자에게 반환한다.

#### 1.2 서브에이전트의 제한: 재귀 스폰 불가

> **"Subagents cannot spawn other subagents."** (공식 문서 명시)

이것이 가장 중요한 제약이다:
- `.claude/agents/`에 정의된 서브에이전트가 실행 중일 때, 해당 서브에이전트는 Agent tool을 사용할 수 없다.
- 따라서 psychology-expert가 coding-expert를 직접 호출하는 것은 **불가능**하다.
- Plan 서브에이전트가 존재하는 이유도 이 제약 때문 — "infinite nesting"을 방지하기 위해.

#### 1.3 오케스트레이터 구현 방법

**방법 A: `--agent` 플래그로 메인 스레드에서 오케스트레이터 실행**
```bash
claude --agent coordinator
```
- `--agent` 플래그로 실행된 에이전트는 **메인 스레드**에서 동작하므로 Agent tool 사용 가능.
- `tools: Agent(worker1, worker2)` 구문으로 스폰 가능한 서브에이전트를 제한 가능.
- `Agent` 없이 `tools`에서 Agent를 생략하면 서브에이전트 스폰 자체가 차단됨.
- `Agent`만 적으면 (괄호 없이) 모든 서브에이전트를 스폰 가능.

```yaml
# 오케스트레이터 에이전트 예시
---
name: coordinator
description: 작업을 전문 에이전트에게 위임하는 조정자
tools: Agent(psychology-expert, mbti-expert, enneagram-expert, coding-expert, uiux-expert), Read, Glob, Grep
model: opus
---
```

**방법 B: Agent Teams (실험적)**
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` 환경 변수로 활성화.
- 별도의 Claude Code 인스턴스들이 팀으로 동작.
- 공유 태스크 리스트, 에이전트 간 직접 메시징, 자율 태스크 클레임.
- 제한: 실험적 기능, 세션 재개 불가, 중첩 팀 불가, 리드 고정.

**방법 C: 체이닝 (Chaining)**
- 메인 대화에서 순차적으로 서브에이전트를 호출하는 방식.
- "Use agent A, then use agent B with the results"
- 메인 대화가 오케스트레이터 역할을 함.

#### 1.4 Agent tool에서 커스텀 에이전트 지정

- Agent tool 호출 시, `.claude/agents/`에 정의된 에이전트 이름을 `agent_type`으로 지정.
- `subagent_type`이 아닌 `agent_type`이 정확한 파라미터명.
- 빌트인 에이전트: `Explore`, `Plan`, `general-purpose`, `Bash`, `Claude Code Guide`.
- 커스텀 에이전트: `.claude/agents/`에 정의된 이름 (예: `psychology-expert`).

### 2. 도구 및 권한 모델

#### 2.1 사용 가능한 전체 도구 목록 (25종)

| 도구 | 설명 | 권한 필요 |
|------|------|-----------|
| `Agent` | 서브에이전트 스폰 | 아니오 |
| `AskUserQuestion` | 사용자에게 질문 | 아니오 |
| `Bash` | 셸 명령 실행 | **예** |
| `CronCreate` | 반복/일회 프롬프트 스케줄링 | 아니오 |
| `CronDelete` | 스케줄 취소 | 아니오 |
| `CronList` | 스케줄 목록 | 아니오 |
| `Edit` | 파일 수정 | **예** |
| `EnterPlanMode` | 플랜 모드 진입 | 아니오 |
| `EnterWorktree` | Git worktree 생성 | 아니오 |
| `ExitPlanMode` | 플랜 모드 종료 | **예** |
| `ExitWorktree` | Worktree 종료 | 아니오 |
| `Glob` | 파일 패턴 검색 | 아니오 |
| `Grep` | 파일 내용 검색 | 아니오 |
| `ListMcpResourcesTool` | MCP 리소스 목록 | 아니오 |
| `LSP` | 코드 인텔리전스 | 아니오 |
| `NotebookEdit` | Jupyter 노트북 수정 | **예** |
| `Read` | 파일 읽기 | 아니오 |
| `ReadMcpResourceTool` | MCP 리소스 읽기 | 아니오 |
| `Skill` | 스킬 실행 | **예** |
| `TaskCreate/Get/List/Update/Output/Stop` | 태스크 관리 | 아니오 |
| `TodoWrite` | 태스크 체크리스트 (비대화형) | 아니오 |
| `ToolSearch` | 지연 로딩 도구 검색 | 아니오 |
| `WebFetch` | URL 콘텐츠 가져오기 | **예** |
| `WebSearch` | 웹 검색 | **예** |
| `Write` | 파일 생성/덮어쓰기 | **예** |

#### 2.2 permissionMode (5종)

| 모드 | 동작 |
|------|------|
| `default` | 표준 권한 확인 + 사용자 프롬프트 |
| `acceptEdits` | 파일 편집 자동 승인 (Bash는 여전히 허용 규칙 기반) |
| `dontAsk` | 권한 프롬프트 자동 거부 (명시적 허용 도구만 작동) |
| `bypassPermissions` | 모든 권한 검사 건너뜀 (CI/컨테이너용, **위험**) |
| `plan` | 읽기 전용 탐색 모드 |

**중요**: 부모가 `bypassPermissions`면 자식에서 재정의 불가. 서브에이전트는 부모의 권한 컨텍스트를 상속.

**현재 프로젝트**: 5개 에이전트 모두 `acceptEdits` 사용 중 — 파일 편집은 자동 승인되지만 Bash 실행은 허용 규칙 필요.

#### 2.3 skills 배열

- `skills` 필드는 서브에이전트 시작 시 **스킬 전체 내용을 컨텍스트에 주입**한다.
- 호출 가능하게 만드는 것이 아니라, 시작 시점에 전체 내용이 시스템 프롬프트에 포함됨.
- 서브에이전트는 부모 대화의 스킬을 **상속하지 않음** — 명시적으로 나열해야 함.
- **현재 프로젝트**: uiux-expert가 `skills: [ui-ux-pro-max]` 사용 중. 이 스킬의 전체 내용이 uiux-expert 시작 시 주입됨.

#### 2.4 model 필드

- 사용 가능한 값: `sonnet`, `opus`, `haiku`, 풀 모델 ID (`claude-opus-4-6`, `claude-sonnet-4-6` 등), `inherit`
- 미지정 시 기본값: `inherit` (메인 대화의 모델 사용)
- **현재 프로젝트**: 5개 에이전트 모두 `model: sonnet` — 비용/속도 최적화이나, 오케스트레이터는 `opus`가 적절할 수 있음.

### 3. 실행 제약

#### 3.1 maxTurns

- **maxTurns**: 에이전트가 수행할 수 있는 최대 "에이전틱 턴" 수.
- "턴"은 도구 사용 턴만 카운트함 (사고만 하는 턴은 미카운트).
- maxTurns에 도달하면 서브에이전트가 중지됨.
- **오케스트레이터가 워커를 호출할 때**: 각 Agent tool 호출이 오케스트레이터의 턴 1개를 소비. 워커 내부의 턴은 워커의 maxTurns에서 별도로 카운트.
- **현재 프로젝트 설정**: psychology/mbti/enneagram = 15턴, uiux = 20턴, coding = 25턴.

#### 3.2 컨텍스트 윈도우 관리

- 각 서브에이전트는 **독립된 컨텍스트 윈도우**에서 실행.
- 서브에이전트는 시스템 프롬프트(마크다운 본문) + 기본 환경 정보(작업 디렉토리)만 받음. 메인 대화의 전체 시스템 프롬프트는 받지 않음.
- **자동 컴팩션**: 약 95% 용량에서 자동 트리거. `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE`로 조정 가능.
- 서브에이전트 트랜스크립트는 `~/.claude/projects/{project}/{sessionId}/subagents/agent-{agentId}.jsonl`에 저장.
- 메인 대화가 컴팩션되어도 서브에이전트 트랜스크립트는 영향 없음 (별도 파일).

#### 3.3 동시 실행 (병렬/백그라운드)

**포그라운드 vs 백그라운드**:
- **포그라운드**: 메인 대화를 블로킹. 권한 프롬프트/질문이 사용자에게 전달됨.
- **백그라운드**: 동시 실행. 실행 전에 필요한 도구 권한을 미리 요청. 실행 중 추가 권한 요청은 자동 거부. 명확화 질문(AskUserQuestion)도 실패하지만 서브에이전트는 계속 실행.

**병렬 리서치**: 여러 서브에이전트를 동시에 스폰하여 독립 작업 가능.
```
Research the authentication, database, and API modules in parallel using separate subagents
```

**isolation: worktree**: 서브에이전트를 임시 git worktree에서 실행하여 파일 충돌 방지. 변경 없으면 자동 정리.

**주의**: 많은 서브에이전트가 상세 결과를 반환하면 메인 대화의 컨텍스트를 상당히 소비.

### 4. 파일 기반 특성

#### 4.1 frontmatter 전체 스펙 (12개 필드)

| 필드 | 필수 | 설명 |
|------|------|------|
| `name` | **예** | 고유 식별자 (소문자 + 하이픈) |
| `description` | **예** | Claude가 위임 결정 시 참조하는 설명 |
| `tools` | 아니오 | 사용 가능한 도구 (미지정 시 모든 도구 상속) |
| `disallowedTools` | 아니오 | 거부할 도구 (상속/지정 목록에서 제거) |
| `model` | 아니오 | 사용 모델 (`sonnet`, `opus`, `haiku`, 풀 ID, `inherit`) |
| `permissionMode` | 아니오 | 권한 모드 (5종) |
| `maxTurns` | 아니오 | 최대 에이전틱 턴 수 |
| `skills` | 아니오 | 시작 시 주입할 스킬 목록 |
| `mcpServers` | 아니오 | 사용 가능한 MCP 서버 (인라인 정의 또는 참조) |
| `hooks` | 아니오 | 라이프사이클 훅 (PreToolUse, PostToolUse, Stop) |
| `memory` | 아니오 | 영속 메모리 범위 (`user`, `project`, `local`) |
| `background` | 아니오 | 항상 백그라운드 실행 여부 (`true`/`false`) |
| `isolation` | 아니오 | `worktree` 설정 시 임시 git worktree에서 실행 |

#### 4.2 마크다운 본문의 시스템 프롬프트 주입

- frontmatter 아래의 마크다운 본문 전체가 서브에이전트의 **시스템 프롬프트**가 된다.
- 서브에이전트는 이 시스템 프롬프트 + 기본 환경 정보(작업 디렉토리 등)만 받음.
- **메인 Claude Code 시스템 프롬프트는 받지 않음** — 완전히 독립적인 프롬프트.
- CLAUDE.md 파일은 로드됨 (프로젝트 컨텍스트로).

#### 4.3 에이전트 파일 관리 규칙

**우선순위** (높은 순):
1. `--agents` CLI 플래그 (현재 세션 전용)
2. `.claude/agents/` (프로젝트 수준)
3. `~/.claude/agents/` (사용자 수준)
4. 플러그인의 `agents/` 디렉토리

**로딩 시점**: 세션 시작 시 로드. 수동 파일 추가 후에는 세션 재시작 또는 `/agents` 명령으로 즉시 로드.

**같은 이름**: 여러 위치에 동명 에이전트가 있으면 높은 우선순위 위치가 승리.

#### 4.4 memory 필드 (영속 메모리)

공식 문서에서 지원하는 memory 스킴:
- `memory: user` → `~/.claude/agent-memory/<name>/`
- `memory: project` → `.claude/agent-memory/<name>/`
- `memory: local` → `.claude/agent-memory-local/<name>/`

활성화 시:
- 시스템 프롬프트에 메모리 읽기/쓰기 지침 자동 포함.
- `MEMORY.md`의 처음 200줄이 시스템 프롬프트에 포함.
- Read, Write, Edit 도구가 자동 활성화.

**현재 프로젝트**: 커스텀 메모리 시스템을 마크다운 본문에 직접 구현 (`.claude/agent-memory/<name>/`에 YAML 파일 사용). 공식 `memory` frontmatter 필드는 미사용. 공식 방식으로 전환하면 MEMORY.md 기반의 간소화된 메모리가 가능하나, 현재 구조화된 YAML 방식이 더 정밀.

### 5. 현재 프로젝트 에이전트 분석

| 에이전트 | model | tools | permissionMode | maxTurns | skills |
|----------|-------|-------|----------------|----------|--------|
| psychology-expert | sonnet | Read, Glob, Grep, Edit, Write | acceptEdits | 15 | - |
| mbti-expert | sonnet | Read, Glob, Grep, Edit, Write | acceptEdits | 15 | - |
| enneagram-expert | sonnet | Read, Glob, Grep, Edit, Write | acceptEdits | 15 | - |
| coding-expert | sonnet | Read, Write, Edit, Bash, Glob, Grep | acceptEdits | 25 | - |
| uiux-expert | sonnet | Read, Write, Edit, Bash, Glob, Grep | acceptEdits | 20 | ui-ux-pro-max |

**관찰사항**:
- 5개 에이전트 모두 `Agent` 도구가 tools 목록에 없음 → 서브에이전트 스폰 불가 (설령 가능하더라도 서브에이전트는 재귀 스폰 불가).
- 도메인 전문가 3명(psychology, mbti, enneagram)은 Bash 도구가 없음 → 코드 실행 불가, 읽기/쓰기만.
- coding-expert와 uiux-expert만 Bash 도구 보유.

## Key Findings

### KF-1: 서브에이전트 재귀 스폰 불가 (Critical)
**서브에이전트는 다른 서브에이전트를 스폰할 수 없다.** 이것이 가장 중요한 제약이며 오케스트레이터 설계의 핵심 전제가 된다. `.claude/agents/`에 정의된 에이전트 간 직접 호출은 원천적으로 불가능하다.

### KF-2: 오케스트레이터는 `--agent` 플래그 필수
오케스트레이터 에이전트가 워커를 호출하려면 반드시 `claude --agent orchestrator` 형태로 **메인 스레드에서 실행**해야 한다. 이때 `tools: Agent(worker1, worker2, ...)` 구문으로 스폰 가능한 서브에이전트를 명시적으로 제어할 수 있다.

### KF-3: Agent tool의 스폰 제어 구문
- `tools: Agent` → 모든 서브에이전트 스폰 가능
- `tools: Agent(a, b, c)` → 지정된 서브에이전트만 스폰 가능 (화이트리스트)
- `tools`에서 Agent 생략 → 서브에이전트 스폰 불가
- **이 제어는 `--agent`로 메인 스레드에서 실행될 때만 유효.** 서브에이전트 정의에서 `Agent(...)` 작성해도 효과 없음.

### KF-4: 서브에이전트 독립 컨텍스트
각 서브에이전트는 **별도의 컨텍스트 윈도우**에서 실행된다. 메인 대화의 시스템 프롬프트를 상속하지 않으며, 마크다운 본문이 유일한 시스템 프롬프트가 된다. CLAUDE.md는 로드됨.

### KF-5: maxTurns는 도구 사용 턴만 카운트
턴 소비는 계층적으로 분리된다: 오케스트레이터의 Agent tool 호출 = 오케스트레이터 1턴 소비, 워커 내부 동작 = 워커의 maxTurns에서 별도 카운트.

### KF-6: 백그라운드/병렬 실행 가능
서브에이전트는 포그라운드(블로킹) 또는 백그라운드(병렬)로 실행 가능. 백그라운드 실행 시 권한을 미리 승인받고, 실행 중 추가 권한 요청은 자동 거부.

### KF-7: Agent Teams는 실험적
Agent Teams는 더 강력한 멀티에이전트 패턴(공유 태스크 리스트, 에이전트 간 직접 메시징)을 제공하나, 실험적 기능이며 세션 재개 불가, 중첩 팀 불가 등의 제한이 있다.

### KF-8: 공식 memory 필드 존재
frontmatter에 `memory: project` 같은 필드를 사용하면 MEMORY.md 기반의 자동 메모리 시스템이 활성화됨. 현재 프로젝트의 커스텀 YAML 메모리 시스템은 이를 사용하지 않고 마크다운 본문에 직접 구현.

## Recommendations

### R-1: 오케스트레이터 에이전트 신설
`.claude/agents/orchestrator.md`를 생성하고, `claude --agent orchestrator`로 실행하는 패턴을 채택한다.
```yaml
---
name: orchestrator
description: 작업을 분석하고 적절한 전문 에이전트에게 위임하는 조정자
tools: Agent(psychology-expert, mbti-expert, enneagram-expert, coding-expert, uiux-expert), Read, Glob, Grep
model: opus
maxTurns: 30
---
```

### R-2: `--agent` 실행 방식을 프로젝트 워크플로우에 통합
`claude --agent orchestrator "작업 설명"` 형태를 표준 실행 방식으로 정립. 스크립트나 Makefile로 래핑하면 편의성 향상.

### R-3: memory 필드 전환 검토
현재 커스텀 YAML 메모리 → 공식 `memory: project` 필드로 전환하면 시스템이 MEMORY.md를 자동 관리. 단, 현재 구조화된 YAML이 더 정밀하므로 트레이드오프 평가 필요.

### R-4: 워커 에이전트에서 Agent 도구 제거 확인
현재 5개 에이전트 모두 `Agent` 도구가 tools에 없으므로 이미 안전. 향후에도 워커 에이전트에는 `Agent`를 추가하지 않는다 (어차피 서브에이전트에서는 작동하지 않지만 명확성을 위해).

### R-5: isolation: worktree 활용 검토
coding-expert에 `isolation: worktree`를 적용하면 코드 변경 시 메인 작업 디렉토리와 충돌 없이 안전하게 작업 가능.

### R-6: Agent Teams 모니터링
현재는 실험적이므로 프로덕션 도입은 보류하되, 안정화 시 에이전트 간 직접 통신이 필요한 복잡한 작업에 활용 가능.

## References

- [Create custom subagents - Claude Code 공식 문서](https://code.claude.com/docs/en/sub-agents) — frontmatter 스펙, 도구 목록, permissionMode, 서브에이전트 제약 전체
- [Orchestrate teams of Claude Code sessions](https://code.claude.com/docs/en/agent-teams) — Agent Teams 실험적 기능 문서
- [Tools reference - Claude Code](https://code.claude.com/docs/en/tools-reference) — 전체 도구 25종 목록
- [Extend Claude with skills](https://code.claude.com/docs/en/skills) — skills 배열 동작 방식
- 프로젝트 내 에이전트 파일:
  - `/Users/kampikrein/A/personality/.claude/agents/psychology-expert.md`
  - `/Users/kampikrein/A/personality/.claude/agents/mbti-expert.md`
  - `/Users/kampikrein/A/personality/.claude/agents/enneagram-expert.md`
  - `/Users/kampikrein/A/personality/.claude/agents/coding-expert.md`
  - `/Users/kampikrein/A/personality/.claude/agents/uiux-expert.md`
- `/Users/kampikrein/A/personality/.claude/settings.local.json` — 현재 권한 설정
