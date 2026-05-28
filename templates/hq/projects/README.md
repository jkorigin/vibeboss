# Projects

Each partner-owned project gets a subdirectory here: `hq/projects/<project-name>/`.

**Standard project structure:**
```
hq/projects/<name>/
  STATE.md          ← project-specific state
  lessons.md        ← project-specific lessons (optional)
  decisions/        ← project-specific decisions
  inbox/
    requests/       ← tasks from Boss
    chats/          ← freeform notes
    todos/          ← self-assigned by named agent
    processed/      ← completed items (subdirectory per item)
```

The named agent for this project checks `inbox/requests/` on every boot.

**To add a project:**

```
bash ~/ventures/vibeboss/init.sh --add-project <name>
```

That scaffolds the standard structure above, assigns the next crew name from `hq/crew.yml` `next_available`, symlinks Vibeboss-native skills (`dev-workflow`, `compact-handover`) into the project's `.claude/skills/`, and prints follow-up steps.

Manual finishing touches (Boss owns these on first spawn, so they land in the runlog/decisions):
1. Add the new crew member to `hq/crew.yml` `agents[]`
2. Update `hq/CLAUDE.md` authorizations section
3. Write a decision file: `hq/decisions/YYYY-MM-DD-add-project-<name>.md`
