# Secrets handling

Secret values must never appear in tool output, files, commits, tracker or wiki pages, chat drafts, outbox items, or session logs.

**Secrets leak incidentally, not deliberately.** The usual failure is not choosing to print a value — it is a routine structural command whose output happens to carry it, often run with this rule loaded: a `grep -n` run only to get a line number, a `sed` "redaction" that silently didn't match. On a single-line secret file, `grep -n`, `cat`, `sed -n`, `head`, `git show`, `git diff`, and `-o yaml` on a Kubernetes Secret all print the value. Treat any path containing `secrets/`, or named `*secret*`, `*credential*`, `*kubeconfig*`, `*.dockerconfigjson`, `.env*`, `.envrc`, `*.pem`, `*.key`, `*.jks`, `*.p12`, or `*.bkp` beside those, as payload-bearing until proven otherwise. Screenshots count: opening one renders it into the transcript.

**Filenames are not enough.** Ordinary config and source files (values files, application config, per-env config modules) carry committed plain-text secrets too. Survey them by counting secret-shaped **keys**, never by printing lines.

**List key names, never values:**
- JSON secret: `… | jq -r 'keys[]'`
- YAML secret: `yq -r '.data | keys | .[]' <file>`; any YAML config: `yq 'paths'` or `yq 'keys'`
- Env vars in a container: `env | cut -d= -f1`
- Kubernetes Secret: `kubectl get secret … -o json | jq -r '.data | keys[]'` — never `-o yaml` or `describe` with data.
- Parameter / secret stores: list names only (e.g. a "get parameters by path" call queried for `Name`), never with decryption.
- CI variables: key names only.
- Need a line number? `grep -n <key> <file> | cut -d: -f1` — the number, not the line.
- Need to know whether a file holds data? Count, don't print: `grep -ciE '^[[:space:]]*insert' <file>`, `wc -l`.
- To prove a value is set or matches, compare lengths or hashes (`wc -c`, `shasum`), e.g. `yq -r '.data.<key>' <file> | tr -d '\n' | shasum` — never the value.

**Never print-then-redact.** A redaction regex that misses (quoting, an unexpected separator) passes the secret straight through. macOS/BSD `sed` doesn't understand `\s` — it matches a literal `s` — so `sed 's/password:\s.*/…/'` prints the line untouched. Extract keys structurally with `yq`/`jq` instead; if you must match whitespace, use `[[:space:]]`.

**Logs carry values too.** Some services log credentials or partner identifiers at normal levels, and some test reports dump every variable. Don't paste those logs: summarise, filter with `grep -v`, count matches, and quote line numbers rather than lines. List the known offenders in the table below.

**If a value leaks anyway:**
- Tell the user right away, name every file that now holds it (including agent transcripts), so they can decide on rotation.
- Don't copy the value anywhere else, including summaries.

**Where secrets never go:** values files and charts (the rendered manifest lands in cluster audit logs and GitOps diff output), CI config, committed `.env` files, specs, evidence logs. Record key names and counts instead.

**Identifiers that are not secret but stay out of tickets** (e.g. a cross-account `ExternalId`, a confused-deputy guard): write them abbreviated — first 4 and last 5 characters, `AbCd...vWxYz` — in tracker, wiki and session logs. Whoever needs the full value can read it at its source.

## Paths in this project that hold sensitive data

Sensitive data is not only secrets: personal data and unreleased business data carry the same handling rules, even though no rotation fixes them. The data is already there, so the rule is about not **spreading** it: quote a **path and line number**, never the content.

| Path | What (no values) | Safe inspection |
|---|---|---|
| {{path — found by filename or by secret-shaped key count}} | {{kind of data}} | {{keys / hash / count command}} |

Each payload row should also have a `Read(...)` deny in `.claude/settings.json` — a seatbelt, not a substitute for this rule.

## Secret providers

| Where | Provider | Location |
|---|---|---|
| {{env}} | {{provider}} | {{path / mount}} |
