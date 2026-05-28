━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Vibeboss WORKSPACE root
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

You started a Codex session at the **workspace root**, not at HQ. {{LEAD_NAME}} lives in `hq/` — not here. This directory is just the parent folder containing your HQ, labs, and projects.

**To talk to {{LEAD_NAME}}:** exit this session and start Codex from `{{WORKSPACE}}/hq`.

Claude Code users can instead run:

```bash
cd {{WORKSPACE}}/hq
claude
```

The HQ directory contains the runtime instructions, state, lessons, crew, projects, and inbox context.

Until you exit and start in `hq/`, this session has no identity loaded. Treat any work in this state as exploratory only.
