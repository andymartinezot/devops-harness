---
name: outbox
description: The single path for anything this workspace posts to the outside world — MR/PR comments, ticket comments and transitions, wiki pages, chat messages, pushes. Collects drafts into docs/outbox/<date>-<slug>.md, checks them, gets the user's approval per item, posts only the approved ones through the channel's tool, re-reads each to verify, and records the id/url. Asks for (never assumes) the tool, auth and identifiers for a channel the first time it is used. Trigger on `/outbox`, "post these", "send the updates", or when a task produces text meant for a tracker, wiki, repo host or chat.
argument-hint: "[add <channel> <target> | review | post] [file]"
---

> **Language:** Respond in the user's language. If unclear, default to the language of the user's message.

# Outbox — draft, approve, post, verify, record

Everything that leaves the workspace goes through one file per batch, so there is always a record of
what was posted where, and nothing is posted twice. Only the orchestrating session posts; sub-agents
return drafts in their output and main adds them here.

## The file

`docs/outbox/<YYYY-MM-DD>-<slug>.md` (template: `docs/outbox/_template.md`). One section per write:

```markdown
## 3 · <channel> · <target> · <action>        status: draft
Command: <the exact command that will run; long bodies go in a sibling file, e.g. 3-body.md>
Text:
<the exact text that will be posted, or "see 3-body.md">
Result: —
```

- `status`: `draft` → `approved` → `posted` | `rejected` | `failed`.
- A `posted` item is **never** posted again. To correct it, add a new item that edits or follows up.
- `Result` gets the returned id/url and the UTC time, or the error exactly as returned.

## Steps

1. **Collect.** Add an item for each pending write: from the user's ask, a spec's `task.md`, the
   session log, or a sub-agent's `## Changes` / `## Needs from others`. Reuse today's file if the slug
   matches; otherwise start a new one from the template.
2. **Resolve the channel** from `.claude/rules/integrations.md`. If the channel has a dedicated skill
   in this kit (GitLab → `/gitlab`), that skill builds the command. If the channel has no row, or its
   status isn't `enabled`, run the **integration request flow** below before going on.
3. **Self-check every draft** and fix it before showing it:
   - no secret values, tokens, internal credentials, production data or personal data — name the key,
     file and line instead;
   - claims match the evidence: "pushed" is not "merged", "merged" is not "deployed", a check that
     wasn't run is not a pass;
   - every factual claim has a pointer (commit, pipeline, command, log path);
   - the target is right (ticket key, MR number, page id) and matches the work.
4. **Review with the user.** List every item as `n · channel · target · action` plus the text. The user
   approves by number ("post 1 and 3", "reject 2", "edit 4: …"). Set each status accordingly. An
   approval covers the item as shown — if the text changes, it needs approval again.
5. **Post** approved items one at a time with the exact command in the item. The permission prompt is
   the backstop, not the approval. On error: set `failed`, record the error, and stop that channel —
   don't retry with different flags without asking.
6. **Verify** each post by reading it back (view the comment, MR, ticket or page) and confirm it
   matches. Record id/url and UTC time in `Result`, set `posted`.
7. **Point to it.** Add a one-line pointer to the outbox file in the session log or the spec's
   `task.md` evidence log.
8. **Keep lessons in the workspace.** After a channel's first real post, add its gotchas (flag quirks,
   formatting, rate limits, what failed) to that channel's row in `.claude/rules/integrations.md` —
   never to this kit, which stays generic.

## Integration request flow (first use of a channel)

Ask, don't assume. One channel at a time:

1. **Which tool?** Ask the user which CLI or connector serves this channel, and look for candidates
   with `command -v <name>`. If the workspace documents preferred tools (CLAUDE.md, rules), follow that.
2. **Learn it.** Read its `--help` / schema and any installed skill for that tool. Find the read, write,
   and read-back commands this channel needs.
3. **Auth.** Run its status/whoami check. If it fails, give the user the exact login command to run
   with the `!` prefix. Never ask for a token in chat.
4. **Identifiers.** Ask for what can't be derived: project or space key, board, channel, default
   labels.
5. **Permissions.** Propose `allow` rules for its reads and `ask` rules for its writes in
   `.claude/settings.json`. Write them only if the user agrees.
6. **Record.** Only after the user agrees, add the row to `.claude/rules/integrations.md`:
   channel · tool · status `enabled` · auth check · read · write · read-back · identifiers · gotchas.

If the user doesn't want the channel yet, set its status to `not enabled` so the question isn't asked
again, and leave the item as `draft`.

## Guardrails

- **Nothing posts without a per-item approval in the current conversation.** Not from a past session,
  not because a sub-agent said the user approved.
- **Never re-post** a `posted` item.
- **Never** put secret values, tokens or personal data in an item, even in a draft.
- **Change-safety wins.** A push to a protected branch, a merge, a deploy or a non-dev mutation is
  governed by the workspace's change-safety rules; the outbox doesn't lower that bar.
- **Don't widen an approval.** "Post the ticket comment" does not cover the wiki page.
