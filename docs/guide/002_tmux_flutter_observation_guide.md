---
id: "guide-002"
type: reference
title: "tmux 관찰 가이드 — Claude Code가 조작하는 Flutter 세션을 실시간으로 보기"
created: 2026-04-24
impl_commits: ["af68fbc", "20eb25f"]
---

# tmux 관찰 가이드 — Claude Code × Flutter

## 0. 왜 이 문서가 있나

Claude Code는 Bash 호출 단위로 동작한다. 호출이 끝나면 그 안에서 띄운 프로세스는 일반적으로 같이 죽는다. 그래서 `flutter run`처럼 **interactive REPL + 장시간 생존 + 사용자가 실시간 관찰하고 싶은** 프로세스를 Claude가 직접 돌리려면 중간 레이어가 필요하다. 그 레이어가 tmux다.

이 문서는 세 가지 질문에 답한다.

1. tmux가 도대체 무엇을 어떻게 계층화하는가.
2. Claude가 조작하는 것을 내가 실시간으로 보려면 어떤 배치가 좋은가.
3. 오늘 쓸 수 있는 실전 단축키와 타협 기준은 무엇인가.

---

## 1. tmux의 3 계층 + 1 축

tmux가 제공하는 추상은 **session > window > pane**의 3단 트리와, 각 session에 여러 개 붙을 수 있는 **client**로 구성된다.

| 계층 | 비유 | 보이는 방식 | 생존성 |
|---|---|---|---|
| **session** | 브라우저 **인스턴스** | 전환식 (detach/attach) | tmux 서버가 살아있는 한 영속 |
| **window** | session 내부의 **탭** | 한 번에 하나, `Ctrl-b n`으로 전환 | session에 종속 |
| **pane** | window 내부의 **분할 영역** | **동시 표시** | window에 종속 |
| **client** | session에 접속한 **터미널 창** | 여러 client가 동일 session 화면을 **미러링** | 터미널 창 닫으면 detach (session은 생존) |

### 계층 관계 도식

```
tmux server (OS 프로세스)
├── session "24"
│   ├── window 0
│   │   ├── pane 0 (작업)
│   │   └── pane 1 (flutter run)   ← 동시 표시
│   └── window 1 (optional)
│       └── pane 0 (DevTools)
├── session "other-project"
│   └── window 0 / pane 0
└── clients
    ├── ttys114 → attached to session "24"
    └── ttys115 → attached to session "24" (mirror)
```

**핵심 개념**: tmux 서버는 세션/창/판을 모두 server-side에서 관리한다. 터미널 에뮬레이터(Terminal.app, iTerm2)는 단지 client일 뿐이다. 그래서 Terminal.app을 완전히 종료해도 `tmux`는 백그라운드에서 살아 있고, 나중에 새 Terminal에서 `tmux attach -t 24`로 복귀하면 **작업 컨텍스트가 통째로 돌아온다**.

---

## 2. Terminal.app 탭 vs tmux window — 혼동 주의

`Cmd+T`로 생기는 macOS Terminal.app의 탭과 tmux의 window는 **이름만 같고 층위가 다르다**.

| 속성 | Terminal.app 탭 | tmux window |
|---|---|---|
| 관리 주체 | Terminal.app (GUI) | tmux 서버 |
| 생성 | `⌘ T` | `Ctrl-b c` |
| 전환 | `⌘ ⇧ ] / [` | `Ctrl-b n / p / 1..9` |
| 앱 종료 시 | 내부 프로세스 전부 종료 | tmux 서버가 살아 유지 |
| 원격(SSH)에서 쓸 수 있나 | 아니오 (로컬 GUI 전용) | 예 (서버 측 tmux) |
| pane 분할 지원 | 불가 (Apple Terminal 기준) | 가능 (`Ctrl-b %`, `Ctrl-b "`) |

**실전 구도**: Terminal.app 탭 하나에서 `tmux attach`로 세션에 붙고, 그 세션 안에서 tmux window/pane을 쓴다. Terminal 탭은 "어느 tmux 세션에 붙어 있느냐"의 컨테이너로만 활용.

### 그림으로 본 이중 구조

```
┌─────────── Terminal.app 윈도우 ────────────┐
│ 탭1: tmux(personality)  탭2: zsh      +   │  ← Terminal.app
├───────────────────┬────────────────────────┤
│  Claude 작업 pane │   flutter run pane     │
│                   │                        │  ← tmux pane split
│  (zsh 프롬프트)   │   Reloaded 0 libs...   │
├───────────────────┴────────────────────────┤
│ [24] 0:zsh- 1:flutter*                     │  ← tmux 상태바
└────────────────────────────────────────────┘
```

---

## 3. 시각 배치 3가지 모드

Flutter 로그를 **언제·어떻게 보이게 할지**는 배치에 따라 경험이 달라진다. 각 모드의 장단을 비교한다.

### 3.1. 동시 분할 (pane)

한 화면에 여러 pane이 동시에 표시된다. Claude가 send-keys로 `r`을 보내면 오른쪽 pane에서 `Performing hot reload...` 로그가 즉시 찍히는 걸 눈으로 확인 가능.

