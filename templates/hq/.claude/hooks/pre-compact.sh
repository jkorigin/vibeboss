#!/usr/bin/env bash
# pre-compact.sh — Vibeboss HQ PreCompact hook.
#
# Fires immediately before Claude Code compacts the conversation (auto at ~100%
# context or manual via /compact). Writes a comprehensive snapshot to
# hq/handovers/_current.md by parsing the live pre-compact transcript.
#
# Why PreCompact and not Stop:
#   - Stop fires every turn. Each turn overwrites _current.md. By the time
#     compact fires, _current.md reflects the most recent turn — which is rarely
#     the most important context. Rich content from earlier in the session
#     (keywords, decisions) gets displaced.
#   - PreCompact fires at the EXACT moment of compaction. The transcript at
#     this moment is the full session. We can capture the last 30-50 turns,
#     grep wide for markers, and write a real "what mattered this session"
#     snapshot.
#
# Input (stdin, JSON from Claude Code):
#   { "session_id": "...",
#     "transcript_path": "<path>.jsonl",
#     "cwd": "...",
#     "hook_event_name": "PreCompact",
#     "trigger": "auto" | "manual",
#     "custom_instructions": "..." | null }
#
# Output: empty (or short status). On any error, exit 0 silently — never block
# compaction.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HQ="$(cd "$SCRIPT_DIR/../.." && pwd)"
HANDOVER_DIR="$HQ/handovers"
ROLLING_FILE="$HANDOVER_DIR/_current.md"

mkdir -p "$HANDOVER_DIR"

INPUT="$(cat 2>/dev/null || true)"

# Pass everything to python for parsing — easier than nested bash JSON handling.
INPUT="$INPUT" HQ="$HQ" ROLLING_FILE="$ROLLING_FILE" \
python3 - <<'PYEOF' 2>/dev/null || true
import json, os, re, sys
from pathlib import Path
from datetime import datetime

raw = os.environ.get("INPUT", "")
hq = Path(os.environ["HQ"])
rolling = Path(os.environ["ROLLING_FILE"])

try:
    payload = json.loads(raw) if raw else {}
except json.JSONDecodeError:
    payload = {}

transcript_path = payload.get("transcript_path", "")
session_id = payload.get("session_id", "")
trigger = payload.get("trigger", "unknown")
now = datetime.now().strftime("%Y-%m-%d %H:%M:%S %z") or datetime.now().strftime("%Y-%m-%d %H:%M:%S")

# ---- Parse transcript ----
user_turns = []      # list of (idx, text) — only real partner messages
assistant_turns = [] # list of (idx, text) — final assistant text per turn
turn_idx = 0

def extract_text_from_content(content):
    """CC transcript content can be str or list of blocks."""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for block in content:
            if isinstance(block, dict):
                if block.get("type") == "text":
                    parts.append(block.get("text", ""))
            elif isinstance(block, str):
                parts.append(block)
        return "\n".join(parts)
    return ""

