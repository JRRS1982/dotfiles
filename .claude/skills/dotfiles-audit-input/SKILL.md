---
name: dotfiles-audit-input
description: Use when the user asks to trace user input to dangerous sinks, find injection (SQL/NoSQL/command), eval/exec/shell usage, unsafe file uploads, XSS / dangerouslySetInnerHTML, or missing server-side validation — or types /dotfiles-audit-input. Also invoked by dotfiles-audit.
---

# Input-to-Sink Audit

Trace every path where user input reaches something dangerous in this repository. For each, produce a working example payload.

## What to trace

1. **Query injection** — SQL or NoSQL queries built with string concatenation or template literals instead of parameterised queries / prepared statements.
2. **Command execution** — input passed to `eval`, `exec`, `child_process`, `os.system`, `subprocess`, or any shell invocation.
3. **File uploads** — is the filename sanitised, is the type verified server-side (not just by extension or client MIME), can you upload an executable, and can you path-traverse with `../`?
4. **Unescaped HTML** — user content rendered as HTML without escaping, including `dangerouslySetInnerHTML`, `v-html`, `innerHTML`, and markdown renderers that allow raw HTML.
5. **No server-side validation** — endpoints that accept input with no validation on the server at all (trusting client-side checks).

## How to hunt

- Find the sinks first, then trace backward to a user-controlled source: query builders, `eval`/`exec`/`spawn`, `innerHTML`/`dangerouslySetInnerHTML`/markdown render calls, file-write/upload handlers.
- For each sink, confirm whether the tainted value is parameterised, escaped, allow-listed, or validated before it lands.
- For uploads, check the full chain: accepted types, storage path construction, and whether the stored file can be executed or served back.
- Note endpoints whose only validation lives in the frontend.

## Severity

- **CRITICAL** — a working injection into a query, shell, or `eval`; an upload that yields code execution or overwrites arbitrary paths; stored XSS.
- **HIGH** — reflected XSS, path traversal that reads/writes outside the intended dir, NoSQL operator injection.
- **MEDIUM** — missing server-side validation with limited blast radius; markdown renderer allowing raw HTML but behind auth.

## Output (standalone)

A table: `file & line | input source | what it reaches | a working example payload | severity | fix`.

The payload must be concrete (the actual string/JSON that triggers it), not a description.

## Orchestrated mode

When invoked by `dotfiles-audit` (or told to return structured findings), output ONLY a JSON array. Put the example payload in the `attack` field:

```json
[
  {
    "category": "input",
    "location": "src/search.ts:88",
    "issue": "SQL built by string concatenation of req.query.q",
    "attack": "?q=' OR '1'='1  — returns all rows; ?q='; drop table users;--",
    "severity": "CRITICAL",
    "fix": "Use a parameterised query / prepared statement; never concatenate user input into SQL"
  }
]
```

Return `[]` if nothing is found.
