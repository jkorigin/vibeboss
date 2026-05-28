# Compact Handover — Design Spec

**Subsystem:** E
**Status:** shipped 2026-05-26
**Author:** Boss (Vibeboss venture lead)

---

## Problem

CC sessions accumulate context. Two failure modes Vibeboss must prevent:

1. **Silent quality degradation:** as context fills, the model forgets early-session details. Subtle, hard to detect, dangerous.
2. **Hard cutoff:** session cannot continue once context limit is reached. Loss of in-flight work.

CC provides `/compact` — a command that asks the model to summarize the session, then trims the conversation to that summary. After `/compact`, the session continues with reduced context. But `/compact` is **lossy by nature**: a model-generated summary drops specifics.

## Solution: session-never-closes pattern

Before `/compact`, the agent writes a **structured handover file** capturing in-flight state. After `/compact`, the `SessionStart compact` hook reads the handover and injects it as `additionalContext`. Result: `/compact` is lossless from a resumption standpoint — the model summary is augmented by a structured, agent-written note.

## Self-monitoring triggers

Since CC exposes no direct "tokens remaining" signal, the agent uses heuristics. Any single trigger is sufficient:

| # | Trigger | Threshold | Rationale |
|---|---|---|---|
| T1 | Turn count | >50 substantive turns | Rough proxy for context depth |
| T2 | Session age | >4 hours active | Long sessions accumulate large tool results |
| T3 | Tool result volume | Last 10 tool results avg >3KB | Direct context pressure signal |
| T4 | Partner signal | Partner asks to compact | Explicit human authority |
| T5 | Self-perception | Model notices recall gaps | The most reliable signal — the model itself notices |

## Architecture

```
SessionStart (compact matcher)
  └── compact-boot.sh
        ├── calls boot.sh → standard boot brief
        └── finds hq/handovers/*.md (mtime < 60 min)
              ├── found → injects file content into additionalContext
              └── not found → announces gap, instructs re-read of STATE.md
```

## Hook approach: separate compact-boot.sh

Chose a **separate `compact-boot.sh`** over extending `boot.sh` for these reasons:

1. `boot.sh` already handles startup/resume correctly. Adding compact-mode detection would add a conditional branch requiring the script to receive its own matcher value as input — not how hooks are wired.
2. `compact-boot.sh` has distinct logic: call boot.sh as a subprocess, parse its JSON, augment with handover, re-emit. That's augmentation, not duplication.
3. Testing is cleaner — each hook script can be tested independently.
4. `boot.sh` stays simple and unchanged.

## Handover format rationale

Fields chosen for minimum viable resumption:
- **Session metadata** — allows cross-session correlation and debugging
- **In-flight task** — the ONE thing the session must not lose
- **What just happened** — prevents context-cliff at the compact boundary
- **Critical context** — catches conventions/partner-intent not yet formalized
- **Resume action** — eliminates post-compact disorientation ("where was I?")
- **Open spawns** — crew system: active sessions must be tracked
- **Lessons not yet logged** — captures learning before compaction discards it
- **Open task list** — TaskCreate tasks are in-memory; handover preserves them

## Staleness window: 60 minutes

`/compact` itself takes <5 seconds. A 60-minute window is generous enough to cover:
- Slow CC startup after compact
- Manual `/compact` followed by a break before resumption

After 60 minutes, the handover is flagged stale. The agent must re-orient from STATE.md and runlog.

## What this subsystem does NOT do

- Does not auto-detect when to compact (would require per-turn hooks — too invasive)
- Does not attempt to run `/compact` programmatically — it is a CC UI command only
- Does not modify `hq/CLAUDE.md` directly (auto-mode classifier blocks; patch queued as inbox request)

## Files

| File | Purpose |
|---|---|
| `hq/skills/compact-handover/SKILL.md` | The skill: triggers, ritual, format, discipline |
| `hq/.claude/hooks/compact-boot.sh` | Hook script for `compact` matcher |
| `hq/.claude/settings.json` | `compact` matcher entry added |
| `hq/handovers/README.md` | Directory README: naming, staleness, retention |
| `hq/handovers/2026-05-26-1200-subsystem-E-sim.md` | Simulation handover for round-trip test |
| `hq/inbox/requests/2026-05-26-claude-md-compact-patch.md` | CLAUDE.md patch for Boss to apply |
