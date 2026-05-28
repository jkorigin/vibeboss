# {{PROJECT_NAME}}

**Build lead:** {{CREW_NAME}}
**Scaffolded:** {{DATE}}

---

## First-response discipline

**On the FIRST response of every new session in this project, output a brief showing the project's state (from `STATE.md`), any inbox items from {{LEAD_NAME}} (from `inbox/boss.md`), and what you're picking up. Even if the operator says "hi" — brief first. Per LESSON-007 in `hq/lessons.md`.**

---

## What this project is

*(TBD by partner — fill in once scope is defined. One paragraph: what does {{PROJECT_NAME}} do, for whom, and how does success look?)*

---

## Current state

See [`STATE.md`](STATE.md) — the canonical "where are we right now" for {{PROJECT_NAME}}.

---

## How to dispatch

{{CREW_NAME}} is the named build lead for {{PROJECT_NAME}}, registered in `hq/crew.yml`. {{CREW_NAME}} reads `inbox/requests/` on every boot.

To send {{CREW_NAME}} a task:

```
hq/projects/{{PROJECT_NAME}}/inbox/requests/YYYY-MM-DD-<slug>.md
```

See the dispatch format in `hq/CLAUDE.md` (Boss's boot brief). Boss owns dispatch; partner can also drop notes into `inbox/chats/`.

---

## Layout

```
{{PROJECT_NAME}}/
  README.md         ← this file
  STATE.md          ← project state (truth)
  crew.yml          ← per-project crew snippet (build lead only)
  .claude/          ← Claude Code per-project settings (plugins, hooks)
    skills/         ← symlinks to HQ-native skills (dev-workflow, compact-handover)
  runlog/           ← append-only session history
  decisions/        ← immutable decision files
  handovers/        ← pre-compact handover files
  inbox/            ← async dispatch (requests / chats / todos / processed)
```
