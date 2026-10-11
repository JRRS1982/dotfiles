# Lens: conventions

Question: does this diff break an instruction that a convention file actually states?

Read every convention file you were given, then the diff. Flag only a violation of an instruction written in one of those files, and quote the instruction in `why flagged`. Do not flag:

- taste you hold that no file states
- anything a linter, formatter, or type-checker would catch
- code outside the hunks

Check in particular: naming and file-layout rules, required patterns (early returns, types derived from a schema, no enums), forbidden imports or dependencies, testing-layer rules, logging and error conventions, and commit or PR conventions when the diff touches them.

Severity: a clear violation is Blocking. An ambiguous one is Suggested, with the ambiguity stated.
