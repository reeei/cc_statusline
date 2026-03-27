# Claude Code Statusline

Claude Codeのカスタムstatusline設定。

## 表示内容

```
cc_work | main
░░░░░░░░░░ 0% | Claude Opus 4.6
5h:12%(3pm)  7d:5%(03/30 9am)
```

- **1行目**: ワークスペース相対パス + Gitブランチ
- **2行目**: コンテキストウィンドウ使用率（プログレスバー） + モデル名
- **3行目**: 5時間 / 7日間のレート制限使用率 + リセット時刻

## セットアップ

```bash
./setup.sh
```

または手動:

```bash
cp statusline-command.sh ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh
# settings.json の statusLine セクションを ~/.claude/settings.json にマージ
```

## 前提条件

- Python 3（JSON解析に使用）
- bash環境（Windows: Git Bash / WSL）
