# Decision — Agent-as-operator: Boss runs scripts, partner speaks intent

**Date:** 2026-05-28
**Layer:** Framework (Vibeboss canon)
**Author:** Vibe Chief
**Status:** active
**Supersedes:** `2026-05-28-v025-agent-as-operator-planned.md` (planning file; this is the shipped version)

## Context

Through v0.2.4, Vibeboss canon repeatedly assumed the operator runs scripts: `bash init.sh --update`, `bash init.sh --add-project <name>`, `/plugin install <name>@claude-plugins-official`, `git clone … && ./setup` for gstack, etc. The README's user-facing sections showed these commands directly. The update banner in `boot.sh` instructed *"Run `bash init.sh --update --workspace …`"*. My own conversational responses (Vibe Chief) repeatedly told partner *"you can run `init.sh --update`"*.

Partner caught it: *"users won't run scripts. you need to design the agents to handle all these things."*

This is correct against Vibeboss's stated target: non-technical 40+ business operators. The README's *Target user* block explicitly names *"don't want to learn Git, terminal, or technical configuration."* Showing commands to operators contradicts that premise on first contact.

Source of the leak: same cargo-cult pattern as the `--max-budget-usd 10` issue fixed in the v0.2.5 $10-cleanup — canon was drafted with a developer-fluent operator implicitly in mind, even though the target-user block says the opposite.

## Decision

**Adopt the agent-as-operator pattern as canonical, codified in LESSON-009.**

**Principle:** Boss runs scripts on partner's verbal request. Partner never types CLI commands except the one-time `bash init.sh` bootstrap (no agent exists yet at that moment). Documentation describes what *Boss* runs when partner speaks intent — never what partner types.

**LESSON-009** lands in `templates/hq/lessons.md`:

> **Rule:** When Vibeboss canon documents a CLI command (`init.sh --update`, `init.sh --add-project <name>`, `/plugin install <name>`, `git pull`, migration scripts, etc.), Boss is the executor — not partner. Partner expresses intent verbally; Boss confirms (briefly), runs the script via the Bash tool, and reports results — not commands.
>
> **Exception:** the very first `bash init.sh` bootstrap. No agent exists yet, so partner must run it once. After that, every script is Boss's job.

## What shipped

**Discipline + protocols (Cluster A):**
- LESSON-009 in `templates/hq/lessons.md` (matching LESSON-001..LESSON-008 format).
- New `## Partner-facing protocols` section in `templates/hq/CLAUDE.md` with five canonical mappings: "Apply the update", "Start a new project", "There's a framework bug", "Show me what's in the inbox", and a general rule (*"results, not commands"*).
- New `## Partner-facing protocols (Vibe Chief)` section in `CHIEF.md` with framework-side mappings: "Pull the latest", "Apply this to the workspace", "Address the framework feedback", "Ship this".
- New CHIEF.md discipline bullet 8: *"Run scripts on partner's verbal request. Per LESSON-009."*

**Verbal update banner (Cluster B):**
- `templates/hq/.claude/hooks/boot.sh` update-available banner rewritten from command-form (*"Run `bash …init.sh --update …`"*) to verbal-form (*"Say 'apply it' or 'update vibeboss' and I'll pull the latest framework and apply the changes"*). Banner points at the new CLAUDE.md Partner-facing protocols section for the executor reference.

**Public surface (Cluster C):**
- README's *To update Vibeboss* section rewritten as the conversational flow (Boss surfaces banner; partner says yes; Boss runs everything). Quick Start bootstrap block preserved (the unavoidable first-time CLI moment) but followed by a one-line note: *"After this first install, you never type a command again."*
- README's *Recommended companions* section rewritten: partner expresses intent (*"Boss, enable context7 for this project"*) rather than typing `/plugin install`. The gstack reference points partner at an "install gstack" verbal request rather than the upstream `git clone … && ./setup`.
- New appendix `## Reference: under the hood (for the technically curious)` with a table mapping verbal intent → command Boss runs. Operator can ignore; technical readers get the underlying.

