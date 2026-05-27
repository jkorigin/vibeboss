#!/usr/bin/env bash
# tests/init-smoke.sh — smoke test for `bash init.sh` end-to-end.
#
# Scaffolds a temp workspace via init.sh in noninteractive mode, then verifies
# the expected files exist, the boot hook emits valid JSON, and no unresolved
# `{{...}}` placeholders remain in generated markdown.
#
# Usage: bash tests/init-smoke.sh   (run from anywhere; resolves repo root)
set -euo pipefail

# ─── Locate repo root ────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ ! -f "$REPO_DIR/init.sh" ]; then
  echo "FAIL: could not find init.sh at $REPO_DIR/init.sh" >&2
  exit 1
fi

# ─── Temp workspace + cleanup ────────────────────────────────────────────────
TMPWS="${TMPDIR:-/tmp}/vibeboss-smoke-$$"
TMPWS="${TMPWS%/}"

cleanup() {
  rm -rf "$TMPWS"
}
trap cleanup EXIT

# ─── Failure collection ──────────────────────────────────────────────────────
FAILURES=()

fail() {
  FAILURES+=("$1")
}

check_file() {
  local path="$1"
  if [ ! -f "$path" ]; then
    fail "missing file: $path"
  fi
}

check_exec() {
  local path="$1"
  if [ ! -f "$path" ]; then
    fail "missing file: $path"
  elif [ ! -x "$path" ]; then
    fail "not executable: $path"
  fi
}

# ─── Run init.sh ─────────────────────────────────────────────────────────────
echo "Running: bash init.sh --noninteractive --name 'Smoke Test' --email 'smoke@test.local' --workspace '$TMPWS'"

set +e
bash "$REPO_DIR/init.sh" \
  --noninteractive \
  --name "Smoke Test" \
  --email "smoke@test.local" \
  --workspace "$TMPWS"
INIT_STATUS=$?
set -e

if [ "$INIT_STATUS" -ne 0 ]; then
  echo "FAIL: init.sh exited with status $INIT_STATUS" >&2
  echo "FAIL: vibeboss init smoke test" >&2
  exit 1
fi

# ─── Verify expected files exist ─────────────────────────────────────────────
check_file "$TMPWS/hq/CLAUDE.md"
check_file "$TMPWS/hq/lessons.md"
check_file "$TMPWS/hq/crew.yml"
check_file "$TMPWS/hq/STATE.md"
check_file "$TMPWS/hq/.claude/settings.json"
check_exec "$TMPWS/hq/.claude/hooks/boot.sh"
check_exec "$TMPWS/hq/.claude/hooks/compact-boot.sh"
check_file "$TMPWS/hq/skills/dev-workflow/SKILL.md"
check_file "$TMPWS/hq/skills/compact-handover/SKILL.md"
check_file "$TMPWS/labs/README.md"
check_file "$TMPWS/labs/crew.yml"
check_file "$TMPWS/labs/STATE.md"
check_file "$TMPWS/.claude/settings.json"
check_exec "$TMPWS/.claude/hooks/redirect.sh"

# ─── Verify boot hook emits valid JSON ───────────────────────────────────────
if [ -x "$TMPWS/hq/.claude/hooks/boot.sh" ]; then
  set +e
  BOOT_OUT="$("$TMPWS/hq/.claude/hooks/boot.sh" 2>/dev/null)"
  BOOT_STATUS=$?
  set -e
  if [ "$BOOT_STATUS" -ne 0 ]; then
    fail "boot hook exited with status $BOOT_STATUS"
  else
    if ! printf '%s' "$BOOT_OUT" | python3 -c "import json,sys; d=json.load(sys.stdin); assert 'additionalContext' in d['hookSpecificOutput']; print('boot hook JSON ok')"; then
      fail "boot hook did not emit valid JSON with hookSpecificOutput.additionalContext"
    fi
  fi
else
  fail "boot hook missing or not executable; cannot validate JSON"
fi

# ─── Verify no `{{...}}` placeholders remain in generated markdown ───────────
# Search hq/ and labs/ for any unresolved `{{...}}` patterns in .md files.
# Note: ${...} patterns (e.g. ${CLAUDE_PROJECT_DIR}) are intentionally NOT
# matched here — those are runtime variables, not init-time placeholders.
PLACEHOLDER_HITS=""
for dir in "$TMPWS/hq" "$TMPWS/labs"; do
  if [ -d "$dir" ]; then
    # -I would be GNU-only; restrict to .md by name and rely on grep -l.
    while IFS= read -r f; do
      if grep -l '{{[^}]*}}' "$f" >/dev/null 2>&1; then
        PLACEHOLDER_HITS="$PLACEHOLDER_HITS$f"$'\n'
      fi
    done < <(find "$dir" -type f -name '*.md')
  fi
done

if [ -n "$PLACEHOLDER_HITS" ]; then
  fail "unresolved {{...}} placeholders found in generated markdown:"$'\n'"$PLACEHOLDER_HITS"
fi

# ─── Report ──────────────────────────────────────────────────────────────────
if [ "${#FAILURES[@]}" -gt 0 ]; then
  echo ""
  echo "Smoke test failures:"
  for f in "${FAILURES[@]}"; do
    echo "  - $f"
  done
  echo ""
  echo "FAIL: vibeboss init smoke test"
  exit 1
fi

echo "PASS: vibeboss init smoke test"
exit 0
