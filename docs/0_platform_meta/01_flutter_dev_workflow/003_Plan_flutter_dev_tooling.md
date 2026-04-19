---
id: "003"
type: plan
title: "Flutter 개발 워크플로우 도구 구축"
created: 2026-04-12
status: in-progress
traces_brief: "001"
traces_scope: "002"
summary: >
  CLAUDE.md에 Flutter 개발 워크플로우 섹션을 추가하고, ~/.claude/skills/flutter-dev/SKILL.md
  스킬을 신규 생성한다. 에뮬레이터 접근(ADB), 빌드 검증, 스크린샷 캡처, 로그 필터링,
  hot reload 표준 절차를 포함한다.
keywords: [flutter, adb, skill, workflow, claude-code, mobile]
structural_decisions:
  - decision: "에뮬레이터 관리 방식"
    chosen: "사용자 별도 실행 + ADB 접근"
    rationale: "에뮬레이터는 장시간 프로세스이므로 Claude CLI 세션 독립 필요. ADB가 터미널 독립적으로 접근 가능."
  - decision: "스킬 구조"
    chosen: "단일 flutter-dev 스킬 + 서브커맨드 분기"
    rationale: "기능이 모두 '모바일 개발 워크플로우' 하나의 맥락. 진입점을 단순화."
  - decision: "hot reload 전략"
    chosen: "VS Code F5 + Dart-Code 확장 자동 hot reload 표준"
    rationale: "이미 VS Code + Dart-Code가 설치되어 있으며 저장 시 자동 반영. 별도 관리 불필요."
---

# Flutter 개발 워크플로우 도구 구축 — 구현 플랜

## 개요

변경 파일 2개, 단일 Phase. 구조적 결정사항은 이미 Scope 002에서 확정됨.

| # | 파일 | 변경 종류 |
|---|------|---------|
| 1 | `/Users/kampikrein/A/personality/CLAUDE.md` | 섹션 추가 (Edit) |
| 2 | `~/.claude/skills/flutter-dev/SKILL.md` | 신규 생성 (Write) |

---

## Phase 1: CLAUDE.md 섹션 추가

### 삽입 위치

`## 모노레포 구조` 섹션 끝 ~ `# 위임 판단` 섹션 시작 사이에 삽입한다.

**Before (현재 CLAUDE.md 9-11번 줄):**

```markdown
- `docs/` — 공유 문서 (산출물 중앙화)

# 위임 판단
```

**After (삽입 후):**

```markdown
- `docs/` — 공유 문서 (산출물 중앙화)

## Flutter 개발 워크플로우

### 전제 조건
- **에뮬레이터**: 사용자가 Android Studio / AVD Manager에서 별도 실행. Claude Code는 ADB로 접근.
  - 디바이스 확인: `$ANDROID_HOME/platform-tools/adb devices`
  - 연결 디바이스가 없으면 사용자에게 에뮬레이터 실행 요청. 직접 `emulator` 명령 실행 금지.
- **환경 변수**: `ANDROID_HOME=/Users/kampikrein/Library/Android/sdk`
- **앱 패키지명**: `com.personality.personality_mobile`

### 빌드 정책
코드 수정 후 빌드 성공 여부를 반드시 확인한다.

```bash
cd /Users/kampikrein/A/personality/mobile
flutter build apk --debug   # 빌드 성공 확인
```

빌드 실패 시 오류를 해결하고 재빌드. 빌드 성공 확인 없이 완료 보고 금지.

### Hot Reload 표준
- **표준**: 사용자가 VS Code에서 F5로 `flutter run` 실행 → 저장 시 Dart-Code 확장이 자동 hot reload.
- **대안**: 터미널에서 `flutter run` 직접 실행 → 수동 `r` 키로 reload.
- Claude Code는 flutter run 프로세스를 직접 관리하지 않는다 (세션 종속성 방지).

### 스크린샷 검증
UI 변경 시 ADB 스크린샷으로 결과를 시각적으로 확인한다.

```bash
# 스크린샷 캡처 및 Pull
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SAVE_PATH="/Users/kampikrein/A/personality/mobile/tmp/screenshots/screenshot_${TIMESTAMP}.png"
mkdir -p "$(dirname $SAVE_PATH)"
$ANDROID_HOME/platform-tools/adb exec-out screencap -p > "$SAVE_PATH"
# 이후 Read tool로 이미지 확인
```

스크린샷은 `mobile/tmp/screenshots/` 에 저장 (`.gitignore` 처리됨).

### 로그 확인

```bash
# Flutter 로그만 필터링
$ANDROID_HOME/platform-tools/adb logcat -s flutter

