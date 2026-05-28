#!/usr/bin/env bash
# boot.sh — Vibeboss HQ auto-boot brief
# Emits JSON for CC SessionStart hook: hookSpecificOutput.additionalContext
set -euo pipefail

# Arg parsing: --brief-only emits plain text brief, no JSON wrapper
BRIEF_ONLY=false
if [ "${1:-}" = "--brief-only" ]; then
  BRIEF_ONLY=true
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HQ="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORKSPACE="$(cd "$HQ/.." && pwd)"

TODAY="$(date '+%Y-%m-%d')"

# STOP-file kill switch — existence is the entire signal.
# Triggers: operator `touch STOP`, agent self-cap, three-strikes low-signal.
# Recovery: operator removes STOP file AND issues an explicit re-authorization.
STOP_PATH=""
if [ -e "$HQ/STOP" ]; then
  STOP_PATH="$HQ/STOP"
elif [ -e "$WORKSPACE/STOP" ]; then
  STOP_PATH="$WORKSPACE/STOP"
fi

if [ -n "$STOP_PATH" ]; then
  STOP_SIZE="$(wc -c < "$STOP_PATH" 2>/dev/null | tr -d ' ' || echo '0')"
  STOP_BRIEF="$(cat <<STOP_EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  VIBEBOSS HQ — STOPPED
  ${TODAY}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

A STOP file was detected at:
  ${STOP_PATH}

The autonomous loop or boot sequence is halted. {{LEAD_NAME}} will NOT auto-start work.

Recovery:
  1. Decide whether the halt was intentional or accidental.
  2. If intentional and now resolved: \`rm ${STOP_PATH}\` (the STOP file).
  3. Re-authorize with an explicit directive ({{LEAD_NAME}} should not infer next steps from history alone — wait for partner instruction).

STOP file size: ${STOP_SIZE} bytes — purely diagnostic; existence is the signal regardless of content.
STOP_EOF
)"

  if [ "$BRIEF_ONLY" = "true" ]; then
    printf '%s\n' "$STOP_BRIEF"
    exit 0
  fi

  BRIEF_CONTENT="$STOP_BRIEF" python3 - <<'PYEOF'
import json, os
brief = os.environ["BRIEF_CONTENT"]
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": brief
    }
}))
PYEOF
  exit 0
fi

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
# Fields parsed in ANY order: name, project, born_at, current_session_id
CREW_DISPLAY=""
if [ -f "$HQ/crew.yml" ]; then
  CREW_DISPLAY="$(CREW_YML="$HQ/crew.yml" python3 - <<'PYEOF'
import os, re

path = os.environ["CREW_YML"]
try:
    with open(path, "r") as f:
        lines = f.read().splitlines()
except OSError:
    raise SystemExit(0)

def strip_quotes(s):
    s = s.strip()
    if len(s) >= 2 and s[0] == s[-1] and s[0] in ('"', "'"):
        s = s[1:-1]
    return s

agents = []
current = None
in_agents = False

for line in lines:
    if re.match(r'^agents:\s*$', line):
        in_agents = True
        continue
    if not in_agents:
        continue
    # Exit block on a new top-level key (non-indented alpha line)
    if re.match(r'^[A-Za-z]', line):
        in_agents = False
        continue
    # New agent entry
    m = re.match(r'^\s*-\s*name:\s*(.*)$', line)
    if m:
        if current is not None:
            agents.append(current)
        current = {"name": strip_quotes(m.group(1))}
        continue
    if current is None:
        continue
    # Any other "key: value" line within current agent
    m = re.match(r'^\s+([A-Za-z_][A-Za-z0-9_]*):\s*(.*)$', line)
    if m:
        key = m.group(1)
        val = strip_quotes(m.group(2))
        if key in ("project", "born_at", "current_session_id"):
            current[key] = val

if current is not None:
    agents.append(current)

EM = "—"
out_lines = []
for a in agents:
    name = a.get("name", "")
    proj = a.get("project", "")
    ba = a.get("born_at", "null")
    cs = a.get("current_session_id", "null")
    if ba == "null":
        out_lines.append(f"  - [{name}] ({proj}) {EM} unborn")
    elif cs == "null":
        out_lines.append(f"  - {name} ({proj}) {EM} dormant")
    else:
        out_lines.append(f"  - {name} ({proj}) {EM} active {EM} session {cs}")

if out_lines:
    print("\n".join(out_lines))
PYEOF
  )"
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

# Update check: compare workspace's pinned version against source repo's VERSION.
# Defensive — any failure silently yields no banner; boot must not break.
UPDATE_BANNER=""
UPDATE_BANNER_BLOCK=""
if [ -f "$WORKSPACE/.vibeboss-version" ]; then
  WS_VERSION="$(grep '^version:' "$WORKSPACE/.vibeboss-version" 2>/dev/null | head -1 | sed 's/^version: *//' || true)"
  SOURCE_PATH="$(grep '^source_path:' "$WORKSPACE/.vibeboss-version" 2>/dev/null | head -1 | sed 's/^source_path: *//' || true)"
  if [ -n "$WS_VERSION" ] && [ -n "$SOURCE_PATH" ] && [ -f "$SOURCE_PATH/VERSION" ]; then
    SOURCE_VERSION="$(cat "$SOURCE_PATH/VERSION" 2>/dev/null | tr -d '[:space:]' || true)"
    if [ -n "$SOURCE_VERSION" ] && [ "$WS_VERSION" != "$SOURCE_VERSION" ]; then
      UPDATE_BANNER="- **Vibeboss update available:** v$WS_VERSION → v$SOURCE_VERSION. Run \`bash $SOURCE_PATH/init.sh --update --workspace $WORKSPACE\` to apply."
      UPDATE_BANNER_BLOCK=$'\n'"$UPDATE_BANNER"
    fi
  fi
fi

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
${NEXT_ITEMS}${UPDATE_BANNER_BLOCK}

${CLOSING}
BRIEF_EOF
)"

# If --brief-only, emit plain text and exit (used by compact-boot.sh)
if [ "$BRIEF_ONLY" = "true" ]; then
  printf '%s\n' "$BRIEF"
  exit 0
fi

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
