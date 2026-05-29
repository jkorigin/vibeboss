# Labs dashboard

Web UI for reviewing pending research findings. Read-only file-system viewer + status/comment write-back. Files remain the source of truth — the dashboard never moves data into a database.

## What you see

- **Pending findings** — research outputs awaiting your disposition (approved / revise / rejected).
- **For each finding:** title, hypothesis tested, confidence (derived from tier mix per LESSON-011), risk, recommended action, tier-tagged evidence, optional patch.
- **Actions per finding:** Approve / Revise / Reject + comment box.
- **History:** previously-dispositioned findings, browsable.

## Starting it

```
bash <workspace>/labs/dashboard/start.sh
```

Boss runs this for you on verbal request (per LESSON-009). The script picks an available port starting at 3101, prints the URL, and writes the actual port to `.runtime/port`.

## Prerequisites

- **Bun 1.0+** (https://bun.sh). The dashboard is a single Bun process. If Bun isn't installed, `start.sh` will tell you and point at the install URL.

## How status changes propagate

The dashboard rewrites the finding's frontmatter `status:` field. Build-leads see the new status on their next inbox check. Comments are appended to the finding's `## Comments` section as `### <YYYY-MM-DD HH:MM> — partner`.

## Security

- Localhost-bind only (`127.0.0.1`). The dashboard is not reachable from another machine on the network unless you reverse-proxy it.
- No authentication. Anyone with shell access on this machine can reach the dashboard.
- Acceptable for single-operator workstation use. Don't expose to the public internet.

## API (for the future master dashboard or external tools)

The dashboard exposes a documented JSON interface. See `server.ts` for the contract:

- `GET /api/findings` — list of findings (filterable by `?status=<value>`)
- `GET /api/findings/:id` — single finding with full content
- `POST /api/findings/:id/status` — write back a status change
- `POST /api/findings/:id/comment` — append a comment

The master dashboard (deferred to v0.4.0) will discover labs by reading `<workspace>/labs/dashboard/.runtime/port` from each workspace in `vibeboss/.workspaces`.

## Status vocabulary

The dashboard understands four states, matching the finding template frontmatter:

- `pending-pickup` — awaiting partner disposition
- `applied` — approved and adopted by a build lead
- `revise-requested` — partner wants changes; comments explain what
- `rejected` — finding will not be adopted

## File layout

```
labs/dashboard/
├── README.md         ← this file
├── start.sh          ← entry point
├── server.ts         ← Bun HTTP server
├── package.json
├── public/
│   ├── index.html
│   ├── style.css
│   └── app.js
└── .runtime/
    └── port          ← actual bound port (written at startup, deleted on exit)
```

`.runtime/` is created at startup. It holds ephemeral process state and should be gitignored by the workspace install (workspace-level concern, not a dashboard concern).
