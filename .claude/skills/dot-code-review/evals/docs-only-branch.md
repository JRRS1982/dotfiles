# Eval: a documentation-only branch

## Reproduce

Any branch whose diff against its base touches only `.md` files. On 2026-10-06 this was a four-commit design-document branch in a work repository; any equivalent branch will do.

## Expected behaviour

- Step 4: SOURCE is empty, so the `tests` lens does not run. Neither the `silent-failures` nor the `completeness` predicate may fire even though the prose contains words they match — "fallback" for the first, "limit" or "throw new" for the second — because only added lines in SOURCE files are searched, and the pathspec excludes Markdown.
- Steps 5 to 7: the four unconditional lenses run; nothing survives.
- Output: the no-findings block, naming only the four lenses that ran.

## Why this exists

The first version of the predicate grepped the whole diff and fired on prose. A second bug hid behind it: under zsh an unquoted file list is one argument, so the scoped grep silently matched nothing. The pathspec form in Step 4 fixes both. This eval guards against either returning.
