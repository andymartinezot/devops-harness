# devops-harness

A small, reusable kit for running a DevOps workspace with Claude Code: one orchestrating session that routes work, specs for risky changes, a single audited path for anything posted outside the workspace, session logs, and a memory that travels with the project.

It holds **behavior**, never facts. Every fact about a workspace — hosts, projects, envs, accounts, ticket keys, people — comes from that workspace or from you when an agent asks, and stays there.

## What's in it

| Path | What | How it's used |
|---|---|---|
| `.claude/skills/gitlab` | MRs, pipelines, failing-job diagnosis, CI variable **names**, on whatever GitLab host the remote points at | user-wide symlink |
| `.claude/skills/outbox` | The one write path: draft → approve by number → post → read back → record. Requests a channel's tool, auth and identifiers on first use | user-wide symlink |
| `.claude/skills/spec`, `spec-verify` | Spec-driven changes (`specs/NNN-slug/{spec,plan,task}.md`) and evidence-based closure | user-wide symlink |
| `.claude/skills/harness-init` | Bootstraps a workspace: surveys read-only, asks what it can't derive, fills `template/` | user-wide symlink |
| `template/` | `CLAUDE.md`, `STATUS.md`, `DECISIONS.md`, rules, an inspector agent, `handoff` / `resume`, spec / outbox / session / memory scaffolding — all `{{PLACEHOLDERS}}` | copied per workspace |
| `scripts/harness-lint.sh` | Read-only PASS/WARN/FAIL check of a workspace's harness; `--live` runs each enabled integration's auth check | run in a workspace |
| `scripts/check-agnostic.sh` | Fails if an org fact leaked into this kit | run before every commit here |

**Why skills are linked and the rest is copied:** skills are the same everywhere, so one copy serves every workspace. Rules, `CLAUDE.md` and agents describe one workspace, so each gets its own copy, filled in by asking. `handoff` and `resume` are copied rather than linked, so a workspace that already has its own keeps it.

## Install

```bash
./install.sh            # links the kit skills into ~/.claude/skills/
./install.sh --list     # installed / missing / conflict
./install.sh --uninstall
```

Idempotent. It never replaces a directory or a link that isn't its own. Use `--project <path>` to install into one workspace instead of user-wide. Personal skills outrank project skills with the same name, so remove a workspace's own `spec` / `spec-verify` once you've diffed them against the kit's.

`glab`, `jq` and `git` are the only tools the kit skills assume. Everything else is requested on first use.

## Adopt a workspace

In a new session at the workspace root:

```
/harness-init
```

It surveys (names, never contents), asks whether another workspace's `integrations.md` can be reused (tool rows and gotchas only, never identifiers), asks the few facts it can't derive — including whether harness files are **personal** (kept out of git by a path-scoped ignore) or **committed** — and then drafts. It merges into an existing `CLAUDE.md` and never overwrites. It starts with main plus one read-only inspector; add domain agents only when a routing need recurs.

Then start a fresh session so the new rules load, and run `/resume`.

## Day to day

| When | Run |
|---|---|
| Start of a session | `/resume` |
| A change that spans repos, touches a non-dev env or shared infra, or needs a rollback plan | `/spec`, then `/spec-verify` to close |
| Anything that leaves the workspace (MR, ticket comment, wiki page, chat) | `/outbox` |
| GitLab reads and MR mechanics | `/gitlab` |
| End of a session | `/handoff` |
| Now and then, or after editing the harness | `scripts/harness-lint.sh <workspace> [--live]` |

Guardrails are **permissions only** (`deny` / `ask` / `allow` in `.claude/settings.json`), no hooks. They are a seatbelt, not a wall: the rules in `change-safety.md` and per-item approval in `/outbox` are what actually keep writes deliberate.

## Iterate

- **A workspace teaches something generic** (a better step, a missing guardrail, a lint check): fix it here, in the kit. Every workspace gets it through the symlinks, or on its next `harness-init` for template files.
- **A workspace teaches a fact** (a CLI quirk for its tracker, a host, an account): it goes in that workspace — usually the channel's row in `.claude/rules/integrations.md`, or memory. Never here.
- Template changes don't propagate to workspaces that already copied them; diff and merge by hand when it matters.

## Keeping it agnostic

This repo is published, so it must never hold an org fact. Before every commit:

```bash
scripts/check-agnostic.sh
```

It checks for absolute home paths, 12-digit account IDs, email addresses, ticket keys and long token-like strings, and reports `file:line` only. Put your own org terms (company, internal tool and host names), one per line, in the gitignored `.agnostic-denylist.local`; the script fails on any of them too.

When writing a skill or template:
- Detect from the environment (git remote, `--help`, marker files) or ask; never assume a host, org or tool.
- Use `{{PLACEHOLDERS}}` for workspace facts and `ABC-123` / `example.com` in examples.
- Put gotchas you learn in the workspace's `integrations.md`, not in the skill.
- Never make a command print a secret: key names, lengths and hashes only.
