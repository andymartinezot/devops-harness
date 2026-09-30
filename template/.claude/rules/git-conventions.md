# Git conventions

- **Where to run git.** {{Is the workspace root a repo? If not: "Each subdirectory is its own repo; run git inside the subproject. Container dirs: <list> — run git one level deeper."}}
- **Harness files are {{personal | committed}}.**
  - *Personal:* `CLAUDE.md` and `.claude/` are ignored for every repo under `{{WORKSPACE_PARENT}}` by a scoped excludesFile (`~/.gitconfig` `includeIf "gitdir/i:{{WORKSPACE_PARENT}}/"` → a per-scope gitconfig → its own ignore file). Repos outside that path are unaffected. A clean `git status` therefore doesn't mean nothing was written. To see why a path is ignored: `git check-ignore --no-index -v <path>`.
  - *Committed:* harness files are reviewed like code. Never commit `.claude/settings.local.json`.
- **Branches:**
  - {{branch → env mapping, e.g. "`develop` builds dev", "`release/*` builds staging", "`main` builds prod"}}
  - Feature branches: `{{BRANCH_TEMPLATE, e.g. ABC-123_<slug>}}`.
- **Commit subject:** `{{SUBJECT_TEMPLATE, e.g. [ABC-123] <imperative summary>}}`. Ticket keys match `{{TICKET_REGEX}}`. The key must be the ticket the work belongs to — check it against the branch and the ticket before committing.
- **Commit-message or branch prefixes that trigger CI** are not decoration. List them here and use them only on purpose:
  - {{prefix → what it triggers}}
- **Temporary test triggers** added to CI config must be removed in a follow-up commit that is a **byte-exact revert**. Verify with `git diff <commit-before-the-add> HEAD -- <ci-file>`, which must print nothing.
- **Git hooks.** Never bypass them (`--no-verify`) unless the user explicitly authorizes it for that repo and that push.
- **Destructive operations.** Never force-push, reset, rebase shared branches, or delete branches without explicit confirmation.
