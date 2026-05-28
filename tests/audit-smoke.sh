#!/usr/bin/env bash
# tests/audit-smoke.sh — CI wrapper for the sensitivity audit.
#
# Runs tools/audit/audit.sh in --tree mode against the current checkout.
# Used by .github/workflows/ci.yml to gate every push.
#
# Exit 0 if clean, 1 if findings.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
AUDIT="$REPO_ROOT/tools/audit/audit.sh"

if [ ! -x "$AUDIT" ]; then
  echo "FAIL: $AUDIT missing or not executable" >&2
  exit 1
fi

echo "Running sensitivity audit (--tree mode) ..."
echo ""

if "$AUDIT"; then
  echo ""
  echo "PASS: vibeboss sensitivity audit"
  exit 0
else
  echo ""
  echo "FAIL: vibeboss sensitivity audit — findings above must be redacted or allowlisted before this push can land."
  exit 1
fi
