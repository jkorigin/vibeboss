# Decision — Framework feedback channel + calibration log + claim-provenance discipline

**Date:** 2026-05-28
**Layer:** Framework (Vibeboss canon)
**Author:** Vibe Chief
**Status:** active

## Context

Three connected gaps surfaced in one conversation:

1. **Boss-to-Vibe-Chief feedback is impossible.** When partner reports a framework issue (e.g. "auto-boot didn't fire when I said hi"), Boss either fixes it locally with no upstream signal, or shrugs. Vibe Chief — sitting in `vibeboss/` source on the same machine — has no way to know that real workspaces are hitting the issue. The discipline file (CHIEF.md) says Vibe Chief writes to source and never to workspaces; the runtime side says Boss writes to workspace and never to source. Correct boundary, but nothing crosses it.

2. **Boss doesn't proactively output its boot brief.** The SessionStart hook fires and injects the brief as `additionalContext`, but the model treats it as ambient context rather than as a first-output instruction. When operator says "hi", Boss replies "hi" — vanilla Claude behavior, framework state-grounding bypassed silently. <external-office-project>'s CLAUDE.md solves this with imperative language ("On every new session, before responding to any user message, run the boot sequence. This is not optional."). Vibeboss's CLAUDE.md was descriptive, not imperative.

3. **Time estimates were unmeasured guesses.** Multiple proposals in this conversation cited "~3 hrs", "~1 hr", etc. Tracing back: no skill, no instruction, no canon required them. Pure heuristic from training. The numbers were honest-feeling but had no measurement behind them. gstack has the right discipline (dual-time estimates: human-team vs. CC+gstack, from `task-emission-schema.ts`); Vibeboss had nothing.

## Decision

Ship all three fixes together as v0.2.3:

### (1) Framework feedback channel

- New directory: `<workspace>/hq/follow-ups/framework/` with `README.md`, `.gitkeep`, and a `processed/` subfolder.
- Boss writes here when partner reports a framework issue OR Boss notices a canon-level gap. Filename: `YYYY-MM-DD-<slug>.md`. Body: problem statement, reproducer, Boss's local workaround if any, suggested fix or framework change.
- Vibe Chief on every reno boot reads each workspace's `follow-ups/framework/` directory. Workspaces are tracked in a new file at `vibeboss/.workspaces` (gitignored, one absolute path per line, populated by `init.sh` on every install / `--upgrade` / `--update` / `--add-project`).
- After Vibe Chief addresses an item: append a `## Disposition` block (the protocol from v0.2.1) with verdict/result/rationale/closed-thread, then move the file to `follow-ups/framework/processed/`.
- Migration script `migrations/v0.2.2-dev-to-v0.2.3-dev.sh` backfills the directory + registers the workspace for legacy installs.

This is **the only sanctioned channel** that crosses the Vibe-Chief / Boss boundary. Documented in `templates/hq/follow-ups/framework/README.md`.

### (2) First-response discipline (LESSON-007)

New hard-gate LESSON-007 in `templates/hq/lessons.md`:

> **Rule:** On the FIRST response of every new session, output the boot brief (provided as additionalContext by the SessionStart hook) as the lead of your reply, regardless of what the operator says — including "hi", direct tasks, or any other input. Then proceed with their actual request (or ask "What are we working on?" if it was a greeting).

`templates/hq/CLAUDE.md` gets a new `## First-response discipline` section at the very top — imperative language, before the existing `## Boot sequence`. Same imperative shape goes into `templates/projects/_per_project/README.md` for project-level build leads, and into `CHIEF.md` for Vibe Chief's own first-response.

The brief's content stays the same; the change is purely about making the model OUTPUT it unprompted.

### (3) Calibration log + claim-provenance discipline (LESSON-008)

- Two new JSON Lines logs:
  - `<workspace>/hq/calibration/log.jsonl` — Boss appends entries when work completes.
  - `<vibeboss>/calibration/log.jsonl` — Vibe Chief appends entries for framework work. Seeded with three retroactive entries reconstructing v0.2.0 / v0.2.1 / v0.2.2 wall-clock from this session's git history (n=3 baseline).
