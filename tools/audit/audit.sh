#!/usr/bin/env bash
# tools/audit/audit.sh — Vibeboss sensitivity audit.
#
# Scans the working tree (or git diff, in --staged mode) for patterns that
# look like sensitive personal data:
#
#   - Phone-number-shaped digit runs
#   - WhatsApp IDs (digits@c.us / @lid / @g.us / @s.whatsapp.net)
#   - Absolute macOS / Linux user paths (/Users/<name>/, /home/<name>/)
#   - Email addresses NOT in the allowlist
#   - API-key shapes (Anthropic, OpenAI, GitHub, AWS)
#   - Other-venture references (~/ventures/X/ where X is not vibeboss-related)
#   - Hardcoded `Co-Authored-By:` lines pointing at non-anonymized identities
#
# Design philosophy: detect SHAPES, not specific data. The audit's pattern file
# must NEVER list the literal sensitive tokens it's catching — that would be the
# same circular-leak failure mode that motivated this script. We grep for
# *structures* (regex) and let an allowlist handle known-OK matches.
#
# Modes:
#   bash tools/audit/audit.sh             — scan entire working tree
#   bash tools/audit/audit.sh --staged    — scan only what's staged for commit
#   bash tools/audit/audit.sh --history   — scan all commits (slow; for one-off
#                                            forensic checks, not CI)
#
# Exit codes:
#   0  no findings
#   1  findings (block commit / fail CI)
#   2  internal error (allowlist missing, etc.)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALLOWLIST_FILE="$SCRIPT_DIR/allowlist.txt"

MODE="tree"
case "${1:-}" in
  --staged)   MODE="staged" ;;
  --history)  MODE="history" ;;
  --tree|"")  MODE="tree" ;;
  -h|--help)
    grep -E "^# " "$0" | sed 's/^# *//'
    exit 0
    ;;
  *)
    echo "error: unknown mode '$1'. Use --tree (default), --staged, or --history." >&2
    exit 2
    ;;
esac

# Load allowlist into a single regex (each line OR'd together)
if [ ! -f "$ALLOWLIST_FILE" ]; then
  echo "error: allowlist missing at $ALLOWLIST_FILE" >&2
  exit 2
fi

# Build allowlist as a single ERE alternation (skip comment lines + blanks)
ALLOWLIST=""
while IFS= read -r line; do
  case "$line" in
    ""|"#"*) continue ;;
  esac
  if [ -z "$ALLOWLIST" ]; then
    ALLOWLIST="$line"
  else
    ALLOWLIST="$ALLOWLIST|$line"
  fi
done < "$ALLOWLIST_FILE"

# ─── Get the content to scan ─────────────────────────────────────────────────
TMP_TARGET="$(mktemp -d -t vbaudit-XXXXXX)"
trap "rm -rf $TMP_TARGET" EXIT

# ─── Denylist (gitignored, local-only literal runtime terms) ─────────────────
# Catches SHAPELESS runtime-specific names — project names, crew names, other
# ventures the operator works on — that the shape-based patterns above cannot
# see (a bare word like a project name has no detectable shape). Lives at
# <repo>/.vibeboss-denylist, gitignored: it contains the very terms it protects
# against, so it must NEVER be committed. Present locally (the pre-commit gate
# that matters for a single-operator repo); absent in CI (CI checks out the repo
# without the gitignored file, so CI does shape-detection only). This closes the
# framework-feedback leak vector: runtime data flows toward source via the
# feedback channel; the denylist flags any runtime-specific literal that slips in.
DENYLIST_FILE="$(cd "$SCRIPT_DIR/../.." && pwd)/.vibeboss-denylist"
DENY_PATTERNS=""
if [ -f "$DENYLIST_FILE" ]; then
  DENY_PATTERNS="$TMP_TARGET/deny.patterns"
  grep -vE '^[[:space:]]*(#|$)' "$DENYLIST_FILE" 2>/dev/null > "$DENY_PATTERNS" || true
  [ -s "$DENY_PATTERNS" ] || DENY_PATTERNS=""
fi

