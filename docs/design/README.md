# docs/design/ — 設計ドキュメント

「How」(どう実装するか・モジュール構成・API設計) を記述する。

- フォーマット: `.claude/rules/docs.md` のテンプレートに従う
- 作成・修正: `design-writer` エージェントに依頼するのが基本
- Mermaid 図 (classDiagram, sequenceDiagram, stateDiagram-v2) を活用

## ファイル命名

- `<topic>.md` (例: `architecture-overview.md`, `board-domain-model.md`)

## 関連

- 仕様: `docs/spec/<topic>.md` (必須先行)
- 設計判断 (Why this approach): `docs/adr/`
