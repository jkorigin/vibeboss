# Crew System — Implementation Plan

**Subsystem:** C of A→G
**Date:** 2026-05-26
**Spec:** `docs/superpowers/specs/2026-05-26-crew-system-design.md`

---

## Build sequence

All items are data/docs — no code compilation, tests are YAML parse validation.

### Group 0 — Data files (parallel, independent)

1. **`hq/crew.yml`** — extend with `naming_convention:` block + `agents:` entries for Banana, Carrot, Ginger.
2. **`vibeboss/crew.yml.template`** — new file; schema with `{{PLACEHOLDER}}` vars.
3. **`hq/projects/<example-project>/inbox/`** — create 4 subdirs + READMEs.
4. **`hq/projects/master-dashboard/inbox/`** — create 4 subdirs + READMEs.

### Group 1 — Documentation updates (after Group 0)

5. **`hq/CLAUDE.md`** — add "Crew" section; extend boot sequence with step 7 (load crew from crew.yml).

### Group 2 — Paperwork (final)

6. **`hq/runlog/2026-05-26-subsystem-C-crew-system.md`** — record what was done.
7. **`hq/STATE.md`** — C → Recently closed; promote D (auto-boot) to Next-1.

---

## Validation

After Group 0, run:

```bash
python3 -c "import yaml; yaml.safe_load(open('hq/crew.yml')); print('crew.yml OK')"
python3 -c "import yaml; yaml.safe_load(open('vibeboss/crew.yml.template')); print('template OK')"
```

Both must print OK with no exceptions. YAML parse error = implementation bug, fix before proceeding to Group 1.

---

## DoD check (at end)

Go through spec DoD line by line. Each item must be true before writing the runlog.

- crew.yml extended ✓
- crew.yml.template created ✓
- <example-project> inbox dirs created ✓
- master-dashboard inbox dirs created ✓
- CLAUDE.md Crew section added ✓
- CLAUDE.md boot sequence updated ✓
- YAML parses clean ✓
- Runlog written ✓
- STATE.md updated ✓
