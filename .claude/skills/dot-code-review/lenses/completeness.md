# Lens: completeness

Question: does this diff guard some paths to a thing and leave others open?

A guard applied to one caller and not its siblings is worse than no guard: it reads as a guarantee the codebase does not keep, and the next reader trusts it. The defect is never in the diff — it is the file the diff did not touch — so you must look outside it.

Locate every guard the diff adds or edits: a ceiling or quota constant, a rate-limit check, a validation schema or bound, an ownership or permission check, an authentication check, a feature gate, a sanitiser.

For each one:

1. Name the sink it protects — the table or column written, the external call made, the value parsed, the resource spent.
2. Find **every** path that reaches that sink, not only the ones in the diff. Grep the whole repo: other `create`/`createMany`/`update`/`upsert` calls on the same model, other callers of the same helper, other schemas with the same field, bulk or sync paths beside the one-at-a-time path, cron or webhook entry points beside the interactive one.
3. Report each path that reaches the sink without the guard.

Flag when:

- a new limit, cap or quota covers the interactive path but not a bulk, import, copy, sync or scheduled one
- a new validation bounds a field in one schema while a sibling schema declares the same field unbounded
- a new ownership or auth check is added to some entry points for the same resource and not others
- the diff introduces a named constant that reads like a global invariant (`MAX_*`, `*_LIMIT`, `*_PER_USER`) while a writer exists that never consults it
- an existing guard is extended to a new case, and a case of the same kind was missed

Say explicitly, when you find one, that the guard now claims a guarantee the code does not keep.

Severity: an unguarded path to the same sink is Blocking when the guard is for auth, ownership, or data loss; Suggested when it is for cost or resource use. Quote both the new guard and the unguarded path you found, with its `path:line`.
