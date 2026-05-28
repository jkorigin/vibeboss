# Project Inbox

Drop zone for work addressed to this project's build lead. Same bidirectional topology as the HQ inbox — see `<workspace>/hq/inbox/README.md` for the canonical message format, status lifecycle, thread IDs, and disposition-footer protocol.

This file documents only the **scope** and **asymmetry** specific to a project inbox.

---

## Two layers (same as HQ)

### Layer 1 — Type-folder drop zone (legacy, backwards-compatible)

```
inbox/
  requests/    ← task requests dropped here by Boss or partner
  processed/   ← completed items (subdirectory per item, for artefact attachment)
```

Preserved for v0.1.0 / v0.2.0 compatibility. Kept for one-way drops where there is no conversation, only a task to do. Project `processed/` uses subdirectories (one per item) — intentional difference from HQ `inbox/processed/`, which is flat — so artefacts can travel with the completed item.

### Layer 2 — Bidirectional per-counterparty files (canonical)

```
inbox/
  boss.md      ← Boss writes here when dispatching work to this build lead
  partner.md   ← rare; if the partner addresses the build lead directly
```

Default counterparties are `boss.md` (the common case — Boss dispatching DOWN) and `partner.md` (rare — partner reaching past Boss to the build lead directly).

Use the same message format, status lifecycle, thread IDs, and disposition-footer protocol as the HQ inbox. See `<workspace>/hq/inbox/README.md`.

---

## The asymmetry: project inboxes are DOWN-only

HQ inbox holds bidirectional conversations — Boss talks to partner, partner talks to Boss, both messages land in `hq/inbox/partner.md`.

Project inboxes are **DOWN-only** by default. The build lead does NOT reply into its own project inbox. Instead, the build lead writes UP to `<workspace>/hq/inbox/<lead-name>.md` — that's where Boss reads the lead's response.

So a typical conversation looks like:

```
Boss dispatches:    projects/<name>/inbox/boss.md         (boss → <lead>)
<lead> replies:     hq/inbox/<lead-name>.md               (<lead> → boss)
Boss responds:      projects/<name>/inbox/boss.md         (boss → <lead>)
<lead> closes:      hq/inbox/<lead-name>.md               (<lead> → boss, with Disposition)
```

Threads (`THREAD-<slug>`) carry across the two files — the slug stays the same; only `<FROM>`, `<TO>`, and file location change. A reader following a thread walks back and forth between the project inbox and the HQ inbox using the slug as the anchor.

### Why down-only at project level

- One file per direction keeps the build lead's working surface narrow — the lead reads `inbox/boss.md` for inbound; doesn't need to keep both sides in one file.
- Boss's view stays in HQ — Boss reads all leads' UP traffic in `hq/inbox/<lead-name>.md` files, no need to walk into each project to read replies.
- Threads still close cleanly via the disposition-footer protocol — see HQ inbox README.

`partner.md` is the rare exception; if the partner reaches the build lead directly (and the build lead replies back into the same file), both directions can live here. Most projects will not need it.

---

## Pointers

- Canonical inbox protocol: `<workspace>/hq/inbox/README.md`
- Dispatch format (the body of a `boss → <lead>` message): `<workspace>/hq/CLAUDE.md` crew system section
- Disposition-footer protocol: `<workspace>/hq/inbox/README.md` (same backlink shape applies here)
