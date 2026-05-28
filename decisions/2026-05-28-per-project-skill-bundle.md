# Decision — Per-Project Skill Bundle (PPSB) architecture

**Date:** 2026-05-28
**Layer:** Framework (Vibeboss canon)
**Author:** Vibe Chief
**Status:** active

## Context

Through v0.2.0, Vibeboss shipped exactly two native skills (`dev-workflow`, `compact-handover`) as file-based SKILL.md trees under `templates/hq/skills/`. Everything else the framework leaned on was conditional: `dev-workflow` referenced superpowers' brainstorming/TDD/debugging/parallel-agent skills as recommended invocations, but never installed them. There was no opinion at all about what skills a Boss-created project should inherit.

The v0.2.1 audit found three concrete gaps:

1. **Fresh clones got broken references.** Operators reading `dev-workflow` saw `superpowers:brainstorming` invocations they couldn't run, because superpowers wasn't enabled in their workspace.
2. **No per-project bundle.** Each project Boss spawned came up with a default Claude Code skill set — whatever the operator's machine happened to have globally. Two operators on the same Vibeboss release got non-reproducible behaviour.
3. **No published opinion.** The README never told operators which companion skills make Vibeboss actually work, so the recommendation lived in the partner's head, not the canon.

Partner's brief: every Boss-created project should inherit a skill bundle. Per-project, not machine-wide. Superpowers as the always-on baseline. Curated opt-in pool for the rest. Reproducible across clones.

## Decision

Adopt the **Per-Project Skill Bundle (PPSB)** architecture. Three skill classes, scoped at the project level:

| Class | Activation | Scope | Examples |
|---|---|---|---|
| **Baseline (always on)** | Pre-enabled in every workspace's `.claude/settings.json` `enabledPlugins` | HQ + every Boss-created project | `superpowers@claude-plugins-official` |
| **Vibeboss-packaged natives** | Bundled in `templates/`, file-based in v0.2.1; will migrate to a Vibeboss marketplace in v0.3.0 | HQ + Boss-created projects | `dev-workflow`, `compact-handover` |
| **Vibeboss-recommended** | Opt-in per project; documented in README; one-command install via `/plugin install <name>@claude-plugins-official` | Per project | `context7`, `code-review`, `pr-review-toolkit`, `commit-commands`, `frontend-design`, `playwright`, `hookify`, `skill-creator`, `claude-md-management`, `feature-dev`, service integrations |
| **User-custom** | Operator-authored, lives under the project's `.claude/skills/` | Per project | Anything the operator writes |

External skills (notably `gstack`) are recommended in the README but never vendored, never auto-installed, and never added to a Vibeboss marketplace. The README points at their canonical upstream.

## Why per-project, not machine-wide

- **Reproducibility for cloners.** A project's `.claude/settings.json` is checked in; cloning the repo gives the same skill activation as the original author had. Machine-wide install (`~/.claude/`) breaks this.
- **Multiple Vibeboss installs.** Operators may run more than one Vibeboss workspace (e.g. one per venture). Machine-wide skills would conflict across installs.
- **Shared machines.** A developer pairing on the operator's box shouldn't drag global skill state into their own work.
- **Clean uninstall.** Removing a Vibeboss workspace removes its skill activation. No `~/.gstack/`-style residue.

## What v0.2.1 ships

- **HQ baseline** — `templates/hq/.claude/settings.json` pre-enables `superpowers@claude-plugins-official` via `enabledPlugins` alongside the existing hooks block.
- **Per-project template** — every Boss-created project inherits a `.claude/settings.json` baseline with superpowers enabled and Vibeboss natives symlinked in. (Owned by Cluster A.)
- **`init.sh --add-project <name>`** — CLI baseline for scaffolding new projects with the bundle pre-wired. (Owned by Cluster A.)
- **Recommended companions docs** — README lists the opt-in pool with install commands; NOTICE acknowledges Jesse Vincent (superpowers, MIT) and Garry Tan (gstack, MIT).
- **STOP-file kill switch** — `hq/STOP` and `<workspace>/STOP` sentinels, boot-brief detection, recovery protocol documented in HQ `CLAUDE.md`. (Owned by Cluster C.)
- **Bidirectional inbox topology + disposition-footer convention.** (Owned by Cluster B.)

## What v0.3.0 will add

- **`vibeboss-natives@vibeboss` marketplace.** A `.claude-plugin/marketplace.json` so the natives resolve through the same plugin mechanism as superpowers, not via file-based symlinks. Uniform install model, clean update story, single command from anywhere.
- **`add-project` Boss skill.** Full SKILL.md for Boss with an interactive recommend-menu UX that walks the operator through opt-in picks, beyond the CLI baseline shipped here.
- **HQ refactor.** Drop file-based symlinks once the marketplace resolves, switch HQ's `.claude/settings.json` to enable `vibeboss-natives@vibeboss` alongside superpowers.

## Why marketplace eventually

The plugin-marketplace pattern is how Anthropic ships superpowers and how the broader Claude Code ecosystem is converging. Adopting it for Vibeboss natives gives operators a uniform mental model (`@vibeboss` and `@claude-plugins-official` work the same way), clean version upgrades (`/plugin update vibeboss-natives@vibeboss`), and one install command from anywhere — not just inside a Vibeboss workspace. File-based bundling in v0.2.1 is the bridge; marketplace in v0.3.0 is the destination.

## Consequences

- From v0.3.0 onward, plugin activation is uniform everywhere — HQ, every Boss-created project, every external project that opts in.
- Cloners of a Vibeboss workspace get superpowers immediately on first session start, with no manual install step.
- The opt-in path for the recommended pool is documented and one command per skill — operators are never blocked by "which skill should I add?"
- `gstack` stays explicitly external: not vendored, not in the Vibeboss marketplace, not auto-cloned. Install instructions live in README and the upstream README is the source of truth.
- The skill ecosystem Vibeboss depends on is now visible in `NOTICE`, with credit to upstream authors and MIT licenses preserved.

## Supersedes

Nothing. This is the first PPSB decision.
