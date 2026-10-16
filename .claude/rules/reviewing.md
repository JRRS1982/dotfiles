# Reviewing a diff

When reviewing a pull request or a branch diff, apply these on top of the repository's own conventions:

- Expect simple code, pure functions where possible, and early returns. Demand self-documenting code over comments.
- Ignore anything a linter or formatter covers.
- Guard against architectural drift: a new feature must follow the patterns already in the codebase and its documentation.
- Challenge every new external dependency against long-term maintainability and the minimal-dependency rule.
- Check security-sensitive code for broken authentication or authorization, and flag any hard-coded credential immediately.
