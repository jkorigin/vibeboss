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
- **Subsystem F-ish — Labs as continuous research function.** `vibeboss-workspace/labs/` mirrors project structure (`research/<example-project>/`, `research/master-dashboard/`, `research/hq/`). Ginger (research lead) born; first 4 research streams kicked off for <example-project>. Three protocols documented: Boss→labs, dev-lead→labs, labs→dev-lead handoff.
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

- **Blocker 1 — Portable hook paths.** `vibeboss/.claude/settings.json` was hardcoded to the partner's absolute path. Now committed with `VIBEBOSS_DIR_PLACEHOLDER`; `reno.sh` substitutes the real path at startup and restores the placeholder on exit (trap-restore pattern). See `decisions/2026-05-26-portable-hook-paths.md`.
- **Blocker 2 — Workspace-root redirect template.** Added `templates/_workspace_root/.claude/` with `settings.json`, `hooks/redirect.sh`, and `hooks/redirect.md`. `init.sh` now installs it at workspace root on every fresh install. Users who accidentally `cd <workspace>/ && claude` now get a redirect instead of a blank session.
- **Blocker 3 — Git repository initialized.** `vibeboss/` now has a git repo, v0.1.0 tagged.
- **Blocker 4 — Partner-specific data audit.** Removed `.claude/launch.json` (hardcoded runtime paths, not OSS canon). Redacted phone number identity from `docs/superpowers/plans/2026-05-26-topology-hq-split.md`. Removed absolute path mention from CHANGELOG. See `decisions/2026-05-26-partner-data-audit.md`.
- **Blocker 5 — Template `crew.yml` clean.** Already correct at time of v0.1.0 ship (`agents: []`, `next_available: Artichoke`). No change needed.

### Added

- `decisions/2026-05-26-portable-hook-paths.md` — documents the hook-path portability approach.
- `decisions/2026-05-26-partner-data-audit.md` — documents what was found and fixed in the audit.
- `decisions/2026-05-26-workspace-root-redirect-template.md` — documents why the workspace-root redirect was added to templates.
- `.gitignore` entries for `.claude/launch.json` and the reno.sh backup file.

### Deferred

- `dashboard-bootstrap.sh` template — dashboard scaffold for OSS users.
- Windows support (`mingw`/`cygwin`/`msys` compatibility).
- `vibeboss add-project <name>` interactive scaffolder.
- Shell alias injection (`alias vb=...`) into user's shell rc.
- Tests / CI — `tests/init-smoke.sh` and a GitHub Actions workflow.
- Minimum Claude Code version documented in README prerequisites.
- `CONTRIBUTING.md` stub.
