# 機能開発ワークフロー (8エージェント連携 + プロセスゲート)

新機能追加時の標準フロー。**hook によるプロセスゲートで物理的に工程を強制する** ため、順序を飛ばすと block される。

## 全体像

```
[1] 仕様Issue作成 ─────→ create-spec-issue (skill)
[2] 仕様ドキュメント ──→ spec-writer (agent)         [phase=planning]
[3] 設計ドキュメント ──→ design-writer (agent)       [phase=design]
[4] 計画策定 + 承認 ───→ dev-manager (agent)         [planning→impl 遷移]
[5] 依存・設定変更 ───→ env-manager (agent)         (必要時のみ)
[6] 実装 ──────────────→ android-impl (agent)        [phase=impl]
[7] テスト追加 ────────→ test-writer (agent)         [phase=test]
[8] UI/UX確認 ────────→ ux-checker (agent)          [phase=test または review]
[9] 自己レビュー ──────→ code-reviewer (agent)       [phase=review]
[10] 品質ゲート判定 ──→ dev-manager (agent)         [phase=gate]
[11] PR作成 ───────────→ create-pr (skill)           [phase=pr]
```

## 各ステップの詳細

### [1] 仕様Issue作成
- グローバルスキル `create-spec-issue` を起動
- 出力: `[仕様]` プレフィックス + `spec` ラベル付きIssue
- 状態: `current_phase.txt = planning`

### [2] 仕様ドキュメント
- `spec-writer` エージェントを呼ぶ
- 出力: `docs/spec/<topic>.md`
- レビュー後、Issueに `docs/spec/...` リンクを追記

### [3] 設計ドキュメント
- `dev-manager` 経由で `current_phase.txt = design` に遷移
- `design-writer` エージェントを呼ぶ
- 出力: `docs/design/<topic>.md` (+ 必要なら ADR)

### [4] 計画策定 + ユーザー承認
- `dev-manager` エージェントを呼ぶ
- `dev-manager` が `.claude/state/current_plan.md` を起こす
- ユーザーに承認を AskUserQuestion で要求
- **yes 回答後のみ** `dev-manager` が `.claude/state/plan_approved.json` を発行
- `current_phase.txt = impl` に遷移

> 🔴 **重要**: `plan_approved.json` がないと、hook が `*/src/main/` への編集をブロックする

### [5] 依存・設定変更 (必要時のみ)
- 新規ライブラリ追加 / Compose BOM更新 / CI変更などが必要なら `env-manager` を呼ぶ
- env-manager は `current_phase.txt` の制約を受けない (hook で `.claude/agents/env-manager.md` 経由は通る前提だが、実際は env-manager 専用フェーズを設けない代わりに対象パスを Gradle/CI 系に限定)
- 完了後、ユーザーへバージョン差分と検証結果を報告

### [6] 実装
- `current_phase.txt = impl` の状態で `android-impl` を呼ぶ
- 入力: 設計ドキュメント + 計画書
- 出力: `*/src/main/` のコード
- android-impl は **テストファイルを書かない** (hook で test 配下への Write/Edit がブロックされる)

### [7] テスト追加
- `dev-manager` 経由で `current_phase.txt = test` に遷移
- `test-writer` エージェントを呼ぶ
- 出力: `*/src/test/`, `*/src/androidTest/` のテスト

### [8] UI/UX確認 (Composable変更時)
- `ux-checker` エージェントを呼ぶ (Read-only なのでフェーズ問わず実行可)
- 出力: Blocker / Major / Minor 分類のレポート
- Blocker があれば android-impl に戻して修正

### [9] 自己レビュー
- `dev-manager` 経由で `current_phase.txt = review` に遷移
- `code-reviewer` エージェントを呼ぶ
- 出力: 仕様/設計整合 + Clean Architecture違反 + Kotlin/Compose規約 + テスト の4観点レポート
- Blocker があれば該当エージェントに差し戻し

### [10] 品質ゲート判定
- `dev-manager` 経由で `current_phase.txt = gate` に遷移
- `dev-manager` が build/test/ktlint/detekt/lint を実行し、`.claude/state/quality_gate.json` を生成
- 全項目 PASS で `passed: true`
- PASS時のみ `current_phase.txt = pr` に遷移

> 🔴 **重要**: `quality_gate.json` の `passed: true` がないと、hook が `gh pr create` をブロックする

### [11] PR作成
- グローバルスキル `create-pr` を起動
- PR本文に関連 Issue 番号 (Closes #NN) と spec/design ドキュメントリンクを含める
- マージ後は `dev-manager` で状態リセット (state/* を削除し phase=planning に戻す)

## フェーズ遷移コマンド (dev-manager が実行)

```bash
# 各遷移は dev-manager が直前フェーズの完了条件を確認してから行う
echo "design"   > .claude/state/current_phase.txt
echo "impl"     > .claude/state/current_phase.txt
echo "test"     > .claude/state/current_phase.txt
echo "review"   > .claude/state/current_phase.txt
echo "gate"     > .claude/state/current_phase.txt
echo "pr"       > .claude/state/current_phase.txt
```

## 並行実行

以下は並行可能 (hookに干渉しない):
- 仕様作成中の **既存コード調査** をサブエージェントで
- 実装中の **テスト計画書き出し** を別agentで (実ファイル書き込みは test phase で)
- レビュー中の **次タスクの設計**

ただし Trunk-based なので、未完成機能はフィーチャーフラグで隔離。

## 進捗管理

- 仕様Issue (`spec` ラベル) → 設計完了で `design` ラベル追加 → 実装完了でクローズ
- PRと Issue は `Refs: #NN` または `Closes #NN` で紐付ける
- `gh issue list --label spec` で進行中の仕様を一覧

## 緊急対応 (hookで詰まった時)

- 状態リセット: `rm .claude/state/current_phase.txt` で hook が無効化される
- hook 一時停止: `.claude/settings.json` の `hooks` セクションをコメントアウト
- 詳細: `.claude/hooks/README.md`
