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
1. Create `hq/projects/<name>/` with the structure above
2. Add a crew entry in `hq/crew.yml`
3. Update `hq/CLAUDE.md` authorizations section
4. Write a decision file: `hq/decisions/YYYY-MM-DD-add-project-<name>.md`
