#!/usr/bin/env bash
# OthelloJosekiMaster — hook 回帰テスト
#
# プロセスゲート用 hook (check-phase-gate / check-plan-approved / check-pr-gate) が
# 期待通り動作するか、フェーズ × 編集対象の組み合わせでテストする。
#
# 使い方:
#   bash .claude/hooks/run-tests.sh
#
# 注意: テスト本体は別ファイル化している。コマンドラインに "gh pr create" 文字列が
# 含まれると check-pr-gate.sh がそれを拾って親プロセスをブロックするため。
#
# 終了コード:
#   0 — 全テスト PASS
#   1 — 1件以上 FAIL

set -uo pipefail

# スクリプト自身の位置からプロジェクトルートを推定 (.claude/hooks/ の2階層上)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"
export CLAUDE_PROJECT_DIR="$PROJECT_ROOT"

PHASE_HOOK=".claude/hooks/check-phase-gate.sh"
PLAN_HOOK=".claude/hooks/check-plan-approved.sh"
PR_HOOK=".claude/hooks/check-pr-gate.sh"

PASS=0
FAIL=0
FAILED_CASES=()

# 既存の状態を退避 (テスト後に復元)
STATE_BAK="$(mktemp -d)"
for f in current_phase.txt current_plan.md plan_approved.json quality_gate.json; do
  if [[ -f ".claude/state/$f" ]]; then
    cp ".claude/state/$f" "$STATE_BAK/$f"
  fi
done

restore_state() {
  rm -f .claude/state/current_phase.txt .claude/state/current_plan.md \
        .claude/state/plan_approved.json .claude/state/quality_gate.json
  for f in current_phase.txt current_plan.md plan_approved.json quality_gate.json; do
    if [[ -f "$STATE_BAK/$f" ]]; then
      cp "$STATE_BAK/$f" ".claude/state/$f"
    fi
  done
  rm -rf "$STATE_BAK"
}
trap restore_state EXIT

run() {
  local name="$1"; local hook="$2"; local input="$3"; local expected="$4"
  local actual_code
  actual_code=$(echo "$input" | bash "$hook" >/dev/null 2>&1; echo $?)
  local result
  if [[ "$actual_code" == "$expected" ]]; then
    result="PASS"; PASS=$((PASS+1))
  else
    result="FAIL"; FAIL=$((FAIL+1))
    FAILED_CASES+=("$name (expect=$expected actual=$actual_code)")
  fi
  printf "  %-55s expect=%s actual=%s [%s]\n" "$name" "$expected" "$actual_code" "$result"
}

