# Pinned handovers — survive every compact

Files in this directory are injected by `compact-boot.sh` BEFORE the rolling `_current.md` snapshot, on every post-compact session reboot.

Use this for content that must not be displaced by topic drift across multiple compacts: keywords, test phrases, hard decisions, identity reminders, "don't forget X" items, instructions-to-say-verbatim.

Filename convention: `YYYY-MM-DD-HHMM-<slug>.md` (sorted by filename → oldest first).

The agent or partner writes these explicitly. There is no automatic mechanism to populate this directory — that's the point. Pinned means "I decided this must survive."

To retire a pinned handover, move it out of this directory (e.g. into `hq/handovers/archive/` or just delete it). The rolling `_current.md` is overwritten at every compact by the PreCompact hook and never lives here.

## Why this exists (failure mode it closes)

The original Stop-hook design (v0.2.4, superseded same day — see `decisions/2026-05-28-rolling-handover-mechanism.md`) overwrote a single rolling handover file every turn. By the time auto-compact fired at 100% context, the file reflected the most recent turn — which is rarely the most important content. Keywords introduced mid-session got erased.

The pinned/rolling split (v0.2.6 — see `decisions/2026-05-28-precompact-handover-mechanism.md`) closes this: pinned content is immune to mtime displacement; rolling content captures the snapshot at the compact boundary. `compact-boot.sh` injects pinned-first so the model reads critical content before topic-of-the-moment.
