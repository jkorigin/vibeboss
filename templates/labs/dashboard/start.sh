#!/usr/bin/env bash
# start.sh — start the labs dashboard.
#
# Picks an open port starting at 3101 (3100 is reserved for the master dashboard
# per v0.1.0 canon), binds localhost only, writes the chosen port to
# .runtime/port for master-dashboard discovery.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check Bun
if ! command -v bun >/dev/null 2>&1; then
  echo "error: bun not found on PATH" >&2
  echo "  install: https://bun.sh" >&2
  echo "  then re-run this script." >&2
  exit 1
fi

# Resolve workspace root (this template will be at <workspace>/labs/dashboard/).
# Two levels up from script dir lands on <workspace>/.
WORKSPACE="$(cd "$SCRIPT_DIR/../.." && pwd)"
export WORKSPACE

mkdir -p "$SCRIPT_DIR/.runtime"

echo "Starting labs dashboard..."
echo "  workspace: $WORKSPACE"
echo ""

exec bun run server.ts