# 앱 전체 로그 (패키지 필터)
$ANDROID_HOME/platform-tools/adb logcat | grep -i "personality_mobile"

# 최근 로그만 (이전 로그 무시)
$ANDROID_HOME/platform-tools/adb logcat -T 1 -s flutter
```

### 빠른 참조

| 작업 | 명령 |
|------|------|
| 디바이스 확인 | `adb devices` |
| 앱 실행 | `cd mobile && flutter run` |
| 스크린샷 | `/flutter-dev screenshot` 스킬 사용 |
| 로그 | `adb logcat -s flutter` |
| Release 빌드 설치 | `flutter build apk && adb install build/app/outputs/flutter-apk/app-release.apk` |

# 위임 판단
```

**Edit 조작:**
- `old_string`: `- \`docs/\` — 공유 문서 (산출물 중앙화)\n\n# 위임 판단`
- `new_string`: 위 After 블록 전체

---

## Phase 2: ~/.claude/skills/flutter-dev/SKILL.md 생성

### 파일 경로
`/Users/kampikrein/.claude/skills/flutter-dev/SKILL.md`

### 디렉토리 생성
```bash
mkdir -p /Users/kampikrein/.claude/skills/flutter-dev/
```

### 파일 전체 내용

```markdown
---
name: flutter-dev
description: "Flutter mobile app development workflow for Claude Code. Device connection check, build & run, screenshot capture, log filtering, APK install. Android-first, iOS reserved. Use when working on mobile/ Flutter app in personality monorepo."
argument-hint: "[status|run|screenshot|log|install]"
---

# /flutter-dev — Flutter 개발 워크플로우 스킬

personality 모노레포의 Flutter 모바일 앱 개발에서 반복적으로 쓰는 ADB/flutter 작업을 표준화한다.

## 환경 상수

```
FLUTTER=/opt/homebrew/bin/flutter
ADB=$ANDROID_HOME/platform-tools/adb
APP_ID=com.personality.personality_mobile
MOBILE_DIR=/Users/kampikrein/A/personality/mobile
SCREENSHOT_DIR=$MOBILE_DIR/tmp/screenshots
```

## 서브커맨드 분기

`$ARGUMENTS`를 파싱하여 서브커맨드 결정. 인수 없으면 `status` 실행.

---

## status (기본)

디바이스 연결 상태와 Flutter 환경을 확인한다.

**Steps:**

1. ADB 디바이스 목록 확인
   ```bash
   $ANDROID_HOME/platform-tools/adb devices
   ```
   - 연결된 디바이스가 없으면: "에뮬레이터가 연결되지 않았습니다. Android Studio에서 에뮬레이터를 실행하세요." 안내 후 종료.

2. Flutter 디바이스 목록 확인
   ```bash
   /opt/homebrew/bin/flutter devices
   ```

3. Flutter doctor 요약 (에러/경고만)
   ```bash
   /opt/homebrew/bin/flutter doctor 2>&1 | grep -E "(✗|✘|!|Error|Warning)" | head -20
   ```

**Output:** 디바이스 ID, 이름, 상태 요약 테이블.

---

## run

Flutter 앱을 빌드하고 실행한다.

**Steps:**

1. ADB 디바이스 확인 (status 서브커맨드 Step 1 동일)
2. 앱 빌드 & 실행
   ```bash
   cd /Users/kampikrein/A/personality/mobile && /opt/homebrew/bin/flutter run
   ```
   - 빌드 실패 시 오류 메시지 표시 후 종료.
3. 실행 성공 시 사용자에게 알림: "앱이 실행 중입니다. VS Code에서 F5를 사용하면 hot reload가 자동으로 동작합니다."

**Note:** `flutter run` 은 foreground 프로세스이므로, 터미널 세션이 필요하다.
VS Code에서 F5로 실행하는 것이 hot reload 자동화를 위한 표준 방법이다.

---

## screenshot

에뮬레이터 현재 화면을 캡처하고 표시한다.

**Steps:**

1. ADB 디바이스 확인
2. 저장 경로 생성
   ```bash
   TIMESTAMP=$(date +%Y%m%d_%H%M%S)
   SAVE_PATH="/Users/kampikrein/A/personality/mobile/tmp/screenshots/screenshot_${TIMESTAMP}.png"
   mkdir -p "$(dirname $SAVE_PATH)"
   ```
3. 스크린샷 캡처 및 Pull
   ```bash
   $ANDROID_HOME/platform-tools/adb exec-out screencap -p > "$SAVE_PATH"
   ```
4. Read tool로 이미지 확인
   - `Read(file_path=SAVE_PATH)` — Claude Code 멀티모달로 직접 확인
5. 저장 경로 보고: "Screenshot saved: {SAVE_PATH}"

**저장 위치:** `mobile/tmp/screenshots/screenshot_YYYYMMDD_HHMMSS.png`
(`.gitignore`에 `tmp/` 포함되어 있어 커밋되지 않음)

---

## log

앱 로그를 필터링하여 표시한다.

**Steps:**

1. ADB 디바이스 확인
2. 로그 유형 결정 (`$ARGUMENTS`에 추가 인수가 있으면 참고):
   - 기본: Flutter 로그만
   - `all`: 앱 전체 로그
   - `error`: 에러/크래시만
3. 로그 출력 (최근 로그부터, 최대 100줄)
   ```bash
   # 기본 — Flutter 로그
   $ANDROID_HOME/platform-tools/adb logcat -T 1 -s flutter 2>&1 | head -100
   
   # all — 앱 전체
   $ANDROID_HOME/platform-tools/adb logcat -T 1 2>&1 | grep -i "personality" | head -100
   
   # error — 에러/크래시
   $ANDROID_HOME/platform-tools/adb logcat -T 1 *:E 2>&1 | head -50
   ```

---

## install

Release APK를 빌드하고 디바이스에 설치한다.

**Steps:**

1. ADB 디바이스 확인
2. Release APK 빌드
   ```bash
   cd /Users/kampikrein/A/personality/mobile && /opt/homebrew/bin/flutter build apk --release
   ```
3. APK 설치
   ```bash
   $ANDROID_HOME/platform-tools/adb install -r /Users/kampikrein/A/personality/mobile/build/app/outputs/flutter-apk/app-release.apk
   ```
4. 설치 완료 보고

---

## iOS (Reserved)

iOS 지원 시 이 섹션에 xcrun simctl 기반 명령어를 추가한다.

```bash
# 예약 — 미구현
# xcrun simctl list devices
# xcrun simctl boot {UDID}
# xcrun simctl install booted {APP_PATH}
# xcrun simctl launch booted {BUNDLE_ID}
# xcrun simctl io booted screenshot {SAVE_PATH}
```

플랫폼 추상화 계층 없이, 각 서브커맨드에 `if iOS: ... else Android: ...` 분기로 구현 예정.

---

## 공통 에러 처리

| 상황 | 처리 |
|------|------|
| `adb: command not found` | `$ANDROID_HOME` 환경변수 미설정. "ANDROID_HOME=/Users/kampikrein/Library/Android/sdk 를 shell profile에 추가하세요." 안내 |
| `error: no devices/emulators found` | "Android Studio에서 에뮬레이터를 실행하세요." 안내 |
| `flutter: command not found` | `/opt/homebrew/bin/flutter`로 절대경로 사용. PATH 미설정 시 절대경로로 fallback. |
| 빌드 오류 | 오류 메시지 전체 출력, `flutter clean && flutter pub get` 제안 |
```

