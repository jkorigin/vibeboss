# Runlog — {{PROJECT_NAME}}

Append-only session history for the **{{PROJECT_NAME}}** project. One file per work session: `YYYY-MM-DD-<slug>.md`.

This runlog is project-scoped. Cross-cutting sessions (work spanning multiple projects) live in `hq/runlog/` instead.

**Format:**
```markdown
# YYYY-MM-DD — <slug>

## Goal
<What this session set out to accomplish for {{PROJECT_NAME}}>

## What happened
<Chronological notes — key decisions, commands run, findings>

## Commands / files touched
- `path/to/file` — what changed

## State at end
<What is true now that wasn't before this session>

## Next
<What to do in the next session, if anything>
```

Never edit past entries. If something needs correcting, note the correction in the next entry.
