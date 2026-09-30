#!/usr/bin/env bash
# install.sh — symlink this kit's skills into a Claude Code skills directory.
#
#   ./install.sh                                  user-wide: ~/.claude/skills/
#   ./install.sh --project <path>                 one workspace: <path>/.claude/skills/
#   ./install.sh --list [--project <path>]        show what is installed
#   ./install.sh --uninstall [--project <path>]   remove only links that point into this kit
#
# Idempotent. Never replaces a real directory, or a link that points elsewhere; it reports
# the conflict and exits 1 so you resolve it by hand.
set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SRC="$KIT/.claude/skills"
DEST="$HOME/.claude/skills"
MODE=install

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      [[ $# -ge 2 ]] || { echo "--project needs a path" >&2; exit 2; }
      DEST="$(cd "$2" && pwd -P)/.claude/skills"; shift 2 ;;
    --list) MODE=list; shift ;;
    --uninstall) MODE=uninstall; shift ;;
    -h|--help) sed -n '2,10p' "$0" | cut -c3-; exit 0 ;;
    *) echo "unknown argument: $1 (see --help)" >&2; exit 2 ;;
  esac
done

rc=0
for dir in "$SRC"/*/; do
  name="$(basename "$dir")"
  target="$SRC/$name"
  link="$DEST/$name"
  current=""
  [[ -L "$link" ]] && current="$(readlink "$link")"

  case "$MODE" in
    list)
      if [[ "$current" == "$target" ]]; then echo "installed  $name"
      elif [[ -e "$link" || -L "$link" ]]; then echo "conflict   $name  ($link is not this kit's)"
      else echo "missing    $name"; fi ;;
    install)
      if [[ "$current" == "$target" ]]; then echo "ok         $name"
      elif [[ -e "$link" || -L "$link" ]]; then
        echo "conflict   $name  ($link exists and is not this kit's; resolve by hand)" >&2; rc=1
      else
        mkdir -p "$DEST"; ln -s "$target" "$link"; echo "linked     $name"
      fi ;;
    uninstall)
      if [[ "$current" == "$target" ]]; then rm "$link"; echo "removed    $name"
      else echo "untouched  $name"; fi ;;
  esac
done

echo "($MODE → $DEST)"
exit $rc
