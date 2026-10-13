---
paths:
  - "**/.claude/settings*.json"
  - "**/CLAUDE.md"
  - "**/CLAUDE.local.md"
  - "**/.claude/rules/*.md"
---

# Editing Claude configuration

- Treat every CLAUDE.md, rule, and settings.json as possibly public. No employer or client names, internal hostnames, cloud IDs, workspace paths, or account IDs. Those belong in `CLAUDE.local.md` or `settings.local.json`, which are never committed.
- Before committing a settings.json change, read the diff. Tools write into this file too, and what they write may not belong in the repo.
- A rule is context, not enforcement. If something must never happen, propose a PreToolUse hook rather than another sentence.
- Keep each instruction file under 200 lines. Move anything that only matters for one kind of file into a path-scoped rule.