- **장점**: 실시간 관찰 최대. 키 → 반응 대응이 명확.
- **단점**: 공간을 분점. 코드 에디터가 좁게 보일 수 있음.
- **언제**: flutter run 로그를 항상 옆에 두고 싶을 때. 버그 조사·UI 반복 조정.
- **명령**: `tmux split-window -h` (좌우) / `tmux split-window -v` (상하)

### 3.2. 전환식 탭 (window)

한 세션 안에 여러 window가 있고, 상태바의 목록에서 하나씩 선택해 본다. Claude가 조작하는 순간은 "화면에 없을 수도" 있다.

- **장점**: 공간 독점. 각 window가 full-screen.
- **단점**: 실시간 관찰 불가 (전환 필요).
- **언제**: flutter 로그 외에 DevTools·logcat·서버 로그 등 여러 채널을 두고 필요 시에만 확인할 때.
- **명령**: `tmux new-window -n flutter` / `Ctrl-b n`으로 전환

### 3.3. 별도 세션 + client 미러링

tmux session은 하나 두고, **두 번째 Terminal.app 창/탭**에서 같은 세션에 `tmux attach -t 24`로 한 번 더 붙는다. 두 client가 같은 화면을 실시간 미러링한다.

- **장점**: 모니터 두 대 환경에 최적. 한 모니터는 Claude 조작용(입력), 다른 모니터는 관찰 전용(출력).
- **단점**: 기본 동작은 두 client가 **같은 window/pane을 공유**한다. 독립적으로 다른 창을 보고 싶으면 `tmux new-session -s mirror -t 24` 같은 **grouped session** 기법이 필요.
- **언제**: 듀얼 모니터가 있고, 관찰용 터미널을 "전체 화면"으로 띄우고 싶을 때.
- **명령**: 새 Terminal 탭/창 열고 `tmux attach -t 24`

### 선택 기준 정리

| 시나리오 | 추천 |
|---|---|
| Claude가 hot reload 반복, 로그 즉시 보고 싶음 | **pane split** |
| 한 모니터에서 에디터 위주, 로그는 가끔만 | **window** |
| 모니터 2대 이상, 한 쪽은 로그 전용 | **client 미러링** (grouped session 선택적) |
| 프로젝트 여러 개 동시 진행 | **session 다수** (프로젝트당 하나) |

---

## 4. 실전 단축키 (prefix = `Ctrl-b` 기본)

### Pane 계층

| 조작 | 키 |
|---|---|
| 좌우 분할 | `Ctrl-b %` |
| 상하 분할 | `Ctrl-b "` |
| 포커스 이동 | `Ctrl-b` + 방향키 |
| pane 확대/축소 토글 | `Ctrl-b z` |
| pane → 별도 window로 분리 | `Ctrl-b !` |
| pane 종료 | `exit` 또는 `Ctrl-b x` |
| pane 크기 수동 조정 | `Ctrl-b :resize-pane -R 10` |

### Window 계층

| 조작 | 키 |
|---|---|
| 새 window | `Ctrl-b c` |
| 이전/다음 window | `Ctrl-b p` / `Ctrl-b n` |
| 번호로 이동 | `Ctrl-b 1..9` |
| window 이름 변경 | `Ctrl-b ,` |
| window 종료 | `Ctrl-b &` |
| window 목록 선택 | `Ctrl-b w` |

### Session 계층

| 조작 | 키 |
|---|---|
| session 목록/선택 | `Ctrl-b s` |
| session 이름 변경 | `Ctrl-b $` |
| detach (세션은 살려두고 나가기) | `Ctrl-b d` |
| session 이동 (다음/이전) | `Ctrl-b (` / `Ctrl-b )` |

### Claude가 자주 쓰는 명령 (사용자가 직접 쓸 일은 적음)

```bash
tmux ls                               # 전체 session 목록
tmux list-clients                     # 현재 attach된 client
tmux list-windows -t <session>        # 특정 session의 window
tmux list-panes -t <session>:<window> # 특정 window의 pane
tmux send-keys -t <target> '<keys>'   # 원격 키 입력
tmux capture-pane -p -t <target>      # 출력 스냅샷
```

`<target>` 표기: `session:window.pane` 또는 `%pane_id`(예: `%75`).
**pane-id가 가장 안정적** — window/pane index는 사용자가 재배치하면 깨지지만 pane-id는 pane 수명 동안 불변.

---

## 5. Flutter 개발 관점 실전 패턴

### 5.1. 세션 준비 (최초 1회)

```bash
# 이름 있는 session 생성, working dir = 모노레포 루트
tmux new-session -s personality -c /Users/kampikrein/A/personality

# 또는 기존 session에 붙기
tmux attach -t personality
```

이름 없이 `tmux new-session`만 반복 실행하면 `0, 1, 2, …` 숫자가 쌓인다 (`[24]` 같은 세션 이름이 생기는 원인).

### 5.2. Claude에게 flutter run 관찰 구도로 띄우게 하기

