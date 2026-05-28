#!/usr/bin/env bash
# vibeboss/init.sh — scaffold a Vibeboss workspace for a new user
# Usage: bash init.sh [options]
# Options:
#   --workspace <path>      workspace root (default: $HOME/ventures/vibeboss-workspace)
#   --name <name>           your name
#   --email <email>         your email
#   --lead-name <name>      venture lead name (default: Boss)
#   --operator-as <word>    how the lead addresses you (default: partner)
#   --lab-lead-name <name>  labs research lead name (default: Ginger)
#   --noninteractive        skip prompts; require --name and --email
#   --upgrade               add missing files to an existing workspace (idempotent)
#   --update                refresh template-derived files in an existing workspace
#   --dry-run               show what would be done without writing anything
#   --add-project <name>    scaffold a new project under an existing workspace
#   -h, --help              show this help message
set -euo pipefail

# ─── Color helpers ───────────────────────────────────────────────────────────
BOLD="$(tput bold 2>/dev/null || true)"
GREEN="$(tput setaf 2 2>/dev/null || true)"
YELLOW="$(tput setaf 3 2>/dev/null || true)"
RED="$(tput setaf 1 2>/dev/null || true)"
RESET="$(tput sgr0 2>/dev/null || true)"

info()    { printf "%s\n" "${BOLD}${GREEN}  ✓${RESET} $*"; }
warn()    { printf "%s\n" "${BOLD}${YELLOW}  !${RESET} $*"; }
error()   { printf "%s\n" "${BOLD}${RED}  ✗${RESET} $*" >&2; }
heading() { printf "\n%s\n" "${BOLD}$*${RESET}"; }

# ─── Parse arguments ─────────────────────────────────────────────────────────
WORKSPACE=""
OPERATOR_NAME=""
OPERATOR_EMAIL=""
LEAD_NAME="Boss"
OPERATOR_ADDRESSED_AS="partner"
LAB_LEAD_NAME="Ginger"
NONINTERACTIVE=false
UPGRADE=false
UPDATE_MODE=false
DRY_RUN=false
ADD_PROJECT_MODE=false
PROJECT_NAME=""
CREW_NAME=""

# Counters used by --update mode (declared early so write_file can update them)
UPDATE_REFRESHED=0
UPDATE_KEPT=0
UPDATE_SKIPPED=0
UPDATE_UNCHANGED=0
UPDATE_NEW=0
UPDATE_LEGACY_ADOPTED=0
UPDATE_MIGRATIONS_RUN=0

usage() {
  cat <<EOF
Usage: bash init.sh [options]

Options:
  --workspace <path>      workspace root (default: \$HOME/ventures/vibeboss-workspace)
  --name <name>           your name
  --email <email>         your email
  --lead-name <name>      venture lead name (default: Boss)
  --operator-as <word>    how the lead addresses you (default: partner)
  --lab-lead-name <name>  labs research lead name (default: Ginger)
  --noninteractive        skip prompts; require --name and --email
  --upgrade               add missing files to an existing workspace (idempotent)
  --update                refresh template-derived files in an existing
                          workspace. Compares each file against a manifest
                          recorded at install time; refreshes unmodified
                          files automatically, prompts before overwriting
                          user-customized files. Runs version migrations
                          between the workspace's pinned version and the
                          source's current VERSION. Honors --noninteractive
                          (defaults to keeping customizations) and --dry-run.
  --dry-run               show what would be done without writing anything
  --add-project <name>    scaffold a new project under an existing workspace
                          (requires the workspace to already exist; assigns
                           the next crew name from hq/crew.yml next_available
                           and symlinks Vibeboss-native skills into the
                           project's .claude/skills/)
  --version, -v           print framework version and exit
  -h, --help              show this help message
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workspace)      WORKSPACE="$2";             shift 2 ;;
    --name)           OPERATOR_NAME="$2";          shift 2 ;;
    --email)          OPERATOR_EMAIL="$2";         shift 2 ;;
    --lead-name)      LEAD_NAME="$2";              shift 2 ;;
    --operator-as)    OPERATOR_ADDRESSED_AS="$2";  shift 2 ;;
    --lab-lead-name)  LAB_LEAD_NAME="$2";          shift 2 ;;
    --noninteractive) NONINTERACTIVE=true;          shift   ;;
    --upgrade|--repair) UPGRADE=true;              shift   ;;
    --update)         UPDATE_MODE=true;            shift   ;;
    --dry-run)        DRY_RUN=true;                shift   ;;
    --add-project)
      ADD_PROJECT_MODE=true
      PROJECT_NAME="$2"
      shift 2
      ;;
    --version|-v)
      cat "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/VERSION"
      exit 0
      ;;
    -h|--help)        usage; exit 0 ;;
    --)               shift; break ;;
    *)
      error "Unknown option: $1"
      echo "Run 'bash init.sh --help' for usage." >&2
      exit 1
      ;;
  esac
done

# ─── Script location ─────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES="$SCRIPT_DIR/templates"

if [ ! -d "$TEMPLATES" ]; then
  error "Templates directory not found: $TEMPLATES"
  echo "  Make sure you're running init.sh from inside the vibeboss repo." >&2
  exit 1
fi

# ─── Platform check ──────────────────────────────────────────────────────────
OS="$(uname -s)"
case "$OS" in
  Linux|Darwin) ;;
  MINGW*|CYGWIN*|MSYS*)
    error "Windows is not yet supported."
    echo "  Windows support is deferred — see https://github.com/vibeboss/vibeboss/issues for updates." >&2
    exit 1
    ;;
  *)
    warn "Unrecognized OS: $OS — proceeding, but this is untested."
    ;;
