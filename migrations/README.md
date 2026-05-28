# Vibeboss migrations

Structural shape adjustments applied to existing workspaces when `init.sh --update` carries them across release boundaries.

## What belongs here

- Renaming a directory in the workspace tree
- Changing a YAML schema (e.g. adding a required field to `crew.yml`)
- Splitting one file into two, or merging two into one
- Any one-time, breaking-change fix that an existing workspace needs to keep working

## What does NOT belong here

- Content updates of templates (refreshed copies of `boot.sh`, skill bodies, prompt files, etc.). Those are handled by the manifest-driven refresh in `init.sh --update` directly. Migrations are for *structural shifts*, not file-content drift.

## Naming convention

Each migration is a shell script named:

```
v<from>-to-v<to>.sh
```

Examples:

- `v0.2.1-dev-to-v0.2.2-dev.sh`
- `v0.3.0-to-v0.3.1.sh`

Each script:

- Has shebang `#!/usr/bin/env bash` and sets `set -euo pipefail`.
- Takes `$1` = workspace path. Validates it exists.
- Is **idempotent** — safe to re-run on a workspace that already has the migration applied.
- Exits 0 on success, nonzero on failure.

## How the runner picks them

`run.sh <WORKSPACE> <FROM_VERSION> <TO_VERSION>` lex-sorts all `v*-to-v*.sh` files, then applies those whose `<from>` >= `FROM_VERSION` and whose `<to>` <= `TO_VERSION`. Each is invoked as `bash <migration> <WORKSPACE>`. First failure aborts the run.

## SemVer caveat

Version comparison is plain string comparison. This is fine for the foreseeable future (we're in 0.2.x) but note: `0.10` sorts *before* `0.2` lexically. If/when Vibeboss approaches a two-digit minor or patch, swap in a real semver compare.
