#!/usr/bin/env bash
# boot.sh — Vibeboss HQ auto-boot brief
# Emits JSON for CC SessionStart hook: hookSpecificOutput.additionalContext
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HQ="$(cd "$SCRIPT_DIR/../.." && pwd)"

TODAY="$(date '+%Y-%m-%d')"

# Phase: first **Phase:** line in STATE.md
PHASE="$(grep -m1 '^\*\*Phase:\*\*' "$HQ/STATE.md" 2>/dev/null \
  | sed 's/\*\*Phase:\*\* *//' \
  || true)"
[ -z "$PHASE" ] && PHASE="unavailable"

# State: first non-empty, non-heading line after ## Current state
STATE_ONELINER="$(awk '
  /^## Current state/{found=1; next}
  found && /^## /{exit}
  found && /[[:alpha:]]/{print; exit}
' "$HQ/STATE.md" 2>/dev/null | cut -c1-160 || true)"
[ -z "$STATE_ONELINER" ] && STATE_ONELINER="unavailable"

# Last session: most recently modified runlog file (by mtime)
LAST_LOG="$(ls -t "$HQ/runlog/" 2>/dev/null \
  | grep '\.md$' \
  | grep -v '^README' \
  | head -1 \
  || true)"
LAST_SESSION="${LAST_LOG%.md}"
[ -z "$LAST_SESSION" ] && LAST_SESSION="none"

# Inbox: count items per subfolder
INBOX_TOTAL=0
INBOX_LINES=""
for subdir in requests chats todos; do
  INBOX_DIR="$HQ/inbox/$subdir"
  if [ -d "$INBOX_DIR" ]; then
    n="$(find "$INBOX_DIR" -maxdepth 1 -name '*.md' ! -name 'README*' 2>/dev/null | wc -l | tr -d ' ')"
    INBOX_TOTAL=$((INBOX_TOTAL + n))
    if [ "$n" -gt 0 ]; then
      INBOX_LINES="${INBOX_LINES}  ${subdir}: ${n} item(s)"$'\n'
    fi
  fi
done
if [ -z "$INBOX_LINES" ]; then
  INBOX_DISPLAY="empty"
else
  INBOX_DISPLAY=$'\n'"${INBOX_LINES%$'\n'}"
fi

# Active projects: first non-heading status line from each project's STATE.md
PROJECTS_DISPLAY=""
if [ -d "$HQ/projects" ]; then
  for proj_dir in "$HQ/projects"/*/; do
    [ -d "$proj_dir" ] || continue
    proj="$(basename "$proj_dir")"
    headline="$(awk '/^#/{next} /[[:alpha:]]/{print; exit}' \
      "$proj_dir/STATE.md" 2>/dev/null \
      | sed 's/^\*\*//; s/\*\*//' \
      | cut -c1-80 \
      || true)"
    [ -z "$headline" ] && headline="no state"
    PROJECTS_DISPLAY="${PROJECTS_DISPLAY}  - ${proj}: ${headline}"$'\n'
  done
fi
[ -z "$PROJECTS_DISPLAY" ] && PROJECTS_DISPLAY="  none"$'\n'
PROJECTS_DISPLAY="${PROJECTS_DISPLAY%$'\n'}"

# Crew: parse crew.yml agents block
# Unborn agents shown in brackets per CLAUDE.md convention
CREW_DISPLAY=""
if [ -f "$HQ/crew.yml" ]; then
  CREW_DISPLAY="$(awk '
    /^agents:/{in_agents=1; next}
    in_agents && /^[a-zA-Z]/{in_agents=0}
    in_agents && /^  - name:/{
      split($0, a, /: /); name=a[2]; gsub(/"/, "", name)
    }
    in_agents && /^    project:/{
      split($0, a, /: /); proj=a[2]; gsub(/"/, "", proj)
    }
    in_agents && /^    born_at:/{
      split($0, a, /: /); ba=a[2]; gsub(/"/, "", ba)
    }
    in_agents && /^    current_session_id:/{
      split($0, a, /: /); cs=a[2]; gsub(/"/, "", cs)
      if (ba == "null")
        printf "  - [%s] (%s) \342\200\224 unborn\n", name, proj
      else if (cs == "null")
        printf "  - %s (%s) \342\200\224 dormant\n", name, proj
      else
        printf "  - %s (%s) \342\200\224 active \342\200\224 session %s\n", name, proj, cs
    }
  ' "$HQ/crew.yml" 2>/dev/null)"
fi
[ -z "$CREW_DISPLAY" ] && CREW_DISPLAY="  none"

# Open questions: first 5 bullets from ## Open questions section
OPEN_QS="$(awk '
  /^## Open questions/{found=1; count=0; next}
  found && /^## /{exit}
  found && /^- / && count < 5 {
    print "  " substr($0, 1, 120)
    count++
  }
' "$HQ/STATE.md" 2>/dev/null || true)"
[ -z "$OPEN_QS" ] && OPEN_QS="  none"

# Next: first 3 numbered items from ## Next section
NEXT_ITEMS="$(awk '
  /^## Next/{found=1; count=0; next}
  found && /^## /{exit}
  found && /^[0-9]+\./ && count < 3 {
    print "  " substr($0, 1, 120)
    count++
  }
' "$HQ/STATE.md" 2>/dev/null || true)"
[ -z "$NEXT_ITEMS" ] && NEXT_ITEMS="  none"

# Closing line depends on inbox state
if [ "$INBOX_TOTAL" -gt 0 ]; then
  CLOSING="Inbox has ${INBOX_TOTAL} item(s) — start there?"
else
  CLOSING="Ready. What are we working on?"
fi

# Compose brief
BRIEF="$(cat <<BRIEF_EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  VIBEBOSS HQ — online
  ${TODAY}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

- **Phase:** ${PHASE}
- **State:** ${STATE_ONELINER}
- **Last session:** ${LAST_SESSION}
- **Inbox:** ${INBOX_DISPLAY}
- **Active projects:**
${PROJECTS_DISPLAY}
- **Active crew:**
${CREW_DISPLAY}
- **Open questions:**
${OPEN_QS}
- **Next (top 3):**
${NEXT_ITEMS}

${CLOSING}
BRIEF_EOF
)"

# Emit JSON — pass brief via env var so Python json.dumps handles all escaping
BRIEF_CONTENT="$BRIEF" python3 - <<'PYEOF'
import json, os
brief = os.environ["BRIEF_CONTENT"]
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": brief
    }
}))
PYEOF
