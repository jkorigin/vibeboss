# Handovers

Pre-compact handover files. Written by the lead BEFORE running `/compact` so the post-compact session resumes with full context.

**Format:** `YYYY-MM-DD-HHMM-<session-slug>.md`

Files are permanent audit records — do not delete them. The `compact-boot.sh` hook auto-injects the most-recent file less than 60 minutes old.

See `hq/skills/compact-handover/SKILL.md` for the full ritual.
