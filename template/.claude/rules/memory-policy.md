# Memory policy

## Where memory lives

The real files are **`memory/` in the workspace root**, so the user can see, edit and review them, and they travel with the project.

The harness reads them through a symlink:

```
{{HARNESS_MEMORY_DIR}}  →  <workspace>/memory
```

- **Don't "fix" that symlink.** It is deliberate. The harness path is keyed to the workspace's absolute path, so if the real files lived there, moving or renaming the workspace would orphan every memory silently.
- **If the workspace ever moves**, re-point that one symlink. The memories themselves are safe.
- `MEMORY.md` is the index, and it is **injected into every session automatically** — you already have it, so never read it again to "check".

Memory exists for one thing: knowledge that would otherwise be re-learned from scratch next session.

## The boundary — one source of truth per fact

| Kind of fact | Home | Not memory because |
|---|---|---|
| "Right now": critical path, blockers, open MRs/PRs, service × env | `STATUS.md` | it changes weekly |
| A decision and its status | `DECISIONS.md` → ADR / docs home | it has an owner and a date |
| How a repo's code works | that repo's `CLAUDE.md` | the repo already records it |
| How to reach an external tool, and its gotchas | `.claude/rules/integrations.md` | it is config, read by `/outbox` |
| What happened in one session | `docs/sessions/<date>-<role>-<slug>.md` | it is a narrative, not a fact |
| Ticket state | the tracker | the tracker wins, always |
| **Durable, cross-session, not in any repo** | **memory** | — |

What genuinely belongs in memory:
- An external process or who to contact, when finding out cost real time.
- A trap that already burned you and will burn you again.
- How the user wants work done, especially after a correction.
- Stable identifiers that aren't in any repo.

## Who writes

**Main only.** Named agents end their output contract with `## Memory candidates` and propose; main verifies the claim first — re-running the decisive check — and then writes. This keeps several agents from creating near-duplicate memories no one reviews.

## Never in memory

- Secret values, credentials, tokens — key names and counts only, per `secrets-handling.md`.
- Production data or personal data.
- Ticket state, code structure, or git history.
- Anything true only for the current conversation.

## Format

- One file, one fact. Filename stem **must** equal the frontmatter `name:`, which is also the `[[link]]` target. Breaking that invariant silently breaks links.
- Frontmatter: `name`, `description` (one line — it is what recall matches on), `metadata.type` of `user` | `feedback` | `project` | `reference`.
- `feedback` and `project` bodies end with `**Why:**` and `**How to apply:**`.
- Every memory gets one index line in `MEMORY.md`: `- [Title](<name>.md) — hook`.
- Link related memories with `[[name]]`. A link to a memory that doesn't exist yet is fine — it marks something worth writing.
- Convert relative dates to absolute.
- `scripts/harness-lint.sh` in the kit checks all of the above.

## Maintenance

A memory records what was true when it was written, so treat it as a lead, not as truth:

- Before acting on a memory that names a file, flag, path or command, **confirm it still exists.**
- When a memory is wrong, **correct or delete that file.** Never add a second memory beside it — you get two conflicting recollections and no way to tell which is current.
- When you correct a memory, note the date and what was wrong, so the next reader knows it was reviewed rather than never checked.
- Fix the places the wrong fact already spread to (docs, ADRs, STATUS.md) in the same pass.
