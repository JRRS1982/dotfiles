---
paths:
  - "**/*.sh"
  - "**/.zsh*"
  - "**/bin/*"
  - "**/hooks/**"
---

# Shell scripts and helpers

- Write for both bash and zsh. Quote every variable; an unquoted list is one argument under zsh.
- Do not start a function name with an underscore. Claude Code drops `_`-prefixed functions from its shell snapshot, so they are missing in every agent shell.
- Prefer `print` over `echo` for anything that may start with a dash, and `command gh` or `command git` inside a wrapper to avoid recursion.
- A hook script exits 0 to allow and 2 to block, with the reason on stderr. Read its input from stdin as JSON; never guess the fields.
- After editing a helper, source it in a fresh shell and run it once on a real case before reporting it works.
