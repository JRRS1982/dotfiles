---
paths:
  - "**/SKILL.md"
  - "**/.claude/skills/**/*.md"
---

# Editing a skill

- The description says what the skill does and when to use it, in third person, with the words a user would type. It never summarises the steps; a summary becomes a shortcut that skips the body.
- Keep SKILL.md under 500 lines. Move checklists, schemas and references into files beside it, linked directly from SKILL.md, one level deep.
- Shared content lives in one file that the others read; never paste the same block into sibling skills.
- Commands in a skill run under the user's shell, which may be zsh: quote every variable and use git pathspecs or arrays instead of unquoted lists.
- No model names, dates, or prices in the body. They go stale.
- Before claiming an edit is done, run one evaluation from the skill's `evals/` folder, or write the first one from a real diff. An untested edit to a skill is an untested change to code.

## Before committing a skill

Check it for these failings, which a reviewer will notice and a linter will not:

| Failing | What it looks like |
|---|---|
| Stale line | Guidance describing an older version of the skill |
| Dead sentence | Delete it and nothing changes |
| Premature stop | The method ends before the work does: asks but never records, cleans but never verifies |
| Weak anchor | No single idea the skill turns on; the reader cannot name it in one word |
| Undeclared invocation | Neither clearly human-run (`disable-model-invocation: true`) nor written to auto-fire on a precise description |
| Vague write op | Changes state without saying whether it adds, updates or appends, so a second run duplicates |

A skill that is side-effectful or a deliberate ritual is human-run. If you cannot say in one sentence when it should fire by itself, it is human-run.
