#!/usr/bin/env bash
# compact-boot.sh — Vibeboss HQ post-compact context injector.
#
# Fires on SessionStart matcher="compact". Composes the standard boot brief
# (from boot.sh) followed by:
#   1. All pinned handovers (hq/handovers/_pinned/*.md, oldest first).
#      Pinned handovers are agent- or partner-written for things that must
#      survive across multiple compacts (keywords, hard decisions, identity
#      reminders). They are not overwritten by the rolling mechanism.
#   2. The rolling _current.md (overwritten at every compact by pre-compact.sh).
#
# Pinned-first ordering is deliberate: if context is large, the model reads
# top-down. Pinned content surfaces before topic-of-the-moment content from
# the rolling snapshot. This is what closes the keyword-displacement failure
# mode from the Stop-hook-only design.
#
# Emits JSON: { systemMessage, hookSpecificOutput: { hookEventName, additionalContext } }
# Both fields carry the same content for redundancy across CC versions.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HQ="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ---- 1. Standard boot brief ----
BOOT_BRIEF="$(bash "$SCRIPT_DIR/boot.sh" 2>/dev/null \
  | python3 -c "import json, sys; print(json.load(sys.stdin)['hookSpecificOutput']['additionalContext'])" \
  2>/dev/null || true)"
[ -z "$BOOT_BRIEF" ] && BOOT_BRIEF="(boot brief unavailable)"

# ---- 2. Pinned handovers ----
PINNED_BLOCK=""
PINNED_DIR="$HQ/handovers/_pinned"
if [ -d "$PINNED_DIR" ]; then
  # Collect all *.md files in _pinned/ sorted by filename (chronological if YYYY-MM-DD-...)
  shopt -s nullglob
  PINNED_FILES=( "$PINNED_DIR"/*.md )
  shopt -u nullglob
  if [ "${#PINNED_FILES[@]}" -gt 0 ]; then
    PINNED_BLOCK="
$(printf '\342\224\200%.0s' {1..35})
  PINNED HANDOVERS (must survive every compact)
$(printf '\342\224\200%.0s' {1..35})
"
    for f in "${PINNED_FILES[@]}"; do
      [ -f "$f" ] || continue
      PINNED_BLOCK+="
═══ File: $(basename "$f") ═══

$(cat "$f")
"
    done
  fi
fi

# ---- 3. Rolling handover (_current.md) ----
ROLLING_BLOCK=""
ROLLING_FILE="$HQ/handovers/_current.md"
if [ -f "$ROLLING_FILE" ]; then
  NOW_SEC="$(date +%s)"
  FILE_MTIME_SEC="$(stat -f %m "$ROLLING_FILE" 2>/dev/null || echo 0)"
  AGE_SEC=$(( NOW_SEC - FILE_MTIME_SEC ))
  # PreCompact writes _current.md at the moment of compaction, so age should be
  # seconds-to-minutes. If somehow older than 1 hour, still include it — the
  # rolling snapshot is always useful, freshness just affects confidence.
  AGE_NOTE=""
  if [ "$AGE_SEC" -gt 3600 ]; then
    AGE_NOTE=" (stale — $((AGE_SEC / 60)) min old; pre-compact hook may have misfired)"
  fi
  ROLLING_BLOCK="
$(printf '\342\224\200%.0s' {1..35})
  ROLLING HANDOVER — _current.md${AGE_NOTE}
$(printf '\342\224\200%.0s' {1..35})

$(cat "$ROLLING_FILE")
"
fi

# Compose full additionalContext
if [ -z "$PINNED_BLOCK" ] && [ -z "$ROLLING_BLOCK" ]; then
  FULL_CONTEXT="${BOOT_BRIEF}

$(printf '\342\224\200%.0s' {1..35})
  POST-COMPACT — NO HANDOVERS FOUND
$(printf '\342\224\200%.0s' {1..35})
Neither hq/handovers/_pinned/ nor hq/handovers/_current.md exists.
The pre-compact hook (pre-compact.sh) may have misfired or never installed.
Re-read STATE.md + most recent runlog to orient."
else
  FULL_CONTEXT="${BOOT_BRIEF}
${PINNED_BLOCK}
${ROLLING_BLOCK}

═══════════════════════════════════════
RESUME PROTOCOL (post-compact)
═══════════════════════════════════════
1. If any PINNED handover contains a keyword, test phrase, or instruction-to-
   say-verbatim, honour it on the FIRST response of this session — before
   greeting, before recap, before any other content.
2. Then resume from the most recent partner message in the ROLLING handover.
3. STATE.md + crew.yml are ground truth for project status; re-read if unsure."
fi

# Emit JSON — env var approach so python json.dumps handles escaping.
# Fallback: emit minimal valid JSON if python fails.
BRIEF_CONTENT="$FULL_CONTEXT" python3 - <<'PYEOF' || \
  python3 -c "import json; print(json.dumps({'hookSpecificOutput': {'hookEventName': 'SessionStart', 'additionalContext': '(compact-boot.sh: JSON emit failed)'}}))"
import json, os
ctx = os.environ["BRIEF_CONTENT"]
print(json.dumps({
    "systemMessage": ctx,
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": ctx
    }
}))
PYEOF
