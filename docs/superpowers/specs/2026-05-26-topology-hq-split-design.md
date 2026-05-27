# Subsystem A — Topology + HQ Split

**Status:** approved design, ready for implementation plan
**Date:** 2026-05-26
**Author:** Boss (Vibeboss venture lead)
**Approver:** partner
**Predecessors:** [2026-05-25-build-locations-and-spawning.md](../../../office/decisions/2026-05-25-build-locations-and-spawning.md), [2026-05-25-workspace-reorg.md](../../../office/decisions/2026-05-25-workspace-reorg.md) — earlier passes at the same problem.
**Supersedes:** Both prior decisions on this topic. Their rationale is preserved here; only the exact topology is amended.

---

## Goal

Cleanly separate Vibeboss's two things: **source code (framework, future-OSS)** from **runtime state (the lead's memory + the partner's projects)**. Right now they're mixed inside `~/ventures/vibeboss/`, which means:

- `vibeboss/office/`, `vibeboss-workspace/labs/research/`, `vibeboss/crew.yml` are runtime data sitting inside the future public repo.
- "Edit Vibeboss source" and "do my work as Boss" share a directory, so neither is ergonomic.
- Per-project memory has no clean home — runlogs and decisions about an individual project (e.g. `<project-name>`) live in `vibeboss/office/`, conflating project memory with framework patterns.

The fix is a sibling-directory layout under `~/ventures/`, with the runtime concentrated in a workspace folder.

---

## Final topology

```
~/ventures/vibeboss/                       ← OSS source. Apache 2.0. Framework only.
~/ventures/vibeboss-workspace/             ← Runtime. Partner-owned. Never committed to OSS.
  ├── hq/                                   ← My home. Where I boot. Where memory lives.
  ├── labs/                                 ← Research-labs project code + experiments.
  └── projects/                             ← Parent of all partner-owned project codebases.
      └── <project-name>/                   ← One subdir per partner-owned project (illustrative example used during this migration: <example-project>).
```

**Hard rules**

- `vibeboss/` contains zero runtime state. If a file changes during normal operation (logs, decisions, lessons), it belongs in `vibeboss-workspace/`.
- `vibeboss-workspace/` is **never** committed to the public OSS repo. It is the user's machine-local state.
- Cross-references go *from* the workspace *to* `vibeboss/` (the workspace knows about the framework), never the other way (the framework knows nothing about any specific runtime).

---

## HQ shape

```
~/ventures/vibeboss-workspace/hq/
├── CLAUDE.md             ← BOOT BRIEF — the entry point I read on every session.
├── STATE.md              ← Master cross-project state ("where are we right now").
├── crew.yml              ← Operator + lead identity + per-project agents registry.
├── lessons.md            ← Cross-cutting LESSONS (LESSON-001…LESSON-003 today).
├── runlog/               ← Chronological master diary. Every session, every project.
├── decisions/            ← Cross-cutting decisions (apply to multiple projects).
├── inbox/                ← Partner drop-zone. Master inbox (requests/chats/todos/processed).
├── skills/               ← Custom skills I write or partner asks me to add.
├── follow-ups/           ← Cross-project TODOs.
├── secrets/              ← Never committed. Reference-by-path discipline.
└── projects/             ← Per-project memory routing.
    ├── <project-name>/   ← (illustrative example used during this design: <example-project>)
    │   ├── STATE.md      ← Project-specific state.
    │   ├── notes.md      ← Running notes for this project.
    │   ├── lessons.md    ← Project-specific lessons.
    │   └── decisions/    ← Project-specific decisions.
    ├── labs/             ← Research-labs HQ memory.
    └── …
```

### Routing rule (the answer to "where do I write this?")

| Type of writing | Destination |
|---|---|
| LESSON that applies across projects (e.g. "default to build") | `hq/lessons.md` |
| LESSON specific to one project (e.g. "WA bot-detection bypass") | `hq/projects/<name>/lessons.md` |
| Decision that affects multiple projects (e.g. topology) | `hq/decisions/` |
| Decision specific to one project (e.g. "use Sonnet for WA") | `hq/projects/<name>/decisions/` |
| Runlog entry (any work session) | `hq/runlog/YYYY-MM-DD-<slug>.md` (chronological master, regardless of project) |
| Project-specific state ("what's the WA PA doing right now") | `hq/projects/<name>/STATE.md` |
| Cross-cutting state ("which phase is Vibeboss in") | `hq/STATE.md` |
| Inbox item from partner | `hq/inbox/` (master); after handling, move to `hq/inbox/processed/` AND reference from runlog |
| Custom skill I write | `hq/skills/<name>/SKILL.md` |
| Spec for future framework patterns | `vibeboss/docs/superpowers/specs/` (rare — only when documenting an OSS-bound pattern) |

