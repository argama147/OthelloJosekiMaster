# docs/adr/ — Architecture Decision Records

設計判断のうち、後から「なぜこうしたか?」と問われそうなもののみ記録する。

- フォーマット: `.claude/rules/docs.md` のテンプレートに従う
- ファイル名: `NNNN-<slug>.md` (4桁連番、ケバブケース)
- 例: `0001-clean-architecture-3-layers.md`

## いつ書くか

- 主要なライブラリ選定 (例: Hilt vs Koin)
- アーキテクチャ層構成の選択
- 永続化方式の選択 (Room vs DataStore vs Preferences)
- 大きな後方互換性の判断

## いつ書かないか

- ❌ 細かなコーディング判断 (コードレビューで議論する)
- ❌ 一時的な妥協策 (TODO コメントで十分)
- ❌ 自明な選択 (ドキュメント化コストが上回る)

## ステータス

- `Proposed` → 提案中
- `Accepted` → 採用
- `Deprecated` → 廃止 (代替ADR を Superseded by で示す)
- `Superseded` → 別のADR で置き換えられた
