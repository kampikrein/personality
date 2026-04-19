---
id: "001"
type: brief
title: "Flutter 개발 워크플로우 — Claude Code 통합 도구"
created: 2026-04-12
status: completed
deep_critique: false
critique_docs: []
summary: >
  Claude Code가 Flutter 모바일 앱 개발 전 과정(에뮬레이터 관리, 빌드, hot reload, 디버깅, 스크린샷 검증)을
  CLI 도구(flutter, adb)를 활용해 자율적으로 수행할 수 있도록 가이드 문서와 실행 스킬을 구축한다.
  Android 우선, iOS 확장 가능 구조.
keywords: [flutter, adb, emulator, hot-reload, mobile-dev, skill, workflow]
---

# Flutter 개발 워크플로우 — Claude Code 통합 도구

## Intent
Claude Code가 Flutter 모바일 앱 개발 시 에뮬레이터 조작, 빌드, hot reload, 로그 확인, 스크린샷 검증 등
개발 전 과정을 자율적으로 수행할 수 있는 체계를 만든다.

현재 문제: flutter CLI와 adb가 설치되어 있고 기능적으로 충분하지만, Claude Code가 이를 활용하는
표준화된 워크플로우가 없어 매번 ad-hoc으로 접근하게 되고, 사용자가 기본적인 질문부터 다시 해야 한다.

목표: "코드 수정 → 에뮬레이터 반영 → 결과 확인"의 전 과정이 가이드/스킬로 표준화되어,
새 세션에서도 일관된 워크플로우로 작업할 수 있어야 한다.

## Context
- **프로젝트**: personality 모노레포. `mobile/` 하위에 Flutter 앱 (타로 + 성격 서비스)
- **Flutter 앱 구조**: feature-based (`lib/features/shuffle/`, `lib/features/reading/`, etc.), Riverpod, Drift DB, Flame 엔진
- **도구 환경**:
  - Flutter: `/opt/homebrew/bin/flutter` (설치됨)
  - ADB: `$ANDROID_HOME/platform-tools/adb` (v37.0, 설치됨)
  - Android SDK: `$ANDROID_HOME=/Users/kampikrein/Library/Android/sdk`
  - IDE: VS Code + `Dart-Code.flutter` 확장 설치 완료
  - Claude Code: VS Code 터미널에서 실행
- **기존 인프라**: 전문 에이전트 7개 정의 (flutter-expert 포함), 스킬 시스템 구축됨
- **iOS**: `mobile/ios/` 디렉토리 존재, 미사용 상태

## Boundaries

### In Scope
| # | Item | Description |
|---|------|-------------|
| 1 | CLAUDE.md 가이드 섹션 | Flutter 개발 워크플로우 컨벤션 — 에뮬레이터/빌드/디버깅 표준 절차 |
| 2 | flutter-dev 스킬 | 에뮬레이터 상태 확인, 앱 실행, 스크린샷 캡처, 로그 조회 등 자동화 스킬 |
| 3 | ADB 명령어 래핑 | 스크린샷, 로그 필터링, 앱 상태 관리 등 자주 쓰는 ADB 작업 표준화 |
| 4 | Android 에뮬레이터 워크플로우 | 1차 타겟 플랫폼 |
| 5 | iOS 확장 가능 구조 | 구조적으로 iOS 지원을 추가할 수 있는 설계 |

### Out of Scope
| # | Item | Reason |
|---|------|--------|
| 1 | 에뮬레이터 생성/삭제 | AVD 생성은 빈도 낮고 GUI가 효율적 |
| 2 | CI/CD 파이프라인 | 로컬 개발 워크플로우에 집중 |
| 3 | iOS 구현 | 1차에서는 Android만. 구조만 확장 가능하게 |
| 4 | Flutter 테스트 자동화 | 별도 스킬 또는 별도 scope에서 다룰 영역 |
| 5 | VS Code 확장 개발 | 기존 Dart-Code 확장으로 충분 |

## Decisions