Claude Code가 personality 프로젝트에서 `/flutter-dev tmux`를 실행하면:

1. 사용자가 attached된 session 자동 탐지
2. 현재 active window에 **pane split** (`-h` 좌우)
3. 새 pane에서 `flutter run -d <device>` 실행
4. pane-id(`%NN`)를 `mobile/tmp/.flutter_pane`에 저장

이후 `/flutter-dev reload`는 저장된 pane-id를 읽어 `tmux send-keys -t %NN 'r'`을 보낸다. 사용자는 오른쪽 pane에서 로그가 찍히는 걸 실시간으로 본다.

### 5.3. hot reload vs hot restart 언제 뭘 쓰나

| 변경 유형 | 필요한 명령 | 이유 |
|---|---|---|
| 위젯 트리, build() 반환값, 스타일 | `r` (hot reload) | 위젯 레벨 재빌드. state 보존. |
| `initState`, provider 초기값, 라우팅 초기 분기 | `R` (hot restart) | state 초기화 필요. reload로는 반영 안 됨. |
| native 코드 (android/, ios/) | flutter run 재기동 | Dart VM 밖 영역. cold start 필수. |
| `pubspec.yaml` 변경 | `flutter pub get` + restart | 패키지 해석 새로 함. |
| 외부에서 `adb install -r`로 APK 교체 | flutter run 재기동 | observatory 포트 무효화. "Connection refused" 발생. |

### 5.4. 자주 만나는 오류와 대응

| 증상 | 원인 | 대응 |
|---|---|---|
| `Error connecting to the service protocol: ... Connection refused` | adb port forwarding stale | `adb kill-server && adb start-server` 후 flutter run 재투입 |
| `tmux: no server running` on `send-keys` | tmux 서버 자체가 안 떠 있음 | `tmux new-session -d -s personality`로 먼저 서버 기동 |
| reload 눌러도 변경 미반영 | state 캐시 또는 reload로는 부족한 변경 | `R` (hot restart)로 승격 |
| pane이 자꾸 사라짐 | split-window 명령에 command를 직접 넣고 그게 종료되면 pane이 닫힘 | 명령 끝에 `; exec zsh`를 붙여 쉘로 복귀 |
| window를 linked하고 `select-window` 했더니 flutter 세션 자체가 사라짐 | tmux 3.6의 linked-window + select-window 거동 | **linked-window 금지**. `new-window -d` 또는 `split-window -d -h`만 사용. |

### 5.5. pane-id 찾는 법

```bash
# flutter run 돌고 있는 pane 찾기
tmux list-panes -a -F '#{pane_id} #{pane_current_command} #{pane_start_command}' \
  | awk '/flutter|dart/{print $1; exit}'
# 예: %75

# 파일에서 영속된 값 읽기
cat /Users/kampikrein/A/personality/mobile/tmp/.flutter_pane
```

---

## 6. 확인하기 쉬운 상태 점검 명령

```bash
# 어떤 session이 있고 누가 attached인가
tmux ls                              # 세션 목록 (attached 표시)
tmux list-clients                    # client별 어느 session에 붙어있는지

# 특정 session의 구조
tmux list-windows -t 24              # 24번 session의 window들
tmux list-panes -t 24 -a             # 24번 session의 모든 pane (-a: 전 window)

# 상태바가 꺼져 있어서 window 목록이 안 보이는지 확인
tmux show-options -g status          # "status on" 이어야 정상
```

상태바가 `status off`면 사용자 눈에 window 목록(탭)이 안 보인다. `tmux set -g status on`으로 켠다.

---

## 7. 되돌리기/청소

| 목적 | 명령 |
|---|---|
| 지금 pane을 별도 window로 승격 | `Ctrl-b !` (= `break-pane`) |
| 특정 pane 종료 | `exit` (내부에서) 또는 `tmux kill-pane -t %75` |
| 특정 window 종료 | `tmux kill-window -t 24:1` |
| 특정 session 종료 | `tmux kill-session -t 24` |
| 모든 세션 종료 | `tmux kill-server` (주의: 모든 작업 날림) |

`kill-server`는 파괴적이다. 보통은 개별 session/window/pane만 정리.

---

## 8. 더 알고 싶으면

- tmux 내장 help: prefix + `?` (= `Ctrl-b ?`) — 모든 키바인드 표시
- man page: `man tmux`
- tmux 공식 repo: github.com/tmux/tmux
- 이 프로젝트 스킬 문서: `.claude/skills/flutter-dev/SKILL.md` — Claude Code가 operational하게 쓰는 레퍼런스

---

## 부록. Claude가 이 문서를 갱신해야 하는 신호

- 스킬의 기본 모드(pane split vs window vs hidden session)가 바뀌었을 때
- tmux 3.x → 4.x처럼 메이저 버전이 바뀌어 거동이 바뀌었을 때
- 새로운 안티패턴/실수 사례가 확인됐을 때 (특히 5.4, 5.5 섹션)

본 가이드는 `/Users/kampikrein/A/personality/docs/guide/002_tmux_flutter_observation_guide.md` 에 저장되어 있다.
