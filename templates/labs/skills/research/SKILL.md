---
name: research
description: Use when the labs research lead picks up a request from labs/inbox/requests/. Methodology for producing tier-tagged findings with derived confidence.
---

# Research methodology

When you pick up a request from `hq/projects/labs/inbox/requests/<request>.md`, follow this methodology. Three rules — no more, no less.

## The three rules

### Rule 1 — Hypothesis first

Before researching, write what you expect to find AND what would falsify it. Save at `labs/research/<project>/topics/<topic>/hypothesis.md` (use the template in `labs/_templates/hypothesis.md`).

Why: stops fishing-expedition research. If you can't state a hypothesis, the question isn't researchable — go back to the requester and ask for refinement.

### Rule 2 — Every claim cites evidence with a source tier

Every factual claim in your finding cites a source AND tags it with one of five tiers. Confidence is **derived** from the tier mix, not asserted free-form.

Tier rubric:

- **Tier A — Primary / authoritative.** Official documentation, source code read directly, RFC/spec, reproducible test result.
- **Tier B — Secondary / reputable.** Maintainer's blog, engineering blog (e.g. Anthropic), peer-reviewed paper, high-vote recent SO answer.
- **Tier C — Tertiary / opinion.** Random Medium post, Substack, tutorial site of unknown authorship, X thread.
- **Tier D — Hype / superficial.** Listicles, influencer takes without code, content-farm articles, LLM-generated content as evidence.
- **Tier U — Untraceable / from-memory.** Pattern recalled from training with no verifiable source. Use this label whenever you cannot point to a real source.

Confidence-derivation table:

| Evidence mix | Confidence |
|---|---|
| Multiple Tier A, corroborating, no contradiction | HIGH |
| Single Tier A + Tier B corroboration, OR multiple Tier B | MEDIUM-HIGH |
| Tier B + C mix, no contradiction | MEDIUM |
| Mostly C/D, single source, OR Tier-U-dominant | LOW |
| Contradicting sources, unresolved | LOW + needs re-dispatch |

Why: without source tiering, "HIGH confidence" is a feeling. Tier U surfaces hallucination at the moment it would be written. Forces you to either find a real source or admit you don't have one.

### Rule 3 — Findings end with a recommended action

Not "here are the observations." Always: "given X, do Y." When the answer translates to code, include a patch section in the finding (diff format, files to touch, test to run). When it's a recommendation between options, state the recommendation + the rejected options + why.

Use the template in `labs/_templates/finding.md`.

## The 8-step shape (for guidance, not strict gate)

1. **Orient.** Read the request. Read prior findings in `labs/research/<project>/findings/` for context. Read `hq/projects/<project>/STATE.md` to know what's going on.
2. **Hypothesize.** Write `hypothesis.md` per Rule 1.
3. **Dispatch.** Decide tier:
   - In-context: do it yourself with WebFetch/WebSearch/Read.
   - Parallel: spawn 2-3 Explore agents via the `Agent` tool. Each gets a focused brief + this contract prefix: *"Cite every claim with a source URL or file:line. Label each citation with one of: Tier A (primary/authoritative), Tier B (secondary/reputable), Tier C (tertiary/opinion), Tier D (hype/superficial), Tier U (untraceable/from-memory). If you cannot verify a claim with a real source, label it Tier U and lower confidence accordingly. Budget: ~15 min. Return markdown."*
4. **Synthesize.** Combine returns. Identify contradictions. Re-dispatch if unresolved.
5. **Derive confidence.** Use the rubric table — don't free-form.
6. **Assess risk.** Independently of confidence — what's the cost of the recommendation being wrong? LOW = easy to revert. MEDIUM = some rework. HIGH = blocks a release or affects partner's core path.
7. **Write the finding.** Use the template in `labs/_templates/finding.md`.
8. **Handoff.** Write a handoff at `hq/projects/<project>/inbox/from-labs-<topic>.md` using the template in `labs/_templates/handoff.md`. Move the original request from `labs/inbox/requests/` to `labs/inbox/processed/`.

## When you're stuck

If you can't make progress: write a partial finding with Confidence: LOW, document what's blocking, and surface to the dispatching agent via the handoff. Better to return "I couldn't determine confidently — here's what I found" than to fabricate confidence.

## Skill composition

This skill assumes superpowers (the always-on baseline) is enabled. Use `superpowers:brainstorming` during Step 2 (hypothesis), `superpowers:systematic-debugging` if a finding requires falsifying via experiment. Don't reinvent what superpowers already does well.
