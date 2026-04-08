---
id: "001"
type: scope
title: "글로벌 오케스트레이션 참조 문서 + 플러그인 생성"
created: 2026-03-16
complexity: simple
research_needed: false
research_reason: "모든 시스템 구조가 현재 컨텍스트에 완전히 존재"
auto_run: true
intent: >
  personality 프로젝트에서 구현된 오케스트레이션 시스템(에이전트 7종 + 통합 프로토콜)을
  다른 프로젝트에서 재사용할 수 있도록 ~/.claude/에 참조 문서를 저장하고,
  글로벌 CLAUDE.md에 에이전트 설정 부족 시 안내를 추가하며,
  kampi-plugins 마켓에 플러그인으로 등록한다.
summary: >
  8개 파일 생성/수정. ~/.claude/docs/에 참조문서, ~/.claude/CLAUDE.md에 안내 추가,
  kampi-plugins/orchestration-system 플러그인 신규 등록.
keywords: [orchestration-system, global-reference, plugin, reusable]
---

# 글로벌 오케스트레이션 참조 문서 + 플러그인

## 작업 목표
- 오케스트레이션 시스템을 프로젝트 독립적 재사용 아티팩트로 만들기
- 신규 프로젝트에서 에이전트 설정이 없을 때 안내 경로 제공
- 플러그인 형태로 다른 컴퓨터·프로젝트에도 이식 가능하게

## 접근 방향
참조 문서(~/.claude/docs/)에 시스템 전체 설명 + 셋업 가이드를 저장하고,
플러그인(kampi-plugins)에 설치 가능한 형태로 에이전트 템플릿 + 프로토콜을 제공.
글로벌 CLAUDE.md는 에이전트 설정 감지 → 참조 문서 안내 역할.

## Research 판단
- **판단**: 불필요
- **근거**: 시스템 전체 구조가 현재 세션에서 완전히 파악됨
- **파이프라인**: S → P → I(V)

## 설계

### 변경 대상 (8파일)

| 파일 | 유형 | 내용 |
|------|------|------|
| `~/.claude/docs/05_orchestration_system/001_Reference_orchestration-system.md` | NEW | 전체 시스템 설명 + 셋업 가이드 |
| `~/.claude/CLAUDE.md` | EDIT | 에이전트 설정 부족 → 참조 안내 섹션 |
| `kampi-plugins/orchestration-system/README.md` | NEW | 플러그인 소개 + 설치법 |
| `kampi-plugins/orchestration-system/docs/orchestration-protocol.md` | NEW | 통합 프로토콜 제네릭 템플릿 |
| `kampi-plugins/orchestration-system/docs/CLAUDE-snippet.md` | NEW | 프로젝트 CLAUDE.md 붙여넣기 섹션 |
| `kampi-plugins/orchestration-system/agents/_domain-expert-template.md` | NEW | 도메인 에이전트 정의 템플릿 |
| `kampi-plugins/orchestration-system/commands/setup-orchestration.md` | NEW | /setup-orchestration 커맨드 |
| `kampi-plugins/marketplace.json` | EDIT | orchestration-system 엔트리 추가 |

### 핵심 설계 원칙
- 참조 문서: personality 프로젝트의 구체적 구현을 **설명**
- 플러그인: 새 프로젝트에서 **범용적으로 적용 가능한 제네릭 버전**
- 에이전트 7종은 도메인 의존적 → 플러그인에는 **템플릿** + personality 예시만 제공
- 프로토콜(orchestration.md)은 완전히 도메인 무관 → 그대로 이식 가능

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
