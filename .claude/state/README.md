# .claude/state/ — プロセス状態管理

**重要**: このディレクトリのファイルは hook によるプロセスゲートで参照される。手動で書き換えるとゲートが正しく機能しなくなるので、原則 `dev-manager` エージェントとユーザー承認のみが書き込む。

## ファイル一覧

### `current_phase.txt`
現在のフェーズを1行で記録する。値は以下のいずれか:

| 値          | 編集を許可するパス                  | 用途                     |
| ----------- | ----------------------------------- | ------------------------ |
| `planning`  | `.claude/state/`, `docs/`           | 計画策定中               |
| `design`    | `docs/design/`, `docs/adr/`         | 設計ドキュメント作成中   |
| `impl`      | `*/src/main/`                       | 実装中                   |
| `test`      | `*/src/test/`, `*/src/androidTest/` | テスト作成中             |
| `review`    | (Read/Grep のみ)                    | レビュー中               |
| `gate`      | (Bash で build/test/lint のみ)      | 品質ゲート判定中         |
| `pr`        | (`gh pr create` 許可)               | PR作成可                 |

書き込みは `dev-manager` のみ。

### `current_plan.md`
現在の作業計画書。`dev-manager` が起こし、ユーザーが承認すれば `plan_approved.json` が発行される。
- 承認済み計画と異なる作業を行うときは、まず `dev-manager` で計画を更新する
- フォーマットは `dev-manager` エージェント定義のテンプレートに従う

### `plan_approved.json`
ユーザーによる計画承認の証跡。
- フォーマット例:
  ```json
  {
    "approved_at": "2026-05-06T10:00:00Z",
    "approved_by": "user",
    "plan_hash": "abc123..."
  }
  ```
- **このファイルが存在しないと、impl/test フェーズへの遷移が hook でブロックされる**
- ユーザーの明示的な yes 回答後にのみ作成する

### `quality_gate.json`
品質ゲートの判定結果。`dev-manager` が build/test/lint の実行結果から作る。
- フォーマット例:
  ```json
  {
    "checked_at": "2026-05-06T11:30:00Z",
    "build": "pass",
    "test": {"passed": 42, "failed": 0},
    "ktlint": "pass",
    "detekt": "pass",
    "lint": {"errors": 0, "warnings": 2},
    "passed": true,
    "plan_hash": "abc123..."
  }
  ```
- **`passed: true` でないと `gh pr create` が hook でブロックされる**
- `plan_hash` が `plan_approved.json` と一致しないと無効 (計画変更後の再ゲート要求)

## 状態のリセット

新しいタスクを始める時:
```bash
rm -f .claude/state/current_plan.md .claude/state/plan_approved.json .claude/state/quality_gate.json
echo "planning" > .claude/state/current_phase.txt
```

## .gitignore について

`current_plan.md`, `plan_approved.json`, `quality_gate.json`, `current_phase.txt` は **作業中の状態** であり、共有リポジトリにコミットしない。`.gitignore` で `.claude/state/*` (この README 除く) を除外する。
