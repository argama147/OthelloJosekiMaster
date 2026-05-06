# docs/spec/ — 仕様ドキュメント

ユーザー視点での「何をするか・どう振る舞うか」を記述する。

- フォーマット: `.claude/rules/docs.md` のテンプレートに従う
- 作成・修正: `spec-writer` エージェントに依頼するのが基本
- 1機能 = 1ファイル を目安に

## ファイル命名

- `<topic>.md` (例: `board-rules.md`, `joseki-display.md`)
- 関連グループは prefix で揃える (例: `joseki-*.md`)

## 関連

- 設計: `docs/design/<topic>.md`
- 設計判断: `docs/adr/`
- ドメイン知識: `knowledge/`
