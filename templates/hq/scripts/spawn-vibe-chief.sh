#!/usr/bin/env bash
# spawn-vibe-chief.sh — Boss-side dispatcher for a background Vibe Chief session.
#
# Per LESSON-010 (dispatch-vibe-chief SOP): when Boss has framework work to send
# to Vibe Chief and partner doesn't want to context-switch to run `bash reno.sh`,
# Boss can spawn a background Vibe Chief that executes the work autonomously.
#
# Safety:
#   1. Detects active Vibe Chief sessions (claude processes with vibeboss/ cwd).
#      Exits 2 with an advisory message if any found — Boss must ask partner to
#      relay context to the active session instead, per partner's clash-avoidance
#      rule.
#   2. Cleans env per WA-PA-LESSON-004: unsets empty ANTHROPIC_API_KEY so the
#      spawned process uses subscription auth, not API-tier billing.
#   3. Backgrounds the spawn. Logs to hq/spawns/vibechief-<timestamp>.log so Boss
#      can tail and report results.
#
# Usage:
#   bash hq/scripts/spawn-vibe-chief.sh "<initial prompt>"
#   bash hq/scripts/spawn-vibe-chief.sh --task-file <path-to-follow-up-md>
#
# The common pattern is to point Vibe Chief at a follow-up brief in
# hq/follow-ups/framework/ that documents the port work. Vibe Chief reads the
# file, executes all steps, commits, and disposition-blocks the file into
# processed/.
#
# Exit codes:
#   0 — spawn launched successfully (background PID printed to stdout)
#   1 — usage / setup error (e.g., vibeboss/ not found, claude CLI missing)
#   2 — active Vibe Chief session detected, refused to spawn (clash avoidance)

set -uo pipefail

# Resolve the Vibeboss source dir from this workspace.
# Standard layout: workspace at ~/ventures/vibeboss-workspace/, source at ~/ventures/vibeboss/.
# Allow override via $VIBEBOSS_SOURCE for non-standard installs.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HQ_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_DIR="$(cd "$HQ_DIR/.." && pwd)"

# Resolution order:
#   1. $VIBEBOSS_SOURCE env override (highest priority)
#   2. $WORKSPACE_DIR/.vibeboss-version → source_path field (v0.2.2+ installs)
#   3. Sibling-dir heuristic: $WORKSPACE_DIR/../vibeboss/ (standard layout)
#   4. Hard-coded fallback: $HOME/ventures/vibeboss/
if [ -n "${VIBEBOSS_SOURCE:-}" ]; then
  VIBEBOSS_DIR="$VIBEBOSS_SOURCE"
elif [ -f "$WORKSPACE_DIR/.vibeboss-version" ]; then
  VIBEBOSS_DIR="$(grep '^source_path:' "$WORKSPACE_DIR/.vibeboss-version" 2>/dev/null | sed 's/^source_path: *//' | head -1)"
fi

# Sibling-dir fallback
if [ -z "${VIBEBOSS_DIR:-}" ] || [ ! -f "${VIBEBOSS_DIR:-}/CHIEF.md" ]; then
  SIBLING_GUESS="$(cd "$WORKSPACE_DIR/.." 2>/dev/null && pwd)/vibeboss"
  if [ -f "$SIBLING_GUESS/CHIEF.md" ]; then
    VIBEBOSS_DIR="$SIBLING_GUESS"
  fi
fi

# Final hard-coded fallback
if [ -z "${VIBEBOSS_DIR:-}" ] || [ ! -f "${VIBEBOSS_DIR:-}/CHIEF.md" ]; then
  if [ -f "$HOME/ventures/vibeboss/CHIEF.md" ]; then
    VIBEBOSS_DIR="$HOME/ventures/vibeboss"
  fi
fi

