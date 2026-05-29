# Decision — Denylist closes the shapeless-leak vector the feedback channel opens

**Date:** 2026-05-29
**Layer:** Framework (Vibeboss canon)
**Author:** Vibe Chief
**Status:** active
**Extends:** `2026-05-28-sensitivity-audit-mechanism.md` (the shape-based detector)

## Context

The v0.2.7 sensitivity audit detects **shapes** — phone/WhatsApp-ID digit runs, absolute user paths, emails, credential tokens. That was the right call for the leak classes it was built against, and its core constraint (never embed the literal tokens it catches) still holds.

But a later review against partner's question — *"means everytime from workspace side they update u any issues then u fix, u will leak those data in. how? can u audit one more last time"* — surfaced a leak **class** the shape detector is structurally blind to:

**Shapeless literals.** Another venture's project name, a crew name borrowed from a different operation, an internal codename. These have no detectable shape. They read like ordinary English prose. No regex distinguishes them from legitimate content.

This is not a hypothetical. The v0.2.3 **framework-feedback channel** is a one-way data flow *toward* source: Boss (runtime) files an issue from the live workspace; Vibe Chief (framework) reads it and ports the fix into canon. Every loop iteration is an opportunity for a runtime-specific literal to ride along into a tracked file. The audit-one-more-time pass confirmed it had already happened — a handful of shapeless terms sat in old commits that every prior shape-based and manual scrub had walked straight past.

## Decision

Add a **denylist** as a fourth element of the audit, complementing (not replacing) the shape detector.

### The denylist file — `<repo>/.vibeboss-denylist`

- One literal runtime-specific term per line. `#` comments and blank lines ignored.
- **Gitignored. Never committed.** It contains the very terms it protects against. Committing it would be the circular leak in its purest form.
- This is the deliberate, bounded **inversion** of the v0.2.7 "never embed literals" rule. The literals are permitted to exist in exactly one place — a file git is configured never to track. Everywhere else, the no-literals rule still governs.
- Sanctioned illustrative names are **excluded** by design: the produce-theme defaults (Banana / Carrot / Ginger / …) are meant to ship in templates and docs. The denylist is for runtime data that must *not* ship.

### Detector integration (`tools/audit/audit.sh`)

- Loads the denylist if present; builds a fixed-string pattern file (comments/blanks stripped).
- `flag_denylist()` reports hits under category `denylist-term` and **bypasses the allowlist** — a denylist term is definitionally a leak, so there is no false-positive escape hatch for it.
- Matched case-insensitively as a fixed string (`grep -niFf`) in both file-content modes (`--tree` / `--staged`) and the `--history` full-log dump.
- The audit's own files and the denylist itself are skipped (they legitimately discuss / contain the patterns).

### Enforcement posture — local gate, not CI gate

- **Local:** the operator's machine has `.vibeboss-denylist`, so the pre-commit hook and any local `--tree` / `--history` run get full denylist coverage. This is the layer that matters for a single-operator source repo.
- **CI:** checks out the repo *without* the gitignored file, so CI does shape-detection only. This is correct, not a gap — CI must never see the literals either. The denylist is the operator's belt-and-suspenders at the point where runtime data could enter; CI remains the unbypassable wall for everything shape-detectable.

## History remediation (this pass)

The new denylist surfaced residual shapeless terms in old commits. Scrubbed from full history via `git filter-repo --replace-text` + force-push, in the same pass:

- a residual **illustrative crew name** that collided with a real runtime agent (design docs) — realigned to the canonical produce-theme default;
- a **capitalized project-name form** that survived an earlier lowercase-only scrub (one plan step);
- a **real-name fragment** embedded inside a placeholder example (audit README).

Per the standing circular-leak discipline, this file records the scrubbed items **by category only** — never the literal values. (The values live solely in the gitignored denylist.)

## Why this is mechanism, not discipline

The v0.2.4 → v0.2.6 lesson — *mechanism beats discipline* — applied to the audit itself. Before this, keeping a borrowed project name out of a canon doc relied on the operator *remembering* not to paste it. Now the gate catches it at commit time. The feedback channel stays a structural asset (it's why the framework self-corrects); the denylist is the dedicated countermeasure for the one thing that channel could carry that the shape detector can't see.

## Limits / known caveats

- **Only as complete as the list.** A runtime term not yet added to `.vibeboss-denylist` won't be caught. The operator appends terms as new ventures/codenames appear. This is acceptable: the denylist targets *known* runtime vocabulary, the shape detector targets *structured* data, and the two are complementary.
- **Local-only by design** — a fresh clone on another machine has no denylist until the operator creates one. For the OSS consumer this is moot (they have their *own* runtime vocabulary to protect, not the maintainer's).
- **Fixed-string, case-insensitive** — no word-boundary logic, so a denylist term that is a substring of a legitimate word would over-flag. Keep terms specific enough to avoid this (the current list is).

## Consequences

- v0.3.2 ships the denylist layer + the history remediation. Both `--tree` and `--history` audits return clean after this pass.
- `tools/audit/README.md` documents the denylist, its discipline (append locally, never name in tracked files), and its place in the Limits section as the shapeless-word mitigation.
- The framework-feedback channel is now safe to keep running indefinitely — its one residual leak class has a dedicated gate.

## Supersedes

Nothing. Extends `2026-05-28-sensitivity-audit-mechanism.md` with a complementary token-based layer for the leak class the shape-based detector cannot see.
