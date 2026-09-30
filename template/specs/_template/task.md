# TASKS NNN — <Title>

**The work.** Contract and status live in `spec.md`; the approach lives in `plan.md`.

## Task table
One row per repo and file. Owner comes from the routing table in `CLAUDE.md` — every task has exactly one. Main dispatches these; independent owners run in parallel, same-repo tasks run in sequence.

| # | Repo | File(s) | Owner agent | Depends on | State | Commit |
|---|---|---|---|---|---|---|
| 1 | | | | — | todo | |

State values: `todo` → `in-progress` → `done` → or `n/a` with a reason. Fill `Commit` from the owner's output contract, not from memory.

## Needs from others
Items an owner raised that main must route. Keep until closed.

| From | Request | Routed to | Closed? |
|---|---|---|---|

## Outward writes
Tracker comments, MR/PR descriptions, doc updates this spec needs. Draft them as `/outbox` items and link the item here; never post from this file.

| Outbox item | Channel · target | Posted? |
|---|---|---|

## Evidence log
Append-only. Date, what was run, the outcome, and a pointer. Abridged command output only — never a secret value, never prod or personal data.

| Date | Check / action | Outcome | Pointer |
|---|---|---|---|

## Decisions made while executing
Mirror each as a row in `DECISIONS.md`. If it is ADR-worthy, say which ADR.

| Date | Decision | Recorded where |
|---|---|---|
