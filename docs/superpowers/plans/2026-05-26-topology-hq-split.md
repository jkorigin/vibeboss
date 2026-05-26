# Topology + HQ Split Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate Vibeboss's runtime state out of `~/ventures/vibeboss/` (the future OSS repo) into `~/ventures/vibeboss-workspace/{hq,labs,projects/}`, leaving `vibeboss/` as a pure framework-source folder.

**Architecture:** Pure filesystem migration — no code generation. Move `office/` and `research/` and `crew.yml` and `vibeboss-workspace/projects/<example-project>/` to new homes. Rewrite the two CLAUDE.md files (framework-reference vs boot-brief). Sweep all internal absolute-path references. Restart the running WhatsApp PA daemon from its new home and verify it still works end-to-end.

**Tech Stack:** Bash for moves, sed/grep for sweeps, Bun for restarting the daemon, curl for verifying the dashboard API.

**Pre-flight context:**
- Spec: [`docs/superpowers/specs/2026-05-26-topology-hq-split-design.md`](../specs/2026-05-26-topology-hq-split-design.md)
- Live daemon at port 3000, PID stored at `/tmp/wapa-direct.pid`, currently connected to WhatsApp as `<whatsapp-id>@c.us`
- No git repo on either side — rollback is via filesystem snapshot, not `git revert`
- `vibeboss-workspace/projects/` currently contains only `<example-project>/` and will be removed entirely

---

## Task 0: Pre-flight snapshot and daemon stop

**Files:**
- Backup: `/tmp/vibeboss-snapshot-2026-05-26/` (rollback safety net)
- Read: `/tmp/wapa-direct.pid` (PID of running WhatsApp PA daemon)

- [ ] **Step 0.1: Take a filesystem snapshot of both source and runtime trees**

Run:
```bash
mkdir -p /tmp/vibeboss-snapshot-2026-05-26
cp -R ~/ventures/vibeboss /tmp/vibeboss-snapshot-2026-05-26/vibeboss
cp -R ~/ventures/vibeboss-workspace/projects /tmp/vibeboss-snapshot-2026-05-26/vibeboss-workspace/projects
echo "snapshot size:" && du -sh /tmp/vibeboss-snapshot-2026-05-26/
```
Expected: snapshot dirs exist; size reported (likely 100–300 MB because of node_modules).

- [ ] **Step 0.2: Stop the running WhatsApp PA daemon**

Run:
```bash
if [ -f /tmp/wapa-direct.pid ]; then
  echo "stopping PID $(cat /tmp/wapa-direct.pid)…"
  kill $(cat /tmp/wapa-direct.pid) 2>/dev/null
fi
lsof -ti :3000 2>/dev/null | xargs -r kill 2>&1
pkill -f "<example-project>/data" 2>/dev/null
sleep 2
echo "port 3000 free?"; lsof -nP -iTCP:3000 -sTCP:LISTEN 2>&1 | head -3
```
Expected: no listener on port 3000.

- [ ] **Step 0.3: Note current state for the migration runlog**

Run:
```bash
echo "BEFORE migration:" > /tmp/vibeboss-migration-snapshot.txt
echo "--- vibeboss/ contents ---" >> /tmp/vibeboss-migration-snapshot.txt
ls ~/ventures/vibeboss/ >> /tmp/vibeboss-migration-snapshot.txt
echo "--- office/ contents ---" >> /tmp/vibeboss-migration-snapshot.txt
find ~/ventures/vibeboss/office -type f | head -50 >> /tmp/vibeboss-migration-snapshot.txt
echo "--- vibeboss-workspace/projects/ contents ---" >> /tmp/vibeboss-migration-snapshot.txt
ls ~/ventures/vibeboss-workspace/projects/ >> /tmp/vibeboss-migration-snapshot.txt
cat /tmp/vibeboss-migration-snapshot.txt
```
Expected: a record of the pre-migration tree shape for inclusion in the runlog entry.

---

## Task 1: Create the new directory tree

**Files:**
- Create: `~/ventures/vibeboss-workspace/hq/{runlog,decisions,inbox,skills,follow-ups,secrets,projects/<example-project>/decisions}`
- Create: `~/ventures/vibeboss-workspace/labs/research`
- Create: `~/ventures/vibeboss-workspace/projects`

- [ ] **Step 1.1: Create the full directory tree in one command**

Run:
```bash
mkdir -p \
  ~/ventures/vibeboss-workspace/hq/runlog \
  ~/ventures/vibeboss-workspace/hq/decisions \
  ~/ventures/vibeboss-workspace/hq/inbox/requests \
  ~/ventures/vibeboss-workspace/hq/inbox/chats \
  ~/ventures/vibeboss-workspace/hq/inbox/todos \
  ~/ventures/vibeboss-workspace/hq/inbox/processed \
  ~/ventures/vibeboss-workspace/hq/skills \
  ~/ventures/vibeboss-workspace/hq/follow-ups \
  ~/ventures/vibeboss-workspace/hq/secrets \
  ~/ventures/vibeboss-workspace/hq/projects/<example-project>/decisions \
  ~/ventures/vibeboss-workspace/labs/research \
  ~/ventures/vibeboss-workspace/projects
echo "tree created:"
find ~/ventures/vibeboss-workspace -type d | sort
```
Expected output (16 directories):
```
~/ventures/vibeboss-workspace
~/ventures/vibeboss-workspace/hq
~/ventures/vibeboss-workspace/hq/decisions
~/ventures/vibeboss-workspace/hq/follow-ups
~/ventures/vibeboss-workspace/hq/inbox
~/ventures/vibeboss-workspace/hq/inbox/chats
~/ventures/vibeboss-workspace/hq/inbox/processed
~/ventures/vibeboss-workspace/hq/inbox/requests
~/ventures/vibeboss-workspace/hq/inbox/todos
~/ventures/vibeboss-workspace/hq/projects
~/ventures/vibeboss-workspace/hq/projects/<example-project>
~/ventures/vibeboss-workspace/hq/projects/<example-project>/decisions
~/ventures/vibeboss-workspace/hq/runlog
~/ventures/vibeboss-workspace/hq/secrets
~/ventures/vibeboss-workspace/hq/skills
~/ventures/vibeboss-workspace/labs
~/ventures/vibeboss-workspace/labs/research
~/ventures/vibeboss-workspace/projects
```