- Schema documented in both `calibration/README.md` files. Required fields: `date`, `task`, `scope`, `tags`, `wallclock_min`. Optional: `subagents`, `files`, `human_est_min`, `notes`. Append-only.
- New hard-gate LESSON-008:

  > **Rule:** Every numerical or quantitative claim — time estimates, percentages, counts — cites its source. For time: grep `hq/calibration/log.jsonl` for ≥3 similar past entries; report median + range + sample size. For counts: run the count. For percentages: cite the measurement. If no source can be cited, prefix the number with `guess:` and italic-format. Skip for clearly subjective claims.

- `templates/hq/CLAUDE.md` and `CHIEF.md` both get a new `## Estimate honesty + claim provenance` section.

## Why this shape

1. **One channel, not many.** Boss → Vibe Chief feedback could have used inboxes, a github issues mirror, or a per-issue file. The `follow-ups/framework/` directory reuses an existing primitive (follow-ups already had a README and a discipline pattern) without inventing new shape. Reuse > invention.

2. **`.workspaces` is gitignored, runtime-only.** Vibe Chief reads it on boot; it's never committed. Multi-workspace setups (one operator running multiple ventures) work because all workspace paths land in the same file. Single-workspace setups are the common case.

3. **First-response discipline is a CLAUDE.md edit, not a hook change.** The hook already does its job (injecting additionalContext). The gap was model behavior — imperative language is the right tool. Doing this in a hook (e.g. forcing the first turn) would fight the model rather than direct it.

4. **Calibration via JSON Lines, not SQLite or YAML.** JSONL is greppable, appendable without parsing the whole file, robust to corruption (one bad line = one bad entry, rest still readable), and trivial to aggregate with `jq`. Schema is minimal so logging stays cheap.

5. **Retroactive seeding with n=3** gives the log enough data to be useful immediately. Without seeding, LESSON-008 would universally produce "guess: ~X" labels until enough entries accumulate. With three retroactive entries, the first real estimate for "subagent-cluster + templates + bash" tasks can cite a median (~25 min).

6. **Human-estimate as optional, explicit field.** `human_est_min` is the operator's gut estimate of what a developer-without-CC would take — never measured, always a guess. Including it as a separate field makes that distinction explicit and lets future analysis compare CC speedup ratios.

## Limits

- **`.workspaces` doesn't survive `vibeboss/` directory moves.** If the operator relocates the source tree, `.workspaces` paths still point to the old workspace locations (which are usually fine — workspaces don't move with the source). But Vibe Chief reading the file in a freshly-cloned source repo on a new machine would find an empty file. Acceptable: just install once on the new machine and the file repopulates.
- **Calibration median can be misleading for small N.** Three entries can't characterize a wide-variance task. The README documents the median + range + sample-size citation explicitly so the reader sees confidence as well as the number.
- **First-response discipline can't be enforced by code.** It's a model-behavior contract. Adherence depends on the imperative language landing in the model's context with enough weight. If it drifts, the operator catches it (as they did) and the rule gets sharpened.
- **No automatic feedback-channel routing.** When partner reports an issue, Boss has to consciously decide "this is framework-level, write it to follow-ups/framework/" rather than "this is project-level, write to STATE/runlog/decisions." Heuristic; might drift. Future: a `categorize-feedback` skill or LESSON-009 if drift becomes real.

## Consequences

- v0.2.3 ships three discipline shifts together — they're logically independent but operationally connected (all are about the seams between Boss and Vibe Chief / between session and session / between claim and source).
- Future framework work that Vibe Chief does will be calibrated against the seeded baseline; future estimates will improve in accuracy as data accumulates.
- The first-response discipline directly addresses the operator's observed bug. If "hi" still produces vanilla-Claude behavior after v0.2.3 lands, the rule needs sharpening (or the hook needs investigation).
- Boss now has a sanctioned write target for framework observations. The Boss CLAUDE.md should mention this when documenting how to handle "framework-level" observations vs. "project-level" ones — that documentation will land in a follow-up pass alongside the LESSON-007 / LESSON-008 wording.

## Supersedes

Nothing. First decision on framework feedback channel and on calibration discipline.
