# Sensitivity audit (`tools/audit/`)

A shape-based detector for personal / sensitive data in the Vibeboss source repo. Runs in three modes:

| Mode | Invocation | Use case |
|---|---|---|
| Tree | `bash tools/audit/audit.sh` | Default. Scans all tracked files in the working tree. |
| Staged | `bash tools/audit/audit.sh --staged` | Scans only files staged for commit. Used by the `pre-commit` git hook. |
| History | `bash tools/audit/audit.sh --history` | Slower forensic check across the whole git history. One-off use. |

## What gets flagged

The audit detects *shapes*, not specific data — the audit file itself must never list the literal tokens it's catching (same circular-leak failure that motivated this script).

| Category | Pattern |
|---|---|
| `phone-or-id` | `[0-9]{10,15}@(c.us\|lid\|s.whatsapp.net\|g.us)` — WhatsApp / LID ID shape |
| `phone-shaped-digits` | bare runs of 10-15 digits (post-filtered to skip run IDs / version numbers / ports) |
| `abs-user-path` | `/Users/<name>/` or `/home/<name>/` absolute paths (leaks the username) |
| `other-venture-path` | `~/ventures/X/` where X is not `vibeboss`/`vibeboss-workspace`/a placeholder |
| `email` | any `user@host.tld` pattern not allowlisted |
| `credential` | API-key shapes: Anthropic (`sk-ant-…`), OpenAI (`sk-…`), GitHub (`ghp_…`, `gho_…`, `github_pat_…`), AWS (`AKIA…`), Slack (`xoxb-…`, `xoxp-…`), Bearer tokens |
| `credential-assignment` | `password=`, `api_key=`, `secret=`, `token=` followed by a quoted value |

## Allowlist

False-positives go in `tools/audit/allowlist.txt` — one regex per line. The list intentionally allowlists *patterns* (e.g., `@test\.local`, `\{\{[A-Z_]+\}\}`), not literal sensitive data.

## Denylist (the shapeless-leak catch)

The shape-based detector has a known blind spot (see Limits): a bare runtime-specific word — another venture's project name, a crew name borrowed from a different operation, an internal codename — has **no detectable shape**. It reads like ordinary prose. Yet it's exactly the kind of literal that leaks toward source through the framework-feedback channel (runtime data flows source-ward every loop iteration when Boss files an issue that Vibe Chief then fixes).

The denylist closes that vector:

- Lives at `<repo>/.vibeboss-denylist`, **gitignored** — it contains the very terms it protects against, so it must never be committed. This is the deliberate inversion of the "never embed literals" rule below: the literals are allowed to exist *only* in a file git will never track.
- One literal term per line; `#` comments and blank lines ignored. Sanctioned illustrative names (the produce-theme defaults like Banana / Carrot / Ginger) are explicitly **excluded** — they're meant to ship.
- A denylist hit **bypasses the allowlist** — a denylist term is definitionally a leak, no false-positive escape hatch.
- Matched case-insensitively as a fixed string (`grep -niFf`) in both `--tree`/`--staged` (file content) and `--history` (full log dump).
- **Local-only gate.** The file is present on the operator's machine (where the pre-commit hook that matters runs) and absent in CI (CI checks out the repo without the gitignored file). CI therefore does shape-detection only; the denylist is the operator's local belt-and-suspenders.

To add a term: append it to `.vibeboss-denylist` locally. Never reference the literal in any tracked file (commit message, CHANGELOG, decision) — describe the *category* ("a residual crew name", "another venture's codename"), never the value. That's the same circular-leak discipline as everything else here.

## How this gets enforced

Three layers:

1. **Pre-commit hook** — `.git/hooks/pre-commit` (installed by `tools/install-hooks.sh`) runs `audit.sh --staged` before each commit lands. Hits block the commit.
2. **CI gate** — `.github/workflows/ci.yml` runs `tests/audit-smoke.sh` which calls `audit.sh --tree`. Any new commit that introduces a finding fails CI.
3. **One-off forensic checks** — `audit.sh --history` for periodic sweeps across the full git log (e.g., after a major refactor or before a public flip).

## Why shape-based, not token-based

The deleted decision file `2026-05-26-partner-data-audit.md` listed the literal sensitive identifiers in an audit-trail table. Documenting "we scrubbed X" by quoting X re-introduced the leak. v0.2.7 (this mechanism) avoids that by detecting structural shapes instead.

If a new category of sensitive data appears (e.g., a new social-media handle format, a new credential pattern), add a *regex* to `audit.sh`, not the literal value. The audit's source code itself never embeds real personal data.

## Limits

- **False positives are real.** A legitimate use of a 10-digit number (e.g., a Unix timestamp in test data) may flag. Add an allowlist entry.
- **Doesn't catch novel patterns.** The audit knows the shapes it was taught. A truly creative leak (e.g., a real name embedded inside a placeholder) wouldn't trigger. Stay vigilant on PRs.
- **Shapeless bare words** (another venture's project name, a borrowed crew name, an internal codename) have no detectable shape and slip past every regex above. The **denylist** (see above) is the dedicated mitigation — a local gitignored literal list checked alongside the shape detector.
- **History mode is slow** — runs through the entire `git log -p` output. Use sparingly.
- **No commit-message scanning by default.** The current detector reads file content; commit messages are handled separately by the `--history` mode. Tighten if needed.

## Calibration

LESSON-008 self-citation: this audit script was implemented in v0.2.7 (see CHANGELOG). Catches the kinds of leaks v0.2.6's manual scrub had to clean up post-hoc.
