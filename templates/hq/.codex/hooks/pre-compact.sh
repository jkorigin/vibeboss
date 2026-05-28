#!/usr/bin/env bash
# Codex wrapper for the canonical Vibeboss PreCompact hook.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HQ="$(cd "$SCRIPT_DIR/../.." && pwd)"

exec "$HQ/.claude/hooks/pre-compact.sh" "$@"
