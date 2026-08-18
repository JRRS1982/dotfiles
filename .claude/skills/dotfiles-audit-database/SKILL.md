---
name: dotfiles-audit-database
description: Use when the user asks to audit database access rules, row-level security (RLS), Supabase policies, table permissions, or storage bucket access — or types /dotfiles-audit-database. Also invoked by dotfiles-audit.
---

# Database Access Audit

Audit the database access rules table by table (Supabase RLS or the equivalent for whatever DB this repo uses). Prove whether one user can reach another user's data.

## What to check

1. **RLS enabled per table** — list every table and whether row-level security is on. **Any table reachable with the public/anon key and no RLS is CRITICAL.**
2. **Read/write across users** — for each policy, write the exact query user A would run to read or edit user B's rows, and state whether it succeeds.
3. **Client-controlled filters** — flag any policy that filters on a value the client sends (a column, a header, a JWT claim the client can set) instead of the server-trusted identity (`auth.uid()` or equivalent).
4. **INSERT and UPDATE, not just SELECT** — can you insert rows pointed at another user, or update columns you should not own (e.g. `role`, `credits`, `is_admin`, `plan`)? Check `WITH CHECK` clauses, not only `USING`.
5. **Storage buckets** — apply the same checks to file storage: bucket visibility, per-object ownership, path-based access rules.

## How to hunt

- Read the migration / policy definitions (Supabase `policies`, SQL `CREATE POLICY`, ORM-level guards).
- For each table, note: RLS on/off, which policies exist for SELECT/INSERT/UPDATE/DELETE, and what each policy's `USING` / `WITH CHECK` predicate compares.
- Identify columns a user must not be able to set on themselves (privilege/credit columns) and confirm a policy prevents it.
- Check storage bucket config and object-level rules.

## Severity

- **CRITICAL** — table reachable with the public key and no RLS; a working cross-user read/edit; ability to set a privilege/credit column on yourself; public storage bucket exposing others' files.
- **HIGH** — policy filters on a client-supplied value; INSERT/UPDATE policy missing a `WITH CHECK` so ownership is not enforced on write.
- **MEDIUM** — overly broad but low-impact policy; missing DELETE restriction on non-sensitive data.

## Output (standalone)

A table: `table | policy state | the attack query | what leaks | severity | corrected policy as real SQL`.

For every CRITICAL/HIGH, give the corrected policy as runnable SQL, not a description.

## Orchestrated mode

When invoked by `dotfiles-audit` (or told to return structured findings), output ONLY a JSON array. Put the corrected SQL in the `fix` field:

```json
[
  {
    "category": "database",
    "location": "table:public.profiles",
    "issue": "RLS disabled; readable with anon key",
    "attack": "select * from profiles; returns every user's row via the public client",
    "severity": "CRITICAL",
    "fix": "alter table profiles enable row level security; create policy own_rows on profiles for select using (auth.uid() = user_id);"
  }
]
```

Return `[]` if nothing is found.
