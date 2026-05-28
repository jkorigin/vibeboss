# Crew System Design

**Subsystem:** C of A→G
**Date:** 2026-05-26
**Status:** Implemented (fresh-agent review applied)

---

## Summary

The crew system gives every partner-owned project a *named build lead* — a persistent identity that owns work on that project across sessions. This document specifies the schema, naming theme, dispatch mechanisms, inbox topology, and boot-time presentation.

---

## Problem

Once a Vibeboss workspace has multiple active projects (illustrative: two partner-owned projects plus labs), spawned sessions multiply and Boss has no structured way to:

1. Know which agent is currently "owning" a project.
2. Route a task to the right identity.
3. Surface who is alive (session ID) vs. dormant (no active session).

Without a registry and naming convention, Boss defaults to ad-hoc spawn descriptions that are opaque in the master dashboard activity stream.

---

## Design decisions

### Naming theme: Vegetables

**Chosen:** vegetables.
**Rationale:** Short (≤10 chars), memorable, easy to pronounce aloud, infinite supply (~400+ named vegetables), neutral (no cultural baggage of cartoon characters, no brand risk of food brands), and thematically amusing in the "AI is the boss" brand.

**Canonical mapping rule:** `next_available` in `crew.yml` is the authoritative next name. When a new agent is born, Boss assigns the `next_available` name, then updates `next_available` to the next unused vegetable name in alphabetical order. **Do not derive next_available by scanning agents[].** This avoids ambiguity when pre-reserved names appear out-of-order.