| # | Decision | Chosen | Rationale | Trade-off | Alternatives Considered |
|---|----------|--------|-----------|-----------|------------------------|
| 1 | 산출물 범위 | CLAUDE.md 가이드 + 실행 스킬 2개 조합 | 가이드만으로는 매번 ad-hoc 실행이 반복됨. 스킬이 있어야 표준 워크플로우가 자동화됨. 하지만 가이드가 없으면 스킬 외 상황에서 기준이 없음. 둘 다 필요. | 스킬 제작에 추가 시간 소요. 하지만 이후 모든 세션에서 시간 절약되므로 투자 대비 효과 높음. | (A) 가이드 문서만 — 매번 수동 명령 필요, 반복. (B) 스킬만 — 스킬이 커버하지 않는 상황에서 기준 부재. (C) 셸 스크립트 래퍼 — 유지보수 포인트 증가, 스킬이 이미 같은 역할 수행 |
| 2 | 에뮬레이터 관리 방식 | 사용자가 별도로 에뮬레이터 실행, Claude Code는 ADB로 접근 | 앞선 대화에서 확인: 에뮬레이터는 장시간 프로세스이고, Claude CLI 터미널에서 관리하면 세션 종속성과 로그 오염 문제 발생. ADB가 터미널 독립적으로 접근 가능하므로 별도 실행이 최적. | 에뮬레이터 시작을 자동화할 수 없음. 하지만 에뮬레이터는 한번 켜면 오래 유지하므로 자동화 필요성 낮음. | (A) Claude CLI에서 background로 에뮬레이터 실행 — 세션 종료 시 불안정, 로그 컨텍스트 소모 |
| 3 | 스킬 구조 | 단일 `flutter-dev` 스킬 (서브커맨드로 분기) | 에뮬레이터 상태 확인, 앱 실행, 스크린샷, 로그가 모두 "모바일 개발 워크플로우"라는 하나의 맥락. 스킬을 분리하면 사용자가 어떤 스킬을 써야 할지 판단해야 함. 단일 스킬 + 서브커맨드가 진입점을 단순화. | 스킬 프로토콜이 길어질 수 있음. 하지만 서브커맨드별 섹션으로 구조화하면 관리 가능. | (A) 기능별 스킬 분리 (flutter-run, flutter-screenshot, etc.) — 진입점 과다, 사용자 혼란. (B) 셸 스크립트 + 스킬 — 유지보수 포인트 2개, 불필요한 복잡도 |
| 4 | hot reload 전략 | VS Code Flutter 확장의 자동 hot reload 활용 (F5 실행 시) | 앞선 대화에서 확인: VS Code + Dart-Code 확장이 설치되어 있으며, F5로 실행하면 저장 시 자동 hot reload. Claude Code가 코드를 수정하면 VS Code가 파일 변경을 감지하여 자동 반영. 별도 메커니즘 불필요. | Claude CLI 터미널에서 `flutter run`을 직접 실행하는 경우 수동 `r` 키 필요. 하지만 F5 워크플로우를 표준으로 정하면 이 문제 회피. | (A) Claude가 flutter run + r키 관리 — 복잡하고 불안정, 터미널 세션 관리 필요 |
| 5 | iOS 확장 설계 | 플랫폼 추상화 계층 없이, 스킬 프로토콜에 플랫폼 분기 섹션만 예약 | 현재 iOS 사용 계획 없음. 추상화 계층을 미리 만들면 YAGNI 위반. 스킬 프로토콜에 `## iOS (Reserved)` 섹션만 두고, 필요 시 해당 섹션을 채우는 것이 가장 가벼운 확장 경로. | iOS 도입 시 스킬 수정 필요. 하지만 수정 범위가 섹션 추가 수준이므로 비용 낮음. | (A) 플랫폼 추상화 인터페이스 — 과도한 사전 설계, 현재 Android만 사용 |
| 6 | 스크린샷 검증 통합 | adb screencap → 로컬 파일 저장 → Read tool로 이미지 확인 | Claude Code는 멀티모달이므로 이미지를 직접 볼 수 있음. ADB 스크린샷을 캡처하여 Read하면 UI 변경 결과를 시각적으로 검증 가능. 웹 개발에서는 어려운 이 기능이 모바일에서는 ADB 덕분에 가능. | 스크린샷 파일 관리(정리) 필요. tmp/ 디렉토리 사용으로 해결. | (A) 스크린샷 없이 로그만 확인 — UI 변경 검증 불가 |

