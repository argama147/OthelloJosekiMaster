# Spec → Design 引き継ぎスキル

仕様ドキュメントが固まった後、設計ドキュメント作成にスムーズに移行する。

## 手順

### 1. 仕様の確認

```bash
ls docs/spec/                               # 仕様ファイル一覧
gh issue list --label spec --state open     # オープンな仕様Issue
gh issue list --label spec --state closed --limit 10  # 直近確定した仕様
```

該当仕様ファイルを `Read` して、以下を確認する:
- ✅ ユースケース / シナリオが Given-When-Then で書かれている
- ✅ ルールが箇条書きで列挙されている
- ✅ スコープ外が明示されている
- ✅ TBDマーカーがない (あれば spec-writer に戻す)

### 2. 既存設計との整合確認

```bash
ls docs/design/                             # 既存設計
ls docs/adr/ 2>/dev/null                    # ADR (あれば)
```

新しい設計が既存と矛盾していないか、拡張で済むか作り直しかを判断する。

### 3. design-writer エージェントを起動

設計対象の仕様ファイルパスを渡してエージェントを呼ぶ。Agentツールで `subagent_type: design-writer` を指定する。

例:
```
docs/spec/board-rules.md の仕様に基づき、設計ドキュメント
docs/design/board-domain-model.md を起こしてください。
- 既存の docs/design/architecture-overview.md と整合させる
- Mermaid でクラス図とシーケンス図を含める
```

### 4. レビュー & 確定

設計案が出たら:
- 仕様の各ルールが設計でカバーされているかを目視チェック
- 未決事項リストをユーザーに提示し、判断を仰ぐ
- 設計確定後、対応Issueに `design` ラベルを付け、PR化を検討

### 5. 次フェーズへの引き継ぎ

設計確定後の選択肢:
- **android-impl**: 実装フェーズへ
- **test-writer**: テスト計画から先に着手 (TDD志向)
- **両方並行**: 実装とテストを別ブランチで進める (Trunk-based の短命PR運用)
