# Android プロジェクト初期化スキル

`OthelloJosekiMaster` の Android プロジェクト雛形を生成する (リポジトリは作成済み前提)。

## 前提

- GitHub リポジトリ: https://github.com/argama147/OthelloJosekiMaster (既存)
- ローカル: `/Users/argama147/claudework/OthelloAndroid/`
- スコープに `.claude/` 設定の範囲を超えるため、**ユーザー同意を得てから実行する**

## 手順

### 1. 現状確認

```bash
ls /Users/argama147/claudework/OthelloAndroid/
git -C /Users/argama147/claudework/OthelloAndroid/ status 2>&1 || echo "not a git repo yet"
```

### 2. ユーザーに確認 (AskUserQuestion)

```
以下の初期化を実行しますか？

1. git init + GitHub リモート設定 (origin = https://github.com/argama147/OthelloJosekiMaster)
2. Gradle Wrapper の生成
3. settings.gradle.kts / build.gradle.kts (root) の作成
4. app / domain / data の3モジュール雛形
5. .gitignore (Android標準)
6. docs/ 配下のディレクトリ作成 (spec/, design/, adr/)
7. .github/workflows/ci.yml (build + test + lint)
8. ktlint / detekt 設定
```

承認されてから実行する。

### 3. 実装の流れ

#### a. Git 初期化
```bash
git -C /Users/argama147/claudework/OthelloAndroid/ init
git -C /Users/argama147/claudework/OthelloAndroid/ remote add origin https://github.com/argama147/OthelloJosekiMaster.git
git -C /Users/argama147/claudework/OthelloAndroid/ fetch origin
# リモートに既存コミットがある場合は要確認
```

#### b. プロジェクト構造

```
OthelloAndroid/
├── build.gradle.kts                  # ルート (plugins, version catalog ref)
├── settings.gradle.kts               # モジュール宣言
├── gradle/
│   ├── libs.versions.toml            # Version Catalog
│   └── wrapper/                      # Gradle Wrapper
├── app/
│   ├── build.gradle.kts
│   └── src/main/
│       ├── java/com/argama/othello/josekimaster/
│       │   ├── MainActivity.kt
│       │   └── ui/
│       └── AndroidManifest.xml
├── domain/
│   ├── build.gradle.kts              # Pure Kotlin, no android plugin
│   └── src/main/kotlin/com/argama/othello/josekimaster/domain/
├── data/
│   ├── build.gradle.kts              # com.android.library
│   └── src/main/kotlin/com/argama/othello/josekimaster/data/
├── docs/
│   ├── spec/.gitkeep
│   ├── design/.gitkeep
│   └── adr/.gitkeep
├── .github/workflows/ci.yml
├── .gitignore
├── config/detekt/detekt.yml
└── README.md
```

#### c. Version Catalog (libs.versions.toml) の主要項目

```toml
[versions]
kotlin = "2.0.20"
agp = "8.6.0"
compose-bom = "2024.09.02"
hilt = "2.52"
room = "2.6.1"
coroutines = "1.9.0"
junit5 = "5.11.0"
mockk = "1.13.12"
turbine = "1.1.0"
ktlint = "12.1.1"
detekt = "1.23.7"
```

(最新版は実行時に確認)

#### d. CI ワークフロー (.github/workflows/ci.yml)

```yaml
name: CI
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  build-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'
      - uses: gradle/actions/setup-gradle@v4
      - run: ./gradlew ktlintCheck detekt lint
      - run: ./gradlew :domain:test :data:test :app:test
      - run: ./gradlew :app:assembleDebug
```

### 4. 初回コミット

```bash
git -C /Users/argama147/claudework/OthelloAndroid/ add -A
git -C /Users/argama147/claudework/OthelloAndroid/ commit -m "chore: initial project scaffold

Kotlin + Jetpack Compose + Clean Architecture (3 modules: app/domain/data).
Gradle KTS + Version Catalog. CI: build/test/ktlint/detekt/lint."
git -C /Users/argama147/claudework/OthelloAndroid/ branch -M main
git -C /Users/argama147/claudework/OthelloAndroid/ push -u origin main
```

**注意**: push は必ずユーザー同意を得てから実行する。

### 5. 完了後

- GitHub Actions が初回ビルドを通すことを確認
- 必要に応じて `gh repo edit` でデフォルトブランチを `main` に
- README.md にセットアップ手順を追記
