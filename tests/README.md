# tests/

Smoke tests for the Vibeboss framework itself. These are the first tests the
framework has — they keep `init.sh` honest.

## init-smoke.sh

End-to-end smoke test for `bash init.sh`. Runs the installer against a temp
workspace in noninteractive mode, then verifies:

- The expected HQ files exist (`CLAUDE.md`, `AGENTS.md`, `lessons.md`,
  `crew.yml`, `STATE.md`, `.claude/settings.json`, `.codex/hooks.json`,
  hooks).
- The expected Labs files exist (`README.md`, `crew.yml`, `STATE.md`).
- The workspace-root redirect hook is installed.
- Hook scripts (`boot.sh`, `compact-boot.sh`, `redirect.sh`) are executable.
- The boot hook emits valid JSON with `hookSpecificOutput.additionalContext`.
- No `{{...}}` placeholders remain unresolved in generated markdown.

The temp workspace lives under `${TMPDIR:-/tmp}/vibeboss-smoke-$$` and is
cleaned up on exit (success or failure).

## Run locally

From the repo root:

```bash
bash tests/init-smoke.sh
```

Exits 0 on success, 1 on any failure. All collected failures are printed
before the final `FAIL` line.

## CI

`.github/workflows/ci.yml` runs this test on every push and PR to `main`.
