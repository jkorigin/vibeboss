# Decision — Rolling handover mechanism replaces self-discipline

**Date:** 2026-05-28
**Status:** Active
**Author:** Boss (live HQ session) — promoted to framework canon

## Context

The original compact-handover design (subsystem E, shipped 2026-05-26) required the agent to recognise context-pressure triggers (T1–T5) and write a handover file *before* running `/compact`. The post-compact hook (`compact-boot.sh`) would then inject that handover into the next session as `additionalContext`.

In practice, two failure modes appeared:

1. **The agent has no access to context-usage data.** Claude Code shows partner `960.2k / 1.0M (96%)` in the app UI; the agent never sees that number. So Trigger T1 (turn count) and partner's "compact soon" hint (T4) are the only signals — and both are unreliable.
2. **Auto-compact fires at 100% without warning.** When CC hits the ceiling, it compacts automatically. If no fresh handover exists, `compact-boot.sh` emits "no recent handover — discipline failure" and the new session boots blind.

Partner's framing (2026-05-28): "can we avoid self-discipline and make it automatically mechanism-style triggered?" Validated with a keyword test — pass a verbatim phrase, let auto-compact fire, see if the post-compact session can recall the phrase.

## Decision

Add a **`Stop` hook** (`hq/.claude/hooks/update-handover.sh`) that fires every time the assistant's turn ends. It writes/overwrites `hq/handovers/_current.md` with:

- Last partner message (verbatim, truncated to 2000 chars)
- Last agent response (truncated to 3000 chars)
- Lines from the session matching markers: `KEYWORD:` `REMEMBER:` `TODO:` `HANDOVER:` `PARTNER ASK:` `DON'T FORGET:` `IMPORTANT:`
- Timestamp + session id + a fixed "resume action" block

This means `_current.md` is at most one turn stale at the moment of compaction. The existing `compact-boot.sh` (which picks the newest handover < 60 min old) injects it automatically.

**The agent does nothing** to maintain this. The hook is invisible from the agent's perspective.

### Layered rich handovers preserved

The original rich-handover format (`hq/handovers/YYYY-MM-DD-HHMM-<slug>.md`) is preserved as an optional layer. When the agent wants to capture something the rolling format can't convey — milestone shipping, multi-day plan, critical decision — it writes a dated file. Because `compact-boot.sh` picks the newest file by mtime, the rich handover takes precedence over `_current.md` for the next 60 minutes, then the rolling baseline resumes.

## Why not PreCompact hook?

`PreCompact` would also work (fires right before compaction). We chose `Stop` for three reasons:

1. **Defends against forced/manual compact too** — partner running `/compact` mid-session, or CC's auto-compact, both go through PreCompact, but Stop also guards against context loss from `/clear`, `/resume`, or any other session boundary the hook list expands to in future.
2. **Cheap and frequent** — running on every Stop is bounded (one transcript parse, one file write, ~100ms). Frequent freshness is better than freshness-at-the-last-moment, because if PreCompact crashes the session is unrecoverable.
3. **Composable with optional rich layer** — agent-written rich handovers naturally override the rolling baseline because both write to the same directory.

## Implementation

Live workspace (already deployed):
- `hq/.claude/hooks/update-handover.sh` (executable)
- `hq/.claude/settings.json` — Stop hook registered under `"hooks": { "Stop": [...] }`

Framework templates (mirror for new installs):
- `templates/hq/.claude/hooks/update-handover.sh`
- `templates/hq/.claude/settings.json` — Stop hook entry using `${CLAUDE_PROJECT_DIR}` placeholder
- `templates/hq/CLAUDE.md` — "Compact handover" section rewritten to describe mechanism + layered rich-handover model, replacing the original self-discipline framing

## Validation

2026-05-28 12:10 — partner passed test keyword `cat climb clock tower dog run stairs eagle beats the eye`. Boss wrote it to `hq/handovers/2026-05-28-1210-keyword-test.md` (rich layer) and verified the Stop hook also auto-captured it via the marker grep. Either path alone is sufficient for survival.

Acceptance gate: at next auto-compact, post-compact session must surface the keyword without partner re-stating it. Outcome will be appended to this file.

## Supersedes

- `decisions/2026-05-26-...` (subsystem E original design) — extends, not replaces. The original handover format and `compact-boot.sh` injection remain. What changes is the *source of freshness* — mechanism-driven rather than discipline-driven.

## Open items

- Consider adding the same Stop hook to `templates/projects/_per_project/.claude/` so build-lead spawns (Banana, Carrot, Ginger, etc.) get the same rolling-handover guarantee. Deferred until first time a build lead loses context across a compact.
- If the marker-grep heuristic misses important content in practice, consider invoking `claude -p` from inside the Stop hook to produce an LLM-summarized rolling handover. Current heuristic is deliberately deterministic and zero-cost.

## Superseded 2026-05-28 (same day)

**Status now:** Superseded. The Stop-hook approach described above failed the keyword-test acceptance gate on the very same day it shipped. Three compounding failure modes were diagnosed in live testing:

1. `_current.md` overwritten every turn → keywords introduced mid-session get displaced by topic drift before compact fires.
2. `compact-boot.sh` picks newest file by mtime → the rich dated handover (where the keyword lived) lost to the just-touched rolling file.
3. Marker regex required `KEYWORD:` literal prefix → partner's natural phrasing slipped past.

Plus a structural issue: a Stop hook running in the *post*-compact session sees only post-compact transcript content. The pre-compact transcript (where the keyword turn lived) is gone.

See `decisions/2026-05-28-precompact-handover-mechanism.md` for the replacement design (PreCompact hook + pinned/rolling separation) and the verified-live keyword-test pass.
