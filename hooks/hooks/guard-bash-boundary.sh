#!/usr/bin/env bash
#
# guard-bash-boundary.sh — Bash 도구의 명령어가 프로젝트 외부를 수정하는지 검사
#
# PreToolUse hook: stdin으로 JSON 수신, 외부 수정 감지 시 permissionDecision:"ask" 출력
#

set -euo pipefail

# 프로젝트 루트 정규화
PROJECT_DIR="$(realpath "${CLAUDE_PROJECT_DIR:-.}")"

# stdin에서 JSON 읽기 → command 추출
INPUT="$(cat)"
COMMAND="$(echo "$INPUT" | node -e "
  let d='';
  process.stdin.on('data',c=>d+=c);
  process.stdin.on('end',()=>{
    try {
      const o=JSON.parse(d);
      console.log(o.tool_input?.command || '');
    } catch(e) {
      console.log('');
    }
  });
")"

# command가 비어있으면 통과
if [ -z "$COMMAND" ]; then
  exit 0
fi

# ─── 읽기 전용 명령어 판별 ───
# 화이트리스트 기반: 모든 서브커맨드가 읽기 전용이면 return 0
# 판단 불가 시 return 1 (안전 측 — 수정 가능으로 간주하여 추가 검사 진행)

# 읽기 전용 명령어 화이트리스트 (단순 명령어)
READONLY_CMDS="cat|head|tail|less|more|ls|dir|tree|find|stat|file|wc|du|df|free"
READONLY_CMDS="$READONLY_CMDS|grep|rg|egrep|fgrep|ag|ack|sed -n|awk"
READONLY_CMDS="$READONLY_CMDS|echo|printf|true|false|test|\\[|date|whoami|hostname|uname|uptime|id|env|printenv"
READONLY_CMDS="$READONLY_CMDS|which|type|whereis|command|hash"
READONLY_CMDS="$READONLY_CMDS|sort|uniq|cut|tr|paste|column|fmt|fold|expand|unexpand|nl|tac|rev|shuf"
READONLY_CMDS="$READONLY_CMDS|diff|cmp|comm|md5sum|sha256sum|sha1sum|cksum|sum"
READONLY_CMDS="$READONLY_CMDS|xargs|basename|dirname|realpath|readlink|pwd|nproc"
READONLY_CMDS="$READONLY_CMDS|jq|yq|node|python3?|ruby|perl"
READONLY_CMDS="$READONLY_CMDS|ps|top|htop|pgrep|lsof|ss|netstat|nslookup|dig|ping|traceroute|curl|wget"
READONLY_CMDS="$READONLY_CMDS|npm run|npx|npm list|npm ls|npm view|npm info|npm outdated|npm audit"

# git 읽기 전용 서브커맨드 화이트리스트
GIT_READONLY_SUBCMDS="log|diff|status|show|branch|tag|describe|shortlog|blame|annotate|reflog|stash list|remote|fetch|ls-files|ls-tree|ls-remote|cat-file|rev-parse|rev-list|name-rev|config --get|config --list|config -l"

is_single_cmd_readonly() {
  local subcmd="$1"

  # 앞뒤 공백 제거
  subcmd="$(echo "$subcmd" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')"
  [ -z "$subcmd" ] && return 0  # 빈 명령어는 안전

  # 첫 번째 토큰 추출
  local first_token
  first_token="$(echo "$subcmd" | awk '{print $1}')"

  # git 명령어 — 서브커맨드까지 검사
  if [ "$first_token" = "git" ]; then
    local git_subcmd
    git_subcmd="$(echo "$subcmd" | awk '{print $2}')"
    [ -z "$git_subcmd" ] && return 0  # bare 'git'은 안전
    if echo "$git_subcmd" | grep -qEw "$GIT_READONLY_SUBCMDS"; then
      return 0  # 읽기 전용 git 서브커맨드
    fi
    return 1  # git add, git commit, git push 등 → 수정 가능
  fi

  # 일반 명령어 — 화이트리스트 매칭
  if echo "$first_token" | grep -qEw "$READONLY_CMDS"; then
    return 0
  fi

  return 1  # 화이트리스트에 없음 → 수정 가능으로 간주
}

is_read_only_command() {
  local cmd="$1"

  # 체인 연산자(;, &&, ||)로 분리된 각 세그먼트를 검사
  # 각 세그먼트 내에서 파이프(|)로 연결된 모든 명령어를 검사
  local segment
  while IFS= read -r segment; do
    segment="$(echo "$segment" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')"
    [ -z "$segment" ] && continue

    # 리다이렉트(>, >>)가 있으면 읽기 전용이 아님
    if echo "$segment" | grep -qP '>{1,2}\s*\S'; then
      return 1
    fi

    # 파이프라인의 각 명령어를 검사
    local pipe_cmd
    while IFS= read -r pipe_cmd; do
      pipe_cmd="$(echo "$pipe_cmd" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')"
      [ -z "$pipe_cmd" ] && continue
      if ! is_single_cmd_readonly "$pipe_cmd"; then
        return 1  # 하나라도 수정 가능이면 전체가 수정 가능
      fi
    done < <(echo "$segment" | tr '|' '\n')
  done < <(echo "$cmd" | tr ';' '\n' | sed 's/&&/\n/g; s/||/\n/g')

  return 0  # 모든 명령어가 읽기 전용
}

