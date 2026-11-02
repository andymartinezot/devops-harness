# devops-harness

A guide, and a working reference implementation, for giving any DevOps project a useful Claude Code harness: one orchestrating session that routes work, specs for risky changes, a single audited path for anything posted outside the project, session logs, and a memory that travels with the project.

It holds **behavior**, never facts. Every fact about a project — hosts, envs, accounts, ticket keys, people — comes from that project or from you when an agent asks, and stays there.

## The baseline

Every project starts from the same small set. Nothing more is needed on day one.

```
<project>/
  CLAUDE.md                 the map: what's here, how it connects, envs, who owns what, where state lives
  STATUS.md                 "right now": critical path, service × env, blockers, open MRs
  DECISIONS.md              decision index (one row each; bodies live elsewhere)
  .claude/settings.json     allow reads · ask for writes · deny force-push / IaC apply / secret reads · the two ledger hooks
  .claude/orchestrator.md   how main orchestrates (behavior, same everywhere) — main-only, read by /resume-handoff,
                            deliberately NOT under rules/ so subagents don't carry it
  .claude/rules/            what every subagent needs to act safely: change-safety · secrets-handling
                            git-conventions · memory-policy (short) · integrations
  .claude/agents/           a read-only inspector and a harness agent to start, filled from .claude/templates/
  .claude/templates/        inspector-agent · harness-agent · domain-agent · repo-CLAUDE.md (outside agents/: every file there registers)
  .claude/skills/           spec · spec-verify · outbox · gitlab · lint · retro · harness-init (linked) · handoff · resume-handoff (copied)
  .claude/scripts/          ledger-subagent.sh · ledger-mutation.sh (observer hooks: exit 0 always, names and numbers only)
  specs/_template/          spec.md · plan.md · task.md  →  /spec creates specs/001-<slug>/
  docs/sessions/            one log per session (/handoff writes it, /resume-handoff reads it)
  docs/outbox/              every external post: draft → approved → posted, with id/url
  docs/runs/                the run ledger: one row per finished subagent (tokens, tools, seconds) and per outward mutation
  memory/MEMORY.md          durable cross-session memory, index injected every session
```

## Set up a project

```bash
./install.sh --project <path>    # link the kit skills into <path>/.claude/skills/
```

Then, in a Claude Code session at the project root:

```
/harness-init
```

It surveys (names, never contents), asks the few facts it can't derive, copies `template/` and fills it. It never overwrites an existing `CLAUDE.md`; it merges into it. Start a fresh session so the new rules load, then `/resume-handoff`.

**Instruction files are a snapshot.** `CLAUDE.md`, the rules and the memory index are read at session start, and subagents inherit the parent's snapshot: an edit to them reaches subagents only after a restart. Agent definitions under `.claude/agents/` and hooks are picked up live, so a new agent is spawnable within minutes. To see what a subagent really carries, spawn a cheap general-purpose agent with "do not use tools; list the instruction files you see with approximate line counts".

**Install per project, not user-wide.** `./install.sh` without `--project` links the skills into `~/.claude/skills/`, and user-wide skills outrank project skills with the same name. A user-wide `spec` then silently replaces a project's own `spec`. Per-project links avoid that, and fixes made here still reach every linked project. `./install.sh --list` and `--uninstall` take `--project` too.

## What made it useful (the guide part)

These are the lessons behind the files. Take them even if you take nothing else.

