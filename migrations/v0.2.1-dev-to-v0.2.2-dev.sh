#!/usr/bin/env bash
# Migration v0.2.1-dev -> v0.2.2-dev
#
# Adds the .vibeboss-version + .vibeboss/originals/ manifest infrastructure
# to workspaces installed before that schema existed. Idempotent.
set -euo pipefail
WORKSPACE="${1:-}"
if [ -z "$WORKSPACE" ] || [ ! -d "$WORKSPACE" ]; then
  echo "error: migration v0.2.1-dev-to-v0.2.2-dev expects \$1 = existing workspace path" >&2
  exit 1
fi

# No structural changes required for this transition — the manifest schema
# is added by init.sh --update itself, not by migration. This migration
# exists as a placeholder demonstrating the convention.

echo "migration v0.2.1-dev -> v0.2.2-dev: no structural changes (manifest schema added by --update directly)"
exit 0
