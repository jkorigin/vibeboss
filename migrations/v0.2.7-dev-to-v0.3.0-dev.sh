#!/usr/bin/env bash
# Migration v0.2.7-dev → v0.3.0-dev
#
# Backfills the autonomous research-loop scaffold + the labs review dashboard
# into existing workspaces:
#
#   - labs/skills/research/SKILL.md         (research methodology)
#   - labs/_templates/{hypothesis,finding,handoff}.md  (artifact templates)
#   - labs/dashboard/*                       (Bun-served review UI)
#
# Idempotent. Detects missing files and writes them. Existing files are left
# alone (the manifest-driven --update flow handles content drift; this migration
# only handles structural additions).
#
# Per the framework's migration discipline: this script's effects are scoped to
# what fresh installs would scaffold via init.sh. No data is touched.

set -euo pipefail

WORKSPACE="${1:-}"
if [ -z "$WORKSPACE" ] || [ ! -d "$WORKSPACE" ]; then
  echo "error: migration v0.2.7-dev-to-v0.3.0-dev expects \$1 = existing workspace path" >&2
  exit 1
fi

LABS="$WORKSPACE/labs"
if [ ! -d "$LABS" ]; then
  echo "  skip: $LABS not present (workspace predates labs); nothing to backfill"
  exit 0
fi

CREATED=0

# Methodology skill + artifact templates
mkdir -p "$LABS/skills/research" "$LABS/_templates"

# Dashboard skeleton
mkdir -p "$LABS/dashboard/public" "$LABS/dashboard/.runtime"

# .gitkeep so the runtime port-file directory survives empty
if [ ! -f "$LABS/dashboard/.runtime/.gitkeep" ]; then
  touch "$LABS/dashboard/.runtime/.gitkeep"
  CREATED=$((CREATED + 1))
fi

# Note: actual file contents (SKILL.md, finding.md, dashboard server.ts etc.)
# are populated by `init.sh --update --noninteractive` after this migration
# runs. The manifest-driven refresh handles the writes; this migration just
# ensures the directories exist so the writes have somewhere to land.

# Workspace-root .gitignore: ignore the dashboard runtime port file
GITIGNORE="$WORKSPACE/.gitignore"
if [ -f "$GITIGNORE" ]; then
  if ! grep -qF "labs/dashboard/.runtime/" "$GITIGNORE" 2>/dev/null; then
    {
      echo ""
      echo "# v0.3.0 — labs dashboard runtime state (port file, etc.)"
      echo "labs/dashboard/.runtime/"
    } >> "$GITIGNORE"
    CREATED=$((CREATED + 1))
  fi
fi

echo "migration v0.2.7-dev → v0.3.0-dev: $CREATED structural change(s) applied; run \`bash <source>/init.sh --update --workspace $WORKSPACE\` to populate file contents."
exit 0
