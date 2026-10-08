# CLAUDE.md — <repo>

<!--
Template for a per-repo CLAUDE.md. Claude Code loads it automatically whenever work touches files in
this repo — for the main session and for subagents — so it's how repo knowledge reaches an agent
without costing context in every other session.

Rules for whoever fills it in:
- Under ~100 lines. It's read on every task in this repo; a long file costs context every time.
- Every fact verified against a file in the repo (or a command run in it). Cite the file when it isn't obvious.
- Commands must be ones that actually exist here (wrapper present, script defined, target in the Makefile).
- Never secret values. Config and secret KEY NAMES only; secret-bearing paths by name only, never opened.
- Don't repeat the project root CLAUDE.md or .claude/context/ — link them. This file is what's
  specific to THIS repo.
- Delete any section that would be empty, and delete this comment.
- Personal or committed, like every harness file — see .claude/rules/git-conventions.md.
-->

Owner: `<prefix>-<area>-agent` (or main). Project map: the root `CLAUDE.md`. Last verified: YYYY-MM-DD against `<branch>@<short-sha>`.

## What it is
2–4 lines: what this repo does in the system, what it consumes and what it produces.

## Commands
```bash
<build>
<all tests>
<single test class / single test case>
<lint / format>
<run locally, if supported>
```
Toolchain: <language + version, framework + version, build tool> — from <the manifest file>.

## Layout
Only the non-obvious: where the entry points, domain logic, persistence, messaging and config live. One line each.

## How it connects
- **Reads:** <topics / queues / endpoints / tables / buckets>
- **Writes:** <same>
- **Called by / calls:** <services>

## Configuration
- Profiles and config sources: <files, config server paths>.
- Secret **key names** it needs (never values): <names>.
- Secret-bearing paths in this repo (by name only, never open): <paths, or "none">.

## Migrations / data
<migration tool, location, naming; "none">

## Gotchas
- <traps specific to this repo that a newcomer would hit>

## Pointers
- <README sections, deep-dive docs inside the repo, relevant .claude/context/ files>
