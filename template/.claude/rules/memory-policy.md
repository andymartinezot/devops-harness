# Memory policy (agents)

Memory is durable, cross-session knowledge that would otherwise be re-learned from scratch: a trap that already burned us and will recur, an external process or contact that took real effort to find, how the user wants work done, a stable identifier that is in no repo.

- **Main writes memory; agents propose.** End your output contract with `## Memory candidates` — one line each, or `none`. Main verifies the claim and triages it at `/handoff`.
- **Not memory** (it has a home already): live state → `STATUS.md` / a spec's `task.md`; how a repo works → that repo's `CLAUDE.md` (update it yourself when your change alters a command, key or gotcha); tool access and gotchas → `.claude/rules/integrations.md`; ticket state → the tracker.
- **Never in memory, never in a candidate:** secret values or tokens (key names and counts only, per `secrets-handling.md`), production or personal data, anything true only for this conversation.
- Recalled memories in your context record what was true when written: confirm a file, flag or command still exists before relying on it.

Full policy, format and maintenance rules: `.claude/orchestrator.md` §Memory policy — main (main only).
