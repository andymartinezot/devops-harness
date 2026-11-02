#!/usr/bin/env bash
# PostToolUse hook: record outward mutations in docs/runs/<date>.md — repo-host writes, applies,
# cloud/cluster writes, tracker/wiki/chat posts. Reads are ignored. Observer only: always exit 0.
# Logged detail is the tool name, an abridged command or target (≤120 chars, --body/secret values
# redacted) and an id/url pulled from the response. Never the response body.
#
# Bash commands are matched against MUT below. Any other tool reaches this script only if the
# project's PostToolUse matcher in settings.json names it: add the WRITE tools of your tracker,
# wiki and chat integrations there (e.g. the MCP tools that add a comment, transition an issue,
# create or update a page, send a message). Reads must stay out of the matcher.
#
# Test:  echo '{}' | bash .claude/scripts/ledger-mutation.sh; echo $?     (must print 0, write nothing)
set +e
W="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
R="$W/docs/runs"; mkdir -p "$R" 2>/dev/null || exit 0
in=$(cat 2>/dev/null) || exit 0
[ -n "$in" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0
jq -e '.hook_event_name // empty | length > 0' <<<"$in" >/dev/null 2>&1 || exit 0

tool=$(jq -r '.tool_name // ""' <<<"$in" 2>/dev/null)
[ -n "$tool" ] || exit 0

# Response as text, whether the host passed a string or an object.
resp=$(jq -r '.tool_response | if type=="string" then . else tojson end' <<<"$in" 2>/dev/null)

detail=""; ref=""
case "$tool" in
  Bash)
    cmd=$(jq -r '.tool_input.command // ""' <<<"$in" 2>/dev/null | tr '\n\t' '  ')
    MUT='(^|[;&|[:space:](])(gh pr (merge|create|close|reopen|ready|edit)|glab mr (merge|create|close|reopen|update|approve)|git push|terraform (apply|destroy|import|force-unlock|state (rm|mv))|tofu (apply|destroy|import)|make (apply|deploy)|kubectl (apply|delete|patch|scale|rollout|edit|create|set)|helm (upgrade|install|uninstall|rollback)|argocd app (sync|delete)|aws [a-z0-9-]+ (create|update|delete|put|modify|start|stop|terminate|run|tag|untag|attach|detach|associate|disassociate|authorize|revoke|register|deregister)-[a-z-]+|gcloud [a-z-]+( [a-z-]+)* (create|update|delete|deploy|apply)|az [a-z-]+( [a-z-]+)* (create|update|delete|deploy|set)|gh (variable|secret) set|glab (variable|ci variable) (set|create|update)|gh workflow run|gh run (rerun|cancel)|glab ci (run|retry|cancel)|gh api [^|;]* (-X|--method) *(POST|PUT|PATCH|DELETE)|glab api [^|;]* (-X|--method) *(POST|PUT|PATCH|DELETE)|gh repo (create|delete|edit))'
    grep -qE "$MUT" <<<"$cmd" 2>/dev/null || exit 0
    # Redact values that could be secrets on a command line.
    # Quoted values go first so a "--body \"two words\"" is removed whole, not just its first word.
    detail=$(sed -E 's/(--body|-b|--body-file|-F|--description|-d|--message|-m)[= ]+("[^"]*"|'"'"'[^'"'"']*'"'"'|[^ ]+)/\1 …/g; s/((gh|glab) (secret|variable|ci variable) (set|create|update) [^ ]+).*/\1 …/' <<<"$cmd" | cut -c1-120)
    ref=$(grep -oE 'https://[^ "\\]+/(pull|merge_requests)/[0-9]+|Apply complete![^"\\]*|Destroy complete![^"\\]*|arn:aws:[^ "\\]{1,80}' <<<"$resp" 2>/dev/null | head -1)
    ;;
  *)
    # A tracker / wiki / chat write tool the project put in the matcher: log its target and the returned id.
    detail=$(jq -r '.tool_input | (.issueIdOrKey // .issueKey // .pageId // .page_id // .title // .channel_id // .channel // .projectKey // .project // .summary // "") | tostring' <<<"$in" 2>/dev/null | cut -c1-80)
    ref=$(jq -r 'try (.tool_response | if type=="string" then fromjson else . end | (.id // .key // .ts // .url // empty) | tostring) catch empty' <<<"$in" 2>/dev/null | head -1 | cut -c1-80)
    [ -n "$ref" ] || ref=$(grep -oE 'https://[^ "\\]{1,80}|pages/[0-9]+|\b[[:upper:]][[:upper:][:digit:]]{1,9}-[[:digit:]]+\b' <<<"$resp" 2>/dev/null | head -1)
    ;;
esac

f="$R/$(date +%F).md"
if [ ! -s "$f" ]; then
  printf '# Runs — %s\n\nAppended by the ledger hooks (`.claude/scripts/ledger-*.sh`). Read by `/retro`. Never edited by hand.\n\n| Time | Event | Who / tool | Detail | Metrics |\n|---|---|---|---|---|\n' "$(date +%F)" > "$f"
fi
k="$R/_payload-keys-posttooluse.json"
[ -s "$k" ] || jq -c '{event: .hook_event_name, keys: keys, response_type: (.tool_response|type)}' <<<"$in" > "$k" 2>/dev/null

# Pipes would break the table.
detail=${detail//|/¦}; ref=${ref//|/¦}
printf '| %s | mutation | %s | %s | %s |\n' "$(date +%H:%M:%S)" "$tool" "${detail:-—}" "${ref:-—}" >> "$f" 2>/dev/null
exit 0
