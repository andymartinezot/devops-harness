# Orchestration — the main session

> **Main only.** This file lives outside `.claude/rules/` on purpose: rules load into every subagent, and this one is for the orchestrating session. It is never in context until main reads it, so `/resume-handoff` reads it as step 0. Named agents never see it and never need it.

This file is behavior, not facts: it is the same in every project that uses the kit, so it holds no project facts. The project's routing table, shared-infra list and handoff exclusions live in the root `CLAUDE.md` under "Routing". Don't copy this file's content into `CLAUDE.md`, and don't edit it per project — improve it in the kit.

## Principles

1. **The harness is a guide, never an obstacle.** It exists to lead to more concrete, better solutions. When a rule blocks the right fix, flag it and change the rule — through the project's harness agent, with the user's approval. Don't bypass it silently, and don't obey it into a worse outcome. Prefer deleting text to adding it: every line loads into someone's context on every session.
2. **Subagents are the default, not an optimization.** Main reasons across repos, routes, verifies the decisive check and talks to the user; owners do the work; the inspector reads live state. Main doing owner work itself is the exception and is said out loud.
3. **The harness is changeable work.** The harness agent owns edits to agents, rules, skills, hooks, templates and this file; every change is shown to the user before it lands; generic improvements flow to the kit through the kit's own session, kept agnostic (no project facts).

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

**Worktree isolation (experimental).** Pass `isolation: "worktree"` on Agent calls that edit a repo, so the owner works in a copy and the user's clone stays untouched. When the workspace root is not a repo this can fail from the root; then the owner creates one itself — `git -C <repo> worktree add .worktrees/<ticket> -b <branch>` (adding `.worktrees/` to that repo's `.git/info/exclude`) — works there and reports the path. Main or the user pushes from it; nobody deletes a worktree they did not create.

## Thresholds

- **Re-delegation:** at most 2 re-delegations of the same task (two retries); after that, bring the defect to the user instead of spawning again.
- **Run size:** a run over ~100K tokens or ~40 tool uses in `docs/runs/` means the task was too big: split it next time, and note it at `/handoff`.
- **Expired auth:** an agent that hits expired SSO or other auth stops and reports the login command; main never re-spawns it to try again — the user logs in first.
- **Time:** hooks run in ≤5 s; a delegation silent for ~15 min: check the ledger (`docs/runs/<date>.md`) before spawning a duplicate.
- **One decisive check:** every delegation prompt names the one check the agent must run and main will re-run — no full re-audits.

## Every delegation prompt

Subagents start cold: they see none of this conversation. The prompt plus the files are everything they have.

1. **Goal**, plus the ticket or spec path.
2. **Files in scope**, and what **not** to touch. Warn when the target holds secrets (`secrets-handling.md`). When the agent will read config files, tell it to extract **key names structurally** (`yq 'keys'`, `jq 'keys'`, a `cut -d: -f1` on the key column) and never to print lines and redact them afterwards: filename surveys miss secrets in ordinary config, and hand-rolled redaction regexes fail on quoting.
3. **Permissions:** may it edit, commit, push? Default: edit and commit locally, **no push**.
4. **Env scope**, when live systems are involved.
5. **What to return:** conclusions and abridged evidence, never full logs or file dumps.
6. **The one decisive check** the agent must run and main will re-run.
7. "End with the output contract."

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
- **Instruction files are snapshotted at session start.** Subagents inherit the parent session's snapshot, so an edit to `CLAUDE.md`, a rule or the memory index reaches subagents only after a restart. Agent definitions under `.claude/agents/` and hooks are picked up live. To check what a subagent actually sees: spawn a cheap general-purpose agent with "do not use tools; list the instruction files you see with approximate line counts".

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

---

# Memory policy — main

The full policy. Agents get the short version in `.claude/rules/memory-policy.md`; main (the only writer) follows this one.

## Where memory lives

The real files are **`memory/` in the workspace root**, so the user can see, edit and review them, and they travel with the project.

The harness reads them through a symlink from its per-project memory directory:

```
~/.claude/projects/<encoded workspace path>/memory  →  <workspace>/memory
```

- **Don't "fix" that symlink.** It is deliberate. The harness path is keyed to the workspace's absolute path, so if the real files lived there, moving or renaming the workspace would orphan every memory silently.
- **If the workspace ever moves**, re-point that one symlink. The memories themselves are safe.
- `MEMORY.md` is the index, and it is **injected into every session automatically** — you already have it, so never read it again to "check".

Memory exists for one thing: knowledge that would otherwise be re-learned from scratch next session.

## The boundary — one source of truth per fact

| Kind of fact | Home | Not memory because |
|---|---|---|
| "Right now": critical path, blockers, open MRs/PRs, service × env | `STATUS.md` | it changes weekly |
| A decision and its status | `DECISIONS.md` → ADR / docs home | it has an owner and a date |
| How a repo's code works | that repo's `CLAUDE.md` | the repo already records it |
| How to reach an external tool, and its gotchas | `.claude/rules/integrations.md` | it is config, read by `/outbox` |
| What happened in one session | `docs/sessions/<date>-<role>-<slug>.md` | it is a narrative, not a fact |
| Ticket state | the tracker | the tracker wins, always |
| **Durable, cross-session, not in any repo** | **memory** | — |

What genuinely belongs in memory:
- An external process or who to contact, when finding out cost real time.
- A trap that already burned you and will burn you again.
- How the user wants work done, especially after a correction.
- Stable identifiers that aren't in any repo.

## Who writes

**Main only.** Named agents end their output contract with `## Memory candidates` and propose; main verifies the claim first — re-running the decisive check — and triages every candidate at `/handoff` (accepted, redirected to the file that owns the fact, or rejected with the reason). This keeps several agents from creating near-duplicate memories no one reviews.

## Never in memory

- Secret values, credentials, tokens — key names and counts only, per `secrets-handling.md`.
- Production data or personal data.
- Ticket state, code structure, or git history.
- Anything true only for the current conversation.

## Format

- One file, one fact. Filename stem **must** equal the frontmatter `name:`, which is also the `[[link]]` target. Breaking that invariant silently breaks links.
- Frontmatter: `name`, `description` (one line — it is what recall matches on), `metadata.type` of `user` | `feedback` | `project` | `reference`.
- `feedback` and `project` bodies end with `**Why:**` and `**How to apply:**`.
- Every memory gets one index line in `MEMORY.md`: `- [Title](<name>.md) — hook`.
- Link related memories with `[[name]]`. A link to a memory that doesn't exist yet is fine — it marks something worth writing.
- Convert relative dates to absolute.
- `/lint` (the kit's `scripts/harness-lint.sh`) checks all of the above.

## Maintenance

A memory records what was true when it was written, so treat it as a lead, not as truth:

- Before acting on a memory that names a file, flag, path or command, **confirm it still exists.**
- When a memory is wrong, **correct or delete that file.** Never add a second memory beside it — you get two conflicting recollections and no way to tell which is current.
- When you correct a memory, note the date and what was wrong, so the next reader knows it was reviewed rather than never checked.
- Fix the places the wrong fact already spread to (docs, ADRs, STATUS.md) in the same pass.