esac

# ─── Banner ──────────────────────────────────────────────────────────────────
if $ADD_PROJECT_MODE; then
cat <<'BANNER'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Vibeboss — add project
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BANNER
elif $UPDATE_MODE; then
cat <<'BANNER'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Vibeboss — workspace update
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BANNER
else
cat <<'BANNER'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Vibeboss — workspace init
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BANNER
fi

if $DRY_RUN; then
  warn "DRY RUN — no files will be written."
fi

# Default workspace path (used by both fresh-init and --add-project modes)
DEFAULT_WORKSPACE="$HOME/ventures/vibeboss-workspace"

# ─── Helpers (used by both modes) ────────────────────────────────────────────
# substitute — replaces placeholders in a string
substitute() {
  local text="$1"
  text="${text//\{\{LEAD_NAME\}\}/$LEAD_NAME}"
  text="${text//\{\{OPERATOR_NAME\}\}/$OPERATOR_NAME}"
  text="${text//\{\{OPERATOR_EMAIL\}\}/$OPERATOR_EMAIL}"
  text="${text//\{\{OPERATOR_ADDRESSED_AS\}\}/$OPERATOR_ADDRESSED_AS}"
  text="${text//\{\{LAB_LEAD_NAME\}\}/$LAB_LEAD_NAME}"
  text="${text//\{\{WORKSPACE\}\}/$WORKSPACE}"
  text="${text//\{\{HQ_PATH\}\}/$HQ_PATH}"
  text="${text//\{\{DATE\}\}/$TODAY}"
  text="${text//\{\{PROJECT_NAME\}\}/$PROJECT_NAME}"
  text="${text//\{\{CREW_NAME\}\}/$CREW_NAME}"
  printf '%s' "$text"
}

# hash_file — print SHA256 hex hash of file contents (works on macOS + Linux)
hash_file() {
  if command -v shasum &>/dev/null; then
    shasum -a 256 "$1" | cut -d' ' -f1
  elif command -v sha256sum &>/dev/null; then
    sha256sum "$1" | cut -d' ' -f1
  else
    error "Neither shasum nor sha256sum is available — cannot compute file hash."
    return 1
  fi
}

# hash_string — print SHA256 hex hash of a string passed on stdin
hash_string() {
  if command -v shasum &>/dev/null; then
    shasum -a 256 | cut -d' ' -f1
  elif command -v sha256sum &>/dev/null; then
    sha256sum | cut -d' ' -f1
  else
    error "Neither shasum nor sha256sum is available — cannot compute hash."
    return 1
  fi
}

# write_manifest_hash — record the hash of a destination file in the
# .vibeboss/originals/<rel-path>.sha256 manifest. Skips in --dry-run.
# Requires WORKSPACE to be set.
write_manifest_hash() {
  local dest="$1"
  if [ -z "${WORKSPACE:-}" ]; then
    return 0
  fi
  if [ ! -f "$dest" ]; then
    return 0
  fi

  # rel = dest minus workspace prefix (no leading slash)
  local rel="${dest#"$WORKSPACE"/}"
  local manifest_path="$WORKSPACE/.vibeboss/originals/$rel.sha256"
  local manifest_dir
  manifest_dir="$(dirname "$manifest_path")"

  if $DRY_RUN; then
    echo "    [dry-run] would record hash: $manifest_path"
    return 0
  fi

  mkdir -p "$manifest_dir"
  local hash
  hash="$(hash_file "$dest")"
  printf '%s\n' "$hash" > "$manifest_path"
}

# write_file — write a file from a template, substituting placeholders, then
# record its post-substitute hash in the manifest. Usage: write_file <src> <dest>
write_file() {
  local src="$1"
  local dest="$2"

  if $UPGRADE && [ -f "$dest" ]; then
    # In upgrade mode, if the file already exists we leave it alone — but
    # we still want a manifest entry so a future --update can manage it.
    # (Only record if the manifest doesn't already exist.)
    if [ -n "${WORKSPACE:-}" ]; then
      local rel="${dest#"$WORKSPACE"/}"
      local existing_manifest="$WORKSPACE/.vibeboss/originals/$rel.sha256"
      if [ ! -f "$existing_manifest" ]; then
        write_manifest_hash "$dest"
      fi
    fi
    return 0
  fi

  local dest_dir
  dest_dir="$(dirname "$dest")"

  if $DRY_RUN; then
    echo "    [dry-run] would write: $dest"
    return 0
  fi

  mkdir -p "$dest_dir"
  local content
  content="$(cat "$src")"
  substitute "$content" > "$dest"
  write_manifest_hash "$dest"
}

