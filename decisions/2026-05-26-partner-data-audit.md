# Decision — Partner-specific data audit (OSS-ready pass)

**Date:** 2026-05-26
**Layer:** Framework (Vibeboss canon)
**Author:** Vibe Chief
**Status:** active

## Context

Before pushing the framework to a public GitHub repo, every file was audited for partner-specific data that should not ship in OSS canon. The audit used grep across all `.md`, `.json`, `.yml`, `.sh` files for: partner name, email, phone number, machine path, project-specific identifiers, and hardcoded crew names.

## Audit results

### Critical — removed

| File | Issue | Action |
|---|---|---|
| `vibeboss/.claude/settings.json` | Hardcoded `~/...` absolute path | Replaced with `VIBEBOSS_DIR_PLACEHOLDER` (see decisions/2026-05-26-portable-hook-paths.md) |
| `vibeboss/.claude/launch.json` | VS Code-style debug config with hardcoded runtime paths (`~/ventures/vibeboss-workspace/projects/<example-project>/...`) | **Deleted.** Not framework canon — partner's local dev tooling. Added to `.gitignore`. |
| `docs/design/plans/2026-05-26-topology-hq-split.md` (×3) | Phone number `<phone>@c.us` (partner's WhatsApp identity) | Redacted to `<whatsapp-id>@c.us` / `<name>` |
| `CHANGELOG.md` (Known follow-ups) | Mentioned `~/...` path in the portable-hook-paths follow-up note | Replaced with generic description |

### Acceptable — kept as-is

| File | Content | Reason |
|---|---|---|
| `README.md` | `jkorigin` (author name), copyright line | Author attribution is explicitly correct per Apache 2.0 and partner's consent |
| `LICENSE`, `NOTICE` | `jkorigin` | Required by Apache 2.0 |
| `CLAUDE.md` | `jkorigin` in license section | Same as README |
| `docs/design/specs/2026-05-26-crew-system-design.md` | `Banana`, `<example-project>` as concrete design examples | Specs documenting the crew system design process may use the real examples that validated the design. `<example-project>` is acceptable in docs/specs per framework canon (it's "the example app that validated the spawning model"). `Banana` is not in the restricted list. |
| `docs/design/specs/2026-05-26-topology-hq-split-design.md` | `<example-project>` as example project | Same rationale — spec documenting design. |
| `docs/design/plans/2026-05-26-topology-hq-split.md` | `<example-project>`, runtime paths (post-redaction) | Historical execution plan. Phone number redacted; remaining content describes process, not private identity. |
| `docs/design/plans/2026-05-26-crew-system.md` | `<example-project>/inbox/` dirs | Execution plan using the example project. |
| `docs/design/plans/2026-05-26-master-dashboard.md` | `<example-project>` in test assertion example | Acceptable as example. |
| `CHANGELOG.md` | `<example-project>`, `Ginger` (in Subsystem F description) | Historical record of what shipped. Crew names mentioned as example context, not as "official" crew. |
| `CHIEF.md` | Mentions `Banana`, `<example-project>`, `<phone>@c.us` as examples of what NOT to include | These are the discipline rules, not actual data. |

### Not found

- `<operator-email>` — not present in any tracked file (appears only in session context, not in OSS source)
- `Banana`, `Carrot`, `Ginger` — not present in any template file; appear in CHANGELOG/CHIEF.md as illustrative examples only (acceptable)

## Audit rule going forward

Vibe Chief discipline: before any new spec, plan, or template is committed, scan for the following substrings: phone numbers, email addresses, absolute paths with usernames, partner-specific project names used as defaults (not as examples), hardcoded crew names in templates.

The `CHIEF.md` discipline rules (no partner-specific runtime references in source) are the authority. This decision documents the one-time cleanup pass; CHIEF.md is the ongoing guardrail.

## Files changed

1. `vibeboss/.claude/settings.json` — placeholder replacement
2. `vibeboss/.claude/launch.json` — deleted
3. `vibeboss/.gitignore` — added `launch.json` exclusion
4. `vibeboss/docs/design/plans/2026-05-26-topology-hq-split.md` — 3 redactions
5. `vibeboss/CHANGELOG.md` — 1 path reference removed
