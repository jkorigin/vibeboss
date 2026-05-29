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

## Research dispatch + pickup

Per LESSON-011 (dispatch tiers) and LESSON-012 (source-tier discipline) in `hq/lessons.md`. When {{CREW_NAME}} hits a decision-issue {{CREW_NAME}} cannot resolve in-context with confidence, dispatch — don't guess and don't block {{OPERATOR_ADDRESSED_AS}}.

### Dispatch (when stuck)

1. **Classify the unknown.** Single-source 15-min answer = T1 (in-context spike). Multi-angle, 30-min, needs in-session = T2 (sync `Agent`-tool parallel subagents). Big, methodology-needed, async-OK = T3 (file write to `hq/projects/labs/inbox/requests/YYYY-MM-DD-from-{{CREW_NAME}}-<topic>.md`).
2. **For T3, the request includes:** the question (one sentence), what's blocking on it (one sentence), and a deadline if any. The labs research lead reads the methodology in `labs/skills/research/SKILL.md` on pickup.
3. **Keep working with a workaround.** In code, mark with a comment `// [RESEARCH-PENDING: <topic>]`. Pick a plausible default that's easy to revert. Don't block the project on the research.

### Pickup (when finding lands in {{CREW_NAME}}'s inbox)

Findings have a frontmatter line: `Confidence: <HIGH|MEDIUM-HIGH|MEDIUM|LOW>` and `Risk: <LOW|MEDIUM|HIGH>`. Use this rubric to decide:

| Confidence | Risk | {{CREW_NAME}}'s action |
|---|---|---|
| HIGH | LOW | Auto-apply the recommendation. Write decision file with `Author: {{CREW_NAME}}, via research by <research-lead>` and `Status: auto-applied`. Move the request to processed/. |
| HIGH | HIGH | Surface to {{OPERATOR_ADDRESSED_AS}} with a one-paragraph summary + link to finding. Recommend apply. Wait for verbal accept. |
| MEDIUM (any tier) | any | Surface with summary + open questions. Don't apply yet. |
| LOW | any | Re-dispatch as a refined T3 request OR escalate verbally: *"I couldn't determine confidently — here's what we found, your call."* |

### Linking decision back to evidence (provenance)

When auto-applying or partner-approving a research-led decision, the decision file frontmatter includes:
- `Author: {{CREW_NAME}}, via research by <research-lead>`
- `Linked finding: labs/research/{{PROJECT_NAME}}/findings/<topic>.md`
- `Confidence: <from finding>` and `Risk: <from finding>`
- `Status: auto-applied <date>` or `pending-partner-review`
- `Verified by:` (filled when partner reviews later via the dashboard or directly)

This creates the full audit chain: decision → finding → tier-tagged evidence. Six months later anyone can trace a wrong decision back to its source quality.

See `labs/skills/research/SKILL.md` for the research lead's methodology + tier rubric.

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
