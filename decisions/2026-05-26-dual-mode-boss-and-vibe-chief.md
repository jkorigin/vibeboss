# Decision — Dual-mode agent topology (Boss + Vibe Chief)

**Date:** 2026-05-26
**Layer:** Framework (Vibeboss canon)
**Author:** Boss, acting as Vibe Chief (the role didn't formally exist yet, so Boss wrote it)
**Approver:** partner
**Status:** active

## Context

After 6 subsystems shipped, partner asked: "if vibeboss source code is the installer, who is the agent at `~/ventures/vibeboss/` itself? Or does Boss live at both sides?" The question was sharper than the existing architecture answered. There were three plausible models:

1. **Boss everywhere** — same identity at `hq/` and at `vibeboss/`, the agent self-detects mode by cwd.
2. **Separate agents** — Boss at HQ, a distinct named agent at vibeboss/.
3. **Hybrid — Boss + reviewer subagent** — Boss does framework work too, but dispatches a "framework reviewer" subagent for canonization.

Partner's read: "majority are consumer not maintainer." Boss is the default. People accidentally cd to vibeboss/ — that needs handled. People intentionally enhance the framework — they need a distinct identity so they know they're not talking to runtime Boss.

The right answer is **(2) with a redirect for accidental cd's**, with the framework-dev identity called **Vibe Chief** (partner's chosen name).

## Decision

**Two agent identities, one partner, mode determined by activation:**

| Mode | Identity | cwd | Activated by | Boot brief |
|---|---|---|---|---|
| HQ runtime | **Boss** | `vibeboss-workspace/hq/` | `cd <workspace>/hq && claude` (SessionStart hook fires automatically) | `hq/.claude/hooks/boot.sh` (Subsystem D) |
| Framework dev | **Vibe Chief** | `vibeboss/` | `bash reno.sh` (sets `VIBEBOSS_RENO=1`, launches `claude`) | `vibeboss/.claude/hooks/route.sh` reads `vibeboss/CHIEF.md` |
| Accidental cd to `vibeboss/` | None (redirect) | `vibeboss/` | `cd vibeboss && claude` without reno flag | `vibeboss/.claude/hooks/route.sh` reads `vibeboss/.claude/hooks/redirect.md` |

**Roles:**
- **Boss** owns the partner's runtime — talks to partner, dispatches build leads (Banana / Carrot / Ginger), surfaces status, never writes to `vibeboss/` source.
- **Vibe Chief** owns the framework canon — writes to `vibeboss/` source, `templates/`, `decisions/`, `CHANGELOG.md`, `docs/`. Never writes to `vibeboss-workspace/`.
- **Both** address partner as "partner" (LESSON-001).

**The redirect path** is load-bearing UX. Most users will accidentally `cd` to `vibeboss/` because the install instructions point there. The route hook detects no `VIBEBOSS_RENO` env var and emits a friendly explanation: "you probably want HQ — `cd ../vibeboss-workspace/hq/`. If you want to enhance the framework, run `bash reno.sh`." No identity is loaded in this state; the session is exploratory only.

## Why this shape

1. **Separation of concerns.** Boss is fast / build / partner-focused. Vibe Chief is careful / canon / OSS-user-focused. Different priorities, different memory routes, different disciplines.
2. **Accident-tolerant.** A user who cd's to the wrong place gets corrected, not confused. The redirect message is the safety net.
3. **Clear naming announces the mode.** Partner sees "Vibe Chief" in the boot banner and knows immediately they're not talking to runtime Boss. Reduces "wrong agent" mistakes.
4. **Vibe Chief breaks the produce naming theme intentionally.** Produce names (Banana, Carrot, Ginger) are project-level build leads — the layer where Boss dispatches work. Vibe Chief is at a different layer entirely (framework, not partner-owned project). The name marks the layer change.
5. **One partner, no extra cognitive load.** Partner doesn't need to manage two relationships. Boss and Vibe Chief are two roles the *same* partner activates by command.

## Mechanism (technical)

`vibeboss/reno.sh` sets `VIBEBOSS_RENO=1` and execs `claude` interactively. CC auto-loads `CLAUDE.md` from cwd; the SessionStart hook in `vibeboss/.claude/settings.json` fires `route.sh`. The hook reads `$VIBEBOSS_RENO`:

- If `=1`: read `vibeboss/CHIEF.md`, emit as `hookSpecificOutput.additionalContext`. Vibe Chief is loaded.
- If unset/other: read `vibeboss/.claude/hooks/redirect.md`, emit. No identity loaded; user is told how to pick a mode.

The hook script also handles a missing-brief-file fallback (emits a minimal valid JSON) so a corrupted install doesn't block session boot.

## Consequences

- `vibeboss/` source ships with `.claude/`, `CHIEF.md`, `reno.sh`, `route.sh`, `redirect.md` — these are part of the framework, never templated.
- The init script (`init.sh`) does NOT install Vibe Chief into the workspace. Vibe Chief lives only at source.
- When a user clones vibeboss/, they get Vibe Chief mode "for free" — `bash reno.sh` just works.
- The dashboard's Sessions pane surfaces both Boss sessions (at `hq/`) and Vibe Chief sessions (at `vibeboss/`), so partner can see when each is active.
- Future Vibeboss versions can add more modes (e.g. a `--dashboard-only` mode for dashboard maintainers) by extending the same `VIBEBOSS_*` env-var routing pattern.

## What this design does NOT cover

- A third named agent for cross-partner support (e.g. someone running multiple vibeboss workspaces). Deferred — not needed at current scale.
- Sage/Pepper/other-name alternatives. Considered and rejected by partner ("too AI sounding"). Vibe Chief locked.
- Shell-alias setup for `vibeboss reno` as a real command (instead of `bash reno.sh`). Deferred to v0.2.0 — `init.sh` could optionally inject the alias into the user's shell rc.

## Supersedes

Nothing. Earlier topology decisions (2026-05-25-build-locations-and-spawning.md, 2026-05-25-workspace-reorg.md, 2026-05-26-topology-hq-split-design.md) didn't address the framework-side agent question — they all assumed Boss was the only identity. This decision is additive.
