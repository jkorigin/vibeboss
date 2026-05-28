#!/usr/bin/env bash
# Codex SessionStart routing hook for Vibeboss source directory.
#
# In Claude Code, Vibe Chief is activated by reno.sh. In Codex, the active
# project-local surface is .codex/hooks.json + AGENTS.md, so starting Codex at
# the Vibeboss source root is treated as framework-dev mode and loads CHIEF.md.
#
# Emits hookSpecificOutput.additionalContext, which Codex adds to developer
# context on SessionStart.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VIBEBOSS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
BRIEF_FILE="$VIBEBOSS_DIR/CHIEF.md"

if [ ! -f "$BRIEF_FILE" ]; then
  # Hook should never silently produce empty output.
  # Emit a minimal valid response so the session still boots.
  echo '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"(vibeboss Codex SessionStart hook: CHIEF.md missing — check '"$BRIEF_FILE"')"}}'
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
