# Kotlin / Android コーディング規約

## 命名規約

- **クラス・オブジェクト**: PascalCase (`GameBoard`, `OthelloRepository`)
- **関数・変数**: camelCase (`placeStone`, `currentPlayer`)
- **定数**: UPPER_SNAKE_CASE (`MAX_BOARD_SIZE`)
- **Composable関数**: PascalCase (`BoardScreen`, `PlayerStatusCard`)
- **package**: 全て小文字 (`com.example.othello.domain.model`)

## 言語機能の使い方

- **null安全**: `!!` 禁止。`?.` / `?:` / `requireNotNull()` を使う
- **可視性**: 公開する必要のないシンボルは `private` または `internal` にする
- **`when` 式**: `enum` / `sealed class` 分岐では網羅性を活かす (`else` を不用意に書かない)
- **データクラス**: 値オブジェクトは `data class`、識別子付きエンティティは通常クラス
- **拡張関数**: 既存型に振る舞いを追加するときに使い、ユーティリティの static メソッド代替にしない

## Coroutines / Flow

- **構造化並行性**: `GlobalScope` 禁止。`viewModelScope` / `lifecycleScope` / 引数の `CoroutineScope` を使う
- **Dispatcher**: I/O は `Dispatchers.IO`、CPU重い処理は `Dispatchers.Default`、UI更新は呼び出し側に任せる
- **Flow**: UI 状態は `StateFlow`、イベントは `SharedFlow(replay=0)` を基本とする
- **例外**: コルーチン内の例外は握りつぶさない。`CoroutineExceptionHandler` か `try-catch` で明示的に扱う

## エラーハンドリング

- **Result型**: ドメイン層では `Result<T>` または独自 `sealed class` でエラー状態を表現
- **例外の型**: 業務エラーは独自例外 (`OthelloException` 等) を、システムエラーは標準例外をそのまま投げる
- **ログ**: `Log.e` ではなく Timber 等の抽象化されたロガーを使う (リリース時に無効化できる構成)

## 依存性注入 (Hilt)

- **コンストラクタインジェクション** を基本とする (フィールドインジェクションは Activity/Fragment のみ)
- **Module** は機能単位で分割 (`NetworkModule`, `DatabaseModule`, `RepositoryModule`)
- **Scope**: `@Singleton` は本当に1つで良いものに限定。それ以外は `@ViewModelScoped` 等を選ぶ

## インターフェース変更時の注意

- 関数シグネチャ・型・公開APIを変更する前に、**Grep で全呼び出し箇所を事前把握** する
- 同じパターンの問題が他にないか **横展開チェック** を行う
- テスト・Mockクラスへの影響が大きいので、逐次コンパイルエラー修正は避ける
