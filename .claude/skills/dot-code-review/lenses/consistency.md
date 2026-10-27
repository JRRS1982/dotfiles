# Lens: consistency

Question: does this change do things the way this codebase already does them?

For each new file, function, module, or dependency, find its two or three nearest siblings: the existing code that does the same kind of job. Read them. Compare the approach, not the style. Flag when the change:

- duplicates a helper, utility, or component that already exists (grep for it)
- adds an abstraction with one caller
- adds a dependency for a job the repository already does another way
- builds a feature unlike its siblings with no reason stated in the diff or its description

Quote the sibling and the departure side by side. A departure that is stated and deliberate is not drift; say that it is stated.

Layering and ownership belong to the `architecture` lens; this lens compares the change with its nearest siblings only.

Severity: duplication of an existing helper is Blocking. The rest Suggested.
