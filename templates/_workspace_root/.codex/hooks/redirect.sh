#!/usr/bin/env bash
# SessionStart redirect for the Vibeboss workspace root in Codex.
#
# Emits the same additionalContext shape as the Claude Code hook. Codex adds
# hookSpecificOutput.additionalContext to developer context on SessionStart.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRIEF_FILE="$SCRIPT_DIR/redirect.md"

if [ ! -f "$BRIEF_FILE" ]; then
  echo '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"(vibeboss Codex SessionStart hook: redirect.md missing — cd to hq/ to talk to your lead)"}}'
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