if transcript_path and Path(transcript_path).exists():
    try:
        with open(transcript_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    entry = json.loads(line)
                except json.JSONDecodeError:
                    continue
                t = entry.get("type")
                msg = entry.get("message", {})
                if t == "user":
                    content = extract_text_from_content(msg.get("content", ""))
                    if not content or not content.strip():
                        continue
                    # Skip tool results and system reminders — those are not user input
                    skip_patterns = [
                        "<system-reminder>",
                        "Result of calling",
                        "tool_use_id",
                        "<command-name>",
                    ]
                    if any(p in content[:300] for p in skip_patterns):
                        continue
                    user_turns.append((turn_idx, content))
                    turn_idx += 1
                elif t == "assistant":
                    content = extract_text_from_content(msg.get("content", ""))
                    if content and content.strip():
                        assistant_turns.append((turn_idx, content))
    except Exception:
        pass

# ---- Build the rolling handover ----
LAST_N_USER = 8        # last 8 partner messages verbatim
LAST_N_ASSISTANT = 3   # last 3 agent responses (truncated)
MARKER_LIMIT = 50      # grep marker lines from full session

# Wide marker capture: anchored prefixes + quoted phrases + emphasis patterns
marker_patterns = [
    re.compile(r"(KEYWORD|REMEMBER|TODO|HANDOVER|PARTNER ASK|DON'?T FORGET|IMPORTANT|CRITICAL|NOTE)[:\s]", re.IGNORECASE),
    re.compile(r'you (will|should|must) say [\'"]([^\'"]+)[\'"]', re.IGNORECASE),
    re.compile(r'remember [\'"]([^\'"]+)[\'"]', re.IGNORECASE),
    re.compile(r"(test|validate|verify) (.*?)keyword", re.IGNORECASE),
]

markers = []
for idx, text in user_turns:
    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue
        for pat in marker_patterns:
            if pat.search(line):
                markers.append(f"[turn {idx}] {line}")
                break

# Dedupe preserving order, keep last MARKER_LIMIT
seen = set()
markers_uniq = []
for m in markers:
    if m not in seen:
        seen.add(m)
        markers_uniq.append(m)
markers_uniq = markers_uniq[-MARKER_LIMIT:]

def truncate(s, n):
    if not s:
        return "(empty)"
    s = s.strip()
    if len(s) <= n:
        return s
    return s[:n].rstrip() + f"\n\n... [truncated, full was {len(s)} chars]"

# Last N user turns verbatim
last_users_block = []
for idx, text in user_turns[-LAST_N_USER:]:
    last_users_block.append(f"### Turn {idx} — partner\n\n{truncate(text, 1500)}")
last_users_text = "\n\n".join(last_users_block) if last_users_block else "(no captured partner turns)"

# Last N assistant turns truncated
last_assist_block = []
for idx, text in assistant_turns[-LAST_N_ASSISTANT:]:
    last_assist_block.append(f"### Turn {idx} — agent\n\n{truncate(text, 2000)}")
last_assist_text = "\n\n".join(last_assist_block) if last_assist_block else "(no captured agent turns)"

# Markers block
if markers_uniq:
    markers_text = "\n".join(f"- {m}" for m in markers_uniq)
else:
    markers_text = "(none captured — partner did not emphasize anything via marker patterns this session)"

# Session counts
content = f"""# Rolling Handover — auto-written by PreCompact hook at moment of compaction

**Written:** {now}
**Trigger:** `{trigger}` (auto = CC hit context limit; manual = partner ran /compact)
**Session id (pre-compact):** `{session_id or 'unknown'}`
**Source:** `hq/.claude/hooks/pre-compact.sh`
**Turn counts:** {len(user_turns)} partner turns, {len(assistant_turns)} agent turns

This file is overwritten at every compact moment. The hook fires AT the moment
of compaction (not earlier and not later), so this snapshot captures the full
session as it was at the boundary. On the post-compact session,
`compact-boot.sh` injects this file as additional context.

Rich, durable handovers that should survive multiple compacts live in
`hq/handovers/_pinned/*.md` — `compact-boot.sh` injects those FIRST,
followed by this rolling snapshot. Use `_pinned/` for keywords, hard
decisions, anything that must not be displaced by topic drift.

---

## Markers grepped across the session

These are lines from partner turns matching marker patterns (KEYWORD:, REMEMBER:,
"you will say 'X'", emphasized phrases, etc.). If a keyword test or critical
instruction was issued this session, it should appear below.

{markers_text}

---

## Last {LAST_N_USER} partner messages (verbatim, oldest first within window)

{last_users_text}

---

## Last {LAST_N_ASSISTANT} agent responses (truncated, oldest first)

{last_assist_text}

---

## Resume action on post-compact reboot

1. **First**: check `## Markers grepped` above. If any marker mentions a keyword,
   test phrase, or instruction-to-say-verbatim, honour it on the FIRST response
   of the post-compact session — before anything else.
2. Read `hq/handovers/_pinned/` for any pinned handovers from earlier sessions.
3. Read `hq/STATE.md` and `hq/crew.yml` for ground truth.
4. Resume from the most recent partner message in "Last partner messages" above.
"""

try:
    rolling.write_text(content, encoding="utf-8")
except Exception:
    pass
PYEOF

# Don't emit anything to stdout — CC would prepend it as PreCompact display message
# and it would add noise. Pure side-effect (file write) is what we want.
exit 0
