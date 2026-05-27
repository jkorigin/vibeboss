# Decision — Framework's first test + CI workflow

**Date:** 2026-05-27
**Layer:** Framework (Vibeboss canon)
**Author:** Vibe Chief
**Status:** active

## Context

Vibeboss ships `templates/hq/skills/dev-workflow/SKILL.md`, which prescribes — as a hard gate — ≥3 bug-fix rounds, a fresh-agent review, and ≥3 tightening rounds for any non-trivial implementation. LESSON-005 wires this into Boss's decision loop. **The framework itself had zero tests through v0.1.0 and the v0.2.0-cleanup pass.** Hypocritical: the canon preached discipline the framework couldn't meet.

The 2026-05-27 audit called this out as the most damning discipline-vs-reality gap. Tests and CI were listed under "Deferred" in CHANGELOG with no priority.

## Decision

**Ship a smoke test for `init.sh` + a GitHub Actions workflow that runs it on every push and PR.** This is the framework's first test. It exists primarily so the framework can live by the discipline it prescribes; secondarily, it catches regressions in the install path — which is the single most user-facing surface today.

Files:

- **`tests/init-smoke.sh`** — bash, executable. Runs `init.sh --noninteractive` against a temp workspace, verifies all required scaffolded files exist (including executable bits on hook scripts), validates the boot hook emits JSON with `additionalContext`, and greps for any unresolved `{{...}}` placeholder in installed `.md` files. Cleans up via `trap EXIT`.
- **`.github/workflows/ci.yml`** — minimal: ubuntu-latest, `actions/checkout@v4`, `python3 --version`, `bash tests/init-smoke.sh`. No matrix, no cache, no untrusted GitHub event inputs.
- **`tests/README.md`** — under 30 lines, explains how to run locally.

## Why this shape

1. **Smallest test that catches the most regressions.** The install path touches `init.sh`, every template file, both hooks, the substitute() function, and the workspace topology. A smoke test that runs `init.sh` end-to-end exercises all of it cheaply.
2. **Verifying `{{...}}` placeholders are all substituted** is the test that catches the most subtle template regressions — a missing `{{LEAD_NAME}}` substitution would otherwise ship to user clones and only surface when the user reads the file.
3. **CI on PRs gates merge.** When external contribution opens (Phase 2), every PR runs the smoke test. The framework's discipline is now enforced by CI, not just by canon.
4. **No matrix / no caching deliberately.** Minimal surface. We can add macOS-runner coverage later, but the smoke test is portable and runs identically on darwin + linux today (verified locally on darwin).

## Consequences

- v0.2.0 ships with a test. Future template / `init.sh` changes can't pass CI without keeping the smoke test green.
- Future tests can be added under `tests/` following the same pattern (executable bash, `set -euo pipefail`, trap-cleanup, collect failures, PASS/FAIL exit).
- `dev-workflow` skill's hard gates now have a concrete example to point to — the framework itself runs tests before shipping.

## Supersedes

Nothing — first test/CI decision. Future test-discipline decisions reference this one.
