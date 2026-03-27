# Claude Code Statusline

Claude Code のカスタム statusline 設定。

## 表示内容

```
sap-cc | main
██░░░░░░░░ 23% | Opus 4.6
5h:4%(8am/4h46m)  7d:9%(04/02 6pm/5d14h)
```

- **1行目**: ワークスペース相対パス + Git ブランチ
- **2行目**: コンテキストウィンドウ使用率（プログレスバー） + モデル名
- **3行目**: レート制限使用率 + リセット時刻 + リセットまでの残り時間

## セットアップ

```bash
git clone https://github.com/reeei/cc_statusline.git
cd cc_statusline
./setup.sh
```

または手動:

```bash
cp statusline-command.sh ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh
# settings.json の statusLine セクションを ~/.claude/settings.json にマージ
```

セットアップ後、Claude Code を再起動してください。

## 前提条件

- **Node.js** (v18+)
- **Git**
- bash 環境（Windows: Git Bash / WSL）

## 技術メモ

- JSON 解析・日時フォーマットに Node.js を使用（Python 不要）
- `resets_at` は Unix epoch seconds として処理（公式スキーマ準拠）
- Windows (Git Bash) / macOS / Linux で動作確認済み