# 읽기 전용 명령어면 무조건 허용
if is_read_only_command "$COMMAND"; then
  exit 0
fi

# ─── 경로가 외부인지 검사하는 헬퍼 ───
is_outside_project() {
  local path="$1"

  # 빈 문자열이면 내부로 간주
  [ -z "$path" ] && return 1

  # 상대경로면 프로젝트 루트 기준으로 해석
  if [[ "$path" != /* ]]; then
    path="$PROJECT_DIR/$path"
  fi

  local canonical
  canonical="$(realpath --canonicalize-missing "$path")"

  if [[ "$canonical" == "$PROJECT_DIR"/* || "$canonical" == "$PROJECT_DIR" ]]; then
    return 1  # 내부
  fi
  return 0  # 외부
}

# ─── 파일 수정 명령어의 대상 경로 검사 ───
# 수정 가능 명령어 패턴: rm, mv, cp, mkdir, rmdir, chmod, chown, touch, ln
MODIFY_CMDS='rm|mv|cp|mkdir|rmdir|chmod|chown|touch|ln'

# 명령어에서 수정 대상 경로 추출 및 검사
# 각 토큰을 분석하여 수정 명령어의 인자(경로)를 검사
check_modify_commands() {
  local cmd="$1"

  # 수정 명령어가 포함되어 있는지 빠른 체크
  if ! echo "$cmd" | grep -qEw "$MODIFY_CMDS"; then
    return 1  # 수정 명령어 없음
  fi

  # 수정 명령어의 경로 인자를 추출하여 외부 여부 검사
  # 간단한 접근: 명령어 뒤의 경로처럼 보이는 토큰들을 검사
  local found_outside=false

  # 각 세미콜론/&&/|| 로 분리된 서브커맨드를 검사
  while IFS= read -r subcmd; do
    # 앞뒤 공백 제거
    subcmd="$(echo "$subcmd" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')"
    [ -z "$subcmd" ] && continue

    # 첫 번째 토큰 추출
    local first_token
    first_token="$(echo "$subcmd" | awk '{print $1}')"

    # 수정 명령어인지 확인
    if echo "$first_token" | grep -qEw "$MODIFY_CMDS"; then
      # 나머지 토큰(경로 인자) 검사 — 옵션 플래그(-로 시작) 제외
      local args
      args="$(echo "$subcmd" | awk '{for(i=2;i<=NF;i++) print $i}')"
      while IFS= read -r arg; do
        [ -z "$arg" ] && continue
        # 옵션 플래그 스킵
        [[ "$arg" == -* ]] && continue
        # 경로로 간주하여 외부 검사
        if is_outside_project "$arg"; then
          found_outside=true
          break
        fi
      done <<< "$args"
    fi

    $found_outside && break
  done < <(echo "$cmd" | tr ';&' '\n' | sed 's/&&/\n/g; s/||/\n/g')

  $found_outside && return 0 || return 1
}

# ─── 리다이렉트 대상 검사 ───
check_redirects() {
  local cmd="$1"

  # > 또는 >> 뒤의 경로 추출
  local redirect_targets
  redirect_targets="$(echo "$cmd" | grep -oP '>{1,2}\s*\K[^\s;|&]+' 2>/dev/null || true)"

  while IFS= read -r target; do
    [ -z "$target" ] && continue
    if is_outside_project "$target"; then
      return 0  # 외부
    fi
  done <<< "$redirect_targets"

  # tee 명령어의 대상 검사
  local tee_targets
  tee_targets="$(echo "$cmd" | grep -oP '\btee\s+(-a\s+)?\K[^\s;|&]+' 2>/dev/null || true)"

  while IFS= read -r target; do
    [ -z "$target" ] && continue
    if is_outside_project "$target"; then
      return 0  # 외부
    fi
  done <<< "$tee_targets"

  return 1  # 내부만
}

# ─── 글로벌 설치 검사 ───
check_global_install() {
  local cmd="$1"

  # npm install -g / npm i -g
  if echo "$cmd" | grep -qP '\bnpm\s+(install|i)\s+(-g|--global)'; then
    return 0
  fi
  # pip install (without --user or venv context)
  if echo "$cmd" | grep -qP '\bpip3?\s+install\b' && ! echo "$cmd" | grep -qP '--user|--target|venv'; then
    return 0
  fi

  return 1
}

# ─── 메인 검사 실행 ───
REASON=""

if check_modify_commands "$COMMAND"; then
  REASON="파일 수정 명령어가 프로젝트 외부 경로를 대상으로 합니다"
elif check_redirects "$COMMAND"; then
  REASON="출력 리다이렉트가 프로젝트 외부 경로를 대상으로 합니다"
elif check_global_install "$COMMAND"; then
  REASON="글로벌 패키지 설치가 감지되었습니다"
fi

if [ -n "$REASON" ]; then
  echo '{"permissionDecision":"ask","message":"⚠️ '"$REASON"': '"$(echo "$COMMAND" | head -c 200)"'"}'
  exit 0
fi

# 문제 없음 → 통과
exit 0