---

## Task 2: Move the WhatsApp PA project code

**Files:**
- Move: `~/ventures/vibeboss-workspace/projects/<example-project>` → `~/ventures/vibeboss-workspace/projects/<example-project>`
- Remove: `~/ventures/vibeboss-workspace/projects/` (parent, now empty)

- [ ] **Step 2.1: Move the project directory wholesale**

Run:
```bash
mv ~/ventures/vibeboss-workspace/projects/<example-project> ~/ventures/vibeboss-workspace/projects/<example-project>
ls ~/ventures/vibeboss-workspace/projects/
echo "---"
ls ~/ventures/vibeboss-workspace/projects/<example-project>/ | head -15
```
Expected: `<example-project>` appears under `projects/`; its contents include `package.json`, `src/`, `public/`, `node_modules/`, `data/`, etc.

- [ ] **Step 2.2: Remove the now-empty `vibeboss-workspace/projects/` parent**

Run:
```bash
ls ~/ventures/vibeboss-workspace/projects/ 2>&1
rmdir ~/ventures/vibeboss-workspace/projects/
ls ~/ventures/vibeboss-workspace/projects/ 2>&1
```
Expected: first `ls` shows empty; `rmdir` succeeds; second `ls` returns "No such file or directory".

If `rmdir` complains the directory is non-empty (e.g. a hidden file slipped through), investigate before forcing — do NOT `rm -rf` blindly.

---

## Task 3: Move HQ runtime out of `vibeboss/office/`

**Files:**
- Move: `~/ventures/vibeboss-workspace/hq/STATE.md` → `~/ventures/vibeboss-workspace/hq/STATE.md`
- Move: `~/ventures/vibeboss-workspace/hq/runlog/*.md` → `~/ventures/vibeboss-workspace/hq/runlog/`
- Move: `~/ventures/vibeboss-workspace/hq/decisions/*.md` → `~/ventures/vibeboss-workspace/hq/decisions/`
- Move: `~/ventures/vibeboss-workspace/hq/inbox/processed/*` → `~/ventures/vibeboss-workspace/hq/inbox/processed/`
- Move: `~/ventures/vibeboss-workspace/hq/lessons.md` → `~/ventures/vibeboss-workspace/hq/lessons.md`
- Move: `~/ventures/vibeboss/crew.yml` → `~/ventures/vibeboss-workspace/hq/crew.yml`
- Remove: `~/ventures/vibeboss/office/` (now empty)

- [ ] **Step 3.1: Move STATE.md**

Run:
```bash
mv ~/ventures/vibeboss-workspace/hq/STATE.md ~/ventures/vibeboss-workspace/hq/STATE.md
ls -la ~/ventures/vibeboss-workspace/hq/STATE.md
```
Expected: STATE.md exists at new location.

- [ ] **Step 3.2: Move all runlog entries**

Run:
```bash
mv ~/ventures/vibeboss-workspace/hq/runlog/*.md ~/ventures/vibeboss-workspace/hq/runlog/
ls ~/ventures/vibeboss-workspace/hq/runlog/ | head -10
```
Expected: all `2026-05-25-*.md` and `2026-05-26-*.md` entries plus the `README.md` are listed in the new runlog dir.

- [ ] **Step 3.3: Move all decision files**

Run:
```bash
mv ~/ventures/vibeboss-workspace/hq/decisions/*.md ~/ventures/vibeboss-workspace/hq/decisions/
ls ~/ventures/vibeboss-workspace/hq/decisions/
```
Expected: `2026-05-25-build-locations-and-spawning.md`, `2026-05-25-workspace-reorg.md`, plus the `README.md` are in the new location.

- [ ] **Step 3.4: Move the inbox (processed/ only — requests/chats/todos are already empty)**

Run:
```bash
ls ~/ventures/vibeboss-workspace/hq/inbox/
mv ~/ventures/vibeboss-workspace/hq/inbox/processed/* ~/ventures/vibeboss-workspace/hq/inbox/processed/ 2>/dev/null
mv ~/ventures/vibeboss-workspace/hq/inbox/README.md ~/ventures/vibeboss-workspace/hq/inbox/README.md 2>/dev/null
ls ~/ventures/vibeboss-workspace/hq/inbox/processed/
```
Expected: `2026-05-25-kickoff/` subdir appears under the new processed/ dir.

- [ ] **Step 3.5: Move lessons.md**

Run:
```bash
mv ~/ventures/vibeboss-workspace/hq/lessons.md ~/ventures/vibeboss-workspace/hq/lessons.md
head -3 ~/ventures/vibeboss-workspace/hq/lessons.md
```
Expected: file moved; first lines show "# Vibeboss — LESSONS".

- [ ] **Step 3.6: Move crew.yml**

Run:
```bash
mv ~/ventures/vibeboss/crew.yml ~/ventures/vibeboss-workspace/hq/crew.yml
head -5 ~/ventures/vibeboss-workspace/hq/crew.yml
```
Expected: file moved; first lines show the crew header.

- [ ] **Step 3.7: Verify office/ is empty, then remove it**

