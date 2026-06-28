# 開発ツール

このディレクトリには、ゲーム本体(RGBDS)とは独立した開発支援ツールを配置します。

例:

* フォント画像生成
* タイル画像変換
* マップデータ変換
* 各種アセット生成
* その他の開発補助ツール

---

# 開発環境

Pythonツールはプロジェクトルートに作成した仮想環境 (`.venv`) を使用します。

## 初回セットアップ

### 1. Python環境を準備

Ubuntuの場合

```bash
sudo apt update
sudo apt install python3 python3-pip python3-venv
```

### 2. 仮想環境を作成

プロジェクトルートで実行します。

```bash
python3 -m venv .venv
```

### 3. 仮想環境を有効化

```bash
source .venv/bin/activate
```

有効化されるとプロンプトの先頭に

```text
(.venv)
```

が表示されます。

### 4. 必要なライブラリをインストール

```bash
pip install -r requirements.txt
```

---

# 仮想環境の有効化

開発を再開するときは、プロジェクトルートで以下を実行してください。

```bash
source .venv/bin/activate
```

終了する場合は

```bash
deactivate
```

を実行します。

---

# フォント画像生成

Nuきなこもちフォントから `assets/font.png` を生成します。

```bash
python tools/generate_font_png.py
```

入力ファイル

```text
assets/NuKinakoMochi-Reg.otf
```

出力ファイル

```text
assets/font.png
```

---

# BG画像タイル変換

Indexed Color PNGを8×8タイルへ分割し、重複タイルを削除したタイルセットPNGと、1タイル1バイトのBGマップファイルを生成します。

```bash
python tools/convert_bg_image.py assets/title.png obj/title_tiles.png obj/title_map.bin
```

入力画像の条件:

* Indexed Color PNG
* 使用パレットインデックスは0〜3の4色
* アルファチャンネルなし
* 幅と高さが8の倍数
* 重複削除後のタイル数が256以下

出力ファイル:

```text
obj/title_tiles.png
obj/title_map.bin
```

`obj/title_map.bin` は元画像を左上から右下へ8×8タイル単位で走査したタイル番号列です。

---

# requirements.txt

Pythonライブラリはプロジェクトルートの

```text
requirements.txt
```

で管理します。

ライブラリを追加した場合は

```bash
pip freeze > requirements.txt
```

ではなく、必要なライブラリのみを手動で管理してください。

例

```text
Pillow
```

---

# 開発方針

* ゲーム本体はRGBDSでビルドする。
* Pythonは開発支援ツール専用とする。
* Pythonツールは可能な限り再利用できるよう、ゲーム固有処理への依存を避ける。
* 新しいツールを追加した場合は、このREADMEへ用途と実行方法を追記する。
