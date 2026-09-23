# dot-deslop
Claude Code AI-Slop Removal Skill

## Installation

Provided via the dotfiles `.claude/skills/` symlink. After syncing the dotfiles,
the symlink makes this skill available as `/dot-deslop`.

## What it does

Reads the current branch's diff against its base and removes the residue an AI
leaves behind — then verifies behaviour is unchanged.

In skill mode it points the same instinct at a `SKILL.md`, linting the prose
for the equivalent failings. Run that before committing a new or edited skill.

## Why it exists

`/simplify` and the `code-simplifier` plugin already cover reuse, efficiency and
altitude. They do not look for the two things that most often make an AI diff
embarrassing in review:

- **Scope creep** — features, refactors or "improvements" outside the task
- **Drive-by edits** — docstrings, annotations or renames on code the task never touched

Those two are the reason this skill exists. The rest (obvious comments, needless
`try`/`catch`, `as any`, one-caller abstractions, back-compat residue) is the
supporting cast.

## When to call it

- After Claude has written a chunk of code, before `/dot-code-review`
- When a diff feels bigger or more ceremonious than the task warranted
- Before committing a skill, pointed at its `SKILL.md`

## Usage examples
```
/dot-deslop                         Diff against the auto-resolved base (master/main/develop)
/dot-deslop develop                 Diff against an explicit base branch
/dot-deslop .claude/skills/dot-council/SKILL.md    Skill mode — lint the prose
```

## Notes

- Claude will never auto-trigger this — it only runs when you type `/dot-deslop`.
  It edits code, and an unprompted skill that deletes things you did not ask it
  to touch is exactly the wrong kind of surprise.
- Behaviour stays identical unless it is fixing a clear bug, and it says so
  explicitly when it does.
- It verifies with whatever the repo actually uses — it reads `package.json`
  rather than assuming, and says so plainly if there is no test script.
- If nothing qualifies it says so and stops. It does not manufacture findings
  to look busy.