Run:
```bash
find ~/ventures/vibeboss/office -type f 2>/dev/null
```
Expected: empty output. If any files remain, INVESTIGATE and move them before continuing.

Then:
```bash
rm -rf ~/ventures/vibeboss/office
ls ~/ventures/vibeboss/office 2>&1
```
Expected: "No such file or directory".

---

## Task 4: Move research artifacts to labs/

**Files:**
- Move: `~/ventures/vibeboss-workspace/labs/research/cc-app-orchestration.md` → `~/ventures/vibeboss-workspace/labs/research/cc-app-orchestration.md`
- Move: `~/ventures/vibeboss-workspace/labs/research/README.md` → `~/ventures/vibeboss-workspace/labs/research/README.md`
- Remove: `~/ventures/vibeboss-workspace/labs/research/`

- [ ] **Step 4.1: Move research files and remove the empty source dir**

Run:
```bash
mv ~/ventures/vibeboss-workspace/labs/research/*.md ~/ventures/vibeboss-workspace/labs/research/
ls ~/ventures/vibeboss-workspace/labs/research/
find ~/ventures/vibeboss-workspace/labs/research -type f 2>/dev/null
rm -rf ~/ventures/vibeboss-workspace/labs/research
ls ~/ventures/vibeboss-workspace/labs/research 2>&1
```
Expected: research markdowns live under labs/research/; old vibeboss-workspace/labs/research/ no longer exists.

---

## Task 5: Write the boot-brief CLAUDE.md in HQ

**Files:**
- Create: `~/ventures/vibeboss-workspace/hq/CLAUDE.md`

- [ ] **Step 5.1: Write the HQ boot-brief CLAUDE.md**

This file replaces the boot-sequence portion of `vibeboss/CLAUDE.md`. It contains identity, current authorizations, boot sequence, and references to the framework docs at `vibeboss/CLAUDE.md` for pattern explanations.

Write to `~/ventures/vibeboss-workspace/hq/CLAUDE.md`:

```markdown
# Vibeboss — HQ (runtime boot brief)

You are **Boss**, the venture lead. This is your home: `~/ventures/vibeboss-workspace/hq/`. The framework source — the OSS code you publish and edit only when explicitly working on Vibeboss-the-product — lives at `~/ventures/vibeboss/`.

Address the operator as **partner** (LESSON-001).

## Boot sequence

When a session starts in this directory (or partner says `boot`):

1. Read `STATE.md` (master state across projects).
2. List `runlog/` filenames (don't read all — just know what exists; read the most-recent one for last-session context).
3. List `decisions/` filenames.
4. List `inbox/{requests,chats,todos}` for new work.
5. List `projects/` for known projects.
6. Read `lessons.md` end-to-end before any non-trivial decision.

Output the boot brief in this format:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  VIBEBOSS HQ — online
  {current date}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Then:
- **Phase:** current phase from STATE.md
- **State:** one-liner from STATE.md
- **Last session:** most-recent runlog title + date
- **Inbox:** new items grouped by subfolder, or `empty`
- **Active projects:** from `projects/` subdir names + their per-project STATE.md headlines
- **Open questions:** from STATE.md "Open questions" section
- **Next:** from STATE.md "Next" section

End with: `Ready. What are we working on?` (or `Inbox has N item(s) — start there?` if non-empty).

## Routing rule

When you write memory:
- Cross-cutting lessons → `hq/lessons.md`
- Project-specific lessons → `hq/projects/<name>/lessons.md`
- Cross-cutting decisions → `hq/decisions/`
- Project-specific decisions → `hq/projects/<name>/decisions/`
- Runlog (any session) → `hq/runlog/YYYY-MM-DD-<slug>.md` (chronological master)
- Project state → `hq/projects/<name>/STATE.md`
- Master state → `hq/STATE.md`

When unclear which project a piece of memory belongs to — ASK (LESSON-003).

## Current authorizations

You may read/write inside these directories. Outside these is read-only at best, never write.

| Path | Purpose |
|---|---|
| `~/ventures/vibeboss-workspace/hq/` | This HQ — your home. |
| `~/ventures/vibeboss-workspace/labs/` | Research-labs project workspace. |
| `~/ventures/vibeboss-workspace/projects/<example-project>/` | Partner's personal WhatsApp PA. |
| `~/ventures/vibeboss/` | Framework source. Edit only when explicitly working on the OSS-bound product. |

When a new partner-owned project is authorized, add a row here and write a decision file.

## Boundaries

- **Never write inside <other-project>** (`~/ventures/<other-project>/`). Mail-drop only.
- **Never write to other ventures** unless they appear in "Current authorizations".
- **Secrets** live in `hq/secrets/` — never echo, always reference by path, never commit.
- **The framework directory `~/ventures/vibeboss/` is OSS-bound** — anything written there must be free of business-internal references and partner-specific runtime state.

## Framework reference

For the *patterns* Vibeboss publishes (LESSONS-as-hard-gates, runlog discipline, decisions discipline, spawning model, dev workflow), read `~/ventures/vibeboss/CLAUDE.md`. That doc is what an OSS clone-r reads to understand Vibeboss; this doc is your runtime memory of how to operate one.
```

Expected: file exists; partner can read it; on next session boot, this is the file Claude Code auto-loads from cwd.

---

## Task 6: Rewrite vibeboss/CLAUDE.md as the framework reference

**Files:**
- Modify: `~/ventures/vibeboss/CLAUDE.md` (full rewrite)
- Modify: `~/ventures/vibeboss/AGENTS.md` (symlink remains pointing to CLAUDE.md)

- [ ] **Step 6.1: Snapshot the existing vibeboss/CLAUDE.md (for reference during rewrite)**

Run:
```bash
cp ~/ventures/vibeboss/CLAUDE.md /tmp/vibeboss-old-CLAUDE.md
wc -l /tmp/vibeboss-old-CLAUDE.md
```
Expected: file copied; line count shown (~150–200 lines).