When partner says "log a lesson about X" and X is unambiguously one project, I route to that project. When ambiguous, I ask.

---

## `vibeboss/` source shape (post-migration)

```
~/ventures/vibeboss/
├── README.md             ← public OSS one-pager (unchanged).
├── LICENSE               ← Apache 2.0 (unchanged).
├── NOTICE                ← unchanged.
├── .gitignore
├── CLAUDE.md             ← REWRITTEN as framework reference doc — what a clone-r reads to
│                            understand Vibeboss's patterns. Not a boot brief anymore.
├── crew.yml.template     ← Template; init copies to hq/crew.yml on first setup.
├── docs/                 ← Framework reference docs (Diataxis-aligned over time).
│   ├── superpowers/
│   │   └── specs/        ← Design specs for framework patterns (this file lives here).
│   └── (future: how-to, reference, tutorial, explanation)
└── (future framework code in Phase 1+)
```

What `vibeboss/CLAUDE.md` becomes: a doc that explains the *patterns* (HQ, runlog discipline, LESSONS as hard-gates, the spawning model, the dev workflow). Whoever reads it learns what Vibeboss publishes. It is *not* personalized to any installation.

---

## Migration steps (one-time)

1. `mkdir -p ~/ventures/vibeboss-workspace/{hq/{runlog,decisions,inbox,skills,follow-ups,secrets,projects/<example-project>/decisions},labs/research,projects}`
2. Move project code:
   `mv ~/ventures/vibeboss-workspace/projects/<example-project>  ~/ventures/vibeboss-workspace/projects/<example-project>`
   `rmdir ~/ventures/vibeboss-workspace/projects` (now empty)
3. Move HQ runtime:
   - `mv ~/ventures/vibeboss-workspace/hq/STATE.md  ~/ventures/vibeboss-workspace/hq/STATE.md`
   - `mv ~/ventures/vibeboss-workspace/hq/runlog/*  ~/ventures/vibeboss-workspace/hq/runlog/`
   - `mv ~/ventures/vibeboss-workspace/hq/decisions/*  ~/ventures/vibeboss-workspace/hq/decisions/`
   - `mv ~/ventures/vibeboss-workspace/hq/inbox/*  ~/ventures/vibeboss-workspace/hq/inbox/`
   - `mv ~/ventures/vibeboss-workspace/hq/lessons.md  ~/ventures/vibeboss-workspace/hq/lessons.md`
   - `mv ~/ventures/vibeboss-workspace/hq/secrets  ~/ventures/vibeboss-workspace/hq/secrets` (if non-empty)
   - `mv ~/ventures/vibeboss/crew.yml  ~/ventures/vibeboss-workspace/hq/crew.yml`
   - `rm -rf ~/ventures/vibeboss/office  ~/ventures/vibeboss-workspace/labs/research` (now empty)
4. Move research artifacts:
   `mv ~/ventures/vibeboss-workspace/labs/research/cc-app-orchestration.md  ~/ventures/vibeboss-workspace/labs/research/cc-app-orchestration.md`
5. Write fresh `~/ventures/vibeboss-workspace/hq/CLAUDE.md` (boot brief — references framework docs for patterns; routes to STATE/runlog/decisions/inbox in HQ).
6. Rewrite `~/ventures/vibeboss/CLAUDE.md` as framework reference (no boot sequence, no per-installation specifics, no boundaries section — those are HQ concerns).
7. Sweep all moved files for absolute path references and update them. Specifically:
   - All `~/ventures/vibeboss-workspace/projects/<example-project>` → `~/ventures/vibeboss-workspace/projects/<example-project>`
   - All `vibeboss/office/...` → `vibeboss-workspace/hq/...`
   - All `office/lessons.md` → `hq/lessons.md` (relative or absolute as appropriate)
   - Includes README files, decision files, runlog entries, agent.js comments, launch.json paths.
8. Bootstrap per-project subdir for <example-project>:
   - Create `hq/projects/<example-project>/STATE.md` with current WA-PA state copied from cross-cutting STATE.md (anything WA-specific moves here; truly cross-project stays in `hq/STATE.md`).
   - Create stub `hq/projects/<example-project>/lessons.md`, `notes.md`.
