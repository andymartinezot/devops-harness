# Change safety

Environment ladder: `{{ENV_LADDER}}`. Promote in that order. Never try something in a higher env first.

**Confirm with the user before:**
- Any mutation outside {{LOWEST_SHARED_ENV, e.g. dev}}: deploys, image changes, scaling, restarts, applies, deletes, cloud writes, secret-store writes.
- Any `git push`, MR/PR creation or merge, or branch deletion.
- Any tracker, wiki or chat write. Show the exact text first — through `/outbox`.
- Any change to shared or account-level infra: {{shared infra list, e.g. cluster bootstrap, DNS, WAF, IAM trust}}. These apply through their own pipelines, never by hand. Never run an IaC apply, a cluster create/delete, or a stack deploy yourself.

An approval covers the action you described, not the next one.

**Before any deploy or image change:**
- Record what is running now (image or version per deployment), so rollback is one command.
- Write it into the spec or the session log.

**When something breaks after a change:** roll back first, debug second.

**Read-only is always fine:** `get` / `describe` / `logs` / `list`, plan and template renders, `git status` / `log` / `diff` — secret values excepted (see `secrets-handling.md`).

**Production:**
- Production goes through the release flow: {{branches / manual jobs / approvals}}.
- {{Change-control regime, if any}}. Never bypass or suggest disabling the gates.
