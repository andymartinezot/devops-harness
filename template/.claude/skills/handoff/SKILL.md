---
name: handoff
description: Write a session log to docs/sessions/<date>-<role>-<slug>.md summarizing what this session changed, its outcome and open threads, so the next session can /resume-handoff. Main also triages memory candidates (accepted / redirected / rejected, recorded in the log), asks for a STATUS.md refresh, and offers /outbox for unposted drafts. Use at the end of a session, or when the user says "handoff", "wrap up" or "log this session".
---

# Handoff — session log

Write a single markdown file under `docs/sessions/` summarizing this session. Make no other changes; the only extra actions are main's steps 5–7, and each needs the user's OK.

## Steps

1. **Compute today's date** as `YYYY-MM-DD`.
2. **Determine the role.** If you are running as a named agent, the role is its area (the agent name without the workspace prefix and `-agent` suffix). Otherwise the role is `main`. Several consoles can write logs on the same day; the role keeps `/resume-handoff` from picking up another console's log.
3. **Pick a slug** — 2–4 kebab-case words for the session's main focus. Derive it; don't ask.
4. **Write `docs/sessions/<date>-<role>-<slug>.md`** with the template below. Pull everything from this session's actual context — file edits, command output, decisions, posts. Do not invent. Older logs without a role segment stay as they are.
5. **Main only — memory triage.** Collect every candidate from this session: each `## Memory candidates` line the agents returned, plus your own sweep (a trap that will recur, an external process or contact that took real effort to find, a correction the user made to how you work). Classify each against the boundary table in `.claude/orchestrator.md` §Memory policy: **accepted** (→ a memory file, after the user's OK), **redirected** (the fact is real but belongs in a repo `CLAUDE.md`, `STATUS.md`, `integrations.md` or a spec — name the file and write it there now), or **rejected** (why: already recorded, session-only, wrong). Write the table into the log's `## Memory candidates — triaged` section so the same candidate is not re-proposed next session. Propose the accepted ones in one line each; write only what the user approves. Named agents skip this and list candidates in their output contract. An all-rejected table is a normal outcome; an empty table is not — agents always propose something.
6. **Main only — STATUS.md.** If `STATUS.md` exists and the session changed anything it tracks (critical path, service × env, blockers, MRs/PRs), update it — or, if `CLAUDE.md` routes `STATUS.md` to a docs agent, delegate the refresh to that agent with the log path.
7. **Main only — unposted drafts.** If `docs/outbox/` has items still in `draft` or `approved`, list them in one line and offer `/outbox`. Don't post from here.
8. **Tell the user** the path you wrote, one line on STATUS.md, one line on memories written (or none), and one line on pending outbox items (or none).

## Template

```markdown
# YYYY-MM-DD — <Title Case Session Topic>

## Goal
One paragraph: what we set out to do, as the user framed it.

## What changed
- **Files:** `path/to/file` — one-line why. (One bullet per file.)
- **Decisions:** ID — title — one-line summary. Or "none".
- **External systems:** durable changes outside the repos — cloud or CLI actions, secrets or DNS created out-of-band, tickets created or transitioned, pages published (with outbox item pointers). Or "none".
- **Version control:** branches pushed, MRs/PRs opened or merged (link). Or "none".

## Outcome
One paragraph: live, partially live, broken, rolled back, or on a branch awaiting review? Describe the actual state of the repos and any deployed envs. Pushed is not merged; merged is not deployed.

## Open threads
- One bullet per unresolved item, with enough context (ticket, file path, owner) that the next session can pick it up without re-asking.

## Memory candidates — triaged
| Candidate (one line) | Proposed by | Verdict | Where it went / why not |
|---|---|---|---|
| | agent name or main | accepted / redirected / rejected | `memory/<name>.md`, `<repo>/CLAUDE.md §…`, or the reason |

## Context for next /resume-handoff
2–4 lines: what's blocked on what, where to look first, non-obvious gotchas from this session that aren't written down anywhere else yet.
```

## Guardrails

- **Don't run tests or lint, commit, or push as part of /handoff.** It is a documentation step, not an integration step.
- **Never put secret values, prod data or personal data in the log** — key names, counts and pointers only.
- **The file is the summary.** Don't repeat its contents back to the user.
- **Be honest about broken state.** Half-done or broken goes under Outcome, explicitly.
- **External systems lists durable changes only.** Ticket creations, transitions and decisions — not every comment.
