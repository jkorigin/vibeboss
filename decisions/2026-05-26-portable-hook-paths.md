# Decision — Portable hook paths for `vibeboss/.claude/settings.json`

**Date:** 2026-05-26
**Layer:** Framework (Vibeboss canon)
**Author:** Vibe Chief
**Status:** active

## Context

`vibeboss/.claude/settings.json` specifies the `SessionStart` hook command that routes Claude Code sessions at the source repo to either Vibe Chief (via `route.sh`) or a redirect (for accidental `cd` without `reno.sh`). The hook command must be an absolute path because CC does not guarantee relative-path resolution for hook commands.

The path was originally committed as `/Users/jinkunyong/ventures/vibeboss/.claude/hooks/route.sh` — the partner's machine-specific absolute path. This breaks silently on every other clone.

## Options considered

**(a) Relative path** — `".claude/hooks/route.sh"` in settings.json. Cleanest if CC resolves from project root. Not reliably documented in CC's hook spec. Risk: silent failure on some CC versions.

**(b) `${CLAUDE_PROJECT_DIR}` env var** — if CC exposes this in the hook environment. Not confirmed in CC's documented surface.

**(c) `reno.sh` self-substitution** — on each `bash reno.sh` invocation, rewrite `settings.json` with the real absolute path before launching `claude`. Restore the placeholder on exit.

## Decision

**Option (c) — `reno.sh` self-substitution** with a trap-restore pattern.

Rationale:
1. Works regardless of CC's internal path resolution behavior.
2. The placeholder in the committed `settings.json` makes the mechanism self-documenting.
3. The trap-restore (bash `trap` on EXIT, `claude` without `exec`) keeps the committed file clean — git shows no modification after a session.
4. `reno.sh` is the only sanctioned entrypoint for Vibe Chief sessions; there is no scenario where `vibeboss/.claude/settings.json` needs to work without `reno.sh` having run first.

## Mechanism

`settings.json` committed with: `"VIBEBOSS_DIR_PLACEHOLDER/.claude/hooks/route.sh"`

`reno.sh` on startup:
1. Copies `settings.json` → `settings.json.reno-bak`
2. Replaces `VIBEBOSS_DIR_PLACEHOLDER` with `$VIBEBOSS_DIR` (computed by `reno.sh`)
3. Registers `trap _restore_settings EXIT`
4. Runs `claude` (not `exec` — so trap fires when CC exits)
5. On exit, moves `settings.json.reno-bak` back to `settings.json`

`.gitignore` includes `settings.json.reno-bak` to prevent accidental commit of the backup.

## Redirect case (direct `cd vibeboss && claude`)

If a user `cd`s to `vibeboss/` and runs `claude` without `reno.sh`, `settings.json` has the placeholder path. CC will fail to find the hook (or report a hook-not-found warning) and boot a vanilla session. This is acceptable — `CLAUDE.md` visible in the project root already explains the two paths (Boss vs. Vibe Chief). The redirect hook is belt-and-suspenders.

## Consequences

- `reno.sh` is no longer a pure `exec` (uses `claude` + trap). Minor: one extra bash process lives for the duration of the session. Acceptable.
- `.gitignore` must include `.claude/settings.json.reno-bak`.
- Future framework contributors should never commit `settings.json` with a real path — only the placeholder.
- If CC's hook system documents relative-path support in a future version, we can simplify to option (a) and supersede this decision.

## Supersedes

Nothing. This is the first documented decision for hook-path portability.