case "$MODE" in
  tree)
    # Scan tracked files in working tree
    cd "$(git rev-parse --show-toplevel)" 2>/dev/null || cd "$SCRIPT_DIR/../.."
    SCAN_LIST="$TMP_TARGET/files.list"
    git ls-files 2>/dev/null > "$SCAN_LIST" || find . -type f -not -path "./.git/*" > "$SCAN_LIST"
    ;;
  staged)
    cd "$(git rev-parse --show-toplevel)" 2>/dev/null || {
      echo "error: --staged mode requires a git repo" >&2
      exit 2
    }
    # Get only staged files (added/modified, not deleted)
    SCAN_LIST="$TMP_TARGET/files.list"
    git diff --cached --name-only --diff-filter=AM > "$SCAN_LIST"
    if [ ! -s "$SCAN_LIST" ]; then
      echo "audit: no staged files to scan"
      exit 0
    fi
    ;;
  history)
    cd "$(git rev-parse --show-toplevel)" 2>/dev/null || {
      echo "error: --history mode requires a git repo" >&2
      exit 2
    }
    # For history mode, we'll scan via git log -p instead of file list
    SCAN_LIST=""
    ;;
esac

# ─── Findings accumulator ────────────────────────────────────────────────────
FINDINGS_FILE="$TMP_TARGET/findings.out"
: > "$FINDINGS_FILE"

