# PLAN NNN — <Title>

**How.** Contract and status live in `spec.md`; the work lives in `task.md`. Do not restate status here.

## Rollout & gates
Order of envs (never skip up the ladder in `.claude/rules/change-safety.md`), which jobs are manual, and who approves each step.

| # | Step | Env | Gate — who approves | Manual job? |
|---|---|---|---|---|
| 1 | | | | |

Every step above the lowest shared env needs a gate. Production gates are never bypassed or disabled.

## Rollback
The prior state must be **recorded here before the change lands**, not described in the abstract. "Redeploy the old image" is not a rollback plan; an image digest is.

| Env | Thing | Recorded prior value | Restore command |
|---|---|---|---|

Record it with, e.g.:
```bash
kubectl --context <ctx> -n <ns> get deploy \
  -o jsonpath='{range .items[*]}{.metadata.name}={.spec.template.spec.containers[0].image}{"\n"}{end}'
```

If something breaks after the change: **roll back first, debug second.**

## Alternatives considered
One short paragraph each, and why it was rejected. This is what stops the same debate reopening in three weeks.

| Option | Why rejected |
|---|---|

## Open questions
Anything still undecided that the tasks depend on. A task must not depend on an open question — resolve it or cut the task.
