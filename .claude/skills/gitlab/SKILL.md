---
name: gitlab
description: Work with GitLab from any repo — merge requests (list, view, diff, create, comment), pipelines and failing-job diagnosis, CI variable NAMES, and project info — on whatever GitLab host the git remote points at (self-managed or gitlab.com; never assumed). Reads run freely; every write (push, MR create/update/comment, job retry) is shown as an exact command first and runs only after explicit confirmation. Never merges, never plays manual or deploy jobs, never prints job logs or variable values in full. Trigger on `/gitlab`, "open an MR", "MR status", "why did the pipeline fail", or any GitLab task in a repo whose origin is a GitLab host.
argument-hint: "[setup|mr|pipeline|job|vars] [args]"
---

> **Language:** Respond in the user's language. If unclear, default to the language of the user's message.

# GitLab — MRs, pipelines, jobs, variables

Uses the `glab` CLI against the GitLab host the repo actually lives on. Nothing here is host-, group- or
project-specific. **Detect, never assume** — least of all that the host is gitlab.com.

## Step 0 — Detect (always first, all cheap, run in parallel)

```sh
git remote get-url origin                 # → host + group/project
git branch --show-current
glab version                              # flags drift between versions
glab auth status --hostname <host>        # NEVER add --show-token / -t
```

- **Host and project** come from the remote URL: `git@<host>:<group>/<project>.git` or
  `https://<host>/<group>/<project>.git`. Subgroups are part of the path. Outside a repo, ask for both
  and pass `-R <group>/<project>` (and `--hostname <host>` to `glab api`).
- **Not a GitLab remote** (e.g. a GitHub host) → say so and stop.
- **Default branch:** `glab repo view -F json --jq .default_branch`, else `git rev-parse --abbrev-ref origin/HEAD`.
  Never a literal `main`.
- **Conventions** (ticket key, MR title shape): what the project's `CLAUDE.md`, `.claude/rules/` or
  `CONTRIBUTING.md` states, else the majority shape of `git log --oneline -20`. Ask if still ambiguous.
  If `.gitlab/merge_request_templates/` exists, the description follows that template.
- **Flags:** before the first *write* with a given subcommand in a session, run `glab <cmd> --help`.
  Some subcommands are marked EXPERIMENTAL and change between releases; when one is, or a flag is
  missing, use the REST route through `glab api` with an explicit `--method`.

State what was detected in one line before acting, e.g.
`Detected: host=<host> · project=<group>/<project> · default=<branch> · glab <version> · auth ok`.

## `setup` — when auth fails

Don't retry in a loop. Give the user the exact command to run themselves with the `!` prefix, so it
executes in their session:

```sh
! glab auth login --hostname <host>                               # interactive
! <their-secret-tool> | glab auth login --hostname <host> --stdin # token from their own store
```

- **Never** ask for a token in chat, never echo one, never write one to a file.
- Setting the default host (`glab config set -g host <host>`) changes global config — ask first.
- Re-run `glab auth status --hostname <host>` to confirm, then continue.

## Reads (no confirmation needed)

| Need | Command |
|---|---|
| MRs for this branch | `glab mr list -s <branch> -F json` |
| One MR | `glab mr view <iid> -F json --jq '{iid,title,state,draft,web_url,merge_status,pipeline:.head_pipeline.status}'` |
| Discussion | `glab mr view <iid> --comments` (or `--unresolved`) |
| Diff | `glab mr diff <iid> --raw` |
| Pipelines | `glab ci list -F json` · `glab ci list --status failed -F json` |
| One pipeline | `glab ci get -p <id> -F json` (or `-b <branch>`, `--merge-request <iid>`) |
| Jobs in a pipeline | `glab api --method GET "projects/:fullpath/pipelines/<id>/jobs?per_page=100" \| jq -r '.[] \| [.id,.stage,.name,.status] \| @tsv'` |
| Anything else | `glab api --method GET "projects/:fullpath/…"` |

Always pass `--method GET` to `glab api` explicitly: any `-f`/`-F` field silently turns a call into a `POST`.

## Failing-job diagnosis — logs are payload-bearing

Job logs routinely contain tokens, account IDs, hostnames and echoed variables. The whole log must
never land in the transcript.

```sh
f=$(mktemp) && chmod 600 "$f"
glab api --method GET "projects/:fullpath/jobs/<job-id>/trace" > "$f"
wc -l < "$f"
grep -n -iE 'error|fail|exception|denied|forbidden|not found|timed out|exit code' "$f" \
  | cut -c1-200 | sed -E 's/[A-Za-z0-9+=_-]{32,}/<redacted>/g' | tail -40
rm -f "$f"
```

- Widen with more grep context (`-B2 -A2`) only around a specific line number, keeping the same
  `cut` + `sed` masking.
