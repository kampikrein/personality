#!/usr/bin/env bash
#
# guard-file-boundary.sh — Write/Edit 도구의 file_path가 프로젝트 외부인지 검사
#
# PreToolUse hook: stdin으로 JSON 수신, 외부 경로면 permissionDecision:"ask" 출력
#

set -euo pipefail

# 프로젝트 루트 정규화
PROJECT_DIR="$(realpath "${CLAUDE_PROJECT_DIR:-.}")"

# stdin에서 JSON 읽기 → file_path 추출 (jq 미설치 환경 대응, Node.js 사용)
INPUT="$(cat)"
FILE_PATH="$(echo "$INPUT" | node -e "
  let d='';
  process.stdin.on('data',c=>d+=c);
  process.stdin.on('end',()=>{
    try {
      const o=JSON.parse(d);
      console.log(o.tool_input?.file_path || '');
    } catch(e) {
      console.log('');
    }
  });
")"

# file_path가 비어있으면 통과 (파싱 실패 또는 해당 필드 없음)
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# 경로 정규화 (미존재 경로도 처리)
CANONICAL_PATH="$(realpath --canonicalize-missing "$FILE_PATH")"

# 프로젝트 내부 경로인지 prefix 비교
if [[ "$CANONICAL_PATH" == "$PROJECT_DIR"/* || "$CANONICAL_PATH" == "$PROJECT_DIR" ]]; then
  # 내부 경로 → 통과
  exit 0
fi

# 외부 경로 → 사용자 확인 요청
echo '{"permissionDecision":"ask","message":"⚠️ 프로젝트 외부 파일 수정 감지: '"$CANONICAL_PATH"'"}'
