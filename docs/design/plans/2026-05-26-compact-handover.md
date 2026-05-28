# Compact Handover — Implementation Plan

**Subsystem:** E
**Date:** 2026-05-26
**Agent:** Build agent (spawn from Boss session)

---

## Phase 0 — Research (complete)

Requirements fully specified in spawn brief. No additional research needed. Reviewed:
- `hq/.claude/settings.json` — existing hook structure (startup + resume matchers)
- `hq/.claude/hooks/boot.sh` — how JSON is emitted via BRIEF_CONTENT env var + Python
- `hq/skills/dev-workflow/SKILL.md` — execution discipline
- `hq/lessons.md` — LESSONS 001-005
- Subsystem D runlog — constraint: CLAUDE.md direct writes blocked by auto-mode classifier

Key decision: **separate `compact-boot.sh`** over extending `boot.sh`. See design spec for rationale.

---

## Phase 1 — Build

### Step 1: Skill
- [ ] Write `hq/skills/compact-handover/SKILL.md`
  - Triggers table (T1-T5)
  - Pre-compact ritual (4 ordered steps)
  - Handover file format (8 fields)
  - Post-compact pickup explanation
  - Staleness rule (60 min)
  - Discipline note

### Step 2: Hook script
- [ ] Write `hq/.claude/hooks/compact-boot.sh`
  - Call `boot.sh`, parse JSON, extract additionalContext
  - Find newest handover in `hq/handovers/` with mtime < 60 min
  - Compose combined context (boot brief + handover or gap warning)
  - Emit JSON via BRIEF_CONTENT env var + Python (same pattern as boot.sh)
  - chmod +x

### Step 3: Settings
- [ ] Update `hq/.claude/settings.json` — add `compact` matcher pointing to compact-boot.sh

### Step 4: Handover directory
- [ ] Create `hq/handovers/` directory
- [ ] Write `hq/handovers/README.md`

### Step 5: Framework docs
- [ ] Write spec: `vibeboss/docs/design/specs/2026-05-26-compact-handover-design.md`
- [ ] Write plan: `vibeboss/docs/design/plans/2026-05-26-compact-handover.md` (this file)

---

## Phase 2 — Test (simulation)

Since `/compact` cannot be triggered programmatically from a spawn session, simulate the round trip:

1. Write a sample handover at `hq/handovers/2026-05-26-1200-subsystem-E-sim.md` with realistic content
2. Run `compact-boot.sh` directly: `bash hq/.claude/hooks/compact-boot.sh`
3. Assert: output is valid JSON
4. Assert: `hookSpecificOutput.additionalContext` contains the boot brief banner
5. Assert: `hookSpecificOutput.additionalContext` contains the handover file content
6. Assert: `hookSpecificOutput.additionalContext` contains "POST-COMPACT HANDOVER INJECTED"
7. Touch the sample file with a timestamp > 60 min ago, re-run, assert "NO RECENT HANDOVER" appears

---

## Phase 3 — Bug-fix (≥3 rounds)

Fix any failures from simulation tests. At minimum: 3 rounds of re-run + fix.

---

## Phase 4 — Fresh-agent review

Dispatch fresh agent with: spec summary, compact-boot.sh full content, simulation test results.
Prompt template from `dev-workflow` skill.

---

## Phase 5 — Tighten (3 rounds)

- Round 1: Code clarity (identifiers, dead code, magic literals)
- Round 2: Test quality (edge cases in simulation)
- Round 3: Hardening (missing file graceful degradation, macOS stat compatibility, Python error handling)

---

## Phase 6 — Human gate

DEFERRED — spawn context (no partner interaction available in this spawn).
Document deferred items in return JSON `deferred` array.

---

## Ancillary outputs

- `hq/lessons.md` — LESSON-006
- `hq/STATE.md` — E → Recently closed; G promoted to Next-1
- `hq/runlog/2026-05-26-subsystem-E-compact-handover.md`
- `hq/inbox/requests/2026-05-26-claude-md-compact-patch.md`