if [ -z "${VIBEBOSS_DIR:-}" ] || [ ! -f "$VIBEBOSS_DIR/CHIEF.md" ]; then
  echo "error: cannot locate Vibeboss source dir. Tried:" >&2
  echo "       \$VIBEBOSS_SOURCE (unset or invalid)" >&2
  echo "       $WORKSPACE_DIR/.vibeboss-version source_path (missing or invalid)" >&2
  echo "       $WORKSPACE_DIR/../vibeboss/ (sibling-dir heuristic)" >&2
  echo "       $HOME/ventures/vibeboss/ (hard-coded fallback)" >&2
  echo "       Set \$VIBEBOSS_SOURCE explicitly and retry." >&2
  exit 1
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "error: 'claude' CLI not on PATH." >&2
  exit 1
fi

# ---- usage parsing ----
TASK_PROMPT=""
TASK_FILE=""
if [ "${1:-}" = "--task-file" ]; then
  TASK_FILE="${2:-}"
  if [ -z "$TASK_FILE" ] || [ ! -f "$TASK_FILE" ]; then
    echo "error: --task-file requires a valid path." >&2
    exit 1
  fi
  TASK_PROMPT="Read and execute every task documented in this file: $TASK_FILE

You are Vibe Chief — operate under the discipline in $VIBEBOSS_DIR/CHIEF.md (the SessionStart hook should have loaded this; if not, read it first).

Execute all port tasks listed in the follow-up brief. Commit changes (the prepare-commit-msg hook in vibeboss/ rewrites the trailer automatically). After completion, append a ## Disposition block to the follow-up file (verdict, files changed, commit sha, any deferred items) and move the file from hq/follow-ups/framework/ to hq/follow-ups/framework/processed/.

Report a one-paragraph summary to stdout."
elif [ -n "${1:-}" ]; then
  TASK_PROMPT="$1"
else
  cat <<EOF >&2
usage:
  bash hq/scripts/spawn-vibe-chief.sh "<initial prompt>"
  bash hq/scripts/spawn-vibe-chief.sh --task-file <path-to-follow-up.md>

Spawns a background Vibe Chief session in $VIBEBOSS_DIR. Logs to
$HQ_DIR/spawns/vibechief-<timestamp>.log.
EOF
  exit 1
fi

# ---- active-session detection ----
# Find claude processes with cwd == vibeboss/. If any exist, refuse to spawn.
ACTIVE_PIDS="$(lsof -c claude 2>/dev/null | awk -v dir="$VIBEBOSS_DIR" '$4=="cwd" && $NF==dir {print $2}' | sort -u | tr '\n' ' ')"

if [ -n "$ACTIVE_PIDS" ]; then
  cat <<EOF >&2
ACTIVE_VIBE_CHIEF_DETECTED
Active claude process(es) with cwd at $VIBEBOSS_DIR: $ACTIVE_PIDS
Refusing to spawn — clash risk.

Boss should surface this to partner and ask them to relay context to the active
Vibe Chief session, instead of starting a parallel one. The relay message
should reference the task file or the work briefing.
EOF
  exit 2
fi

# ---- spawn ----
mkdir -p "$HQ_DIR/spawns"
TS="$(date +%Y%m%d-%H%M%S)"
LOG="$HQ_DIR/spawns/vibechief-$TS.log"

# Clean env (subscription auth safety per WA-PA-LESSON-004)
unset ANTHROPIC_API_KEY

(
  cd "$VIBEBOSS_DIR"
  VIBEBOSS_RENO=1 claude -p "$TASK_PROMPT" > "$LOG" 2>&1
) &
SPAWN_PID=$!

echo "spawned Vibe Chief PID=$SPAWN_PID"
echo "cwd=$VIBEBOSS_DIR"
echo "log=$LOG"
echo "task-file=${TASK_FILE:-<inline-prompt>}"
echo ""
echo "Tail the log: tail -f \"$LOG\""
echo "Check status:  ps -p $SPAWN_PID >/dev/null && echo running || echo finished"
exit 0
