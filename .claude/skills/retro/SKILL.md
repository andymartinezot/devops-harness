---
name: retro
description: Read-only retrospective of the harness itself — subagent runs and tokens from the run ledger (docs/runs/), outward mutations, spec Status counts, memory churn and session logs for the last N days (default 7). Prints one table and at most three one-line observations; proposes nothing and changes nothing. Use on `/retro`, "how did the harness do this week", or before porting harness changes to the kit.
argument-hint: "[days]"
disable-model-invocation: true
---

# /retro $ARGUMENTS

Read-only. Run the one block below exactly as written from the workspace root (it only reads `docs/runs/`, `specs/`, `memory/` and `docs/sessions/`), then report. Don't open the files it summarises, and don't fix anything from here.

```bash
bash <<'RETRO'
DAYS="$ARGUMENTS"; DAYS="${DAYS:-7}"
cd "${CLAUDE_PROJECT_DIR:-$PWD}" || exit 1
SINCE=$(date -v-"${DAYS}"d +%F 2>/dev/null || date -d "-${DAYS} days" +%F)
echo "== window: $SINCE .. $(date +%F) ($DAYS days)"

files=$(ls docs/runs/20[0-9][0-9]-[0-9][0-9]-[0-9][0-9].md 2>/dev/null | awk -v s="$SINCE" '{ d=$0; sub(/.*\//,"",d); sub(/\.md$/,"",d); if (d>=s) print }')
echo "== ledger files in window: $(printf '%s\n' $files | grep -c .)"
if [ -n "$files" ]; then
  # Rows: | HH:MM:SS | subagent | type | id label | tokens=N new=N turns=N tools=N s=N model=M |   and   | HH:MM:SS | mutation | tool | detail | ref |
  awk -F'|' '
    function trim(s){ gsub(/^[ \t]+|[ \t]+$/,"",s); return s }
    { ev=trim($3); who=trim($4); met=trim($6) }
    ev=="subagent" { n++; t=-1; if (match(met,/tokens=[0-9]+/)) t=substr(met,RSTART + 7, RLENGTH - 7)+0
                     if (t<0) unk++; else { tot+=t; by[who]+=t }; cnt[who]++
                     if (match(met,/tools=[0-9]+/)) { u=substr(met,RSTART + 6, RLENGTH - 6)+0; if (u>40) big_tools++ }
                     if (t>100000) big_tok++ }
    ev=="mutation" { m++; mt[who]++ }
    END {
      printf "== subagent runs: %d  total tokens: %d  rows without a token count: %d  runs >100K tokens: %d  runs >40 tools: %d\n", n, tot, unk, big_tok, big_tools
      for (w in cnt) printf "   by type: %-22s runs=%d tokens=%d\n", w, cnt[w], by[w]
      printf "== mutations: %d\n", m
      for (w in mt) printf "   by tool: %-40s %d\n", w, mt[w]
    }' $files
  echo "== top 5 subagent runs by tokens (tokens, date, time, type, id label):"
  awk -F'|' '
    function trim(s){ gsub(/^[ \t]+|[ \t]+$/,"",s); return s }
    trim($3)=="subagent" { met=trim($6); t=0; if (match(met,/tokens=[0-9]+/)) t=substr(met,RSTART + 7, RLENGTH - 7)+0
                           d=FILENAME; sub(/.*\//,"",d); sub(/\.md$/,"",d)
                           printf "%9d  %s %s  %-22s %s\n", t, d, trim($2), trim($4), trim($5) }' $files | sort -rn | head -5
fi

echo "== spec Status counts (all specs):"
grep -h '^| Status |' specs/[0-9]*/spec.md 2>/dev/null | awk -F'|' '{ s=$3; sub(/^[ \t]+/,"",s); split(s,a,/[ (<]/); c[a[1]]++ } END { for (k in c) printf "   %-12s %d\n", k, c[k] }'
echo "== specs in-progress (dir — created / updated):"
for s in specs/[0-9]*/spec.md; do
  [ -f "$s" ] || continue
  grep -q '^| Status | in-progress' "$s" && printf '   %s — %s\n' "$(dirname "$s")" "$(grep -m1 '^| Created / updated |' "$s" | awk -F'|' '{print $3}' | tr -s ' ')"
done

echo "== memory: $(ls memory/*.md 2>/dev/null | grep -vc MEMORY.md) files total; changed since $SINCE:"
find memory -name '*.md' ! -name MEMORY.md -newermt "$SINCE" -exec basename {} \; 2>/dev/null | sort | sed 's/^/   /'

echo "== session logs in window:"
ls docs/sessions/*.md 2>/dev/null | awk -v s="$SINCE" '{ d=$0; sub(/.*\//,"",d); if (substr(d,1,10)>=s) print "   " $0 }'
RETRO
```

## Report

1. **One table**, rows: `subagent runs`, `total tokens`, `runs >100K tokens or >40 tools`, `mutations (by tool)`, `specs closed / total` (plus the other Status counts), `memory files changed / total`, `session logs`. Columns: metric, value, note (e.g. the top run's label). Keep the top-5 list under the table only when a run exceeds a threshold.
2. **At most 3 one-line observations**, only when the data shows them: a run over 100K tokens or 40 tool uses (`.claude/orchestrator.md` §Thresholds), a spec `in-progress` with an updated date older than 2 weeks, memory files that have never changed since they were written while related facts moved, ledger rows with `tokens=?` (the hook could not read the transcript, usually another session's subagent).
3. Propose nothing else. If something deserves a fix, the user decides and routes it (the harness agent for the harness, the spec's owner for a spec).