0. **The harness is a guide, never an obstacle.** It exists to lead to more concrete, better solutions. When a rule blocks the right fix, flag it and change the rule, through the project's harness agent with the user's approval. Don't bypass it silently, and don't obey it into a worse outcome. Prefer deleting text to adding it: every line loads into someone's context on every session.
1. **One orchestrator, many owners.** The main session holds the map and routes. Agents own one area each and end every task with the same output contract: Result, Changes, Validation, Commits, Needs from others, Risks / follow-ups, Memory candidates. Uniform endings are what make delegation reviewable. The protocol lives in one behavior file, `.claude/orchestrator.md`, identical in every project; `CLAUDE.md` keeps only the project's routing table. That file sits outside `.claude/rules/` on purpose: rules load into every subagent, and a cold subagent already carries the user's and project's `CLAUDE.md` plus every rule before it reads its own prompt. Keep `rules/` to what a subagent needs to act safely; main-only text goes in the orchestrator file, which `/resume-handoff` reads.
2. **Delegate by default; main's context is the scarcest resource.** Edits, reads of more than a few files, log trawls, test runs and live checks go to a subagent, which returns conclusions, not dumps. Every delegation prompt carries the goal, scope and what not to touch, permissions, env scope and the return shape — subagents start cold.
3. **Verify delegated claims.** Before a subagent's finding becomes durable state (STATUS, a ticket, memory), re-run the one check that decides it. Plausible-but-wrong facts spread fastest through summaries.
4. **One source of truth per fact.** "Now" goes in `STATUS.md`, decisions in `DECISIONS.md`, repo facts in that repo's `CLAUDE.md`, ticket state in the tracker, narrative in session logs, and only the durable, cross-session leftovers in memory. `memory-policy.md` has the boundary table.
5. **Write state down, so context loss costs nothing.** Assume the session can compact or end any time. Progress goes to the spec's `task.md`, "now" to `STATUS.md`, the narrative to a session log. One workstream per session: when it gets long, `/handoff`, start fresh, `/resume-handoff` — a fresh window with good files beats a long window with a summary of itself.
6. **A `CLAUDE.md` in every repo you work in.** Claude Code loads it whenever work touches that repo, for main and subagents alike, so repo knowledge arrives without costing context anywhere else. Keep it short, verified against the repo, and current — its owner updates it in the same task that changes a command or gotcha.
7. **One write path.** Only main posts outside the project, through `/outbox`, with approval per item and a read-back. Agents draft. Afterwards there is a record of what was posted where, and nothing is posted twice.
8. **Specs for the risky changes only.** Multi-repo, non-dev env, shared infra, or needs a rollback plan → `/spec`, and close with `/spec-verify` on evidence. Everything else just gets done.
9. **Secrets: names, never values.** Most leaks are incidental (`grep -n` or `cat` on a secret file, a redaction regex that silently didn't match), not deliberate. Ordinary config carries committed secrets too, so survey it by counting secret-shaped keys. Key lists, counts, lengths and hashes cover every check you need; never print-then-redact. `secrets-handling.md` has the commands.
10. **Permissions are the seatbelt, not the wall.** `deny` for the irreversible, `ask` for outward writes, `allow` for reads. Rules and per-item approval are what keep writes deliberate. Hooks only observe: the two ledger hooks append a row per finished subagent (label, tokens, tool uses, seconds, model) and per outward mutation (abridged command, returned id) to `docs/runs/<date>.md`, always exit 0, and store field names and numbers, never payload content. The `SubagentStop` payload carries no metrics; they come from the agent's transcript file. The number that matches the host's own subagent total is the final turn's input, cache-read, cache-creation and output tokens, not a sum over turns, which would count the cached context once per turn.
11. **Integrations are requested, not pre-wired.** A channel (tracker, wiki, repo host, chat) gets its row in `integrations.md` the first time it's needed: tool, read-only auth check, identifiers, and the gotchas learned by posting.
12. **Start small.** Main plus one read-only inspector and one harness agent. Add a domain agent when the same routing need recurs, grouping repos by stack and knowledge boundary rather than one agent per repo. Templates live in `.claude/templates/`, never in `.claude/agents/`, where Claude Code would register them as real agents.
13. **The harness is changeable work, with one owner.** The harness agent owns edits to agents, rules, local skills, hooks, templates and the orchestrator file. It backs up first when the root is unversioned, tests a hook with `{}` and garbage before wiring it, runs `/lint`, reports the line delta of what loads into subagents, shows every change to the user before it lands, and notes when a change (a rule or `CLAUDE.md`) needs a restart to reach subagents. Permissions and the kit stay out of its scope; generic improvements come back here, agnostic.
14. **Memory candidates get triaged, not swept.** At `/handoff`, every candidate an agent proposed is accepted, redirected to the file that owns the fact (a repo `CLAUDE.md`, `STATUS.md`, `integrations.md`, a spec) or rejected with the reason, and the table goes in the session log so nothing is re-proposed. An all-rejected table is normal; an empty one means the agents weren't asked.

## Day to day

| When | Run |
|---|---|
| Start of a session | `/resume-handoff` |
| A change that spans repos, touches a non-dev env or shared infra, or needs a rollback plan | `/spec`, then `/spec-verify` to close |
| Anything that leaves the project (MR, ticket comment, wiki page, chat) | `/outbox` |
| GitLab reads and MR mechanics | `/gitlab` |
| End of a session, or when it gets long or the workstream changes | `/handoff`, then a fresh session |
| Now and then, or after editing the harness | `/lint` (`--live` also runs the auth checks) |
| Weekly, or before porting harness changes to the kit | `/retro` — subagent runs and tokens, mutations, spec and memory churn from `docs/runs/` |

## Iterate

- **A project teaches something generic** (a better step, a missing guardrail, a lint check): fix it here. Linked skills pick it up at once; template files don't propagate to projects that already copied them, so diff and merge by hand when it matters.
- **Upgrading a project set up from an older kit:** move `.claude/rules/orchestrator.md` to `.claude/orchestrator.md` and replace it with `template/.claude/orchestrator.md` (it now carries the principles and main's full memory policy); replace `.claude/rules/memory-policy.md` with the short agent version; copy `template/.claude/templates/`, `template/.claude/scripts/`, `template/docs/runs/README.md` and the `hooks` block of `template/.claude/settings.json` in; create the harness agent from its template and add its routing row; re-link the skills (`./install.sh --project <path>`) and delete `.claude/commands/lint.md`; update `handoff` and `resume-handoff` from the template (memory triage, orchestrator step 0); in each agent, replace any "read the rules" step with "the files under `.claude/rules/` are already in your context"; move any `.claude/agents/_*.md` template out to `.claude/templates/` (`/lint` FAILs it — Claude Code registers it as an agent); rename the `resume` skill to `resume-handoff`; slim the `CLAUDE.md` orchestrator section down to the template's "Routing" section. Then restart, and run `/lint`.
- **A project teaches a fact** (a CLI quirk for its tracker, a host, an account): it goes in that project, usually the channel's row in `.claude/rules/integrations.md`, or memory. Never here.

## For an organization with many similar projects

When several projects share platforms and tools, fork `template/` into a **private** repo for that organization. Then:

- Pre-fill what is true for all of them: the tool rows in `integrations.md`, known accounts and clusters, platform gotchas.
- Leave per-project identifiers as `{{PLACEHOLDERS}}`.
- Copy skills into each project instead of linking them, and add a small bootstrap script with a `--check` mode. It should diff the behavior files (skills, commands, `.claude/templates/`, the orchestrator rule, spec and outbox templates) against the fork, so improvements can flow back upstream.

Keep org facts in that fork, never here.

## Keeping it agnostic

This repo is published, so it must never hold an org fact. Before every commit:

```bash
scripts/check-agnostic.sh
```

It checks for absolute home paths, 12-digit account IDs, email addresses, ticket keys and long token-like strings, and reports `file:line` only. Put your own org terms (company, internal tool and host names), one per line, in the gitignored `.agnostic-denylist.local`; the script fails on any of them too.

When writing a skill or template:
- Detect from the environment (git remote, `--help`, marker files) or ask; never assume a host, org or tool.
- Use `{{PLACEHOLDERS}}` for project facts and `ABC-123` / `example.com` in examples.
- Put gotchas you learn in the project's `integrations.md`, not in the skill.
- Never make a command print a secret: key names, lengths and hashes only.