- **Never** `glab ci trace` (streams the full log) and **never** `glab ci get --with-variables`.
- If a line still looks like a credential after masking, stop, report the **line number only**, and
  tell the user.
- When reporting in an MR, ticket or doc, **summarize** the failure — don't paste log lines.

## CI/CD variables — names only

```sh
glab variable list -F json | jq -r '.[].key'           # project
glab variable list -g <group> -F json | jq -r '.[].key' # group
```

Never print `.value` and never run `glab variable get`. To prove two values match, compare hashes
computed without displaying either value.

## Writes — show the exact command, wait for an explicit "yes"

If the workspace keeps an outbox (`docs/outbox/`), add the write as an outbox item instead of running it
here; the outbox posts it after approval and records the result.

| Write | Command |
|---|---|
| Push a branch | `git push -u origin <branch>` — never `--force`; never `--no-verify` unless the user authorizes it for this push |
| Create an MR | `glab mr create --source-branch <b> --target-branch <default> --title "<t>" --description-file <file> --remove-source-branch [--draft] --yes` |
| Create an MR without glab | `git push -u origin <b> -o merge_request.create -o merge_request.target=<default> -o merge_request.title="<t>"` |
| Comment on an MR | `glab mr note create …` per `--help`, else `glab api --method POST "projects/:fullpath/merge_requests/<iid>/notes" --field body=@<file>` (`@file` works with `--field`, not `--raw-field`) |
| Update an MR (title, draft, labels…) | `glab mr update <iid> …` per `--help`, else `glab api --method PUT "projects/:fullpath/merge_requests/<iid>" --raw-field …` |
| Retry a failed job | `glab ci retry <job-id>` — only for jobs that don't deploy or mutate an environment |

- Write MR descriptions and comments to a temp file first, show it, then pass the file — no shell-quoted
  multi-paragraph strings.
- Check the draft for secrets, production or personal data before showing it. "Pushed" or "merged" is
  not "deployed": say which one happened.

## After every write — verify and report

```sh
glab mr view <iid> -F json --jq '{web_url,state,draft,pipeline:.head_pipeline.status}'
```

Report the URL, state, pipeline status and the next action in 2-4 lines. If the write failed, report the
error as returned and stop — don't retry with different flags without saying so.

## Never

- **Merge.** Propose `glab mr merge <iid> [--squash] [--remove-source-branch]` and let the user approve
  or run it, in the current turn.
- **Approve an MR the user authored**, or approve at all unless asked.
- **Run, trigger or play pipelines and manual jobs** (`glab ci run`, `glab ci trigger`, a job's play
  action). Manual jobs are commonly deploy gates; only the user starts them.
- Cancel someone else's pipeline, or delete branches, pipelines, tags or variables.
- Read variable values, print full job logs, or use `--show-token`.
- Override the project's own change-safety rules (CLAUDE.md, `.claude/rules/`); where they are stricter,
  they win.

## Suggested permissions (propose, write only if the user agrees)

For the project's `.claude/settings.json`:

- **allow** — `Bash(glab mr list *)`, `Bash(glab mr view *)`, `Bash(glab mr diff *)`, `Bash(glab ci list *)`,
  `Bash(glab ci get *)`, `Bash(glab repo view *)`, `Bash(glab auth status --hostname *)`, `Bash(glab version)`,
  `Bash(glab api --method GET *)`
- **ask** — `Bash(glab mr create *)`, `Bash(glab mr update *)`, `Bash(glab mr note *)`,
  `Bash(glab mr approve *)`, `Bash(glab mr merge *)`, `Bash(glab ci retry *)`, `Bash(glab ci run *)`,
  `Bash(glab ci trigger *)`, `Bash(glab api --method POST *)`, `Bash(glab api --method PUT *)`,
  `Bash(glab api --method DELETE *)`, `Bash(git push *)`
- **deny** — `Bash(glab ci trace *)`, `Bash(glab ci get *--with-variables*)`,
  `Bash(glab auth status *--show-token*)`, `Bash(glab variable get *)`, `Bash(glab variable export *)`.
  These must be deny, not merely left out: allow rules match by prefix, so an allowed `glab ci get`
  would otherwise run `--with-variables` silently. Deny beats allow.
- Permission rules are a seatbelt, not a wall — the rules above still apply.

## Examples

```
/gitlab mr
   → Detects host/project from origin, finds the MR for the current branch,
     prints state, draft flag, pipeline status and URL.

/gitlab pipeline
   → Latest pipeline for the branch; if failed, lists failed jobs and runs the
     masked grep diagnosis on the first one. Summarizes the cause.

/gitlab vars
   → CI variable key names for the project. No values.

"open an MR for this branch"
   → Push (if needed) + `glab mr create …` shown with the description file.
     Runs only after "yes"; then re-reads the MR and reports URL + pipeline.
```
