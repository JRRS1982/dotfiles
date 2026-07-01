# Personal Global Instructions

These apply across all projects on any machine. Machine- and work-specific
context (e.g. the Team Gold project registry) lives in `~/.claude/CLAUDE.local.md`.
That file is **not part of this repo** and you will not find it here — it exists only
on each machine (gitignored; created by `setup.sh`). It is pulled in via the import at
the bottom of this file; if it is absent, the import is simply skipped.

## Commits

- Prefix commit messages with the branch name, e.g. `GOLD-123: add avatar upload`
  (the `/dotfiles-gc` skill and the `gc` shell helper both do this automatically).

## Skills

- Skills that ship from this dotfiles repo are prefixed `dotfiles-` (e.g. `dotfiles-gc`)
  to signal their provenance and distinguish them from plugin-provided skills.

<!-- The file below is machine-local and NOT in this repo; the import is skipped if it is absent. -->
@~/.claude/CLAUDE.local.md
