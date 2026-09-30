---
name: spec-verify
description: Run a spec's acceptance checks read-only (through the workspace's inspector agent, if it has one), record the evidence in task.md, and move the spec to verified — or back to in-progress with the specific failures. Then queue the ticket and docs updates in the outbox. The orchestrating session uses it after the /spec tasks complete.
argument-hint: "<NNN-slug>   (directory under specs/)"
arguments:
  - spec
disable-model-invocation: true
---

# /spec-verify $spec

Reads `specs/$spec/`. All three files matter: `task.md` for completion, `plan.md` for rollback, `spec.md` for the checks and the status.

1. **Check the work is done.** Every row in `task.md` must be `done` with a commit, or `n/a` with a reason. If any isn't, stop and list them.
2. **Check there is a rollback.** The `plan.md` rollback table must hold a *recorded* prior value, not a description. If it doesn't, stop — verifying without a rollback path is not allowed.
3. **Run the checks.** Give the inspector agent named in the root `CLAUDE.md` routing (or run them yourself, read-only, if there is none) the `spec.md` section 6 table verbatim, with: "run each check exactly and report actual vs expected", "read-only", "names and counts only, never values". Add read-only checks for the `spec.md` section 4 invariants — typically that environments outside scope are untouched.
4. **Compare.** Mark each check `pass`, `fail` or `blocked` (credentials expired, env unreachable). **A check that wasn't run is not a pass.** Verify anything surprising yourself before recording it; a confident report is not evidence.
5. **Record.** Append to the `task.md` evidence log: the date, each check's outcome, and the abridged commands.
6. **Decide.**
   - **All pass:** set `Status: verified` in `spec.md`. Add outbox items (`/outbox`) for a ticket comment carrying the verified env results and for the docs this spec changes. Nothing posts until the user approves each item.
   - **Any fail:** leave `Status: in-progress`. Send the failing check back to the owning agent with the specific defect rather than redoing it. If a live env is broken, propose the `plan.md` rollback to the user first — roll back, then debug.
7. **Memory sweep.** If executing this spec surfaced a durable trap, an external process, or a correction to how work should be done, propose it as a memory per `.claude/rules/memory-policy.md`. Live state belongs in `STATUS.md`, not in memory.
8. Set `Status: closed` only when the user says the tickets are closed.
