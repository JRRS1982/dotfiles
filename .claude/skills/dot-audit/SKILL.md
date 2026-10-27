---
name: dot-audit
description: Use when the user asks for a full security audit, security review, or "audit my app/repo", or types /dot-audit — runs all five sub-audits (secrets, auth, database, input, endpoints) and merges them into one severity-ranked report.
---

# Security Audit Orchestrator

Run a complete security audit of the current repository by dispatching the five specialised sub-audits, then merge their results into a single report ranked by severity across every category.

The five sub-audits are:

| Sub-skill | Covers |
|-----------|--------|
| `dot-audit-secrets` | Exposed secrets, keys in git history, secrets shipped to the browser |
| `dot-audit-auth` | Session verification, token handling, password & reset flows |
| `dot-audit-database` | RLS / row-level access rules, cross-user attack queries, storage buckets |
| `dot-audit-input` | Injection, eval/exec/shell, file uploads, unescaped HTML |
| `dot-audit-endpoints` | Cost/resource abuse, rate limits, email enumeration, spammable routes |

## Scope

- No arguments → run **all five** sub-audits.
- Arguments naming categories (e.g. `secrets auth`, or `/dot-audit database input`) → run only those. Accept the short name (`secrets`) or the full skill name (`dot-audit-secrets`).

## How to run

1. **Confirm the target repo.** Use the current working directory unless the user names another path. State which repo you are auditing.

2. **Dispatch the sub-audits in parallel.** For each in-scope category, launch one subagent (Agent tool, `general-purpose`) in a single message so they run concurrently. Give each subagent this instruction:

   > You are running the `<dot-audit-CATEGORY>` security audit against the repository at `<ABSOLUTE_REPO_PATH>`. Invoke that skill with the Skill tool and follow it in **orchestrated mode**: return ONLY the structured findings block (the JSON array defined in `~/.claude/skills/dot-audit/findings-schema.md`) and nothing else. Do not print the narrative table.

   If a subagent cannot load the named skill, tell it to read the skill file directly and follow it. The skills are symlinked into the runtime skills directory; resolve the path with `readlink -f ~/.claude/skills/dot-audit-CATEGORY/SKILL.md` if needed.

3. **Collect** each subagent's findings array. A subagent that finds nothing returns `[]`.

4. **Merge and rank.** Combine all findings into one list. Sort by severity (`CRITICAL` → `HIGH` → `MEDIUM`), and within a severity keep them grouped by category. De-duplicate findings that name the same file/line/table from two audits (keep the higher severity).

## Findings schema

Every sub-audit returns the array defined in [findings-schema.md](findings-schema.md): `category`, `location`, `issue`, `attack`, `severity` (`CRITICAL|HIGH|MEDIUM`), `fix`. Read that file before merging; it is the only definition.

## Output

Produce, in this order:

1. **Header** — repo path, which sub-audits ran, counts by severity (e.g. `3 CRITICAL, 5 HIGH, 4 MEDIUM`).
2. **Findings table** — all findings, severity-ranked (`CRITICAL` → `HIGH` → `MEDIUM`), columns in this order: `severity | type | location | issue | attack | fix`.
   - `type` is the audit that surfaced it: `secrets` / `auth` / `database` / `input` / `endpoints`. Always show it so the source is clear at a glance.
   - `issue` and `fix` carry the detail: one or two full sentences each (~20–30 words), enough to understand the problem and act on the fix without opening a file. Still prose, not a paragraph — no code blocks in the cell.
   - `attack` stays terse: the payload, the query, or the one-night cost projection.
   - For secrets that ever touched a commit, the `fix` cell must say to **rotate** — hiding is not enough.
3. **Per-category notes** — anything a sub-audit flagged that does not fit a table cell (e.g. corrected SQL from the database audit, long example payloads from the input audit). Keep these as short labelled code blocks below the table.

If a sub-audit did not run — it errored, timed out, returned something other than a findings array, or you ran it inline instead of as its own subagent — the **first line** of the report, above the header, is `**INCOMPLETE — dot-audit-<category> did not run: <one-line reason>.**`, one line per failure. Never drop a category silently, and never report a zero count for a category that did not run: a missing audit reads exactly like a clean one. An empty array `[]` from a subagent that ran is a clean result, not a failure.

## Notes

- Subagents inherit the repo but not this chat. Everything a sub-audit needs is in its own skill file, so passing the category name and repo path is enough.
- This orchestrator only reads and reports. It does not apply fixes. Offer to fix specific findings after the report if the user wants.
