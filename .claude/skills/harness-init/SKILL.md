---
name: harness-init
description: Bootstrap (or extend) an agent harness in any DevOps workspace — a root CLAUDE.md that routes work, STATUS.md / DECISIONS.md, rules for change-safety, secrets, memory, git and integrations, a spec layout, an outbox, session logs, and a memory directory — by surveying the workspace read-only and ASKING for every fact it can't derive. Never overwrites an existing CLAUDE.md; merges into it. Starts small (main plus one read-only inspector). Trigger on `/harness-init`, "set up the harness here", "bootstrap agents for this project".
argument-hint: "[workspace path]   (default: current directory)"
disable-model-invocation: true
---

> **Language:** Respond in the user's language. If unclear, default to the language of the user's message.

# /harness-init — bootstrap a workspace by asking

**Kit root:** three levels above this skill's directory, symlinks resolved
(`cd "<this skill's base dir>/../../.." && pwd -P`). Templates are in `<kit>/template/`, scripts in
`<kit>/scripts/`.

**Rule of the whole skill:** the kit is generic; the workspace's facts come from the workspace (read
only) or from the user (asked). Never carry facts from one workspace into another unless the user
points you at it. Write nothing until step 4, and only what the user approved.

## 1. Survey — read-only, names not contents

Run in parallel and summarize in a short table:

- Is the root a git repo? Which directories are repos (`find . -maxdepth 3 -name .git`), which are
  containers of repos, which are unversioned?
- Per repo: remote host and group (`git -C <r> remote get-url origin`), default branch, stack from
  marker files (`package.json`, `pom.xml`, `build.gradle`, `go.mod`, `*.tf`, `Chart.yaml`,
  `template.yaml`, `Dockerfile`, `.gitlab-ci.yml`, `.github/workflows/`).
- Existing harness: `CLAUDE.md`, `AGENTS.md`, `.claude/` (settings, rules, agents, skills), `docs/`,
  `specs/`, `memory/`, and per-repo `CLAUDE.md` files.
- **Secret-bearing paths by filename only** — `*secret*`, `*credential*`, `.env*`, `*.pem`, `*.key`,
  `*kubeconfig*`, `secrets/`. **Never open, cat or grep them**; a single-line secret file prints its
  value on any line-oriented read. List paths, and later propose `deny` rules for them.
- Tools on PATH relevant to channels: `command -v git glab gh aws kubectl terraform helm jq yq` and any
  the user's environment documents.

## 2. Integrations — reuse, then request

1. Ask: **"Is there another workspace whose `.claude/rules/integrations.md` I can reuse?"** If yes, read
   it and copy its **tool rows and gotchas** (how a CLI behaves, auth checks, flag quirks). **Never copy
   its identifiers** (project keys, spaces, channels, accounts) — those belong to that workspace.
2. Ask which channels this workspace needs now (repo host, tracker, wiki, chat, cloud, monitoring).
   For each one the user wants now, run the **integration request flow** from `/outbox`. Mark the rest
   `not enabled`. Starting with one or two channels is normal.

## 3. Ask what can't be derived

One `AskUserQuestion` round (max 4 questions), then a second only if needed. Typical:

- Purpose of the workspace in one line, and who it is for.
- Environment ladder (e.g. `local → dev → … → prod`) and which envs are production or regulated.
- Ticket convention (key regex, branch and commit shape) — propose what the survey inferred.
- Docs home and the access map (accounts, clusters, profiles) — **may be deferred**; leave `TODO:`.
- **Harness files: personal or committed?**
  - *Committed* — `CLAUDE.md` and `.claude/` are versioned with the repos.
  - *Personal* — kept out of git with a path-scoped global ignore. Propose, and apply only if the user
    agrees (it changes their global git config; back up both files first):
    ```
    # ~/.gitconfig
    [includeIf "gitdir/i:<workspace-parent>/"]
        path = ~/.config/git/<name>.gitconfig
    # ~/.config/git/<name>.gitconfig
    [core]
        excludesFile = ~/.config/git/ignore-<name>
    # ~/.config/git/ignore-<name>   (replaces the default global ignore for those repos,
    #                                so repeat any lines from ~/.config/git/ignore here)
    CLAUDE.md
    .claude/
    ```
    Verify with `git -C <repo> check-ignore --no-index -v CLAUDE.md .claude/x` inside and outside the
    path.

## 4. Draft the files

Copy `<kit>/template/` into the workspace and fill the `{{PLACEHOLDERS}}` from steps 1-3. Unknowns
become `TODO: <what would settle it>`, never a guess.

- **Existing `CLAUDE.md`: merge, never overwrite.** Show the diff; additions only unless the user asks
  otherwise. Same for any existing rule, agent or skill with the same name.
- `.claude/settings.json`: start from the template (deny force-push, ask on push). Propose extra
  `deny` rules for the secret-bearing paths found in step 1 and for IaC apply / cluster create-delete /
  stack deploy commands of the tools present; `allow` for the channels' reads, `ask` for their writes.
  Write only the approved ones.
- `.claude/rules/secrets-handling.md`: list the secret-bearing paths from step 1 (paths only).
- `.claude/rules/git-conventions.md`: the ticket convention and the personal/committed choice.
- **Memory:** the harness keeps per-project memory under `~/.claude/projects/<encoded path>/memory`
  (list `~/.claude/projects/` to find the entry for this workspace — don't guess the encoding). To make
  memory visible and portable, offer: back it up, move its files to `<workspace>/memory/`, and replace
  the harness directory with a symlink to it. Only with the user's OK; verify a read and a write
  through the link afterwards.
- The template's `handoff` and `resume` skills are workspace copies — keep them unless the workspace
  already has its own.

## 5. Start small

- Routing starts with **main plus one read-only inspector agent** (from
  `template/.claude/agents/_example-agent.md`). Propose domain agents from the survey, but create one
  only when a routing need recurs.
- Per-repo `CLAUDE.md` files are written lazily — the first time a repo is actually worked on.
- Suggest the first real task to run through the harness (a read-only status check is ideal).

## 6. Check and report

- Kit skills installed user-wide? `ls -l ~/.claude/skills/ | grep '<kit>'` should show `gitlab`,
  `outbox`, `spec`, `spec-verify`, `harness-init`. If not: `<kit>/install.sh`.
- Run `<kit>/scripts/harness-lint.sh <workspace>`; fix FAILs, explain WARNs.
- Report: files written (paths), channels enabled / not enabled, deferred `TODO:`s, and the suggested
  first task. Recommend a fresh session so the new `CLAUDE.md` and rules load.

## Guardrails

- **Read-only until step 4**, and step 4 writes only approved content.
- **Never open secret-bearing files**, render credential screenshots, or print environment values.
- **Never overwrite** an existing `CLAUDE.md`, rule, agent or skill.
- **Never change global config** (git, shell, harness) without asking and backing up first.
- **No facts from other workspaces** except the integration tool rows the user pointed you at.
