#!/usr/bin/env bash
# Codex wrapper for the canonical Vibeboss HQ boot hook.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HQ="$(cd "$SCRIPT_DIR/../.." && pwd)"

exec "$HQ/.claude/hooks/boot.sh" "$@"
