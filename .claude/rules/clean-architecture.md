# Clean Architecture (3層構成)

## 層構造と依存方向

```
presentation  →  domain  ←  data
   (app)         (純粋)      (実装)
```

**ルール**: 依存は常に `domain` に向かう。`domain` は他層を知らない。

## 各層の責務

### domain (Pure Kotlin モジュール)

- **役割**: ビジネスロジック・ドメインモデル・UseCase・Repository インターフェース
- **依存**: Kotlin stdlib + Coroutines のみ。Android SDK / Jetpack 依存禁止
- **構成**:
  ```
  domain/
  ├── model/        # Board, Stone, Player などのドメインオブジェクト
  ├── usecase/      # PlaceStoneUseCase, EvaluateBoardUseCase
  └── repository/   # GameRepository (interface のみ)
  ```

### data (Android Library モジュール)

- **役割**: Repository インターフェースの実装、DataSource (Room/Network/Preferences)
- **依存**: `domain` モジュール
- **構成**:
  ```
  data/
  ├── repository/   # GameRepositoryImpl
  ├── local/        # Room DAO, Entity, Database
  ├── remote/       # Retrofit API, DTO
  └── mapper/       # DTO/Entity ⇔ Domain Model 変換
  ```
- **重要**: DTO や Entity を `domain` 層に漏らさない。必ず Mapper で変換する

### presentation (app モジュール)

- **役割**: UI (Compose) + ViewModel + Navigation
- **依存**: `domain`, `data` (DI 経由)
- **構成**:
  ```
  app/
  ├── ui/
  │   ├── board/        # BoardScreen + BoardViewModel
  │   └── menu/         # MenuScreen + MenuViewModel
  ├── di/               # Hilt Module
  └── MainActivity.kt
  ```

## UseCase のルール

- **1 UseCase = 1 ユースケース** (1ファイル1クラス)
- **`operator fun invoke()`** でメソッド名を統一する
  ```kotlin
  class PlaceStoneUseCase(private val repo: GameRepository) {
      suspend operator fun invoke(pos: Position): Result<Board> { ... }
  }
  ```
- **副作用のないものは `suspend` 不要** (純粋計算なら同期メソッドで良い)

## Repository のルール

- **interface は domain、実装は data** で定義する
- **戻り値**: 単発取得は `Result<T>` または `T?`、変化を観測するなら `Flow<T>`
- **エラー**: domain 例外に変換してから投げる (Retrofit例外を上位層に漏らさない)

## ViewModel のルール

- **UseCase を呼び出すのみ**。ビジネスロジックを ViewModel に書かない
- **UIState を `StateFlow` で公開** する
- **副作用**: Snackbar 等は `SharedFlow<UiEvent>` で発火する