---

## 실행 순서 (Implementation)

1. `mkdir -p /Users/kampikrein/.claude/skills/flutter-dev/`
2. Write `~/.claude/skills/flutter-dev/SKILL.md` (위 전체 내용)
3. Edit `/Users/kampikrein/A/personality/CLAUDE.md` — `## Flutter 개발 워크플로우` 섹션 삽입

순서 의존성 없음. 2, 3을 병렬 실행 가능.

## 검증 기준

| 항목 | 확인 방법 |
|------|---------|
| CLAUDE.md 삽입 위치 정확성 | 모노레포 구조 섹션 바로 아래, 위임 판단 섹션 바로 위 |
| SKILL.md 서브커맨드 완전성 | status / run / screenshot / log / install 5개 모두 포함 |
| iOS Reserved 섹션 존재 | `## iOS (Reserved)` 섹션 포함 확인 |
| 스크린샷 경로 형식 | `mobile/tmp/screenshots/screenshot_YYYYMMDD_HHMMSS.png` |
| ADB 절대경로 사용 | `$ANDROID_HOME/platform-tools/adb` 형식 |

## 리스크 및 고려사항

| 리스크 | 대응 |
|--------|------|
| sandbox 모드에서 `~/.claude/` 쓰기 제한 | `dangerouslyDisableSandbox: true`로 재시도 |
| `adb exec-out screencap` vs `adb shell screencap` 방식 차이 | `exec-out`이 pull 없이 직접 바이너리 수신 가능하여 선택. 실패 시 `adb shell screencap /sdcard/tmp.png && adb pull /sdcard/tmp.png $SAVE_PATH` fallback |
| CLAUDE.md Edit의 old_string 공백 정확성 | 삽입 전 파일을 Read하여 실제 공백/개행 확인 필수 |

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
