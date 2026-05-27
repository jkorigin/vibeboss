#!/usr/bin/env bash
# Vibe Chief entry point.
#
# Run this from anywhere; it cd's to the Vibeboss source directory and boots a
# Claude Code session in framework-dev mode (Vibe Chief, not HQ runtime Boss).
#
# Usage:
#   bash reno.sh                        # interactive Vibe Chief session
#   bash reno.sh --help                 # show this
#   bash reno.sh --version              # print framework version
#
# What it does:
#   1. Resolves the Vibeboss source dir (where this script lives).
#   2. Sets VIBEBOSS_RENO=1 so the SessionStart hook knows to boot Vibe Chief.
#   3. cd's to the source dir.
#   4. Launches `claude` interactively. CC auto-loads CLAUDE.md and fires the
#      SessionStart hook with the env var present — the hook routes to Vibe Chief.

set -euo pipefail

VIBEBOSS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  cat <<'EOF'
Vibe Chief — framework canon caretaker for Vibeboss.

Usage:  bash reno.sh

This launches a Claude Code session at the Vibeboss source root with Vibe
Chief's discipline loaded. Use it when you want to enhance the framework
itself (fix a bug in init.sh, update a template, ship a new skill to the
templates, write a decision file, bump CHANGELOG, etc.).

For daily HQ runtime work, use Boss instead: cd to your vibeboss-workspace/hq/
and run `claude` there.
EOF
  exit 0
fi

if [ "${1:-}" = "--version" ] || [ "${1:-}" = "-v" ]; then
  cat "$VIBEBOSS_DIR/VERSION"
  exit 0
fi

# Sanity check we're actually at a Vibeboss source repo
if [ ! -f "$VIBEBOSS_DIR/CHIEF.md" ] || [ ! -f "$VIBEBOSS_DIR/init.sh" ]; then
  echo "error: $VIBEBOSS_DIR doesn't look like a Vibeboss source tree (missing CHIEF.md or init.sh)" >&2
  echo "       reno.sh must be run from inside a Vibeboss clone." >&2
  exit 1
fi

cd "$VIBEBOSS_DIR"

# Check `claude` is available
if ! command -v claude >/dev/null 2>&1; then
  echo "error: 'claude' CLI not found on PATH." >&2
  echo "       Install Claude Code first: https://docs.claude.com/claude-code" >&2
  exit 1
fi

# Set the routing flag the SessionStart hook detects
export VIBEBOSS_RENO=1

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Booting Vibe Chief"
echo "  Vibeboss source at: $VIBEBOSS_DIR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Loading framework-dev discipline. The SessionStart hook will print"
echo "Vibe Chief's boot brief on the first turn."
echo ""

# Launch CC. settings.json uses ${CLAUDE_PROJECT_DIR} — no path substitution needed.
claude

# end of reno.sh
