# Decision — Dispatch Vibe Chief from Boss (Path B) is canon

**Date:** 2026-05-28
**Status:** Active
**Author:** Boss (live HQ session) — promoted to framework canon same session

## Context

The two-mode topology (Boss = HQ runtime, Vibe Chief = framework caretaker) was shipped as part of the v0.2.0 dual-mode work. Activation paths:

- Boss: `cd ~/ventures/vibeboss-workspace/hq/ && claude`
- Vibe Chief: `bash ~/ventures/vibeboss/reno.sh`

Both required partner to context-switch terminals and run a script. The framework-feedback channel (v0.2.3, `templates/hq/follow-ups/framework/`) handled the async case — Boss writes a follow-up file, Vibe Chief sees it on the *next* boot.

Failure mode this decision fixes: when partner has framework work but doesn't want to run `bash reno.sh` — either because the friction of switching terminals is unwelcome (the agent-as-operator principle, LESSON-009) or because the work is small enough that spinning up a dedicated session feels disproportionate.

Partner's framing (2026-05-28): "partner wont run scripts, can we not have a way where u require me to run scripts" — and on follow-up, "u can also spawn vibechief separately too (with proper boot n run). why not u try second, but provided there's no active sessions (avoid clash)."

## Decision

Add a **Path B dispatch**: Boss can spawn Vibe Chief in background via a helper script, with mandatory active-session detection.

### Components

1. **`templates/hq/scripts/spawn-vibe-chief.sh`** (mirrored to live `<workspace>/hq/scripts/`).
   Behavior:
   - Resolves Vibeboss source via `$VIBEBOSS_SOURCE` env → `.vibeboss-version` source_path → sibling-dir heuristic (`<workspace>/../vibeboss/`) → hard fallback (`$HOME/ventures/vibeboss/`).
   - Runs `lsof -c claude` and filters by `$NF == vibeboss_dir` (cwd column) to detect active sessions.
   - On detected: exits **2** with `ACTIVE_VIBE_CHIEF_DETECTED` advisory + list of PIDs. **Refuses to spawn.**
   - On clear: `(cd vibeboss && VIBEBOSS_RENO=1 claude -p "$TASK") &` in background, logs to `<workspace>/hq/spawns/vibechief-<TS>.log`. Returns PID + log path.
   - Subscription-auth safety: `unset ANTHROPIC_API_KEY` before spawn (per WA-PA-LESSON-004).
   - Two task-input modes: positional `"<prompt>"` for inline, or `--task-file <path>` to point at a follow-up brief.

2. **`templates/hq/skills/dispatch-vibe-chief/SKILL.md`** — the SOP. Documents the two paths, when to use each, the active-session check, and what to put in the follow-up file. Mirrored live.

3. **`templates/hq/lessons.md` LESSON-010** — codifies the rule as a hard-gate: never spawn into an active session; the active-session check is mandatory; on refuse, ask partner to relay.

4. **`CHIEF.md` activation paragraph** updated — Vibe Chief now acknowledges two activation paths (manual `reno.sh` or Boss-spawn) and references the dispatch SKILL on the Boss side. Either path produces the same identity.

5. **`templates/hq/CLAUDE.md` framework-bug protocol** updated — the partner-facing protocol section now offers Path A vs Path B based on partner's preference, pointing to the SKILL for the full SOP.

### Why active-session detection is mandatory

Two concurrent Vibe Chief instances writing to the same OSS-bound source tree corrupts state in multiple ways:

- **CHANGELOG.md** edits race — two entries with the same `[unreleased] — vX.Y.Z` header, or contradictory `### Added` blocks.
- **Decision files** — two simultaneous writes can produce divergent decision narratives for the same date/topic.
- **Git index** — concurrent commits leave the second one to deal with conflicts that shouldn't have existed.
- **Template hashes** — `.vibeboss/originals/<rel-path>.sha256` manifest expects single-writer semantics.

The cost of a missed spawn (Boss has to surface to partner to relay manually) is far smaller than the cost of a corrupted framework source tree.

### Why detection by cwd-only (not by env var or transcript content)

Considered and rejected:

- **`ps -E` env var inspection** — macOS `ps -E` doesn't reliably show env for other-uid processes; even for same-uid, `VIBEBOSS_RENO=1` is only set if the process was launched via `reno.sh` (Path A), not via `claude -p` with inline env (Path B). False negatives in mixed scenarios.
- **Transcript JSONL inspection** — both Boss and Vibe Chief sessions can have CHIEF.md content in their JSONL history if the session ever switched modes or has a long lifespan. Both have HQ-boot content for similar reasons. Empirically observed during testing: both candidate sessions matched all three identity markers (CHIEF / HQ-banner / redirect) at different points in their transcripts.
- **PID file / lockfile** — would only catch Path B spawns; Path A's `bash reno.sh` doesn't write a lockfile. Half-coverage.

The cwd check (`lsof -c claude | awk '$4=="cwd" && $NF==vibeboss_dir'`) catches every claude process operating against `vibeboss/`, regardless of how it was launched. False positives are fine — Boss surfaces to partner and asks them to disambiguate, partner is the source of truth for "what role is that session in."

## Validation

2026-05-28 — smoke test: with two claude processes (PID 3287 and 81377) at `vibeboss/` cwd, `bash spawn-vibe-chief.sh "test"` correctly emitted `ACTIVE_VIBE_CHIEF_DETECTED` listing both PIDs and exited 2. No spawn attempted. Confirms refuse-on-active semantics.

## Open items

- **No log of which follow-up files have been dispatched yet via Path B.** Could write a `<workspace>/hq/spawns/dispatched.log` (append-only). Deferred until Path B sees enough usage to need it.
- **Path B doesn't currently have a "tail until done, then report" wrapper.** Boss has to manually `tail -f` the log and notice when the spawn process exits. Could add a `--wait` flag that blocks until completion. Deferred until usage pattern is clearer.
- **Active-session check is single-host.** If partner runs Vibe Chief on another machine over SSH, this won't detect it. Out of scope; the framework assumes single-machine operation per the OSS use case.

## Relationship to prior decisions

- Extends `decisions/2026-05-26-dual-mode-boss-and-vibe-chief.md` — same two-mode topology, new dispatch mechanism.
- Reinforces `decisions/2026-05-28-feedback-channel-and-calibration.md` (LESSON-009 agent-as-operator) — the dispatch SOP is itself an application of agent-as-operator to the framework-dispatch boundary, not just to in-workspace scripts.
