#!/usr/bin/env bash
# tools/install-hooks.sh — Install Vibeboss git hooks into this clone's .git/hooks/.
#
# Hooks installed:
#   - pre-commit  — runs the sensitivity audit (tools/audit/audit.sh --staged)
#                    before each commit. Blocks commit if sensitive shapes are
#                    detected in staged content.
#
# Idempotent: re-running overwrites the installed hooks with the latest
# source-controlled versions.
#
# Usage:
#   bash tools/install-hooks.sh        # install all available hooks
#   bash tools/install-hooks.sh --check # verify hooks are installed and current

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_HOOK_DIR="$SCRIPT_DIR/hooks"
TARGET_HOOK_DIR="$REPO_ROOT/.git/hooks"

if [ ! -d "$TARGET_HOOK_DIR" ]; then
  echo "error: $TARGET_HOOK_DIR not found. Are you in a git repo?" >&2
  exit 1
fi

MODE="install"
case "${1:-}" in
  --check) MODE="check" ;;
  -h|--help)
    grep -E "^# " "$0" | sed 's/^# *//'
    exit 0
    ;;
esac

INSTALLED=0
CHECK_FAIL=0

for hook in "$SOURCE_HOOK_DIR"/*; do
  [ -f "$hook" ] || continue
  hook_name="$(basename "$hook")"
  target="$TARGET_HOOK_DIR/$hook_name"

  if [ "$MODE" = "check" ]; then
    if [ ! -f "$target" ]; then
      echo "  MISSING: $hook_name"
      CHECK_FAIL=1
    elif ! diff -q "$hook" "$target" >/dev/null 2>&1; then
      echo "  STALE:   $hook_name (differs from $SOURCE_HOOK_DIR)"
      CHECK_FAIL=1
    else
      echo "  OK:      $hook_name"
    fi
    continue
  fi

  cp "$hook" "$target"
  chmod +x "$target"
  echo "  installed: $hook_name -> $target"
  INSTALLED=$((INSTALLED + 1))
done

if [ "$MODE" = "check" ]; then
  if [ "$CHECK_FAIL" -ne 0 ]; then
    echo ""
    echo "Some hooks are missing or stale. Run: bash tools/install-hooks.sh"
    exit 1
  fi
  echo ""
  echo "All hooks installed and current."
  exit 0
fi

echo ""
echo "Installed $INSTALLED hook(s) into $TARGET_HOOK_DIR/"
echo ""
echo "The pre-commit hook will run tools/audit/audit.sh on every git commit."
echo "If you push framework changes, the same audit runs in CI as a backup."
