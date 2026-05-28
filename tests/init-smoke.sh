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

# ─── Exercise --add-project (PPSB scaffolding) ───────────────────────────────
echo ""
echo "Running: bash init.sh --add-project smoke-proj --workspace '$TMPWS'"

set +e
bash "$REPO_DIR/init.sh" --add-project smoke-proj --workspace "$TMPWS" >/dev/null
ADDPROJ_STATUS=$?
set -e

if [ "$ADDPROJ_STATUS" -ne 0 ]; then
  fail "init.sh --add-project exited with status $ADDPROJ_STATUS"
else
  # Project tree shape
  check_file "$TMPWS/hq/projects/smoke-proj/STATE.md"
  check_file "$TMPWS/hq/projects/smoke-proj/README.md"
  check_file "$TMPWS/hq/projects/smoke-proj/crew.yml"
  check_file "$TMPWS/hq/projects/smoke-proj/inbox/README.md"
  check_file "$TMPWS/hq/projects/smoke-proj/inbox/boss.md"
  check_file "$TMPWS/hq/projects/smoke-proj/runlog/README.md"
  check_file "$TMPWS/hq/projects/smoke-proj/decisions/README.md"
  check_file "$TMPWS/hq/projects/smoke-proj/handovers/README.md"
  check_file "$TMPWS/hq/projects/smoke-proj/.claude/settings.json"

  # Symlinks for vibeboss-native skills
  if [ ! -L "$TMPWS/hq/projects/smoke-proj/.claude/skills/dev-workflow" ]; then
    fail "missing or non-symlink: .claude/skills/dev-workflow"
  fi
  if [ ! -L "$TMPWS/hq/projects/smoke-proj/.claude/skills/compact-handover" ]; then
    fail "missing or non-symlink: .claude/skills/compact-handover"
  fi

  # enabledPlugins baseline
  if ! grep -q "superpowers@claude-plugins-official" "$TMPWS/hq/projects/smoke-proj/.claude/settings.json" 2>/dev/null; then
    fail "project settings.json missing superpowers@claude-plugins-official baseline"
  fi

  # Placeholders fully substituted in project files
  PROJ_PLACEHOLDERS=""
  while IFS= read -r f; do
    if grep -l '{{[^}]*}}' "$f" >/dev/null 2>&1; then
      PROJ_PLACEHOLDERS="$PROJ_PLACEHOLDERS$f"$'\n'
    fi
  done < <(find "$TMPWS/hq/projects/smoke-proj" -type f -name '*.md')
  if [ -n "$PROJ_PLACEHOLDERS" ]; then
    fail "unresolved {{...}} placeholders in scaffolded project:"$'\n'"$PROJ_PLACEHOLDERS"
  fi
fi

# ─── STOP-file kill switch test ──────────────────────────────────────────────
echo "Testing STOP-file kill switch..."

touch "$TMPWS/hq/STOP"
set +e
STOP_OUT="$("$TMPWS/hq/.claude/hooks/boot.sh" --brief-only 2>/dev/null)"
STOP_STATUS=$?
set -e
rm -f "$TMPWS/hq/STOP"

if [ "$STOP_STATUS" -ne 0 ]; then
  fail "boot.sh exited nonzero ($STOP_STATUS) when STOP file present"
elif ! printf '%s' "$STOP_OUT" | grep -q "STOPPED"; then
  fail "boot.sh did not emit STOPPED brief when STOP file present"
fi

# Verify normal boot resumes after STOP removed
set +e
RESUME_OUT="$("$TMPWS/hq/.claude/hooks/boot.sh" --brief-only 2>/dev/null)"
RESUME_STATUS=$?
set -e
if [ "$RESUME_STATUS" -ne 0 ]; then
  fail "boot.sh exited nonzero ($RESUME_STATUS) after STOP removed"
elif ! printf '%s' "$RESUME_OUT" | grep -q "online"; then
  fail "boot.sh did not return to normal brief after STOP removed"
fi

# ─── Update mechanism: .vibeboss-version + manifest + --update + banner ──────
echo "Testing update mechanism..."

check_file "$TMPWS/.vibeboss-version"

if ! grep -q "^version: " "$TMPWS/.vibeboss-version" 2>/dev/null; then
  fail ".vibeboss-version missing 'version:' line"
fi
if ! grep -q "^source_path: " "$TMPWS/.vibeboss-version" 2>/dev/null; then
  fail ".vibeboss-version missing 'source_path:' line"
fi
if ! grep -q "^installed_at: " "$TMPWS/.vibeboss-version" 2>/dev/null; then
  fail ".vibeboss-version missing 'installed_at:' line"
fi

# Manifest populated
MANIFEST_COUNT="$(find "$TMPWS/.vibeboss/originals" -name '*.sha256' 2>/dev/null | wc -l | tr -d ' ')"
if [ "$MANIFEST_COUNT" -lt 10 ]; then
  fail ".vibeboss/originals/ manifest has only $MANIFEST_COUNT entries (expected >= 10)"
fi

# Banner should NOT appear when versions match (just installed; identical)
set +e
NOBANNER_OUT="$("$TMPWS/hq/.claude/hooks/boot.sh" --brief-only 2>/dev/null)"
set -e
if printf '%s' "$NOBANNER_OUT" | grep -q "Vibeboss update available"; then
  fail "boot.sh emitted update banner when versions match"
fi

# Simulate stale workspace — bump version backwards
sed -i.bak 's/^version: .*/version: 0.0.1-stale/' "$TMPWS/.vibeboss-version"
rm -f "$TMPWS/.vibeboss-version.bak"

# Banner SHOULD appear now
set +e
BANNER_OUT="$("$TMPWS/hq/.claude/hooks/boot.sh" --brief-only 2>/dev/null)"
set -e
if ! printf '%s' "$BANNER_OUT" | grep -q "Vibeboss update available"; then
  fail "boot.sh did not emit update banner when version is stale"
fi

# --update should apply and clear the staleness
set +e
bash "$REPO_DIR/init.sh" --update --workspace "$TMPWS" --noninteractive >/dev/null 2>&1
UPDATE_STATUS=$?
set -e
if [ "$UPDATE_STATUS" -ne 0 ]; then
  fail "init.sh --update exited with status $UPDATE_STATUS"
fi

# Version should now match source
SOURCE_VERSION="$(cat "$REPO_DIR/VERSION" 2>/dev/null | tr -d '[:space:]')"
WS_VERSION_AFTER="$(grep '^version: ' "$TMPWS/.vibeboss-version" | sed 's/^version: //' | tr -d '[:space:]')"
if [ "$SOURCE_VERSION" != "$WS_VERSION_AFTER" ]; then
  fail "after --update, workspace version ($WS_VERSION_AFTER) != source ($SOURCE_VERSION)"
fi

# Banner should be gone now
set +e
POSTUPDATE_OUT="$("$TMPWS/hq/.claude/hooks/boot.sh" --brief-only 2>/dev/null)"
set -e
if printf '%s' "$POSTUPDATE_OUT" | grep -q "Vibeboss update available"; then
  fail "boot.sh still emits update banner after successful --update"
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
