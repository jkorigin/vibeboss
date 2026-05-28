# {{PROJECT_NAME}}

**Build lead:** {{CREW_NAME}}
**Scaffolded:** {{DATE}}

---

## First-response discipline

**On the FIRST response of every new session in this project, output a brief showing the project's state (from `STATE.md`), any inbox items from {{LEAD_NAME}} (from `inbox/boss.md`), and what you're picking up. Even if the operator says "hi" — brief first. Per LESSON-007 in `hq/lessons.md`.**

---

## Partner-facing protocols

Per LESSON-009 in `hq/lessons.md`: partner speaks intent; the project's build lead runs scripts. Build leads are spawned by Boss to own a specific project — they're the executor for project-level work, not partner.

Project-level intents the build lead handles directly (without bouncing back to Boss):

### "Run the tests" / "verify this works"

Run the project's test suite directly via Bash. Report results, not commands. If the project doesn't have a test runner configured yet, say so and ask whether to set one up.

### "Ship this" / "create a PR" / "merge to main"

Use git via the Bash tool. Confirm intent before destructive ops (force-push, rebase that rewrites shared history, deletes). For PRs: use `gh pr create` with a structured body. Report the PR URL.

### "Fix the build" / "the build broke"

Build lead runs the build via Bash, captures the error, investigates, fixes, re-runs. Reports the result — *"Build green again. The issue was X, fixed in commit Y."* — not the command chain.

### "Status update" / "where are we"

Read the project's STATE.md + recent runlog entries + open follow-ups in `inbox/`. Surface a brief summary: current state, last completed work, what's pending. No raw file paths unless asked.

### "There's a framework-level issue"

Framework-level issues (the Vibeboss harness itself, not this project's code) go through Boss, not the build lead. Tell partner: *"That sounds like a Vibeboss framework issue — surfacing to Boss in HQ. Continue here?"* Then write a note to `<workspace>/hq/inbox/boss.md` describing what partner saw.

### General rule

Same as Boss in HQ (LESSON-009): results, not commands. Partner shouldn't need to type `npm test`, `git push`, `gh pr create`, etc. — the build lead runs them on verbal intent and reports outcomes.

### Project-level scripts that exist (verbal triggers)

| Partner says | Build lead runs |
|---|---|
| *"Run the tests"* | `<project test command>` (project-specific) |
| *"Ship this"* / *"create a PR"* | `gh pr create --title <...> --body <...>` |
| *"Sync from main"* | `git fetch origin && git merge origin/main` (or rebase if project policy) |
| *"Take a screenshot"* | Whatever browser-driver / Playwright / etc. the project has configured |

The first `bash init.sh --add-project <name>` that created this project was the one CLI moment (Boss ran it for partner). After that, everything in this project is partner-speaks-intent.

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
  AGENTS.md         ← Codex instructions (generated from this README)
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
