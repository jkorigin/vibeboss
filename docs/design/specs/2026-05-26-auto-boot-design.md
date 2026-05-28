# Spec: Vibeboss Auto-Boot (Subsystem D)

**Date:** 2026-05-26  
**Status:** implemented  
**Author:** Boss (Build agent, Subsystem D session)

---

## Problem

Vibe coders won't type `boot` manually. Every new CC session starts cold — no phase,
no state summary, no inbox awareness. Partner must type `boot` explicitly to get context.

## Solution

Use the Claude Code `SessionStart` hook to inject a pre-rendered boot brief as
`additionalContext` before the first LLM turn. The hook fires on session start and
resume; the agent sees the brief as part of its first context window.

## Technical approach

**Hook trigger:** `settings.json` declares a `SessionStart` hook at project scope
(`hq/.claude/settings.json`). Two matchers: `startup` (fresh session) and `resume`
(resumed session). `compact` is deferred to Subsystem E.

**Hook command:** `hq/.claude/hooks/boot.sh` — a plain bash script, no external deps
beyond standard Unix tools + python3 (for JSON encoding).

**Output format:** The script emits JSON to stdout:
```json
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<boot brief text>"
  }
}
```

CC wraps this into the session context. The agent sees `additionalContext` as
additional context at the start of the conversation.

**Boot brief format** (mirrors `hq/CLAUDE.md` boot section):
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  VIBEBOSS HQ — online
  {date}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

- **Phase:** {from STATE.md}
- **State:** {one-liner from STATE.md ## Current state}
- **Last session:** {most-recent runlog slug}
- **Inbox:** {grouped by subfolder, or "empty"}
- **Active projects:** {from projects/ + their STATE.md headlines}
- **Crew on duty:** {from crew.yml agents[]}
- **Open questions:** {from STATE.md ## Open questions, first 5 bullets}
- **Next (top 3):** {from STATE.md ## Next, first 3 numbered items}

Ready. What are we working on?
```
("Inbox has N item(s) — start there?" if inbox non-empty.)

## Extraction strategy (STATE.md parsing)

| Field | Method |
|---|---|
| Phase | `grep -m1 '^\*\*Phase:\*\*'` |
| State one-liner | First non-empty line after `## Current state`, truncated to 160 chars |
| Last session | `ls runlog/ \| sort -r \| head -1`, strip `.md` |
| Open questions | Lines matching `^- ` in `## Open questions` section, first 5 |
| Next | Lines matching `^[0-9]+\.` in `## Next` section, first 3 |

## Edge cases

- Missing `STATE.md` → each field falls back to "unavailable" or "none"
- Empty `runlog/` → "none"
- Missing `crew.yml` → Crew section shows "none"
- Missing `projects/` subdirs → Active projects shows "none"
- Empty inbox subdirs → "empty"

## Constraints

- Scope: project-level only (`hq/.claude/settings.json`, NOT `~/.claude/settings.json`)
- No network calls, no `claude` invocations from within the hook (would recurse)
- Runtime: < 2s on the local filesystem
- Spawn-safe: `claude -p` spawns at hq/ also receive the boot brief (treated as extra context)

## Files

| File | Action |
|---|---|
| `hq/.claude/settings.json` | Create — declares SessionStart hook |
| `hq/.claude/hooks/boot.sh` | Create — emits boot brief as JSON |
| `hq/CLAUDE.md` | Modify — note that boot is now automatic |
| `hq/STATE.md` | Modify — D → Recently closed; E promoted to Next-1 |
| `hq/runlog/2026-05-26-subsystem-D-auto-boot.md` | Create |
