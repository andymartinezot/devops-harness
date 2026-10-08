# Change safety

Environment ladder: `{{ENV_LADDER}}`. Promote in that order. Never try something in a higher env first.

**Confirm with the user before:**
- Any mutation outside {{LOWEST_SHARED_ENV, e.g. dev}}: deploys, image changes, scaling, restarts, applies, deletes, cloud writes, secret-store writes.
- Any `git push`, MR/PR creation or merge, or branch deletion.
- Any tracker, wiki or chat write. Show the exact text first — through `/outbox`.
- Any change to shared or account-level infra: {{shared infra list, e.g. cluster bootstrap, DNS, WAF, IAM trust}}. These apply through their own pipelines, never by hand. Never run an IaC apply, a cluster create/delete, or a stack deploy yourself.

An approval covers the action you described, not the next one.

**A hand change the user authorises** (e.g. a console fix during an incident) must match the IaC config exactly, so the follow-up apply is a no-op. Back up the prior value first, and record both in the session log.

**Before any change to a live resource:**
- Record the prior state so rollback is one command: the image or version per deployment, the pinned version in the deploy repo, or the raw policy JSON.
- Write it into the spec or the session log.

**Multi-region or multi-cluster envs:** a change is done when every region or cluster in that env has it. One that lands only in the primary leaves an untested standby.

**When something breaks after a change:** roll back first, debug second.

**Read-only is always fine:** `get` / `describe` / `logs` / `list`, plan and template renders, `git status` / `log` / `diff` / `fetch`, and `git merge --ff-only` on a clean default branch — secret values excepted (see `secrets-handling.md`).

**Production:**
- Production goes through the release flow: {{branches / manual jobs / approvals}}.
- {{Change-control regime, if any}}. Never bypass or suggest disabling the gates, and never deploy outside them.
- Treat any production mutation as needing a second reviewer, even when the identical lower-env change was already approved.
