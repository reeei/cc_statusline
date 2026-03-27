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
  # settings.json exists — merge statusLine key using Python
  python3 -c "
import json, sys

with open('$CLAUDE_DIR/settings.json', 'r') as f:
    existing = json.load(f)

with open('$SCRIPT_DIR/settings.json', 'r') as f:
    new_settings = json.load(f)

existing['statusLine'] = new_settings['statusLine']

with open('$CLAUDE_DIR/settings.json', 'w') as f:
    json.dump(existing, f, indent=2)
"
  echo "Updated statusLine in existing ~/.claude/settings.json"
else
  cp "$SCRIPT_DIR/settings.json" "$CLAUDE_DIR/settings.json"
  echo "Created ~/.claude/settings.json"
fi

echo "Setup complete. Restart Claude Code to apply."
