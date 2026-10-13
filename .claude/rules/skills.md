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
