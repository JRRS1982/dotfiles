# Lens: slop

Question: does every changed line trace to the task, and does the diff weaken any check to make itself pass?

Read the diff, the pull request description or commit messages for the task, and the convention paths. Two kinds of residue, both typical of AI-written changes, and both invisible to the other lenses.

## Weakened checks

The diff lowers a bar instead of meeting it. Flag each new instance; quote it.

- a suppression: `@ts-ignore`, `@ts-expect-error`, `biome-ignore`, `eslint-disable`, `istanbul ignore`, `noqa`, `nosemgrep`, `# type: ignore`
- a cast that silences the type-checker rather than proving the type: `as any`, `as unknown as T`, a non-null `!` on a value that can be absent
- a test made easier to pass: `.skip`, `.only`, `xit`, an assertion removed or loosened (`toEqual` → `toBeDefined`, an exact count → `> 0`), an expected value edited to match new output with no reason given
- a threshold, timeout, retry count, or coverage floor moved in the lenient direction
- a lint, type, or CI rule switched off in configuration

A suppression is fine when a comment beside it says why the check is wrong here, and the reason holds. Flag the ones with no reason, or a reason that only says the check failed.

## Untraceable lines

- **Scope creep** — a feature, refactor, or "improvement" the task did not ask for.
- **Drive-by edits** — renames, reformatting, type annotations, or docstrings on code the task did not otherwise touch.
- **Back-compat residue** — a renamed `_var` kept alive, a re-export kept "just in case", a `// removed` marker, a shim nothing calls.
- **Orphans the diff left** — an import, variable, or function the diff made unused and did not remove. Pre-existing dead code is not this diff's slop; do not flag it.
- **Defensive ceremony** — a guard, `try`/`catch`, or default around an internal call that cannot fail in practice. Name why it cannot fail.

Test each candidate with one sentence: "this line serves the task by …". If you cannot finish the sentence, it is a finding.

## Owned elsewhere — do not flag

- comments that restate the code: `comments`
- a handler that swallows an error: `silent-failures`
- a shallow abstraction or a wrapper with one caller: `modularity`
- a deleted test with a stated harm and no replacement: `tests`

## Severity

- A weakened check on an auth, write, or money path, or a test skipped or deleted with no reason given, is Blocking.
- Other weakened checks and scope creep are Suggested.
- Drive-by edits, residue, orphans, and defensive ceremony are Nit.
