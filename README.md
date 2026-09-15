# Run & Jump (RG Rotate Special)

RG Rotate（正方形・画面回転対応 Android 携帯機など）に特化した、ワンボタン・強制横スクロール・ローグライクジャンプアクションゲームです。

---

## 🎮 ゲーム概要 & 操作設計

- **操作系:**
  - ゲームパッドの **A / B / X / Y ボタン**、**画面タップ**、**スペースキー** のいずれか1ボタンのみで操作。
- **コアメカニクス:**
  - **可変ジャンプ:** ボタンの長押し時間に応じてジャンプの高さが変化（短押しで小ジャンプ、長押しで大ジャンプ）。
  - **快適な操作感:** コヨーテタイム (0.12s) ＆ 先行入力バッファ (0.12s) を搭載。
  - **踏みつけ判定:** 敵の頭上から接触すると敵を撃破し、上空へ大バウンド。
  - **即リトライ:** 落下やトゲ衝突後、0.25秒でワンボタンによる瞬時リスタートが可能。
- **RG Rotate 特化設計:**
  - 画面比率 `720x720`（1:1 正方形）および動的アスペクト比対応により、縦持ち・横持ち・画面回転のどの向きでも快適にプレイ可能。
  - プロシージャル生成による Synthwave/8bit 効果音内蔵。

---

## 🛠 開発環境 & ビルド要件

- **Engine:** Godot Engine 4.7.2
- **Language:** GDScript
- **Target Platforms:** Android (RG Cube / RG Rotate / 汎用Android端末), Windows, Web

---

## 📱 Android 向けビルド & adb インストール

### 1. デバッグキーストア生成（初回のみ）
```bash
keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore debug.keystore -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999 -deststoretype pkcs12
```

### 2. APK のエクスポート
```bash
Godot_v4.7.2-stable_win64_console.exe --headless --export-debug "Android" build/runandjump.apk
```

### 3. 実機へのインストール & 起動
```bash
adb install -r build/runandjump.apk
adb shell am start -n com.example.runandjump/com.godot.game.GodotApp
```

---

## 📁 ディレクトリ構成

```
runandjump/
├── project.godot           # プロジェクト設定・入力マッピング・解像度
├── export_presets.cfg      # Android エクスポートプリセット設定
├── scenes/
│   ├── Main.tscn           # メインゲームシーン (HUD, 背景, カメラ, スポナー)
│   └── Player.tscn         # プレイヤーキャラシーン
├── scripts/
│   ├── Main.gd             # ゲームステート・スコア・即座リトライ
│   ├── Player.gd           # 1ボタン可変ジャンプ・踏みつけバウンド・トレイル
│   ├── Enemy.gd            # 敵挙動・頭上踏みつけ判定
│   ├── LevelSpawner.gd     # 強制スクロール・チャンク生成
│   ├── Platform.gd         # プロシージャル足場
│   ├── Spike.gd            # 即死トゲ
│   ├── GridBackground.gd   # ネオングリッド流体背景
│   ├── SoundSynth.gd       # 8bit効果音プロシージャル生成
│   └── HUD.gd              # スコア・コンボ・タイトル・リザルトUI
└── README.md
```