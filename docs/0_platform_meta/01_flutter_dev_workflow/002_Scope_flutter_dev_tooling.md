---
id: "002"
type: scope
title: "Flutter 개발 워크플로우 도구 구축"
created: 2026-04-12
traces_brief: "001"
complexity: simple
research_needed: false
research_reason: "기존 스킬 패턴(~/.claude/skills/) 활용, 외부 API 조사 불필요, 변경 대상 명확"
auto_run: true
effort_mode: bypass
tdd_mode: false
uncertainty_level: low
intent: >
  Claude Code가 Flutter 모바일 개발 워크플로우를 표준화하여 수행할 수 있도록
  CLAUDE.md 가이드 섹션과 /flutter-dev 스킬을 구축한다.
summary: >
  2개 파일 생성/수정: CLAUDE.md에 Flutter 개발 컨벤션 섹션 추가,
  ~/.claude/skills/flutter-dev/SKILL.md 스킬 프로토콜 작성. bypass 모드.
keywords: [flutter, adb, skill, workflow, claude-code]
---

# Flutter 개발 워크플로우 도구 구축

## 작업 목표
Brief 001의 6개 결정사항을 구현한다:
1. CLAUDE.md에 Flutter 개발 워크플로우 섹션 추가 (에뮬레이터, 빌드, hot reload, 디버깅 컨벤션)
2. `/flutter-dev` 스킬 생성 (status, run, screenshot, log, install 서브커맨드)

성공 기준: 새 세션에서 `/flutter-dev status`로 디바이스 상태 확인, `/flutter-dev screenshot`으로 스크린샷 캡처 가능.

## 접근 방향
- **CLAUDE.md**: 기존 "모노레포 구조" 섹션 뒤에 `## Flutter 개발 워크플로우` 섹션 추가
- **스킬**: `~/.claude/skills/flutter-dev/SKILL.md` — 기존 스킬 패턴 따름 (protocol.md 방식)
- 대안 없음 — 접근법이 자명 (기존 인프라 패턴 그대로 활용)

## Research 판단
- **판단**: 불필요
- **근거**: 기존 스킬 패턴 활용, flutter/adb CLI 사용법 확인됨, 변경 파일 2개
- **파이프라인**: S → Agent(P) → Agent(I) → Agent(V)

## 설계

### 산출물 1: CLAUDE.md 섹션

`## Flutter 개발 워크플로우` 섹션에 포함할 내용:
- 에뮬레이터 전제: 사용자가 별도 실행, Claude는 ADB로 접근
- 빌드 정책: 코드 수정 후 `flutter build` 성공 확인 필수
- 스크린샷 검증: UI 변경 시 `adb screencap`으로 결과 확인
- hot reload: VS Code F5 실행 기준, 저장 시 자동 반영
- 로그 확인: `adb logcat` 필터링
- 앱 패키지명: `mobile/android/app/build.gradle`에서 확인

### 산출물 2: `/flutter-dev` 스킬

서브커맨드 구조:
| 커맨드 | 동작 | 주요 CLI |
|--------|------|---------|
| `status` (기본) | 디바이스 연결 확인 + Flutter doctor 요약 | `adb devices`, `flutter devices` |
| `run` | 앱 빌드 & 실행 | `cd mobile && flutter run` |
| `screenshot` | 스크린샷 캡처 → 표시 | `adb screencap`, Read tool |
| `log` | 앱 로그 필터링 | `adb logcat -s flutter` |
| `install` | release 빌드 설치 | `flutter build apk && adb install` |

iOS 예약: `## iOS (Reserved)` 섹션 — xcrun simctl 기반 명령어 추후 추가

### 변경 파일

**Modified (actual change):**
| # | 파일 | 변경 내용 | Confidence |
|---|------|---------|------------|
| 1 | `CLAUDE.md` | Flutter 개발 워크플로우 섹션 추가 | high |
| 2 | `~/.claude/skills/flutter-dev/SKILL.md` | 스킬 프로토콜 신규 생성 | high |

**Reviewed (check-only):**
| # | 파일 | 확인 내용 |
|---|------|---------|
| 1 | `mobile/android/app/build.gradle` | applicationId 확인 |
| 2 | `mobile/.gitignore` | tmp/ 포함 여부 확인 |

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 23s | 26620 |
| 2 | user-ai-exchange | 18s | 27750 |
| 3 | user-ai-exchange | 18s | 28730 |
| 4 | user-ai-exchange | 51s | 151383 |
| 5 | user-ai-exchange | 4s | 32374 |
| 6 | user-ai-exchange | 0s | 0 |
| 7 | user-ai-exchange | 0s | 0 |
| 8 | user-ai-exchange | 8s | 66364 |
| 9 | user-ai-exchange | 14s | 34219 |
| 10 | user-ai-exchange | 18s | 35330 |
| 11 | user-ai-exchange | 20s | 36529 |
| 12 | user-ai-exchange | 22s | 39532 |
| 13 | user-ai-exchange | 28s | 41166 |
| 14 | user-ai-exchange | 217s | 453803 |
| 15 | user-ai-exchange | 773s | 1224986 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 28316s |
| Total Tokens | 2198786 |
| Input Tokens | 69 |
| Output Tokens | 24311 |
| Cache Read | 1980789 |
| Cache Creation | 193617 |