## Open Questions

| # | Question | Impact | Status |
|---|----------|--------|--------|
| — | — | — | — |

## Constraints
- Claude Code 샌드박스: `~/.cursor/`, 일부 시스템 경로 쓰기 제한 → adb/flutter 실행은 sandbox bypass 필요할 수 있음
- 에뮬레이터 프로세스는 Claude CLI 세션과 독립적으로 유지되어야 함
- VS Code Flutter 확장이 설치되어 있어야 자동 hot reload 가능
- `$ANDROID_HOME` 환경 변수가 설정되어 있어야 ADB 접근 가능

## Exit Criteria
- [x] 산출물 범위 결정 (가이드 + 스킬)
- [x] 에뮬레이터 관리 방식 결정 (별도 실행 + ADB 접근)
- [x] 스킬 구조 결정 (단일 스킬 + 서브커맨드)
- [x] hot reload 전략 결정 (VS Code 확장 활용)
- [x] iOS 확장 전략 결정 (예약 섹션)
- [x] 스크린샷 검증 방식 결정 (adb + Read)

## Model Anchors

### MA-1: 산출물 구성
두 개의 산출물을 생성한다:
1. `CLAUDE.md`에 `## Flutter 개발 워크플로우` 섹션 추가 — 에뮬레이터/빌드/디버깅 컨벤션
2. `~/.claude/skills/flutter-dev/SKILL.md` 스킬 생성 — 서브커맨드 기반 실행 자동화

### MA-2: 에뮬레이터 접근 패턴
에뮬레이터는 사용자가 별도로 실행한다고 가정한다. Claude Code는 `adb devices`로 연결 상태를 확인하고,
연결된 디바이스가 없으면 사용자에게 에뮬레이터 실행을 안내한다. 직접 `emulator` 명령을 실행하지 않는다.

### MA-3: 스킬 서브커맨드
`/flutter-dev` 스킬은 다음 서브커맨드를 지원한다:
- `status` — 디바이스 연결 상태, Flutter doctor 요약
- `run` — flutter run 실행 (디바이스 확인 → 빌드 → 실행)
- `screenshot` — adb screencap → tmp/ 저장 → Read로 표시
- `log` — adb logcat 필터링 (flutter, 앱 패키지)
- `install` — flutter build + adb install (release 빌드)
- (인수 없음) — status 실행

### MA-4: hot reload 워크플로우
표준 워크플로우: 사용자가 VS Code에서 F5로 flutter run 실행 → Claude Code가 코드 수정 →
VS Code가 파일 변경 감지 → 자동 hot reload. Claude Code는 flutter run을 직접 관리하지 않는다.
단, 사용자가 요청하면 터미널에서 flutter run을 실행하고 수동 r키를 전송할 수 있다.

### MA-5: 스크린샷 파일 경로
스크린샷은 `mobile/tmp/screenshots/` 하위에 타임스탬프 기반으로 저장한다.
형식: `screenshot_YYYYMMDD_HHMMSS.png`. .gitignore에 이미 tmp/가 포함되어 있으므로 추가 설정 불필요.

### MA-6: iOS 확장
스킬 프로토콜에 `## iOS (Reserved)` 섹션을 둔다. iOS 지원 시 이 섹션에 xcrun simctl 기반
명령어를 추가한다. 플랫폼 추상화 계층은 만들지 않는다.

### MA-7: CLAUDE.md 가이드 내용
다음 항목을 포함한다:
- 에뮬레이터 전제: 사용자가 별도 실행, Claude는 ADB로 접근
- 빌드 정책: 코드 수정 후 flutter build 성공 확인 필수
- 스크린샷 검증: UI 변경 시 adb screencap으로 결과 확인
- hot reload: VS Code F5 실행 기준, 터미널 flutter run은 대안
- 로그 확인: adb logcat -s flutter로 앱 로그 필터링

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
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 27439s |
| Total Tokens | 973800 |
| Input Tokens | 49 |
| Output Tokens | 16482 |
| Cache Read | 808853 |
| Cache Creation | 148416 |
