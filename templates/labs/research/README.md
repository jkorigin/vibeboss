# Research

One subdirectory per project being researched. Each follows the same layout:

```
research/<project>/
  STATE.md          ← what's been researched, what's pending
  topics/           ← OPTIONAL scratch for in-progress threads + hypothesis.md files
  findings/         ← completed findings, ready for adoption (the durable output)
```

`topics/` is scratch space — the research SKILL writes `hypothesis.md` there during a research pass, but single-pass research can write straight to `findings/`. The durable, adoptable output always lands in `findings/`. Don't treat an empty `topics/` as a problem.

**To add a new project area:** copy `_per_project_template/` to `research/<project-name>/`.
