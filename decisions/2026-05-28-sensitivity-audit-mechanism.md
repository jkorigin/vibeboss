# Decision — Sensitivity audit as a permanent push-gating mechanism

**Date:** 2026-05-28
**Layer:** Framework (Vibeboss canon)
**Author:** Vibe Chief
**Status:** active

## Context

Pre-v0.2.7, Vibeboss canon relied on **discipline + ad-hoc audits** to keep personal / sensitive data out of source. That pattern failed repeatedly:

- v0.2.0 audit-fix pass scrubbed Round 1
- v0.2.0 Round 2 scrubbed identifiers missed in Round 1
- v0.2.7 (the immediate predecessor of this decision) discovered ~10 additional categories of leaks across HEAD + git history — real name, real phone, real WhatsApp IDs, cross-venture project names, absolute user paths — that survived all prior rounds because the **audit files themselves embedded the data they claimed to have redacted** (circular self-documentation leak).

After the v0.2.7 comprehensive scrub + git-filter-repo history rewrite, partner instructed: *"this needs to be part of the mechanism for every push when we update the source code. ie besides test all ik, need audit check any sensitive info n so on."*

The lesson: discipline-based gates fail. Mechanism-based gates work. Same shape as the v0.2.4 → v0.2.6 compact-handover lesson, applied to sensitivity.

## Decision

Adopt a **three-layer sensitivity-audit mechanism**, mirroring how testing was wired in v0.2.0:

### Layer 1 — Detector (`tools/audit/audit.sh`)

Shape-based grep scanner. Detects categories:

- **`phone-or-id`** — `[0-9]{10,15}@(c.us|lid|s.whatsapp.net|g.us)` shape
- **`phone-shaped-digits`** — bare 10-15 digit runs (post-filtered to skip CI/version/port-like contexts)
- **`abs-user-path`** — `/Users/<name>/` or `/home/<name>/` absolute paths (leaks usernames)
- **`other-venture-path`** — `~/ventures/<dir>/` where `<dir>` is not `vibeboss`/`vibeboss-workspace`/a placeholder
- **`email`** — any email address not matched by the allowlist
- **`credential`** — API-key shapes: Anthropic (`sk-ant-…`), OpenAI (`sk-…`), GitHub (`ghp_…`, `gho_…`, `github_pat_…`), AWS (`AKIA…`), Slack (`xoxb-/xoxp-…`), Bearer tokens
- **`credential-assignment`** — `password=`, `api_key=`, `secret=`, `token=` followed by a quoted value

**Critical design constraint:** the detector script and its allowlist must **never embed the literal sensitive tokens they catch**. That was the v0.2.6 circular-leak failure mode. We detect *structures* (regex), not specific instances.

Three modes:
- `--tree` (default): scan all tracked files in working tree. Used by CI.
- `--staged`: scan only what's staged for commit. Used by pre-commit hook.
- `--history`: forensic scan across `git log -p`. One-off use, slow.

### Layer 2 — Pre-commit hook (`tools/hooks/pre-commit`, installed via `tools/install-hooks.sh`)

Runs `audit.sh --staged` before each commit. Findings block the commit. Bypass with `--no-verify` is possible but actively discouraged (the commit message in the bypass attempt is the audit log of someone choosing to override).

Install with: `bash tools/install-hooks.sh` (idempotent; partner runs once after cloning). Verify with `bash tools/install-hooks.sh --check`.

### Layer 3 — CI gate (`.github/workflows/ci.yml` → `tests/audit-smoke.sh`)

`tests/audit-smoke.sh` is the CI wrapper around `audit.sh --tree`. Added as a parallel job to the existing `init-smoke` job. Any push that introduces sensitive shapes fails CI before it can be merged.

The CI gate is the load-bearing layer — the pre-commit hook is a convenience, but CI is the wall the bad data hits if the hook is bypassed or never installed.

## Why shape-based, not token-based

The motivating failure was that audit files (the deleted `2026-05-26-partner-data-audit.md`) listed the literal sensitive identifiers in a table describing what was scrubbed. Documenting "we cleaned X" by quoting X re-introduced the leak.

The fix: detect *shapes*. The audit script knows what a phone-shaped digit run looks like, what an absolute user path looks like, what an API-key looks like — without ever embedding a real phone, a real user, or a real key. The allowlist (`tools/audit/allowlist.txt`) only contains *patterns* (e.g. `@test\.local`, `\{\{[A-Z_]+\}\}`), never literal sensitive data.

## What this catches that prior audits missed

The v0.2.7 scrub had to clean up by hand. With this mechanism in place, equivalent introductions would be caught at commit-time:

- Real partner phone in a discipline-rule example → `phone-shaped-digits` flag
- Real WhatsApp ID anywhere → `phone-or-id` flag
- `/Users/<name>/...` absolute path in a code example → `abs-user-path` flag
- `~/ventures/<other>/` reference → `other-venture-path` flag
- Real email (`<placeholder>@example.com`) → `email` flag (not in allowlist)
- An accidentally committed API key → `credential` flag

## Limits / known caveats

- **False positives happen.** A legitimate use of a 10-digit number (e.g., a Unix timestamp in test data) may flag. Fix: add a *pattern* to the allowlist that captures the legitimate context, not the literal value.
- **The audit is regex-driven.** A truly creative leak (e.g., a real name embedded inside a placeholder syntax that doesn't match any pattern) wouldn't trigger. The mechanism is good against the common failure modes, not against deliberate adversarial concealment.
- **Pre-commit hook can be bypassed** with `git commit --no-verify`. Documented but discouraged. CI is the unbypassable layer.
- **History-mode scans are slow** (~minutes on a repo with deep history). Not used in CI; only for manual forensic checks.
- **Commit messages aren't scanned in tree/staged mode.** A leak via commit message body would only be caught by `--history` (one-off) or by manual review. Tighten later if needed.

## Calibration (per LESSON-008 self-citation)

Wall-clock for this implementation: ~20 min direct work, no subagents. Tagged `tools+bash+ci+audit+mechanism`. Logged in `calibration/log.jsonl`.

## Consequences

- v0.2.7 ships the mechanism. From this point forward, every commit + every push is gated by the sensitivity audit.
- The audit-trail self-documentation pattern is killed by canon — future audits document *patterns added*, never literal data scrubbed.
- The v0.2.6 partner-data-audit pattern (now a deleted file) is the final example of the failure mode. The audit script's README explicitly cites it as the pattern we're avoiding.
- CONTRIBUTING.md / README should mention running `bash tools/install-hooks.sh` after clone (so future contributors get the local pre-commit hook).
- Same mechanism could be extended into the workspace template (`init.sh` could install equivalent hooks into Boss-created project git repos) — deferred for now.

## Supersedes

Nothing direct. Extends the v0.2.0 tests-as-mechanism shipped in `init-smoke.sh` to also cover sensitivity (alongside install correctness).
