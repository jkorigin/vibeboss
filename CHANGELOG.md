# Changelog

All notable changes to Vibeboss. Format loosely follows [Keep a Changelog](https://keepachangelog.com/). Versions follow [SemVer](https://semver.org/).

## [v0.1.0] — 2026-05-26 — first OSS-ready cut

The 7-subsystem framework arc + Vibe Chief mode shipped. Vibeboss is now installable from a clone in under 2 minutes via `init.sh`, and enhanceable via `reno.sh`.

### Added

- **Subsystem A — Topology + HQ split.** Source/runtime separation: `vibeboss/` source vs `vibeboss-workspace/{hq, labs, projects/}` runtime. Per-project memory routing under `hq/projects/<name>/`. See [docs/superpowers/specs/2026-05-26-topology-hq-split-design.md](docs/superpowers/specs/2026-05-26-topology-hq-split-design.md).
- **Subsystem B — Dev-workflow skill.** The standard build loop (research → build → test → ≥3 bug-fix → fresh-agent review → ≥3 tighten → human gate) codified as a skill installed at `hq/skills/dev-workflow/SKILL.md`. LESSON-005 wires it into Boss's decision loop.
- **Subsystem C — Crew system.** Per-project named build leads in `hq/crew.yml`. Inbox dispatch (`hq/projects/<name>/inbox/requests/`) for async; spawn dispatch (`claude --session-id <uuid>`) for sync. Naming theme: produce (vegetables / fruits / herbs).
- **Subsystem D — Auto-boot.** SessionStart hook at `hq/.claude/settings.json` calls `boot.sh` on every fresh/resumed session and injects the boot brief as `additionalContext`. Partner never types `boot`.
- **Subsystem E — Compact handover protocol.** Pre-`/compact` ritual writes a structured handover file at `hq/handovers/YYYY-MM-DD-HHMM-<slug>.md`. Post-compact hook (`compact-boot.sh`) injects the latest handover as additional context. Session never closes. Five self-monitoring triggers (T1-T5) defined in `hq/skills/compact-handover/SKILL.md`. LESSON-006 hard-gates the discipline.
- **Subsystem F-ish — Labs as continuous research function.** `vibeboss-workspace/labs/` mirrors project structure (`research/<project-name>/`, plus an `hq/` track for framework research). The labs lead identity (Ginger) is reserved in the template `labs/crew.yml`. Three protocols documented: Boss→labs, dev-lead→labs, labs→dev-lead handoff.
- **Subsystem G — `init.sh` installer.** Single-command workspace scaffolding from `templates/`. 6 interactive prompts, 4 modes (fresh/noninteractive/upgrade/dry-run), 34 template files, smoke test verifies a clean install. Quick Start documented in README.
- **Master dashboard.** `vibeboss-workspace/hq/dashboard/` — Bun-served operator view at port 3100 surfacing all running CC sessions, per-project status, JSONL activity stream, and HQ state. Currently lives in the partner's workspace; a `dashboard-bootstrap.sh` template for OSS users is a deferred follow-up.
- **Vibe Chief mode.** `bash reno.sh` boots Vibe Chief — the framework canon caretaker — at the source repo. SessionStart hook at `vibeboss/.claude/` routes to either Vibe Chief (when `VIBEBOSS_RENO=1`) or a polite redirect (when partner accidentally cd's here). Decision documenting the dual-mode pattern at `decisions/2026-05-26-dual-mode-boss-and-vibe-chief.md` (forthcoming).

### Discipline rules (LESSONS that ship with the framework templates)

- **LESSON-001:** Identity — Boss / partner naming convention.
- **LESSON-002:** Default to build, not improve-the-office.
- **LESSON-003:** Research-first on ambiguity (refinement of LESSON-002).
- **LESSON-004:** Default execution mode is subagent-driven.
- **LESSON-005:** Invoke `dev-workflow` skill before any non-trivial implementation.
- **LESSON-006:** Write compact-handover BEFORE `/compact`. No exceptions.

### Known follow-ups (deferred to v0.2.0 or later)

- **Portable hook paths in `vibeboss/.claude/settings.json`.** The hook command was hardcoded to an absolute path, breaking on any clone at a different path. Fix via `reno.sh` self-substitution (see decisions/2026-05-26-portable-hook-paths.md). Tracked as the highest-priority v0.2.0 fix.
- `dashboard-bootstrap.sh` template — package the master dashboard scaffold so OSS users can install it.
- Windows support — `init.sh` currently rejects Windows; needs `mingw`/`cygwin`/`msys` compatibility.
- `vibeboss add-project <name>` — interactive project scaffolder.
- Shell alias support — `vibeboss reno` as a real command instead of `bash reno.sh`. Plus an `alias vb='cd ~/ventures/vibeboss-workspace/hq && claude'` suggestion in install output (or auto-injected into shell rc on install).
- **Workspace-root SessionStart redirect in templates.** Users who accidentally `cd ~/ventures/vibeboss-workspace/` (instead of `hq/`) currently get a vanilla Claude session with no Boss context — confusing failure mode. Fix: add `templates/_workspace_root/.claude/{settings.json,hooks/redirect.{sh,md}}` and have `init.sh` install it at workspace root. Already implemented manually for the current installation at `vibeboss-workspace/.claude/`; needs templating for future users.
- Long-running framework agent code — Phase 1 begins when this lands.

---

## [unreleased] — v0.2.0 in progress

### Fixed (OSS-ready cleanup pass — 2026-05-26)

- **Blocker 1 — Portable hook paths (initial fix, now superseded).** `vibeboss/.claude/settings.json` was hardcoded to the partner's absolute path. First fix: committed with `VIBEBOSS_DIR_PLACEHOLDER`; `reno.sh` substituted the real path on startup and restored the placeholder on exit (trap-restore). Superseded on 2026-05-27 — see Audit-fix pass below.
- **Blocker 2 — Workspace-root redirect template.** Added `templates/_workspace_root/.claude/` with `settings.json`, `hooks/redirect.sh`, and `hooks/redirect.md`. `init.sh` now installs it at workspace root on every fresh install. Users who accidentally `cd <workspace>/ && claude` now get a redirect instead of a blank session.
- **Blocker 3 — Git repository initialized.** `vibeboss/` now has a git repo, v0.1.0 tagged.
- **Blocker 4 — Partner-specific data audit.** Removed `.claude/launch.json` (hardcoded runtime paths, not OSS canon). Redacted phone number identity from `docs/superpowers/plans/2026-05-26-topology-hq-split.md`. Removed absolute path mention from CHANGELOG. See `decisions/2026-05-26-partner-data-audit.md`.
- **Blocker 5 — Template `crew.yml` clean.** Already correct at time of v0.1.0 ship (`agents: []`, `next_available: Artichoke`). No change needed.

### Audit-fix pass (2026-05-27)

Full self-audit identified overclaims in the README, residual partner-specific data, fragile hook-path mechanism, missing tests, and over-rigid dev-workflow gates. Fixes below.

**Public surface — honest repositioning**
- **README rewritten.** Replaced "AI-as-Boss autonomous OS" framing with an accurate description of what v0.1.0 ships (memory-disciplined Claude Code workspace via conventions + hooks). "What this will be" trimmed to features that actually exist (state/runlog/decisions, LESSONS, inbox protocol, auto-boot, compact-handover, crew). The open-source contradiction (clone URL vs. "not yet open source") resolved: Status now reads "Phase 0 — Feasibility Investigation. v0.1.0 is the first OSS-ready cut." See `decisions/2026-05-27-readme-honest-repositioning.md`.
- **`ROADMAP.md` added.** Aspirational features moved here: bugs-get-fixed loop with reproducer/verify tooling, STOP-file kill switch, Main/Builder/Research as real processes, dashboard OSS scaffold, multi-venture/teams story, plus the deferred items pulled from this CHANGELOG.
- **`CONTRIBUTING.md` stub added.** Explains the closed-until-Phase-2 boundary and points framework-dev work at `bash reno.sh`.

**Hook portability — supersedes 2026-05-26 fix**
- **`${CLAUDE_PROJECT_DIR}` replaces the trap-restore pattern.** All `settings.json` hook commands now use `${CLAUDE_PROJECT_DIR}/.claude/hooks/<script>.sh`. Claude Code expands the env var at hook execution time. The trap-restore mechanism in `reno.sh` is deleted (concurrency hazard, crash-leaves-dirty-tree, heredoc fragility). `reno.sh` is now a thin wrapper. See `decisions/2026-05-27-claude-project-dir-hook-paths.md` (supersedes `2026-05-26-portable-hook-paths.md`).
- **`{{HQ_PATH}}` / `{{WORKSPACE}}` placeholders in template `settings.json` files also replaced with `${CLAUDE_PROJECT_DIR}`.** Installed workspaces now survive renaming or moving.
- **`clear` matcher added** alongside `startup` and `resume` in all three `settings.json` files. `/clear` no longer silently skips the boot brief.

**Boot script hardening**
- **`templates/hq/.claude/hooks/boot.sh`:** the AWK crew parser (field-order dependent — broke if user reordered YAML keys) was replaced with a Python parser. A new `--brief-only` flag emits the plain brief text (no JSON wrapper) for internal callers; default behavior unchanged.
- **`templates/hq/.claude/hooks/compact-boot.sh`:** uses `boot.sh --brief-only` instead of piping JSON-wrap → JSON-parse → re-wrap. Eliminates double encoding.

**Tests + CI**
- **`tests/init-smoke.sh`** added — the framework's first test. Runs `init.sh --noninteractive` against a temp workspace, verifies all required files + executable bits, validates the boot hook emits `additionalContext`, and grep-checks that no `{{...}}` placeholder remains unsubstituted in any generated `.md`. Trap-cleans on exit.
- **`.github/workflows/ci.yml`** added — ubuntu-latest, runs the smoke test on every push and PR to main. Minimal surface.
- **`tests/README.md`** added — how to run locally.
- See `decisions/2026-05-27-first-test-and-ci.md`.

**Discipline alignment**
- **`templates/hq/skills/dev-workflow/SKILL.md`:** softened Phase 3 (bug-fix) and Phase 5 (tighten) "≥3 rounds" hard gates. Three rounds remain the default; explicit carve-out for <50 LOC changes when the preceding round revealed nothing, with the skip logged in the runlog. Realigns dev-workflow with LESSON-002 ("default to build, not improve-the-office"). See `decisions/2026-05-27-dev-workflow-rounds-softening.md`.

**Partner-data scrub (round 2)**
- The 2026-05-26 partner-data audit missed several spots. The 2026-05-27 grep + scrub touched: `CHANGELOG.md` (`<example-project>` reference + spurious "4 research streams" runtime claim), `CLAUDE.md` (illustrative-marker on `Banana / Carrot / Ginger`), `decisions/2026-05-26-dual-mode-boss-and-vibe-chief.md`, `docs/superpowers/plans/2026-05-26-master-dashboard.md`, `docs/superpowers/specs/2026-05-26-master-dashboard-design.md`, `docs/superpowers/specs/2026-05-26-crew-system-design.md`, `docs/superpowers/plans/2026-05-26-crew-system.md`, `docs/superpowers/specs/2026-05-26-topology-hq-split-design.md`. Identifiers either replaced with placeholders or qualified as illustrative.

**Misc**
- **`VERSION` file added** (`0.2.0-dev`). Both `init.sh` and `reno.sh` now support `--version` / `-v`.
- **`CHIEF.md` line 32:** stripped the "create on first run" branch from the boot sequence — CHANGELOG already exists.
- **`crew.yml.template` deleted** — dead file at repo root (different placeholder schema than `init.sh` substitutes, not referenced by any script).
- **`.gitignore` pruned** — removed Phase 1+ cargo-cult entries (`node_modules/`, `dist/`, `build/`, `.next/`, `.turbo/`, `__pycache__/`, `*.pyc`, `.venv/`, `venv/`) and the now-obsolete `settings.json.reno-bak` entry.

### Added (file-level summary)

- `VERSION`
- `ROADMAP.md`
- `CONTRIBUTING.md`
- `tests/init-smoke.sh` + `tests/README.md`
- `.github/workflows/ci.yml`
- `decisions/2026-05-26-portable-hook-paths.md` (from earlier 05-26 pass)
- `decisions/2026-05-26-partner-data-audit.md` (from earlier 05-26 pass)
- `decisions/2026-05-26-workspace-root-redirect-template.md` (from earlier 05-26 pass)
- `decisions/2026-05-27-claude-project-dir-hook-paths.md` (supersedes 05-26-portable-hook-paths)
- `decisions/2026-05-27-readme-honest-repositioning.md`
- `decisions/2026-05-27-first-test-and-ci.md`
- `decisions/2026-05-27-dev-workflow-rounds-softening.md`

### Removed

- `crew.yml.template` (dead file).
- Trap-restore block in `reno.sh` (superseded by `${CLAUDE_PROJECT_DIR}`).
- `VIBEBOSS_DIR_PLACEHOLDER` strings throughout.

### Deferred (carried forward, see ROADMAP.md for full list)

- `dashboard-bootstrap.sh` template — dashboard scaffold for OSS users.
- Windows support (`mingw`/`cygwin`/`msys` compatibility).
- `vibeboss add-project <name>` interactive scaffolder.
- Shell alias injection (`alias vb=...`) into user's shell rc.
- `--rename` mode for `init.sh` — post-install identity renames.
- **Git hooks for co-author attribution.** Local-only `.git/hooks/prepare-commit-msg` was installed in this clone to auto-rewrite Claude Code's `Co-Authored-By: Claude ...` trailer to `vibechief <vibechief@vibeboss.local>` (in `vibeboss/`) or `boss <boss@vibeboss.local>` (in `vibeboss-workspace/*`). Hook is *not* tracked in the repo because `.git/hooks/` is local-only. Fix: commit a `tools/install-hooks.sh` that installs hooks from `tools/hooks/prepare-commit-msg` into `.git/hooks/`. `init.sh` should also install the hook into any new git repos partner creates in `vibeboss-workspace/*` so attribution is automatic everywhere.
