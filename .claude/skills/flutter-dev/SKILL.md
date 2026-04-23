---
name: flutter-dev
description: "Flutter mobile app development workflow for Claude Code. Device connection check, build & run, screenshot capture, log filtering, APK install, tmux-based detached flutter run with hot reload control. Android-first, iOS reserved. Use when working on mobile/ Flutter app in personality monorepo."
argument-hint: "[status|run|tmux|reload|restart|stop|screenshot|log|install]"
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
TMUX_SESSION=flutter_dev
TMUX_LOG=$MOBILE_DIR/tmp/flutter_run.log
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

**Claude Code 자체에서 hot reload까지 제어하려면 `tmux` 서브커맨드를 사용한다.**
`run`은 foreground라 Claude Bash 호출 종료와 함께 프로세스가 죽지만, `tmux` 모드는 detached 세션에 flutter run을 심어 세션 수명을 OS에 위임한다.

---

## tmux

Claude Code가 `flutter run`을 조작하기 위한 **observable** 방식이 기본이다.
사용자가 attached된 기존 tmux 세션에 flutter run window를 **직접 추가**하면, Claude의 send-keys 조작을 사용자가 실시간으로 본다. 별도 `flutter_dev` 세션을 만드는 hidden 방식은 사용자 관찰 가능성이 제로라 권장하지 않는다.

**전제:** `tmux`가 설치되어 있어야 함 (`brew install tmux`). 사용자가 tmux 안에서 작업 중이어야 한다.

**Steps (observable — 사용자 active window에 pane split):**

사용자의 현재 window에 **pane을 split**해서 flutter run을 나란히 표시한다.
`new-window` (full-screen 전환식 탭)보다 `split-window` (동시 표시) 방식이 **관찰 가능성이 높다** — 사용자가 작업 pane과 flutter 로그 pane을 동시에 본다.

1. ADB 디바이스 확인 (status Step 1 동일)
2. 사용자가 attached된 세션과 현재 window·pane 탐지
   ```bash
   SESSION=$(tmux list-clients -F '#S' | head -1)
   WINDOW_PANE=$(tmux display-message -p -t "$SESSION" '#{window_index}.#{pane_index}')
   TARGET_WIN="$SESSION:${WINDOW_PANE%.*}"
   ```
   - 비어있으면 **hidden fallback** (아래) 사용.
3. 세션에 flutter split pane 추가 (`-d`로 포커스 유지, `-h`로 좌우 분할)
   ```bash
   DEVICE_ID=$($ANDROID_HOME/platform-tools/adb devices | awk 'NR>1 && $2=="device"{print $1; exit}')
   NEW_PANE=$(tmux split-window -d -h -P -F '#{pane_id}' \
     -t "$TARGET_WIN" \
     -c /Users/kampikrein/A/personality/mobile \
     "flutter run -d $DEVICE_ID; exec zsh")
   echo "flutter pane = $NEW_PANE"  # e.g. %75
   ```
   - `-P -F '#{pane_id}'`로 새 pane id를 캡처 → 이후 조작 target. pane index는 휘발하지만 pane-id(`%75`)는 pane 수명 동안 안정.
   - 끝에 `exec zsh`를 붙여 flutter run 종료돼도 pane이 닫히지 않도록 한다.
4. 빌드 완료 폴링 (최대 150초, 5초 간격)
   ```bash
   for i in $(seq 1 30); do
     sleep 5
     OUT=$(tmux capture-pane -p -t "$NEW_PANE" -S -300)
     if echo "$OUT" | grep -qE "Flutter run key commands"; then
       echo "flutter run ready"
       break
     fi
     if echo "$OUT" | grep -qE "Connection refused|Error connecting to the service protocol"; then
       echo "[adb forward stale — kill adb and retry]"
       break
     fi
   done
   ```
5. pane-id를 파일에 기록 (다음 Bash 호출에서 재사용)
   ```bash
   echo "$NEW_PANE" > /Users/kampikrein/A/personality/mobile/tmp/.flutter_pane
   ```
6. 사용자 안내: "현재 window 옆에 flutter pane이 split됐습니다. `Ctrl-b ←/→`로 pane 포커스 이동, `Ctrl-b z`로 해당 pane 확대 토글. `/flutter-dev reload|restart|stop`으로 조작합니다."

**이후 조작의 target 규약**: reload/restart/stop은 `/tmp/.flutter_pane`에 저장된 pane-id(`%75`)를 읽어 `tmux send-keys -t "$(cat …/.flutter_pane)"`로 전송한다. pane-id는 pane 수명 동안 불변이므로 window·pane index가 재배치돼도 target이 무너지지 않는다.

---

### hidden fallback (사용자 관찰 불요, 비권장)

사용자가 tmux 밖에서 Claude Code만 단독 사용 중일 때만.