# write_version_metadata — write/refresh $WORKSPACE/.vibeboss-version with
# the contract documented in CLAUDE.md (version, source_path, source_sha,
# installed_at, updated_at). Preserves installed_at if the file already
# exists; otherwise sets installed_at = now.
write_version_metadata() {
  if [ -z "${WORKSPACE:-}" ]; then
    return 0
  fi

  local version_file="$WORKSPACE/.vibeboss-version"
  local now
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  local source_version
  source_version="$(cat "$SCRIPT_DIR/VERSION" 2>/dev/null || echo unknown)"

  local source_sha
  source_sha="$(git -C "$SCRIPT_DIR" rev-parse HEAD 2>/dev/null || echo unknown)"

  local installed_at="$now"
  if [ -f "$version_file" ]; then
    local prev
    prev="$(awk -F': ' '/^installed_at:/ { print $2; exit }' "$version_file" 2>/dev/null || true)"
    if [ -n "$prev" ]; then
      installed_at="$prev"
    fi
  fi

  if $DRY_RUN; then
    echo "    [dry-run] would write version metadata: $version_file"
    return 0
  fi

  mkdir -p "$(dirname "$version_file")"
  cat > "$version_file" <<EOF
version: $source_version
source_path: $SCRIPT_DIR
source_sha: $source_sha
installed_at: $installed_at
updated_at: $now
EOF
}

# ensure_dir — create a directory (skips in dry-run)
ensure_dir() {
  if $DRY_RUN; then
    echo "    [dry-run] would create dir: $1"
  else
    mkdir -p "$1"
  fi
}

# touch_file — create an empty file if it doesn't exist
touch_file() {
  local dest="$1"
  if $UPGRADE && [ -f "$dest" ]; then
    return 0
  fi
  if $DRY_RUN; then
    echo "    [dry-run] would touch: $dest"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  touch "$dest"
}

