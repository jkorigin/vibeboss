# Spec: `vibeboss init` flow — 2026-05-26

**Author:** Boss (Subsystem G spawn)
**Status:** Shipped
**Subsystem:** G of 7 (the final subsystem of Phase 0)

---

## Problem

A new user cloning the Vibeboss repo gets a framework with documented patterns but no scaffolded workspace. The manual setup described in `docs/runtime-layout.md` requires creating 20+ directories and files, substituting personal details in a dozen places, setting hook permissions, and validating that the boot sequence works. This is too high a barrier for the target user (non-technical 40+ operators).

## Solution

A single bash script — `vibeboss/init.sh` — that:
1. Checks prerequisites (claude CLI, python3)
2. Asks ≤8 questions (workspace path, name, email, lead name, address term, lab lead name)
3. Scaffolds the full `{hq,labs,projects}/` workspace from `vibeboss/templates/`
4. Substitutes 8 placeholders throughout
5. Makes hook scripts executable
6. Smoke-tests the boot hook
7. Prints a three-step "what to do next" block

Target time: fresh user runs `bash init.sh`, presses Enter 6 times, and has a bootable HQ in under 2 minutes.

## Placeholder schema

| Placeholder | Default | What it controls |
|---|---|---|
| `{{LEAD_NAME}}` | Boss | The AI venture lead's name |
| `{{OPERATOR_NAME}}` | *(required)* | The operator's real name |
| `{{OPERATOR_EMAIL}}` | *(required)* | The operator's email |
| `{{OPERATOR_ADDRESSED_AS}}` | partner | How the lead addresses the operator |
| `{{LAB_LEAD_NAME}}` | Ginger | The labs research lead's name |
| `{{WORKSPACE}}` | `$HOME/ventures/vibeboss-workspace` | Absolute path to the workspace root |
| `{{HQ_PATH}}` | `{{WORKSPACE}}/hq` | Absolute path to HQ (used in settings.json hook commands) |
| `{{DATE}}` | Today (YYYY-MM-DD) | Initialization date stamped in STATE.md and crew.yml |

## Template tree

```
vibeboss/templates/
├── hq/
│   ├── CLAUDE.md                      ← lead identity + dispatch model
│   ├── lessons.md                     ← LESSONS 001-006 (generic)
│   ├── crew.yml                       ← operator + lead + empty agents list
│   ├── STATE.md                       ← fresh-install initial state
│   ├── .claude/
│   │   ├── settings.json              ← SessionStart hooks (uses {{HQ_PATH}})
│   │   └── hooks/
│   │       ├── boot.sh                ← auto-boot brief (same as installed version)
│   │       └── compact-boot.sh       ← post-compact injector (Linux stat fallback added)
│   ├── skills/
│   │   ├── dev-workflow/SKILL.md
│   │   └── compact-handover/SKILL.md
│   ├── inbox/README.md
│   ├── runlog/README.md
│   ├── decisions/README.md
│   ├── handovers/README.md
│   ├── follow-ups/README.md
│   ├── secrets/README.md
│   ├── secrets/.gitignore             ← ignores all files except README + .gitignore
│   └── projects/README.md
├── labs/
│   ├── README.md                      ← three-flow protocol + directory layout
│   ├── STATE.md                       ← fresh-install initial state
│   ├── queue.md                       ← empty queue with format guide
│   ├── crew.yml                       ← lab lead (born_at: null initially)
│   ├── inbox/README.md
│   ├── research/
│   │   ├── README.md
│   │   └── _per_project_template/    ← copy this to add a new research area
│   │       ├── STATE.md
│   │       ├── topics/.gitkeep
│   │       └── findings/.gitkeep
│   └── handoffs/README.md
└── projects/.gitkeep
```

## Script modes

| Mode | Flag | Behavior |
|---|---|---|
| Fresh install | *(default)* | Full scaffold; refuses to overwrite non-empty workspace |
| Non-interactive | `--noninteractive` | No prompts; requires `--name` and `--email` |
| Upgrade / repair | `--upgrade` | Adds missing files; skips existing; idempotent |
| Dry run | `--dry-run` | Prints what would be done; writes nothing |

## Boot hook smoke test

After scaffolding (fresh install only), the script runs the boot hook and validates that it emits JSON with `hookSpecificOutput.additionalContext`. This catches permission issues, python3 absence (warned in prereqs), and any template substitution errors that broke the hook syntax. Skipped when python3 is absent (already warned in prereqs block).

## What is NOT included

- Master dashboard: installation-specific; separate optional step
- Project-level directories (`hq/projects/<name>/`): created by the lead when the first project is added
- Windows support: deferred (macOS/Linux only)

## Deferred items (JSON)

```json
[
  "Windows support — MINGW/CYGWIN/MSYS rejection with link to tracking issue",
  "bun prerequisite check — bun used by master dashboard but not by init itself; deferred until dashboard-bootstrap.sh",
  "dashboard-bootstrap.sh — separate optional script for master dashboard setup",
  "project scaffold helper — vibeboss add-project <name> command to create hq/projects/<name>/ interactively"
]
```
