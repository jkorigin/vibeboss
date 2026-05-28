# Vibe Chief calibration log (framework-level)

Append-only log of framework-development work done in `~/ventures/vibeboss/`. Grounds future time estimates for framework changes (template edits, hook changes, version ships, audits, migrations) in measured wall-clock.

Per LESSON-008 (in `templates/hq/lessons.md`, which both Boss and Vibe Chief honor): no bare numerical claims; cite source or tag as guess. This log is Vibe Chief's source for time-estimate citations on framework work.

Boss has a parallel log inside each workspace at `<workspace>/hq/calibration/log.jsonl` for runtime work. This source-level log is **only** for work done to the framework itself.

## When to log

Append an entry to `log.jsonl` at one of:
- **Session end** — one entry summarizing the framework-dev session's work.
- **Discrete-unit completion** — when a clearly-scoped framework change finishes mid-session (e.g. a version ship, a migration, a multi-cluster audit), log it immediately so the next estimate can use it.

Never edit past entries. Never delete past entries. If an entry is wrong, append a corrective entry referencing the original's `date` + `task` in the `notes` field.

## How to grep for prior estimates

Before quoting any time estimate for framework work, grep `log.jsonl` for entries with overlapping tags:

```bash
grep -E '"tags":\[[^]]*"templates"[^]]*"subagent-cluster"[^]]*\]' calibration/log.jsonl
```

Rules:
- If **≥3 matching entries** exist → report **median** + **range** + **sample size**. Median is computed on `wallclock_min` only.
- If **<3 matches** → label the number as `guess:` with italics. Example: *"guess: ~45 min (no calibration data yet for tasks tagged `migration` + `init-script`)"*.

## Schema

Each line is one JSON object. One entry per line, no trailing comma, no array wrapper.

| Field | Required | Type | Meaning |
|---|---|---|---|
| `date` | yes | ISO `YYYY-MM-DD` | When the work completed. |
| `task` | yes | short slug | Stable handle (e.g. `v0.2.0-audit-fix-pass`, `v0.2.2-update-mechanism`). |
| `scope` | yes | one-line string | What actually got done. |
| `tags` | yes | JSON array of strings | Coarse categories. Grep target. Examples: `subagent-cluster`, `templates`, `bash`, `skill-design`, `audit`, `ppsb`, `update-mechanism`, `docs`, `ci`, `tests`, `migration`, `init-script`, `hooks`. |
| `wallclock_min` | yes | integer | **Actual measured CC wall-clock for the work.** This is the only field that grounds future estimates. |
| `subagents` | no | integer | Count of parallel subagents used. |
| `files` | no | integer | Files touched. |
| `human_est_min` | no | integer | Best-guess of what an unassisted developer would take. **Explicitly an estimate, not a measurement.** Useful for tracking the leverage Vibe Chief + subagents provide. Never used as the basis for future-estimate calculations. |
| `notes` | no | free text | Anything worth recording: stages, surprises, blockers, references to prior entries. |

## Example entry

```json
{"date":"2026-05-27","task":"v0.2.0-audit-fix-pass","scope":"6 parallel clusters: README/ROADMAP/CONTRIBUTING rewrite, partner-data scrub, hook portability fix, boot script hardening, tests+CI, dev-workflow softening","subagents":6,"files":30,"tags":["subagent-cluster","docs","bash","tests","ci","audit"],"wallclock_min":25,"human_est_min":480,"notes":"3 stages: parallel clusters, integration (decision files + CHANGELOG), commit+push+CI"}
```

## Discipline rules (short form)

- Append only; never edit past entries.
- Log at session end OR when a discrete unit of work completes.
- For estimates: grep tags; if ≥3, report median + range + sample size; if <3, label as guess.
- Median is computed by `wallclock_min` only.
- `human_est_min` is always an estimate, never a measurement — keep that boundary in any output that cites it.
