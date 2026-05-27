# Roadmap

Vibeboss is in Phase 0 — Feasibility Investigation. v0.1.0 ships the memory and discipline harness. The runtime engine and the broader vision live in later phases. This file is the honest accounting of what's planned vs. what's built.

For what *is* shipped today, see [README.md](README.md#what-ships-today) and [CHANGELOG.md](CHANGELOG.md).

---

## Phase 1 — Runtime engine

The autonomous loop. Today's cut is conventions + hooks; Phase 1 turns those into a running system.

- **Bugs that get fixed, not patched.** Reproduce → locate → fix → verify → log. No "fixed!" claims without a verification step. Requires reproducer tooling, a verify gate, and a runlog entry shape that captures the loop.
- **Don't-stop loops with a kill switch.** Autonomous chain hops via async spawn; drop a STOP file in a known location to halt cleanly. Requires a STOP-file handler in the boot hook and a chain-hop dispatcher.
- **Main / Builder / Research separation as real processes.** Today there's Boss plus named crew (build leads, Ginger as research lead). Phase 1 promotes the pattern: the agent that talks to the operator doesn't build — it delegates to a builder, and researches when it's unsure rather than asking. Requires a Main agent identity distinct from build leads, and a "research-first on ambiguity" enforcement path beyond LESSON-003.

## Phase 2 — Public-repo cut

- Public GitHub repo (this is what users will clone).
- `dashboard-bootstrap.sh` — OSS scaffold for the master dashboard currently living in the partner's workspace. Bun-served operator view at port 3100, surfacing all running CC sessions, per-project status, JSONL activity stream, and HQ state.
- Open to external contribution (see [CONTRIBUTING.md](CONTRIBUTING.md)).

## Phase 3 — Multi-venture / teams

- AI office framework for teams.
- Multi-venture topology (Vibeboss running across several venture workspaces with shared canon).

---

## Deferred for v0.2.0

Honest backlog of smaller items that didn't make v0.1.0:

- **Windows support.** `init.sh` currently rejects Windows; needs `mingw`/`cygwin`/`msys` compatibility.
- **`vibeboss add-project <name>`.** Interactive project scaffolder so operators don't hand-edit `hq/projects/`.
- **Shell-alias injection.** `vibeboss reno` as a real command instead of `bash reno.sh`. Plus an `alias vb='cd ~/ventures/vibeboss-workspace/hq && claude'` suggestion in install output (or auto-injected into shell rc on install).
- **`CONTRIBUTING.md` proper.** Stub exists today (see [CONTRIBUTING.md](CONTRIBUTING.md)); full contribution flow gets written when Phase 2 opens external contribution.
- **`--rename` flag.** Support renaming the workspace, the lead, or the partner identity after install without hand-editing.
- **Tests / CI.** `tests/init-smoke.sh` and a GitHub Actions workflow.
- **Portable hook paths.** Already fixed for `vibeboss/.claude/settings.json` (placeholder + `reno.sh` substitution); audit remaining hook paths in templates for the same hazard.
