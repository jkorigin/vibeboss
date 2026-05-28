#!/usr/bin/env bash
# Migration v0.2.2-dev -> v0.2.3-dev
#
# Two backfills:
#   1. follow-ups/framework/ + processed/ subdir (Boss → Vibe Chief feedback channel,
#      introduced in v0.2.3). README.md content is NOT created here — it lands via
#      init.sh --update's manifest refresh, which uses the canonical template under
#      templates/hq/follow-ups/framework/README.md. We only ensure directories +
#      .gitkeep markers exist so --update has a place to write into.
#   2. calibration/ + log.jsonl (estimate-honesty + calibration log, introduced in
#      v0.2.3). Same reasoning: README.md content lands via --update; the migration
#      just ensures the directory and empty log file exist.
#
# Also: records this workspace in <vibeboss>/.workspaces (the source-side workspace
# registry, also introduced in v0.2.3) so Vibe Chief can discover the workspace
# even if init.sh hasn't run since the feature shipped. Idempotent — appends only
# if the path isn't already listed.
#
# All operations idempotent. Re-running this migration is a no-op.

set -euo pipefail

WORKSPACE="${1:-}"
if [ -z "$WORKSPACE" ] || [ ! -d "$WORKSPACE" ]; then
  echo "error: migration v0.2.2-dev-to-v0.2.3-dev expects \$1 = existing workspace path" >&2
  exit 1
fi

HQ="$WORKSPACE/hq"
if [ ! -d "$HQ" ]; then
  echo "error: $HQ does not exist — workspace shape looks wrong" >&2
  exit 1
fi

# ── 1. follow-ups/framework/ + processed/ ────────────────────────────────────
FOLLOWUPS_FRAMEWORK="$HQ/follow-ups/framework"
FOLLOWUPS_PROCESSED="$FOLLOWUPS_FRAMEWORK/processed"

mkdir -p "$FOLLOWUPS_FRAMEWORK"
mkdir -p "$FOLLOWUPS_PROCESSED"

if [ ! -f "$FOLLOWUPS_FRAMEWORK/.gitkeep" ]; then
  : > "$FOLLOWUPS_FRAMEWORK/.gitkeep"
fi
if [ ! -f "$FOLLOWUPS_PROCESSED/.gitkeep" ]; then
  : > "$FOLLOWUPS_PROCESSED/.gitkeep"
fi

# ── 2. calibration/ + log.jsonl ──────────────────────────────────────────────
CALIBRATION="$HQ/calibration"
mkdir -p "$CALIBRATION"

if [ ! -f "$CALIBRATION/log.jsonl" ]; then
  : > "$CALIBRATION/log.jsonl"
fi

# ── 3. Record workspace in source-side registry ──────────────────────────────
# Derive the source repo path from this script's location: this script lives at
# <source>/migrations/<name>.sh, so <source> = $(dirname $0)/..
SOURCE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_WORKSPACES="$SOURCE_DIR/.workspaces"

if [ -f "$SOURCE_WORKSPACES" ] && grep -qxF "$WORKSPACE" "$SOURCE_WORKSPACES" 2>/dev/null; then
  : # already registered — nothing to do
else
  echo "$WORKSPACE" >> "$SOURCE_WORKSPACES"
fi

echo "migration v0.2.2-dev → v0.2.3-dev: backfilled follow-ups/framework + calibration directories; recorded workspace."
exit 0
