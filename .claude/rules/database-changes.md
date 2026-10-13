---
paths:
  - "**/migrations/**"
  - "**/*.sql"
  - "**/schema.prisma"
  - "**/supabase/**"
---

# Database changes

- Invoke the `supabase-postgres-best-practices` skill before writing or changing anything here, including a one-column change.
- Never edit a migration that has been applied anywhere. Add a new one.
- Every new table on Supabase gets row-level security enabled in the same migration, with policies that carry `WITH CHECK` on writes.
- State the rollback before the change: what the down migration or manual reversal is.
