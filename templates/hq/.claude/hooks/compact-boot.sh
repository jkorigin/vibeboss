#!/usr/bin/env bash
# compact-boot.sh — Vibeboss HQ post-compact context injector
# Fires on SessionStart matcher="compact"
# Calls boot.sh for standard boot brief, then injects the most-recent handover file.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HQ="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Get the boot brief as plain text (--brief-only skips the JSON wrap)
BOOT_BRIEF="$(bash "$SCRIPT_DIR/boot.sh" --brief-only 2>/dev/null || true)"
[ -z "$BOOT_BRIEF" ] && BOOT_BRIEF="(boot brief unavailable)"

# Find most-recently-modified handover *.md (not README, case-insensitive) in hq/handovers/
HANDOVER_FILE=""
if [ -d "$HQ/handovers" ]; then
  NEWEST_FILE="$(ls -t "$HQ/handovers/"*.md 2>/dev/null | grep -iv 'README' | head -1 || true)"
  if [ -n "$NEWEST_FILE" ]; then
    NOW_SEC="$(date +%s)"
    # macOS stat: -f %m; Linux stat: -c %Y — try macOS first, fall back to Linux
    FILE_MTIME_SEC="$(stat -f %m "$NEWEST_FILE" 2>/dev/null \
      || stat -c %Y "$NEWEST_FILE" 2>/dev/null \
      || echo 0)"
    AGE_SEC=$(( NOW_SEC - FILE_MTIME_SEC ))
    # 3600 seconds = exactly 60 minutes; files older than this are stale
    [ "$AGE_SEC" -lt 3600 ] && HANDOVER_FILE="$NEWEST_FILE"
  fi
fi

# Compose full additionalContext
if [ -n "$HANDOVER_FILE" ]; then
  HANDOVER_CONTENT="$(cat "$HANDOVER_FILE" 2>/dev/null || true)"
  FULL_CONTEXT="${BOOT_BRIEF}

$(printf '\342\224\200%.0s' {1..35})
  POST-COMPACT HANDOVER INJECTED
$(printf '\342\224\200%.0s' {1..35})
File: $(basename "$HANDOVER_FILE")

${HANDOVER_CONTENT}

Resume from the \"Resume action\" field above."
else
  FULL_CONTEXT="${BOOT_BRIEF}

$(printf '\342\224\200%.0s' {1..35})
  POST-COMPACT \342\200\224 NO RECENT HANDOVER
$(printf '\342\224\200%.0s' {1..35})
No handover file < 60 min old in hq/handovers/.
Discipline failure: write handover BEFORE /compact next time.
Re-read STATE.md + most recent runlog to orient."
fi

# Emit JSON — env var approach so Python json.dumps handles all escaping
# Fallback: if python3 fails, emit minimal valid JSON so CC does not receive a hook error
BRIEF_CONTENT="$FULL_CONTEXT" python3 - <<'PYEOF' || \
  python3 -c "import json; print(json.dumps({'hookSpecificOutput': {'hookEventName': 'SessionStart', 'additionalContext': '(compact hook error: JSON emit failed)'}}))"
import json, os
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": os.environ["BRIEF_CONTENT"]
    }
}))
PYEOF
