# HQ Inbox

Drop zone for incoming work. The lead checks this on every boot.

```
inbox/
  requests/    ← task requests (from partner or external triggers)
  chats/       ← freeform notes and context drops
  todos/       ← self-assigned work items
  processed/   ← completed items (moved here after done)
```

**To add a task:** create a `.md` file in `requests/` with the standard task format (see `hq/CLAUDE.md` crew system section for the format).

**processed/** is a flat directory — just move the file there when done.
