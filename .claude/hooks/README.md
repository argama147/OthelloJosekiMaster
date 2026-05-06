# .claude/hooks/ — プロセスゲート用 hook スクリプト

Claude Code の hook 機構を使い、プロジェクトの工程違反を **物理的に** ブロックする。
`.claude/settings.json` から `bash <path>` 経由で起動する想定 (実行権限不要)。

## hook 一覧

### `check-phase-gate.sh` (PreToolUse: Write/Edit/NotebookEdit)
`.claude/state/current_phase.txt` のフェーズと、編集対象パスの整合をチェックする。
- 整合: 通過
- 不整合: stderr にエラーを出して exit 2 (block)

| フェーズ      | 編集を許可するパス                              |
| ------------- | ----------------------------------------------- |
| `planning`    | `.claude/state/`, `docs/`, `knowledge/`         |
| `design`      | `docs/design/`, `docs/adr/`, `docs/process/`    |
| `impl`        | `*/src/main/`                                   |
| `test`        | `*/src/test/`, `*/src/androidTest/`             |
| `review/gate` | (編集不可)                                      |
| `pr`          | (編集不可、`gh pr create` のみ許可)             |

`.claude/agents/`, `.claude/skills/`, `.claude/rules/`, `.claude/hooks/`, `CLAUDE.md` 等のメタ設定ファイルは常に編集可能。

### `check-plan-approved.sh` (PreToolUse: Write/Edit/NotebookEdit)
`*/src/main/`, `*/src/test/`, `*/src/androidTest/` への編集時、`.claude/state/plan_approved.json` の存在を要求する。
- ファイルなし → block
- ファイルあり → 通過 (内容の妥当性は dev-manager が責任を持つ)

### `check-pr-gate.sh` (PreToolUse: Bash)
`gh pr create` を含む Bash コマンド実行時、品質ゲートの PASS を要求する。
- `quality_gate.json` が存在し、`passed: true` であること
- `plan_hash` が `plan_approved.json` と一致すること

## 動作確認

### 回帰テスト (推奨)

3つの hook を全フェーズ × 編集対象パスの組み合わせでまとめて検証する:

```bash
bash .claude/hooks/run-tests.sh
```

- 32+件のケースを自動実行し、PASS/FAIL を一覧表示する
- 開始前に `.claude/state/` を退避し、終了時に復元する (現在の作業状態を破壊しない)
- 終了コード: 0 = 全PASS / 1 = 1件以上FAIL

hook を変更したら必ず実行する。

### 単体での動作確認

```bash
# Phase が impl で src/test/ を編集しようとする例 (block されるはず)
echo '{"tool_name":"Write","tool_input":{"file_path":"app/src/test/Foo.kt"}}' \
  | bash .claude/hooks/check-phase-gate.sh
echo "exit: $?"
```

## hook が間違ってブロックする場合

- **緊急対応**: `.claude/settings.json` から該当 hook をコメントアウトして再起動
- **状態リセット**: `rm .claude/state/current_phase.txt` で hook が無効化される (ファイルがないと素通し)
- **正攻法**: dev-manager にフェーズ遷移を依頼

## 拡張のアイデア

- `SubagentStop` で各エージェント完了時に状態ファイルを更新
- `PostToolUse` で `gh pr create` 成功後に `.claude/state/` を初期化
- `Stop` (会話終了) で未完了タスクの警告

これらは記事の "12工程フル実装" に近づく方向だが、個人開発では不要なので導入していない。必要になったら追加する。
