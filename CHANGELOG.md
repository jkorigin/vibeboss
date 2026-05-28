# Changelog

All notable changes to Vibeboss. Format loosely follows [Keep a Changelog](https://keepachangelog.com/). Versions follow [SemVer](https://semver.org/).

## [unreleased] — v0.2.6 in progress — PreCompact handover mechanism (2026-05-28)

The v0.2.4 Stop-hook compact-handover design failed the keyword-test acceptance gate on the very same day it shipped. Boss in the live HQ session diagnosed three compounding failure modes, switched to a PreCompact-hook design with pinned/rolling separation, and **passed live** — partner triggered `/compact`, post-compact session led with the keyword verbatim. Boss filed the port spec through the framework-feedback channel (the channel I designed in v0.2.3 — used end-to-end for the first time). This ship ports the verified-live mechanism into framework canon.

### Added

- **`templates/hq/.claude/hooks/pre-compact.sh`** (236 lines, copied from `~/ventures/vibeboss-workspace/hq/.claude/hooks/pre-compact.sh` verified-live source). PreCompact hook. Fires AT the moment of compaction (both `auto` from CC's 100% context limit and `manual` from partner's `/compact`). Receives `transcript_path` on stdin per CC's PreCompact hook signature. Captures last 8 partner turns verbatim + last 3 agent turns truncated + marker grep across the full session into `hq/handovers/_current.md`. Widened marker regex: `(KEYWORD|REMEMBER|TODO|HANDOVER|PARTNER ASK|DON'?T FORGET|IMPORTANT|CRITICAL|NOTE)[:\s]` plus quoted-phrase patterns (`you (will|should|must) say ['"]...['"]`, `remember ['"]...['"]`, `(test|validate|verify) ...keyword`). Idempotent, exits 0 on any error so it can never block compaction.
- **`templates/hq/.claude/hooks/compact-boot.sh` rewritten** for pinned-first injection. Composes `additionalContext` as: boot brief → all `_pinned/*.md` sorted by filename → `_current.md` → RESUME PROTOCOL block that hard-instructs: *"If any PINNED handover contains a keyword, test phrase, or instruction-to-say-verbatim, honour it on the FIRST response of this session — before greeting, before recap, before any other content."* Pinned-first ordering is what closes the keyword-displacement failure mode.
- **`templates/hq/handovers/_pinned/`** new directory with `README.md` documenting the pinned/rolling distinction + `.gitkeep`. Pinned handovers survive every compact; rolling `_current.md` is overwritten by PreCompact hook at every compact moment.
- **PreCompact hook registration in `templates/hq/.claude/settings.json`** — two matcher entries (`"auto"` and `"manual"`) both pointing at `pre-compact.sh`. `Stop` block removed.
- **Codex compatibility layer.** Source repo now has tracked `.codex/hooks.json` that loads `CHIEF.md` for Codex source-root sessions. Fresh installs scaffold `AGENTS.md` at workspace root, HQ, labs, and Boss-created projects. HQ and workspace-root `.codex/hooks.json` mirror the Claude boot/redirect contexts; HQ Codex hooks are thin wrappers around canonical `.claude/hooks/*.sh` so boot, STOP, update-banner, and compact behavior stay single-sourced.
- **`migrations/v0.2.5-dev-to-v0.2.6-dev.sh`** — backfills `<workspace>/hq/handovers/_pinned/` for legacy installs; removes `update-handover.sh` if its hash matches the installed-original (i.e. user didn't customize it). Idempotent.
- **Smoke test extended:** verifies `pre-compact.sh` exists + executable, settings.json has both `PreCompact` matchers, settings.json does NOT have `Stop` block, `_pinned/README.md` exists, `update-handover.sh` does NOT exist; also verifies Codex `AGENTS.md` files and `.codex` hooks exist and emit valid `additionalContext` JSON. Regression-guards against the failed Stop-hook design returning and against Codex compatibility regressing to source-root-only.
- `decisions/2026-05-28-precompact-handover-mechanism.md` — full decision documenting the failure modes, the replacement design, source-verification against <cc-source-archive> (CC source archive), the verified-live keyword-test pass, and the limits (pinned content is operator-curated; `_pinned/*.md` grows over time; CC version drift may shift the hook signature).
- `decisions/2026-05-28-codex-compatibility.md` — documents the Codex audit finding (root `AGENTS.md` was present, generated workspaces were not Codex-friendly), the compatibility layer, verification coverage, and honest limits (Claude spawn/plugin surfaces remain Claude Code-specific).

### Removed

- **`templates/hq/.claude/hooks/update-handover.sh`** — the Stop hook from the v0.2.4 abandoned design. Stop entry removed from `templates/hq/.claude/settings.json`. The script + the manifest entry are deleted by the migration script for installs that didn't customize the file.

### Changed

- **`templates/hq/CLAUDE.md` "Compact handover" section rewritten** from the Stop-hook framing to the PreCompact + pinned/rolling framing. New section name: *"Compact handover — PreCompact hook + pinned/rolling split"*. Documents when to write a pinned handover (keywords, hard decisions, identity reminders, "don't forget" content) and the filename convention (`YYYY-MM-DD-HHMM-<slug>.md` in `_pinned/`).
- **`init.sh`** — scaffolds `pre-compact.sh` + makes it executable on fresh install; scaffolds `handovers/_pinned/` directory + its README + `.gitkeep`; stops scaffolding `update-handover.sh`. Same `write_file` / `chmod +x` pattern as existing hooks.
- **README / CLAUDE.md / CHIEF.md** — now document dual tool support: Claude Code remains the native runtime; Codex is supported via `AGENTS.md` and `.codex/hooks.json`.
- **`decisions/2026-05-28-rolling-handover-mechanism.md`** carries a `## Superseded` block noting the same-day failure + pointing at the replacement decision. Per CLAUDE.md decisions discipline (supersession via new file, never overwrite), the original file stays.
- **`VERSION`** bumped to `0.2.6-dev`.
- **`ROADMAP.md`** gains "Recently shipped (v0.2.6)" section above v0.2.5.

### Rationale

The Stop-hook approach (shipped in v0.2.4 commit `74ff817`) failed for four compounding reasons: (1) `_current.md` overwritten every turn → keywords from earlier in the session displaced by topic drift; (2) `compact-boot.sh` mtime-newest selection meant the rich dated handover (where the keyword lived) lost to the just-touched rolling file; (3) marker regex too narrow to catch partner content without `KEYWORD:` literal prefix; (4) structural — Stop hook running in the post-compact session sees only post-compact transcript content, so the pre-compact turn (where the keyword lived) is gone before grep even runs.

PreCompact + pinned/rolling closes all four: PreCompact runs at the boundary with the full session still in the transcript; pinned handovers are immune to mtime displacement; widened regex + quoted-phrase capture surfaces a broader set of partner emphasis patterns; the hook sees the pre-compact transcript directly. Verified live 2026-05-28 — partner's keyword `cat climb clock tower dog run stairs eagle beats the eye` survived `/compact` and led the post-compact response verbatim.

### Notes on authorship + the framework-feedback channel

Boss (live HQ session) diagnosed the v0.2.4 failure, designed + verified the replacement mechanism, and filed the port spec at `<workspace>/hq/follow-ups/framework/2026-05-28-precompact-mechanism-port.md` — exactly the use case the v0.2.3 feedback channel was designed for. Vibe Chief read the file, ported the verified-live source into framework templates, wrote this decision + CHANGELOG entry, ran the validation gate. After landing, the feedback file gets a `## Disposition` footer (per v0.2.1's disposition protocol) and moves to `follow-ups/framework/processed/`. The loop closes.

## [v0.2.5] — 2026-05-28 — Agent-as-operator

The architectural shift partner asked for: *"users won't run scripts. you need to design the agents to handle all these things."* Vibeboss canon stops assuming partner types CLI commands. Boss, Vibe Chief, and per-project build leads run scripts on partner's verbal request and report results, not commands. The only unavoidable CLI moment is the one-time `bash init.sh` bootstrap (no agent exists yet at that moment).

### Added

- **LESSON-009 — Agent-as-operator. Boss runs scripts; partner speaks intent.** Hard-gated rule in `templates/hq/lessons.md`. When Vibeboss canon documents a CLI command (`init.sh --update`, `init.sh --add-project <name>`, `/plugin install <name>`, etc.), Boss is the executor; partner expresses intent verbally; Boss confirms briefly, runs via the Bash tool, and reports results.
- **`## Partner-facing protocols` section in `templates/hq/CLAUDE.md`.** Five canonical intent → action mappings (Apply the update / Start a new project / There's a framework bug / Show me what's in the inbox / general "results-not-commands" rule). Each maps a verbal intent to: what Boss confirms with partner, the exact command Boss runs via the Bash tool, and how Boss reports the outcome.
- **`## Partner-facing protocols (Vibe Chief)` section in `CHIEF.md`.** Framework-side mirror with four canonical mappings (Pull the latest / Apply this to the workspace / Address the framework feedback / Ship this).
- **CHIEF.md discipline list gains bullet 8:** *"Run scripts on partner's verbal request. Per LESSON-009."*
- **`## Partner-facing protocols` section in `templates/projects/_per_project/README.md`.** Project-level mirror with build-lead intent → action mappings (Run the tests / Ship this / Fix the build / Status update / Framework-level issue) plus a verbal-triggers table.
- **README "Reference: under the hood (for the technically curious)" appendix.** Table mapping verbal intent → underlying command for technical readers who want to see what's running. Non-technical operators can ignore.
- **Smoke test gains v0.2.5 coverage:** verifies LESSON-009 in lessons.md, Partner-facing protocols section in CLAUDE.md, verbal-form update banner in boot.sh, and regression-guards against the command-form banner returning.
- `decisions/2026-05-28-agent-as-operator.md` — full decision documenting the architectural shift, the five-cluster scope of edits, why the protocols section is the operational handle, the bootstrap-CLI honesty, and the limits (model-behavior contract, finite protocols).
- **LESSON-010 — Dispatch Vibe Chief from Boss; never spawn into a clash.** Codifies the two-path dispatch (Path A: partner runs `bash reno.sh`; Path B: Boss runs `hq/scripts/spawn-vibe-chief.sh`). Active-session detection mandatory before any Path B spawn — refuses on detected (exit 2) and surfaces detected PIDs to partner for relay.
- **`templates/hq/scripts/spawn-vibe-chief.sh`** — Boss-side dispatcher. Resolves Vibeboss source via `$VIBEBOSS_SOURCE` → `.vibeboss-version` source_path → sibling-dir heuristic → `$HOME/ventures/vibeboss/` fallback. Runs `lsof -c claude` to detect active claude processes at `vibeboss/` cwd. On clear: `(cd vibeboss && VIBEBOSS_RENO=1 claude -p "$TASK") &` in background, logs to `<workspace>/hq/spawns/vibechief-<TS>.log`. Subscription-auth safety: unsets `ANTHROPIC_API_KEY` before spawn.
- **`templates/hq/skills/dispatch-vibe-chief/SKILL.md`** — full SOP for both dispatch paths, the active-session check rationale, follow-up file structure, commit hygiene, and post-dispatch behavior.
- **`CHIEF.md` activation paragraph** updated to acknowledge both Vibe Chief activation paths (manual `reno.sh` or Boss-spawn) with same identity.
- **`templates/hq/CLAUDE.md` "There's a framework bug" partner-protocol** updated to offer Path A/Path B choice based on partner preference; references the SKILL.
- `decisions/2026-05-28-dispatch-vibe-chief-sop.md` — documents the decision, why active-session detection by cwd is mandatory, why env-var/transcript-content/pidfile alternatives were rejected, and the deferred items (no dispatched-log, no --wait flag, single-host scope).

### Changed

- **Update banner in `templates/hq/.claude/hooks/boot.sh` rewritten.** Was: *"Run `bash $SOURCE_PATH/init.sh --update --workspace $WORKSPACE` to apply."* Now: *"Say 'apply it' or 'update vibeboss' and I'll pull the latest framework and apply the changes to this workspace. Files you've customized stay yours unless you say otherwise."* Banner points at the Partner-facing protocols section in CLAUDE.md for the executor reference.
- **README user-facing sections rewritten.** *To update Vibeboss* now describes Boss surfacing the banner + partner saying "apply it"; CLI commands removed. *Recommended companions* now describes telling Boss what kind of project you're building rather than typing `/plugin install`. The Quick Start bootstrap block is preserved as the one CLI moment, with an explicit follow-on note: *"After this first install, you never type a command again."*
- `VERSION` bumped to `0.2.5-dev`.
- `ROADMAP.md` gained "Recently shipped (v0.2.5)" section above v0.2.4.

### Removed

- `decisions/2026-05-28-v025-agent-as-operator-planned.md` — superseded by the shipped decision file; planning file removed in this commit.

### Deferred (v0.3.0+)

- **Protocol generalization.** The Partner-facing protocols section has five canonical mappings. Boss has to generalize for everything else ("when in doubt, results not commands"). Future LESSONS may sharpen the heuristic if drift appears.
- **Shell alias for the bootstrap step.** Phase 2's `vibeboss reno` alias may let us reduce the one CLI moment to a shorter word; won't eliminate it.

## [v0.2.4] — 2026-05-28 — Rolling handover mechanism (SUPERSEDED SAME DAY — see v0.2.6)

> **Superseded:** This release's Stop-hook design failed the keyword-test acceptance gate on the very same day it shipped. See v0.2.6 above and `decisions/2026-05-28-precompact-handover-mechanism.md` for the working PreCompact + pinned/rolling replacement. The original entry is preserved below for traceability.

Compact handover converted from self-discipline ("agent remembers to write handover before /compact") to mechanism-driven enforcement. A `Stop` hook fires every turn and rewrites `hq/handovers/_current.md` with the last partner message, last agent response, and grepped markers — so at the moment Claude Code's auto-compact fires, a fresh handover always exists for `compact-boot.sh` to inject. Zero agent self-discipline required as the baseline. Rich dated handovers preserved as an optional override layer.

### Added

- **`templates/hq/.claude/hooks/update-handover.sh`** — Stop hook. Parses the live transcript JSONL, extracts last user message + last assistant response, greps for markers (`KEYWORD:` / `REMEMBER:` / `TODO:` / `HANDOVER:` / `PARTNER ASK:` / `DON'T FORGET:` / `IMPORTANT:`), writes `hq/handovers/_current.md`. Idempotent, exits 0 on any error so it can never block the assistant. ~100ms per turn.
- **Stop hook registration in `templates/hq/.claude/settings.json`** — new `"Stop"` entry under `"hooks"`, invoking `${CLAUDE_PROJECT_DIR}/.claude/hooks/update-handover.sh`. Uses the same portable-path pattern as existing SessionStart hooks.
- **`init.sh` scaffolds + chmods the new Stop hook script** at install time. (Originally drafted by Boss without this — Vibe Chief caught the gap during land: fresh installs would have a Stop hook registered in settings.json pointing at a missing file. Now plugged.)
- **Smoke test verifies the new hook script is present and executable** (`tests/init-smoke.sh` gained one `check_exec` line so CI catches regressions of the scaffold gap above).
- `decisions/2026-05-28-rolling-handover-mechanism.md` — documents why Stop hook over PreCompact (defends multi-trigger, cheap+frequent, composable with optional rich layer), the dual-layer model (rolling baseline + optional rich override picked by mtime), the marker-grep heuristic + future LLM-summarized escalation path, and the keyword test validation (`cat climb clock tower dog run stairs eagle beats the eye`, 2026-05-28 12:10).

### Changed

- **`templates/hq/CLAUDE.md`** — "Compact handover" section rewritten: was framed as agent self-discipline with triggers T1-T5, now framed as "Stop hook + compact-boot.sh working together with zero discipline as baseline; rich dated handovers as optional override layer". The five triggers are reframed as opt-in moments for the rich layer, not as gates the agent must self-recognize. (Landed early — bundled into commit 396b596 inadvertently when Boss and Vibe Chief edited CLAUDE.md in parallel sessions.)
- **`VERSION`** bumped to `0.2.4-dev`.

### Rationale

The original subsystem-E design required the agent to self-detect context-pressure triggers and proactively write a handover before `/compact`. Two failure modes appeared in practice: (1) the agent has no access to context-usage numbers (the CC app shows partner 96%, the agent never sees it), and (2) auto-compact at 100% fires without warning — by the time the agent could react, compaction has already happened. Mechanism-driven enforcement removes both failure modes.

### Notes on authorship

Boss (live HQ session) drafted the Stop hook, settings.json registration, decision file, and CLAUDE.md rewrite. Vibe Chief landing this version added the missing init.sh scaffolding + smoke test coverage so fresh installs and CI both get the new hook, then promoted the work to a tagged release. This is the first release where canon-level work originated outside Vibe Chief mode — worth flagging as a pattern (the Boss → Vibe Chief framework-feedback channel shipped in v0.2.3 is intended for exactly this kind of cross-boundary work, though Boss in this case wrote source directly rather than going through follow-ups/framework/).

## [v0.2.3] — 2026-05-28 — Discipline at the seams

Three discipline shifts at the seams between Boss, Vibe Chief, and the operator: first-response output is now imperative (closes the "Boss didn't auto-boot on 'hi'" gap), Boss has a sanctioned channel to surface framework observations back to Vibe Chief, and all numerical claims must cite their source or label as guess. See `decisions/2026-05-28-feedback-channel-and-calibration.md` for the architecture.

### Added

- **LESSON-007 — First-response output discipline.** On the FIRST response of every new session, output the boot brief from `additionalContext` as the lead of the reply — regardless of what the operator says. Imperative section at the top of `templates/hq/CLAUDE.md`, mirrored in `templates/projects/_per_project/README.md` for project build leads, and in `CHIEF.md` (Vibe Chief's discipline applies too). Closes the "Boss didn't auto-boot when I said hi" failure mode where the SessionStart hook fires correctly but the model treats `additionalContext` as ambient context rather than as an act-on-this instruction.
- **LESSON-008 — No bare claims; cite provenance or tag as guess.** New hard-gate rule: every numerical or quantitative claim cites its source (grep the calibration log for time estimates; run the count for file counts; cite measurements for percentages) — or prefixes the number with `guess:` and italic-formats it. Documented in `templates/hq/lessons.md` and reinforced in CLAUDE.md and CHIEF.md.
- **Framework feedback channel (Boss → Vibe Chief).** New directory `templates/hq/follow-ups/framework/` with README documenting the channel, `.gitkeep`, and `processed/` subfolder. Boss writes here when partner reports framework issues (e.g. "auto-boot didn't fire") or when Boss notices a canon-level gap. Filename: `YYYY-MM-DD-<slug>.md`. Body: problem statement, reproducer, Boss's local workaround, suggested fix. After Vibe Chief addresses the item, disposition-footer protocol (from v0.2.1) closes the loop and the file moves to `processed/`.
- **`vibeboss/.workspaces` tracker.** New gitignored file at source root. `init.sh` appends the workspace's absolute path on every fresh install, `--upgrade`, `--update`, and `--add-project` (with dedup). Vibe Chief's boot sequence (per the new `## Read workspace framework feedback` section in `CHIEF.md`) globs this file and reads each workspace's `follow-ups/framework/` directory to surface pending items.
- **Calibration log infrastructure.** Two new JSON Lines logs:
  - `templates/hq/calibration/log.jsonl` — empty initial file scaffolded into every new workspace; Boss appends entries when work completes.
  - `vibeboss/calibration/log.jsonl` — at source root; Vibe Chief appends for framework work. Seeded with three retroactive entries reconstructing wall-clock for v0.2.0 (~25 min), v0.2.1 (~30 min), and v0.2.2 (~20 min) from this session's git history. Tagged with coarse categories (`subagent-cluster`, `templates`, `bash`, `audit`, `ppsb`, `update-mechanism`).
  - Both come with `calibration/README.md` documenting the schema (required: `date` / `task` / `scope` / `tags` / `wallclock_min`; optional: `subagents` / `files` / `human_est_min` / `notes`) and the discipline (append-only; grep for ≥3 entries with overlapping tags; report median + range + sample size, or label as guess if <3 matches).
- `decisions/2026-05-28-feedback-channel-and-calibration.md` — documents the three-shift architecture, why one channel for feedback rather than many, why JSON Lines for calibration, the retroactive seeding rationale, and the limits (single-channel, model-behavior contract for first-response, small-N calibration).
- `migrations/v0.2.2-dev-to-v0.2.3-dev.sh` — backfills `hq/follow-ups/framework/` and `hq/calibration/` directories + registers the workspace in `vibeboss/.workspaces` for legacy installs running `init.sh --update`.
- Smoke test extended (`tests/init-smoke.sh`): verifies framework-feedback dir exists with proper README content, calibration log + README exist with LESSON-008 reference, `.workspaces` tracker records the temp workspace (and cleans up after itself), LESSON-007 + LESSON-008 are in `lessons.md`, first-response discipline section is in CLAUDE.md, migration script is executable.

### Changed

- **`templates/hq/CLAUDE.md`** — new `## First-response discipline` section at the top (between intro and Boot sequence) with imperative language; new `## Estimate honesty + claim provenance` section near Boundaries pointing at the calibration log and LESSON-008.
- **`templates/projects/_per_project/README.md`** — first-response discipline applied to project build leads.
- **`CHIEF.md`** — new discipline bullet 6 (first-response applies to Vibe Chief too); new `## Read workspace framework feedback` section in boot sequence pointing at `vibeboss/.workspaces` + each workspace's `follow-ups/framework/`; new `## Estimate honesty + claim provenance` section pointing at `vibeboss/calibration/log.jsonl`.
- **`templates/hq/lessons.md`** — LESSON-007 and LESSON-008 appended (matching the LESSON-001 through LESSON-006 format).
- **`init.sh`** — scaffolds the new `hq/follow-ups/framework/` and `hq/calibration/` directories on fresh install; writes their README.md + log.jsonl from new templates; records the workspace in `<source>/.workspaces` (with dedup) on every install / `--upgrade` / `--update` / `--add-project`.
- **`.gitignore`** — added `.workspaces` entry with rationale comment.
- **`VERSION`** bumped to `0.2.3-dev`.
- **`ROADMAP.md`** — "Recently shipped (v0.2.3)" section added above v0.2.2.

### Deferred (v0.3.0+)

- **A categorize-feedback skill or LESSON-009** if Boss starts misrouting issues between `STATE.md` / runlog / decisions / `follow-ups/framework/`. Current heuristic relies on Boss recognizing "this is framework-level" — could drift.
- **Automated calibration analysis** — a `vibeboss estimate <tag1>,<tag2>` helper that greps the log, computes median + range + n, and outputs the formatted citation. Today Boss does it inline via grep + manual median; a helper would make LESSON-008 cheaper to follow.

## [v0.2.2] — 2026-05-28 — Update mechanism

Vibeboss workspaces can now receive framework updates safely. Per-workspace version pinning + per-file installed-original hashes let `init.sh --update` distinguish between files the user customized and files that still match the canonical install — refreshing the latter, prompting on the former. Boss surfaces a banner in the boot brief when updates are available.

### Added

- **`<workspace>/.vibeboss-version`** written at every fresh install and updated at every `--update` completion. Records `version`, `source_path`, `source_sha` (git rev-parse of the Vibeboss source at install time, or "unknown"), `installed_at`, `updated_at` (ISO 8601 UTC).
- **`<workspace>/.vibeboss/originals/<rel-path>.sha256` manifest.** Every template-derived file gets its post-substitute SHA256 stored at install. This is the load-bearing source of truth for "did the user customize this file?" Without it, every update decision is a guess.
- **`init.sh --update` mode.** Walks the templates tree against an existing workspace. Decision tree per file: missing → create (legacy); unchanged from original → refresh + update hash; customized → prompt (keep / overwrite / view-diff / skip), `--noninteractive` defaults to keep; original missing (legacy workspace) → adopt current as authoritative. Runs migrations between installed and target version, then writes the updated `.vibeboss-version`. Prints a summary block at the end.
- **`migrations/` directory + runner.** New top-level dir at `vibeboss/migrations/` with `run.sh` (the runner) + `README.md` (convention docs) + a sample no-op migration `v0.2.1-dev-to-v0.2.2-dev.sh`. Each migration takes `$1 = workspace path`, must be idempotent, exits 0 on success. `init.sh --update` invokes the runner with installed + target versions; the runner lex-sorts applicable scripts and executes the chain.
- **Boss boot banner.** `templates/hq/.claude/hooks/boot.sh` now reads `<workspace>/.vibeboss-version` + `<source>/VERSION`; if they differ, appends `**Vibeboss update available:** vX → vY. Run \`...init.sh --update --workspace ...\`` to the brief. Silent fail if any piece is missing or malformed; never blocks boot. STOP-file path unaffected.
- **README "To *update* Vibeboss" section** between Quick Start and "To enhance Vibeboss" — documents the `git pull && bash init.sh --update` flow, the refresh-vs-prompt semantics, and the `--noninteractive` automation default.
- **Smoke test extended** to exercise the update path: install, simulate stale workspace by editing `.vibeboss-version`, run `--update --noninteractive`, verify the version metadata is updated and migrations runner is invoked. Banner check: verify `boot.sh --brief-only` includes the banner when stale, omits when current.
- `decisions/2026-05-28-update-mechanism.md` — documents the architecture (version pinning + manifest + per-file resolution + migrations as a separate channel + Boss banner), why per-file resolution is the right grain, the lex-comparison caveat for version sorting, and the no-three-way-merge limit.

### Changed

- `init.sh` grew ~200 lines for the update flow. New helpers `hash_file()`, `hash_string()`, `write_manifest_hash()`, `write_version_metadata()`. `write_file()` extended to write a manifest entry for every file it writes. Updated `usage()` heredoc; updated success-block hint to point at `--update` as the future-update path.
- `VERSION` bumped to `0.2.2-dev`.
- `ROADMAP.md` updated: new "Recently shipped (v0.2.2)" section above the v0.2.1 one tracking the update mechanism.

### Deferred (v0.3.0+)

- **Three-way merge for customized files.** Current behavior on the "overwrite" path is to replace the workspace file wholesale. A three-way merge (current / installed-original / new-canonical) via `git merge-file` would let users adopt upstream changes without losing local edits in non-conflicting regions. Not shipped because it adds noise to the simple cases without proportional benefit.
- **Versions as sortable tuples instead of lex strings.** The migration runner sorts filenames lexically — fine until we cross x.10 (where `0.10.0` sorts before `0.2.0`). Fix by parsing semver into tuples and sorting numerically.

## [v0.2.1] — 2026-05-28 — PPSB foundation

The Per-Project Skill Bundle (PPSB) architecture lands. Every project Boss creates now ships its own `.claude/settings.json` with `superpowers@claude-plugins-official` enabled by default, plus symlinks to Vibeboss's native skills. Per-project, never machine-wide. Also: STOP-file kill switch (closes a Phase 1 ROADMAP item), bidirectional inbox topology (stolen from <coordinator-agent> in `<other-multi-repo>/`), and a recommended-companions doc surface.

### Added

- **Per-project skill bundle (PPSB) baseline.** New template at `templates/projects/_per_project/` defines the scaffold Boss applies to every project: `.claude/settings.json` pre-seeded with `enabledPlugins["superpowers@claude-plugins-official"]: true`, project-scoped STATE/runlog/decisions/handovers/inbox topology, per-project `crew.yml` snippet. When scaffolded, Vibeboss native skills (`dev-workflow`, `compact-handover`) are symlinked from `hq/skills/` so build leads dispatched into the project inherit the discipline.
- **`init.sh --add-project <name>` mode.** New scaffolding flag: reads `hq/crew.yml`'s `next_available` for the produce-themed crew name, computes `LEAD_NAME` from `venture_lead.name`, scaffolds the per-project template with placeholder substitution, creates the skill symlinks, prints next-steps. Reuses the existing substitute/write_file/ensure_dir helpers. Does NOT auto-mutate `hq/crew.yml` agents[] — Boss does that at first spawn so the runlog records the birth event.
- **STOP-file kill switch.** `templates/hq/.claude/hooks/boot.sh` now checks `$HQ/STOP` and `$WORKSPACE/STOP` first thing. If either exists (zero-byte sentinel — existence IS the signal), emits a HALTED brief and exits cleanly. Three triggers documented: operator kill (`touch STOP`), agent self-cap, workspace-wide halt. Recovery requires both `rm STOP` AND explicit re-authorization from the operator. Closes the Phase 1 ROADMAP item; mechanism ported from `<other-research-project>/AUTONOMOUS-BRIEF.md`.
- **Bidirectional inbox topology.** Two layers now: Layer 1 keeps the legacy type-folder topology (`inbox/{requests,chats,todos,processed}/`) for backwards compatibility; Layer 2 introduces per-counterparty inbox files (`inbox/<counterparty>.md`) with append-only messages, `unread → seen → acted → escalated → closed` status lifecycle, `THREAD-<slug>` IDs for threading, and a disposition-footer protocol that closes the loop (every artifact a counterparty produces gets a Disposition block citing the originating thread, mirrored back to the inbox message). Pattern stolen from <coordinator-agent> in `<other-multi-repo>/inbox/` + `<other-research-project>/CONTRACT.md §4`.
- **Per-project inbox documented as DOWN-only by default.** Asymmetric topology: HQ has bidirectional inboxes per counterparty; projects have only DOWN (Boss writes TO the project's lead at `<project>/inbox/boss.md`). Project leads write UP back to `hq/inbox/<lead-name>.md`. Documented in both `templates/hq/inbox/README.md` and `templates/projects/_per_project/inbox/README.md`.
- **Disposition-footer protocol.** Whenever a counterparty acts on a request and produces an artifact (decision, runlog entry, deliverable), they append a `## Disposition` block to both the originating inbox message AND the produced artifact, with `Verdict / Result / Rationale / Closed thread` fields and a backlink. Loop closes; readers of the artifact see what was adopted without spelunking the inbox.
- **HQ baseline plugin enable.** `templates/hq/.claude/settings.json` now ships with `enabledPlugins["superpowers@claude-plugins-official"]: true` — Boss gets superpowers as baseline too, not just spawned crew.
- **`## Recommended companions` section in README.** Documents superpowers as auto-enabled baseline, lists a curated opt-in pool from Anthropic's official marketplace (context7, code-review, pr-review-toolkit, commit-commands, frontend-design, playwright, hookify, skill-creator, claude-md-management, feature-dev, figma, vercel, firebase, sourcegraph, Notion), and mentions gstack as external (with the Bun caveat, install per upstream README). Vibeboss never auto-clones — it points.
- **`Acknowledgements` block in NOTICE.** MIT attribution for superpowers (Jesse Vincent) and gstack (Garry Tan) with upstream URLs.
- **Smoke test extended.** `tests/init-smoke.sh` now exercises `--add-project` (project tree shape, symlinks present, `enabledPlugins` baseline correct, all placeholders substituted) and the STOP-file kill switch (HALTED brief on touch, normal brief after rm). CI still green on Ubuntu.
- `decisions/2026-05-28-per-project-skill-bundle.md` — documents the PPSB architecture, three skill classes (baseline / recommended / custom), why per-project not machine-wide, and the v0.2.1 vs v0.3.0 staging plan.

### Changed

- `templates/hq/projects/README.md` rewritten to point at `bash ~/ventures/vibeboss/init.sh --add-project <name>` as the canonical scaffolding command.
- `templates/hq/CLAUDE.md` inbox section replaced with a one-paragraph pointer to `hq/inbox/README.md` plus the DOWN-only asymmetry rule; new `### STOP-file kill switch` subsection added near the Boot sequence.
- `templates/hq/STATE.md` carries a one-line HTML comment under "Current state" referencing the STOP kill switch.
- `templates/_workspace_root/.gitignore` (new) — gitignores `/STOP`, `/hq/STOP`, `/labs/STOP`, `/projects/*/STOP` at workspace scope. Existence-is-the-signal must never be committed.
- `ROADMAP.md` updated: STOP-file kill switch moved to "Recently shipped (v0.2.1)"; per-project skill bundle moved to shipped; bidirectional inbox moved to shipped; new "Phase 1.5 — PPSB Phase 2 (v0.3.0)" section tracks the vibeboss-natives marketplace, full add-project Boss skill (interactive recommend menu), and HQ refactor.
- `VERSION` bumped to `0.2.1-dev`.

### Deferred (v0.3.0)

- **`vibeboss-natives@vibeboss` marketplace.** Currently dev-workflow + compact-handover are file-based skills symlinked into each project. v0.3.0 publishes a `.claude-plugin/marketplace.json` so cloners activate via `/plugin marketplace add jkorigin/vibeboss` + `enabledPlugins["vibeboss-natives@vibeboss"]: true`. Uniform with superpowers. Clean update story.
- **Full `add-project` Boss skill** with interactive recommend-menu UX. Current `init.sh --add-project` is a CLI baseline; v0.3.0 promotes to a SKILL.md Boss invokes when the operator says "new project X", with an opinionated prompt flow that asks which recommended skills to enable.
- **HQ template refactor** to use the marketplace once published — removes the file-based skill symlinking, switches to enabledPlugins.

## [v0.2.0] — 2026-05-27 — audit-fix pass

Full self-audit + fix pass. Honest README repositioning, portable `${CLAUDE_PROJECT_DIR}` hook paths (supersedes the trap-restore mechanism), the framework's first test + CI workflow, dev-workflow round-count softening, partner-data scrub round 2, plus VERSION + `--version` flag scaffolding.

### Fixed (OSS-ready cleanup pass — 2026-05-26)

- **Blocker 1 — Portable hook paths (initial fix, now superseded).** `vibeboss/.claude/settings.json` was hardcoded to the partner's absolute path. First fix: committed with `VIBEBOSS_DIR_PLACEHOLDER`; `reno.sh` substituted the real path on startup and restored the placeholder on exit (trap-restore). Superseded on 2026-05-27 — see Audit-fix pass below.
- **Blocker 2 — Workspace-root redirect template.** Added `templates/_workspace_root/.claude/` with `settings.json`, `hooks/redirect.sh`, and `hooks/redirect.md`. `init.sh` now installs it at workspace root on every fresh install. Users who accidentally `cd <workspace>/ && claude` now get a redirect instead of a blank session.
- **Blocker 3 — Git repository initialized.** `vibeboss/` now has a git repo, v0.1.0 tagged.
- **Blocker 4 — Partner-specific data audit.** Removed `.claude/launch.json` (hardcoded runtime paths, not OSS canon). Redacted phone number identity from `docs/design/plans/2026-05-26-topology-hq-split.md`. Removed absolute path mention from CHANGELOG. See `decisions/2026-05-26-partner-data-audit.md`.
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
- The 2026-05-26 partner-data audit missed several spots. The 2026-05-27 grep + scrub touched: `CHANGELOG.md` (`<example-project>` reference + spurious "4 research streams" runtime claim), `CLAUDE.md` (illustrative-marker on `Banana / Carrot / Ginger`), `decisions/2026-05-26-dual-mode-boss-and-vibe-chief.md`, `docs/design/plans/2026-05-26-master-dashboard.md`, `docs/design/specs/2026-05-26-master-dashboard-design.md`, `docs/design/specs/2026-05-26-crew-system-design.md`, `docs/design/plans/2026-05-26-crew-system.md`, `docs/design/specs/2026-05-26-topology-hq-split-design.md`. Identifiers either replaced with placeholders or qualified as illustrative.

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
- Shell alias injection (`alias vb=...`) into user's shell rc.
- `--rename` mode for `init.sh` — post-install identity renames.
- **Git hooks for co-author attribution.** Local-only `.git/hooks/prepare-commit-msg` was installed in this clone to auto-rewrite Claude Code's `Co-Authored-By: Claude ...` trailer to `vibechief <vibechief@vibeboss.local>` (in `vibeboss/`) or `boss <boss@vibeboss.local>` (in `vibeboss-workspace/*`). Hook is *not* tracked in the repo because `.git/hooks/` is local-only. Fix: commit a `tools/install-hooks.sh` that installs hooks from `tools/hooks/prepare-commit-msg` into `.git/hooks/`. `init.sh` should also install the hook into any new git repos partner creates in `vibeboss-workspace/*` so attribution is automatic everywhere.

## [v0.1.0] — 2026-05-26 — first OSS-ready cut

The 7-subsystem framework arc + Vibe Chief mode shipped. Vibeboss is now installable from a clone in under 2 minutes via `init.sh`, and enhanceable via `reno.sh`.

### Added

- **Subsystem A — Topology + HQ split.** Source/runtime separation: `vibeboss/` source vs `vibeboss-workspace/{hq, labs, projects/}` runtime. Per-project memory routing under `hq/projects/<name>/`. See [docs/design/specs/2026-05-26-topology-hq-split-design.md](docs/design/specs/2026-05-26-topology-hq-split-design.md).
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

### Known follow-ups (deferred to v0.2.0 or later — most now shipped in v0.2.0 / v0.2.1)

- **Portable hook paths in `vibeboss/.claude/settings.json`.** — Shipped in v0.2.0 via `${CLAUDE_PROJECT_DIR}`.
- `dashboard-bootstrap.sh` template — still deferred.
- Windows support — still deferred.
- `vibeboss add-project <name>` — CLI baseline shipped in v0.2.1; full Boss skill version v0.3.0.
- Shell alias support — still deferred.
- **Workspace-root SessionStart redirect in templates.** — Shipped in v0.2.0 cleanup pass.
- Long-running framework agent code — Phase 1 begins when this lands.
