#!/usr/bin/env bash
# PreToolUse hook: gh pr create を実行する前に品質ゲート PASS を要求
#
# 動作: Bash ツールで gh pr create を実行しようとした時、
#   .claude/state/quality_gate.json の passed=true と
#   plan_hash の整合を確認。NG ならブロック。

set -euo pipefail

REPO_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
GATE_FILE="$REPO_ROOT/.claude/state/quality_gate.json"
PLAN_FILE="$REPO_ROOT/.claude/state/current_plan.md"
APPROVAL_FILE="$REPO_ROOT/.claude/state/plan_approved.json"

INPUT=$(cat)

if command -v jq >/dev/null 2>&1; then
  TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
  CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
else
  TOOL=$(echo "$INPUT" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
  CMD=$(echo "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)"[[:space:]]*}.*/\1/p')
fi

# Bash ツール以外は対象外
[[ "$TOOL" == "Bash" ]] || exit 0

# gh pr create が含まれない場合は対象外
echo "$CMD" | grep -qE '(^|[[:space:];&|])gh[[:space:]]+pr[[:space:]]+create' || exit 0

block() {
  cat >&2 <<EOF
[pr-gate] BLOCKED: $1

PR作成前に品質ゲートを通過する必要があります。
- dev-manager エージェントを呼び、現在のフェーズを 'gate' に進めて
  build / test / ktlint / detekt / lint を実行させてください
- 全項目 PASS で .claude/state/quality_gate.json が passed:true になります
- その後 'pr' フェーズに遷移してから gh pr create を実行できます
EOF
  exit 2
}

[[ -f "$PLAN_FILE" ]] || block "current_plan.md がありません"
[[ -f "$APPROVAL_FILE" ]] || block "plan_approved.json がありません"
[[ -f "$GATE_FILE" ]] || block "quality_gate.json がありません (品質ゲート未実行)"

if command -v jq >/dev/null 2>&1; then
  PASSED=$(jq -r '.passed' "$GATE_FILE")
  GATE_HASH=$(jq -r '.plan_hash' "$GATE_FILE")
  APPROVED_HASH=$(jq -r '.plan_hash' "$APPROVAL_FILE")
else
  PASSED=$(grep -o '"passed"[[:space:]]*:[[:space:]]*[a-z]*' "$GATE_FILE" | awk -F: '{gsub(/[[:space:]]/,""); print $2}')
  GATE_HASH=$(grep -o '"plan_hash"[[:space:]]*:[[:space:]]*"[^"]*"' "$GATE_FILE" | sed 's/.*"\([^"]*\)"$/\1/')
  APPROVED_HASH=$(grep -o '"plan_hash"[[:space:]]*:[[:space:]]*"[^"]*"' "$APPROVAL_FILE" | sed 's/.*"\([^"]*\)"$/\1/')
fi

[[ "$PASSED" == "true" ]] || block "品質ゲート未PASS (passed=$PASSED)"

# 現在の plan の hash を計算し、approval / gate と一致するか検証
CURRENT_HASH=$(shasum -a 256 "$PLAN_FILE" | cut -d' ' -f1)

if [[ -n "$GATE_HASH" && -n "$APPROVED_HASH" && "$GATE_HASH" != "$APPROVED_HASH" ]]; then
  block "計画ハッシュが不一致 (gate=$GATE_HASH, approved=$APPROVED_HASH) — 計画変更後の再承認・再ゲート要"
fi

if [[ -n "$APPROVED_HASH" && "$CURRENT_HASH" != "$APPROVED_HASH" ]]; then
  block "計画が承認後に変更された (current=$CURRENT_HASH, approved=$APPROVED_HASH) — 再承認要"
fi

if [[ -n "$GATE_HASH" && "$CURRENT_HASH" != "$GATE_HASH" ]]; then
  block "計画が品質ゲート判定後に変更された (current=$CURRENT_HASH, gate=$GATE_HASH) — 再ゲート要"
fi

exit 0
