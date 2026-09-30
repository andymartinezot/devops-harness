---
name: spec
description: Start or update a spec-driven (SDD) change as a numbered directory specs/NNN-<slug>/ holding spec.md (what and why, and the only place Status lives), plan.md (how, gates, rollback) and task.md (the work, one owner per row). The orchestrating session uses it before any change that spans repos, touches a non-dev environment or shared infra, or needs a rollback plan. It gathers current-state evidence read-only and gets user approval before dispatching tasks.
argument-hint: "<slug> [<ticket>[,<ticket>...]]   e.g. secrets-source ABC-123,ABC-124"
arguments:
  - slug
  - tickets
disable-model-invocation: true
---

# /spec $slug $tickets

Only the orchestrating session runs this skill. Named agents return their work to it instead.

Names used below come from the workspace, not from this skill:
- **inspector** — the read-only agent in the root `CLAUDE.md` routing table (live checks, evidence). If
  there is none, main gathers the evidence itself, read-only.
- **owners** — the agents in that routing table. If there are none, main is the owner.
- **ladder** — the environment order in the workspace's `CLAUDE.md` / change-safety rule.

## 1. Locate or create the directory

```bash
ls -1 specs 2>/dev/null | grep -oE '^[0-9]{3}' | sort -n | tail -1
```

- If a `specs/NNN-$slug/` already exists, **resume it**: read all three files and its `Status`. Never renumber an existing spec.
- Otherwise the number is that value + 1, zero-padded to 3 (empty → `001`). Copy `specs/_template/` to `specs/NNN-$slug/` and replace `NNN` and `<Title>` in all three headers.

The directory name carries the slug only. The tickets go in `spec.md`, because one spec routinely covers several.

## 2. Fill in the contract (`spec.md`)

- Header: `$tickets`, `Status: draft`, owners from the routing table, envs in scope, today's date.
- **1 Intent** from the user's request plus the tickets — read each through the tracker listed in `.claude/rules/integrations.md`. If the tracker isn't enabled, ask the user for the ticket summary instead.
- **2 Current state:** delegate the evidence to the inspector, per env in scope, and to the owning repo agents for code facts. Paste their evidence abridged, with the command as the pointer. Never a secret value. Anything you could not verify is `TODO: verify` plus what would settle it.
- **3 Desired state matrix**, **4 Invariants** (always include "environments outside scope unchanged" and "production gates unchanged"), **5 Blast radius** (name any shared account, cluster or tenant explicitly), **6 Acceptance checks**.

## 3. Fill in the approach (`plan.md`)

Rollout order along the ladder with its gates, the recorded rollback state, alternatives considered and why rejected, and any open questions. Main writes this itself — it is the cross-repo reasoning main exists to do.

## 4. Fill in the work (`task.md`)

One task row per repo and file, each with exactly one owner, plus dependencies.

## 5. Self-review before showing the user

- Every task has one owner.
- Every non-dev step has a gate.
- Every change has a rollback with a **recorded** prior value.
- Every desired-state cell has an acceptance check.
- No task depends on a `TODO: verify` fact or an open question.
- `Status` appears in `spec.md` and nowhere else.

## 6. Approval

Summarize for the user: intent, the matrix, tasks by owner, the gates, and the open questions. Ask the open questions with `AskUserQuestion`. On approval set `Status: approved` in `spec.md`, record decisions in `task.md` and as a row in `DECISIONS.md`.

## 7. Dispatch

- Set `Status: in-progress`.
- Run independent owners in parallel with the delegation prompt from the root `CLAUDE.md`. Include the spec directory path, that owner's task rows, what not to touch, and permissions.
- Update each task row's Status and Commit from the owner's output contract — verify the claims that matter first.
- Route every `Needs from others` item and track it in that table.
- Anything that must be posted outside the workspace (ticket comments, MRs) goes through `/outbox`.

When all tasks are `done` or `n/a`, run `/spec-verify NNN-$slug`.
