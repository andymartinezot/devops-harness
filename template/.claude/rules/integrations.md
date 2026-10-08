# Integrations

How this workspace reaches each external system. `/outbox` reads this file to post; `harness-lint.sh --live` runs each enabled row's auth check.

**Rows are added on first use, never pre-wired.** When a channel has no row, `/outbox` runs the integration request flow: ask which tool, learn it from its `--help`, check auth (the user logs in with `! <command>`), ask for identifiers, propose permissions, and write the row only after the user agrees. A channel the user declines gets status `not enabled`.

- **Status** is `enabled` or `not enabled`. Note the date an enabled row's auth check last passed.
- **Auth check** must be a read-only command that exits non-zero when logged out and **never prints a token**. A check that fails once with a success body may be flaky: retry once before calling it logged out.
- **Identifiers** are the non-secret coordinates the tool needs: host, project/space key, page IDs, channel names. Never tokens.
- **Gotchas** are what the first post taught you. Add them here, never to the kit. A gotcha that is about the tool itself, not this project's use of it, is a candidate for the kit's skills too.
- **No `|` characters inside cells:** `harness-lint.sh --live` splits rows on them.

| Channel | Tool | Status | Auth check | Read | Write | Read-back | Identifiers | Gotchas |
|---|---|---|---|---|---|---|---|---|