# ─── --add-project mode ──────────────────────────────────────────────────────
if $ADD_PROJECT_MODE; then
  if [ -z "$PROJECT_NAME" ]; then
    error "--add-project requires a project name"
    echo "  Example: bash init.sh --add-project <example-project>" >&2
    exit 1
  fi

  # Sanity-check the project name (alphanumeric, dash, underscore only)
  if [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    error "Invalid project name: $PROJECT_NAME"
    echo "  Use only letters, numbers, dashes, and underscores." >&2
    exit 1
  fi

  # Resolve workspace
  if [ -z "$WORKSPACE" ]; then
    WORKSPACE="$DEFAULT_WORKSPACE"
  fi
  WORKSPACE="${WORKSPACE/#\~/$HOME}"
  if [[ "$WORKSPACE" != /* ]]; then
    WORKSPACE="$PWD/$WORKSPACE"
  fi
  WORKSPACE="${WORKSPACE%/}"

  HQ_PATH="$WORKSPACE/hq"
  PROJECT_PATH="$HQ_PATH/projects/$PROJECT_NAME"
  TODAY="$(date '+%Y-%m-%d')"

  # Workspace must exist
  if [ ! -d "$HQ_PATH" ]; then
    error "No existing workspace found at: $WORKSPACE"
    echo "  Run \`bash init.sh\` first to create a workspace, then re-run with --add-project." >&2
    exit 1
  fi

  # Project must not already exist
  if [ -e "$PROJECT_PATH" ]; then
    error "Project already exists: $PROJECT_PATH"
    echo "  Choose a different name, or remove the existing project directory." >&2
    exit 1
  fi

  # Read CREW_NAME (next_available) and LEAD_NAME from hq/crew.yml
  CREW_YML="$HQ_PATH/crew.yml"
  if [ ! -f "$CREW_YML" ]; then
    error "hq/crew.yml not found at: $CREW_YML"
    echo "  The workspace looks incomplete. Run \`bash init.sh --upgrade\` to repair." >&2
    exit 1
  fi

  # next_available — first line matching "  next_available: <NAME>"
  CREW_NAME="$(awk '/^[[:space:]]*next_available:/ { print $2; exit }' "$CREW_YML" | tr -d '"' )"
  if [ -z "$CREW_NAME" ]; then
    error "Could not read next_available from $CREW_YML"
    exit 1
  fi

  # venture_lead.name — first "  name:" within the venture_lead: block
  LEAD_NAME="$(awk '
    /^venture_lead:/ { in_block=1; next }
    in_block && /^[a-zA-Z]/ { in_block=0 }
    in_block && /^[[:space:]]+name:/ { print $2; exit }
  ' "$CREW_YML" | tr -d '"')"
  if [ -z "$LEAD_NAME" ]; then
    LEAD_NAME="Boss"
  fi

  info "Workspace:    $WORKSPACE"
  info "Project:      $PROJECT_NAME"
  info "Build lead:   $CREW_NAME (assigned from crew.yml next_available)"
  info "Venture lead: $LEAD_NAME"

  heading "Scaffolding project..."

  PROJECT_TEMPLATES="$TEMPLATES/projects/_per_project"
  if [ ! -d "$PROJECT_TEMPLATES" ]; then
    error "Per-project template not found: $PROJECT_TEMPLATES"
    exit 1
  fi

  ensure_dir "$PROJECT_PATH"
  ensure_dir "$PROJECT_PATH/.claude"
  ensure_dir "$PROJECT_PATH/.claude/skills"
  ensure_dir "$PROJECT_PATH/runlog"
  ensure_dir "$PROJECT_PATH/decisions"
  ensure_dir "$PROJECT_PATH/handovers"

  write_file "$PROJECT_TEMPLATES/.claude/settings.json"  "$PROJECT_PATH/.claude/settings.json"
  write_file "$PROJECT_TEMPLATES/README.md"              "$PROJECT_PATH/README.md"
  write_file "$PROJECT_TEMPLATES/STATE.md"               "$PROJECT_PATH/STATE.md"
  write_file "$PROJECT_TEMPLATES/crew.yml"               "$PROJECT_PATH/crew.yml"
  write_file "$PROJECT_TEMPLATES/runlog/README.md"       "$PROJECT_PATH/runlog/README.md"
  write_file "$PROJECT_TEMPLATES/decisions/README.md"    "$PROJECT_PATH/decisions/README.md"
  write_file "$PROJECT_TEMPLATES/handovers/README.md"    "$PROJECT_PATH/handovers/README.md"

  # Inbox — owned by the inbox-topology spec. Copy any files present in
  # the per-project inbox template (README, boss.md, etc.) plus standard
  # legacy type-folders (requests/, processed/).
  if [ -d "$PROJECT_TEMPLATES/inbox" ]; then
    ensure_dir "$PROJECT_PATH/inbox"
    while IFS= read -r -d '' src; do
      rel="${src#"$PROJECT_TEMPLATES/inbox/"}"
      dest="$PROJECT_PATH/inbox/$rel"
      if [[ "$rel" == *.gitkeep ]]; then
        touch_file "$dest"
      else
        write_file "$src" "$dest"
      fi
    done < <(find "$PROJECT_TEMPLATES/inbox" -type f -print0)
  fi

  # Symlink Vibeboss-native skills from HQ
  if ! $DRY_RUN; then
    for skill in dev-workflow compact-handover; do
      if [ -d "$HQ_PATH/skills/$skill" ]; then
        ln -sfn "$HQ_PATH/skills/$skill" "$PROJECT_PATH/.claude/skills/$skill"
        info "Symlinked skill: $skill"
      else
        warn "HQ skill missing — skipping symlink: $HQ_PATH/skills/$skill"
      fi
    done
  else
    echo "    [dry-run] would symlink dev-workflow + compact-handover into $PROJECT_PATH/.claude/skills/"
  fi

  info "Project scaffolded at $PROJECT_PATH"

  cat <<DONE

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Project ready
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ${BOLD}${GREEN}✓${RESET} $PROJECT_PATH

  Build lead: $CREW_NAME

  Next steps:

  1. Open a session in the project:
       cd "$PROJECT_PATH" && claude

  2. From hq/, $LEAD_NAME can dispatch to $CREW_NAME via:
       $PROJECT_PATH/inbox/

  3. Add $CREW_NAME to hq/crew.yml agents[] when you first spawn them
     so the runlog/decision records the birth event.

DONE

  if $DRY_RUN; then
    warn "DRY RUN complete — no files were written."
  fi

  exit 0
fi

# ─── --update mode ───────────────────────────────────────────────────────────
if $UPDATE_MODE; then
  # Resolve workspace
  if [ -z "$WORKSPACE" ]; then
    WORKSPACE="$DEFAULT_WORKSPACE"
  fi
  WORKSPACE="${WORKSPACE/#\~/$HOME}"
  if [[ "$WORKSPACE" != /* ]]; then
    WORKSPACE="$PWD/$WORKSPACE"
  fi
  WORKSPACE="${WORKSPACE%/}"

  if [ ! -d "$WORKSPACE" ]; then
    error "Workspace not found: $WORKSPACE"
    echo "  Run \`bash init.sh\` first to create a workspace." >&2
    exit 1
  fi

  VERSION_FILE="$WORKSPACE/.vibeboss-version"
  if [ ! -f "$VERSION_FILE" ]; then
    error "This workspace doesn't track a Vibeboss version."
    echo "  $VERSION_FILE is missing — the workspace was installed before --update existed." >&2
    echo "  Run \`bash init.sh --upgrade --workspace \"$WORKSPACE\"\` once to bootstrap the manifest," >&2
    echo "  then re-run --update from there." >&2
    exit 1
  fi

  # Read workspace's pinned version + sha
  WS_VERSION="$(awk -F': ' '/^version:/ { print $2; exit }' "$VERSION_FILE" 2>/dev/null || true)"
  WS_SHA="$(awk -F': ' '/^source_sha:/ { print $2; exit }' "$VERSION_FILE" 2>/dev/null || true)"
  [ -z "$WS_VERSION" ] && WS_VERSION="unknown"
  [ -z "$WS_SHA" ] && WS_SHA="unknown"

  SOURCE_VERSION="$(cat "$SCRIPT_DIR/VERSION" 2>/dev/null || echo unknown)"
  SOURCE_SHA="$(git -C "$SCRIPT_DIR" rev-parse HEAD 2>/dev/null || echo unknown)"

  # If both version + sha are identical, no-op
  if [ "$WS_VERSION" = "$SOURCE_VERSION" ] && [ "$WS_SHA" = "$SOURCE_SHA" ] && [ "$WS_SHA" != "unknown" ]; then
    info "Already up to date (v$WS_VERSION @ ${WS_SHA:0:12})."
    exit 0
  fi

  cat <<UPDBANNER

Updating Vibeboss workspace
─────────────────────────────
Workspace: $WORKSPACE
From:      v$WS_VERSION (sha ${WS_SHA:0:12})
To:        v$SOURCE_VERSION (sha ${SOURCE_SHA:0:12})
─────────────────────────────
UPDBANNER

  if $DRY_RUN; then
    warn "DRY RUN — no files will be written."
  fi

  # We need TODAY + HQ_PATH set for the substitute() helper. We don't have
  # the operator-customization values from the original install, so for any
  # placeholders that remain unsubstituted, we read them back from the existing
  # workspace files where possible. For the most common ones, we read from the
  # version metadata + hq/crew.yml.
  TODAY="$(date '+%Y-%m-%d')"
  HQ_PATH="$WORKSPACE/hq"

  # Best-effort recovery of operator fields from the existing workspace so
  # substitute() produces the same bytes as the original install.
  if [ -f "$HQ_PATH/crew.yml" ]; then
    LEAD_NAME="$(awk '
      /^venture_lead:/ { in_block=1; next }
      in_block && /^[a-zA-Z]/ { in_block=0 }
      in_block && /^[[:space:]]+name:/ { print $2; exit }
    ' "$HQ_PATH/crew.yml" 2>/dev/null | tr -d '"')"
    [ -z "$LEAD_NAME" ] && LEAD_NAME="Boss"
  fi
  # Operator name/email are harder to recover — pull from hq/CLAUDE.md if present
  if [ -f "$HQ_PATH/CLAUDE.md" ]; then
    OP_LINE="$(grep -m1 -E 'operator|Operator' "$HQ_PATH/CLAUDE.md" 2>/dev/null || true)"
    # Not strictly required; substitute() will just leave the placeholders for
    # fields it can't fill. The hash comparison on the *new canonical* will
    # also see the same placeholder — meaning the file matches and we skip
    # gracefully.
    : "$OP_LINE"
  fi
  # Leave OPERATOR_NAME etc. as whatever they were (probably empty) — the
  # canonical content is computed identically for both stored-original and
  # new-canonical, so missing fields don't cause false-positive customizations
  # for files that *don't* embed those fields. For files that *do*, the
  # comparison is between two identically-substituted strings.

  # ── Walk templates and decide per-file ──────────────────────────────────────
  heading "Comparing workspace against templates..."

  # update_file — compares one template against its workspace destination and
  # acts per the decision tree. Args: <src_template> <dest_path>
  update_file() {
    local src="$1"
    local dest="$2"
    local rel="${dest#"$WORKSPACE"/}"
    local manifest_path="$WORKSPACE/.vibeboss/originals/$rel.sha256"

    # Compute new-canonical hash (what we'd write right now)
    local new_canonical_content new_canonical_hash
    new_canonical_content="$(substitute "$(cat "$src")")"
    new_canonical_hash="$(printf '%s' "$new_canonical_content" | hash_string)"

    if [ ! -f "$dest" ]; then
      # Destination missing — refresh.
      if $DRY_RUN; then
        echo "    [dry-run] would create missing: $rel"
      else
        mkdir -p "$(dirname "$dest")"
        printf '%s' "$new_canonical_content" > "$dest"
        write_manifest_hash "$dest"
        info "Created (was missing): $rel"
      fi
      UPDATE_NEW=$((UPDATE_NEW + 1))
      return 0
    fi

    local current_hash
    current_hash="$(hash_file "$dest")"

    local stored_original=""
    if [ -f "$manifest_path" ]; then
      stored_original="$(head -n1 "$manifest_path" | tr -d '[:space:]')"
    fi

    if [ -z "$stored_original" ]; then
      # Legacy workspace — no manifest entry. Treat current file as authoritative.
      if $DRY_RUN; then
        echo "    [dry-run] would adopt existing as original: $rel"
      else
        mkdir -p "$(dirname "$manifest_path")"
        printf '%s\n' "$current_hash" > "$manifest_path"
        info "Adopted existing (no prior manifest): $rel"
      fi
      UPDATE_LEGACY_ADOPTED=$((UPDATE_LEGACY_ADOPTED + 1))
      return 0
    fi

    if [ "$current_hash" = "$stored_original" ]; then
      # User hasn't touched it.
      if [ "$stored_original" = "$new_canonical_hash" ]; then
        # No change needed.
        UPDATE_UNCHANGED=$((UPDATE_UNCHANGED + 1))
        return 0
      fi
      # Safe refresh.
      if $DRY_RUN; then
        echo "    [dry-run] would refresh: $rel"
      else
        printf '%s' "$new_canonical_content" > "$dest"
        printf '%s\n' "$new_canonical_hash" > "$manifest_path"
        info "Refreshed: $rel"
      fi
      UPDATE_REFRESHED=$((UPDATE_REFRESHED + 1))
      return 0
    fi

    # User has customized this file.
    if [ "$current_hash" = "$new_canonical_hash" ]; then
      # Their customization happens to match the new canonical — no action.
      if $DRY_RUN; then
        echo "    [dry-run] customization matches new canonical: $rel"
      else
        printf '%s\n' "$new_canonical_hash" > "$manifest_path"
      fi
      UPDATE_UNCHANGED=$((UPDATE_UNCHANGED + 1))
      return 0
    fi

    if $NONINTERACTIVE; then
      warn "CUSTOMIZED (kept): $rel"
      UPDATE_KEPT=$((UPDATE_KEPT + 1))
      return 0
    fi

    # Interactive prompt loop
    while true; do
      cat <<PROMPT

CUSTOMIZED: $rel
  Your version differs from the canonical version that was installed.
  [k] keep your version (no change)
  [o] overwrite with new canonical
  [d] show diff (then re-prompt)
  [s] skip this file (decide later)
PROMPT
      local choice
      read -rp "Choice [k]: " choice
      choice="${choice:-k}"
      case "$choice" in
        k|K)
          UPDATE_KEPT=$((UPDATE_KEPT + 1))
          return 0
          ;;
        o|O)
          if $DRY_RUN; then
            echo "    [dry-run] would overwrite: $rel"
          else
            printf '%s' "$new_canonical_content" > "$dest"
            printf '%s\n' "$new_canonical_hash" > "$manifest_path"
            info "Overwritten: $rel"
          fi
          UPDATE_REFRESHED=$((UPDATE_REFRESHED + 1))
          return 0
          ;;
        d|D)
          local tmp
          tmp="$(mktemp)"
          printf '%s' "$new_canonical_content" > "$tmp"
          echo "─── diff: workspace vs new canonical ───"
          diff -u "$dest" "$tmp" || true
          echo "─────────────────────────────────────────"
          rm -f "$tmp"
          ;;
        s|S)
          UPDATE_SKIPPED=$((UPDATE_SKIPPED + 1))
          return 0
          ;;
        *)
          warn "Unknown choice: $choice — please pick k/o/d/s."
          ;;
      esac
    done
  }

  # Walk every template file and compute its destination path. Skip the
  # _per_project template directory (those are project scaffolding, handled
  # by --add-project, not part of the per-workspace baseline).
  while IFS= read -r -d '' src; do
    rel="${src#"$TEMPLATES/"}"

    # Skip per-project template tree (different lifecycle)
    if [[ "$rel" == projects/_per_project/* ]]; then
      continue
    fi

    # Map template path to workspace destination
    if [[ "$rel" == _workspace_root/* ]]; then
      dest="$WORKSPACE/${rel#_workspace_root/}"
    else
      dest="$WORKSPACE/$rel"
    fi

    # .gitkeep files don't need manifest tracking — just ensure they exist.
    if [[ "$rel" == *.gitkeep ]]; then
      if [ ! -f "$dest" ]; then
        if $DRY_RUN; then
          echo "    [dry-run] would touch: $dest"
        else
          mkdir -p "$(dirname "$dest")"
          touch "$dest"
        fi
      fi
      continue
    fi

    update_file "$src" "$dest"
  done < <(find "$TEMPLATES" -type f -print0)

  # ── Run migrations ──────────────────────────────────────────────────────────
  heading "Running migrations..."
  MIGRATION_RUNNER="$SCRIPT_DIR/migrations/run.sh"
  if [ -f "$MIGRATION_RUNNER" ]; then
    if $DRY_RUN; then
      echo "    [dry-run] would run migrations: $WS_VERSION → $SOURCE_VERSION"
    else
      MIG_OUT="$(bash "$MIGRATION_RUNNER" "$WORKSPACE" "$WS_VERSION" "$SOURCE_VERSION" 2>&1 || true)"
      if [ -n "$MIG_OUT" ]; then
        printf '%s\n' "$MIG_OUT"
        # Best-effort count: lines matching "running migration" or similar.
        # The runner is owned by Cluster C; we just trust the exit status here.
        UPDATE_MIGRATIONS_RUN="$(printf '%s\n' "$MIG_OUT" | grep -c -E '^(running|applying|migrating)' || true)"
      fi
    fi
  else
    warn "Migration runner not found at $MIGRATION_RUNNER — skipping migrations."
  fi

  # ── Update version metadata ─────────────────────────────────────────────────
  write_version_metadata

  # ── Summary ─────────────────────────────────────────────────────────────────
  cat <<SUMMARY

─────────────────────────────
Update complete: v$WS_VERSION → v$SOURCE_VERSION
  Files refreshed:        $UPDATE_REFRESHED
  Files kept (customized): $UPDATE_KEPT
  Files unchanged:        $UPDATE_UNCHANGED
  Files newly created:    $UPDATE_NEW
  Legacy files adopted:   $UPDATE_LEGACY_ADOPTED
  Files skipped:          $UPDATE_SKIPPED
  Migrations run:         $UPDATE_MIGRATIONS_RUN
─────────────────────────────
SUMMARY

  if $DRY_RUN; then
    warn "DRY RUN complete — no files were written."
  fi

  exit 0
fi

# ─── Prerequisites check ─────────────────────────────────────────────────────
heading "Checking prerequisites..."

MISSING_PREREQS=false

if command -v claude &>/dev/null; then
  info "claude CLI found: $(command -v claude)"
else
  warn "claude CLI not found on PATH."
  echo "    Install it from: https://docs.anthropic.com/en/docs/claude-code"
  echo "    You can continue the init now and install Claude Code later."
  MISSING_PREREQS=true
fi

if command -v python3 &>/dev/null; then
  info "python3 found: $(command -v python3)"
else
  warn "python3 not found — the boot hook requires it."
  echo "    Install Python 3 from https://www.python.org/downloads/"
  MISSING_PREREQS=true
fi

if $MISSING_PREREQS; then
  echo ""
  warn "Some prerequisites are missing. The workspace will be scaffolded,"
  warn "but it may not function until the missing tools are installed."
fi

# ─── Workspace location ───────────────────────────────────────────────────────
heading "Workspace location..."

if [ -z "$WORKSPACE" ]; then
  if $NONINTERACTIVE; then
    WORKSPACE="$DEFAULT_WORKSPACE"
  else
    read -rp "  Where should the workspace go? [${DEFAULT_WORKSPACE}] " input
    WORKSPACE="${input:-$DEFAULT_WORKSPACE}"
  fi
fi

# Expand ~ and make absolute
WORKSPACE="${WORKSPACE/#\~/$HOME}"
if [[ "$WORKSPACE" != /* ]]; then
  WORKSPACE="$PWD/$WORKSPACE"
fi
# Remove trailing slash
WORKSPACE="${WORKSPACE%/}"

# Check if workspace exists and is non-empty (only relevant for fresh init)
if [ -d "$WORKSPACE" ] && [ "$(ls -A "$WORKSPACE" 2>/dev/null)" ] && ! $UPGRADE; then
  error "Directory already exists and is not empty: $WORKSPACE"
  echo "  If you want to add missing files to an existing workspace, run:" >&2
  echo "    bash init.sh --upgrade --workspace \"$WORKSPACE\"" >&2
  echo "  If you want a fresh install, choose a different path." >&2
  exit 1
fi

info "Workspace: $WORKSPACE"

# ─── Gather user info ────────────────────────────────────────────────────────
heading "About you..."

if $NONINTERACTIVE; then
  if [ -z "$OPERATOR_NAME" ]; then
    error "--noninteractive requires --name"
    exit 1
  fi
  if [ -z "$OPERATOR_EMAIL" ]; then
    error "--noninteractive requires --email"
    exit 1
  fi
else
  if [ -z "$OPERATOR_NAME" ]; then
    read -rp "  Your name: " OPERATOR_NAME
    while [ -z "$OPERATOR_NAME" ]; do
      warn "Name cannot be empty."
      read -rp "  Your name: " OPERATOR_NAME
    done
  fi

  if [ -z "$OPERATOR_EMAIL" ]; then
    read -rp "  Your email: " OPERATOR_EMAIL
    while [ -z "$OPERATOR_EMAIL" ] || [[ "$OPERATOR_EMAIL" != *@* ]]; do
      warn "Please enter a valid email address."
      read -rp "  Your email: " OPERATOR_EMAIL
    done
  fi

  read -rp "  Lead's name [${LEAD_NAME}]: " input
  LEAD_NAME="${input:-$LEAD_NAME}"

  read -rp "  How should the lead address you? [${OPERATOR_ADDRESSED_AS}]: " input
  OPERATOR_ADDRESSED_AS="${input:-$OPERATOR_ADDRESSED_AS}"

  read -rp "  Labs research lead name [${LAB_LEAD_NAME}]: " input
  LAB_LEAD_NAME="${input:-$LAB_LEAD_NAME}"
fi

info "Operator: $OPERATOR_NAME <$OPERATOR_EMAIL>"
info "Lead name: $LEAD_NAME  |  addresses you as: $OPERATOR_ADDRESSED_AS"
info "Labs lead: $LAB_LEAD_NAME"

# ─── Scaffold ────────────────────────────────────────────────────────────────
heading "Scaffolding workspace..."

TODAY="$(date '+%Y-%m-%d')"
HQ_PATH="$WORKSPACE/hq"

# ── HQ skeleton ───────────────────────────────────────────────────────────────
ensure_dir "$HQ_PATH"
ensure_dir "$HQ_PATH/.claude/hooks"
ensure_dir "$HQ_PATH/skills/dev-workflow"
ensure_dir "$HQ_PATH/skills/compact-handover"
ensure_dir "$HQ_PATH/inbox/requests"
ensure_dir "$HQ_PATH/inbox/chats"
ensure_dir "$HQ_PATH/inbox/todos"
ensure_dir "$HQ_PATH/inbox/processed"
ensure_dir "$HQ_PATH/runlog"
ensure_dir "$HQ_PATH/decisions"
ensure_dir "$HQ_PATH/handovers"
ensure_dir "$HQ_PATH/follow-ups"
ensure_dir "$HQ_PATH/secrets"
ensure_dir "$HQ_PATH/projects"

# HQ files
write_file "$TEMPLATES/hq/CLAUDE.md"                          "$HQ_PATH/CLAUDE.md"
write_file "$TEMPLATES/hq/lessons.md"                         "$HQ_PATH/lessons.md"
write_file "$TEMPLATES/hq/crew.yml"                           "$HQ_PATH/crew.yml"
write_file "$TEMPLATES/hq/STATE.md"                           "$HQ_PATH/STATE.md"
write_file "$TEMPLATES/hq/.claude/settings.json"              "$HQ_PATH/.claude/settings.json"
write_file "$TEMPLATES/hq/.claude/hooks/boot.sh"              "$HQ_PATH/.claude/hooks/boot.sh"
write_file "$TEMPLATES/hq/.claude/hooks/compact-boot.sh"      "$HQ_PATH/.claude/hooks/compact-boot.sh"
write_file "$TEMPLATES/hq/skills/dev-workflow/SKILL.md"       "$HQ_PATH/skills/dev-workflow/SKILL.md"
write_file "$TEMPLATES/hq/skills/compact-handover/SKILL.md"   "$HQ_PATH/skills/compact-handover/SKILL.md"
write_file "$TEMPLATES/hq/runlog/README.md"                   "$HQ_PATH/runlog/README.md"
write_file "$TEMPLATES/hq/decisions/README.md"                "$HQ_PATH/decisions/README.md"
write_file "$TEMPLATES/hq/handovers/README.md"                "$HQ_PATH/handovers/README.md"
write_file "$TEMPLATES/hq/follow-ups/README.md"               "$HQ_PATH/follow-ups/README.md"
write_file "$TEMPLATES/hq/inbox/README.md"                    "$HQ_PATH/inbox/README.md"
write_file "$TEMPLATES/hq/secrets/README.md"                  "$HQ_PATH/secrets/README.md"
write_file "$TEMPLATES/hq/secrets/.gitignore"                 "$HQ_PATH/secrets/.gitignore"
write_file "$TEMPLATES/hq/projects/README.md"                 "$HQ_PATH/projects/README.md"

touch_file "$HQ_PATH/inbox/requests/.gitkeep"
touch_file "$HQ_PATH/inbox/chats/.gitkeep"
touch_file "$HQ_PATH/inbox/todos/.gitkeep"
touch_file "$HQ_PATH/inbox/processed/.gitkeep"

info "HQ scaffolded at $HQ_PATH"

# ── Labs skeleton ─────────────────────────────────────────────────────────────
LABS_PATH="$WORKSPACE/labs"
ensure_dir "$LABS_PATH"
ensure_dir "$LABS_PATH/inbox/requests"
ensure_dir "$LABS_PATH/inbox/processed"
ensure_dir "$LABS_PATH/research/_per_project_template/topics"
ensure_dir "$LABS_PATH/research/_per_project_template/findings"
ensure_dir "$LABS_PATH/handoffs"

write_file "$TEMPLATES/labs/README.md"                                    "$LABS_PATH/README.md"
write_file "$TEMPLATES/labs/STATE.md"                                     "$LABS_PATH/STATE.md"
write_file "$TEMPLATES/labs/queue.md"                                     "$LABS_PATH/queue.md"
write_file "$TEMPLATES/labs/crew.yml"                                     "$LABS_PATH/crew.yml"
write_file "$TEMPLATES/labs/inbox/README.md"                              "$LABS_PATH/inbox/README.md"
write_file "$TEMPLATES/labs/research/README.md"                           "$LABS_PATH/research/README.md"
write_file "$TEMPLATES/labs/research/_per_project_template/STATE.md"      "$LABS_PATH/research/_per_project_template/STATE.md"
write_file "$TEMPLATES/labs/handoffs/README.md"                           "$LABS_PATH/handoffs/README.md"

touch_file "$LABS_PATH/inbox/requests/.gitkeep"
touch_file "$LABS_PATH/inbox/processed/.gitkeep"
touch_file "$LABS_PATH/research/_per_project_template/topics/.gitkeep"
touch_file "$LABS_PATH/research/_per_project_template/findings/.gitkeep"

info "Labs scaffolded at $LABS_PATH"

# ── Projects placeholder ──────────────────────────────────────────────────────
ensure_dir "$WORKSPACE/projects"
touch_file "$WORKSPACE/projects/.gitkeep"

info "Projects directory created at $WORKSPACE/projects"

# ── Workspace-root .claude redirect ───────────────────────────────────────────
# Installs a SessionStart hook at the workspace root so users who accidentally
# `cd vibeboss-workspace/ && claude` get a friendly redirect to hq/ instead of
# a blank vanilla session.
ensure_dir "$WORKSPACE/.claude/hooks"

write_file "$TEMPLATES/_workspace_root/.claude/settings.json"         "$WORKSPACE/.claude/settings.json"
write_file "$TEMPLATES/_workspace_root/.claude/hooks/redirect.sh"     "$WORKSPACE/.claude/hooks/redirect.sh"
write_file "$TEMPLATES/_workspace_root/.claude/hooks/redirect.md"     "$WORKSPACE/.claude/hooks/redirect.md"

info "Workspace-root redirect hook installed at $WORKSPACE/.claude"

# ─── Make hooks executable ────────────────────────────────────────────────────
if ! $DRY_RUN; then
  chmod +x "$HQ_PATH/.claude/hooks/boot.sh"
  chmod +x "$HQ_PATH/.claude/hooks/compact-boot.sh"
  chmod +x "$WORKSPACE/.claude/hooks/redirect.sh"
fi

# ─── Smoke-test the boot hook ─────────────────────────────────────────────────
if ! $DRY_RUN && ! $UPGRADE; then
  if command -v python3 &>/dev/null; then
    heading "Verifying boot hook..."
    HOOK_OUT="$("$HQ_PATH/.claude/hooks/boot.sh" 2>&1 || true)"
    if echo "$HOOK_OUT" | python3 -c "import json, sys; d=json.load(sys.stdin); assert 'additionalContext' in d['hookSpecificOutput']" 2>/dev/null; then
      info "Boot hook emits valid JSON with additionalContext"
    else
      warn "Boot hook verification failed — the hook script may have an issue."
      warn "Hook output: ${HOOK_OUT:0:200}"
      warn "Once python3 is installed, verify with: bash ${HQ_PATH}/.claude/hooks/boot.sh | python3 -m json.tool"
    fi
  else
    warn "Skipping boot hook verification (python3 not available)."
  fi
fi

# ─── Version metadata ────────────────────────────────────────────────────────
# Pin the workspace to the source version + sha so future --update runs know
# where they started from.
write_version_metadata

# ─── Success block ────────────────────────────────────────────────────────────
cat <<SUCCESS


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Vibeboss workspace ready
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ${BOLD}${GREEN}✓${RESET} ${WORKSPACE}

  Next steps:

  1. Start your first session:
       cd "${WORKSPACE}/hq" && claude
     ${LEAD_NAME} will auto-boot with a briefing.

  2. Tell ${LEAD_NAME} what you want to build.
     It will ask the right questions, then dispatch.

  3. When you add a project, ${LEAD_NAME} will help you
     set up its inbox and crew entry.

  Tip: the master dashboard (optional) gives you a live
  view of all sessions. See the Vibeboss README for setup.

  Future updates:
       bash $SCRIPT_DIR/init.sh --update --workspace "$WORKSPACE"

SUCCESS

if $DRY_RUN; then
  warn "DRY RUN complete — no files were written."
fi
