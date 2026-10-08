# SPEC NNN — <Title>

**What and why.** The contract. `plan.md` holds how, `task.md` holds the work.

| Field | Value |
|---|---|
| Tickets | <ABC-123> (+ every related key) |
| Status | draft <!-- draft → approved → in-progress → verified → closed. THIS IS THE ONLY PLACE STATUS LIVES --> |
| Owner agents | (from the routing table in `CLAUDE.md`; main if none) |
| Envs in scope | (rungs of the ladder in `.claude/rules/change-safety.md`, and platform if more than one) |
| Created / updated | YYYY-MM-DD / YYYY-MM-DD |

## 1. Intent
3–5 lines: the problem and the end state. Say why, not how.

## 2. Current state (evidence)
What is true today, per env. Every row carries evidence — a command plus its abridged output, or a log path. Never a guess, and never a secret value. Gather this through the read-only inspector named in `CLAUDE.md`, not by assuming.

| Env | Platform | Fact | Evidence |
|---|---|---|---|

If a fact could not be verified, write it as `TODO: verify` and say what would settle it. Do not let an unverified fact drive a task.

## 3. Desired state matrix
Every cell needs a matching acceptance check in section 6.

| Env | <platform or component> | <platform or component> |
|---|---|---|
| | | |

## 4. Invariants (must NOT change)
- e.g. envs outside scope keep their current config
- e.g. production gates and manual approvals untouched
- Always state "out-of-scope envs unchanged" unless changing them is the point.

## 5. Blast radius
Services, accounts, clusters, DNS, other tenants and users affected if this goes wrong. Name shared infrastructure explicitly — it has tenants who are not us.

## 6. Acceptance checks
Runnable commands with expected output, per env. `/spec-verify` runs these through the inspector. A check that wasn't run is not a pass.

| # | Env | Check | Command | Expected |
|---|---|---|---|---|
| A1 | | | | |
