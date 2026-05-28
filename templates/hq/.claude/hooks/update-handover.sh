#!/usr/bin/env bash
# update-handover.sh — Vibeboss HQ rolling-handover mechanism.
#
# Fires on Stop (assistant turn ends). Writes hq/handovers/_current.md so that
# at any moment, if Claude Code auto-compacts (CC fires PreCompact + SessionStart
# matcher="compact"), the post-compact handover injector (compact-boot.sh) has
# a fresh handover to inject. Zero agent self-discipline required.
#
# Input (stdin, JSON from Claude Code):
#   { "session_id": "...", "transcript_path": "<path>.jsonl", "stop_hook_active": bool }
#
# Output: nothing to stdout (Stop hooks don't need to emit JSON unless blocking).
# Writes hq/handovers/_current.md as a side effect.
#
# Safety: never blocks the assistant. On any error, exit 0 silently.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HQ="$(cd "$SCRIPT_DIR/../.." && pwd)"
HANDOVER_DIR="$HQ/handovers"
ROLLING_FILE="$HANDOVER_DIR/_current.md"

mkdir -p "$HANDOVER_DIR"

# Read stdin (JSON from Claude Code). If empty/malformed, fall back to "no transcript".
INPUT="$(cat 2>/dev/null || true)"

TRANSCRIPT_PATH=""
SESSION_ID=""
if [ -n "$INPUT" ]; then
  TRANSCRIPT_PATH="$(printf '%s' "$INPUT" | python3 -c "
import json, sys
try:
    d = json.loads(sys.stdin.read())
    print(d.get('transcript_path', ''))
except Exception:
    print('')
" 2>/dev/null || true)"
  SESSION_ID="$(printf '%s' "$INPUT" | python3 -c "
import json, sys
try:
    d = json.loads(sys.stdin.read())
    print(d.get('session_id', ''))
except Exception:
    print('')
" 2>/dev/null || true)"
fi

NOW="$(date '+%Y-%m-%d %H:%M:%S %Z')"

# Build the rolling handover. Use python3 to parse JSONL safely.
TRANSCRIPT_PATH="$TRANSCRIPT_PATH" SESSION_ID="$SESSION_ID" NOW="$NOW" \
ROLLING_FILE="$ROLLING_FILE" HQ="$HQ" \
python3 - <<'PYEOF' 2>/dev/null || true
import json, os, re, sys
from pathlib import Path

transcript = os.environ.get("TRANSCRIPT_PATH", "")
session_id = os.environ.get("SESSION_ID", "")
now = os.environ.get("NOW", "")
rolling = Path(os.environ["ROLLING_FILE"])
hq = Path(os.environ["HQ"])

last_user = ""
last_assistant = ""
all_user_msgs = []  # for marker grep

if transcript and Path(transcript).exists():
    try:
        with open(transcript, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    entry = json.loads(line)
                except json.JSONDecodeError:
                    continue
                # CC transcript format: each line has "type" and "message"
                t = entry.get("type")
                msg = entry.get("message", {})
                if t == "user":
                    # message.content can be str or list of content blocks
                    content = msg.get("content", "")
                    if isinstance(content, list):
                        text_parts = []
                        for block in content:
                            if isinstance(block, dict) and block.get("type") == "text":
                                text_parts.append(block.get("text", ""))
                            elif isinstance(block, str):
                                text_parts.append(block)
                        content = "\n".join(text_parts)
                    if isinstance(content, str) and content.strip():
                        # Skip tool-result echo-back (large, not user input)
                        if not content.startswith("<system-reminder>") and \
                           not content.startswith("Result of calling") and \
                           "tool_use_id" not in content[:200]:
                            last_user = content
                            all_user_msgs.append(content)
                elif t == "assistant":
                    content = msg.get("content", "")
                    if isinstance(content, list):
                        text_parts = []
                        for block in content:
                            if isinstance(block, dict) and block.get("type") == "text":
                                text_parts.append(block.get("text", ""))
                        content = "\n".join(text_parts)
                    if isinstance(content, str) and content.strip():
                        last_assistant = content
    except Exception:
        pass

# Truncate to keep handover bounded
def truncate(s, n):
    if not s:
        return "(none)"
    s = s.strip()
    if len(s) <= n:
        return s
    return s[:n] + f"\n\n... [truncated, full was {len(s)} chars]"

last_user_t = truncate(last_user, 2000)
last_assistant_t = truncate(last_assistant, 3000)

# Grep markers across all user messages
marker_re = re.compile(r"(KEYWORD|REMEMBER|TODO|HANDOVER|PARTNER ASK|DON'T FORGET|IMPORTANT):", re.IGNORECASE)
markers = []
for m in all_user_msgs:
    for line in m.splitlines():
        if marker_re.search(line):
            markers.append(line.strip())
# Dedupe preserving order
seen = set()
markers_uniq = []
for m in markers:
    if m not in seen:
        seen.add(m)
        markers_uniq.append(m)
markers_block = "\n".join(f"- {m}" for m in markers_uniq[-30:]) if markers_uniq else "(none flagged this session)"

content = f"""# Rolling Handover — auto-updated each turn by Stop hook

**Last updated:** {now}
**Session:** `{session_id or '(unknown)'}`
**Source:** `hq/.claude/hooks/update-handover.sh`

This file is overwritten every time the assistant finishes a turn. If Claude
Code auto-compacts, `compact-boot.sh` injects this file as additional context
so the post-compact session resumes without losing state. Zero agent
self-discipline required — the mechanism enforces it.

## Last partner message

{last_user_t}

## Last agent response (truncated)

{last_assistant_t}

## Markers grepped from this session

{markers_block}

## Resume action

1. Re-read `hq/STATE.md` and `hq/crew.yml`.
2. Continue from the "Last partner message" above.
3. Honour any markers flagged above (KEYWORD / REMEMBER / TODO / PARTNER ASK).
"""

try:
    rolling.write_text(content, encoding="utf-8")
except Exception:
    pass
PYEOF

exit 0
