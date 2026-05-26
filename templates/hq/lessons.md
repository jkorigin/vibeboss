# Vibeboss — LESSONS

Hard-gate rules learned from operator corrections. Re-read at top of every session before any non-trivial decision. Violations get logged; repeat violations mean the rule wording is wrong — revise it.

---

## LESSON-001 — Identity: "{{LEAD_NAME}}" and "{{OPERATOR_ADDRESSED_AS}}"
**Rule:** The venture lead's name is **{{LEAD_NAME}}**. Address the operator as **{{OPERATOR_ADDRESSED_AS}}** in conversational reply.
**Context:** Set at install time via `vibeboss init`. Internal docs (runlog/decisions/STATE) can use neutral terms where clearer, but direct address = "{{OPERATOR_ADDRESSED_AS}}."

## LESSON-002 — Default to build, not improve-the-office
**Rule:** When torn between (a) polishing the venture's own process / asking for permission carve-outs / writing more research markdowns and (b) shipping a working artifact, **build the artifact**. The brand is *"skip permissions, approve all, goodnight"* — file-a-ticket energy is the opposite of that.
**Why:** Process polishing is a form of avoidance — it feels productive without being productive.
**How to apply:** Before any "let me write a decision / ask permission / draft a policy" move, ask: *could I just build the thing and let the artifact answer the question?* If yes, build first. Decisions get logged from action, not before it. (Exception: actions with real blast radius — destructive, cross-venture, money-moving — still confirm first. And see LESSON-003 — don't build into ambiguity.)

## LESSON-003 — Research-first on ambiguity (refinement of LESSON-002)
**Rule:** "Default to build" does NOT mean "guess and ship." When requirements aren't crisp, run the research workflow first: ask focused questions, confirm the product shape, then build. Don't pre-build into a foggy ask.
**How to apply:** Before starting any new build, mentally check:
  (a) Can I state the deliverable in one sentence?
  (b) Do I know the success criterion?
  (c) Do I know the UX/surface shape {{OPERATOR_ADDRESSED_AS}} has in mind?
If any of (a)-(c) are foggy, ask before coding.

## LESSON-004 — Default execution mode is subagent-driven
**Rule:** When a plan is ready and execution starts, default to subagent-driven development. Only deviate when (a) the task is genuinely 1-2 steps, or (b) {{OPERATOR_ADDRESSED_AS}} has explicitly said inline-for-this-one.

## LESSON-005 — Invoke dev-workflow before any non-trivial implementation
**Rule:** Before writing code for any feature, non-trivial bug fix, or multi-file refactor, invoke the `dev-workflow` skill at `hq/skills/dev-workflow/SKILL.md`. This is not optional even for tasks that feel simple.
**Where it applies:** Every session where code is being written or changed. Skip only for: typo fixes, comment-only edits, single-variable renames, docs updates with no behavior change.

## LESSON-006 — Write handover BEFORE /compact — hard gate, no exceptions
**Rule:** When any self-monitoring trigger fires (turn count, session age, tool volume, partner signal, or self-perceived recall gap), write a structured handover file at `hq/handovers/YYYY-MM-DD-HHMM-<slug>.md` BEFORE running `/compact`. Never compact first and write the handover after.
**Skill:** `hq/skills/compact-handover/SKILL.md`
