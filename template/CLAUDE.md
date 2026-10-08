# CLAUDE.md — {{WORKSPACE_NAME}}

{{ONE_LINE_PURPOSE}}

- {{LAYOUT: "single repo" | "workspace of N repos; the root is not a repo — run git inside each"}}
- **Not every directory is a repo.** {{container dirs holding nested repos (run git one level deeper), and unversioned dirs — or "none"}}.

This file is the map: what exists, how it connects, who owns what, and how work gets delegated. Repo-level detail belongs in each repo's `CLAUDE.md` (template: `.claude/templates/repo-CLAUDE.md`), not here. Deep reference that doesn't need to load every session can live in `.claude/context/*.md`, read on demand.

Harness: from `{{KIT_DIR}}` on {{YYYY-MM-DD}}. `/lint` checks this project.

## Subprojects

| Directory | Stack | Role | Owner agent |
|---|---|---|---|
| {{dir}} | {{stack}} | {{role}} | main |

**Outside this project:** {{"none" — or each path in `additionalDirectories`, what it holds and its owner. Their `CLAUDE.md` files are not auto-loaded, so read them explicitly.}}

## How it connects

- {{inbound / outbound flows, one line each: producer → transport → consumer — or TODO: describe}}

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
| Durable cross-session knowledge | `memory/` (index `memory/MEMORY.md`, auto-injected each session). Policy: `.claude/rules/memory-policy.md` |
| Channels and tools | `.claude/rules/integrations.md` |
| Ticket state | {{TRACKER}} — files are snapshots only |

---

## Routing — main is the orchestrator

> **If you are running as a named agent** (any `{{PREFIX}}-*-agent`), **skip this section.** Follow your agent definition instead.

This session is the orchestrator. **How** it orchestrates — delegate by default, the delegation prompt, the output contract, verifying claims, writing state down so context loss costs nothing, the outbox, when to write a spec — is in `.claude/rules/orchestrator.md`, which is the same in every project on the kit. This section holds only this project's facts.

| Path / topic | Owner |
|---|---|
| Read-only live checks, evidence for specs | `{{PREFIX}}-inspector-agent` |
| Everything else | main |

Add a row per domain agent when one is created from `.claude/templates/domain-agent.md`.

**Project tie-breaks:** {{e.g. "a service's values block in the deploy repo belongs to the platform owner" — or "none yet"}}. Each owner keeps its repos' `CLAUDE.md` current.

**Secrets warning for delegations:** {{the secret-bearing paths from `secrets-handling.md` an owner must be warned about — or "none found"}}.

**Shared infra (spec first):** {{e.g. cluster bootstrap, DNS, IAM trust policies — or "none"}}.

**Handoff packet additions:** {{"none" — or project-specific "Do not include" items}}.

**Start of session:** `/resume-handoff`. **End of session:** `/handoff`.
