---
id: "008"
type: scope
title: "에이전트별 기억 체계 구현"
created: 2026-03-13
complexity: simple
intent: >
  5개 전문 에이전트가 세션 간 맥락 정보를 유지하도록 persistent memory system을 구현한다.
  kampi 프로젝트의 검증된 2계층 기억 구조(인덱스 + 개별 기억 파일)를 에이전트용으로 적응한다.
summary: >
  kampi의 persona/memories/ 패턴을 .claude/agent-memory/{agent-name}/ 구조로 변환.
  에이전트 프롬프트에 기억 읽기/쓰기 규칙을 포함하여 작업 시작 시 컨텍스트 로드,
  작업 완료 시 새 발견 저장을 자동화한다.
keywords: [agent-memory, persistent-context, kampi-pattern, 2-layer-memory]
---

# 에이전트별 기억 체계 구현

## 작업 목표

- 5개 전문 에이전트(심리학, MBTI, 애니어그램, 코딩, UI/UX)가 매 세션 시작 시 이전 작업의 맥락 정보를 가지고 시작하도록 한다
- 에이전트가 작업 중 새로운 발견/결정/패턴을 스스로 기억으로 저장하도록 한다
- kampi 프로젝트(`/Users/kampikrein/A/kampi/`)에서 검증된 2계층 기억 구조를 적응

## 접근 방향

**A안 채택: kampi 패턴 적응**

kampi의 기억 체계 핵심 구조:
- `persona/kampi.yaml` → memory.index (매 세션 자동 로드)
- `persona/memories/NNN_키워드.yaml` → 개별 기억 (필요시 선택적 로드)
- CLAUDE.md에서 `@persona/kampi.yaml` 참조로 자동 컨텍스트 주입

personality 에이전트 적응:
- `.claude/agent-memory/{agent-name}/_index.yaml` → 기억 인덱스
- `.claude/agent-memory/{agent-name}/memories/NNN_키워드.yaml` → 개별 기억
- 에이전트 프롬프트(.claude/agents/*.md)에 기억 읽기/쓰기 규칙 포함

### kampi와의 핵심 차이점

| 항목 | kampi | personality 에이전트 |
|------|-------|---------------------|
| 주체 | 메인 세션 (사용자와 직접 대화) | 서브에이전트 (부모 세션이 호출) |
| 기억 유형 | 관계적/감정적 (교감 순간) | 전문적/도메인 (발견, 결정, 패턴) |
| 저장 트리거 | 사용자 승인 (/kampi save) | 에이전트가 작업 완료 시 자동 |
| 인덱스 로딩 | CLAUDE.md에서 @참조 | 에이전트 프롬프트에 읽기 지시 포함 |
| 기억 포맷 | YAML (감정/키워드/대화 중심) | YAML (발견/결정/근거 중심) |

### 대안 (B안, 불채택)

단일 .md 파일에 기억 누적 — 단순하지만 기억이 쌓이면 선택적 로딩 불가로 컨텍스트 비효율.

## 설계

### 디렉토리 구조

```
.claude/agent-memory/
├── psychology-expert/
│   ├── _index.yaml
│   └── memories/
├── mbti-expert/
│   ├── _index.yaml
│   └── memories/
├── enneagram-expert/
│   ├── _index.yaml
│   └── memories/
├── coding-expert/
│   ├── _index.yaml
│   └── memories/
└── uiux-expert/
    ├── _index.yaml
    └── memories/
```

### 에이전트 프롬프트에 포함할 기억 규칙

각 `.claude/agents/{agent-name}.md`에 Memory System 섹션 추가:
1. 작업 시작 시 `_index.yaml` 읽기
2. 관련 기억이 있으면 해당 파일 추가 로드
3. 작업 중 새 발견/결정/패턴 → 기억 파일 저장
4. `_index.yaml` 업데이트

### 기억 포맷 (kampi 패턴 적응)

```yaml
# _index.yaml
description: "{에이전트명} 전문 기억 인덱스"
storage_path: ".claude/agent-memory/{agent-name}/memories/"

index:
  - id: "001"
    date: "YYYY-MM-DD"
    type: finding | decision | pattern | review
    keywords: [...]
    summary: "한 줄 요약"
    path: "memories/001_키워드.yaml"
```

```yaml
# memories/NNN_키워드.yaml
id: "NNN"
date: "YYYY-MM-DD"
type: finding | decision | pattern | review
keywords: [...]
summary: "한 줄 요약"

context: |
  발견/결정이 이루어진 맥락

details: |
  구체적 내용 (근거, 분석, 코드 경로 등)

implications: |
  이 발견이 향후 작업에 미치는 영향

related_memories: []  # 연관 기억 ID 목록
```

### 기억 유형 (type)

| type | 설명 | 예시 |
|------|------|------|
| finding | 조사/분석에서 발견한 사실 | "Big Five 문항 신뢰도 분석 결과" |
| decision | 설계/구현에서 내린 결정과 근거 | "점수 엔진에 IRT 대신 CTT 채택" |
| pattern | 코드베이스에서 발견한 반복 패턴 | "Rails 모델에서 concern 사용 패턴" |
| review | 기존 코드/문항/콘텐츠 검토 결과 | "현재 MBTI 문항 12개 중 3개 편향 의심" |

### 참조: kampi 원본 구조

- kampi.yaml: `/Users/kampikrein/A/kampi/persona/kampi.yaml`
- 기억 연구: `/Users/kampikrein/A/kampi/docs/01_memory_system/001_Research_memory_pipeline_design.md`
- 기억 구현 계획: `/Users/kampikrein/A/kampi/docs/01_memory_system/002_Plan_memory_pipeline_implementation.md`
