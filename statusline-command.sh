#!/usr/bin/env bash
cat | node -e "
let buf = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', c => buf += c);
process.stdin.on('end', () => {
  try {
    const d = JSON.parse(buf);
    const get = (path) => {
      let o = d;
      for (const k of path.split('.')) {
        if (o && typeof o === 'object') o = o[k];
        else return null;
      }
      return o;
    };

    // --- Path display ---
    const cwd = get('workspace.current_dir') || '';
    let displayPath = '';
    if (cwd) {
      const norm = cwd.replace(/\\\\/g, '/');
      const base = (process.env.HOME || '').replace(/\\\\/g, '/') + '/.vscode/workspace';
      if (norm.startsWith(base + '/')) {
        displayPath = norm.slice(base.length + 1);
      } else {
        displayPath = norm.split('/').pop() || norm;
      }
    }

    // --- Git branch ---
    let gitBranch = '';
    if (cwd) {
      try {
        gitBranch = require('child_process')
          .execSync('git rev-parse --abbrev-ref HEAD', { cwd, encoding: 'utf8', stdio: ['pipe','pipe','pipe'] })
          .trim();
      } catch(e) {}
    }

    // --- Model ---
    const model = get('model.display_name') || get('model.id') || 'Unknown';

    // --- Context window progress bar ---
    const usedPct = Number(get('context_window.used_percentage')) || 0;
    const filled = Math.round(usedPct / 10);
    const bar = '\u2588'.repeat(filled) + '\u2591'.repeat(10 - filled);
    const contextStr = bar + ' ' + Math.round(usedPct) + '%';

    // --- Rate limits ---
    const fivePct = get('rate_limits.five_hour.used_percentage');
    const fiveReset = get('rate_limits.five_hour.resets_at');
    const sevenPct = get('rate_limits.seven_day.used_percentage');
    const sevenReset = get('rate_limits.seven_day.resets_at');

    let rateStr = '';
    if (fivePct != null && sevenPct != null) {
      const now = Date.now();
      const fmtRemaining = (epochSec) => {
        const diff = epochSec * 1000 - now;
        if (diff <= 0) return '0m';
        const h = Math.floor(diff / 3600000);
        const m = Math.floor((diff % 3600000) / 60000);
        if (h > 24) { const dd = Math.floor(h / 24); return dd + 'd' + (h % 24) + 'h'; }
        if (h > 0) return h + 'h' + m + 'm';
        return m + 'm';
      };
      const fmtTime = (epochSec) => {
        try {
          if (epochSec == null) return '?';
          const dt = new Date(epochSec * 1000);
          if (isNaN(dt.getTime())) return '?';
          let h = dt.getHours(), ampm = h >= 12 ? 'pm' : 'am';
          h = h % 12 || 12;
          return h + ampm + '/' + fmtRemaining(epochSec);
        } catch(e) { return '?'; }
      };
      const fmtDateTime = (epochSec) => {
        try {
          if (epochSec == null) return '?';
          const dt = new Date(epochSec * 1000);
          if (isNaN(dt.getTime())) return '?';
          const mm = String(dt.getMonth()+1).padStart(2,'0');
          const dd = String(dt.getDate()).padStart(2,'0');
          let h = dt.getHours(), ampm = h >= 12 ? 'pm' : 'am';
          h = h % 12 || 12;
          return mm + '/' + dd + ' ' + h + ampm + '/' + fmtRemaining(epochSec);
        } catch(e) { return '?'; }
      };
      rateStr = '5h:' + Math.round(fivePct) + '%(' + fmtTime(fiveReset) + ')  7d:' + Math.round(sevenPct) + '%(' + fmtDateTime(sevenReset) + ')';
    }

    // --- Build output ---
    const lines = [];
    let line1 = displayPath;
    if (gitBranch) line1 = line1 ? line1 + ' | ' + gitBranch : gitBranch;
    if (line1) lines.push(line1);
    lines.push(contextStr + ' | ' + model);
    if (rateStr) lines.push(rateStr);

    process.stdout.write(lines.join('\n'));
  } catch(e) {
    process.stdout.write('statusline error');
  }
});
"
