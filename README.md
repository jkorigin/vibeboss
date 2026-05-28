# Vibeboss

**A conventions + hooks pack for Claude Code that gives non-technical operators a memory-disciplined workspace where sessions auto-boot with state, lessons, crew, and inbox context.**

What ships today: a scaffolder (`init.sh`), a templates tree, SessionStart hooks, and a set of memory disciplines (runlog, STATE, decisions, LESSONS, inbox). What it does *not* yet ship: an autonomous runtime engine. That's Phase 1 — see [ROADMAP.md](ROADMAP.md).

> *Skip permissions, approve all, goodnight* — but without the drift, with memory of every mistake, and surfacing only when it genuinely needs you. **(That's the goal. Today's cut delivers the memory and discipline scaffolding; the don't-stop loop and verification tooling arrive in Phase 1.)**

## Quick Start

### To *use* Vibeboss (you're a builder/operator)

```bash
# 1. Clone this repo
git clone https://github.com/jkorigin/vibeboss ~/ventures/vibeboss

# 2. Run the init script — scaffolds your workspace in ~2 minutes
bash ~/ventures/vibeboss/init.sh

# 3. Start your first session
cd ~/ventures/vibeboss-workspace/hq && claude
```

The init script asks 6 questions (with sensible defaults — just press Enter through). When Claude Code opens in `hq/`, your AI lead **Boss** auto-boots with a briefing and asks what you want to build.

### To *enhance* Vibeboss (you're a contributor/maintainer)

```bash
# From inside the vibeboss/ source repo
bash reno.sh
```

That boots **Vibe Chief** — the framework caretaker. Vibe Chief is the agent who maintains the OSS canon: writes to `decisions/`, `CHANGELOG.md`, `templates/`, `docs/`. Different discipline from runtime Boss. Use this when you want to fix a bug in the framework, ship a new feature to the templates, or write a design spec.

If you accidentally `cd` to this repo and run `claude` without `reno.sh`, you'll get a polite redirect pointing you back to your HQ workspace.

**Prerequisites:** [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code), Python 3 (for the boot hooks), Bash 3.2+ (macOS/Linux). Tested with recent Claude Code releases (2026-Q1+).

---

## Status

**Phase 0 — Feasibility Investigation.** v0.1.0 is the first OSS-ready cut. The framework is installable and functions as a memory/discipline harness today; the runtime engine arrives in Phase 1. See [ROADMAP.md](ROADMAP.md) for what's coming.

## What ships today

- **State that survives every session** — STATE.md as canonical "where are we right now," runlog as append-only history, decisions as immutable choices in `decisions/YYYY-MM-DD-<slug>.md`
- **Mistakes become guardrails** — every correction the operator gives turns into a LESSONS hard gate that fires at decision-time, not just a hint in memory
- **Inbox protocol** — operator drop-zone (`hq/projects/<name>/inbox/{requests,chats,todos,processed}/`) Boss scans on every boot and surfaces
- **Auto-boot + compact-handover hooks** — SessionStart hook injects boot brief on every fresh/resumed session; pre-`/compact` ritual writes a structured handover that the post-compact hook re-injects. Session never closes; partner never types `boot`.
- **Crew system** — per-project named build leads (Banana, Carrot, Ginger, etc.) registered in `hq/crew.yml`. Boss dispatches via inbox (async) or `claude --session-id` (sync). Naming theme: produce.

For what's planned but not yet built (autonomous loop, verification tooling, Main/Builder/Research separation, OSS dashboard scaffold), see [ROADMAP.md](ROADMAP.md).

## Recommended companions

Vibeboss is a memory + workflow harness; the heavy lifting comes from Claude Code skills.

**Always on (baseline):** every Vibeboss workspace and every Boss-created project ships with **superpowers** enabled — Jesse Vincent's MIT-licensed collection covering brainstorming, TDD, debugging, parallel-agent dispatch, plans, and code review. Part of Anthropic's official Claude Code marketplace, so it activates automatically on first session. Vibeboss's `dev-workflow` skill explicitly invokes superpowers (`brainstorming`, `test-driven-development`, `systematic-debugging`, `requesting-code-review`) — without it, those steps degrade.

**Worth adding — curated to three.** Install per project with `/plugin install <name>@claude-plugins-official` inside a Claude Code session, or pre-enable in the project's `.claude/settings.json`:

- **context7** — live library documentation lookup. Better than training-data recall for any current API. Useful in nearly every project.
- **playwright** — browser-based QA. Essential the moment your project touches a web UI.
- **skill-creator** — supports writing your own skills (the "custom" class of the PPSB architecture). Worth having once you start codifying your own patterns.

**Deliberately not recommended** (in case you wonder why):

- `code-review` / `pr-review-toolkit` — superpowers already includes `requesting-code-review`.
- `commit-commands` — Claude Code handles git fine without a specialized skill.
- `hookify` — for *authoring* Claude Code hooks. Vibeboss ships its hooks; users don't write them.
- `claude-md-management` — risks conflict with Vibeboss's own CLAUDE.md templates.
- `feature-dev` — duplicates Vibeboss's `dev-workflow` skill.
- `frontend-design`, `figma`, `vercel`, `firebase`, `sourcegraph`, `Notion`, other service-specific integrations — install when the project actually needs them. A Vercel-deployed Next.js project should add `vercel` and `frontend-design`; a CLI tool shouldn't.

**External — reference, not a recommendation:**

- **gstack** ([garrytan/gstack](https://github.com/garrytan/gstack)) — Garry Tan's 40+ skill bundle. Comprehensive but heavy: installs machine-wide under `~/.claude/skills/gstack/`, requires Bun, writes to `~/.gstack/`. Worth a look if Vibeboss's curated set feels too thin. Install per upstream README.

Vibeboss never auto-clones any of these.

## What this will NOT be

- A library you import — it's conventions + tooling, not code dependencies
- A replacement for Cursor / Cline / Aider — it's the **orchestration layer above them**
- An AI office framework for teams — that's a separate concern, deferred to Phase 3
- A vibe-coding tool for engineers — engineers can use it, but the target is non-technical operators

## Target user

40+ business operators — founders, CEOs, consultants — who:
- Have ideas and can describe them in plain language
- Don't want to learn Git, terminal, or technical configuration
- Want AI to handle the work without 50 confirmation prompts
- Need to trust that the AI won't drift, forget, or quietly break things

## License

Apache License 2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).

Copyright (c) 2026 jkorigin

## Author

Created by jkorigin. Distilled from patterns refined across years of running AI agents in production.
