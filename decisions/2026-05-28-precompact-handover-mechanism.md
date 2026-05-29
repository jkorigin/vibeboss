# Decision — PreCompact handover mechanism (supersedes Stop-hook design)

**Date:** 2026-05-28
**Layer:** Framework (Vibeboss canon)
**Author:** Vibe Chief (porting Boss's verified-live mechanism into framework canon)
**Status:** active
**Supersedes:** `2026-05-28-rolling-handover-mechanism.md` (same-day failure)

## Context

The v0.2.4 rolling handover mechanism (v0.2.4) shipped a `Stop` hook that fired every turn and rewrote `hq/handovers/_current.md` with the latest exchange + grepped markers. The design was intended to ensure that at the moment Claude Code's auto-compact fires, a fresh handover always exists for `compact-boot.sh` to inject.

Boss in the live HQ session ran the acceptance gate from that decision (the keyword test: partner passes a phrase, triggers `/compact`, post-compact session must surface the keyword verbatim on first response). It failed. Boss diagnosed root cause, switched to a PreCompact-hook design with pinned/rolling separation, re-ran the test, and **passed live** — partner's keyword `cat climb clock tower dog run stairs eagle beats the eye` led the post-compact response verbatim.

Boss filed the finding through the framework-feedback channel (shipped in v0.2.3) at `<workspace>/hq/follow-ups/framework/2026-05-28-precompact-mechanism-port.md`, with full diagnosis, source-verified reasoning, exact port tasks, and migration spec. The channel I designed for exactly this kind of Boss → Vibe Chief framework-level feedback worked as intended.

This decision documents the replacement mechanism + ports it into framework canon.

## Failure modes of the Stop-hook design (preserved for posterity)

Three compounding reasons the Stop-hook approach failed:

1. **`_current.md` overwritten every turn → displaced by topic drift.** By the time auto-compact fired at ~100% context, the file reflected the most recent turn — rarely the most important content of the session. Keywords introduced mid-session got erased.
2. **`compact-boot.sh` picked newest file by mtime.** Because the Stop hook had just touched `_current.md`, the rich dated handover (where the keyword lived) was older — never selected.
3. **Marker grep too narrow.** Regex required `KEYWORD:` literal prefix. Partner typed the test phrase without that prefix → grep returned "(none flagged this session)".

Plus a structural issue: a Stop hook running in the *post*-compact session sees only post-compact transcript content. The pre-compact transcript (where the keyword turn lived) is gone. So even widening the grep couldn't recover content that the Stop-hook design fundamentally couldn't see.

## Decision

**Three changes, ported as v0.2.6:**

### 1. PreCompact hook replaces Stop hook

A new hook at `templates/hq/.claude/hooks/pre-compact.sh` fires AT the moment of compaction (both `auto` triggers from CC's 100% context limit and `manual` triggers from partner running `/compact`). Receives the full pre-compact transcript path on stdin (per CC's PreCompact hook signature). Captures:

- **Last 8 partner turns verbatim** (truncated to 1500 chars each) — the conversation right before compaction.
- **Last 3 agent turns truncated** to 2000 chars each — recent context.
- **Marker grep across the full session** with widened regex covering `KEYWORD|REMEMBER|TODO|HANDOVER|PARTNER ASK|DON'?T FORGET|IMPORTANT|CRITICAL|NOTE` prefixes plus quoted-phrase patterns (`you (will|should|must) say ['"]...['"]`, `remember ['"]...['"]`, `(test|validate|verify) ...keyword`) — surfaces a broader set of partner emphasis patterns.
- Writes to `hq/handovers/_current.md` (rolling).

Exits 0 on any error so it can never block compaction.

### 2. Pinned vs rolling separation

Two locations:

- **`hq/handovers/_pinned/*.md`** — durable, must survive multiple compacts. Agent or partner writes these when there's content (keywords, hard decisions, identity reminders) that must not be displaced by topic drift. No automatic mechanism populates this directory — pinning is an explicit decision.
- **`hq/handovers/_current.md`** — overwritten at every compact by the PreCompact hook. Rolling snapshot of the just-compacted session.

The split defeats mtime-displacement: rich dated handovers and keyword tests live in `_pinned/`, immune to the rolling hook's overwrite cycle.

### 3. `compact-boot.sh` rewritten for pinned-first injection

Composition order in `additionalContext`:

1. Boot brief (standard from `boot.sh`)
2. All `_pinned/*.md` files sorted by filename (chronological since they're `YYYY-MM-DD-HHMM-<slug>.md`)
3. `_current.md` (rolling)
4. **RESUME PROTOCOL** block explicitly instructing: *"If any PINNED handover contains a keyword, test phrase, or instruction-to-say-verbatim, honour it on the FIRST response of this session — before greeting, before recap, before any other content."*

Pinned-first ordering is deliberate: large context = model reads top-down, pinned content surfaces before topic-of-the-moment content from the rolling snapshot. This is what closes the keyword-displacement failure mode.

## Why PreCompact, not Stop

- **Stop runs every turn.** `_current.md` ends up being whatever-the-last-turn-was, not what-mattered-this-session.
- **PreCompact runs once at the boundary** with the full session still in the transcript file → captures real session contents.
- **Source verification:** <cc-source-archive> (reverse-engineered CC source archive at `<cc-source-archive>/`) confirms — `services/compact/compact.ts:592,981` calls `processSessionStartHooks('compact', ...)` on auto-compact; `utils/sessionStart.ts:163` appends `additionalContext` as an attachment message; `services/compact/prompt.ts:345` (`getCompactUserSummaryMessage`) generates the "This session is being continued..." string. PreCompact hook signature documented at `utils/hooks.ts:3961-4025` (receives `transcript_path`, `cwd`, `session_id`, `trigger: 'auto'|'manual'`). Boss did the homework.

## What shipped (v0.2.6)

- **`templates/hq/.claude/hooks/pre-compact.sh`** copied from the verified-live source at `~/ventures/vibeboss-workspace/hq/.claude/hooks/pre-compact.sh`.
- **`templates/hq/.claude/hooks/compact-boot.sh`** replaced (pinned-first composition).
- **`templates/hq/.claude/hooks/update-handover.sh`** deleted (the Stop hook is gone).
- **`templates/hq/.claude/settings.json`** — `Stop` block removed; `PreCompact` block added with both `auto` and `manual` matchers pointing at `pre-compact.sh`. Same `${CLAUDE_PROJECT_DIR}` portable path pattern as other hooks.
- **`templates/hq/handovers/_pinned/`** new directory with `README.md` documenting the pinned/rolling distinction + `.gitkeep`.
- **`templates/hq/CLAUDE.md`** "Compact handover" section rewritten to describe PreCompact + pinned/rolling split (replaces the v0.2.4 framing about Stop-hook).
- **`init.sh`** — scaffolds the new hook + `_pinned/` dir + its README; stops scaffolding `update-handover.sh`.
- **`tests/init-smoke.sh`** — validation gate per Boss's spec: pre-compact.sh exists + executable, settings.json has PreCompact + no Stop, `_pinned/README.md` exists, update-handover.sh does NOT exist.
- **`migrations/v0.2.5-dev-to-v0.2.6-dev.sh`** — backfills `_pinned/` + installs pre-compact.sh + removes update-handover.sh (with hash check) for legacy installs.

## Validation (verified live before this canon port)

2026-05-28 — partner passed test keyword `cat climb clock tower dog run stairs eagle beats the eye`. Boss wrote it to `hq/handovers/_pinned/2026-05-28-1210-keyword-test.md` (pinned layer) and verified the PreCompact hook also auto-captured it via the widened marker grep. Partner triggered `/compact`. Post-compact session led with the keyword verbatim on the first response. Mechanism works.

Acceptance gate passed.

## Limits / known caveats

- **Pinned content is operator-curated.** No automatic mechanism populates `_pinned/`. The agent or partner has to explicitly decide "this must survive multiple compacts." The pinning act is deliberately effortful — that's the point. Drift defense lives in pinning, not in heuristics.
- **`_pinned/*.md` files grow over time.** Compact-boot injects ALL pinned files. As `_pinned/` fills, the post-compact additionalContext grows. Operator's responsibility to retire stale pinned handovers (move out of `_pinned/`).
- **Source-verified against current <cc-source-archive> snapshot.** If Claude Code's compact internals shift, the hook signature could change. Today's signature documented; future CC version bumps should re-verify.

## Consequences

- v0.2.4's Stop-hook design is now formally superseded. The decision file (`2026-05-28-rolling-handover-mechanism.md`) carries a `## Superseded` block noting the same-day failure; the implementation files are removed from templates.
- Fresh installs from v0.2.6+ get PreCompact + pinned/rolling. Legacy installs running v0.2.4 or v0.2.5 see the migration on next `init.sh --update`.
- The framework-feedback channel shipped in v0.2.3 (`hq/follow-ups/framework/`) was used end-to-end for the first time in production: Boss diagnosed + verified the fix + filed the port spec → Vibe Chief read it + ported into canon → disposition footer + move-to-processed closes the loop. Pattern works.
- LESSON-008 self-citation: this port was direct (no parallel subagents), tagged `bash + templates + hook-design + cross-mode`. Wall-clock logged in calibration.

## Supersedes

`2026-05-28-rolling-handover-mechanism.md` — entirely. The Stop-hook approach failed live; this PreCompact design passed live; canon ships the working version.
