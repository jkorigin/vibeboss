# Decision — Add workspace-root redirect to templates

**Date:** 2026-05-26
**Layer:** Framework (Vibeboss canon)
**Author:** Vibe Chief
**Status:** active

## Context

When a user installs Vibeboss via `init.sh`, they get `vibeboss-workspace/{hq,labs,projects}/` scaffolded. The agent (Boss) lives in `hq/`, activated by `cd hq/ && claude`. But new users frequently `cd vibeboss-workspace/` and run `claude` directly — landing at the workspace root. Without a hook, they get a vanilla CC session with no identity, no context, no guidance.

This failure mode was identified at v0.1.0 and manually patched in the partner's installation at `vibeboss-workspace/.claude/`. It was not templated, so fresh installs from `init.sh` didn't get it.

## Decision

Add `templates/_workspace_root/.claude/` containing:

- `settings.json` — wires SessionStart (startup + resume) to `redirect.sh`
- `hooks/redirect.sh` — emits a hookSpecificOutput JSON with `additionalContext` (the redirect message)
- `hooks/redirect.md` — the human-readable redirect message (parameterized with `{{LEAD_NAME}}` and `{{WORKSPACE}}`)

Update `init.sh` to:
1. Create `$WORKSPACE/.claude/hooks/`
2. Copy and substitute all three files from the template
3. `chmod +x` the `redirect.sh`

## Why this template approach

The hook is already implemented and battle-tested in the partner's runtime installation. Templating it:
- Gives every new installer the redirect by default (no manual step)
- Uses the same `{{LEAD_NAME}}` substitution as the rest of the templates (the redirect message addresses the user's lead by their chosen name)
- Keeps the redirect.md portable — no partner-specific names hardcoded

## Consequences

- `init.sh` now creates one extra directory (`$WORKSPACE/.claude/`) and three files. Upgrade mode (`--upgrade`) skips existing files idempotently.
- The workspace root `.claude/settings.json` uses an absolute path (via `{{WORKSPACE}}`) for the hook — consistent with how HQ hooks are wired.
- The redirect message is generic enough to work for any installation (any lead name, any workspace path).
- Users can customize `redirect.md` after install without breaking any framework-level logic.

## Supersedes

Nothing. First decision for workspace-root templating.