- [ ] **Step 6.2: Write the new framework-reference CLAUDE.md**

Replace `~/ventures/vibeboss/CLAUDE.md` with this content (full rewrite — do not preserve any boot-sequence / runtime-specific text; that all lives in HQ now):

```markdown
# Vibeboss — Framework Reference

This is the OSS source for **Vibeboss**, an autonomous-AI operating system for vibe coders (non-technical 40+ business operators). This file documents the *patterns* Vibeboss publishes; it is the entry point for anyone cloning this repository.

If you are running a Vibeboss installation, your runtime memory lives in a separate workspace directory (not here). See [docs/runtime-layout.md](docs/runtime-layout.md) — short version: source goes here (this repo), all runtime state goes to a sibling `vibeboss-workspace/` directory you create on first init.

## What Vibeboss is

A toolkit of primitives that lets a non-technical operator give an autonomous-AI agent a goal and walk away, while the agent:
- Maintains structural memory of past decisions (no drift)
- Surfaces only when it genuinely needs the human
- Records its work for audit
- Refuses to drift past structural guardrails (LESSONS as hard-gates)

Inspired by patterns developed in the realm of `~/ventures/<other-project>/`-style multi-venture offices, packaged for external use.

## The published primitives

1. **HQ + per-project memory** — separation of cross-cutting memory (lessons, decisions, runlog) from per-project memory (`hq/projects/<name>/`). See [docs/superpowers/specs/2026-05-26-topology-hq-split-design.md](docs/superpowers/specs/2026-05-26-topology-hq-split-design.md) for the canonical design.
2. **Runlog discipline** — every meaningful work session ends with an append-only runlog entry capturing goal, what-happened, commands, files-touched, state-at-end, next.
3. **Decisions discipline** — non-trivial choices land as immutable `YYYY-MM-DD-<slug>.md` decision files. Supersession via new files, never overwrite.
4. **LESSONS as hard-gates** — operator corrections become structural rules re-read at the top of every session. Violation gets logged; repeat violations indicate the rule wording needs revision.
5. **Spawning model** — a Main agent (talks to operator, never builds) dispatches Builder agents (bounded tasks, spawnable recursively) and a Research agent (investigates and reports). Implemented at small scale in the WhatsApp PA example app.
6. **Inbox protocol** — operator drop-zone with `requests/`, `chats/`, `todos/`, `processed/` subfolders. On every boot the agent surfaces new items.
7. **Brand discipline** — internal docs may be technical; anything destined for the public release is non-business-internal and uses product-native vocabulary.

## Repository layout

```
vibeboss/
├── README.md             ← public one-pager
├── LICENSE               ← Apache 2.0
├── NOTICE                ← attribution per Apache 2.0
├── CLAUDE.md             ← this file
├── AGENTS.md             ← symlink to CLAUDE.md (Codex compatibility)
├── crew.yml.template     ← template; copied to hq/crew.yml on first install
├── docs/                 ← framework documentation
│   └── superpowers/
│       ├── specs/        ← design specs for each pattern
│       └── plans/        ← implementation plans
└── (framework code in Phase 1+)
```

## Phase

Vibeboss is in **Phase 0 — Feasibility Investigation**. No framework code yet. The current artifacts are:
- Patterns under documentation (this file, docs/)
- One example partner-app validating the patterns at small scale (the WhatsApp PA, runtime-only)
- Research artifacts under `vibeboss-workspace/labs/research/` (CC orchestration feasibility)

Phase 1 begins the framework code (Main/Builder/Research agents as a runnable system, dashboard scaffold, `vibeboss init` flow). Phase 2 is the public-repo cut.

## License

Apache License 2.0. Copyright jkorigin. `NOTICE` preserves attribution through forks. Commercial layers (paid dashboard, hosted service) are a Phase 2+ decision and not pre-committed.

## Contributing

Not yet open to external contribution. This boundary will move when Phase 2 lands the public repo.

## Where the agent actually runs

If you cloned this repo and want to *use* Vibeboss (not just read about it), the workflow is:
1. Clone this repo somewhere (e.g. `~/ventures/vibeboss/`).
2. Run the init script (forthcoming in subsystem G) which scaffolds `~/ventures/vibeboss-workspace/{hq,labs,projects}` alongside.
3. Start a Claude Code session in `~/ventures/vibeboss-workspace/hq/`. The boot brief there does the rest.

Until subsystem G is shipped, init is manual — see [docs/superpowers/specs/2026-05-26-topology-hq-split-design.md](docs/superpowers/specs/2026-05-26-topology-hq-split-design.md) for the layout.
```