write_in() { printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$1"; }
bash_in()  { printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$1"; }

# === Reset to fresh state ===
rm -f .claude/state/current_plan.md .claude/state/plan_approved.json .claude/state/quality_gate.json
echo "planning" > .claude/state/current_phase.txt

echo "============================================================"
echo "  PHASE: planning"
echo "============================================================"
run "docs/spec/foo.md → ALLOW"               "$PHASE_HOOK" "$(write_in docs/spec/foo.md)" 0
run "knowledge/foo.md → ALLOW"               "$PHASE_HOOK" "$(write_in knowledge/foo.md)" 0
run ".claude/state/current_plan.md → ALLOW"  "$PHASE_HOOK" "$(write_in .claude/state/current_plan.md)" 0
run "app/src/main/Foo.kt → BLOCK"            "$PHASE_HOOK" "$(write_in app/src/main/Foo.kt)" 2
run "build.gradle.kts → BLOCK"               "$PHASE_HOOK" "$(write_in build.gradle.kts)" 2

echo ""
echo "============================================================"
echo "  PHASE: design"
echo "============================================================"
echo "design" > .claude/state/current_phase.txt
run "docs/design/foo.md → ALLOW"             "$PHASE_HOOK" "$(write_in docs/design/foo.md)" 0
run "docs/adr/0001-foo.md → ALLOW"           "$PHASE_HOOK" "$(write_in docs/adr/0001-foo.md)" 0
run "docs/spec/foo.md → BLOCK"               "$PHASE_HOOK" "$(write_in docs/spec/foo.md)" 2
run "app/src/main/Foo.kt → BLOCK"            "$PHASE_HOOK" "$(write_in app/src/main/Foo.kt)" 2

echo ""
echo "============================================================"
echo "  Simulate plan creation + user approval"
echo "============================================================"
cat > .claude/state/current_plan.md <<'EOF'
# 実装計画: ドライラン用ダミー
ステップ:
1. domain層 Foo クラス追加
2. テスト追加
EOF
PLAN_HASH=$(shasum -a 256 .claude/state/current_plan.md | cut -d' ' -f1)
cat > .claude/state/plan_approved.json <<EOF
{"approved_at":"2026-05-06T10:00:00Z","approved_by":"user","plan_hash":"$PLAN_HASH"}
EOF
echo "  plan_hash = $PLAN_HASH"

echo ""
echo "============================================================"
echo "  PHASE: impl (with plan approved)"
echo "============================================================"
echo "impl" > .claude/state/current_phase.txt
run "src/main/ phase-gate → ALLOW"           "$PHASE_HOOK" "$(write_in app/src/main/Foo.kt)" 0
run "src/main/ plan-approval → ALLOW"        "$PLAN_HOOK"  "$(write_in app/src/main/Foo.kt)" 0
run "src/test/ phase-gate → BLOCK"           "$PHASE_HOOK" "$(write_in app/src/test/FooTest.kt)" 2
run "build.gradle.kts → BLOCK (env-mgr only)" "$PHASE_HOOK" "$(write_in build.gradle.kts)" 2
run "gradle/libs.versions.toml → BLOCK"      "$PHASE_HOOK" "$(write_in gradle/libs.versions.toml)" 2
run ".github/workflows/ci.yml → BLOCK"       "$PHASE_HOOK" "$(write_in .github/workflows/ci.yml)" 2
run "docs/spec/foo.md → BLOCK"               "$PHASE_HOOK" "$(write_in docs/spec/foo.md)" 2

echo ""
echo "----- impl WITHOUT plan_approved.json -----"
mv .claude/state/plan_approved.json .claude/state/plan_approved.json.bak
run "src/main/ no-approval → BLOCK"          "$PLAN_HOOK"  "$(write_in app/src/main/Foo.kt)" 2
mv .claude/state/plan_approved.json.bak .claude/state/plan_approved.json

echo ""
echo "============================================================"
echo "  PHASE: test"
echo "============================================================"
echo "test" > .claude/state/current_phase.txt
run "src/test/ phase-gate → ALLOW"           "$PHASE_HOOK" "$(write_in app/src/test/FooTest.kt)" 0
run "src/androidTest/ → ALLOW"               "$PHASE_HOOK" "$(write_in app/src/androidTest/UiTest.kt)" 0
run "src/test/ plan-approval → ALLOW"        "$PLAN_HOOK"  "$(write_in app/src/test/FooTest.kt)" 0
run "src/main/ → BLOCK"                      "$PHASE_HOOK" "$(write_in app/src/main/Foo.kt)" 2
run "docs/spec/foo.md → BLOCK"               "$PHASE_HOOK" "$(write_in docs/spec/foo.md)" 2

echo ""
echo "============================================================"
echo "  PHASE: review (read-only)"
echo "============================================================"
echo "review" > .claude/state/current_phase.txt
run "src/main/ → BLOCK"                      "$PHASE_HOOK" "$(write_in app/src/main/Foo.kt)" 2
run "src/test/ → BLOCK"                      "$PHASE_HOOK" "$(write_in app/src/test/FooTest.kt)" 2
run "docs/design/foo.md → BLOCK"             "$PHASE_HOOK" "$(write_in docs/design/foo.md)" 2

echo ""
echo "============================================================"
echo "  PHASE: pr — without quality gate"
echo "============================================================"
echo "pr" > .claude/state/current_phase.txt
PR_CMD="gh pr create --title test"
run "pr-gate (no gate file) → BLOCK"         "$PR_HOOK"    "$(bash_in "$PR_CMD")" 2
run "pr-gate (./gradlew test) → ALLOW"       "$PR_HOOK"    "$(bash_in './gradlew test')" 0

echo ""
echo "============================================================"
echo "  Simulate quality gate PASS"
echo "============================================================"
cat > .claude/state/quality_gate.json <<EOF
{"checked_at":"2026-05-06T11:30:00Z","build":"pass","test":{"passed":42,"failed":0},"ktlint":"pass","detekt":"pass","lint":{"errors":0,"warnings":0},"passed":true,"plan_hash":"$PLAN_HASH"}
EOF

echo ""
echo "============================================================"
echo "  PHASE: pr — with quality gate PASS"
echo "============================================================"
run "pr-gate (gate PASS) → ALLOW"            "$PR_HOOK"    "$(bash_in "$PR_CMD")" 0

echo ""
echo "----- after plan edit (hash mismatch) -----"
echo "# modified plan" >> .claude/state/current_plan.md
run "pr-gate (plan modified after gate) → BLOCK"  "$PR_HOOK" "$(bash_in "$PR_CMD")" 2

echo ""
echo "============================================================"
echo "  Meta-edit (always allowed regardless of phase)"
echo "============================================================"
echo "review" > .claude/state/current_phase.txt
run ".claude/agents/foo.md → ALLOW"          "$PHASE_HOOK" "$(write_in .claude/agents/foo.md)" 0
run ".claude/rules/foo.md → ALLOW"           "$PHASE_HOOK" "$(write_in .claude/rules/foo.md)" 0
run "CLAUDE.md → ALLOW"                      "$PHASE_HOOK" "$(write_in CLAUDE.md)" 0

echo ""
echo "============================================================"
echo "  RESULT: ${PASS} passed, ${FAIL} failed"
echo "============================================================"

if (( FAIL > 0 )); then
  echo ""
  echo "FAILED CASES:"
  for c in "${FAILED_CASES[@]}"; do
    echo "  - $c"
  done
fi

[[ $FAIL -eq 0 ]]
