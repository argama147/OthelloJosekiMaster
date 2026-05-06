# Jetpack Compose ルール

## Composable 関数

- **副作用は LaunchedEffect / DisposableEffect / SideEffect で扱う**
  - Composable 関数本体の中で直接 I/O や状態変更をしない
- **State Hoisting** を徹底する — Composable は値と `onChange` ラムダを受け取り、自身では `mutableStateOf` を持たないのが基本
- **再描画コスト**: 重い計算は `remember` / `derivedStateOf` でメモ化する
- **`remember(key1, key2)` のキー指定漏れ** に注意。引数依存の値はキーに含める
- **Modifier 順序**: `padding` → `background` → `clickable` の順序が結果に影響することを意識する
- **Preview**: 主要 Composable には `@Preview` を付け、Light/Dark 両対応を確認する

## 状態管理

- **UIState は data class で集約** する (`BoardScreenUiState(board, currentPlayer, isLoading, error)`)
- **ViewModel** が `StateFlow<UiState>` を公開し、Composable は `collectAsStateWithLifecycle()` で購読する
- **イベント** (1回限りの通知 = SnackBar表示等) は `SharedFlow` または `Channel` を使う
- **画面回転を含めた状態保持**: `rememberSaveable` または `SavedStateHandle` を使う

## ナビゲーション

- **Navigation Compose** を使い、ルートは `sealed class Route` で型安全に表現する
- **画面間引数**: `Bundle` よりも navigation-compose の typed arguments を使う

## テーマ・スタイル

- **MaterialTheme.colorScheme** から色を取得 (ハードコードのColor禁止)
- **MaterialTheme.typography** からテキストスタイルを取得
- **dp/sp** の値は `theme/Dimens.kt` 等に集約することを検討する

## アクセシビリティ

- **`Modifier.semantics`** で contentDescription を設定する (画像・アイコン)
- **タッチターゲットは 48dp 以上** を確保する
- **コントラスト** はテーマカラーが Material 推奨を満たしているか確認する
