# Decision — Autonomous research-dispatch loop + lab review dashboard

**Date:** 2026-05-28
**Layer:** Framework (Vibeboss canon)
**Author:** Vibe Chief
**Status:** active

## Context

Vibeboss canon through v0.2.7 has the *plumbing* of the labs research function (directories, named research lead Ginger, three handoff flows in `templates/labs/README.md`) and a discipline note about ambiguity (LESSON-003 *"Research-first on ambiguity"*) — but no actual mechanism for build-leads to autonomously dispatch to research when stuck. The autonomous-research-spawn loop that's been the framework's stated differentiator since v0.1.0 wasn't wired.

The audit (this session) surfaced six concrete gaps:

1. No "when to dispatch" trigger discipline — agents default to guessing (Tier-U hallucination), stopping verbally on partner, or in-context spike when scope exceeds what a spike can do.
2. No research methodology — Ginger has a name but no playbook.
3. No non-blocking pattern — build-leads have no documented behavior while research is in-flight.
4. No source-quality grading — "Confidence: HIGH" was a free-form feeling, not a derived value.
5. No provenance on research-led decisions — decision files carry `Author:` but no link to the finding or the evidence chain.
6. No review surface for non-technical partners — files-as-canon is great for storage but awful for partner UX when they need to approve/revise/reject pending findings.

This decision ships the architecture that closes all six.

## Decision

**v0.3.0 adds the autonomous research-dispatch loop as a six-principle architecture, expressed across four layers + a minimal review UI.**

### Six principles (derived from the problem-shape, not vendor-imported)

1. **Confidence × Risk is the load-bearing variable.** Two scalars, four cells, encoded as a rubric. Auto-apply or partner-surface decision falls out of the cell, not a per-finding judgment call.
2. **Dispatch is a spectrum, not a binary.** T1 in-context (default for <15min single-source), T2 sync parallel subagents via the Agent tool (15-30min, multi-angle), T3 async file-write to labs (>30min OR needs methodology). Build-leads classify before dispatching.
3. **Methodology is three rules.** Hypothesis-first, every claim cites evidence with a source tier, findings end with a recommended action (often a patch). No 200-line port from the reference operation — slim, composable with superpowers (the always-on baseline).
4. **Findings are patches when applicable.** Diff format + files-to-touch + test-to-run. Build-lead's pickup is "is this patch sound?" not "what should I do?" Skipped for non-code recommendations.
5. **Provenance is decision-file frontmatter.** `Author: <build-lead>, via research by <research-lead>` + `Linked finding:` + `Confidence:` + `Risk:` + `Status:` + `Verified by:`. Four-line audit chain; no separate tracking system.
6. **Every cited source has a tier label.** Five tiers (A primary / B reputable / C tertiary / D hype / U untraceable-from-training). Confidence is **derived** from the tier mix, not asserted free-form. Tier U is the anti-hallucination layer — it makes the model name when it's pattern-matching from training without a verifiable source.

### Four layers

