# Trunk-based 開発フロー

## 基本ルール

- **`main` が常にデプロイ可能な状態** を維持する
- **短命ブランチ (≤2日)** で `main` に直接マージする
- **大きい機能はフィーチャーフラグ** で段階導入する (未完了でも main にマージ可能)
- **release ブランチ・develop ブランチは作らない**

## ブランチ命名

| プレフィックス | 用途                        | 例                          |
| -------------- | --------------------------- | --------------------------- |
| `feat/`        | 新機能                      | `feat/board-rendering`      |
| `fix/`         | バグ修正                    | `fix/illegal-move-crash`    |
| `docs/`        | ドキュメントのみ            | `docs/spec-board-rules`     |
| `chore/`       | ビルド・CI・依存更新        | `chore/upgrade-compose-bom` |
| `refactor/`    | 振る舞いを変えないリファクタ| `refactor/extract-usecase`  |
| `test/`        | テスト追加・修正のみ        | `test/board-edge-cases`     |

## コミットメッセージ

**Conventional Commits** に準拠:

```
<type>(<scope>): <subject>

<body>

<footer>
```

例:
```
feat(board): 8x8 盤面の初期配置を実装

中央4マスに白黒2個ずつ初期石を配置する処理を追加。
ドメインモデル Board に reset() メソッドを生やした。

Refs: #12
```

`type` は `feat` / `fix` / `docs` / `style` / `refactor` / `test` / `chore` を使う。

## PR運用

- **小さく分ける**: 1 PR = 1 関心事 (差分は ~400 行以内を目標)
- **PR タイトル**: コミットメッセージと同じ Conventional Commits 形式
- **PR本文**: `## Summary` + `## Test plan` を必ず書く (create-pr スキル参照)
- **CI グリーン必須**: build / test / lint が通ってからマージ
- **レビュー**: code-reviewer エージェントで事前自己レビュー → 人間レビュー

## マージ戦略

- **Squash and merge** を基本とする (main の履歴を線形に保つ)
- **マージ後は即ブランチ削除** (リモート・ローカル両方)
- **revert は revert コミットで** (force push しない)

## フィーチャーフラグ

- 未完成機能を main にマージする際は `BuildConfig.ENABLE_<FEATURE>` 等で切る
- フラグ削除はリリース後に別 PR で行う

## 禁止事項

- ❌ `main` への force push (運用ミス時は revert を作る)
- ❌ レビュー無しの直接マージ (例外: typo 修正は author 自身で merge 可)
- ❌ `--no-verify` でフックスキップ (失敗時は原因を直す)