9. Update authorization list in `vibeboss/CLAUDE.md` (the framework doc) → `vibeboss-workspace/hq/CLAUDE.md` (the runtime boot brief) records current authorizations.
10. Write a migration runlog entry at `hq/runlog/2026-05-26-topology-migration.md` documenting the cutover, with a `Commands run` block listing every `mv`, `rm`, `mkdir`.
11. Update VS Code / shell shortcut habits: `cd ~/ventures/vibeboss-workspace/hq/` becomes the default boot location. Source visits are `cd ~/ventures/vibeboss/`.

### Validation gates (must pass before declaring migration complete)

- `find ~/ventures/vibeboss -type f | xargs grep -l "vibeboss-workspace/projects" 2>/dev/null` returns nothing (or only inside this design doc, which references the old path historically).
- `find ~/ventures/vibeboss -type f | xargs grep -l "office/" 2>/dev/null` returns nothing in framework source.
- `ls ~/ventures/vibeboss/office 2>&1` returns "No such file" — runtime fully evicted from source.
- `ls ~/ventures/vibeboss-workspace/hq` shows the expected directory shape.
- `bun start` from `~/ventures/vibeboss-workspace/projects/<example-project>/` still boots the daemon, scans QR, reaches `connected` state (<example-project> code's relative paths must still resolve after the move).
- The dashboard at http://localhost:3000 still renders QR / persona / knowledge / log panes correctly.
- A new Claude Code session at `~/ventures/vibeboss-workspace/hq/` boots and reads the right state.

---

## Open implementation details (will be locked by writing-plans skill, not here)

- `.gitignore` strategy in `vibeboss/` to assert the runtime never sneaks back in (just `office/` and `research/` and `crew.yml` and any obvious runtime paths).
- Whether `vibeboss-workspace/` itself wants a top-level `README.md` for partner orientation (probably yes — a tiny one-pager).
- Whether HQ's `CLAUDE.md` should also be symlinked or copied as `AGENTS.md` for Codex compatibility (per the existing pattern in `vibeboss/`).
- Whether `crew.yml` should be split into `crew.yml` (identity) and `agents.yml` (per-project registry) or stay merged — defer until subsystem C (crew system).
- Where the WhatsApp PA's running daemon lives across the cutover — needs a controlled stop + path-update + restart, or risk a dead daemon pointing at the old code path.

---

## What this design does *not* cover

(In scope for later subsystems, intentionally deferred here.)

- **B: dev-workflow skill** — captured separately; not part of this migration.
- **C: crew system** — per-project named agents and their registry format.
- **D: auto-boot on new conversation** — SessionStart hook will land in HQ later.
- **E: compact handover protocol** — handover file format + reboot mechanism.
- **F: research labs** — labs/ directory will exist after migration; actual labs init flow is its own subsystem.
- **G: `vibeboss init` flow** — the productized command that does all this for a fresh user.

---

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| The running WhatsApp PA daemon (PID 81860, on port 3000) holds open file descriptors against the old path during migration. Move silently breaks it. | Stop daemon before migration step 2. Update its README/launch.json paths in step 7. Restart and verify connection comes back via stored `data/auth`. |
| Path references inside moved files are missed by the grep sweep, leaving stale references that mislead future-Boss. | Step 7's sweep must be thorough: scan `**/*.md`, `**/*.json`, `**/*.yml`, `**/*.js` under both `vibeboss/` and `vibeboss-workspace/`. List every match before mutating. |
| `vibeboss/CLAUDE.md` is doing two jobs (framework reference + boot brief). Splitting it loses context that mattered. | Rewrite both files side-by-side: framework CLAUDE.md = patterns/discipline/license; HQ CLAUDE.md = boot sequence/identity/current authorizations. The boot sequence references the framework doc by relative path. |
| Partner cd's to old path out of habit and gets confused state. | Clean removal of the old paths during migration (steps 2-3). No stub REDIRECT files — they invite drift. If partner cd's to a removed path, the shell errors loudly, which is the right signal. |
| The per-project memory routing rule sounds clean but in practice messages are ambiguous ("did this lesson belong to <example-project> or HQ-cross-cutting?"). | Default behavior: I ask when unclear. LESSON-003 already says research-first on ambiguity; this is its application to memory routing. |

---

## Definition of done

This subsystem is "shipped" when:

1. The directory layout under `~/ventures/vibeboss-workspace/` exists and contains all moved files.
2. `~/ventures/vibeboss/` contains zero runtime state files.
3. All validation gates above pass.
4. A new Claude Code session booting from `~/ventures/vibeboss-workspace/hq/` reads the right state and behaves as before the migration.
5. The WhatsApp PA daemon can be restarted from the new location and reconnects without partner intervention.
6. The migration runlog entry is written.
7. Partner has confirmed the layout works for them (one trial session in the new home).
