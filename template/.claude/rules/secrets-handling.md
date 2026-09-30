# Secrets handling

Secret values must never appear in tool output, files, commits, tracker or wiki pages, chat drafts, outbox items, or session logs.

**Secrets leak incidentally, not deliberately.** The usual failure is not choosing to print a value — it is a routine structural command whose output happens to carry it. On a single-line secret file, `grep -n`, `cat`, `sed -n`, `head`, `git show`, `git diff`, and `-o yaml` on a Kubernetes Secret all print the value. Treat any path containing `secrets/`, or named `*secret*`, `*credential*`, `.env*`, `*.pem`, `*.key`, as payload-bearing until proven otherwise. Screenshots count: opening one renders it into the transcript.

**List key names, never values:**
- JSON secret: `… | jq -r 'keys[]'`
- YAML secret: `yq -r '.data | keys | .[]' <file>`
- Env vars in a container: `env | cut -d= -f1`
- Kubernetes Secret: `kubectl get secret … -o json | jq -r '.data | keys[]'` — never `-o yaml` or `describe` with data.
- CI variables: key names only.
- Need a line number? `grep -n <key> <file> | cut -d: -f1` — the number, not the line.
- To prove a value is set or matches, compare lengths or hashes (`wc -c`, `shasum`) — never the value.

**If a value leaks anyway:**
- Tell the user right away, name every file that now holds it (including agent transcripts), so they can decide on rotation.
- Don't copy the value anywhere else, including summaries.

**Where secrets never go:** values files, charts, CI config, committed `.env` files, specs, evidence logs. Record key names and counts instead.

## Paths in this workspace that hold sensitive data

Sensitive data is not only secrets: personal data and unreleased business data carry the same handling rules, even though no rotation fixes them. Quote a **path and line number**, never the content.

| Path | What (no values) | Safe inspection |
|---|---|---|
| {{path}} | {{kind of data}} | {{keys / hash command}} |

## Secret providers

| Where | Provider | Location |
|---|---|---|
| {{env}} | {{provider}} | {{path / mount}} |
