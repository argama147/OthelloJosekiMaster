# 設計: 技術スタック選定

## 対象範囲

アプリ全体の技術スタックおよび外部サービス連携の選定理由を記録する。

## 関連仕様

- [docs/spec/game-flow.md](../spec/game-flow.md)

## プラットフォーム

- **対象OS**: Android
- **言語**: Kotlin
- **UI フレームワーク**: Jetpack Compose
- **アーキテクチャ**: Clean Architecture (3層: presentation / domain / data)

## UI

- 宣言的 UI により状態駆動の盤面描画が自然に書ける
- Material 3 でのテーマ対応が容易
- アニメーション API（`animateFloatAsState` 等）で石を裏返す演出を実装する

## 外部 API: Edax

着手の評価値算出に **Edax API** を使用する（エンジン詳細は [knowledge/joseki-glossary.md](../../knowledge/joseki-glossary.md#edax) 参照）。

- アプリは Edax API に局面を送り、各着手の評価値を取得する
- 取得した評価値を正誤照会画面に表示する

### API 連携の責務配置

| 層 | 責務 |
|---|---|
| `domain` | `EvaluationRepository` インターフェース定義、`EvaluateMovesUseCase` |
| `data` | `EvaluationRepositoryImpl`（Edax API HTTP クライアント） |
| `presentation` | ViewModel 経由で評価値を `UiState` に反映 |

## 依存ライブラリ（主要）

| カテゴリ | ライブラリ |
|---|---|
| DI | Hilt |
| 非同期 | Kotlin Coroutines + Flow |
| HTTP | Retrofit（Edax API 通信用） |
| 永続化 | Room（正解回数の保存） |
| テスト | JUnit5 + MockK + Turbine |
| Lint | ktlint / detekt |

## 設計判断

- **Compose 採用**: View システムより盤面の宣言的描画・アニメーションが記述しやすい
- **Edax API**: 独自評価ロジックを実装するより既存エンジンを利用するほうが精度・保守コストで優れる
- **Room**: 定石ごとの正解回数（再出題制御）はデバイスローカルに保持すれば十分

## 未決事項

- Edax API のエンドポイント仕様・認証方式の確認
- オフライン時（API 未到達）の UI フォールバック方針
