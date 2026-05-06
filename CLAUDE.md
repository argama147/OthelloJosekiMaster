# OthelloJosekiMaster — プロジェクト規約 (目次)

Androidアプリ「OthelloJosekiMaster」(オセロ定石マスター) の開発リポジトリ。
- GitHub: https://github.com/argama147/OthelloJosekiMaster
- ローカルパス: `/Users/argama147/claudework/OthelloAndroid/`

親ディレクトリの共通規約 (`/Users/argama147/claudework/CLAUDE.md`) を継承する。

> **このファイルは目次。詳細は各リンク先を参照すること。**
> 規範は `.claude/rules/`、知識は `knowledge/`、プロセスは `docs/process/` に分散している。

## 技術スタック

- Kotlin / Jetpack Compose / Material 3 / Clean Architecture (3層)
- Gradle (Kotlin DSL) + Version Catalog / Hilt / Coroutines+Flow
- JUnit5 + MockK + Turbine + Compose UI Test
- ktlint / detekt / Android Lint

## ディレクトリ構成

```
OthelloAndroid/
├── app/  domain/  data/        # 3モジュール (Clean Architecture)
├── docs/
│   ├── spec/        # 仕様 (What)
│   ├── design/      # 設計 (How)
│   ├── adr/         # 設計判断記録
│   └── process/     # 運用プロセス
├── knowledge/       # ドメイン知識 (オセロ・定石・参照資料)
├── .claude/
│   ├── agents/      # 作業フロー別エージェント
│   ├── rules/       # 自動ロード規約
│   ├── skills/      # 手動起動スキル
│   ├── hooks/       # プロセスゲート用 hook
│   ├── state/       # 作業状態 (gitignore)
│   └── settings.json
└── .github/workflows/    # CI/CD
```

## 自動ロードされるルール (規範)

- @.claude/rules/android-kotlin.md — Kotlin/Coroutines/Hilt
- @.claude/rules/jetpack-compose.md — Compose UI / 副作用
- @.claude/rules/clean-architecture.md — 3層の責務と依存方向
- @.claude/rules/testing.md — テスト方針
- @.claude/rules/git-trunk-based.md — ブランチ・コミット規約
- @.claude/rules/docs.md — spec/design/ADR テンプレート

## エージェント (責務分離)

| エージェント       | 責務                              | 編集対象                             |
| ------------------ | --------------------------------- | ------------------------------------ |
| **dev-manager**    | 計画策定・フェーズ遷移・品質ゲート | `.claude/state/`                     |
| **spec-writer**    | 仕様作成・修正                    | `docs/spec/`                         |
| **design-writer**  | 設計作成・修正                    | `docs/design/`, `docs/adr/`          |
| **android-impl**   | 実装専用 (テスト・設定は不可)     | `*/src/main/`                        |
| **test-writer**    | テスト作成・実行                  | `*/src/test/`, `*/src/androidTest/`  |
| **ux-checker**     | UI/UX 検証 (Read-only)            | (編集なし)                           |
| **code-reviewer**  | コードレビュー (Read-only)        | (編集なし)                           |
| **env-manager**    | Gradle/依存/CI管理                | `build.gradle.kts`, `gradle/`, `.github/workflows/` |

**重要**: 各エージェントは自分のスコープ外を編集しない。違反は hook で物理的にブロックされる。

## プロセスゲート (hook で強制)

`.claude/state/current_phase.txt` と `.claude/hooks/` で以下を強制:

| フェーズ      | 編集を許可するパス                              |
| ------------- | ----------------------------------------------- |
| `planning`    | `.claude/state/`, `docs/`, `knowledge/`         |
| `design`      | `docs/design/`, `docs/adr/`                     |
| `impl`        | `*/src/main/` (要 `plan_approved.json`)         |
| `test`        | `*/src/test/`, `*/src/androidTest/` (同上)      |
| `review/gate` | (編集禁止 — Read/Bashのみ)                      |
| `pr`          | (編集禁止、`gh pr create` 許可、要品質ゲートPASS)|

詳細は @.claude/hooks/README.md と @.claude/state/README.md

## 構成管理 (Trunk-based)

- main 直接マージ (短命ブランチ ≤2日)
- ブランチ名: `feat/` `fix/` `docs/` `chore/` `refactor/` `test/`
- Conventional Commits 準拠
- 詳細は @.claude/rules/git-trunk-based.md

## 標準ワークフロー

新機能追加時の流れ:
1. `create-spec-issue` (グローバルスキル) で仕様Issue作成
2. `spec-writer` で `docs/spec/<topic>.md` 作成
3. `design-writer` で `docs/design/<topic>.md` 作成
4. `dev-manager` で計画策定 → ユーザー承認 (`plan_approved.json` 発行)
5. `env-manager` で必要な依存追加 (あれば)
6. `android-impl` で `*/src/main/` 実装 (phase=impl)
7. `test-writer` で `*/src/test/` テスト追加 (phase=test)
8. `ux-checker` でUI/UX確認
9. `code-reviewer` でコードレビュー (phase=review)
10. `dev-manager` で品質ゲート判定 (phase=gate → pr)
11. `create-pr` (グローバルスキル) でPR作成

詳細は @.claude/skills/feature-workflow.md
