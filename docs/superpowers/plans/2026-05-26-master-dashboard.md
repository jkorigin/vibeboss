# Plan: Vibeboss Master Dashboard (v0.1)

**Date:** 2026-05-26
**Spec:** `vibeboss/docs/superpowers/specs/2026-05-26-master-dashboard-design.md`
**Deliverable:** `hq/dashboard/` — Bun server on port 3100

## Build order

Tasks are grouped by dependency layer. Group N can start only after all tasks in Group N-1 are done.

### Group 0 — Infrastructure (parallel, no deps)

| Task | File | Description |
|---|---|---|
| 0a | `hq/dashboard/package.json` | name, type:module, start script, engines |
| 0b | `hq/dashboard/.gitignore` | node_modules, logs, .env |
| 0c | `hq/dashboard/src/events.js` | In-process Bus (ring buffer, pub/sub, snapshot) |
| 0d | `hq/dashboard/src/sources/agents.js` | Spawn `claude agents --json` every 3s, publish to bus |
| 0e | `hq/dashboard/src/sources/jsonl.js` | Tail Vibeboss JSONL files, publish activity events |
| 0f | `hq/dashboard/src/sources/projects.js` | Read hq/projects/*/STATE.md, publish projects_update |
| 0g | `hq/dashboard/src/sources/hq.js` | Read STATE.md + lessons.md + runlog listing |
| 0h | `hq/dashboard/public/style.css` | Dark theme CSS (port WA-PA) |

### Group 1 — Server layer (depends on Group 0)

| Task | File | Description |
|---|---|---|
| 1a | `hq/dashboard/src/server.js` | Bun.serve: static, /api/*, /ws |
| 1b | `hq/dashboard/public/index.html` | 4-pane grid layout, no scripts yet |

### Group 2 — Entry point + frontend (depends on Group 1)

| Task | File | Description |
|---|---|---|
| 2a | `hq/dashboard/src/index.js` | Boot: port check, start sources, start server |
| 2b | `hq/dashboard/public/app.js` | Vanilla ES module: WS client, render all panes |
| 2c | `hq/dashboard/README.md` | How to start, what each pane does |

### Group 3 — Project scaffolding (parallel, no deps)

| Task | File | Description |
|---|---|---|
| 3a | `hq/projects/master-dashboard/STATE.md` | Bootstrap project state |

### Group 4 — Smoke test

1. `cd hq/dashboard && bun start` — must boot without error
2. `curl -s http://127.0.0.1:3100/api/state | jq .` — must return JSON
3. `curl -s http://127.0.0.1:3100/api/agents | jq '.[0].sessionId'` — must return a session ID
4. `curl -s http://127.0.0.1:3100/api/projects | jq '.[0].name'` — must return a project name (e.g. `<project-name>`)
5. WebSocket test via curl --no-buffer or wscat

### Group 5 — Bug-fix rounds (≥3, per dev-workflow)

Round 1 → Round 2 → Round 3: fix failures, surface regressions, clean run.

### Group 6 — Fresh-agent review (dev-workflow Phase 4)

Dispatch a zero-context agent with spec + key diffs. Apply findings.

### Group 7 — Tighten rounds (≥3, per dev-workflow)

Round 1 (clarity) → Round 2 (test quality) → Round 3 (hardening).

### Group 8 — Paperwork

- Write `hq/runlog/2026-05-26-master-dashboard.md`
- Update `hq/STATE.md`: master-dashboard → Recently closed; promote Subsystem C to Next-1

## Constraints

- Port 3100 only — check at startup, fail loudly if taken
- WA-PA daemon at port 3000 must keep running (don't touch its files)
- No React, no build step, no external runtime deps beyond Bun builtins
- No auth (localhost only)
- Read-only access to `~/.claude/projects/` JSONL files
- Write only inside `hq/dashboard/` and `hq/projects/master-dashboard/`

## Definition of done

- Dashboard boots and all 4 panes render data
- All smoke tests pass
- 3 bug-fix rounds complete
- Fresh-agent review complete
- 3 tighten rounds complete
- Runlog written
- STATE.md updated
