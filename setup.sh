#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

mkdir -p "$CLAUDE_DIR"

# Copy statusline script
cp "$SCRIPT_DIR/statusline-command.sh" "$CLAUDE_DIR/statusline-command.sh"
chmod +x "$CLAUDE_DIR/statusline-command.sh"

# Merge statusLine config into settings.json
if [ -f "$CLAUDE_DIR/settings.json" ]; then
  node -e "
const fs = require('fs');
const existing = JSON.parse(fs.readFileSync(process.argv[1], 'utf8'));
const newSettings = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
existing.statusLine = newSettings.statusLine;
fs.writeFileSync(process.argv[1], JSON.stringify(existing, null, 2) + '\n');
" "$CLAUDE_DIR/settings.json" "$SCRIPT_DIR/settings.json"
  echo "Updated statusLine in existing ~/.claude/settings.json"
else
  cp "$SCRIPT_DIR/settings.json" "$CLAUDE_DIR/settings.json"
  echo "Created ~/.claude/settings.json"
fi

echo "Setup complete. Restart Claude Code to apply."