Run:
```bash
wc -l ~/ventures/vibeboss/CLAUDE.md
grep -c "boot sequence" ~/ventures/vibeboss/CLAUDE.md
grep -c "office/" ~/ventures/vibeboss/CLAUDE.md
```
Expected: line count ~80; `boot sequence` count 0 (boot sequence is HQ's job now); `office/` count 0 (the office/ pattern moved to hq/).

- [ ] **Step 6.3: Verify AGENTS.md symlink still resolves**

Run:
```bash
ls -la ~/ventures/vibeboss/AGENTS.md
cat ~/ventures/vibeboss/AGENTS.md | head -3
```
Expected: AGENTS.md is a symlink to CLAUDE.md; its content starts with "# Vibeboss — Framework Reference".

If AGENTS.md doesn't exist (no original symlink), create it:
```bash
cd ~/ventures/vibeboss && ln -s CLAUDE.md AGENTS.md
ls -la ~/ventures/vibeboss/AGENTS.md
```

---

## Task 7: Sweep all internal references to old paths

**Files:**
- Read-and-update: `**/*.md`, `**/*.json`, `**/*.yml`, `**/*.js` under both `vibeboss/` and `vibeboss-workspace/`
- Skipped: `node_modules/`, `data/` (LocalAuth session), `logs/` (jsonl logs)

- [ ] **Step 7.1: Inventory all stale references**

Run:
```bash
echo "=== references to vibeboss-workspace/projects ==="
grep -rln "vibeboss-workspace/projects" \
  ~/ventures/vibeboss ~/ventures/vibeboss-workspace \
  --include="*.md" --include="*.json" --include="*.yml" --include="*.js" \
  2>/dev/null | grep -v node_modules | grep -v "/data/" | head -50

echo
echo "=== references to vibeboss/office ==="
grep -rln "vibeboss/office\|office/lessons\|office/runlog\|office/decisions\|office/inbox\|office/handoff" \
  ~/ventures/vibeboss ~/ventures/vibeboss-workspace \
  --include="*.md" --include="*.json" --include="*.yml" --include="*.js" \
  2>/dev/null | grep -v node_modules | grep -v "/data/" | head -50

echo
echo "=== references to vibeboss-workspace/labs/research ==="
grep -rln "vibeboss-workspace/labs/research" \
  ~/ventures/vibeboss ~/ventures/vibeboss-workspace \
  --include="*.md" --include="*.json" --include="*.yml" --include="*.js" \
  2>/dev/null | grep -v node_modules | grep -v "/data/" | head -50
```
Expected: a list of files (mostly under `hq/runlog/`, `hq/decisions/`, the new spec/plan files, and possibly some inside `projects/<example-project>/`).

- [ ] **Step 7.2: Apply path replacements with `sed`**

For each match family found above, run the corresponding sed transform across all relevant files. Order matters — most-specific first.

Run:
```bash
# Most-specific first: vibeboss-workspace/projects/<example-project> → vibeboss-workspace/projects/<example-project>
find ~/ventures/vibeboss ~/ventures/vibeboss-workspace \
  \( -name "*.md" -o -name "*.json" -o -name "*.yml" -o -name "*.js" \) \
  -not -path "*/node_modules/*" -not -path "*/data/*" \
  -exec sed -i '' 's|vibeboss-workspace/projects/<example-project>|vibeboss-workspace/projects/<example-project>|g' {} +

# vibeboss/office/X → vibeboss-workspace/hq/X (specific subdirs)
find ~/ventures/vibeboss ~/ventures/vibeboss-workspace \
  \( -name "*.md" -o -name "*.json" -o -name "*.yml" -o -name "*.js" \) \
  -not -path "*/node_modules/*" -not -path "*/data/*" \
  -exec sed -i '' \
    -e 's|vibeboss-workspace/hq/STATE.md|vibeboss-workspace/hq/STATE.md|g' \
    -e 's|vibeboss-workspace/hq/runlog|vibeboss-workspace/hq/runlog|g' \
    -e 's|vibeboss-workspace/hq/decisions|vibeboss-workspace/hq/decisions|g' \
    -e 's|vibeboss-workspace/hq/inbox|vibeboss-workspace/hq/inbox|g' \
    -e 's|vibeboss-workspace/hq/lessons.md|vibeboss-workspace/hq/lessons.md|g' \
    -e 's|vibeboss-workspace/hq/secrets|vibeboss-workspace/hq/secrets|g' \
    -e 's|vibeboss-workspace/labs/research|vibeboss-workspace/labs/research|g' \
    {} +

# Relative office/ refs in old runlog / decision entries
find ~/ventures/vibeboss-workspace/hq/runlog ~/ventures/vibeboss-workspace/hq/decisions \
  -name "*.md" \
  -exec sed -i '' \
    -e 's|office/lessons\.md|../lessons.md|g' \
    -e 's|office/runlog/|../runlog/|g' \
    -e 's|office/decisions/|../decisions/|g' \
    -e 's|office/handoff/STATE\.md|../STATE.md|g' \
    -e 's|office/inbox/|../inbox/|g' \
    {} +
```
Expected: sed completes silently for all files; nothing errors.

- [ ] **Step 7.3: Re-inventory to verify the sweep**

Run the same grep commands from Step 7.1 again:
```bash
grep -rln "vibeboss-workspace/projects" \
  ~/ventures/vibeboss ~/ventures/vibeboss-workspace \
  --include="*.md" --include="*.json" --include="*.yml" --include="*.js" \
  2>/dev/null | grep -v node_modules | grep -v "/data/"

grep -rln "vibeboss/office\|vibeboss-workspace/labs/research" \
  ~/ventures/vibeboss ~/ventures/vibeboss-workspace \
  --include="*.md" --include="*.json" --include="*.yml" --include="*.js" \
  2>/dev/null | grep -v node_modules | grep -v "/data/"
```
Expected: empty output, OR only matches inside this very design-doc/plan that intentionally references the old paths historically.

If anything else matches, inspect each match and decide: fix manually or leave (e.g. comments inside snapshot files at `/tmp/`).

---

## Task 8: Bootstrap per-project memory subdir for <example-project>

**Files:**
- Create: `~/ventures/vibeboss-workspace/hq/projects/<example-project>/STATE.md`
- Create: `~/ventures/vibeboss-workspace/hq/projects/<example-project>/notes.md`
- Create: `~/ventures/vibeboss-workspace/hq/projects/<example-project>/lessons.md`

- [ ] **Step 8.1: Write the <example-project> project-specific STATE.md**

Write to `~/ventures/vibeboss-workspace/hq/projects/<example-project>/STATE.md`:

```markdown
# <example-project> — project STATE

**Last updated:** 2026-05-26
**Status:** v1.0.2 — live, connected, allowlisted-and-sending

## Snapshot

- Daemon location: `~/ventures/vibeboss-workspace/projects/<example-project>/`
- WhatsApp account: `<whatsapp-id>@c.us`
- Dashboard: http://localhost:3000 (Bun.serve, WebSocket live log)
- Model: Sonnet 4.6 (`claude-sonnet-4-6`), budget cap $0.15/reply
- Dry-run: false (sending real replies)
- Allowlist: `["<whatsapp-id>@lid"]` (<other-project>)
- Subprocess timeout: 120s (was 45s, bumped after early timeouts on Sonnet cold-cache)

## Hardening notes

- Modern user-agent (Chrome 130) overrides whatsapp-web.js's stale Chrome-101 default
- `--disable-blink-features=AutomationControlled` hides Puppeteer's navigator.webdriver flag
- `webVersionCache` pinned to `wppconnect-team/wa-version/main/html/2.3000.1015901307.html`
- `puppeteer.headless: true` (config-toggleable; flip false if WA Web rejects QR again)
- Modern Node prepended to subprocess PATH (avoids Node-12 SessionEnd hook crash)
- `CLAUDE_CODE_SIMPLE` env var explicitly deleted before subprocess spawn (it's the `--bare` equivalent and strips keychain auth)

## Open issues / follow-ups

- YAML comment-stripping on dashboard PATCH (acceptable trade; README is canonical)
- macOS-only paths (Chrome at /Applications, NVM paths) — portability is a Phase 1+ concern
- No daemonization (Ctrl-C to stop; launchd plist is a v1.x optional improvement)
- No voice-note / image / sticker handling — text-only

## Recent runlogs (chronological, in hq/runlog/)

- 2026-05-25 — WhatsApp PA v0 first ship
- 2026-05-25 — Workspace reorg to vibeboss-workspace/projects/ (superseded by topology migration)
- 2026-05-25 — Dashboard v1 ship
- 2026-05-25 — "No QR" UX fix
- 2026-05-26 — QR-scan rejection / bot-detection hardening
- 2026-05-26 — Topology migration to vibeboss-workspace/ (this migration)
```

Run:
```bash
ls -la ~/ventures/vibeboss-workspace/hq/projects/<example-project>/STATE.md
```
Expected: file exists.

- [ ] **Step 8.2: Write stub notes.md and lessons.md for the project**

Write to `~/ventures/vibeboss-workspace/hq/projects/<example-project>/notes.md`:

```markdown
# <example-project> — running notes

Project-specific running notes. Edit freely. Things that don't rise to LESSON or decision level but worth remembering.

- (empty for now)
```

Write to `~/ventures/vibeboss-workspace/hq/projects/<example-project>/lessons.md`:

```markdown
# <example-project> — project LESSONS

Project-specific structural rules. Re-read before any non-trivial change to this project. Format mirrors `hq/lessons.md` (LESSON-NNN, Rule, Why, How to apply).

## WA-PA-LESSON-001 — Bot-detection hardening is load-bearing
**Rule:** Never remove the three anti-detection measures in `src/whatsapp.js`: modern user-agent, `--disable-blink-features=AutomationControlled`, and the pinned `webVersionCache` remote path. They were added because WhatsApp Web rejected the scan with "expired/failed" otherwise.
**Why:** WhatsApp Web actively fingerprints Puppeteer sessions. The defaults whatsapp-web.js ships are detectable.
**How to apply:** Before editing `makeClient()`, re-read this rule. Removing any of the three is a regression that the partner will discover the next time they wipe `data/auth` and re-scan.

## WA-PA-LESSON-002 — Subscription auth requires keychain reads, so don't use --bare
**Rule:** Never spawn the Claude subprocess with `--bare` or with `CLAUDE_CODE_SIMPLE=1` in env. Both strip keychain reads, which kills subscription auth.
**Why:** Partner uses their CC subscription, not API keys. The subscription token is in macOS keychain. `--bare` skips the keychain by design (per CLI help).
**How to apply:** `src/agent.js` explicitly `delete env.CLAUDE_CODE_SIMPLE` before spawn. Don't add `--bare` to args. If introducing a new flag, check the CLI help first to confirm it doesn't bypass keychain.
```

Run:
```bash
ls -la ~/ventures/vibeboss-workspace/hq/projects/<example-project>/
```
Expected: 3 files (STATE.md, notes.md, lessons.md) + 1 dir (decisions/) — total ~4 entries.

---

## Task 9: Update master STATE.md and write migration runlog

**Files:**
- Modify: `~/ventures/vibeboss-workspace/hq/STATE.md` (update topology-related sections)
- Create: `~/ventures/vibeboss-workspace/hq/runlog/2026-05-26-topology-migration.md`

- [ ] **Step 9.1: Update hq/STATE.md so its paths reflect the new layout**

The sweep in Task 7 should have fixed most paths. Read `hq/STATE.md` end-to-end and confirm:
- "Phase" reflects current state
- "Open questions" no longer mentions boundary-policy (resolved)
- "Recently closed" has an entry for the topology migration
- "Next" lists subsystems B–G as the upcoming work

Run:
```bash
head -30 ~/ventures/vibeboss-workspace/hq/STATE.md
grep -n "office/" ~/ventures/vibeboss-workspace/hq/STATE.md
grep -n "vibeboss-workspace/projects/" ~/ventures/vibeboss-workspace/hq/STATE.md
```
Expected: header reflects current phase; no leftover `office/` or `vibeboss-workspace/projects/` references (or if a few remain, they're historical mentions in context — review each).

Make targeted edits as needed:
- Add to "Recently closed": `- 2026-05-26 — Topology + HQ split shipped. Runtime moved out of vibeboss/. See runlog/2026-05-26-topology-migration.md.`
- Add to "Next" at the top: `0. **Subsystem B** — Write the dev-workflow skill into hq/skills/. Next in the A→G sequence.`

- [ ] **Step 9.2: Write the migration runlog entry**

Write to `~/ventures/vibeboss-workspace/hq/runlog/2026-05-26-topology-migration.md`:

```markdown
# Topology + HQ split — migration runlog

**Phase:** Phase 0 — Feasibility / Vibeboss-the-framework, subsystem A complete
**Goal:** Move all runtime state out of `~/ventures/vibeboss/` into `~/ventures/vibeboss-workspace/{hq,labs,projects/}` so the source repo stays pure framework code (Apache-2.0 OSS bound) and runtime memory has a clean per-project home.

## What happened

Executed the migration per [docs/superpowers/plans/2026-05-26-topology-hq-split.md](../../../vibeboss/docs/superpowers/plans/2026-05-26-topology-hq-split.md). 9 tasks in order:

1. Snapshot taken at `/tmp/vibeboss-snapshot-2026-05-26/`; daemon stopped.
2. New tree created at `~/ventures/vibeboss-workspace/{hq, labs, projects}/...`
3. `<example-project>/` moved from `~/ventures/vibeboss-workspace/projects/` into `~/ventures/vibeboss-workspace/projects/`. Old parent `vibeboss-workspace/projects/` removed.
4. All `office/` contents moved into `hq/` with appropriate restructuring (STATE, runlog/*, decisions/*, inbox/processed/*, lessons.md, secrets/). `office/` itself removed.
5. `research/` contents moved into `labs/research/`. Old `research/` removed.
6. New HQ boot-brief CLAUDE.md written.
7. Framework `vibeboss/CLAUDE.md` rewritten as the OSS reference doc (removed all boot-sequence and per-installation content).
8. Path sweep applied via `sed` across all `*.md`/`*.json`/`*.yml`/`*.js` outside `node_modules` and `data/`. Re-inventory came back clean.
9. Per-project memory subdir bootstrapped for <example-project> with project STATE/notes/lessons.
10. Master STATE.md updated and this runlog entry written.

Daemon restarted from new path; verified WhatsApp connection re-established via stored auth, dashboard accessible at http://localhost:3000, log pane shows live events.

## Commands run

(Full command sequence is in the migration plan at `vibeboss/docs/superpowers/plans/2026-05-26-topology-hq-split.md`. Highlight commands:)

```
mkdir -p ~/ventures/vibeboss-workspace/{hq/{runlog,decisions,inbox,skills,follow-ups,secrets,projects/<example-project>/decisions},labs/research,projects}
mv ~/ventures/vibeboss-workspace/projects/<example-project>  ~/ventures/vibeboss-workspace/projects/<example-project>
rmdir ~/ventures/vibeboss-workspace/projects
mv ~/ventures/vibeboss-workspace/hq/STATE.md  ~/ventures/vibeboss-workspace/hq/STATE.md
mv ~/ventures/vibeboss-workspace/hq/runlog/*.md  ~/ventures/vibeboss-workspace/hq/runlog/
mv ~/ventures/vibeboss-workspace/hq/decisions/*.md  ~/ventures/vibeboss-workspace/hq/decisions/
mv ~/ventures/vibeboss-workspace/hq/inbox/processed/*  ~/ventures/vibeboss-workspace/hq/inbox/processed/
mv ~/ventures/vibeboss-workspace/hq/lessons.md  ~/ventures/vibeboss-workspace/hq/lessons.md
mv ~/ventures/vibeboss/crew.yml  ~/ventures/vibeboss-workspace/hq/crew.yml
rm -rf ~/ventures/vibeboss/office  ~/ventures/vibeboss-workspace/labs/research
mv ~/ventures/vibeboss-workspace/labs/research/*.md  ~/ventures/vibeboss-workspace/labs/research/
# + sed path sweep across all docs (full command in plan)
# + daemon restart
```

## Files touched

- Created: ~/ventures/vibeboss-workspace/ (entire tree)
- Created: ~/ventures/vibeboss-workspace/hq/CLAUDE.md (boot brief, fresh)
- Created: ~/ventures/vibeboss-workspace/hq/projects/<example-project>/{STATE.md, notes.md, lessons.md}
- Modified: ~/ventures/vibeboss/CLAUDE.md (full rewrite, framework reference)
- Modified: ~/ventures/vibeboss-workspace/hq/STATE.md (paths + new closed entry + new Next item)
- Moved: ~80 files from vibeboss/office/, vibeboss-workspace/labs/research/, vibeboss-workspace/projects/<example-project>/ to new locations
- Removed: vibeboss/office/, vibeboss-workspace/labs/research/, vibeboss-workspace/projects/

## State at end

- Source tree (`~/ventures/vibeboss/`) is OSS-pure: README, LICENSE, NOTICE, CLAUDE.md, AGENTS.md symlink, crew.yml.template, docs/, .gitignore. No runtime state.
- Runtime tree (`~/ventures/vibeboss-workspace/`) holds: hq/ (16 dirs + boot brief + STATE + lessons + master crew.yml), labs/ (with research/), projects/ (with <example-project>/).
- WhatsApp PA daemon running from new path. Dashboard live. WA connection healthy (stored auth survived the move).
- All path sweeps cleaned; new and old grep inventories show zero stale references.
- Subsystem A complete. Subsystems B–G still pending in the A→G order.

## Next

1. **Subsystem B** — Write the dev-workflow skill (research → experiment → validate → adopt → build → test → 3-round bug-fix → fresh-agent review → 3 tightening → human gate) into `hq/skills/dev-workflow/SKILL.md`. Brainstorm, spec, plan, execute.
2. **Subsystem C** — Crew system (per-project named agents, naming theme, registry format in crew.yml).
3. Etc per the original 7-subsystem sequence.
```

Run:
```bash
ls -la ~/ventures/vibeboss-workspace/hq/runlog/2026-05-26-topology-migration.md
```
Expected: file exists.

---

## Task 10: Restart the WhatsApp PA daemon from its new path and verify

**Files:**
- Run: `~/ventures/vibeboss-workspace/projects/<example-project>/src/index.js` (via bun)
- Verify: http://localhost:3000/api/state

- [ ] **Step 10.1: Restart daemon from new location**

Run:
```bash
cd ~/ventures/vibeboss-workspace/projects/<example-project> && nohup bun start > /tmp/wapa-direct.log 2>&1 &
echo $! > /tmp/wapa-direct.pid
disown
echo "PID: $(cat /tmp/wapa-direct.pid)"
```
Expected: PID printed. Daemon starting in background.

- [ ] **Step 10.2: Wait for connection (uses stored auth — should be fast)**

Run:
```bash
until curl -s http://127.0.0.1:3000/api/state 2>/dev/null | grep -q '"connected":true'; do sleep 2; done
echo "=== CONNECTED ==="
curl -s http://127.0.0.1:3000/api/state | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); c=d.get('connection',{}); print('connected:', c.get('connected'), '| me:', c.get('me'), '| push_name:', c.get('push_name'), '| status:', d.get('wa_status'))"
```
Expected: within 30-60s, output shows `connected: True | me: <whatsapp-id>@c.us | push_name: <name> | status: ready`.

If it doesn't reconnect:
- Check `tail -30 /tmp/wapa-direct.log` for errors
- Check that `data/auth/` survived the move (`ls ~/ventures/vibeboss-workspace/projects/<example-project>/data/`)
- If auth is broken, partner will need to re-scan QR (acceptable but worth flagging)

- [ ] **Step 10.3: Smoke-test dashboard**

Run:
```bash
echo "=== /api/config ==="; curl -s http://127.0.0.1:3000/api/config | head -c 200
echo
echo "=== /api/persona length ==="; curl -s http://127.0.0.1:3000/api/persona | wc -c
echo "=== /api/knowledge length ==="; curl -s http://127.0.0.1:3000/api/knowledge | wc -c
```
Expected: config JSON returned; persona ~2000 chars; knowledge ~1700 chars.

- [ ] **Step 10.4: Optional — verify a real message round-trips**

Have partner send a test message from another number (<other-project>, the allowlisted chat). Watch `tail -f /tmp/wapa-direct.log` for `[SEND] <other-project> «...» → «...» (Nms, $N)` line. If it lands within ~30s, the migration is fully validated.

---

## Task 11: Final validation gates + cleanup

**Files:**
- Run all validation commands from the spec's "Validation gates" section.

- [ ] **Step 11.1: Run the validation gates**

Run each, capture results:
```bash
echo "GATE 1: vibeboss-workspace/projects references remaining?"
find ~/ventures/vibeboss ~/ventures/vibeboss-workspace -type f \
  -not -path "*/node_modules/*" -not -path "*/data/*" \
  | xargs grep -l "vibeboss-workspace/projects" 2>/dev/null
# Expected: empty (or only this plan / spec docs that intentionally reference history)

echo
echo "GATE 2: 'office/' references in framework source?"
find ~/ventures/vibeboss -type f -not -path "*/node_modules/*" \
  | xargs grep -l "office/" 2>/dev/null
# Expected: empty

echo
echo "GATE 3: vibeboss/office/ should not exist"
ls ~/ventures/vibeboss/office 2>&1
# Expected: "No such file or directory"

echo
echo "GATE 4: HQ shape correct?"
ls ~/ventures/vibeboss-workspace/hq/
# Expected: CLAUDE.md, STATE.md, crew.yml, lessons.md + the directories from the spec

echo
echo "GATE 5: Daemon listening + connected?"
curl -s http://127.0.0.1:3000/api/state | grep -o '"connected":[^,]*'
# Expected: "connected":true

echo
echo "GATE 6: Dashboard renders?"
curl -sI http://127.0.0.1:3000/ | head -1
# Expected: HTTP/1.1 200 OK

echo
echo "GATE 7: Boot brief in HQ?"
head -5 ~/ventures/vibeboss-workspace/hq/CLAUDE.md
# Expected: starts with "# Vibeboss — HQ"

echo
echo "GATE 8: Framework reference rewritten?"
head -5 ~/ventures/vibeboss/CLAUDE.md
# Expected: starts with "# Vibeboss — Framework Reference"
```

All gates pass → migration complete. Report results.

- [ ] **Step 11.2: Delete the rollback snapshot (optional, only after confidence)**

If everything works and partner confirms, free the disk:
```bash
ls -d /tmp/vibeboss-snapshot-2026-05-26
du -sh /tmp/vibeboss-snapshot-2026-05-26
# rm -rf /tmp/vibeboss-snapshot-2026-05-26  # uncomment only after partner says "all good, drop snapshot"
```

Keep the snapshot at least until subsystem B work begins, in case any latent reference bug surfaces.

---

## Done criteria recap

The migration is complete when:

- [ ] All 11 tasks above are checked off.
- [ ] All 8 validation gates in Task 11.1 pass.
- [ ] Daemon at `~/ventures/vibeboss-workspace/projects/<example-project>/` is connected to WhatsApp and dashboard responds at port 3000.
- [ ] Partner has tested booting a fresh Claude Code session from `~/ventures/vibeboss-workspace/hq/` and the boot brief loads correctly.
- [ ] No stale references to old paths remain (per Task 7.3 grep).
- [ ] Migration runlog entry at `hq/runlog/2026-05-26-topology-migration.md` exists and is accurate.
