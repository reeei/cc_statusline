#!/usr/bin/env bash
input=$(cat)

# --- Parse JSON with Python (jq not available on this Windows env) ---
parsed=$(echo "$input" | python -c "
import sys, json
d = json.load(sys.stdin)
def get(path):
    o = d
    for k in path.split('.'):
        if isinstance(o, dict):
            o = o.get(k)
        else:
            return ''
    return '' if o is None else str(o)
fields = [
    'workspace.current_dir',
    'model.id',
    'model.display_name',
    'context_window.used_percentage',
    'rate_limits.five_hour.used_percentage',
    'rate_limits.five_hour.resets_at',
    'rate_limits.seven_day.used_percentage',
    'rate_limits.seven_day.resets_at',
]
for f in fields:
    print(get(f))
" 2>/dev/null)

# Read parsed values
IFS=$'\n' read -r -d '' cwd model_id model_display used_pct five_pct five_reset seven_pct seven_reset <<< "$parsed"

# --- Path display: show workspace-relative path ---
display_path=""
if [ -n "$cwd" ]; then
  # Remove workspace base to get short path (e.g. "cc_work")
  workspace_base="$HOME/.vscode/workspace"
  # Normalize backslashes to forward slashes for Windows
  normalized_cwd=$(echo "$cwd" | sed 's|\\|/|g')
  normalized_base=$(echo "$workspace_base" | sed 's|\\|/|g')
  display_path="${normalized_cwd#$normalized_base/}"
  # If no change (not under workspace), show basename only
  if [ "$display_path" = "$normalized_cwd" ]; then
    display_path=$(basename "$normalized_cwd")
  fi
fi

# --- Git info ---
git_branch=""
if [ -n "$cwd" ]; then
  git_branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
fi

# --- Model ---
model="${model_display:-$model_id}"
[ -z "$model" ] && model="Unknown"

# --- Context window progress bar (10 chars) ---
context_str=""
if [ -n "$used_pct" ] && [ "$used_pct" != "0" ]; then
  filled=$(echo "$used_pct" | awk '{printf "%d", int($1/10 + 0.5)}')
  bar=""
  for i in $(seq 1 10); do
    if [ "$i" -le "$filled" ]; then
      bar="${bar}█"
    else
      bar="${bar}░"
    fi
  done
  pct_int=$(echo "$used_pct" | awk '{printf "%d", $1 + 0.5}')
  context_str="${bar} ${pct_int}%"
else
  context_str="░░░░░░░░░░ 0%"
fi

# --- Rate limits ---
rate_str=""
if [ -n "$five_pct" ] && [ -n "$seven_pct" ]; then
  # Format reset times using python
  five_time=$(echo "$five_reset" | python -c "
import sys
from datetime import datetime
try:
    s = sys.stdin.read().strip()
    dt = datetime.fromisoformat(s.replace('Z','+00:00'))
    print(dt.strftime('%I%p').lstrip('0').lower())
except:
    print('?')
" 2>/dev/null)
  seven_time=$(echo "$seven_reset" | python -c "
import sys
from datetime import datetime
try:
    s = sys.stdin.read().strip()
    dt = datetime.fromisoformat(s.replace('Z','+00:00'))
    print(dt.strftime('%m/%d %I%p').lstrip('0').lower())
except:
    print('?')
" 2>/dev/null)
  five_int=$(echo "$five_pct" | awk '{printf "%d", $1 + 0.5}')
  seven_int=$(echo "$seven_pct" | awk '{printf "%d", $1 + 0.5}')
  rate_str="5h:${five_int}%(${five_time:-?})  7d:${seven_int}%(${seven_time:-?})"
fi

# --- Build output ---
parts=()

# Line 1: path + branch
line1=""
[ -n "$display_path" ] && line1="$display_path"
if [ -n "$git_branch" ]; then
  if [ -n "$line1" ]; then
    line1="$line1 | $git_branch"
  else
    line1="$git_branch"
  fi
fi
[ -n "$line1" ] && parts+=("$line1")

# Line 2: context + model
parts+=("$context_str | $model")

# Line 3: rate limits
[ -n "$rate_str" ] && parts+=("$rate_str")

# Join with newlines
output=""
for p in "${parts[@]}"; do
  if [ -z "$output" ]; then
    output="$p"
  else
    output=$(printf "%s\n%s" "$output" "$p")
  fi
done

printf "%s" "$output"
