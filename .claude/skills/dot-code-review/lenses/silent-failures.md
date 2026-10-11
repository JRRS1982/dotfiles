# Lens: silent failures

Question: does this diff let an error disappear?

Locate every error path the diff adds or edits: try/catch, `.catch`, `except`, `rescue`, error callbacks, `??` and `||` defaults, fallback branches, optional chaining on a value that should exist, early returns on a missing value.

For each one, flag when:

- the handler swallows: nothing logged, nothing rethrown, nothing returned that tells the caller it failed
- the handler is broader than the error it exists for and would hide unrelated failures
- a fallback value or a mock stands in for a real failure without telling the user or the log
- the log lacks what a debugger needs six months on: which operation, which id, which input
- the user-facing message says something went wrong but not what, or what to do next
- the error is caught below the layer that could act on it
- cleanup of locks, handles, or transactions is skipped on the error path

Severity: a swallowed error on a write, auth, or payment path is Blocking. The rest are Suggested. Quote the handler or the default.
