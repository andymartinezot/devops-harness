#!/usr/bin/env bash
# SubagentStop hook: append one row per finished subagent to docs/runs/<date>.md.
# Observer only — every path exits 0, nothing is printed back to the agent. The hook payload carries
# no metrics, so they are computed from the agent's own transcript (agent_transcript_path, a JSONL)
# and its sibling .meta.json: label (the delegation description), model, tokens (the final turn's
# context + output, which is what the host reports for the subagent), new tokens (non-cached, over
# all turns), turns, tool_use count and wall seconds.
# Only numbers and the label are stored — never message content.
#
# Test:  echo '{}' | bash .claude/scripts/ledger-subagent.sh; echo $?     (must print 0, write nothing)
set +e
W="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
R="$W/docs/runs"; mkdir -p "$R" 2>/dev/null || exit 0
in=$(cat 2>/dev/null) || exit 0
[ -n "$in" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0
# Only real hook payloads: valid JSON with an event name.
jq -e '.hook_event_name // empty | length > 0' <<<"$in" >/dev/null 2>&1 || exit 0

f="$R/$(date +%F).md"
if [ ! -s "$f" ]; then
  printf '# Runs — %s\n\nAppended by the ledger hooks (`.claude/scripts/ledger-*.sh`). Read by `/retro`. Never edited by hand.\n\n| Time | Event | Who / tool | Detail | Metrics |\n|---|---|---|---|---|\n' "$(date +%F)" > "$f"
fi

# Field names only, captured once per event type, so the project knows what the host provides.
k="$R/_payload-keys-subagentstop.json"
[ -s "$k" ] || jq -c '{event: .hook_event_name, keys: keys}' <<<"$in" > "$k" 2>/dev/null

agent=$(jq -r '.agent_type // "unknown"' <<<"$in" 2>/dev/null)
id=$(jq -r '.agent_id // ""' <<<"$in" 2>/dev/null | cut -c1-8)
tp=$(jq -r '.agent_transcript_path // ""' <<<"$in" 2>/dev/null)

label=""; model=""; tokens="?"; new="?"; turns="?"; tools="?"; secs="?"
if [ -n "$tp" ] && [ -r "$tp" ]; then
  meta="${tp%.jsonl}.meta.json"
  if [ -r "$meta" ]; then
    label=$(jq -r '.description // ""' "$meta" 2>/dev/null | tr -d '|\n' | cut -c1-60)
    model=$(jq -r '.model // ""' "$meta" 2>/dev/null)
  fi
  # Streaming writes the same assistant message several times: dedupe on message.id.
  # tokens = the LAST turn's input + cache read + cache creation + output. That equals what the host
  # reports for the subagent and what the ~100K threshold in the orchestrator file refers to. Summing
  # cache reads over turns would count the whole context once per turn (10 turns → ~8x too high).
  # new = non-cached tokens over all turns (input + cache creation + output); turns = assistant messages.
  tokens=$(jq -s '[.[] | select(.type=="assistant" and .message.usage)] | unique_by(.message.id) | last.message.usage
                  | (.input_tokens//0)+(.cache_read_input_tokens//0)+(.cache_creation_input_tokens//0)+(.output_tokens//0)' "$tp" 2>/dev/null)
  new=$(jq -s '[.[] | select(.type=="assistant" and .message.usage)] | unique_by(.message.id)
                  | map(.message.usage | (.input_tokens//0)+(.cache_creation_input_tokens//0)+(.output_tokens//0)) | add // 0' "$tp" 2>/dev/null)
  turns=$(jq -s '[.[] | select(.type=="assistant" and .message.usage)] | unique_by(.message.id) | length' "$tp" 2>/dev/null)
  tools=$(jq -s '[.[] | select(.type=="assistant")] | unique_by(.message.id) | [.[] | .message.content[]? | select(.type=="tool_use")] | length' "$tp" 2>/dev/null)
  secs=$(jq -rs '[.[] | .timestamp? // empty] | if length>1 then (((last|sub("\\.[0-9]+Z$";"Z")|fromdateiso8601) - (first|sub("\\.[0-9]+Z$";"Z")|fromdateiso8601))) else "?" end' "$tp" 2>/dev/null)
  [ -z "$model" ] && model=$(jq -r 'select(.type=="assistant") | .message.model // empty' "$tp" 2>/dev/null | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')
  model=$(sed -E 's/^claude-//; s/-[0-9]{8}$//' <<<"$model")
fi

printf '| %s | subagent | %s | %s %s | tokens=%s new=%s turns=%s tools=%s s=%s model=%s |\n' \
  "$(date +%H:%M:%S)" "${agent:-unknown}" "${id:-}" "${label:-}" "${tokens:-?}" "${new:-?}" "${turns:-?}" "${tools:-?}" "${secs:-?}" "${model:-?}" >> "$f" 2>/dev/null
exit 0
