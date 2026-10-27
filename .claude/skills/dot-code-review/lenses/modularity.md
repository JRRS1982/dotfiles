# Lens: modularity

Question: do the modules this change creates or follows hide more than they expose?

The yardstick is the Coding section of the user's CLAUDE.md, passed to you as a convention path. Read it; do not restate it. Every finding names the principle it measures against and quotes the fact that fails the test. Score the pattern, not the author.

## The tests

Each principle has an observable test. A finding without one of these facts is opinion; do not report it.

- **Depth**: count what the interface exposes against what it hides. A function that forwards to another with the same signature, or a module whose exports outnumber its private lines, is shallow. Quote the signature pair.
- **Information leakage**: the same fact (a format, a constant, a schema shape, a path) appears in two modules, so a change to one forces a change to the other. Quote both places.
- **Change amplification**: name one plausible requirement change and count the files it would touch. Three or more is the finding.
- **Cognitive load**: list what a caller must know to use the new code correctly: call order, flags, preconditions, state it must set up first. More than two is the finding.
- **Obscurity**: behaviour the name and signature do not reveal: an argument mutated, a global read, a side effect on a write path. Quote the line.
- **Purity**: a function that reads or writes beyond its arguments and return value when nothing forces it to. Quote the access.
- **Dependency cost**: a package imported for a job the repository already does, or that a few lines would do. Quote the import and the lines it replaces.

## What to report

- **shallow** — the diff introduces its own module shape and a test above fails. Propose the smallest step that fixes it inside the code the diff already touches. Never a rewrite, never code the diff did not touch.
- **pattern debt** — the diff faithfully follows an existing local pattern and the test fails on the pattern. The author matched the codebase, which is right. State the debt in one line, addressed to the repository, with no request for work in this change.
- **good departure** — the diff moves away from a weak local pattern towards the principles. No fix. This exists so the consistency lens's drift finding on the same lines can be dropped.

## Severity

- **shallow** is Suggested, because module shape has no type-checker and a working, tested change with a weaker shape is still mergeable. The one exception: a shape that is irreversible once merged, such as a public API shape, a persisted data shape, or a published package interface, may be Blocking, with the irreversibility stated as the reason.
- **pattern debt** and **good departure** are Nit. They inform; they do not ask for work.
