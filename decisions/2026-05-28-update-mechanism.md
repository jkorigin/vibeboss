# Decision — Vibeboss update mechanism (version pinning + manifest-driven refresh)

**Date:** 2026-05-28
**Layer:** Framework (Vibeboss canon)
**Author:** Vibe Chief
**Status:** active

## Context

Through v0.2.1 there was no way for an existing Vibeboss workspace to receive framework updates. `init.sh --upgrade` was strictly additive: it added missing files, never refreshed existing ones. So when v0.2.0 superseded the trap-restore hook pattern with `${CLAUDE_PROJECT_DIR}`, or v0.2.1 introduced the per-project skill bundle, running workspaces silently fell behind. The update path was:

> "manually diff `templates/` against your workspace and copy whatever you want"

— which scales to zero users.

The Vibe Chief side of the update was always trivial: edit templates, commit, push. The user side was the gap.

The complication: workspaces accumulate user edits. CLAUDE.md gets local notes. crew.yml gains agents. STATE.md gets project-specific status. A naive "refresh all files" overwrites customization. A naive "skip all files" leaves the workspace behind. The mechanism has to distinguish.

## Decision

**Adopt a manifest-driven update mechanism with four moving parts:**

1. **Per-workspace version pinning.** Every install writes `<workspace>/.vibeboss-version` recording:
   - the Vibeboss version that scaffolded it (from `<source>/VERSION`)
   - the absolute path to the source repo (`source_path`)
   - the git SHA of the source at install time (`source_sha`)
   - installed_at + updated_at ISO 8601 timestamps

2. **Per-file installed-original hash manifest.** For every template-derived file, install records its post-substitute SHA256 at `<workspace>/.vibeboss/originals/<rel-path>.sha256`. This is the source of truth for "what did this file look like when we put it there?" Without this, "did the user customize this?" is unanswerable.

3. **`init.sh --update` mode.** Walks the templates tree. For each file:
   - If the workspace destination doesn't exist → create it (treat as legacy missing).
   - If it exists and current-hash matches stored-original-hash → user hasn't touched it; refresh and update the stored hash.
   - If current-hash differs from stored-original-hash → user customized. Prompt: keep / overwrite / view-diff / skip. `--noninteractive` defaults to keep.
   - If stored-original-hash is missing (legacy workspace) → adopt the workspace file as authoritative; store its current hash as the original. Never overwrite a legacy file silently.
   - After all files, run migrations between installed and target version, then write the new `.vibeboss-version`.

4. **Migrations directory + runner.** `<source>/migrations/v<from>-to-v<to>.sh` are versioned shell scripts that each take `$1 = workspace`. The runner (`migrations/run.sh`) lex-sorts and applies the chain between installed and target. Used for *structural* changes (rename a directory, split one file into two) — NOT for content updates of templates, which are handled by the manifest-driven refresh.

5. **Boss-aware update banner.** `templates/hq/.claude/hooks/boot.sh` reads `<workspace>/.vibeboss-version` and `<source>/VERSION`; if they differ, appends a banner to the brief with the exact update command. Silent fail if the version file is missing or malformed.

## Why this shape

1. **The hash manifest is the load-bearing idea.** Once we know what the file looked like at install time, every other question ("did the user customize this?", "is this safe to overwrite?", "what changed?") is answerable. Without it we'd need three-way merge, which is heavier and noisier.

2. **Per-file resolution preserves customization at the right grain.** Workspaces drift file-by-file. Whole-tree decisions ("refresh all" or "keep all") force the wrong default on the wrong half of the tree. Per-file prompts let the operator's customizations live alongside framework updates with no merge conflict.

3. **Migrations as a separate channel** keeps the manifest-driven refresh focused on text content. When the framework needs a structural change (e.g. v0.3.0 will rename `templates/hq/skills/` to a different layout when the marketplace lands), the migration script handles the rename; the manifest handles the per-file content refresh that follows.

4. **The Boss banner closes the loop.** Operators don't remember to check for updates. They open Claude Code, see the banner, run the command. Surfacing is more reliable than scheduled notifications because it appears exactly when they're already paying attention.

5. **Defensive silence on errors.** Missing `.vibeboss-version`, malformed file, missing source path, missing source `VERSION` — all silently produce no banner, never block boot. Better degradation than visible breakage for a non-critical surface.

## Limits / known caveats

- **Lex-comparison of versions.** The runner sorts migrations by string compare on filenames. `v0.10.0-dev` sorts before `v0.2.0-dev` lexically. Fine until we cross x.10; documented in `migrations/README.md`. When it bites, switch to a sortable version-tuple format.
- **No three-way merge.** A user who has customized a file *and* whose customization conflicts with an upstream change has to choose one or the other. We diff but don't merge. Could add three-way merge later via `git merge-file` for the brave.
- **Refreshed files lose user customizations on the customized → overwrite branch.** That's the explicit semantic of "overwrite." The diff option exists specifically so the user can see what they're throwing away first.
- **Forking the framework.** If a user forks `~/ventures/vibeboss/` and edits templates locally, their workspace's `source_sha` will diverge from upstream `origin/main`. The update mechanism still works against the local fork; it just compares against whatever the fork's templates and VERSION currently say. This is correct behavior.

## Consequences

- v0.2.2 ships the mechanism. Future versions can iterate on policy without changing the architecture.
- Every install going forward records what version installed it. Workspaces installed before v0.2.2 lack the manifest; running `init.sh --update` against them is safe (legacy adoption path), but the first update can't tell what was customized vs original; it adopts current state as the new baseline.
- `init.sh` grew significantly (added ~200 lines for the update flow). Worth it — this is the primary user-facing surface for ongoing framework receipt.
- CHANGELOG and ROADMAP discipline matter more now: the migrations directory is the binding contract between releases. Breaking changes that aren't migration-covered will silently break user workspaces.

## Supersedes

Nothing. First update-mechanism decision. Future revisions reference this one.
