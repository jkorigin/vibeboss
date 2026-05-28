#!/usr/bin/env bash
# Migration v0.2.5-dev → v0.2.6-dev
#
# Replaces the v0.2.4 Stop-hook compact-handover design (failed live keyword test)
# with the v0.2.6 PreCompact + pinned/rolling design (verified live).
#
# What this does (idempotent):
#   1. mkdir -p <workspace>/hq/handovers/_pinned/
#   2. Removes <workspace>/hq/.claude/hooks/update-handover.sh IF hash matches the
#      installed-original (i.e. user did not customize it). Otherwise leaves it
#      alone with a warning.
#   3. Leaves pre-compact.sh + compact-boot.sh refresh to the manifest-driven
#      update flow in init.sh --update (those files have hash entries in
#      .vibeboss/originals/ and will be refreshed there).
#   4. Prints a one-liner status.
#
# See decisions/2026-05-28-precompact-handover-mechanism.md for the full design.

set -euo pipefail

WORKSPACE="${1:-}"
if [ -z "$WORKSPACE" ] || [ ! -d "$WORKSPACE" ]; then
  echo "error: migration v0.2.5-dev-to-v0.2.6-dev expects \$1 = existing workspace path" >&2
  exit 1
fi

HQ="$WORKSPACE/hq"
if [ ! -d "$HQ" ]; then
  echo "error: workspace at $WORKSPACE has no hq/ directory; migration cannot proceed" >&2
  exit 1
fi

# 1. Pinned handovers directory
mkdir -p "$HQ/handovers/_pinned"

# 2. Remove update-handover.sh if it exists and hash matches the installed-original
#    (i.e. user did not customize it). Custom modifications are preserved.
STOP_HOOK="$HQ/.claude/hooks/update-handover.sh"
ORIG_HASH="$WORKSPACE/.vibeboss/originals/hq/.claude/hooks/update-handover.sh.sha256"

if [ -f "$STOP_HOOK" ]; then
  if [ -f "$ORIG_HASH" ]; then
    stored="$(cat "$ORIG_HASH" 2>/dev/null | tr -d '[:space:]')"
    current="$(shasum -a 256 "$STOP_HOOK" 2>/dev/null | cut -d' ' -f1 || sha256sum "$STOP_HOOK" 2>/dev/null | cut -d' ' -f1)"
    if [ "$stored" = "$current" ]; then
      rm -f "$STOP_HOOK"
      rm -f "$ORIG_HASH"
      echo "  removed: hq/.claude/hooks/update-handover.sh (matched installed-original)"
    else
      echo "  kept: hq/.claude/hooks/update-handover.sh (you customized it; manual removal needed if no longer wanted)"
    fi
  else
    # Legacy install with no manifest entry — adopt current as authoritative, leave file alone
    echo "  kept: hq/.claude/hooks/update-handover.sh (no original hash recorded; not auto-removing)"
  fi
fi

echo "migration v0.2.5-dev → v0.2.6-dev: PreCompact handover mechanism scaffolded; Stop hook (update-handover.sh) cleared if uncustomized. See decisions/2026-05-28-precompact-handover-mechanism.md."
exit 0
