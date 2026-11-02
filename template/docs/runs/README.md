# docs/runs — the run ledger

One file per day, `YYYY-MM-DD.md`, appended automatically by two hooks. Never edited by hand; `/retro` reads it.

| Column | Meaning |
|---|---|
| Time | local `HH:MM:SS` |
| Event | `subagent` (a delegated agent finished — `SubagentStop`) or `mutation` (an outward write happened — `PostToolUse`) |
| Who / tool | the agent type, or the tool name (`Bash`, the tracker's comment tool, …) |
| Detail | subagent: short id + the delegation label (`description` from the Agent call). mutation: the abridged command (≤120 chars, `--body`/secret values redacted) or the ticket/page/channel |
| Metrics | subagent: `tokens=` (the final turn's input + cache read + cache creation + output — equals the host's reported subagent total and is what the ~100K threshold in the orchestrator file refers to), `new=` (non-cached tokens over all turns: input + cache creation + output — what was actually generated or newly read), `turns=` (assistant messages), `tools=` (tool_use blocks), `s=` (wall seconds, first→last transcript timestamp), `model=`. Computed from `agent_transcript_path` + its `.meta.json`; the hook payload itself carries no metrics. Summing cache reads over turns would count the context once per turn, so the ledger never does. mutation: the id or url from the response (PR/MR url, `Apply complete!…`, a comment id, a message timestamp) |

Hooks: `.claude/scripts/ledger-subagent.sh`, `.claude/scripts/ledger-mutation.sh`, wired in `.claude/settings.json` with `$CLAUDE_PROJECT_DIR` paths. Both are observers: every path exits `0` within 5 s, so they can never block a tool call or an agent stop. Unlike `CLAUDE.md` and the rules, hooks are picked up live — no restart needed.

Hooks are project-directory-wide: every session launched in this project fires them, so subagents of other sessions land in the same day file. A row whose transcript or `.meta.json` the hook could not read shows agent type `unknown` and `tokens=?`; `/retro` just groups them.

**What is a mutation:** `gh pr` / `glab mr` merge, create, close, reopen, ready, edit; `git push`; `terraform`/`tofu` apply, destroy, import, force-unlock, state rm/mv; `make apply`; `kubectl` apply, delete, patch, scale, rollout, edit, create, set; `helm` upgrade, install, uninstall, rollback; `argocd app sync/delete`; `aws <svc> create-|update-|delete-|put-|modify-|…`; `gcloud`/`az` create, update, delete, deploy; CI variable and secret writes; workflow/pipeline runs, reruns and cancels; `gh api`/`glab api` with `-X POST|PUT|PATCH|DELETE`. Reads never produce a row.

**Tracker, wiki and chat writes** are logged only if their tool names are in the `PostToolUse` matcher in `.claude/settings.json`: the kit ships `Bash` alone because those tool names depend on the integration. When a channel is enabled in `integrations.md`, extend the matcher with that channel's **write** tools (`Bash|<tool>|<tool>`), never its reads. The script then logs the target it finds in the input (`issueIdOrKey`, `pageId`, `title`, `channel_id`, …) and the id, key, timestamp or url it finds in the response.

`_payload-keys-*.json`: the field **names** of the first payload each hook received, captured once so the project knows which metrics the host actually provides. No values.

The ledger records that a post happened and its id; the outbox file still holds the draft text and the approval.
