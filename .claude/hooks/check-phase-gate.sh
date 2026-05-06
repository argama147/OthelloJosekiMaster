#!/usr/bin/env bash
# PreToolUse hook: フェーズと編集対象パスの整合をチェックする
#
# 入力: stdin に Claude Code が JSON を渡す
#   { "tool_name": "Write|Edit", "tool_input": { "file_path": "...", ... } }
#
# 動作:
#   - .claude/state/current_phase.txt のフェーズと、編集対象パスが整合するか判定
#   - 整合しなければ stderr にエラーを出して exit 2 (block)
#   - 整合または対象外なら exit 0 (allow)
#
# フェーズ別の編集許可パス:
#   planning → .claude/state/, docs/, knowledge/, README.md
#   design   → docs/design/, docs/adr/, docs/process/
#   impl     → */src/main/
#   test     → */src/test/, */src/androidTest/
#   review   → (編集不可: Write/Edit ともブロック)
#   gate     → (編集不可)
#   pr       → (編集不可)

set -euo pipefail

REPO_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
STATE_FILE="$REPO_ROOT/.claude/state/current_phase.txt"

# 状態ファイルがなければ何もしない (初回セットアップ時など)
if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

PHASE=$(tr -d '[:space:]' < "$STATE_FILE")

# stdin から JSON を読む
INPUT=$(cat)

# tool_name と file_path を抽出 (jq があれば使い、なければ簡易パース)
if command -v jq >/dev/null 2>&1; then
  TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
  PATH_RAW=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
else
  TOOL=$(echo "$INPUT" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
  PATH_RAW=$(echo "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
fi

# Write / Edit / NotebookEdit 以外は対象外
case "$TOOL" in
  Write|Edit|NotebookEdit) ;;
  *) exit 0 ;;
esac

# パスが空 (Edit の old_string only など) はスキップ
if [[ -z "$PATH_RAW" ]]; then
  exit 0
fi

# 絶対パス化
if [[ "$PATH_RAW" == /* ]]; then
  ABS="$PATH_RAW"
else
  ABS="$REPO_ROOT/$PATH_RAW"
fi

# プロジェクト外のパスは対象外 (ホームの設定ファイル等)
case "$ABS" in
  "$REPO_ROOT"/*) ;;
  *) exit 0 ;;
esac

REL="${ABS#$REPO_ROOT/}"

# 常に許可するパス (エージェント・スキル・ルール定義の編集はメタなので許可)
case "$REL" in
  .claude/agents/*|.claude/skills/*|.claude/rules/*|.claude/hooks/*|.claude/settings*.json|CLAUDE.md|.gitignore|README.md)
    exit 0 ;;
esac

# プロセスゲート判定
block() {
  local reason="$1"
  cat >&2 <<EOF
[phase-gate] BLOCKED: $reason
  current_phase: $PHASE
  target: $REL

このフェーズで該当パスの編集は許可されていません。
- フェーズ遷移が必要なら dev-manager エージェントを呼んでください
- 計画外の作業なら現在のタスクをいったん完了してから新規計画を立ててください
EOF
  exit 2
}

case "$PHASE" in
  planning)
    case "$REL" in
      .claude/state/*|docs/*|knowledge/*) exit 0 ;;
      *) block "planning フェーズでは .claude/state/, docs/, knowledge/ のみ編集可" ;;
    esac
    ;;
  design)
    case "$REL" in
      docs/design/*|docs/adr/*|docs/process/*|.claude/state/*) exit 0 ;;
      *) block "design フェーズでは docs/design/, docs/adr/, docs/process/ のみ編集可" ;;
    esac
    ;;
  impl)
    case "$REL" in
      */src/main/*|app/src/main/*|domain/src/main/*|data/src/main/*) exit 0 ;;
      .claude/state/*) exit 0 ;;
      build.gradle.kts|settings.gradle.kts|gradle/libs.versions.toml|*/build.gradle.kts|gradle.properties|.github/workflows/*|config/*)
        block "ビルド/CI 設定の編集は env-manager に委譲してください (impl フェーズでは禁止)"
        ;;
      *)
        block "impl フェーズでは */src/main/ のみ編集可"
        ;;
    esac
    ;;
  test)
    case "$REL" in
      */src/test/*|*/src/androidTest/*|app/src/test/*|app/src/androidTest/*|domain/src/test/*|data/src/test/*)
        exit 0 ;;
      .claude/state/*) exit 0 ;;
      *) block "test フェーズでは */src/test/, */src/androidTest/ のみ編集可" ;;
    esac
    ;;
  review|gate)
    block "$PHASE フェーズでは編集禁止 (Read/Grep/Bash のみ)"
    ;;
  pr)
    case "$REL" in
      .claude/state/*) exit 0 ;;
      *) block "pr フェーズでは編集禁止 (gh pr create のみ許可)" ;;
    esac
    ;;
  *)
    # 未定義フェーズはとりあえず通す (誤設定でロックしないため)
    exit 0 ;;
esac
