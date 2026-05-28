# Handovers — {{PROJECT_NAME}}

Pre-compact handover files for the **{{PROJECT_NAME}}** project. Written by {{CREW_NAME}} BEFORE running `/compact` so the post-compact session resumes with full context.

**Format:** `YYYY-MM-DD-HHMM-<session-slug>.md`

Files are permanent audit records — do not delete them. If a compact-boot hook is wired into this project's `.claude/`, it auto-injects the most-recent file less than 60 minutes old; otherwise read the latest manually after `/compact`.

See `hq/skills/compact-handover/SKILL.md` (symlinked into this project's `.claude/skills/`) for the full ritual.
