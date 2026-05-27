# Vibeboss — Framework Reference

This is the OSS source for **Vibeboss**, an autonomous-AI operating system for vibe coders (non-technical 40+ business operators). This file documents the *patterns* Vibeboss publishes; it is the entry point for anyone cloning this repository.

If you are running a Vibeboss installation, your runtime memory lives in a separate workspace directory (not here). See [docs/superpowers/specs/2026-05-26-topology-hq-split-design.md](docs/superpowers/specs/2026-05-26-topology-hq-split-design.md) — short version: source goes here (this repo), all runtime state goes to a sibling `vibeboss-workspace/` directory you create on first init.

## What Vibeboss is

A toolkit of primitives that lets a non-technical operator give an autonomous-AI agent a goal and walk away, while the agent:
- Maintains structural memory of past decisions (no drift)
- Surfaces only when it genuinely needs the human
- Records its work for audit
- Refuses to drift past structural guardrails (LESSONS as hard-gates)

Inspired by patterns developed in the realm of `~/ventures/<other-project>/`-style multi-venture offices, packaged for external use.

## The two modes — Boss and Vibe Chief

Vibeboss separates "running the workspace" from "maintaining the framework." Two different agent identities, activated by where (and how) you start a Claude Code session.

| Mode | Identity | cwd | Activated by | Job |
|---|---|---|---|---|
| **HQ runtime** | **Boss** | `vibeboss-workspace/hq/` | `cd <workspace>/hq && claude` | Daily venture-lead work — talks to partner, dispatches build leads (Banana / Carrot / Ginger / etc. — illustrative; your install assigns names from the produce theme starting at `crew.yml`'s `next_available`), surfaces status. |
| **Framework dev** | **Vibe Chief** | `vibeboss/` (this repo) | `bash reno.sh` from this dir | Maintain the framework — OSS canon, templates, init script, CHANGELOG, decisions, breaking-change discipline. |

**If you accidentally `cd` to this repo and run `claude`,** the SessionStart hook here (`vibeboss/.claude/hooks/route.sh`) emits a polite redirect explaining the two paths. No identity is loaded until you pick one.

**Almost all daily work is HQ-mode (Boss).** Vibe Chief is only for the rare moment you're improving the framework itself.

See [`CHIEF.md`](CHIEF.md) for Vibe Chief's full boot brief and discipline.

## The published primitives

1. **HQ + per-project memory** — separation of cross-cutting memory (lessons, decisions, runlog) from per-project memory (`hq/projects/<name>/`). See [docs/superpowers/specs/2026-05-26-topology-hq-split-design.md](docs/superpowers/specs/2026-05-26-topology-hq-split-design.md).
2. **Runlog discipline** — every meaningful work session ends with an append-only runlog entry capturing goal, what-happened, commands, files-touched, state-at-end, next.
3. **Decisions discipline** — non-trivial choices land as immutable `YYYY-MM-DD-<slug>.md` decision files. Supersession via new files, never overwrite.
4. **LESSONS as hard-gates** — operator corrections become structural rules re-read at the top of every session. Violation gets logged; repeat violations indicate the rule wording needs revision.
5. **Crew system** — per-project named build leads (Banana, Carrot, Ginger, etc.) registered in `hq/crew.yml`. Boss dispatches. Inbox protocol (`hq/projects/<name>/inbox/`) for async work; spawn protocol (`claude --session-id`) for sync work. Naming theme: **produce** (vegetables / fruits / herbs).
6. **Auto-boot** — SessionStart hook in `hq/.claude/settings.json` fires on every fresh/resumed session; partner never types `boot`.
7. **Compact handover** — pre-`/compact` ritual writes a structured handover file; post-compact hook (`compact-boot.sh`) injects it as additional context. Session never closes.
8. **Inbox protocol** — operator drop-zone with `requests/`, `chats/`, `todos/`, `processed/` subfolders. On every boot the agent surfaces new items.
9. **Brand discipline** — internal docs may be technical; anything destined for the public release is non-business-internal and uses product-native vocabulary.
10. **Dev-workflow skill** — `hq/skills/dev-workflow/SKILL.md` codifies the standard build loop (research → build → test → ≥3 bug-fix → fresh-agent review → ≥3 tighten → human gate). Hard-gates on the round counts.
11. **Labs as continuous research function** — `vibeboss-workspace/labs/` mirrors project structure (`research/<example-project>/`, `research/master-dashboard/`, `research/hq/`). Research lead (Ginger) hands findings back to project build leads via their inboxes for adoption.

## Repository layout

```
vibeboss/                            ← OSS source. Apache 2.0. Framework only.
├── README.md                        ← public one-pager + Quick Start
├── LICENSE                          ← Apache 2.0
├── NOTICE                           ← attribution
├── CLAUDE.md                        ← this file
├── CHIEF.md                         ← Vibe Chief's boot brief (framework-dev mode)
├── CHANGELOG.md                     ← version history
├── AGENTS.md                        ← symlink to CLAUDE.md (Codex compatibility)
├── init.sh                          ← user-facing installer (creates vibeboss-workspace/)
├── reno.sh                          ← framework-dev entry — boots Vibe Chief
├── .claude/                         ← SessionStart routing hook for this dir
│   ├── settings.json
│   └── hooks/
│       ├── route.sh                 ← routes to Vibe Chief or redirect based on $VIBEBOSS_RENO
│       └── redirect.md              ← polite redirect for accidental cd's here
├── templates/                       ← scaffold trees init.sh writes to vibeboss-workspace/
│   ├── hq/
│   └── labs/
├── decisions/                       ← framework-level decisions (Vibe Chief writes here)
├── docs/
│   └── superpowers/
│       ├── specs/                   ← design specs for each primitive
│       └── plans/                   ← implementation plans
└── (framework code, Phase 1+)
```

## Phase

Vibeboss is in **Phase 0 — Feasibility Investigation**. The first 7-subsystem framework arc (A topology → B dev-workflow → C crew → D auto-boot → E compact handover → F labs → G init flow) has shipped, plus the master dashboard and Vibe Chief framework-dev mode. The framework is OSS-ready for the first cut.

Phase 1 begins when the framework gains actual runtime code (Main/Builder/Research agents as a runnable system, packaged dashboard scaffold, polished `vibeboss init` UX). Phase 2 is the public-repo cut.

## License

Apache License 2.0. Copyright jkorigin. `NOTICE` preserves attribution through forks. Commercial layers (paid dashboard, hosted service) are a Phase 2+ decision and not pre-committed.

## Contributing

Not yet open to external contribution. This boundary will move when Phase 2 lands the public repo. When it does, contributors use **Vibe Chief mode** (`bash reno.sh`) for their framework-dev work.

## Where to start

**If you cloned this repo to *use* Vibeboss** (you're a non-technical operator or a builder who wants the autonomous-AI office for your own ventures):

```bash
bash init.sh
```

That scaffolds `~/ventures/vibeboss-workspace/{hq,labs,projects}/`, lets you customize a few things (your name, lead's name, what the lead calls you), and points you to the next command. From then on, all your work happens in `vibeboss-workspace/hq/` — that's where Boss lives.

**If you cloned this repo to *enhance* Vibeboss itself** (fix a bug, ship a feature to the framework):

```bash
bash reno.sh
```

That boots Vibe Chief — the framework caretaker. Vibe Chief is OSS-careful, version-aware, and writes to `decisions/`, `CHANGELOG.md`, `templates/`, `docs/`.

Daily HQ work is Boss. Framework enhancement is Vibe Chief. Same partner, different discipline, different cwd.
