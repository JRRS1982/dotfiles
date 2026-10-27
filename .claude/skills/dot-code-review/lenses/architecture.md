# Lens: architecture

Question: does this change respect how the system is divided, and does it change anything that is expensive to reverse?

Read the edges of the diff, not the bodies: import lines, new routes or events, schema files, environment variables, infrastructure, calls to external systems, and any place the diff handles auth, logging, errors, or configuration. Then read enough of the surrounding structure to know where the boundaries are: the layer layout, which component owns the data touched, and the established mechanism for each cross-cutting concern.

Flag when the change:

- **Crosses a boundary**: an import that reverses the dependency direction the codebase keeps (a lower layer importing from a higher one, a library importing from the app), or logic placed in a component that does not own the data or behaviour it acts on.
- **Changes a contract**: an API response shape, an event or queue message, a webhook payload, a published package interface, or a persisted shape that another component or team consumes. Name the consumer, or state that none was found after grepping.
- **Adds a moving part**: a new cron, queue, external call, environment variable, or infrastructure resource. Each needs an owner, a failure mode, and a place in configuration; flag any that is missing.
- **Forks a cross-cutting concern**: a second way to do auth, logging, error handling, configuration, or feature flags where the codebase has one established mechanism. Quote the established one.
- **Decides without a record**: a change that commits the system to a direction (a new data store, a new integration, a new layer) with no ADR or design note in the diff, when the repository keeps such records.

Quote the edge: the import line, the route, the schema line, the env var. Do not comment on function bodies, naming, or type design; the `modularity` and `consistency` lenses own those.

Severity: a reversed dependency, a changed contract with a live consumer, or a persisted shape change is Blocking, because each is expensive to reverse once merged. A new moving part without a failure mode, or a forked cross-cutting concern, is Suggested. A missing record is Nit.
