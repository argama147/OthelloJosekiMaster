# テスト方針

## テストピラミッド

| レイヤー   | 比率目安 | 使うフレームワーク                          | 配置                |
| ---------- | -------- | ------------------------------------------- | ------------------- |
| Unit       | 70%      | JUnit5 + MockK + Turbine (Flow)             | `src/test/`         |
| Component  | 20%      | Robolectric + Hilt Test                     | `src/test/`         |
| UI / E2E   | 10%      | Compose UI Test + Espresso                  | `src/androidTest/`  |

## Unit テスト

### ドメイン層 (UseCase・Model)

- **モック不要のことが多い** (純粋関数・値オブジェクト)
- **テスト名**: `methodName_条件_期待結果` を日本語で書いてもよい
  ```kotlin
  @Test fun `placeStone_合法手の場合_盤面が更新される`() { ... }
  ```
- **Given-When-Then** の構造を明示する (コメント or 空行)
- **境界値**: 8x8 盤の角・端・中央など意味のある位置を網羅する

### ViewModel テスト

- **MainDispatcherRule** で `Dispatchers.Main` を `TestDispatcher` に置き換える
- **`runTest`** を使い、`advanceUntilIdle()` で完了を待つ
- **Flow の検証**: Turbine の `test { }` ブロックで購読する
  ```kotlin
  viewModel.uiState.test {
      assertEquals(UiState.Loading, awaitItem())
      assertEquals(UiState.Success(board), awaitItem())
  }
  ```

## UI テスト (Compose)

- **`createComposeRule()`** または `createAndroidComposeRule<MainActivity>()` を使う
- **`onNodeWithTag` / `onNodeWithText`** で要素を特定 (テストタグは `Modifier.testTag("board_cell_3_4")`)
- **Hilt 注入**: `@HiltAndroidTest` + テスト用 Module で実装を差し替える

## モック方針

- **MockK を優先** (Kotlin 親和性が高い)
- **Repository / DataSource** はインターフェースを介してモック化する
- **オーバーモック禁止**: 真の依存関係 (data class / 純粋関数) はモックせず実物を使う

## カバレッジ

- **JaCoCo** を導入し、ドメイン層は 80% 以上を目標
- **見えない分岐** (例外パス・空判定) も意識的にテストする

## テストデータ

- **テストフィクスチャ** は `src/test/kotlin/.../fixtures/` に置く
- **Builder パターン** で複雑なオブジェクトを生成する
  ```kotlin
  fun aBoard(currentPlayer: Stone = Stone.BLACK, ...): Board { ... }
  ```

## 落とし穴

- **`runBlocking` を本番コードで使わない** (テスト以外では `viewModelScope` 等を使う)
- **Compose のテストで `idleResource`** を待たないとフレーキー化する
- **時間依存テスト**: `Clock` インターフェースを注入して固定時刻を使う
