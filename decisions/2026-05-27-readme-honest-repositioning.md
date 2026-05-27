# Decision — README repositioned to match what v0.1.0 actually ships

**Date:** 2026-05-27
**Layer:** Framework (Vibeboss canon)
**Author:** Vibe Chief
**Status:** active

## Context

The 2026-05-27 audit found the public README sold Vibeboss as something it isn't yet:

- Tagline: "The AI-as-Boss autonomous OS for vibe coders." There is no OS — there is no runtime engine. v0.1.0 is templates + bash hooks + memory conventions.
- Promise: "Tell Vibeboss a goal. Walk away. Come back to it shipped." Nothing in the repo runs autonomously. Walking away is a Claude Code feature, not a Vibeboss feature.
- "What this will be" listed features that exist only in design docs: "Don't-stop loops with a kill switch" (no STOP-file handler exists), "Main / Builder / Research separation" (only Boss + named crew via spawn, no Main agent), "Non-technical dashboard" (lives in partner's workspace, no OSS scaffold).
- Status section said "Not yet open source. Not yet a usable product." while the Quick Start above told users to `git clone https://github.com/jkorigin/vibeboss` — direct contradiction.

The repo is a real artifact and useful as-is. The marketing surface, not the artifact, was the problem.

## Decision

**Rewrite the README to describe what ships, not what's imagined. Move aspirational features to a new `ROADMAP.md`.**

Specifically:
- Reframe Vibeboss as "a conventions + hooks pack for Claude Code that gives non-technical operators a memory-disciplined workspace where sessions auto-boot with state, lessons, crew, and inbox context." That's accurate and still differentiated.
- Resolve the open-source contradiction: keep the github clone URL (the repo IS at that URL once public), reword Status to "Phase 0 — Feasibility Investigation. v0.1.0 is the first OSS-ready cut. The framework is installable and functions as a memory/discipline harness today; the runtime engine arrives in Phase 1."
- "What this will be" trimmed to: state-that-survives, LESSONS-as-hard-gates, inbox protocol, auto-boot + compact-handover hooks, crew system. All shipped, all real.
- Aspirational items moved to `ROADMAP.md`: bugs-get-fixed loop with reproducer/verify tooling, STOP-file kill switch, Main/Builder/Research as real processes, dashboard OSS scaffold, multi-venture/teams story.
- Phase 1 / Phase 2 / Phase 3 vision lives in `ROADMAP.md`, not in the README's main pitch.

## Why this shape

1. **Trust matters more than excitement at Phase 0.** A clone that lies erodes trust on first contact. A clone that's honest about scope keeps credit for whatever does land.
2. **Keeping the tagline aspiration alive — but qualified.** The "skip permissions, approve all, goodnight" line stays in the README as a stated *goal*, not as a current capability claim. Aspiration is fine; misrepresenting state isn't.
3. **The ROADMAP file is the right home for the Phase 1+ vision.** It pulls all "what's coming" content into one place and lets the README focus on "what's working now."
4. **`CONTRIBUTING.md` stub keeps the door visible.** External contribution opens at Phase 2; the stub explains the boundary and points framework-dev work at `bash reno.sh`.

## Consequences

- Public clones now see a honest pitch on first contact. The Quick Start still works identically.
- The previous README's "What this will be" was carried verbatim into ROADMAP.md so no design intent is lost — just moved to the right surface.
- Future Phase 1 work, when it lands, moves items from ROADMAP into README's "What ships today."

## Supersedes

Nothing — this is the first decision on README framing. Future repositioning decisions reference this one.
