---
name: lint
description: Health-check this project's harness (memory, agents and routing, the main-only orchestrator file, skills, hooks, leftover placeholders, spec Status values, STATUS age, ignore consistency, repo CLAUDE.md coverage, leak scan) by running the kit's harness-lint.sh against the workspace. Add --live to also run each enabled integration's auth check. Read-only; fixes nothing. Trigger on `/lint`, "lint the harness", "check the harness".
argument-hint: "[--live]"
disable-model-invocation: true
---

# /lint $ARGUMENTS

**Kit root:** three levels above this skill's directory, symlinks resolved
(`cd "<this skill's base dir>/../../.." && pwd -P`). The checker is `<kit>/scripts/harness-lint.sh`.

Run it read-only against the workspace root (the directory the session was launched from):

```bash
bash "<kit>/scripts/harness-lint.sh" "$PWD" $ARGUMENTS
```

It prints `PASS` / `WARN` / `FAIL` lines and never file contents beyond names and line numbers. Then report in this shape, and nothing else:

1. The final `N fail, M warn` line.
2. Each FAIL, one line each, with the concrete fix (the file to edit and what to change). Don't fix anything from here; propose, and let the user pick. Harness edits go to the project's harness agent.
3. Each WARN, one line each, saying whether it's expected (recorded in `STATUS.md` or a spec, with the pointer) or needs action.

- **Leak-scan hits:** report them as `file:line` exactly as the script prints them. **Never open, cat or grep those lines** to show them: they may be a credential. Tell the user and let them decide.
- `--live` runs each enabled integration's auth check from `.claude/rules/integrations.md`; it may ask the user to log in with `! <command>`.
- If the script path doesn't exist, the kit moved or the skill link is stale: say so and ask for its new location. Don't search the disk for it.
