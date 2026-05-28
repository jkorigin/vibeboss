# Decision — Soften dev-workflow's "≥3 rounds" hard gates for small changes

**Date:** 2026-05-27
**Layer:** Framework (Vibeboss canon)
**Author:** Vibe Chief
**Status:** active

## Context

`templates/hq/skills/dev-workflow/SKILL.md` previously specified:

> Phase 3 (bug-fix): Hard gate: run exactly 3 rounds regardless of when failures resolve.
> Phase 5 (tighten): Hard gate: complete all 3 discrete rounds even if Round 1 already feels clean.

For sizeable changes — multi-file refactors, new features, non-trivial bug fixes — three rounds is sensible. Round 2 catches Round-1 regressions; Round 3 confirms cleanly. Round 1 clarity → Round 2 test quality → Round 3 hardening covers complementary surfaces.

For **small** changes — a one-function fix, a typo of behavior, a single edge-case addition — three rounds is ceremony. The audit on 2026-05-27 flagged this as a direct contradiction of LESSON-002 ("default to build, not improve-the-office"): mandatory busywork for the sake of process is exactly the energy LESSON-002 warns against.

## Decision

**Three rounds remains the default. Allow explicit skip for <50 LOC changes when the preceding round revealed nothing, with the skip logged in the runlog.**

New phase-3 language:

> **Default: 3 rounds.** Skip subsequent rounds only when all of: (a) the change touches <50 LOC, (b) the most recent round revealed no failures and no regressions, (c) you record the skip in the runlog with a one-line rationale.

New phase-5 language:

> **Default: 3 discrete rounds.** Skip subsequent rounds only when all of: (a) the change touches <50 LOC, (b) the preceding round revealed nothing to tighten in the next category, (c) you record the skip in the runlog with a one-line rationale.

Phase-table cells updated to read `≥ 3 rounds (default; carve-out for <50 LOC)`.

The "When to invoke" hard gate at the top of the skill is **unchanged**. The decision about *whether* to run dev-workflow at all remains binary and rigid: if the trigger condition fires, you invoke. What's softened is only how many rounds you owe inside the workflow.

## Why this shape

1. **Three-part conjunction (LOC + clean preceding round + logged rationale) is the right shape for an exemption.** Any single condition would be too loose; all three together preserve the spirit.
2. **Logging the skip in the runlog is the audit trail.** If a pattern of skips correlates with later bugs, that's surfaced. If skips correlate with no bugs, the threshold (50 LOC) can be revised.
3. **<50 LOC is the threshold because it's roughly the size below which a fresh-agent review and one bug-fix pass usually catches everything.** Above that, complementary surfaces (clarity / test quality / hardening) typically have distinct issues worth iterating on.
4. **References LESSON-002 in the skill body** so the why is self-documenting. Future contributors reading the carve-out know it isn't ad-hoc.

## Consequences

- Small fixes no longer carry forced three-round ceremony. The framework's own canon now matches its LESSONS.
- Runlog gets occasional one-line "skipped Phase 3 rounds 2-3 because <40 LOC and round 1 clean" entries. These accumulate as data on whether the carve-out is being abused.
- If skips correlate with regressions, the decision can be revised: raise the LOC threshold, narrow the carve-out, or remove it entirely. The runlog is the input.
- The phase-3 / phase-5 round-count cells in the phase table now read `≥ 3 rounds (default; carve-out for <50 LOC)` — more accurate than the previous "≥ 3 rounds minimum."

## Supersedes

Nothing direct — this is the first time the round-count gates have been revised. The original SKILL.md authoring (in `docs/design/specs/2026-05-26-dev-workflow-skill-design.md`) remains the rationale for *why* three rounds is the default.
