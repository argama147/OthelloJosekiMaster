# Android ビルド & 品質チェックスキル

PR作成前・作業の節目で、ローカルビルドと品質ゲートを一括実行する。

## 手順

### 1. 全チェックを並行実行

```bash
./gradlew clean
./gradlew :app:assembleDebug             # ビルド
./gradlew :domain:test :data:test :app:test    # ユニットテスト
./gradlew ktlintCheck                    # コーディング規約
./gradlew detekt                         # 静的解析
./gradlew lint                           # Android Lint
```

### 2. 失敗時の対応

各タスクで失敗があれば、原因を特定して報告する:

| タスク         | 失敗時の確認ポイント                                        |
| -------------- | ----------------------------------------------------------- |
| assembleDebug  | 依存解決、Kotlin/Compose のコンパイルエラー                |
| test           | テストレポート: `*/build/reports/tests/test/index.html`    |
| ktlintCheck    | 自動修正: `./gradlew ktlintFormat`                          |
| detekt         | レポート: `*/build/reports/detekt/detekt.html`              |
| lint           | レポート: `*/build/reports/lint-results-debug.html`         |

### 3. 結果サマリを提示

```
## ビルド & 品質チェック結果

| タスク         | 結果   | 詳細                                |
|----------------|--------|-------------------------------------|
| assembleDebug  | ✅ PASS | -                                  |
| test           | ✅ PASS | 42 passed, 0 failed                |
| ktlintCheck    | ❌ FAIL | 3件 → ./gradlew ktlintFormat 提案 |
| detekt         | ✅ PASS | -                                  |
| lint           | ⚠️ WARN | 2件 (UnusedResources)              |

次アクション: <具体的な修正提案>
```

### 4. 品質ゲートの基準

- **PR作成前**: 全項目 PASS が必須
- **WIP状態**: ビルドとテストが通っていればよい
- **静的解析の警告**: detekt/lint の WARN は許容、ERROR は修正必須

## 落とし穴

- **Gradle daemon キャッシュ汚染**: 直前の失敗が引きずられる場合 `./gradlew --stop` してリトライ
- **メモリ不足**: `org.gradle.jvmargs=-Xmx4g` を `gradle.properties` に設定
- **Compose のテスト**: emulator/device が必要な `connectedAndroidTest` は別実行
