# Decision — Codex compatibility surface

**Date:** 2026-05-28
**Layer:** Framework (Vibeboss canon)
**Author:** Vibe Chief
**Status:** active

## Context

Partner booted Vibe Chief in Codex for the first time and asked whether the framework was Codex-friendly.

The audit found a partial yes:

- The source repo already had `AGENTS.md -> CLAUDE.md`, so Codex received the framework reference at `~/ventures/vibeboss/`.
- Freshly scaffolded workspaces did **not** have `AGENTS.md` at workspace root, `hq/`, `labs/`, or Boss-created project directories.
- Freshly scaffolded workspaces had Claude Code `.claude/` SessionStart hooks only. Codex supports project-local hooks through `.codex/hooks.json`, but Vibeboss did not scaffold those mirrors.
- Source-root framework-dev in Claude Code is activated by `bash reno.sh`; Codex has no equivalent wrapper. Therefore source-root Codex sessions need their own rule: source root means Vibe Chief, not accidental HQ work.

## Decision

Add a Codex compatibility layer that mirrors the existing Claude Code surfaces without forking the framework discipline:

1. **Codex instruction files.** Fresh installs now write:
   - `<workspace>/AGENTS.md` — workspace-root redirect instructions.
   - `<workspace>/hq/AGENTS.md` — generated from the same canonical template as `hq/CLAUDE.md`.
   - `<workspace>/labs/AGENTS.md` — generated from `labs/README.md`.
   - `<workspace>/hq/projects/<project>/AGENTS.md` — generated from the project README on `init.sh --add-project`.

2. **Codex hook mirrors.**
   - Source repo: `.codex/hooks.json` loads `CHIEF.md` for Codex source-root sessions.
   - Workspace root: `.codex/hooks.json` emits the same redirect shape as the Claude Code workspace-root hook.
   - HQ: `.codex/hooks.json` registers SessionStart and PreCompact hooks. The scripts are thin wrappers around the canonical `.claude/hooks/*.sh` scripts so boot and compact behavior stay single-sourced.

3. **Installer/update path.**
   - Fresh installs scaffold Codex files and restore executable bits.
   - `init.sh --update` creates missing `AGENTS.md` mirrors and `.codex/` hooks for existing workspaces, while preserving customized files through the manifest mechanism.

4. **Public wording.** README and framework reference now say the accurate thing: Claude Code remains the native runtime for spawn/session/plugin surfaces; Codex can operate the same source/workspace files through `AGENTS.md` and trusted `.codex` hooks.

## Why this shape

- **No duplicate runtime logic.** Codex HQ hooks call the existing `.claude` hook scripts. There is one boot parser, one compact handover implementation, one STOP-file check.
- **Codex works even if hooks are not trusted.** `AGENTS.md` carries enough instruction for Codex to manually execute the boot sequence.
- **Existing Claude Code behavior is unchanged.** `.claude/` files remain canonical for Claude Code. `reno.sh` remains the Claude-native Vibe Chief entrypoint.
- **Honest scope.** This does not make `claude -p`, `claude agents --json`, or Claude plugin activation magically available in Codex. It makes the Vibeboss canon and workspace memory discipline agent-tool portable.

## Verification

`tests/init-smoke.sh` now verifies fresh installs include:

- `AGENTS.md` at workspace root, HQ, labs, and scaffolded projects.
- `.codex/hooks.json` plus executable Codex hook scripts at workspace root and HQ.
- Codex boot and workspace-root redirect hooks emit valid JSON with `hookSpecificOutput.additionalContext`.

The source-level `.codex/hooks/route.sh` was separately run and JSON-parsed; it injected `CHIEF.md`.

## Limits

- Codex hook execution may require the user to trust the project-local hook configuration in Codex. If not trusted, `AGENTS.md` fallback instructions still apply.
- Background spawn orchestration remains Claude Code-specific because it uses `claude -p` and `claude agents --json`.
- The master dashboard's session visibility remains Claude Code-specific until Phase 1 decides whether a Codex-native session source belongs in scope.
