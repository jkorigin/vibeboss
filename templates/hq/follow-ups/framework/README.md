# Framework follow-ups — Boss → Vibe Chief channel

This directory is the **one and only channel** that crosses the runtime/framework boundary. Boss (HQ runtime) writes observations here when something at the **framework level** needs Vibe Chief's attention. Vibe Chief reads this directory on every boot of the framework-dev session (via `reno.sh`).

It is NOT for ad-hoc gripes, daily work notes, or per-project issues. It is for genuine framework-level observations that the framework caretaker should see.

## When Boss writes here

Write a file here when, during normal HQ operation, you (Boss) observe one of:

- **Template gap** — a scaffolded file is missing content, has a placeholder that never gets filled, or assumes structure that doesn't exist in a fresh install.
- **Hook bug** — a SessionStart / compact hook misfires, emits invalid JSON, fails silently on a portable shell, or produces an unexpected brief.
- **Lesson clarification need** — a `lessons.md` rule fires ambiguously or the operator overrides it repeatedly, suggesting the rule wording needs revision.
- **Discipline failure observed in practice** — runlog / decision / handover / inbox protocols proved insufficient under real load and need a structural change, not just a one-off correction.
- **Init-flow friction** — `init.sh` produced a confusing prompt, a broken default, or scaffolded something that immediately needed manual repair.
- **Migration debt** — a workspace at version X had a structural shape that the from→to migration didn't catch.

Do NOT write here for:

- Per-project bugs (those go in the project's own runlog / decisions).
- Operator preferences (those become lessons in `lessons.md`, not framework changes).
- Daily venture work (that's the runlog).
- One-off "I wish this were different" — only write here if you'd genuinely recommend a change to the canonical framework.

## Filename pattern

```
YYYY-MM-DD-<short-slug>.md
```

Examples: `2026-05-28-autoboot-passive.md`, `2026-05-30-crew-yml-schema-drift.md`, `2026-06-02-lesson-007-too-rigid.md`.

Short slug. Topic, not date. Kebab-case.

## Body format

Each file follows this shape:

```markdown
# <Short title — what's wrong, in 5–10 words>

**Date:** YYYY-MM-DD
**Observed by:** <Boss / build lead name>
**Severity:** blocking | annoying | nice-to-fix

## Problem

One paragraph. What's wrong at the framework level. Not "this happened to me" — "this is a structural gap / bug / friction point that affects every installation."

## Reproducer

Steps, or a concrete example, that lets Vibe Chief see the issue without needing the original context. Include file paths, command lines, observed output, expected output.

## Local workaround

If Boss patched around the issue locally to keep working, describe what was done and where. Vibe Chief needs to know what's been temporarily papered over so the canonical fix supersedes it cleanly.

## Suggested fix or framework change

Optional. Boss's recommendation for what the framework should do differently. Vibe Chief may take it, modify it, or reject it — but a concrete starting point accelerates the conversation. If unsure, say so.
```

## Lifecycle

1. Boss writes the file to `follow-ups/framework/<YYYY-MM-DD-slug>.md`.
2. Vibe Chief reads it on next `reno.sh` boot (the framework-dev SessionStart hook surfaces new items).
3. Vibe Chief either:
   - **Adopts** — lands a framework change (template edit, hook fix, lesson revision, decision file, CHANGELOG entry).
   - **Defers** — schedules for a future release; documents the deferral.
   - **Rejects** — explains why the observation doesn't warrant a framework change.
4. Vibe Chief appends a `## Disposition` footer to the file (the disposition-footer protocol from v0.2.1's inbox topology — see `hq/inbox/README.md` for the canonical format):

   ```markdown
   ## Disposition
   - **Verdict:** adopted | deferred | rejected
   - **Result:** path/to/artifact (decision file, template diff, CHANGELOG entry, etc.)
   - **Rationale:** <one sentence>
   - **Closed thread:** framework-followup-<slug>
   ```

5. Vibe Chief moves the file to `follow-ups/framework/processed/` once the disposition footer is in place.

## Channel discipline

- This is the ONLY cross-boundary channel. Don't multiply channels.
- Append-only at the artifact level — once Vibe Chief writes a disposition, the file is closed. If the issue recurs, write a NEW follow-up that cites the prior one.
- One observation per file. Don't bundle.
- Vibe Chief's runtime cwd is the source repo (this clone of vibeboss); Boss's runtime cwd is HQ. Both agents address each other through this directory and nowhere else.
