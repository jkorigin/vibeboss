---
topic: <topic-slug>
researcher: <research-lead-name>
request: <path to labs/inbox/requests/...>
hypothesis: <path to topics/<topic>/hypothesis.md>
date: <YYYY-MM-DD>
confidence: <HIGH | MEDIUM-HIGH | MEDIUM | LOW>
risk: <LOW | MEDIUM | HIGH>
status: <pending-pickup | applied | revise-requested | rejected>
linked_decision: <path or empty if not yet applied>
---

# Finding — <topic>

## Hypothesis tested

<Restate from hypothesis.md. Was it confirmed, falsified, or partially?>

## Recommendation

<One sentence. Given the evidence, do X. If choosing between options, state the choice + why others were rejected.>

## Evidence

<EVERY claim cites a source AND a tier label. Group by claim, not by source. Example:>

### Claim 1: <claim>

- [Tier A] <source URL or file:line> — <one-line note on what this source says>
- [Tier B] <source> — <note>

### Claim 2: <claim>

- [Tier A] <source> — <note>
- [Tier C] <source> — <note, e.g. "used to corroborate primary; on its own would not support claim">

### Tier-U claims (if any)

<If any claim relies on training-data pattern with no verifiable source, label it here. Be honest. Confidence cannot exceed LOW if Tier U dominates.>

## Confidence derivation

<Apply the rubric from SKILL.md. Cite specifically: e.g. "MEDIUM-HIGH: 1× Tier A + 2× Tier B corroborating, no Tier C/D/U content, no contradiction.">

## Risk assessment

<Independent of confidence. LOW = easy to revert; MEDIUM = some rework if wrong; HIGH = blocks release or core path.>

## Patch (when applicable)

<If the recommendation translates to a code change, include a unified diff. Files to touch + test to run after applying. SKIP this section if the recommendation is non-code (e.g. choosing between two libraries, design decision).>

```diff
- old line
+ new line
```

Files: <list>
Test: <one command>

## Open questions / re-dispatch

<Anything unresolved. Items the requester should know about even if accepting the main recommendation.>

## Comments

<!-- Partner / build-lead append comments here via the dashboard or directly. Each comment: ### YYYY-MM-DD HH:MM — <author>, then content. Append-only. -->
