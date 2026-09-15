# Run & Jump (RG Rotate Special)

<div align="center">
  <img src="icon.png" width="180" height="180" alt="Run & Jump Icon" style="border-radius: 24px; box-shadow: 0 8px 24px rgba(0, 200, 255, 0.4);" />
  
  ### 🎮 RG Rotate 特化 ワンボタン・強制スクロール・ローグライクジャンプアクション
</div>

---

## 🕹️ ゲーム概要 & 操作設計

- **操作系:**
  - ゲームパッドの **A / B / X / Y ボタン**、**画面タップ**、**スペースキー** のいずれか1ボタンのみで全操作が可能。
- **コアメカニクス:**
  - **初期2段ジャンプ:** 開始時から空中ジャンプが可能。スキルで3段・4段ジャンプへ拡張可能。
  - **可変ジャンプ:** ボタンの長押し時間に応じてジャンプの高さが変化（短押しで小ジャンプ、長押しで大ジャンプ）。
  - **快適な操作感:** コヨーテタイム (0.12s) ＆ 先行入力バッファ (0.12s) 搭載。
  - **踏みつけ判定:** 敵の頭上から接触すると敵を一撃で粉砕し、上空へ大バウンド。
  - **即リトライ:** ゲームオーバー後、0.25秒でワンボタンによる瞬時リスタートが可能。

---

## ❤️ HP制 & 自動攻撃 & ローグライクレベルアップ

- **❤️ 3桁HPバーシステム (初期 HP 100):**
  - 敵との正面衝突やトゲ接触時は即死せずダメージ（15〜20）を受け、1.0秒間の無敵点滅（I-Frames）が発生。
  - 穴に落ちた場合も落下ダメージ（25）を受けて画面上空から安全に復帰。
- **⚡ 自動攻撃 (Auto-Blaster):**
  - 1ボタン操作（ジャンプ）を維持したまま、前方の敵へ向けてネオン弾を自動連射。
- **💎 経験値回収 & 3択スキルカード:**
  - 敵撃破でEXPジェムがドロップし、磁力でプレイヤーへ自動吸引。
  - レベルアップ時は**ゲームが完全一時停止（Pause）**し、3枚のスキルカードを提示。
  - **ワンボタン対応:** 選択枠が自動巡回するため、欲しいカードのタイミングでボタンを押すだけで選択獲得可能（タップ選択も対応）。

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
adb shell monkey -p com.example.runandjump -c android.intent.category.LAUNCHER 1
```

---

## 📁 ディレクトリ構成

```
runandjump/
├── icon.png                # アプリアイコン画像
├── project.godot           # プロジェクト設定・入力マッピング・解像度
├── export_presets.cfg      # Android エクスポートプリセット設定
├── scenes/
│   ├── Main.tscn           # メインゲームシーン (HUD, 背景, カメラ, スポナー)
│   └── Player.tscn         # プレイヤーキャラシーン
├── scripts/
│   ├── Main.gd             # ゲームステート・スコア・ポーズ管理
│   ├── Player.gd           # 1ボタン可変ジャンプ・踏みつけ・自動攻撃・HP管理
│   ├── Enemy.gd            # 敵挙動・頭上踏みつけ・HPバー
│   ├── LevelSpawner.gd     # 強制スクロール・チャンク生成
│   ├── SkillDatabase.gd    # ローグライクスキル定義
│   ├── Projectile.gd       # 自動弾
│   ├── ExpGem.gd           # EXPジェム・マグネット吸引
│   ├── Platform.gd         # プロシージャル足場
│   ├── Spike.gd            # トゲ障害物
│   ├── GridBackground.gd   # ネオングリッド流体背景
│   ├── SoundSynth.gd       # 8bit効果音プロシージャル生成
│   └── HUD.gd              # HPバー・EXPバー・スキル選択モーダルUI
└── README.md
```