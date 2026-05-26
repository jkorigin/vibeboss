━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Vibeboss WORKSPACE root
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

You started a Claude Code session at the **workspace root**, not at HQ. {{LEAD_NAME}} lives in `hq/` — not here. This directory is just the parent folder containing your HQ, labs, and projects.

**To talk to {{LEAD_NAME}}:**

```bash
exit       # leave this session
cd hq      # (or: cd {{WORKSPACE}}/hq)
claude
```

The SessionStart hook in `hq/` will boot {{LEAD_NAME}} automatically with full context (STATE, lessons, crew, projects, inbox).

**To shorten the cd in the future**, add this alias to your `~/.zshrc` or `~/.bashrc`:

```bash
alias vb='cd {{WORKSPACE}}/hq && claude'
```

Then just type `vb` to boot {{LEAD_NAME}} from anywhere.

---

**Other directories in this workspace and what's there:**

- `hq/` — {{LEAD_NAME}}'s home (start sessions here)
- `projects/<name>/` — your project codebases
- `labs/` — research lab ({{LEAD_NAME}} dispatches research from HQ — don't `cd` here for chat)

Until you exit and `cd hq/`, this session has no identity loaded. Treat any work in this state as exploratory only.
