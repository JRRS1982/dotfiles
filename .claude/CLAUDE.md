# Global Instructions

These apply across all projects on any machine. Machine-specific context lives on each machine in `~/.claude/CLAUDE.local.md` so that i.e. Personal and Work settings can be separated.

That file is and should **not be part of this repo** and you will not find it here — it exists only on each machine (gitignored; created by `setup.sh`). It is pulled in via the import at the bottom of this file; if it is absent, the import is simply skipped.

## Precedence

Claude Code loads every applicable `CLAUDE.md` into context. It does not resolve conflicts between them. This order does:

1. `~/.claude/CLAUDE.local.md` — machine and account context. Highest.
2. The project `CLAUDE.md` nearest the working directory.
3. This file. It states the default; the files above state the exception.

## Scope of this file

- This repo is public. Never add client names, account names, internal URLs, or credentials here. Those belong in `~/.claude/CLAUDE.local.md`.
- Add a rule here only if it holds in every project and cannot be derived from the repository itself.
- Stack, commands, and per-repo conventions belong in the project `CLAUDE.md`.

## Repo layout

- `~/.claude/CLAUDE.md`, `settings.json`, `skills/`, and `output-styles/` are symlinks into this dotfiles repo. An edit to `~/.claude/X` edits the repo working tree, so treat those edits as repo changes.

## Commits

- Prefix commit messages with the branch name, e.g. `GOLD-123: add avatar upload` (the `/dotfiles-gc` skill and the `gc` shell helper both do this automatically).

## Skills

- Skills that ship from this dotfiles repo are prefixed `dotfiles-` (e.g. `dotfiles-gc`) to signal their provenance and distinguish them from plugin-provided skills.

## Output styles

- `outputStyle` in `settings.json` selects the active style. Style files live in `~/.claude/output-styles/`.
- To change the prose register, edit the style file, not this file.

## Coding

- Follow the existing style of the repository. This overrides every preference below.
- Design deep modules: a simple interface that hides substantial implementation. Prefer a few strong abstractions over many shallow wrappers.
- Reuse before you add. Look for an existing helper, component, or utility first.
- Prefer pure functions and immutable data structures.
- Minimize dependencies.
- Code defensively, but avoid premature optimization.

<!-- The file below is machine-local and NOT in this repo; the import is skipped if it is absent. -->
@~/.claude/CLAUDE.local.md
