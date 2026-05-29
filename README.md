# Vibeboss

**A conventions + hooks pack for Claude Code, with Codex-compatible instruction and hook surfaces, that gives non-technical operators a memory-disciplined workspace where sessions auto-boot with state, lessons, crew, and inbox context.**

What ships today: a scaffolder (`init.sh`), a templates tree, Claude Code `.claude/` hooks, Codex `.codex/` hook mirrors, `AGENTS.md` files for Codex, and a set of memory disciplines (runlog, STATE, decisions, LESSONS, inbox). What it does *not* yet ship: an autonomous runtime engine. That's Phase 1 — see [ROADMAP.md](ROADMAP.md).

> *Skip permissions, approve all, goodnight* — but without the drift, with memory of every mistake, and surfacing only when it genuinely needs you. **(That's the goal. Today's cut delivers the memory and discipline scaffolding; the don't-stop loop and verification tooling arrive in Phase 1.)**

## Quick Start

### To *use* Vibeboss (you're a builder/operator)

```bash
# 1. Clone this repo
git clone https://github.com/jkorigin/vibeboss ~/ventures/vibeboss

# 2. Run the init script — scaffolds your workspace in ~2 minutes
bash ~/ventures/vibeboss/init.sh

# 3. Start your first session with Claude Code
cd ~/ventures/vibeboss-workspace/hq && claude

# Or start/open Codex from that same hq directory
```

The init script asks 6 questions (with sensible defaults — just press Enter through). When Claude Code opens in `hq/`, your AI lead **Boss** auto-boots. When Codex opens in `hq/`, `AGENTS.md` supplies the same runtime instructions, and trusted `.codex/` hooks supply the same boot context.

After this first install, you never type a command again. You talk to Boss; Boss handles the rest. Need to update later? Just say so. Want a new project? Just say so.

### To *update* Vibeboss (existing install)

You don't run anything — Boss does. When Boss boots and sees the framework has moved ahead of your workspace, it surfaces a banner:

> *Vibeboss update available: v0.2.4 → v0.2.5. Say "apply it" or "update vibeboss" and I'll pull the latest framework and apply the changes to this workspace.*

Say yes (or "apply it", or "go ahead") and Boss handles the rest: pulls the latest framework source, applies the changes, prompts you only on files you've customized (keep / overwrite / view diff / skip). `--noninteractive` defaults to "keep" so a quick "go ahead" never overwrites your edits.

Breaking-change migrations run automatically in sequence between your installed version and the target.

If you'd rather skip the banner and just check: ask Boss *"is there a Vibeboss update?"* anytime — Boss checks `.vibeboss-version` against the source's current VERSION.

### To *enhance* Vibeboss (you're a contributor/maintainer)

```bash
# From inside the vibeboss/ source repo
bash reno.sh
```

That boots **Vibe Chief** — the framework caretaker. Vibe Chief is the agent who maintains the OSS canon: writes to `decisions/`, `CHANGELOG.md`, `templates/`, `docs/`. Different discipline from runtime Boss. Use this when you want to fix a bug in the framework, ship a new feature to the templates, or write a design spec.

If you accidentally `cd` to this repo and run `claude` without `reno.sh`, you'll get a polite redirect pointing you back to your HQ workspace.

For Codex-based framework work, open/run Codex from this source repo. The source `AGENTS.md` is a symlink to `CLAUDE.md`, and the tracked `.codex/` hook loads `CHIEF.md` as the Vibe Chief boot context when trusted.

**Prerequisites:** [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) for the full Claude-native spawn/session workflow, Python 3 (for the boot hooks), Bash 3.2+ (macOS/Linux). Codex can operate the same source/workspace files via `AGENTS.md` + `.codex/hooks.json`; Claude-specific features such as `claude -p`, `claude agents --json`, and Claude plugin activation remain Claude Code surfaces.

---

## Status

**Phase 0 — Feasibility Investigation.** v0.1.0 is the first OSS-ready cut. The framework is installable and functions as a memory/discipline harness today; the runtime engine arrives in Phase 1. See [ROADMAP.md](ROADMAP.md) for what's coming.

## What ships today

- **State that survives every session** — STATE.md as canonical "where are we right now," runlog as append-only history, decisions as immutable choices in `decisions/YYYY-MM-DD-<slug>.md`
- **Mistakes become guardrails** — every correction the operator gives turns into a LESSONS hard gate that fires at decision-time, not just a hint in memory
- **Inbox protocol** — operator drop-zone (`hq/projects/<name>/inbox/{requests,chats,todos,processed}/`) Boss scans on every boot and surfaces
- **Auto-boot + compact-handover hooks** — SessionStart hook injects boot brief on every fresh/resumed session; pre-`/compact` ritual writes a structured handover that the post-compact hook re-injects. Claude Code uses `.claude/`; Codex gets `.codex/` mirrors plus `AGENTS.md` fallback instructions. Session never closes; you never type `boot`.
- **Crew system** — per-project named build leads (Banana, Carrot, Ginger, etc.) registered in `hq/crew.yml`. Boss dispatches via inbox (async) or `claude --session-id` (sync). Naming theme: produce.

For what's planned but not yet built (autonomous loop, verification tooling, Main/Builder/Research separation, OSS dashboard scaffold), see [ROADMAP.md](ROADMAP.md).

## Recommended companions

Vibeboss is a memory + workflow harness; the heavy lifting comes from Claude Code skills.

> **None of these skills are Vibeboss's.** They're third-party plugins from the broader Claude Code ecosystem. Vibeboss recommends them, activates them via plugin manifests, and credits their authors in [NOTICE](NOTICE). We don't fork, vendor, or maintain them — we point you at the canonical upstream. Skill ownership stays with each upstream author.

**Always on (baseline):** every Vibeboss workspace ships with [**superpowers**](https://github.com/obra/superpowers) enabled — Jesse Vincent's MIT-licensed collection covering brainstorming, TDD, debugging, parallel-agent dispatch, plans, and code review. Distributed through [Anthropic's `claude-plugins-official` marketplace](https://github.com/anthropics/claude-plugins-official), so it activates automatically on first session. Vibeboss's `dev-workflow` skill explicitly invokes superpowers (`brainstorming`, `test-driven-development`, `systematic-debugging`, `requesting-code-review`) — without it, those steps degrade.

**Worth adding — curated to three.** All from Anthropic's `claude-plugins-official` marketplace (authored and maintained by Anthropic and contributors, not Vibeboss). Tell Boss what you're building and Boss enables the right ones for the project. You can also name them directly: *"Boss, enable context7 for this project."*

- **context7** — live library documentation lookup. Better than training-data recall for any current API. Useful in nearly every project.
- **playwright** — browser-based QA. Essential the moment your project touches a web UI.
- **skill-creator** — supports writing your own skills. Worth having once you start codifying your own patterns.

Everything else in the official marketplace — service integrations like `vercel`, `figma`, `sourcegraph`, and `Notion` — is opt-in per project. Add them when a project actually needs them; a Vercel-deployed Next.js app wants `vercel` and `frontend-design`, a CLI tool doesn't.

**External — reference, not a recommendation:**

- [**gstack**](https://github.com/garrytan/gstack) — Garry Tan's 40+ skill bundle (MIT-licensed). Comprehensive but heavy: installs machine-wide under `~/.claude/skills/gstack/`, requires Bun, writes to `~/.gstack/`. Worth a look if Vibeboss's curated set feels too thin. Tell Boss *"install gstack"* and Boss will walk you through the upstream install (it's a global install, not a Vibeboss flow).

Vibeboss never auto-clones, vendors, or forks any of these. Activation happens through Claude Code's plugin manifest (`enabledPlugins` in `.claude/settings.json`); the actual skill code lives in the marketplace or upstream repo, not in this repository.

## What this will NOT be

- A library you import — it's conventions + tooling, not code dependencies
- A replacement for Cursor / Cline / Aider — it's the **orchestration layer above them**
- An AI office framework for teams — that's a separate concern, deferred to Phase 3
- A vibe-coding tool for engineers — engineers can use it, but it's built for operators who'd rather describe intent than run commands

## Reference: under the hood (for the technically curious)

You don't need to know any of these — Boss handles them on verbal intent. But if you're curious what's actually running:

| Verbal intent | What Boss runs |
|---|---|
| *"Apply the update"* | `git -C <source> pull` then `bash <source>/init.sh --update --workspace <workspace> --noninteractive` |
| *"Start a new project called X"* | `bash <source>/init.sh --add-project X --workspace <workspace>` |
| *"Install context7 for this project"* | Adds `"context7@claude-plugins-official": true` to `<project>/.claude/settings.json` `enabledPlugins`; Claude Code activates on next session |
| *"There's a framework bug"* | Writes `hq/follow-ups/framework/YYYY-MM-DD-<slug>.md` describing the issue; Vibe Chief picks it up next `bash reno.sh` session |
| *"Halt everything"* (kill switch) | `touch <workspace>/STOP` or `touch <workspace>/hq/STOP`; Boss refuses new work until you remove the file AND re-authorize |

Boss runs each of these via the Bash tool on your verbal approval. You don't type any of it.

The first `bash init.sh` (bootstrap) is the one exception — no agent exists yet, so you run it once. After that, all CLI is Boss's domain.

## License

Apache License 2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).

Copyright (c) 2026 jkorigin

## Author

Created by jkorigin. Distilled from patterns refined across years of running AI agents in production.
