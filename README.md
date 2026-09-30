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
  .claude/rules/            change-safety · secrets-handling · git-conventions · memory-policy · integrations
  .claude/agents/           one read-only inspector to start; _example-agent.md for the rest
  .claude/skills/           spec · spec-verify · outbox · gitlab · harness-init (linked) · handoff · resume (copied)
  .claude/commands/         /lint
  specs/_template/          spec.md · plan.md · task.md  →  /spec creates specs/001-<slug>/
  docs/sessions/            one log per session (/handoff writes it, /resume reads it)
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

It surveys (names, never contents), asks the few facts it can't derive, copies `template/` and fills it. It never overwrites an existing `CLAUDE.md`; it merges into it. Start a fresh session so the new rules load, then `/resume`.

**Install per project, not user-wide.** `./install.sh` without `--project` links the skills into `~/.claude/skills/`, and user-wide skills outrank project skills with the same name. A user-wide `spec` then silently replaces a project's own `spec`. Per-project links avoid that, and fixes made here still reach every linked project. `./install.sh --list` and `--uninstall` take `--project` too.

## What made it useful (the guide part)

These are the lessons behind the files. Take them even if you take nothing else.

1. **One orchestrator, many owners.** The main session holds the map and routes. Agents own one area each and end every task with the same output contract: Result, Changes, Validation, Commits, Needs from others, Risks / follow-ups, Memory candidates. Uniform endings are what make delegation reviewable.
2. **Verify delegated claims.** Before a subagent's finding becomes durable state (STATUS, a ticket, memory), re-run the one check that decides it. Plausible-but-wrong facts spread fastest through summaries.
3. **One source of truth per fact.** "Now" goes in `STATUS.md`, decisions in `DECISIONS.md`, repo facts in that repo's `CLAUDE.md`, ticket state in the tracker, narrative in session logs, and only the durable, cross-session leftovers in memory. `memory-policy.md` has the boundary table.
4. **One write path.** Only main posts outside the project, through `/outbox`, with approval per item and a read-back. Agents draft. Afterwards there is a record of what was posted where, and nothing is posted twice.
5. **Specs for the risky changes only.** Multi-repo, non-dev env, shared infra, or needs a rollback plan → `/spec`, and close with `/spec-verify` on evidence. Everything else just gets done.
6. **Secrets: names, never values.** Most leaks are incidental (`grep -n` or `cat` on a secret file), not deliberate. Key lists, lengths and hashes cover every check you need. `secrets-handling.md` has the commands.
7. **Permissions are the seatbelt, not the wall.** `deny` for the irreversible, `ask` for outward writes, `allow` for reads. No hooks. Rules and per-item approval are what keep writes deliberate.
8. **Integrations are requested, not pre-wired.** A channel (tracker, wiki, repo host, chat) gets its row in `integrations.md` the first time it's needed: tool, read-only auth check, identifiers, and the gotchas learned by posting.
9. **Start small.** Main plus one read-only inspector. Add a domain agent when the same routing need recurs, and write a repo's `CLAUDE.md` the first time that repo is worked on.

## Day to day

| When | Run |
|---|---|
| Start of a session | `/resume` |
| A change that spans repos, touches a non-dev env or shared infra, or needs a rollback plan | `/spec`, then `/spec-verify` to close |
| Anything that leaves the project (MR, ticket comment, wiki page, chat) | `/outbox` |
| GitLab reads and MR mechanics | `/gitlab` |
| End of a session | `/handoff` |
| Now and then, or after editing the harness | `/lint` (`--live` also runs the auth checks) |

## Iterate

- **A project teaches something generic** (a better step, a missing guardrail, a lint check): fix it here. Linked skills pick it up at once; template files don't propagate to projects that already copied them, so diff and merge by hand when it matters.
- **A project teaches a fact** (a CLI quirk for its tracker, a host, an account): it goes in that project, usually the channel's row in `.claude/rules/integrations.md`, or memory. Never here.

## For an organization with many similar projects

When several projects share platforms and tools, fork `template/` into a **private** repo for that organization. Then:

- Pre-fill what is true for all of them: the tool rows in `integrations.md`, known accounts and clusters, platform gotchas.
- Leave per-project identifiers as `{{PLACEHOLDERS}}`.
- Copy skills into each project instead of linking them, and add a small bootstrap script with a `--check` mode. It should diff the behavior files (skills, commands, templates) against the fork, so improvements can flow back upstream.

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
