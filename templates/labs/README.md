# Vibeboss Labs

Labs is the continuous research operation for your Vibeboss workspace. It runs perpetually: explore → find → handoff → dev leads adopt → cycle repeats.

**Lead:** {{LAB_LEAD_NAME}} (born {{DATE}})
**Home:** `{{WORKSPACE}}/labs/`
**HQ mirror:** `{{WORKSPACE}}/hq/projects/labs/`
**Scope:** Research for all active projects and the HQ/framework itself.

---

## Three flows

### 1. Boss → Labs (research request)

Boss (or {{OPERATOR_ADDRESSED_AS}}) writes a request at `hq/projects/labs/inbox/requests/YYYY-MM-DD-<topic>.md`:

```markdown
# <Topic title>

**To:** {{LAB_LEAD_NAME}} (labs)
**From:** Boss
**Priority:** high | normal | low
**Target project:** <project-name> | hq | other
**Date:** YYYY-MM-DD

## Question

<What specific question do you want answered?>

## Context

<Why this matters, what decisions it will inform.>

## Success criterion

<What "done" looks like. Typically: a finding file + handoff written.>
```

{{LAB_LEAD_NAME}} reads `hq/projects/labs/inbox/requests/` on every spawn. After pickup: moves to `processed/`, does the research, writes finding to `labs/research/<project>/findings/<topic>.md`, writes handoff to the target project's inbox.

### 2. Dev-lead → Labs (build agent requesting research)

Same format, same inbox. Build agents write at `hq/projects/labs/inbox/requests/YYYY-MM-DD-from-<agent>-<topic>.md`. {{LAB_LEAD_NAME}} processes it on next spawn.

### 3. Labs → Dev-lead (handoff for adoption)

When research is complete, {{LAB_LEAD_NAME}} writes a handoff to the target project's inbox:

**Path:** `hq/projects/<target-project>/inbox/requests/YYYY-MM-DD-from-labs-<topic>.md`

**Format:**
```markdown
# [Labs → <Project>] <Topic>

**To:** <Agent name> (<project>)
**From:** {{LAB_LEAD_NAME}} (labs)
**Date:** YYYY-MM-DD

## Finding

<One-line headline.>

## Recommendation

<Specific action the dev lead should take.>

## Evidence

`labs/research/<project>/findings/<topic>.md` — key data:
- <point 1>
- <point 2>

## Risk if ignored

<What breaks or degrades if dev lead doesn't adopt this.>
```

{{LAB_LEAD_NAME}} also appends a one-line entry to `labs/handoffs/YYYY-MM-DD.md` for audit.

---

## Directory layout

```
labs/
├── README.md                         ← this file
├── STATE.md                          ← current research status + queue summary
├── queue.md                          ← ordered research priorities
├── crew.yml                          ← labs crew
├── inbox/
│   ├── requests/                     ← incoming research requests
│   ├── processed/                    ← completed requests (moved here after pickup)
│   └── README.md
├── research/
│   ├── <project-name>/
│   │   ├── STATE.md
│   │   ├── topics/                   ← active research threads
│   │   └── findings/                 ← completed, ready for adoption
│   └── README.md
└── handoffs/
    └── README.md                     ← one daily .md per day, audit log
```

---

## {{LAB_LEAD_NAME}}'s boot protocol

On every spawn, {{LAB_LEAD_NAME}}:

1. Reads `labs/STATE.md` and `hq/projects/labs/STATE.md`
2. Reads `hq/projects/labs/inbox/requests/` for new requests
3. Reads `labs/queue.md` for research priorities
4. Executes top-of-queue or dispatched work
5. Writes finding → `labs/research/<project>/findings/<topic>.md`
6. Writes handoff → `hq/projects/<target>/inbox/requests/`
7. Appends to `labs/handoffs/YYYY-MM-DD.md`
8. Updates `labs/STATE.md` and `hq/projects/labs/STATE.md`
9. Sets `current_session_id: null` in `hq/crew.yml` before exit

---

## Research discipline

- **First pass = 500–1500 words, concrete recommendations, evidence/links where possible.** Depth comes in later spawns.
- **Date everything.** AI tooling moves weekly.
- **Cite sources.** Claims need links, test commands, or observed output.
- **Mark confidence.** Use `**Confidence:** high | medium | low` on any uncertain claim.
- **Findings before recommendations.** Raw finding first; synthesis second.
