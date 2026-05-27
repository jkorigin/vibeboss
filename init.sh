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
#   --dry-run               show what would be done without writing anything
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
DRY_RUN=false

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
  --dry-run               show what would be done without writing anything
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
    --dry-run)        DRY_RUN=true;                shift   ;;
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
cat <<'BANNER'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Vibeboss — workspace init
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BANNER

if $DRY_RUN; then
  warn "DRY RUN — no files will be written."
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

DEFAULT_WORKSPACE="$HOME/ventures/vibeboss-workspace"

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
  printf '%s' "$text"
}

# write_file — write a file from a template, substituting placeholders
# Usage: write_file <src_template> <dest_path>
write_file() {
  local src="$1"
  local dest="$2"

  if $UPGRADE && [ -f "$dest" ]; then
    return 0  # skip existing files in upgrade mode
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

SUCCESS

if $DRY_RUN; then
  warn "DRY RUN complete — no files were written."
fi
