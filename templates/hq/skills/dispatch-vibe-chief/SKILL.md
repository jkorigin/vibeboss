---
name: dispatch-vibe-chief
description: Use when Boss has framework-canon work that belongs to Vibe Chief and partner has not opted to context-switch by running `bash reno.sh` themselves. Defines the two-path dispatch flow with mandatory active-session detection before spawning.
---

# Dispatch Vibe Chief

## When to use

Boss surfaces framework-canon work in two situations:

1. **Partner reports a framework bug or asks for a framework change** ("the auto-boot didn't fire", "ship v0.2.4", "update the templates").
2. **Boss notices canon-level drift while doing HQ work** (template stale relative to live workspace, decision file describes superseded design, CHANGELOG entry describes design we abandoned).

In both cases the work belongs at `~/ventures/vibeboss/` — that's Vibe Chief's domain, not Boss's. The dispatch question is: how does Vibe Chief actually do the work?

## Two paths

### Path A (primary) — partner boots Vibe Chief manually

Partner runs `bash ~/ventures/vibeboss/reno.sh` in another terminal. Vibe Chief activates with full discipline. Boss writes a follow-up file at `hq/follow-ups/framework/YYYY-MM-DD-<slug>.md`; on Vibe Chief's next boot, the CHIEF.md boot sequence reads `vibeboss/.workspaces` → globs each workspace's `follow-ups/framework/` → surfaces pending items.

This is the standard flow. Use it whenever partner is happy to context-switch.

### Path B (secondary) — Boss spawns Vibe Chief in background

When partner explicitly doesn't want to run `reno.sh` (or any other script), Boss spawns Vibe Chief as a background subprocess via `hq/scripts/spawn-vibe-chief.sh`. The script handles:

- `cd` to vibeboss/ source
- Set `VIBEBOSS_RENO=1` so route.sh boots Vibe Chief (not the redirect)
- Subscription-auth env cleanup (per WA-PA-LESSON-004)
- Log to `hq/spawns/vibechief-<timestamp>.log` so Boss can tail
- **Mandatory active-session detection** before spawning

## Mandatory active-session check

**Never spawn Vibe Chief without checking for existing claude processes at `vibeboss/` cwd.** A clash (two concurrent Vibe Chief sessions writing to the same source tree) corrupts state — git conflicts, race conditions in CHANGELOG edits, inconsistent decision files.

Detection (`spawn-vibe-chief.sh` does this automatically):

```bash
lsof -c claude 2>/dev/null | awk -v dir="$VIBEBOSS_DIR" '$4=="cwd" && $NF==dir {print $2}'
```

If this returns any PIDs, `spawn-vibe-chief.sh` refuses to spawn (exits 2) and prints `ACTIVE_VIBE_CHIEF_DETECTED`. Boss must then:

1. **Surface to partner** what was found and what the work is.
2. **Ask partner to relay** the context to whichever Vibe Chief session is active. The simplest relay payload is: "Read `<absolute path to follow-up file>` and execute." If the active session isn't currently Vibe Chief (could be a Boss session that drifted into vibeboss/), partner decides whether to relay anyway or to terminate the orphan and let Boss spawn fresh.

Do NOT try to disambiguate process roles from outside (transcript inspection is fragile — both Boss and Vibe Chief sessions can have CHIEF.md or HQ-banner content in their JSONL history if they switched modes or have long lifespans). The active-session check is purely "is anything alive at this cwd" — partner is the source of truth for "what role is it in."

## Dispatch flow (decision tree)

```
Framework work needed
  │
  ├─ Partner says "I'll boot Vibe Chief myself" or "I'll run reno"
  │     → Path A: write follow-up file, tell partner where it is, done
  │
  ├─ Partner says "do it yourself" / "no scripts" / silent on path
  │     → Path B:
  │         Run spawn-vibe-chief.sh (it does the active-session check)
  │           ├─ Exit 0 (spawn launched)
  │           │     → tail log, report results to partner when done
  │           ├─ Exit 2 (active session detected)
  │           │     → surface to partner + offer relay payload
  │           └─ Exit 1 (setup error)
  │                 → diagnose; usually missing .vibeboss-version source_path
  │
  └─ Partner explicitly says "ask the active Vibe Chief"
        → write follow-up file, surface absolute path, partner relays
```

## What goes in the follow-up file

Same content regardless of Path A or Path B — the file is the durable instruction Vibe Chief executes:

- **Date / From / To / Priority / Status** front-matter
- **Why this is here** — what triggered the framework-level work, brief context
- **Failure modes diagnosed** (if shipping a fix) or **what the gap is** (if shipping a feature)
- **The fix that works** — the proposed change, with verification evidence if Boss already validated it live
- **Exact port tasks** — numbered list of file edits, copy-from-live paths, exact diff content where possible
- **Reference: copy-from sources** table mapping target template paths → live workspace source paths
- **Migration for legacy installs** — bash steps for `migrations/v0.X.Y-to-v0.X.Z.sh`
- **Validation gate** — what tests Vibe Chief must run before declaring done

The clearer this file is, the less Vibe Chief has to re-think. Write it as if briefing a smart colleague who hasn't seen the conversation.

## Commit hygiene

When Vibe Chief commits (Path A or Path B), the `prepare-commit-msg` hook in `vibeboss/` rewrites the trailer from "Claude" → `vibechief`. Don't override. If you find yourself wanting to use `--no-verify`, stop — that's never been correct in this codebase.

## After dispatch

- Path A: partner runs Vibe Chief themselves; Boss watches for the disposition block to appear in the follow-up file (it gets moved to `processed/` when done).
- Path B: Boss tails `hq/spawns/vibechief-<timestamp>.log`. When the log shows completion, Boss reads the disposition block, reports to partner, then archives the log (move into `hq/spawns/archive/` if log dir gets crowded).

In either case, after disposition: if the change touched templates/CLAUDE.md or settings.json in templates, run `init.sh --update --workspace <this-workspace> --noninteractive` from the source dir to land the framework change into this workspace too. (Path A: ask partner or do it via Bash. Path B: include this step in the original prompt to Vibe Chief.)

## Cost

On a subscription plan, neither path incurs per-spawn dollar charges (per Claude Pro/Max subscription model). Don't quote dollar costs to partner. The background spawn does consume context-window budget on Anthropic's side and concurrent-session limits — usually fine for one Vibe Chief at a time, which is exactly why the active-session check is mandatory.
