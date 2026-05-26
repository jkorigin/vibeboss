#!/usr/bin/env bash
# SessionStart redirect for the Vibeboss workspace root.
#
# Fires when a user accidentally cd's to the workspace root and starts
# `claude` there instead of inside hq/. Emits a friendly redirect
# explaining that the lead lives in hq/, with copy-pastable next steps.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRIEF_FILE="$SCRIPT_DIR/redirect.md"

if [ ! -f "$BRIEF_FILE" ]; then
  # Never emit empty output — CC complains and the session boot stutters.
  echo '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"(vibeboss workspace SessionStart hook: redirect.md missing — cd to hq/ to talk to your lead)"}}'
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
