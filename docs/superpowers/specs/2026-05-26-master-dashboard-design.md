# Spec: Vibeboss Master Dashboard (v0.1)

**Date:** 2026-05-26
**Status:** Approved — building now
**Path:** `~/ventures/vibeboss-workspace/hq/dashboard/`
**Port:** 3100

## Problem

When Boss spawns `claude -p` headless sessions to do work autonomously, they are invisible to partner. The Claude Code Desktop app shows only interactive sessions in its session picker. Partner has no way to see what's running, how many spawns are active, or what they're doing.

## Solution

A local web dashboard at `http://127.0.0.1:3100` that gives partner a single view across:
- All running Claude Code sessions on the machine
- Live activity stream from Vibeboss-related JSONL session files
- Per-project status from STATE.md files
- HQ-level state (master STATE.md, lessons count, recent runlog)

## Design decisions

| Decision | Choice | Rationale |
|---|---|---|
| Port | 3100 | 3000 is WA-PA; no collision |
| Runtime | Bun | Same as WA-PA; no build step |
| Frontend | Vanilla ES modules | Same as WA-PA; no framework overhead |
| Theme | Dark, ported from WA-PA | Consistent palette |
| Polling | 3s for agents, 2s for JSONL | Fast enough to feel live; no O(N) polling waste |
| WebSocket | Bun native | Push events to browser without polling |
| Spawn-task pane | Deferred (v0.2) | Design is clear but not critical for v0.1 observability |

## Panes (v0.1)

### 1. Sessions pane
- Source: `claude agents --json` polled every 3s
- Shows: PID, cwd (shortened), kind, status (active/idle), started-at, sessionId
- Vibeboss filter: toggle to show only sessions with cwd containing `vibeboss`
- Copyable resume command: `claude --resume <sessionId>`

### 2. Activity stream
- Source: tail `~/.claude/projects/-Users-jinkunyong-ventures-vibeboss*/*.jsonl`
- Parses each JSONL line; shows one-line summary per event
- Ring buffer: last 500 events
- Auto-scroll (toggleable), text filter
- Color-codes by event type (user/assistant/tool/result)

### 3. Projects pane
- Source: reads `hq/projects/*/STATE.md` on-demand (every 15s refresh)
- Shows project name + first 5 lines of STATUS section
- Links to resume any sub-session

### 4. HQ state pane
- Source: `hq/STATE.md` (first 30 lines), `hq/lessons.md` (lesson count), `hq/runlog/` (5 most recent entries)
- Refreshes every 30s
- Monospace markdown-ish rendering

### 5. Spawn task pane (DEFERRED to v0.2)
- Was: text input + spawn button + cwd selector
- Deferred: v0.1 is observability-only

## API surface

```
GET  /api/state     — bus snapshot (connection, counters)
GET  /api/agents    — current claude agents --json output
GET  /api/projects  — array of {name, state_md_excerpt}
GET  /api/hq        — {state_md, lesson_count, recent_runlog}
GET  /api/activity  — last N activity events from ring buffer
WS   /ws            — live push of all bus events
```

## File structure

```
hq/dashboard/
├── package.json
├── README.md
├── .gitignore
├── src/
│   ├── index.js          — boot, port check, start pollers + server
│   ├── server.js         — Bun.serve: HTTP + WebSocket + static
│   ├── events.js         — in-process pub/sub bus (ring buffers)
│   └── sources/
│       ├── agents.js     — claude agents --json poller
│       ├── jsonl.js      — JSONL file tailing poller
│       ├── projects.js   — hq/projects/*/STATE.md reader
│       └── hq.js         — hq/STATE.md + lessons.md + runlog reader
└── public/
    ├── index.html        — 5-pane layout (4 active + 1 deferred)
    ├── style.css         — dark theme (ported from WA-PA)
    └── app.js            — vanilla ES module frontend
```

## Success criteria

1. `bun start` boots without error on port 3100
2. Sessions pane shows this spawn's own session (or any live session)
3. Activity stream shows new JSONL lines within ~3s of them being written
4. Projects pane shows whatsapp-pa STATE.md excerpt
5. HQ state pane shows current STATE.md content
6. WebSocket reconnects on disconnect
7. All smoke tests pass: `/api/state`, `/api/agents`, `/api/projects`, `WS /ws`
