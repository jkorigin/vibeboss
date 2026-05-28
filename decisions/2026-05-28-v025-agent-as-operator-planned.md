# Decision — v0.2.5 architecture planned: Agent-as-operator

**Date:** 2026-05-28
**Layer:** Framework (Vibeboss canon)
**Author:** Vibe Chief
**Status:** **planned (queued for ship after v0.2.4 lands)**

## Context

Through v0.2.4, Vibeboss canon repeatedly assumes the operator runs scripts: `bash init.sh --update`, `bash init.sh --add-project <name>`, `/plugin install <name>@claude-plugins-official`, etc. README's user-facing sections show these commands directly. The update banner in `boot.sh` says *"Run `bash ...init.sh --update --workspace ...`"*. Vibe Chief's own response patterns (in this session) repeatedly told the operator to "run init.sh --update."

Partner caught it: *"users won't run scripts. you need to design the agents to handle all these things."* This is correct against Vibeboss's stated target (non-technical 40+ business operators) — the framework's whole premise is "tell the AI what you want and walk away." Showing commands to operators contradicts that premise on first contact.

The cargo-cult source is the same as the `--max-budget-usd 10` issue fixed in commit 28dab5a: Vibeboss canon was drafted with a developer-fluent operator implicitly in mind, even though the README's target-user block explicitly names the opposite.

## Decision

**Adopt the agent-as-operator pattern as canonical, codified in LESSON-009.**

- **Principle.** Boss runs scripts on partner's verbal request. Partner never types CLI commands except the one-time `bash init.sh` bootstrap (no agent exists yet). Documentation describes what *Boss* runs when partner speaks intent — never what partner types.

- **LESSON-009 — Agent-as-operator. Boss runs scripts; partner speaks intent.**
  - Rule: When Vibeboss canon documents a CLI command (`init.sh --update`, `init.sh --add-project`, `/plugin install`, etc.), Boss is the executor, not the operator. Partner expresses intent verbally; Boss confirms and runs the script via the Bash tool. Boss reports results, not commands.
  - Exception: the very first `bash init.sh` bootstrap — no agent exists yet, partner must run it once. Document this exception explicitly.
  - When to apply: any user-facing protocol involving a script. Verbal-form templates: *"Vibeboss update available — say 'apply it' and I'll run it"*, *"What's the project for? I'll scaffold it for you"*.

## v0.2.5 scope (queued)

Five clusters; parallelizable on a clean tree (post-v0.2.4):

| Cluster | Files | What changes |
|---|---|---|
| A | `templates/hq/lessons.md`, `templates/hq/CLAUDE.md`, `CHIEF.md` | LESSON-009 added. CLAUDE.md gains a "Partner-facing protocols" section: when partner says "update" / "new project" / "framework issue," Boss runs the corresponding script via Bash. CHIEF.md mirrors for Vibe Chief framework commands (`git pull`, `bash migrations/run.sh`, etc.). |
| B | `templates/hq/.claude/hooks/boot.sh` | Update-available banner rewritten from command-form (*"Run `bash …init.sh --update …`"*) to verbal-form (*"Say 'apply the update' and I'll run it"*). |
| C | `README.md` | "To *update* Vibeboss" section + "Recommended companions" install instructions rewritten as Boss-mediated flows. CLI commands moved to a "Reference: what Boss runs under the hood" appendix for the technically curious; operators don't need to see them. |
| D | `templates/projects/_per_project/README.md` | Same pattern at the project level — build leads run their own scripts on partner request. |
| E | Integration | `decisions/2026-05-28-agent-as-operator.md` (full decision; supersedes this planning file), CHANGELOG v0.2.5 entry, ROADMAP delta, VERSION bump to `0.2.5-dev`, smoke test extension to verify LESSON-009 present + no command-form banner in boot.sh. |

Calibration prior (per LESSON-008): tasks tagged `subagent-cluster + templates + docs` have n=3 in `vibeboss/calibration/log.jsonl`, median wall-clock 25 min, range 20-30 min. v0.2.5 is a similar shape.

## Why this is queued, not shipped now

Boss is mid-flight on v0.2.4 (rolling handover mechanism via Stop hook — `update-handover.sh`, modified `settings.json`, new decision file at `decisions/2026-05-28-rolling-handover-mechanism.md`, edits to the "Compact handover" section of `templates/hq/CLAUDE.md`). My v0.2.5 also edits `templates/hq/CLAUDE.md` (different sections). Sequencing avoids merge conflict.

After Boss commits + pushes v0.2.4, the working tree is clean and v0.2.5 ships in one pass.

## Consequences

- Until v0.2.5 ships, Boss continues to occasionally show partner commands instead of running them. Partner re-correcting Boss is the bridge state.
- After v0.2.5, **the README's user-facing copy stops being a CLI cheat-sheet** and starts being a conversation guide. This is a meaningful surface change; should be re-reviewed by partner before merge to make sure the new copy reads naturally.
- LESSON-009 will be the first lesson explicitly about *agent behavior toward operator*, not about *agent's internal discipline*. Worth noting for future LESSONS-naming consistency.

## Supersedes

Nothing yet. When v0.2.5 ships, replace this file with a real decision: `2026-05-28-agent-as-operator.md` documenting what was implemented (not just planned).
