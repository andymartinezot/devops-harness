# CLAUDE.md — {{WORKSPACE_NAME}}

{{ONE_LINE_PURPOSE}}

- {{LAYOUT: "single repo" | "workspace of N repos; the root is not a repo — run git inside each"}}
- Repo-level detail belongs in each repo's `CLAUDE.md` (written the first time the repo is worked on), not here.

This file is the map: what exists, how it connects, who owns what, and how work gets delegated.

## Subprojects

| Directory | Stack | Role | Owner agent |
|---|---|---|---|
| {{dir}} | {{stack}} | {{role}} | main |

## How it connects

- {{inbound / outbound flows, one line each — or TODO: describe}}

## Environments

Ladder: `{{ENV_LADDER}}`. Promote in that order; never try something in a higher env first.

| Env | Platform | Deploy path |
|---|---|---|
| {{env}} | {{platform}} | {{how it deploys}} |

Access details (profiles, accounts, contexts) live in `.claude/rules/access.md` once known. {{or TODO}}

## Where state lives (one source of truth per fact)

| What | Where |
|---|---|
| Right now: blockers, service × env, open MRs/PRs | `STATUS.md` |
| Decisions | `DECISIONS.md` (index) |
| Change specs (SDD) | `specs/NNN-<slug>/` — `spec.md` (what/why, **the only place Status lives**), `plan.md`, `task.md`. Template: `specs/_template/` |
| Session logs | `docs/sessions/<date>-<role>-<slug>.md` |
| Outward writes (posted or pending) | `docs/outbox/<date>-<slug>.md` |
| Durable cross-session knowledge | `memory/` (index `memory/MEMORY.md`). Policy: `.claude/rules/memory-policy.md` |
| Channels and tools | `.claude/rules/integrations.md` |
| Ticket state | {{TRACKER}} — files are snapshots only |

---

## Main session: orchestrator

> **If you are running as a named agent**, skip this section and follow your agent definition.

Main holds the map, not the territory. It routes, specs, verifies and talks to the user.

**Delegate** when a task sits inside one owner's scope and needs more than a quick read. **Main does
itself:** quick lookups, cross-repo reasoning, specs, reviewing results, every user-facing decision.
While the routing table has only main and the inspector, main does the repo work itself.

**Routing:**

| Path / topic | Owner |
|---|---|
| Read-only live checks, evidence for specs | `{{inspector-agent}}` |
| Everything else | main |

Tie-break: the owner of the file being changed owns the task. State the owner and the reason in one
line before acting.

**Every delegation prompt contains:** the goal plus ticket or spec path; files in scope and what not to
touch; permissions (default: edit and commit locally, **no push**); env scope for live systems; "End
with the output contract."

**Output contract.** Every agent ends with `## Result` (done / partial / blocked), `## Changes`,
`## Validation`, `## Commits`, `## Needs from others`, `## Risks / follow-ups`, `## Memory candidates`.

**Memory is main's to write.** Agents propose; main verifies the claim, then writes.

**Verify the claims that matter** by rereading the diff or running the check. If a result is wrong, send
it back with the specific defect.

**Outward writes go through `/outbox`.** Pushes, MRs/PRs, tracker and wiki writes, chat messages: drafted
as outbox items, approved per item by the user, posted by main, verified, recorded. Sub-agents draft;
they never post. See `.claude/rules/change-safety.md`.

**Write a spec (`/spec`) before implementing** any change that spans more than one repo, touches a
non-dev env, touches shared infra, or needs a rollback plan. Close it with `/spec-verify`.

**End of session:** `/handoff`. **Start of session:** `/resume`.
