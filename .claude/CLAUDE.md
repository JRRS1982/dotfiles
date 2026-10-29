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

- Start the commit title with the Jira key in square brackets when the branch name has one, e.g. `[GOLD-123] Add avatar upload`. With no key, the title stands alone. The `/dot-gc` skill and the `gc` shell helper both do this automatically.

## Skills

- Skills that ship from this dotfiles repo are prefixed `dot-` (e.g. `dot-gc`) to signal their provenance and distinguish them from plugin-provided skills.

## Output styles

- `outputStyle` in `settings.json` selects the active style. Style files live in `~/.claude/output-styles/`.
- To change the prose register, edit the style file, not this file.

## Subagents

- Delegate only when all three hold: the files are known, the acceptance check is stated, and the task does not depend on work still in flight. Otherwise do it in the main session, where the context is. When in doubt, do not delegate.
- Pick the agent by what the task needs. If it needs conversation context, use the `fork` type, which inherits everything and needs no brief. If it can be stated fully in a brief (exports, conversions, renames, boilerplate, test scaffolding, formatting), use a fresh agent with `model: "haiku"`, or `"sonnet"` when it needs judgement. Never send a context-free brief to the main model; that pays full price and still risks drift.
- When a skill with its own dispatch rules is active (e.g. subagent-driven development), its rules replace these.

## Coding

- Follow the existing style of the repository. This overrides every preference below.
- Design deep modules: a simple interface that hides substantial implementation. Prefer a few strong abstractions over many shallow wrappers.
- Reuse before you add. Look for an existing helper, component, or utility first.
- Prefer pure functions and immutable data structures.
- Minimize dependencies.
- Code defensively, but avoid premature optimization.
- Every changed line traces to the request. Remove what your change left unused; mention pre-existing dead code, do not delete it.
- Never weaken a check to make a change pass: no new suppression, skipped test, loosened assertion or lowered threshold without saying why in the code.

## Testing

Before writing any test, state the failure scenario: "if this is wrong, a user can X." That determines the layer. If the failure scenario can't be stated in one sentence, ask before writing.

- **Unit** — pure functions with user-visible outputs. Input → output, no I/O. Write exhaustively for complex logic.
- **Integration** — code that crosses a real boundary (DB, external service). Real dependency, mocked auth. Highest-value layer for server-action apps.
- **E2E** — critical user journeys and async server components. Keep thin.

Three questions before writing any test:
1. What user-visible harm results if this is wrong?
2. At what layer is this most cheaply caught?
3. Would this test survive a refactor of the internals? If not, it tests an implementation detail — don't write it.

See `~/.claude/rules/testing.md` for naming and mocking conventions (loads when working on test files).

<!-- The file below is machine-local and NOT in this repo; the import is skipped if it is absent. -->
@~/.claude/CLAUDE.local.md
