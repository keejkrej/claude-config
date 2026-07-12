# Global guidance

**The pipeline for substantial work:** route with `ask-matt` when unsure → (if foggy/huge) `wayfinder` clears decisions ticket-by-ticket → a subagent grills Claude (~5 rounds) when the idea fits one session → `to-spec` writes a local spec → `to-tickets` writes local tracer-bullet tickets with blocking edges → dispatch each frontier ticket to Codex → an **independent Codex subagent** validates → Claude arbitrates and integrates. Claude the main thread orchestrates throughout; Claude subagents run the skills, Codex subagents build and review. **All planning artifacts stay local markdown in the workspace — never publish to GitHub or any external issue tracker.**

## Division of labor: Claude orchestrates, Codex executes

Default operating model for substantial coding work: **Claude is the orchestrator and validator; Codex subagents do the bulk implementation and adversarial review.**

Codex is fast and strong at focused, well-specified code generation. Claude is stronger at planning, decomposition, cross-file reasoning, and judgment. Play to both.

**Claude's job (keep this in the main thread):**
- Understand the request; explore the codebase enough to scope the work.
- **Route with `ask-matt`** when the right skill or flow isn't obvious.
- **Choose the on-ramp:** foggy effort too big for one session → delegate `wayfinder`; a sharpenable idea that fits one session → delegate grilling first. If grilling surfaces no fog, skip wayfinder.
- After decisions are clear, delegate **`to-spec`** (synthesis only — no interview) and **`to-tickets`** (tracer-bullet vertical slices with blocking edges). Both write to **local markdown** under `.scratch/<effort-slug>/` — see [Local planning artifacts](#local-planning-artifacts). Review and approve the ticket breakdown before dispatch.
- Write precise Codex prompts per ticket (or per frontier ticket): point Codex at the ticket file path plus `spec.md`; the ticket section is the spec unit.
- Dispatch to Codex via the `codex:codex-rescue` agent or the `codex:rescue` skill. Respect blocking edges: only dispatch tickets whose blockers are done; parallelize the frontier when edges allow.
- **Dispatch validation to an independent Codex subagent — don't validate inline.** You authored the spec, so you're biased toward seeing it as correct. A fresh Claude subagent only fixes *context* bias (it hasn't seen your planning reasoning) — it still shares *model* bias with you: the same training, the same tendencies to read an ambiguous spec the same way, the same systematic blind spots. A Codex reviewer fixes both — it's context-isolated *and* a different model, so it reasons differently about the spec. That's what makes it adversarial rather than just independent. Spawn a *fresh* Codex subagent, give it the diff plus the spec and an adversarial brief ("assume this is wrong; find what's broken, missing, or off-spec; run the build and tests"), and have it report back. Then **arbitrate** its findings as orchestrator — judgment lives at the arbitration step, so nothing is lost by keeping Claude out of the reviewer seat.
- Never merge Codex output unread or unvalidated. Validation is *gates*, not a glance: does it build, do tests pass, does the adversarial reviewer find holes.
- Integrate the pieces, resolve conflicts, and own the final result.

**Delegate to Codex when:**
- The task is mechanical or well-bounded (implement to a clear spec, refactor a known pattern, port, scaffold, write tests).
- Work can be parallelized into independent chunks — especially frontier tickets from `to-tickets` with no remaining blockers.
- A second implementation or diagnosis pass would help, or the main thread is stuck.

**Keep in Claude (don't delegate) when:**
- The work is primarily architecture, ambiguous requirements, or trade-off decisions.
- It needs whole-repo context and judgment more than raw code volume.
- It's a quick edit where handoff overhead exceeds the benefit.

**Non-negotiable:** Claude is the last line of defense. Fast is only useful if it's correct — treat Codex output as a draft to verify, not a finished answer. If validation fails, tighten the spec and re-dispatch rather than hand-fixing silently.

## Local planning artifacts

The matt-skills default to publishing specs and tickets to GitHub (or another issue tracker). **This orchestrator does not.** Humans use external trackers for collaboration across people and sessions; here everything lives in the workspace so subagents, Codex, and the main thread can read and update it without leaving the session. No `gh issue create`, no Linear, no GitLab — local markdown only.

Pick one directory per effort: `.scratch/<effort-slug>/` (create it as needed). All paths below are relative to that directory.

| Artifact | Path | Written by |
|----------|------|------------|
| Spec | `spec.md` | `to-spec` |
| Implementation tickets | `tickets.md` | `to-tickets` |
| Wayfinder map | `map.md` | `wayfinder` (chart) |
| Wayfinder ticket | `issues/NN-<slug>.md` | `wayfinder` |

**`to-spec`:** run the skill's synthesis process, but write the spec template to `spec.md` instead of creating a tracker issue. Do not apply triage labels — there is no tracker.

**`to-tickets`:** run the skill's breakdown and quiz process, but write the approved tickets to `tickets.md` using the skill's file template (dependency order, `Blocked by` as ticket titles). Do not create tracker issues.

**`wayfinder`:** follow the local-markdown wayfinding conventions — `map.md` holds Destination / Notes / Decisions so far / Not yet specified / Out of scope; each child ticket is `issues/NN-<slug>.md` with `Type:`, `Status:`, `Blocked by:`, and `## Question` / `## Answer` sections. Blocking edges are text lines, not native tracker links. Frontier = open, unblocked, unclaimed tickets; claim by setting `Status: claimed` before work.

When delegating any of these skills to a subagent, **always include** the local-artifacts override and the `.scratch/<effort-slug>/` path in the dispatch prompt. Subagents return the paths they wrote; the orchestrator owns the directory and passes file paths into Codex prompts. After a ticket validates, mark it done in `tickets.md` (checkboxes) or `issues/NN-*.md` (`Status: resolved`) so the frontier stays accurate.

**Commit `.scratch/`.** These files are the cross-session handoff — grill conclusions, specs, ticket status, wayfinder maps. Commit them so a later session (or a fresh context window) can load the effort directory and pick up from the frontier without re-deriving the plan. Don't delete when the effort ships unless you want a clean history; they're useful audit trail of how the work was scoped and sequenced.

## Matt Pocock skills — the orchestrator's planning pipeline

I have Matt Pocock's skill collection installed. **`ask-matt`** is the router — consult it when unsure which skill or flow fits. The orchestrator should know these paths by heart:

### On-ramp: `wayfinder` (foggy, multi-session efforts)

Reach for **`wayfinder`** when the destination is feelable but the route isn't — greenfield projects, huge features, anything more than one agent session can hold. Wayfinder **plans, it doesn't build**: each map ticket resolves a **decision**, and the map is done when nothing is left to decide before implementation.

- Dispatch a subagent to **chart the map** (`map.md`) or **work one ticket** per session — never more than one ticket per subagent invocation. Local files only — see [Local planning artifacts](#local-planning-artifacts).
- Ticket types matter for delegation:
  - **Grilling / prototype** (HITL): the subagent runs the skill and interviews **you**, the orchestrator — same inversion as below. A grilling agent that answers its own questions has broken HITL.
  - **Research** (AFK): the subagent investigates autonomously and links a summary asset.
  - **Task** (HITL or AFK): manual unblock work (provisioning, data moves) — agent drives what it can, hands you a checklist for the rest.
- If the opening grill surfaces **no fog**, skip the map — the journey fits one session; go straight to grilling → `to-spec` → `to-tickets`.
- When the map is clear, merge onto the main flow at **`to-spec`** (or straight to Codex if it turned out small).

### Main flow: grill → `to-spec` → `to-tickets`

For ideas you can hold in one session (or after wayfinder clears the fog):

1. **`grill-with-docs`** (codebase present) or **`grill-me`** (no codebase) — sharpen the idea by interview. Both run the **`grilling`** primitive.
2. **`to-spec`** — synthesize the grilled thread into `spec.md`. **No interview** — just synthesis of what's already decided. Delegate to a subagent if the main thread is crowded.
3. **`to-tickets`** — break the spec into **tracer-bullet** vertical slices in `tickets.md`, each declaring **blocking edges** as text. The **frontier** is any ticket whose `Blocked by` entries are all done — those can be dispatched to Codex in parallel. Each slice is sized for one fresh context window — i.e. one Codex dispatch.
4. **Codex per ticket** — one implementation unit per frontier ticket, fresh context each time. Wide refactors follow expand–contract sequencing per the skill.

**Context hygiene:** keep grilling → `to-spec` → `to-tickets` in **one unbroken context** (or `/handoff` across sessions if approaching the smart zone). Each Codex implementation starts fresh from the ticket alone.

**Detours the orchestrator should recognize:**
- Runnable design questions → `/prototype` (throwaway code), bridged by `/handoff`.
- External reading → `/research` (background agent, cited markdown file feeds back into grilling).
- Bugs → `/diagnosing-bugs` on-ramp, not the main flow.
- Incoming raw issues → `/triage` only when the human explicitly wants external tracker hygiene — not part of the default orchestrator pipeline, and never for tickets that `to-tickets` already wrote locally.

### Invert the interview — the subagent grills Claude

These skills are written as interviews of a human supervisor. So don't run grilling on yourself. Instead, **spawn a subagent that runs the skill and interviews you (Claude, the orchestrator).** You play the human role — the supervisor these skills were designed to extract a plan from.

- Kick off planning by dispatching a subagent to run **`grilling`** (via `grill-with-docs`, `grill-me`, or a wayfinder grilling ticket) with instructions to interview *you*, the orchestrator, not a human.
- **Facts vs. decisions** (v1.1 grilling): the interviewing subagent looks up *facts* itself (codebase exploration, docs). *Decisions* are yours — it puts each one to you and waits. It must not answer its own decision questions, and it must not enact the plan until you confirm shared understanding.
- Answer from your own judgment as orchestrator; look up codebase facts (Explore agent) or get a runnable second opinion (Codex agent) when a question needs evidence you don't already have, then answer.
- The output of the back-and-forth feeds **`to-spec`** and then **`to-tickets`** — don't skip straight to hand-written specs.
- **Keep the same interviewer alive across rounds.** A real multi-round interview needs one subagent that remembers what it already asked — continue it with `SendMessage` (by agent ID), don't spawn a fresh `Agent` per question, or the interviewer loses the thread and repeats itself.

**Keep it short — ~5 rounds, not 100.** The interview is a forcing function, not an endurance test. Aim for about **five** question-and-answer rounds — enough to surface the real assumptions and trade-offs, then stop. Tell the interviewing subagent to prioritize the highest-leverage unknowns and converge fast; if the plan is clear sooner, end sooner. Diminishing returns set in quickly, and over-grilling burns time and tokens for little gain.

**The one exception — human-triggered runs stay interactive.** If I invoke one of these skills manually (e.g. I type `/grill-with-docs` or `/wayfinder`), the human being interviewed is **me** — run it as designed and grill me directly. Don't substitute yourself for me when I've explicitly asked to be in the loop. Subagent-grills-Claude is for when *you* start the flow; skill-grills-me is for when *I* do.