**Project-level mirror (Cluster D):**
- `templates/projects/_per_project/README.md` gained a `## Partner-facing protocols` section: build-lead canonical mappings for "Run the tests", "Ship this", "Fix the build", "Status update", "Framework-level issue", plus a verbal-triggers table.

**Tests + integration:**
- `tests/init-smoke.sh` extended to verify LESSON-009 + Partner-facing protocols section presence + verbal-form banner (regression-guards against command-form banner returning).
- `VERSION` → `0.2.5-dev`.

## Why this shape

1. **Discipline + UX in the same shift.** LESSON-009 alone wouldn't change behavior — the README, the banner, the protocols all need to align so the operator's first contact (and every subsequent one) is conversational. Five clusters of edits because five surfaces leak the old assumption.

2. **The protocols section is the operational handle.** A LESSON tells Boss *what* to do; the Partner-facing protocols section tells Boss *exactly how* — which command corresponds to which verbal intent, what confirmation to ask, what to report back. Without the protocols, LESSON-009 is aspirational; with them, Boss has a script.

3. **Preserve the bootstrap CLI honestly.** The one moment partner does type a command (`bash init.sh` on first clone) gets documented explicitly as the exception — both in LESSON-009 and in the README Quick Start. Pretending no commands exist would be misleading; naming the one unavoidable moment is honest.

4. **Reference appendix for the technically curious.** Some operators *want* to see what's running. The appendix table satisfies that without polluting the main user flow with commands.

5. **Project-level mirror.** Build leads (Banana, Carrot, etc.) face the same operator that Boss does. Identical principle applies. The per-project README's Partner-facing protocols section uses the same shape but adapted to project-level scripts (tests, builds, PRs).

## Limits / known caveats

- **Adherence depends on model behavior.** LESSON-009 + Partner-facing protocols are imperative-language contracts. If Boss drifts back to showing commands instead of running them, partner has to catch it (as they did this turn) and the rule gets sharpened.
- **The protocols section is finite.** Five canonical mappings cover the most common intents but won't cover everything. Boss has to generalize ("when in doubt, results not commands"). Future LESSONS may sharpen the heuristic.
- **The bootstrap CLI is still real friction.** The one `bash init.sh` step requires partner to open a terminal once. Phase 2's *vibeboss reno* shell alias might let us reduce this to a single short word (`vb install` or similar), but won't eliminate it entirely — somewhere a process has to be the first thing started.
- **No automatic protocol enforcement.** If partner types a command directly (*"I'll just run init.sh --update myself"*), nothing prevents that. The framework accommodates technically-fluent operators who *want* to run commands; LESSON-009 just says Boss shouldn't ASSUME partner will.

## Consequences

- v0.2.5 ships the architectural shift that fixes the second of the two weird traits partner flagged (the first — Boss quoting "$10 per spawn" — was fixed in the v0.2.5 $10-cleanup).
- The README's user-facing copy stops being a CLI cheat-sheet and starts being a conversation guide. Material surface change; partner should re-read it once the commit lands to make sure it reads naturally to a non-technical audience.
- Future canon work follows LESSON-009 by default: when a new script ships (e.g. a future v0.3.0 `add-skill` command), the README documents the verbal intent + adds a Partner-facing-protocols entry; the script itself is for Boss's Bash tool.
- The Boss → Vibe Chief feedback channel shipped in v0.2.3 (`hq/follow-ups/framework/`) now has a use case: if Boss drifts back to showing commands, partner reports it via the feedback channel, Vibe Chief sharpens the protocols.

## Supersedes

- `decisions/2026-05-28-v025-agent-as-operator-planned.md` — the planning file written when v0.2.5 was queued behind v0.2.4. This decision documents what was actually shipped; the planning file is now redundant and should be removed in the same commit.
