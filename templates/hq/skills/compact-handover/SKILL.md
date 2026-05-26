---
name: compact-handover
description: Write a structured handover file before /compact — ensures resumption continuity after context compaction. Invoke when ANY self-monitoring trigger fires.
---

# Compact Handover

The pre-compact ritual that makes `/compact` lossless from a resumption standpoint. When a session's context approaches its limit, the model-generated `/compact` summary drops specifics. This skill writes a structured handover file that captures in-flight state BEFORE `/compact` runs. On resume, the SessionStart hook injects it automatically as `additionalContext`.

## When to invoke

**Hard gate:** invoke when ANY of the following triggers fires — no exceptions.

| # | Trigger | Threshold |
|---|---|---|
| T1 | **Turn count** | >50 substantive turns (questions, answers, tool calls — not brief confirmations) |
| T2 | **Session age** | >4 hours since session start |
| T3 | **Tool result volume** | Last 10 tool results average >3KB each (context filling fast) |
| T4 | **Partner signal** | Partner says "you should compact", "compact soon", "context running low", or similar |
| T5 | **Self-perception** | You notice gaps: "I can't recall X from earlier" or feel uncertain about early-session details |

**When ANY trigger fires:** execute the pre-compact ritual below BEFORE running `/compact`. Do not compact first and write the handover after — the entire point is to capture state while you still have full context.

## Pre-compact ritual

Execute in this exact order:

1. **Write the handover file** at `hq/handovers/YYYY-MM-DD-HHMM-<session-slug>.md` (format below)
2. **Update STATE.md** if any in-progress items have changed status since last STATE update
3. **Flush the runlog** — if this session produced meaningful work not yet in the runlog, append a short entry now (one paragraph is fine; don't write a full entry if nothing significant happened)
4. **Run `/compact`**

Do not skip or reorder steps. Steps 2-3 are cheap insurance: if `/compact` fails or the session is interrupted mid-compact, the artifacts survive.

## Handover file format

**File path:** `hq/handovers/YYYY-MM-DD-HHMM-<session-slug>.md`

- `YYYY-MM-DD` — date of handover (today)
- `HHMM` — 24h local time when handover is written (e.g. `1430` for 2:30pm)
- `<session-slug>` — 2-3 words describing the dominant work this session (e.g. `subsystem-E-compact`)

---

```markdown
# Handover — YYYY-MM-DD-HHMM — <session-slug>

## Session metadata
- **Session ID:** <UUID from `claude agents --json`, or "unknown">
- **CWD:** <current working directory>
- **Session started:** <approximate time or "unknown">
- **Handover written:** <YYYY-MM-DD HH:MM>

## In-flight task
<!-- The literal task being worked on RIGHT NOW, before /compact -->
<One paragraph: what task, which files, what is pending vs done within this task.>

Key files:
- `path/to/file1` — <state: done / in-progress / pending>
- `path/to/file2` — <state: done / in-progress / pending>

Pending:
- [ ] <specific next action 1>
- [ ] <specific next action 2>

## What just happened (last 2-3 turns)
<!-- NOT a runlog — raw substance of the most recent exchanges, not a summary -->
<2-4 sentences on what the last 2-3 turns accomplished or decided. Be specific.>

## Critical context
<!-- What would be lost in a model summary? Partner's last concrete intent, active conventions, blockers -->
- <item 1>
- <item 2>

## Resume action
<!-- EXACT first thing to do when the post-compact session reads this -->
> <Imperative sentence. E.g. "Open hq/skills/compact-handover/SKILL.md and complete the Phase 5 tighten round — round 2 (test quality) is next.">

## Open spawns / parallel work
- <Agent name> — session <UUID> — <what they are doing>
- (none if no active spawns)

## Lessons not yet logged
<!-- Things learned this session that should go in lessons.md but have not been written yet -->
- <lesson — one sentence>
- (none)

## Open task list
<!-- From TaskList output if TaskCreate was used — anything not yet completed -->
- [ ] <task 1>
- (none)
```

---

## Post-compact pickup

After `/compact`, CC fires a `SessionStart` event with `matcher="compact"`. The `compact-boot.sh` hook runs automatically:

1. Calls `boot.sh` to emit the standard boot brief (phase, state, crew, inbox, next)
2. Finds the most-recently-modified handover file that is less than **60 minutes old**
3. Injects that file's content into `additionalContext`

The model sees both the boot brief and the handover. The **Resume action** field tells you exactly what to do first.

**If no recent handover is found** (file is >60 min old or directory is empty): the hook announces the gap. Re-read `STATE.md` and the most recent runlog to orient. This is a recoverable failure — costly but not catastrophic.

## Staleness rule

A handover file older than **60 minutes** will not be auto-injected. Why 60 minutes: `/compact` typically takes <5 seconds; if you wrote the handover and it is now >60 minutes old, something unusual happened (session crash, very long compact operation, manual resumption). In those cases the model cannot assume the handover reflects current state.

Old handover files are **permanent audit records** — do not delete them. They accumulate in `hq/handovers/`.

## Discipline note

Writing the handover before `/compact` is a hard gate, not a reminder. The temptation to skip it ("I'll remember enough from the summary") is exactly what this skill defeats. Model summaries are lossy by design — they collapse specifics into narrative. The handover doesn't.

If you ever catch yourself about to run `/compact` without a handover: stop. Write the handover. Then compact.
