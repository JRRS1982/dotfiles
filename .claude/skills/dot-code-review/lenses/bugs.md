# Lens: bugs

Question: does this diff introduce a defect that misbehaves at runtime?

You may read the full modified files, not only the hunks, and grep for call sites of any changed export, signature, return shape, or default. Flag only breakage this diff causes. Pre-existing problems are out of scope.

Walk each hunk against this list:

- **Null and undefined**: a new path where a value can be absent and is dereferenced, destructured, or indexed.
- **Boundaries**: off-by-one in loops, slices, pagination, or date ranges; inclusive and exclusive mixed.
- **Async**: a missing await, a promise not returned, an ordering assumption, a race between concurrent writers, an unhandled rejection.
- **State**: mutation of a shared or input object, a stale closure, a cache not invalidated.
- **Contracts**: a caller of a changed signature, return shape, enum, or default that was not updated. Grep for them.
- **Data loss**: partial writes without a transaction, delete before a successful write, overwrite without a guard.
- **Resources**: handles, listeners, timers, or subscriptions opened and not closed on every path.
- **Security**: input reaching a query, shell, HTML, or redirect without the project's usual guard; an auth check removed or reordered.
- **Types lying**: a cast or non-null assertion that hides a real possibility.

For every finding quote the line(s) and state the input or sequence that triggers it.
