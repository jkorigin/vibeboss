# HQ Inbox

Boss's drop zone for incoming work and the per-counterparty conversation log. The lead checks this on every boot.

This inbox has **two layers**. Layer 1 is the legacy type-folder drop zone (operator-initiated, kept for backwards compatibility with v0.1.0 / v0.2.0 installs). Layer 2 is the bidirectional per-counterparty topology (the canonical pattern going forward).

---

## Layer 1 — Type-folder drop zone (legacy, backwards-compatible)

Operator-initiated traffic and self-assigned items land in type-folder subdirectories at the root of `inbox/`:

```
inbox/
  requests/    ← task requests (from partner or external triggers)
  chats/       ← freeform notes and context drops
  todos/       ← self-assigned work items
  processed/   ← completed items (moved here after done; flat directory)
```

**To add a task here:** create a `.md` file in `requests/` with the standard task format (see `hq/CLAUDE.md` crew system section).

These subdirectories are preserved unchanged from v0.1.0 / v0.2.0 so existing installs keep working. They are the right shape for one-way operator-into-HQ drops where there is no conversation, only a thing to do.

---

## Layer 2 — Bidirectional per-counterparty files (canonical)

For ongoing conversations between Boss and any named counterparty (the partner, a build lead, the labs research lead, etc.), use a per-counterparty file at the root of `inbox/`:

```
inbox/
  partner.md   ← conversation between Boss and the partner (both directions)
  banana.md    ← conversation between Boss and build lead Banana (both directions)
  carrot.md    ← conversation between Boss and build lead Carrot (both directions)
  labs.md      ← conversation between Boss and the labs research lead
  ...
```

### File naming

`inbox/<lowercase-counterparty-name>.md`. Examples: `inbox/partner.md`, `inbox/banana.md`, `inbox/labs.md`. One file per counterparty. Both parties read and append to the same file.

### Append-only

Newer messages go at the bottom. **Never delete or rewrite earlier messages.** History is the point. The single exception is the `Status:` line of a message — the recipient updates it in-place as the message moves through its lifecycle (see below).

### Message structure

Each message is a level-2 heading. Format:

```
## YYYY-MM-DD HH:MM — <FROM> → <TO> — THREAD-<slug>
**Status:** unread | seen | acted | escalated | closed
**Re:** <optional parent THREAD-<slug>>

<message body>
```

Notes:
- `FROM` and `TO` are lowercase counterparty names (`boss`, `partner`, `banana`, `labs`, etc.).
- `THREAD-<slug>` is a short kebab-case slug — `THREAD-portable-hooks`, `THREAD-q3-roadmap`, `THREAD-banana-dashboard-pass-1`. New thread = new slug.
- `Re:` is optional; include it on every reply to a prior thread. Cite the parent thread's slug verbatim.
- Body is freeform markdown.

### Status lifecycle

Status flows in one direction:

```
unread → seen → acted → (optionally) escalated → closed
```

- **unread** — just sent. The default when a message is appended.
- **seen** — the recipient has read it but hasn't acted yet.
- **acted** — the recipient has done the work or sent a response.
- **escalated** — bumped to a higher counterparty (typically partner) because the recipient cannot resolve alone.
- **closed** — no further action expected. Terminal state.

The recipient updates the `Status:` line **in-place** on the original message. This is the ONE exception to append-only — status changes only; the message body never changes.

### Thread IDs

Threads tie related messages together across the inbox. Conventions:

- New work topic → new slug (`THREAD-<short-slug>`). Pick a slug that reads as a topic, not a date.
- Reply → cite the parent slug in `Re:`. Same slug as the original message's `THREAD-<...>` heading.
- A thread can span counterparties — e.g. Boss escalates a banana-thread to partner. The slug stays; only `<FROM>`/`<TO>` and the file location change.

### Disposition-footer protocol

When a counterparty **acts** on a request and the result lands as an artifact (a decision file, a runlog entry, a deliverable, a commit), the actor MUST append a `## Disposition` block at the bottom of the originating thread message AND at the bottom of the produced artifact. Backlinks both directions; this is what closes the loop.

Format:

```
## Disposition
- **Verdict:** adopted | deferred | rejected
- **Result:** path/to/artifact (link)
- **Rationale:** <one sentence>
- **Closed thread:** THREAD-<slug>
```

The same `## Disposition` block lands at the bottom of the artifact (the decision file, the runlog entry, etc.) — so a reader of the artifact knows what thread spawned it WITHOUT reading the inbox, and a reader of the inbox knows what artifact resulted WITHOUT walking the artifact tree.

Update the parent message's `Status:` to `acted` (or `closed` if no follow-up expected) in the same pass.

---

## Worked example

A 3-message thread between partner and Boss, resulting in a decision file and disposition backlinks at both ends.

```markdown
## 2026-05-28 09:14 — partner → boss — THREAD-portable-hooks
**Status:** acted

The SessionStart hooks aren't portable across machines — my second laptop's `/bin/bash` is older than yours and the brace-expansion in `route.sh` fails silently. Can we make the hooks bash 3.2-safe? It's blocking my partner-side install.

## Disposition
- **Verdict:** adopted
- **Result:** decisions/2026-05-28-portable-hooks.md
- **Rationale:** Confirmed bash 3.2 is the macOS-default floor; rewrote hooks to avoid brace-expansion and `[[ =~` constructs.
- **Closed thread:** THREAD-portable-hooks

## 2026-05-28 09:31 — boss → partner — THREAD-portable-hooks
**Status:** seen
**Re:** THREAD-portable-hooks

Acknowledged — reproducing on a bash 3.2 shell now. Will land a fix today and document the floor in a decision file.

## 2026-05-28 14:47 — boss → partner — THREAD-portable-hooks
**Status:** unread
**Re:** THREAD-portable-hooks

Done. Hooks rewritten to bash 3.2 floor. Decision and rationale at `hq/decisions/2026-05-28-portable-hooks.md`. Tested on bash 3.2.57 (macOS default) and bash 5.x. Safe to install on the second laptop now.

## Disposition
- **Verdict:** adopted
- **Result:** decisions/2026-05-28-portable-hooks.md
- **Rationale:** Bash 3.2 floor confirmed and codified; hooks regression-tested on both shells.
- **Closed thread:** THREAD-portable-hooks
```

And at the bottom of `hq/decisions/2026-05-28-portable-hooks.md` the same `## Disposition` block is appended, pointing back to `THREAD-portable-hooks` in `inbox/partner.md`. The reader of either artifact can walk to the other in one hop.
