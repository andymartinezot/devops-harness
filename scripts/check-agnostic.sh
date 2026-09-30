#!/usr/bin/env bash
#
# Fail if a kit directory carries organization-specific facts.
# Prints file:line only — never the matched text, which may itself be sensitive.
#
#   scripts/check-agnostic.sh            # check this repo
#   scripts/check-agnostic.sh <dir>...   # check other directories
#
# Built-in checks: absolute home paths, 12-digit account IDs, email addresses,
# ticket keys, long token-like strings. Your own org terms (company, product,
# internal hosts, team names) go one per line in .agnostic-denylist.local at the
# repo root — that file is gitignored and matched case-insensitively.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DENYLIST="$ROOT/.agnostic-denylist.local"
if [[ $# -gt 0 ]]; then targets=("$@"); else targets=("$ROOT"); fi

# Matches that are placeholders or standard names, not org facts.
ALLOW_TICKET='^(ABC|ADR|KEY|PROJ|SPEC|UTF|SHA|ISO|RFC|AES|TLS|HTTP|IPV|CVE)-[0-9]+$'
ALLOW_EMAIL='@(example\.(com|org|net)|users\.noreply\.github\.com)$'
# A token has letters AND digits; runs without one of them are dividers or kebab-case names.
ALLOW_TOKEN='^[^0-9]*$|^[^A-Za-z]*$'

total=0

# $1 label; $2 optional allow-regex applied to the match; rest: grep args.
check() {
  local label=$1 allow=$2; shift 2
  local hits
  hits=$(grep -rnoI --exclude-dir=.git --exclude=.agnostic-denylist.local "$@" "${targets[@]}" 2>/dev/null \
    | { if [[ -n "$allow" ]]; then awk -F: -v re="$allow" '{m=$0; sub(/^[^:]*:[^:]*:/, "", m); if (m !~ re) print}'; else cat; fi; } \
    | cut -d: -f1,2 | sort -u || true)
  if [[ -n "$hits" ]]; then
    local n; n=$(printf '%s\n' "$hits" | wc -l | tr -d ' ')
    total=$((total + n))
    echo "FAIL  $label ($n)"
    printf '%s\n' "$hits" | sed "s|^$ROOT/||; s|^|      |"
  else
    echo "ok    $label"
  fi
}

check "absolute home path"  ""               -E '(/Users/|/home/)[A-Za-z0-9._-]+'
check "12-digit account id" ""               -E '(^|[^0-9])[0-9]{12}([^0-9]|$)'
check "email address"       "$ALLOW_EMAIL"   -E '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
check "ticket key"          "$ALLOW_TICKET"  -E '\b[[:upper:]][[:upper:][:digit:]]{1,9}-[[:digit:]]+\b'
check "long token-like run" "$ALLOW_TOKEN"   -E '[A-Za-z0-9+/=_-]{40,}'

if [[ -s "$DENYLIST" ]]; then
  terms=$(mktemp); trap 'rm -f "$terms"' EXIT
  grep -vE '^[[:space:]]*(#|$)' "$DENYLIST" > "$terms" || true
  if [[ -s "$terms" ]]; then
    check "denylist term" "" -iF -f "$terms"
  fi
else
  echo "note  no .agnostic-denylist.local — org terms are not checked (see header)"
fi

if [[ $total -gt 0 ]]; then
  echo "$total hit(s). Fix them before committing or pushing."
  exit 1
fi
echo "clean"
