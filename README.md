# Vibeboss

**The AI-as-Boss autonomous OS for vibe coders.**

Tell Vibeboss a goal. Walk away. Come back to it shipped.

> *Skip permissions, approve all, goodnight* — but without the drift, with memory of every mistake, and surfacing only when it genuinely needs you.

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

**Prerequisites:** [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code), Python 3 (for the boot hooks), Bash 3.2+ (macOS/Linux).

---

## Status

**Phase 0 — Feasibility Investigation.** Not yet open source. Not yet a usable product. The dashboard vision is being validated against Claude Code's actual surface capabilities before any architecture is locked.

## What this will be

A small set of conventions + a runtime that turns Claude Code into an autonomous agent system non-technical operators can actually trust:

- **State that survives every session** — STATE.md as canonical "where are we right now," runlog as append-only history, decisions as immutable choices
- **Bugs that get fixed, not patched** — reproduce → locate → fix → verify → log, with no "fixed!" claims without verification
- **Mistakes become guardrails** — every correction the operator gives turns into a LESSONS hard gate that fires at decision-time, not just a hint in memory
- **Don't-stop loops with a kill switch** — autonomous chain hops via async spawn; drop a STOP file to halt cleanly
- **Main / Builder / Research separation** — the agent that talks to you doesn't build; it delegates to a builder, and researches when it's unsure rather than asking you
- **Non-technical dashboard** *(if feasibility says yes)* — see all your sessions, jump into any one, watch from above

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

Copyright (c) 2026 Jin Kun Yong

## Author

Created by Jin Kun Yong. Distilled from patterns refined across years of running AI agents in production.
