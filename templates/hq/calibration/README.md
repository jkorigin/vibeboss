# HQ calibration log

Append-only log of completed work. Grounds future time estimates in measured wall-clock instead of vibes.

Per LESSON-008 in `hq/lessons.md`: no bare numerical claims; cite source or tag as guess. This log is the source for time-estimate citations.

## When to log

Append an entry to `log.jsonl` at one of:
- **Session end** — one entry summarizing the session's work.
- **Discrete-unit completion** — when a clearly-scoped task finishes mid-session (e.g. a multi-cluster ship, a migration, a feature land), log it immediately so the next estimate can use it.

Never edit past entries. Never delete past entries. If an entry is wrong, append a corrective entry referencing the original's `date` + `task` in the `notes` field.

## How to grep for prior estimates

Before quoting any time estimate, grep `log.jsonl` for entries with overlapping tags. Example:

```bash
grep -E '"tags":\[[^]]*"templates"[^]]*"bash"[^]]*\]' hq/calibration/log.jsonl
```

Rules:
- If **≥3 matching entries** exist → report **median** + **range** + **sample size**. Median is computed on `wallclock_min` only (most stable signal).
- If **<3 matches** → label the number as `guess:` with italics. Example: *"guess: ~30 min (no calibration data yet for tasks tagged `shell` + `migration`)"*.

## Schema

Each line is one JSON object. One entry per line, no trailing comma, no array wrapper.

| Field | Required | Type | Meaning |
|---|---|---|---|
| `date` | yes | ISO `YYYY-MM-DD` | When the work completed. |
| `task` | yes | short slug | Stable handle (e.g. `v0.2.0-audit-fix-pass`). |
| `scope` | yes | one-line string | What actually got done. |
| `tags` | yes | JSON array of strings | Coarse categories. Grep target. Examples: `subagent-cluster`, `templates`, `bash`, `skill-design`, `audit`, `ppsb`, `update-mechanism`, `docs`, `ci`, `tests`, `migration`. |
| `wallclock_min` | yes | integer | **Actual measured CC wall-clock for the work.** This is the only field that grounds future estimates. |
| `subagents` | no | integer | Count of parallel subagents used (if applicable). |
| `files` | no | integer | Files touched. |
| `human_est_min` | no | integer | Operator/agent's **gut estimate** of what an unassisted developer would take. **Explicitly an estimate, not a measurement.** Useful for showing the leverage CC provides; never used as the basis for future-estimate calculations. |
| `notes` | no | free text | Anything else worth recording: stages, surprises, blockers, references to prior entries. |

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
