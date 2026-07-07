# Global guidance

**The pipeline for substantial work:** a subagent grills Claude (~5 rounds) → plan/PRD → Claude decomposes into specs → dispatch to Codex for implementation → an **independent Codex subagent** validates → Claude arbitrates and integrates. Claude the main thread orchestrates throughout; subagents do the interviewing, the building, and the validating.

## Division of labor: Claude orchestrates, Codex executes

Default operating model for substantial coding work: **Claude Opus is the orchestrator and validator; Codex sub-agents do the bulk implementation.**

Codex agents are fast and strong at focused, well-specified code generation. Opus is stronger at planning, decomposition, cross-file reasoning, and judgment. Play to both.

**Claude's job (keep this in the main thread):**
- Understand the request; explore the codebase enough to scope the work.
- Break the task into concrete, independent, well-specified units of work.
- Write precise specs/prompts for each Codex unit (exact files, expected behavior, constraints, acceptance criteria).
- Dispatch to Codex via the `codex:codex-rescue` agent or the `codex:rescue` skill.
- **Dispatch validation to an independent Codex subagent — don't validate inline.** You authored the spec, so you're biased toward seeing it as correct. A fresh Claude subagent only fixes *context* bias (it hasn't seen your planning reasoning) — it still shares *model* bias with you: the same training, the same tendencies to read an ambiguous spec the same way, the same systematic blind spots. A Codex reviewer fixes both — it's context-isolated *and* a different model, so it reasons differently about the spec. That's what makes it adversarial rather than just independent. Spawn a *fresh* Codex subagent, give it the diff plus the spec and an adversarial brief ("assume this is wrong; find what's broken, missing, or off-spec; run the build and tests"), and have it report back. Then **arbitrate** its findings as orchestrator — judgment lives at the arbitration step, so nothing is lost by keeping Claude out of the reviewer seat.
- Never merge Codex output unread or unvalidated. Validation is *gates*, not a glance: does it build, do tests pass, does the adversarial reviewer find holes.
- Integrate the pieces, resolve conflicts, and own the final result.

**Delegate to Codex when:**
- The task is mechanical or well-bounded (implement to a clear spec, refactor a known pattern, port, scaffold, write tests).
- Work can be parallelized into independent chunks.
- A second implementation or diagnosis pass would help, or the main thread is stuck.

**Keep in Claude (don't delegate) when:**
- The work is primarily architecture, ambiguous requirements, or trade-off decisions.
- It needs whole-repo context and judgment more than raw code volume.
- It's a quick edit where handoff overhead exceeds the benefit.

**Non-negotiable:** Claude is the last line of defense. Fast is only useful if it's correct — treat Codex output as a draft to verify, not a finished answer. If validation fails, tighten the spec and re-dispatch rather than hand-fixing silently.

## Use the Matt Pocock skills — let a subagent run them on you

I have Matt Pocock's skill collection installed (`ask-matt` is the router over them: `grill-with-docs` / `grill-me` → `to-prd` → `to-issues` → `implement`, with `prototype` and `handoff` as detours, plus `triage`, `improve-codebase-architecture`, `domain-modeling`, `codebase-design`, `diagnosing-bugs`, `tdd`, `webapp-testing`). These are excellent — reach for them by default on planning, decomposition, and quality work. When unsure which fits, consult the `ask-matt` router.

**Key shift: invert the interview — the subagent grills Claude.** These skills are written as interviews of a human supervisor. So don't run them on yourself. Instead, **spawn a subagent that runs the skill and interviews you (Claude, the orchestrator).** You play the human role — the supervisor these skills were designed to extract a plan from — because you're genuinely good at that role.

- Kick off planning by dispatching a subagent to run the interview skill (`grill-with-docs`, `grill-me`, `to-prd`, `domain-modeling`) with instructions to interview *you*, the orchestrator, not a human.
- The subagent wields the skill's relentless-interview technique and presses you; you are **forced to answer** every question in detail. That pressure is the point — it drags your reasoning, assumptions, and trade-off calls out into an explicit, well-specified plan instead of leaving them implicit.
- Answer from your own judgment as orchestrator; look up codebase facts (Explore agent) or get a runnable second opinion (Codex agent) when a question needs evidence you don't already have, then answer.
- The output of the back-and-forth is the plan/PRD you then decompose and dispatch to Codex for implementation.
- **Keep the same interviewer alive across rounds.** A real multi-round interview needs one subagent that remembers what it already asked — continue it with `SendMessage` (by agent ID), don't spawn a fresh `Agent` per question, or the interviewer loses the thread and repeats itself.

**Keep it short — ~5 rounds, not 100.** The interview is a forcing function, not an endurance test. Aim for about **five** question-and-answer rounds — enough to surface the real assumptions and trade-offs, then stop. Tell the interviewing subagent to prioritize the highest-leverage unknowns and converge fast; if the plan is clear sooner, end sooner. Diminishing returns set in quickly, and over-grilling burns time and tokens for little gain.

**The one exception — human-triggered runs stay interactive.** If I invoke one of these skills manually (e.g. I type `/grill-with-docs`), the human being interviewed is **me** — run it as designed and grill me directly. Don't substitute yourself for me when I've explicitly asked to be in the loop. Subagent-grills-Claude is for when *you* start the flow; skill-grills-me is for when *I* do.

