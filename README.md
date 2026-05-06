# OthelloJosekiMaster

オセロ序盤の定石をクイズ形式で練習する Android アプリ。  
虎定石・うさぎ定石などの名前付き定石について、局面を出題し最善手を選ぶ練習ができる。

- GitHub: https://github.com/argama147/OthelloJosekiMaster
- 対象: Android / Kotlin + Jetpack Compose

## ドキュメント

| 種類 | 場所 | 内容 |
|---|---|---|
| 仕様 | [docs/spec/](docs/spec/) | 機能要件・ユースケース |
| 設計 | [docs/design/](docs/design/) | 技術選定・モジュール構成 |
| ADR | [docs/adr/](docs/adr/) | 設計判断の記録 |
| ドメイン知識 | [knowledge/](knowledge/) | オセロルール・定石用語 |
| プロセス | [docs/process/](docs/process/) | 運用手順 |

主要ドキュメント:
- [ゲームフロー仕様](docs/spec/game-flow.md) — 出題・回答・正誤照会の仕様
- [技術スタック](docs/design/tech-stack.md) — プラットフォーム・ライブラリ選定

## ディレクトリ構成

```
OthelloAndroid/
├── app/           # presentation 層 (Compose UI + ViewModel)
├── domain/        # domain 層 (UseCase + Repository インターフェース)
├── data/          # data 層 (Repository 実装 + Room + Retrofit)
├── docs/
│   ├── spec/      # 仕様 (What)
│   ├── design/    # 設計 (How)
│   ├── adr/       # 設計判断記録
│   └── process/   # 運用プロセス
├── knowledge/     # ドメイン知識 (オセロルール・定石用語)
└── .claude/       # Claude Code 設定 (rules / hooks / state)
```

## 開発フロー

[Trunk-based development](.claude/rules/git-trunk-based.md) を採用。`main` が常にデプロイ可能な状態を維持する。

新機能追加は以下の順で進める（詳細: [.claude/skills/feature-workflow.md](.claude/skills/feature-workflow.md)）:

1. 仕様Issue作成 → 2. 仕様ドキュメント → 3. 設計ドキュメント → 4. 計画承認  
5. 実装 → 6. テスト → 7. UI/UX確認 → 8. コードレビュー → 9. PR作成

## ブランチ命名

| プレフィックス | 用途 |
|---|---|
| `feat/` | 新機能 |
| `fix/` | バグ修正 |
| `docs/` | ドキュメントのみ |
| `chore/` | ビルド・CI・依存更新 |
| `refactor/` | リファクタ |
| `test/` | テスト追加・修正 |

## ビルド

```bash
./gradlew assembleDebug
./gradlew test
./gradlew ktlintCheck
```
