# Roadmap

Vibeboss is in Phase 0 — Feasibility Investigation. v0.1.0 ships the memory and discipline harness. The runtime engine and the broader vision live in later phases. This file is the honest accounting of what's planned vs. what's built.

For what *is* shipped today, see [README.md](README.md#what-ships-today) and [CHANGELOG.md](CHANGELOG.md).

---

## Recently shipped (v0.2.6)

PreCompact handover mechanism — supersedes v0.2.4's Stop-hook design which failed the keyword-test acceptance gate same-day it shipped. Boss diagnosed the failure modes, designed + verified the replacement live, filed the port spec via the v0.2.3 framework-feedback channel; Vibe Chief ported into canon. See [decisions/2026-05-28-precompact-handover-mechanism.md](decisions/2026-05-28-precompact-handover-mechanism.md).

- **`templates/hq/.claude/hooks/pre-compact.sh`** — fires AT compaction (auto + manual), captures last 8 partner turns verbatim + last 3 agent turns + widened marker grep across full session.
- **Codex compatibility pass** — fresh installs now scaffold `AGENTS.md` at workspace root, HQ, labs, and projects; source/HQ/workspace-root `.codex/hooks.json` mirrors the Claude boot/redirect contexts. Verified by `tests/init-smoke.sh`. See [decisions/2026-05-28-codex-compatibility.md](decisions/2026-05-28-codex-compatibility.md).
- **Pinned/rolling separation** — `_pinned/*.md` (durable, agent-or-partner-written) vs `_current.md` (rolling, PreCompact-written). `compact-boot.sh` injects pinned-first to defeat keyword-displacement.
- **`templates/hq/handovers/_pinned/`** new directory + README documenting the distinction.
- **Stop hook removed** from `templates/hq/.claude/hooks/update-handover.sh` and settings.json.
- **Migration `v0.2.5-dev-to-v0.2.6-dev.sh`** backfills `_pinned/` + removes update-handover.sh on legacy installs (with hash check to preserve user customizations).
- **CLAUDE.md "Compact handover" section** rewritten from Stop-hook framing to PreCompact + pinned/rolling framing.
- **Smoke test** regression-guards: settings.json has PreCompact + no Stop block; pre-compact.sh present + executable; _pinned/README exists; update-handover.sh does NOT exist.

End-to-end keyword-test passed live before this canon port — partner's phrase `cat climb clock tower dog run stairs eagle beats the eye` survived `/compact` and led the post-compact response verbatim.

## Recently shipped (v0.2.5)

Agent-as-operator: the framework no longer assumes partner runs scripts. Boss + Vibe Chief + per-project build leads all execute CLI on partner's verbal request and report results, not commands. Closes the second weird trait partner flagged (the first — $10 cost parroting — was fixed in commit 28dab5a). See [decisions/2026-05-28-agent-as-operator.md](decisions/2026-05-28-agent-as-operator.md).

- **LESSON-009 — Agent-as-operator.** Boss runs scripts; partner speaks intent. Hard-gated in `templates/hq/lessons.md`. The one exception is the unavoidable `bash init.sh` bootstrap.
- **Partner-facing protocols section in `templates/hq/CLAUDE.md`.** Canonical mappings for "Apply the update", "Start a new project", "There's a framework bug", "Show me what's in the inbox" — Boss has a script for what to confirm, what to run via the Bash tool, and how to report results.
- **CHIEF.md mirror.** Same shape for Vibe Chief: "Pull the latest", "Apply this to the workspace", "Address the framework feedback", "Ship this".
- **Verbal-form update banner.** `templates/hq/.claude/hooks/boot.sh` rewritten from command-form ("Run `bash init.sh --update ...`") to verbal-form ("Say 'apply it' and I'll run it"). Regression-guarded in the smoke test.
- **README rewrite.** User-facing sections (To *update*, Recommended companions) reframed as conversational flows. Quick Start bootstrap preserved (the one CLI moment) with an explicit "after this you never type a command again" follow-on. New "Reference: under the hood" appendix table maps verbal intent → underlying command for the technically curious.
- **Per-project README mirror.** Build leads get the same Partner-facing protocols section — "Run the tests", "Ship this", "Fix the build", "Status update", etc.

## Recently shipped (v0.2.4)

Rolling handover mechanism — compact handover converted from agent self-discipline (T1-T5 triggers) to mechanism-driven enforcement via a Stop hook that fires every turn. See [decisions/2026-05-28-rolling-handover-mechanism.md](decisions/2026-05-28-rolling-handover-mechanism.md).

- **`templates/hq/.claude/hooks/update-handover.sh`** — Stop hook (178 lines). Parses the live transcript JSONL each turn, writes `hq/handovers/_current.md` with last partner message, last agent response, and grepped markers (`KEYWORD:` / `REMEMBER:` / `TODO:` / etc.). Idempotent, never blocks the assistant.
- **Stop hook registration** in `templates/hq/.claude/settings.json` using the `${CLAUDE_PROJECT_DIR}` portable path.
- **`init.sh` scaffolds the new hook + makes it executable** on fresh install (the gap Vibe Chief caught when landing — Boss's draft registered the hook but didn't install it).
- **CLAUDE.md "Compact handover" section rewritten** from "agent must self-detect T1-T5 and write a handover" to "Stop hook + compact-boot.sh do this automatically as the baseline; rich dated handovers are an optional override layer." The five triggers are reframed as opt-in moments for the rich layer.

## Recently shipped (v0.2.3)

Three discipline shifts at the seams: Boss now outputs the boot brief proactively, has a sanctioned channel back to Vibe Chief for framework-level observations, and all numerical claims are now provenance-tagged. See [decisions/2026-05-28-feedback-channel-and-calibration.md](decisions/2026-05-28-feedback-channel-and-calibration.md).

- **First-response discipline (LESSON-007).** Boss + project build leads now output the boot brief as their FIRST response in every new session, regardless of what the operator says ("hi", a direct task, silence — brief comes first). Imperative language in `templates/hq/CLAUDE.md`, `templates/projects/_per_project/README.md`, and `CHIEF.md`. Closes the "auto-boot didn't fire when I said hi" failure mode observed in practice.
- **Framework feedback channel (Boss → Vibe Chief).** New `hq/follow-ups/framework/` directory in every workspace. Boss writes framework-level observations here when partner reports framework issues or Boss notices canon-level gaps. Vibe Chief reads each workspace's directory on every reno boot via the new `vibeboss/.workspaces` tracker (gitignored; `init.sh` writes the workspace path on every install / `--upgrade` / `--update` / `--add-project`). Disposition-footer protocol from v0.2.1 closes the loop; addressed items move to `processed/`.
- **Calibration log + claim-provenance discipline (LESSON-008).** Two new JSON Lines logs (`<workspace>/hq/calibration/log.jsonl` for Boss work, `<vibeboss>/calibration/log.jsonl` for Vibe Chief framework work). Schema in `calibration/README.md`. LESSON-008 requires every numerical claim to cite source (grep the log for time estimates; run the count for file counts; cite the measurement for percentages) — or label as `guess:` with italics. Source-side calibration log seeded with retroactive entries for v0.2.0 / v0.2.1 / v0.2.2 from this session's git history (n=3 baseline).
- **Migration `v0.2.2-dev-to-v0.2.3-dev`** backfills both directories + registers the workspace for legacy installs.

## Recently shipped (v0.2.2)

Update mechanism — running workspaces can now receive framework updates safely. See [decisions/2026-05-28-update-mechanism.md](decisions/2026-05-28-update-mechanism.md) for the design.

- **Version pinning + manifest.** Every install writes `<workspace>/.vibeboss-version` (records pinned version + source path + source git SHA + timestamps) and a `<workspace>/.vibeboss/originals/<rel-path>.sha256` manifest of every template-derived file's hash at install time. This is the foundation that makes "did the user customize this file?" answerable.
- **`init.sh --update` mode.** Walks the templates tree against an existing workspace. For each file: if the workspace copy matches its installed-original hash, refresh safely; if it doesn't, prompt (keep/overwrite/diff/skip). `--noninteractive` defaults to keep, so cron-like automations stay safe. Backfills missing manifest entries for legacy workspaces.
- **Migrations infrastructure.** `vibeboss/migrations/` directory + a `run.sh` runner. Each migration is a versioned shell script (`v<from>-to-v<to>.sh`) that takes the workspace path. `--update` runs the applicable chain in lex order between installed and target versions. Documented convention; sample no-op migration shipped.
- **Boss boot banner.** When `<workspace>/.vibeboss-version` shows a version older than the source's `VERSION`, the boot brief surfaces a banner with the exact update command. Silent fail if the version file is missing or malformed — never blocks boot.

## Recently shipped (v0.2.1)

The Per-Project Skill Bundle (PPSB) arc — every Boss-created project inherits a sane skill bundle, with superpowers as the always-on baseline. See [decisions/2026-05-28-per-project-skill-bundle.md](decisions/2026-05-28-per-project-skill-bundle.md) for the design.

- **STOP-file kill switch.** Drop a `STOP` file at `hq/STOP` or `<workspace>/STOP` to halt cleanly. The boot hook detects either sentinel and emits a HALTED brief; Boss refuses new work until both the file is removed AND the operator re-authorises. Recovery protocol documented in HQ `CLAUDE.md`.
- **Per-project skill bundle (baseline scaffold + `init.sh --add-project`).** Every Boss-created project ships with a `.claude/settings.json` that pre-enables superpowers and a curated set of Vibeboss-recommended skills. The baseline is per-project (never machine-wide), so reproducibility is preserved across clones.
- **Recommended companions documented.** README now lists superpowers as the auto-enabled baseline plus the curated opt-in pool from `claude-plugins-official` (context7, code-review, pr-review-toolkit, commit-commands, frontend-design, playwright, hookify, skill-creator, claude-md-management, feature-dev, figma/vercel/firebase/sourcegraph/Notion). gstack stays external (not vendored, install per upstream README).
- **Bidirectional inbox topology.** HQ holds up+down per-counterparty files for every crew member; projects hold DOWN by default and write UP to HQ's inbox. Disposition-footer convention codifies how each side signals state.

## Phase 1 — Runtime engine

The autonomous loop. Today's cut is conventions + hooks; Phase 1 turns those into a running system.

- **Bugs that get fixed, not patched.** Reproduce → locate → fix → verify → log. No "fixed!" claims without a verification step. Requires reproducer tooling, a verify gate, and a runlog entry shape that captures the loop.
- **Don't-stop loops.** Autonomous chain hops via async spawn. The STOP-file half of the kill switch shipped in v0.2.1; the chain-hop dispatcher and don't-stop scheduler land in Phase 1.
- **Main / Builder / Research separation as real processes.** Today there's Boss plus named crew (build leads, Ginger as research lead). Phase 1 promotes the pattern: the agent that talks to the operator doesn't build — it delegates to a builder, and researches when it's unsure rather than asking. Requires a Main agent identity distinct from build leads, and a "research-first on ambiguity" enforcement path beyond LESSON-003.

## Phase 1.5 — PPSB Phase 2 (v0.3.0)

Finishing the Per-Project Skill Bundle arc once the marketplace pattern is stable.

- **Vibeboss native skill marketplace.** Add `.claude-plugin/marketplace.json` so `vibeboss-natives@vibeboss` resolves the way `superpowers@claude-plugins-official` does today. Currently the natives are file-based (symlinked into projects by `add-project`); the marketplace gives a clean update story and a single install command from anywhere.
- **`add-project` Boss skill.** Full SKILL.md for Boss with an interactive recommend-menu UX — beyond the CLI baseline shipped in v0.2.1, so the operator gets a guided pick-list when starting a new project.
- **HQ refactor to use the marketplace.** Once `vibeboss-natives@vibeboss` resolves, HQ's `.claude/settings.json` enables it through `enabledPlugins` rather than relying on file-based symlinks.

## Phase 2 — Public-repo cut

- Public GitHub repo (this is what users will clone).
- `dashboard-bootstrap.sh` — OSS scaffold for the master dashboard currently living in the partner's workspace. Bun-served operator view at port 3100, surfacing all running CC sessions, per-project status, JSONL activity stream, and HQ state.
- Open to external contribution (see [CONTRIBUTING.md](CONTRIBUTING.md)).

## Phase 3 — Multi-venture / teams

- AI office framework for teams.
- Multi-venture topology (Vibeboss running across several venture workspaces with shared canon).

---

## Deferred for v0.2.0

Honest backlog of smaller items that didn't make v0.1.0:

- **Windows support.** `init.sh` currently rejects Windows; needs `mingw`/`cygwin`/`msys` compatibility.
- **`vibeboss add-project <name>`.** Interactive project scaffolder so operators don't hand-edit `hq/projects/`.
- **Shell-alias injection.** `vibeboss reno` as a real command instead of `bash reno.sh`. Plus an `alias vb='cd ~/ventures/vibeboss-workspace/hq && claude'` suggestion in install output (or auto-injected into shell rc on install).
- **`CONTRIBUTING.md` proper.** Stub exists today (see [CONTRIBUTING.md](CONTRIBUTING.md)); full contribution flow gets written when Phase 2 opens external contribution.
- **`--rename` flag.** Support renaming the workspace, the lead, or the partner identity after install without hand-editing.
- **Tests / CI.** `tests/init-smoke.sh` and a GitHub Actions workflow.
- **Portable hook paths.** Already fixed for `vibeboss/.claude/settings.json` (placeholder + `reno.sh` substitution); audit remaining hook paths in templates for the same hazard.