Example assignments (illustrative — your install's `crew.yml` will differ):

| Agent | Project | Role | Status |
|---|---|---|---|
| Banana | `<project-name>` | build lead | born |
| Carrot | master-dashboard | build lead | born |
| Ginger | labs | build lead | pre-reserved (unborn) |
| Dill | (next project) | TBD | next_available |

---

## Schema

### `crew.yml` (runtime, in `hq/`)

Illustrative example — your install's `crew.yml` ships with empty `agents: []` and a fresh `next_available`:

```yaml
operator:
  name: <partner legal name>
  role: Founder / original author / product direction
  contact: <email>

venture_lead:
  name: Boss
  role: Vibeboss venture lead
  reports_to: operator
  addresses_operator_as: partner

naming_convention:
  theme: vegetables
  rationale: "..."
  rule: >
    When a new agent is born, assign the name in next_available.
    After assigning, update next_available to the next unused vegetable (alphabetical).
    next_available is the single authoritative source.
  next_available: Dill

agents:
  - name: Banana
    project: <project-name>
    role: build lead
    born_at: "YYYY-MM-DD"
    current_session_id: null

  - name: Carrot
    project: master-dashboard
    role: build lead
    born_at: "YYYY-MM-DD"
    current_session_id: null

  - name: Ginger
    project: labs
    role: build lead
    born_at: null
    current_session_id: null
```

**Fields:**

| Field | Type | Meaning |
|---|---|---|
| `name` | string | Vegetable name — stable identity across sessions |
| `project` | string | Matches `hq/projects/<name>/` directory |
| `role` | string | `build lead` for project owners; `research lead` for research-only agents |
| `born_at` | date string or null | Date Boss first-spawned this agent. Boss sets this field at first spawn. null = pre-reserved, never yet spawned |
| `current_session_id` | UUID string or null | Live session ID from `claude agents --json`; null = dormant |

**Note:** `born_at` is set by Boss, not by the agent itself. First spawn = Boss updates `born_at` + `current_session_id` before or immediately after the `claude -p` call.

---

## Named agent boot sequence

Each project has a `hq/projects/<name>/CLAUDE.md` that defines the named agent's boot protocol. These files are created as part of Subsystem C and serve the same role that `hq/CLAUDE.md` serves for Boss. Key elements:

1. Read project `STATE.md`
2. Check `inbox/requests/` and `inbox/todos/`
3. Read project `lessons.md` (if exists)
4. Read `hq/lessons.md` (cross-cutting lessons — always apply)

Output a project-scoped boot brief, then act on any inbox items.

---

## Dispatch mechanisms

Two mechanisms. Boss chooses based on whether the work is synchronous (partner watching) or async (background work).

### Inbox dispatch (async / queued)

Boss writes a task markdown file to the project's inbox:

```
hq/projects/<name>/inbox/requests/YYYY-MM-DD-<slug>.md
```

Format:
```markdown
# <Task title>

**To:** <Agent name> (<project>)
**From:** Boss
**Priority:** high | normal | low
**Date:** YYYY-MM-DD

## Task

<One paragraph. What to do. Success criterion on the last line.>

## Context

<Optional: links to STATE, runlog entries, decision files that inform this work.>

## Result

<!-- Named agent fills this in after completion, before moving to processed/ -->
```

Named agent reads it at boot. Once the task is **complete** (not at pickup), the agent adds a `## Result` section and moves the entire file to:
```
inbox/processed/YYYY-MM-DD-<slug>/
```
(a subdirectory, so it can include supplemental artefacts alongside the original).

### Spawn dispatch (synchronous / headless)

Boss launches the agent directly via `claude -p`:

```bash
PATH="<node path>:$PATH" claude -p "<task prompt>" \
  --model sonnet \
  --output-format stream-json \
  > /tmp/<AgentName>-<date>.out 2>&1 &
echo "PID: $!"
```

> The `--max-budget-usd <N>` flag is intentionally **omitted** from the default example. It's a real Claude Code flag (caps API spend) but only meaningful for users on API-tier billing. For Claude subscription users (Pro/Max), the flag is inert at best and misleading at worst (Boss should not quote a per-spawn dollar cost to a subscription operator). Add it only when the operator confirms API billing.

After spawning, Boss waits ~2 seconds, then runs:
```bash
claude agents --json | jq '.[] | select(.cwd | test("projects/<name>")) | .sessionId' | head -1
```

If the project has a unique cwd, this reliably identifies the correct session. If multiple agents are running in the same cwd, select by most recent `startTime`. Boss then writes `current_session_id` to `crew.yml`. Clears it (sets to null) when the spawn exits.

If `claude agents --json` returns no matching entry after 5 seconds, the spawn likely failed — check `/tmp/<AgentName>-<date>.out` for error output before retrying.

**Ceremony for first spawn (born_at):** Before first-spawning an agent whose `born_at` is null, Boss sets `born_at` to today's date in `crew.yml`. This is the operational definition of "birth."

---

## Boss dispatch boundary

Boss routes work to named agents and never writes application code directly. **Exception:** if a named agent produces broken code and the project is in an unrecoverable state (spawn fails, agent produces a syntax error blocking startup, or similar emergency), Boss may make a targeted patch of ≤5 lines, log it in the runlog with the `EMERGENCY_PATCH` tag, and dispatch a follow-up request to the named agent to review and own the fix properly.

---

## Inbox topology

```
hq/
  inbox/                          ← Boss-level (cross-project)
    requests/                     ← flat files: YYYY-MM-DD-<slug>.md
    chats/
    todos/
    processed/                    ← flat files (HQ convention — items moved here as files)

  projects/
    <name>/
      CLAUDE.md                   ← named agent boot instructions
      inbox/                      ← Project-level (per named agent)
        requests/                 ← flat files: YYYY-MM-DD-<slug>.md
        chats/
        todos/
        processed/                ← subdirectory per item: YYYY-MM-DD-<slug>/
```

**Note:** The project-level `processed/` uses subdirectories (one per completed item) to allow attaching artefacts. The HQ-level `processed/` is flat (files only). This is an intentional difference, not a symmetry gap.

---

## Boot-time crew presentation

The boot brief adds an **Active crew** section after "Active projects" (illustrative example):

```
Active crew:
  Banana (<project-name>) — dormant
  Carrot   (master-dashboard) — dormant
  [Ginger  (labs) — unborn]
```

Status logic:
- `born_at: null` → `unborn` (pre-reserved, shown in brackets)
- `current_session_id: null` → `dormant` (born, no active session)
- `current_session_id: <uuid>` → `active — session <uuid>`

---

## DoD

- [x] `crew.yml` updated with `naming_convention:` + `agents:` section (Banana, Carrot, Ginger)
- [x] `crew.yml.template` in framework source reflects the schema with placeholders
- [x] `hq/projects/<example-project>/inbox/{requests,chats,todos,processed}/` exist with READMEs
- [x] `hq/projects/master-dashboard/inbox/{requests,chats,todos,processed}/` exist with READMEs
- [x] `hq/projects/<example-project>/CLAUDE.md` created (Banana boot protocol)
- [x] `hq/projects/master-dashboard/CLAUDE.md` created (Carrot boot protocol)
- [x] `hq/CLAUDE.md` has a "Crew" section explaining the dispatch mechanisms
- [x] `hq/CLAUDE.md` boot sequence updated to include crew load step
- [x] `crew.yml` parses cleanly under Ruby's YAML parser
- [x] Fresh-agent review applied (12 findings, all addressed or explicitly deferred)
- [x] Runlog + STATE.md updated

## Deferred (non-blocking)

- **Ginger / labs birth ceremony** — Ginger is pre-reserved but labs hasn't been formally authorized as a project yet. When labs is authorized, Boss sets `born_at` and spawns. No action needed now.
- **`hq/inbox/processed/` subdirectory alignment** — the HQ-level processed/ is currently flat. This is acceptable for Boss-level items (simpler). Could be standardized in a future cleanup. Deferred.
