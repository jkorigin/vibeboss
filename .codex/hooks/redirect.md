━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Vibeboss SOURCE
  ~/ventures/vibeboss/  (OSS framework repo)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

You started an agent session at Vibeboss source — this is the framework repository, NOT a runtime workspace. Two paths from here:

**1. Daily HQ work (you are Boss):** exit this session and `cd ~/ventures/vibeboss-workspace/hq/`, then run `claude` there. The SessionStart hook will boot Boss with full HQ context (STATE, lessons, crew, projects, inbox).

For Codex, start/open Codex from `~/ventures/vibeboss-workspace/hq/`; the `AGENTS.md` file there supplies Boss's runtime instructions.

**2. Framework enhancement (you want Vibe Chief):** in Claude Code, exit this session and run `bash reno.sh` from this directory. In Codex, starting at this source root is the framework-dev path; the Codex hook loads `CHIEF.md` as additional context.

If you're not sure which you want — almost certainly (1). HQ is where 95% of work happens. Vibe Chief is only for the rare moment you're improving the framework itself.

Until you exit and pick a mode, this session has no specific identity loaded. Treat any work in this state as exploratory only.