flag() {
  local category="$1"
  local file="$2"
  local lineno="$3"
  local snippet="$4"
  # Check allowlist against the FULL snippet (before truncation)
  if [ -n "$ALLOWLIST" ] && printf '%s' "$snippet" | grep -qE "$ALLOWLIST"; then
    return 0  # allowlisted; skip
  fi
  # Truncate snippet for display only
  if [ ${#snippet} -gt 200 ]; then
    snippet="${snippet:0:200}..."
  fi
  printf '%s\n' "[$category] $file:$lineno  $snippet" >> "$FINDINGS_FILE"
}

flag_denylist() {
  # Denylist hits BYPASS the allowlist — a denylist term is definitionally a leak.
  local file="$1" lineno="$2" snippet="$3"
  if [ ${#snippet} -gt 200 ]; then snippet="${snippet:0:200}..."; fi
  printf '%s\n' "[denylist-term] $file:$lineno  $snippet" >> "$FINDINGS_FILE"
}

scan_file() {
  local f="$1"
  # Skip binaries, symlinks, missing files
  [ -f "$f" ] || return 0
  [ -L "$f" ] && return 0
  if file -b --mime-encoding "$f" 2>/dev/null | grep -q binary; then
    return 0
  fi

  # Skip the audit's own files (they intentionally contain pattern descriptions)
  # and the denylist itself (it intentionally contains the literal sensitive terms)
  case "$f" in
    tools/audit/*) return 0 ;;
    .vibeboss-denylist) return 0 ;;
  esac

  # Read file once into a temp + iterate with grep
  while IFS=: read -r lineno snippet; do
    [ -z "$lineno" ] && continue
    flag "phone-or-id" "$f" "$lineno" "$snippet"
  done < <(grep -nE '[0-9]{10,15}@(c\.us|lid|s\.whatsapp\.net|g\.us)' "$f" 2>/dev/null)

  while IFS=: read -r lineno snippet; do
    [ -z "$lineno" ] && continue
    # Skip if the digit run is clearly a CI run ID, line number, version, etc.
    if printf '%s' "$snippet" | grep -qE '(run|ci|line|version|chmod|sha|sequence|sleep|delay|timeout|port|million|thousand)'; then
      continue
    fi
    flag "phone-shaped-digits" "$f" "$lineno" "$snippet"
  done < <(grep -nE '\b[0-9]{10,15}\b' "$f" 2>/dev/null)

  while IFS=: read -r lineno snippet; do
    [ -z "$lineno" ] && continue
    flag "abs-user-path" "$f" "$lineno" "$snippet"
  done < <(grep -nE '/(Users|home)/[a-zA-Z][a-zA-Z0-9._-]*/' "$f" 2>/dev/null)

  while IFS=: read -r lineno snippet; do
    [ -z "$lineno" ] && continue
    # Only flag ~/ventures/X/ where X is NOT vibeboss / vibeboss-workspace / a placeholder
    if printf '%s' "$snippet" | grep -qE '~/ventures/(vibeboss|<|\$|\{)'; then
      continue
    fi
    flag "other-venture-path" "$f" "$lineno" "$snippet"
  done < <(grep -nE '~/ventures/[a-zA-Z][a-zA-Z0-9._-]*' "$f" 2>/dev/null)

  while IFS=: read -r lineno snippet; do
    [ -z "$lineno" ] && continue
    flag "email" "$f" "$lineno" "$snippet"
  done < <(grep -nE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' "$f" 2>/dev/null)

  while IFS=: read -r lineno snippet; do
    [ -z "$lineno" ] && continue
    flag "credential" "$f" "$lineno" "$snippet"
  done < <(grep -nE '(sk-ant-[a-zA-Z0-9_-]{20,}|sk-[a-zA-Z0-9_-]{40,}|ghp_[a-zA-Z0-9]{36,}|gho_[a-zA-Z0-9]{36,}|github_pat_[a-zA-Z0-9_]{50,}|AKIA[0-9A-Z]{16}|xox[bp]-[a-zA-Z0-9-]{10,}|Bearer [a-zA-Z0-9._-]{30,})' "$f" 2>/dev/null)

  while IFS=: read -r lineno snippet; do
    [ -z "$lineno" ] && continue
    flag "credential-assignment" "$f" "$lineno" "$snippet"
  done < <(grep -nE '(password|passwd|api[_-]?key|secret|token)\s*[:=]\s*["\x27][^"\x27]{8,}["\x27]' "$f" 2>/dev/null)

  # Denylist: literal runtime-specific terms (case-insensitive fixed-string match)
  if [ -n "$DENY_PATTERNS" ]; then
    while IFS=: read -r lineno snippet; do
      [ -z "$lineno" ] && continue
      flag_denylist "$f" "$lineno" "$snippet"
    done < <(grep -niFf "$DENY_PATTERNS" "$f" 2>/dev/null)
  fi
}

# ─── Scan ────────────────────────────────────────────────────────────────────
if [ "$MODE" = "history" ]; then
  HIST_DUMP="$TMP_TARGET/history.dump"
  git log --all -p 2>/dev/null > "$HIST_DUMP"

  # In history mode we look for the same patterns but in the entire history dump
  # (single grep pass per pattern). Slower than scanning files, but covers commit
  # message bodies + file diffs.
  while IFS=: read -r lineno snippet; do
    [ -z "$lineno" ] && continue
    flag "phone-or-id" "<history>" "$lineno" "$snippet"
  done < <(grep -nE '[0-9]{10,15}@(c\.us|lid|s\.whatsapp\.net|g\.us)' "$HIST_DUMP" 2>/dev/null)

  while IFS=: read -r lineno snippet; do
    [ -z "$lineno" ] && continue
    flag "abs-user-path" "<history>" "$lineno" "$snippet"
  done < <(grep -nE '/(Users|home)/[a-zA-Z][a-zA-Z0-9._-]*/' "$HIST_DUMP" 2>/dev/null)

  while IFS=: read -r lineno snippet; do
    [ -z "$lineno" ] && continue
    if printf '%s' "$snippet" | grep -qE '~/ventures/(vibeboss|<|\$|\{)'; then
      continue
    fi
    flag "other-venture-path" "<history>" "$lineno" "$snippet"
  done < <(grep -nE '~/ventures/[a-zA-Z][a-zA-Z0-9._-]*' "$HIST_DUMP" 2>/dev/null)

  while IFS=: read -r lineno snippet; do
    [ -z "$lineno" ] && continue
    flag "credential" "<history>" "$lineno" "$snippet"
  done < <(grep -nE '(sk-ant-[a-zA-Z0-9_-]{20,}|ghp_[a-zA-Z0-9]{36,}|AKIA[0-9A-Z]{16})' "$HIST_DUMP" 2>/dev/null)

  if [ -n "$DENY_PATTERNS" ]; then
    while IFS=: read -r lineno snippet; do
      [ -z "$lineno" ] && continue
      flag_denylist "<history>" "$lineno" "$snippet"
    done < <(grep -niFf "$DENY_PATTERNS" "$HIST_DUMP" 2>/dev/null)
  fi
else
  # File-list mode (tree or staged)
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    scan_file "$f"
  done < "$SCAN_LIST"
fi

# ─── Report ──────────────────────────────────────────────────────────────────
FINDING_COUNT="$(wc -l < "$FINDINGS_FILE" | tr -d ' ')"

if [ "$FINDING_COUNT" -eq 0 ]; then
  printf 'audit: PASS — no sensitive patterns detected (%s mode)\n' "$MODE"
  exit 0
fi

printf 'audit: FAIL — %d finding(s) in %s mode\n' "$FINDING_COUNT" "$MODE"
echo "─────────────────────────────────────────────────────"
cat "$FINDINGS_FILE"
echo "─────────────────────────────────────────────────────"
echo ""
echo "Each finding shows: [category] file:line  snippet"
echo ""
echo "If a finding is a false positive, add a regex to tools/audit/allowlist.txt"
echo "(one regex per line; matches anywhere in the snippet)."
echo ""
echo "If a finding is a real leak, redact it before committing."
exit 1