```bash
tmux kill-session -t flutter_dev 2>/dev/null || true
tmux new-session -d -s flutter_dev -c /Users/kampikrein/A/personality/mobile
tmux send-keys -t flutter_dev "/opt/homebrew/bin/flutter run -d $DEVICE_ID" Enter
# 이후 target = flutter_dev
```

---

### ⚠️ 주의: tmux linked-window 금지

과거 한 번 시도했던 `tmux link-window -s flutter_dev:0 -t <user_session>: -a` 방식은 **피한다**.
이 방식 직후 사용자의 `select-window`를 호출하면 linked window와 원본 세션이 동시에 사라지는 tmux 3.6 거동이 확인됐다 (flutter run이 SIGHUP으로 죽는다). 항상 `new-window -d`로 사용자 세션에 **독립된 window**를 만드는 것이 안전하다.

---

## reload

tmux의 flutter run pane에 hot reload 키(`r`)를 전달. **observable 모드**에서는 pane-id를 파일에서 읽는다.

```bash
TARGET=$(cat /Users/kampikrein/A/personality/mobile/tmp/.flutter_pane)  # observable (%75 등)
# fallback: TARGET=flutter_dev
tmux send-keys -t "$TARGET" 'r'
sleep 1
tmux capture-pane -p -t "$TARGET" -S -40 | tail -20
```

**주의:** `r` 뒤에 `Enter`를 붙이지 않는다. flutter run은 단일 문자 키 이벤트를 읽으므로 Enter를 붙이면 무응답.

**언제 쓰나:** 위젯 트리 / build 함수 변경. state는 보존된다.

---

## restart

hot restart 키(`R`). state를 리셋하고 앱 로직을 재시작.

```bash
TARGET=$(cat /Users/kampikrein/A/personality/mobile/tmp/.flutter_pane)
tmux send-keys -t "$TARGET" 'R'
sleep 2
tmux capture-pane -p -t "$TARGET" -S -40 | tail -20
```

**언제 쓰나:** `initState` / provider 초기화 / DB 스냅샷 / 라우팅 초기 분기 변경. reload로 state가 남아 검증이 어려울 때.

---

## stop

flutter run 종료(`q`) 후 pane 정리. `exec zsh` 때문에 pane 자체는 q 이후 zsh로 잔존 — 필요하면 kill-pane로 닫는다.

```bash
TARGET=$(cat /Users/kampikrein/A/personality/mobile/tmp/.flutter_pane)
tmux send-keys -t "$TARGET" 'q'
sleep 1
tmux kill-pane -t "$TARGET" 2>/dev/null || true
rm -f /Users/kampikrein/A/personality/mobile/tmp/.flutter_pane
# hidden fallback: tmux kill-session -t flutter_dev 2>/dev/null || true
```

---

## tmux 로그 덤프

장시간 누적된 stdout을 파일로 캡처.

```bash
TARGET=$(cat /Users/kampikrein/A/personality/mobile/tmp/.flutter_pane)
tmux capture-pane -pS - -t "$TARGET" > /Users/kampikrein/A/personality/mobile/tmp/flutter_run.log
```

---

## run vs tmux 선택 기준

| 상황 | 추천 |
|------|------|
| UI 수정 반복 (빠른 hot reload 필요) | **tmux + reload** |
| `initState` / DB / 라우팅 초기 분기 변경 | **tmux + restart** 또는 `install` (cold start) |
| 상태/DB/빌드 레이어 동시 검증 | **install** (APK 재설치 + `adb shell am start`) |
| 사용자가 이미 VS Code F5로 실행 중 | **run 금지** — 같은 디바이스에 중복 인스턴스 충돌 가능. tmux도 주의. |
| 단순 빌드 검증만 | `cd mobile && flutter build apk --debug` (run 불필요) |

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
| `tmux: command not found` | `brew install tmux` 안내 후 종료 |
| `duplicate session: flutter_dev` | tmux 섹션 Step 2의 `kill-session`이 먼저 실행됐는지 확인, 수동 실행: `tmux kill-session -t flutter_dev` |
| `no server running` on `send-keys` | `tmux` 서브커맨드로 세션을 먼저 생성하지 않고 `reload`/`restart`/`stop` 호출한 경우. `/flutter-dev tmux` 선행 |
| reload 후 변경이 반영 안 됨 | state가 캐시된 경우 `restart`(hot restart)로 상향. `initState`·provider 초기화 변경은 restart 필수. |
| `Error connecting to the service protocol: ... Connection refused` | adb port forwarding stale. `adb kill-server && adb start-server`로 adb 데몬 재기동 후 flutter run 재투입. 외부에서 `adb install -r`로 APK를 덮어썼을 때 자주 발생. |
| flutter-dev 같은 hidden 세션이 `select-window` 후 사라짐 | tmux 3.6의 link-window + select-window 조합 거동. **linked window 금지.** 사용자 세션에 `new-window -d`로 독립 window 추가 방식 사용. |