- **Layer 1 — Discipline.** Two new LESSONS (011 dispatch-tiers, 012 source-tier discipline). Protocol sections in `templates/hq/CLAUDE.md`, `templates/projects/_per_project/README.md`, and `CHIEF.md`.
- **Layer 2 — Dispatch.** T2 uses the existing Agent tool (no new plumbing). T3 uses the existing labs inbox (already plumbed in v0.1.0). The trigger is a model-behavior contract (LESSON-011), not a hook.
- **Layer 3 — Methodology.** New SKILL at `templates/labs/skills/research/SKILL.md` (~70 lines after Cluster B's tight compile). Three artifact templates: `_templates/hypothesis.md`, `_templates/finding.md`, `_templates/handoff.md`. The finding template has frontmatter with `confidence:`, `risk:`, `status:`, `linked_decision:` fields + a tier-tagged evidence section + an optional patch block.
- **Layer 4 — Pickup.** Protocol section in CLAUDE.md describing the Confidence × Risk rubric, the auto-apply path for HIGH/LOW, the partner-surface path for everything else, and the decision-file frontmatter convention for research-led decisions.

### The review dashboard

A Bun-served single-process web UI at `templates/labs/dashboard/`. Workspace-scope (one dashboard per workspace). Vanilla HTML/CSS/JS — no React/Vue/Svelte, no npm dependencies beyond Bun's stdlib. ~900 LOC total across server.ts (Bun HTTP, atomic frontmatter write-back) + public/{index.html, style.css, app.js}.

What partner sees:
- Pending findings grouped by status
- For each: title, hypothesis tested, confidence/risk, tier-tagged evidence, recommendation, optional patch
- Action buttons: Approve / Revise / Reject + comment box
- Comments append to the finding's `## Comments` section with timestamp + author

How status changes propagate:
- UI action → POST to dashboard's local Bun server → writes frontmatter `status:` field atomically (write tmp + rename)
- Files-as-canon: dashboard is just UI; the markdown files remain the source of truth
- Build-leads see new status on their next inbox check (no event bus, no pub/sub)

Security model:
- Localhost-bind only (`127.0.0.1`)
- No auth — single-operator workstation assumption
- Documented as not-for-public-internet-exposure

Master-dashboard integration is deferred to v0.4.0. The lab dashboard exposes a documented JSON interface (`GET /api/findings`, etc.) and writes its port to `.runtime/port` so the future master can discover it.

## Why this shape

1. **Confidence × Risk replaces judgment with rubric.** Free-form confidence assertions are where hallucination hides. A two-scalar rubric makes the auto-apply decision auditable.
2. **Three dispatch tiers reflect actual problem-shape.** Most research-y questions are T1 or T2. T3 (the async-to-labs loop) is for the genuinely big stuff. We don't need a heavyweight async dispatch mechanism for the common case — the Agent tool covers T2 today.
3. **Three methodology rules instead of vendor-importing.** The reference operation (`<other-research-container>/<other-research-project>/`) has 10+ recipes, CONTRACT.md, PORTFOLIO.md, mickey-brew/. Useful for that operation, overweight for Vibeboss. The three rules — hypothesis-first, cite with tier, recommend action — capture the load-bearing discipline. Everything else is venture-specific accumulation.
4. **Source tiers make audit possible.** Six months later, partner can trace a wrong decision back to its evidence quality. Without tier labels, "Confidence: HIGH" is unfalsifiable.
5. **Dashboard as files-thin-UI.** The dashboard never owns data. Frontmatter is canonical. This means: if Bun isn't installed, the framework still works (partner reviews via files); if the dashboard crashes, no data lost; the future master-dashboard plugs in via documented JSON, not via shared state.
6. **Bun + vanilla over React/Vue.** First piece of UI code in the framework. Keep dependencies near-zero. Bun has built-in HTTP + fs + file watching. Vanilla JS works fine for ~250 LOC of interactivity. Lower maintenance, lower security surface, lower install friction.
7. **Workspace-scope, not per-project.** One Bun process per workspace covers all projects' research. Per-project would mean partner runs N processes simultaneously; one workspace-level dashboard with project filtering is enough.

## What shipped

Files added (12 new):

- `templates/hq/lessons.md` — LESSON-011 + LESSON-012 appended
- `templates/hq/CLAUDE.md` — new `## Research dispatch + pickup` section
- `templates/projects/_per_project/README.md` — mirrored section for build-leads
- `CHIEF.md` — bullet 9 added to discipline list
- `templates/labs/skills/research/SKILL.md` — methodology
- `templates/labs/_templates/hypothesis.md`
- `templates/labs/_templates/finding.md`
- `templates/labs/_templates/handoff.md`
- `templates/labs/dashboard/README.md`
- `templates/labs/dashboard/start.sh` (executable)
- `templates/labs/dashboard/server.ts`
- `templates/labs/dashboard/package.json`
- `templates/labs/dashboard/public/{index.html, style.css, app.js}`
- `templates/labs/dashboard/.runtime/.gitkeep`
- `migrations/v0.2.7-dev-to-v0.3.0-dev.sh`

Files changed:
- `init.sh` — scaffolds new dirs + Bun availability warning + chmod +x on start.sh
- `tests/init-smoke.sh` — verifies new files + LESSONS + protocol section
- `VERSION` → `0.3.0-dev`
- `CHANGELOG.md` — v0.3.0 entry + closes v0.2.7
- `ROADMAP.md` — "Recently shipped (v0.3.0)" section added; master-dashboard integration tracked for v0.4.0
- `calibration/log.jsonl` — entry per LESSON-008

## Limits / known caveats

- **Methodology is slim.** Three rules captures the discipline but doesn't cover every research style. If a research stream needs a specific heavier methodology (literature review, A/B testing, formal verification), Ginger writes a project-specific addendum at `labs/research/<project>/methodology-addendum.md`. The framework SKILL stays slim.
- **Confidence rubric is mechanical, not perfect.** "Multiple Tier A corroborating" → HIGH is a heuristic. A single excellent Tier A source might warrant HIGH on its own; the rubric won't let it. Build-leads can override the auto-apply decision based on their judgment.
- **Tier U is honest but not enforceable.** Models can claim Tier A while really pattern-matching from training. The discipline relies on agents being honest about source provenance. Audit catches the egregious cases; subtle cases require partner spot-checking.
- **Dashboard is local-only.** No remote access, no auth, no multi-user. Single-operator workstation assumption. If a team ever wants shared review, that's a different surface (Phase 3 territory per ROADMAP).
- **Bun is a new dependency.** Until v0.3.0, Vibeboss had no runtime dependencies beyond Claude Code + Python 3 + Bash. Bun is now optional-but-recommended for dashboard users. Init.sh warns but doesn't block. Findings remain reviewable as files without it.
- **First time we ship code (not markdown + bash).** The dashboard introduces TypeScript + HTML + CSS + JS as maintained surfaces. Maintenance overhead is real; v0.2.7's sensitivity-audit mechanism gates leaks but doesn't gate code-quality. CI doesn't run the dashboard yet (would need Bun in CI).
- **Master-dashboard integration is documented contract, not built code.** Lab dashboard exposes `GET /api/findings` and writes `.runtime/port` for future discovery; the actual master that consumes it lands in v0.4.0.

## Consequences

- v0.3.0 closes the framework's biggest stated-but-unwired feature gap (the autonomous research loop).
- Partner gets a real UI for the workflow described — approve/revise/reject + comments — without leaving the workstation.
- The audit chain (decision → finding → tier-tagged evidence) becomes inspectable forever. Wrong decisions can be traced back to source quality.
- Future canon work that involves research dispatch now has a structured shape to invoke (LESSONS 011-012 + the SKILL). No more ad-hoc "should I research?" reasoning.
- The Bun runtime joins the framework's dependency surface. Workspace install instructions need to mention Bun for dashboard users (init.sh already warns).
- v0.4.0 master-dashboard integration is a documented next step — lab dashboard's JSON interface is the contract.

## Supersedes

Extends LESSON-003 (which becomes the T1 case of the new dispatch tiers). Does not supersede prior decisions; layers on top.
