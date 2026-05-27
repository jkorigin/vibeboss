# Decision — `${CLAUDE_PROJECT_DIR}` for hook paths (supersedes trap-restore)

**Date:** 2026-05-27
**Layer:** Framework (Vibeboss canon)
**Author:** Vibe Chief
**Status:** active
**Supersedes:** `2026-05-26-portable-hook-paths.md`

## Context

The previous decision (`2026-05-26-portable-hook-paths.md`) chose a `reno.sh` self-substitution + trap-restore pattern: commit `settings.json` with `VIBEBOSS_DIR_PLACEHOLDER`, substitute the real absolute path at every `reno.sh` invocation, restore the placeholder on `EXIT` via `trap`. The audit on 2026-05-27 surfaced three problems with that pattern:

1. **Concurrency hazard.** Two parallel `reno.sh` invocations clobber each other's `settings.json.reno-bak`. The second `cp` overwrites the placeholder-restored backup with the already-substituted version. On exit, both restore the substituted version — placeholder lost, working tree dirty, next commit ships a partner-specific path.
2. **Crash recovery.** `kill -9`, system crash, or shell-exit-without-trap leaves `settings.json` substituted. Git status dirty. Risk of committing partner's absolute path on next `git add .`.
3. **Heredoc fragility.** The `python3 - <<PYEOF` block interpolates `$SETTINGS_FILE` and `$VIBEBOSS_DIR` via bash before Python sees them. A path containing `"` or `\` breaks the heredoc.

The original decision noted Option (a) — relative paths — and Option (b) — `${CLAUDE_PROJECT_DIR}` — were "not confirmed in CC's documented surface" and rejected on that basis. **The rejection was on unverified assumptions.** `${CLAUDE_PROJECT_DIR}` is documented to be available to hook commands in Claude Code.

## Decision

**Use `${CLAUDE_PROJECT_DIR}` for all hook command paths.** Delete the trap-restore mechanism in `reno.sh`. Commit `settings.json` files with the env-var form directly — they're correct everywhere, on every clone, without runtime substitution.

This applies to:
- `vibeboss/.claude/settings.json` (Vibe Chief / redirect routing)
- `templates/hq/.claude/settings.json` (HQ boot + compact)
- `templates/_workspace_root/.claude/settings.json` (workspace-root redirect)

The `{{HQ_PATH}}` and `{{WORKSPACE}}` placeholders that `init.sh` previously substituted into installed `settings.json` files are also replaced with `${CLAUDE_PROJECT_DIR}` — this makes installed workspaces portable across renames and moves. `init.sh`'s `substitute()` function only swaps `{{...}}` placeholders; `${...}` is different syntax and is left alone.

## Mechanism

`settings.json` hook commands shift from:

```
"VIBEBOSS_DIR_PLACEHOLDER/.claude/hooks/route.sh"
```

or (in templates):

```
"{{HQ_PATH}}/.claude/hooks/boot.sh"
```

to a single uniform form:

```
"${CLAUDE_PROJECT_DIR}/.claude/hooks/<script>.sh"
```

Claude Code expands `${CLAUDE_PROJECT_DIR}` to the project root at hook execution time. No bash-side substitution, no install-time substitution, no trap.

## Consequences

- `reno.sh` is now a thin wrapper: `cd` to source dir, `export VIBEBOSS_RENO=1`, `claude`. No state mutation. Trap-restore deleted.
- `.gitignore` entry for `.claude/settings.json.reno-bak` removed (no backup file is ever produced now).
- Installed workspaces survive renaming or moving. Previously the embedded absolute path would break; now `${CLAUDE_PROJECT_DIR}` resolves to wherever Claude Code launches.
- Failure mode if a CC version doesn't expand `${CLAUDE_PROJECT_DIR}`: the hook command fails to find the script and the session boots without the brief. Non-fatal; logged in CC's hook output. Better failure mode than the previous "trap didn't fire → partner data committed."
- A `clear` matcher was added alongside `startup` and `resume` in all three `settings.json` files, so `/clear` no longer silently skips the boot brief.

## Supersedes

`2026-05-26-portable-hook-paths.md` — superseded entirely. The trap-restore mechanism described there is no longer in the codebase.
