#!/usr/bin/env bash
# SessionStart routing hook for Vibeboss source directory.
#
# VIBEBOSS_RENO=1 (set by reno.sh) → boot Vibe Chief (framework caretaker).
# Otherwise → emit polite redirect (Boss landed here by mistake).
#
# Both paths emit a hookSpecificOutput JSON with additionalContext populated.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VIBEBOSS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [ "${VIBEBOSS_RENO:-}" = "1" ]; then
  BRIEF_FILE="$VIBEBOSS_DIR/CHIEF.md"
else
  BRIEF_FILE="$SCRIPT_DIR/redirect.md"
fi

if [ ! -f "$BRIEF_FILE" ]; then
  # Hook should never silently produce empty output — CC complains.
  # Emit a minimal valid response so the session still boots.
  echo '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"(vibeboss SessionStart hook: brief file missing — check '"$BRIEF_FILE"')"}}'
  exit 0
fi

BRIEF_FILE="$BRIEF_FILE" python3 <<'PYEOF'
import json, os
with open(os.environ["BRIEF_FILE"]) as f:
    brief = f.read()
out = {
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": brief,
    }
}
print(json.dumps(out))
PYEOF
