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
  .claude/settings.json     allow reads · ask for writes · deny force-push / IaC apply / secret reads
  .claude/rules/            orchestrator (behavior, same everywhere) · change-safety · secrets-handling
                            git-conventions · memory-policy · integrations
  .claude/agents/           one read-only inspector to start, filled from .claude/templates/
  .claude/templates/        inspector-agent · domain-agent · repo-CLAUDE.md (outside agents/: every file there registers)
  .claude/skills/           spec · spec-verify · outbox · gitlab · harness-init (linked) · handoff · resume-handoff (copied)
  .claude/commands/         /lint
  specs/_template/          spec.md · plan.md · task.md  →  /spec creates specs/001-<slug>/
  docs/sessions/            one log per session (/handoff writes it, /resume-handoff reads it)
  docs/outbox/              every external post: draft → approved → posted, with id/url
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

**Install per project, not user-wide.** `./install.sh` without `--project` links the skills into `~/.claude/skills/`, and user-wide skills outrank project skills with the same name. A user-wide `spec` then silently replaces a project's own `spec`. Per-project links avoid that, and fixes made here still reach every linked project. `./install.sh --list` and `--uninstall` take `--project` too.

## What made it useful (the guide part)

These are the lessons behind the files. Take them even if you take nothing else.

1. **One orchestrator, many owners.** The main session holds the map and routes. Agents own one area each and end every task with the same output contract: Result, Changes, Validation, Commits, Needs from others, Risks / follow-ups, Memory candidates. Uniform endings are what make delegation reviewable. The protocol lives in one behavior file, `.claude/rules/orchestrator.md`, identical in every project; `CLAUDE.md` keeps only the project's routing table.
2. **Delegate by default; main's context is the scarcest resource.** Edits, reads of more than a few files, log trawls, test runs and live checks go to a subagent, which returns conclusions, not dumps. Every delegation prompt carries the goal, scope and what not to touch, permissions, env scope and the return shape — subagents start cold.
3. **Verify delegated claims.** Before a subagent's finding becomes durable state (STATUS, a ticket, memory), re-run the one check that decides it. Plausible-but-wrong facts spread fastest through summaries.
4. **One source of truth per fact.** "Now" goes in `STATUS.md`, decisions in `DECISIONS.md`, repo facts in that repo's `CLAUDE.md`, ticket state in the tracker, narrative in session logs, and only the durable, cross-session leftovers in memory. `memory-policy.md` has the boundary table.
5. **Write state down, so context loss costs nothing.** Assume the session can compact or end any time. Progress goes to the spec's `task.md`, "now" to `STATUS.md`, the narrative to a session log. One workstream per session: when it gets long, `/handoff`, start fresh, `/resume-handoff` — a fresh window with good files beats a long window with a summary of itself.
6. **A `CLAUDE.md` in every repo you work in.** Claude Code loads it whenever work touches that repo, for main and subagents alike, so repo knowledge arrives without costing context anywhere else. Keep it short, verified against the repo, and current — its owner updates it in the same task that changes a command or gotcha.
7. **One write path.** Only main posts outside the project, through `/outbox`, with approval per item and a read-back. Agents draft. Afterwards there is a record of what was posted where, and nothing is posted twice.
8. **Specs for the risky changes only.** Multi-repo, non-dev env, shared infra, or needs a rollback plan → `/spec`, and close with `/spec-verify` on evidence. Everything else just gets done.
9. **Secrets: names, never values.** Most leaks are incidental (`grep -n` or `cat` on a secret file, a redaction regex that silently didn't match), not deliberate. Ordinary config carries committed secrets too, so survey it by counting secret-shaped keys. Key lists, counts, lengths and hashes cover every check you need; never print-then-redact. `secrets-handling.md` has the commands.
10. **Permissions are the seatbelt, not the wall.** `deny` for the irreversible, `ask` for outward writes, `allow` for reads. No hooks. Rules and per-item approval are what keep writes deliberate.
11. **Integrations are requested, not pre-wired.** A channel (tracker, wiki, repo host, chat) gets its row in `integrations.md` the first time it's needed: tool, read-only auth check, identifiers, and the gotchas learned by posting.
12. **Start small.** Main plus one read-only inspector. Add a domain agent when the same routing need recurs, grouping repos by stack and knowledge boundary rather than one agent per repo. Templates live in `.claude/templates/`, never in `.claude/agents/`, where Claude Code would register them as real agents.

## Day to day

| When | Run |
|---|---|
| Start of a session | `/resume-handoff` |
| A change that spans repos, touches a non-dev env or shared infra, or needs a rollback plan | `/spec`, then `/spec-verify` to close |
| Anything that leaves the project (MR, ticket comment, wiki page, chat) | `/outbox` |
| GitLab reads and MR mechanics | `/gitlab` |
| End of a session, or when it gets long or the workstream changes | `/handoff`, then a fresh session |
| Now and then, or after editing the harness | `/lint` (`--live` also runs the auth checks) |

## Iterate

- **A project teaches something generic** (a better step, a missing guardrail, a lint check): fix it here. Linked skills pick it up at once; template files don't propagate to projects that already copied them, so diff and merge by hand when it matters.
- **Upgrading a project set up from an older kit:** copy `template/.claude/rules/orchestrator.md` and `template/.claude/templates/` in, move any `.claude/agents/_*.md` template out to `.claude/templates/` (`/lint` FAILs it — Claude Code registers it as an agent), rename the `resume` skill to `resume-handoff`, and slim the `CLAUDE.md` orchestrator section down to the template's "Routing" section.
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
