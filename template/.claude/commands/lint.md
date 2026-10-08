---
description: Health-check this project's harness (memory, agents and routing, orchestrator rule, skills, commands, leftover placeholders, specs, STATUS age, ignore consistency, repo CLAUDE.md coverage, leak scan). Add --live to also run each enabled integration's auth check.
argument-hint: "[--live]"
---

Run, from the project root:

```bash
bash {{KIT_DIR}}/scripts/harness-lint.sh . $ARGUMENTS
```

Then report in this shape, and nothing else:

1. The final `N fail, M warn` line.
2. Each FAIL, one line each, with the concrete fix (the file to edit and what to change). Fix only if the user asks.
3. Each WARN, one line each, saying whether it's expected or needs action.

**Leak-scan hits:** report them as `file:line` exactly as the script prints them. **Never open, cat or grep those lines** to show them: they may be a credential. Tell the user and let them decide.

If the script path doesn't exist, the kit moved: say so and ask for its new location. Don't search the disk for it.
