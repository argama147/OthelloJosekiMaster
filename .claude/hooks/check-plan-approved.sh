#!/usr/bin/env bash
# PreToolUse hook: impl/test フェーズへの遷移時に計画承認を要求
#
# 動作: 編集対象が */src/main/, */src/test/, */src/androidTest/ なら
#   .claude/state/plan_approved.json の存在を確認。なければブロック。

set -euo pipefail

REPO_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
APPROVAL_FILE="$REPO_ROOT/.claude/state/plan_approved.json"

INPUT=$(cat)

if command -v jq >/dev/null 2>&1; then
  TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
  PATH_RAW=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
else
  TOOL=$(echo "$INPUT" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
  PATH_RAW=$(echo "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
fi

case "$TOOL" in
  Write|Edit|NotebookEdit) ;;
  *) exit 0 ;;
esac

if [[ -z "$PATH_RAW" ]]; then
  exit 0
fi

if [[ "$PATH_RAW" == /* ]]; then
  ABS="$PATH_RAW"
else
  ABS="$REPO_ROOT/$PATH_RAW"
fi

REL="${ABS#$REPO_ROOT/}"

# src/main または src/test 配下のみ計画承認を要求
case "$REL" in
  */src/main/*|*/src/test/*|*/src/androidTest/*) ;;
  *) exit 0 ;;
esac

if [[ ! -f "$APPROVAL_FILE" ]]; then
  cat >&2 <<EOF
[plan-approval] BLOCKED: 計画が未承認です
  target: $REL
  required: .claude/state/plan_approved.json

src/main/, src/test/, src/androidTest/ の編集には計画承認が必要です。
1. dev-manager エージェントで実装計画を起こす
2. ユーザーに承認を求める
3. 承認後、dev-manager が plan_approved.json を発行する
EOF
  exit 2
fi

exit 0
