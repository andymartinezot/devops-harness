# Orchestration — the main session

> **If you are running as a named agent** (any `*-agent` defined in `.claude/agents/`), **skip this file** and follow your agent definition. Rules load into subagents too; this one is only for the main session.

This file is behavior, not facts: it is the same in every project that uses the kit, so it holds no project facts. The project's routing table, shared-infra list and handoff exclusions live in the root `CLAUDE.md` under "Routing". Don't copy this file's content into `CLAUDE.md`, and don't edit it per project — improve it in the kit.

## Roles

| Role | Who | Does |
|---|---|---|
| **Main** (orchestrator) | this session | holds the map, routes work, writes and verifies specs, reviews results, owns every user-facing decision, is the only one that writes memory or posts outside the project |
| **Owners** | the domain agents in the routing table, once they exist | do the repo work inside their scope; commit locally when allowed |
| **Inspector** | the read-only inspector agent | live-env evidence (cluster, cloud, monitoring), never changes anything |
| **Drafters** (optional) | tracker or docs agents, if the project adds them | draft tracker / wiki text and local docs; never post. Until they exist, main drafts |

Only main can orchestrate: agents run with the Agent tool disallowed, so they cannot spawn other agents. Main fulfils each agent's `## Needs from others` by routing it.

## Delegate by default

Main's context window is the scarcest resource in the project. Everything main reads stays in it until the session ends or compacts; everything a subagent reads stays in the subagent's.

**Delegate** whenever the work sits inside one owner's scope and is any of:
- an edit;
- reading-heavy: more than two or three files, a log trawl, a test run, a dependency or call-graph search;
- a live-env check (always the inspector);
- producing output bulkier than its conclusion.

While the routing table has only main and the inspector, main does the repo work itself — but still sends live checks to the inspector, and still hands bulky reads to a general-purpose subagent rather than pulling them into its own context.

**Main does these itself:**
- a quick lookup of a file or two;
- reasoning across repos and owners;
- writing and verifying specs;
- reviewing results and re-running the decisive check;
- anything that needs back-and-forth with the user.

**Before acting, state the owner and the reason in one line.** Tie-break: the owner of the file being changed owns the task. Split cross-repo work by owner; run independent owners **in parallel** in one message, and same-repo tasks one after another.

## Every delegation prompt

Subagents start cold: they see none of this conversation. The prompt plus the files are everything they have.

1. **Goal**, plus the ticket or spec path.
2. **Files in scope**, and what **not** to touch. Warn when the target holds secrets (`secrets-handling.md`). When the agent will read config files, tell it to extract **key names structurally** (`yq 'keys'`, `jq 'keys'`, a `cut -d: -f1` on the key column) and never to print lines and redact them afterwards: filename surveys miss secrets in ordinary config, and hand-rolled redaction regexes fail on quoting.
3. **Permissions:** may it edit, commit, push? Default: edit and commit locally, **no push**.
4. **Env scope**, when live systems are involved.
5. **What to return:** conclusions and abridged evidence, never full logs or file dumps.
6. "End with the output contract."

**Output contract.** Every agent ends with `## Result` (done / partial / blocked), `## Changes`, `## Validation`, `## Commits`, `## Needs from others`, `## Risks / follow-ups`, `## Memory candidates`.

**Verify the claims that matter** by rereading the diff or re-running the check — a confident report is not evidence. If a result is wrong, send it back with the specific defect rather than redoing it.

## Writing state down — so context loss costs nothing

Assume the session can compact or end at any point. State that only exists in the conversation is already lost.

| What | Where | When |
|---|---|---|
| Progress on a spec'd change | the spec's `task.md` (rows, evidence log, decisions) | after each task or check |
| "Right now" across the project | `STATUS.md` (main, or the docs agent if there is one) | after anything it tracks changes |
| How a repo works | that repo's `CLAUDE.md` (its owner keeps it current) | when the owner learns or changes it |
| What happened this session | `docs/sessions/<date>-<role>-<slug>.md` via `/handoff` | end of session, or before switching workstream |
| Anything posted outside | `docs/outbox/<date>-<slug>.md` via `/outbox` | before and after posting |
| A decision | `DECISIONS.md` row → body in spec / log / docs home | when made |
| A durable trap, process or preference | `memory/` (main only, per `memory-policy.md`) | when it will recur |

**Memory is not a state store.** Its index is injected into every session, so live state there clutters every future session and goes stale. Progress belongs in `task.md` and `STATUS.md`.

**Session hygiene:**
- One workstream per session. When a session gets long or the workstream changes: `/handoff`, start a new session from the project root, `/resume-handoff`. A fresh window with good files beats a long window with a summary of itself.
- After a compaction, re-read `STATUS.md` and the active spec's `task.md` before acting. Don't trust recollection for IDs, hashes, versions or resource identifiers — re-read the file or re-run the check.
- Launch from the project root. A session started in a sub-repo is a different project: no memory, no harness.

## Memory, outward writes and gates

- **Memory is main's to write.** Agents propose under `## Memory candidates`; main verifies the claim, then writes. See `memory-policy.md`.
- **Outward-facing actions need user confirmation**, even when an agent proposes them: push or MR/PR, tracker or wiki writes, chat messages, any non-dev mutation, any shared-infra change. See `change-safety.md`.
- **Outbox is the one write path.** Main posts through `/outbox`: drafts go into `docs/outbox/<date>-<slug>.md`, the user approves by item number, main posts, reads each post back and records the id/url. Drafting agents, if the project has them, run as subagents, draft the exact text and return it in `## Changes`. Repo-host mechanics go through the repo host's skill (e.g. `/gitlab`).
- Brief any drafter with this packet (project-specific exclusions are added in `CLAUDE.md`):

```
HANDOFF from main-agent
Spec/tickets: <ABC-123> (spec: specs/NNN-slug/ | none)
Commits: <repo> <hash> <msg>            (or: none)
Env results: <env>: <verified fact> — evidence: <command or log pointer>
Requested: tracker → <comment/transition on ABC-123> | docs → <file or page §section>
Do not include: secret values, prod data
```

## Spec before you build

Write an SDD spec (`/spec`) before implementing any change that:
- spans more than one repo;
- touches any non-dev env;
- touches shared infra (the list in `CLAUDE.md` → "Routing");
- needs a rollback plan.

Close it with `/spec-verify`. **Start of session:** `/resume-handoff`. **End of session:** `/handoff`.

## Models

- **Main** runs on the strongest available model with the largest context window; check the real window with `/context`.
- **Owners and the inspector** use `model: inherit`: they reason about code, policies and live state.
- **Drafters** can use a cheaper, faster model: their output is checked by main before anything is posted.
