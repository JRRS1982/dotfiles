# Findings schema

Every `dot-audit-*` sub-audit returns one JSON array of findings in this shape when it runs in orchestrated mode. `dot-audit` merges these arrays, so the field names and the severity set are fixed here and nowhere else.

```json
[
  {
    "category": "secrets|auth|database|input|endpoints",
    "location": "path/to/file.ts:42 | table:public.users | POST /api/generate",
    "issue": "what is wrong, in one line",
    "attack": "how an attacker finds or exploits it",
    "severity": "CRITICAL|HIGH|MEDIUM",
    "fix": "the exact change to make"
  }
]
```

Rules:

- `category` is the sub-audit's own name without the `dot-audit-` prefix.
- `location` is a file and line, a table, or a method and route. One per finding.
- `severity` is one of the three values above. Nothing lower is reported.
- Return `[]` when nothing is found. Never return prose or a table in orchestrated mode.

## One example per category

The category-specific conventions live in the `attack` and `fix` fields.

**auth**

```json
{ "category": "auth", "location": "POST /api/orders", "issue": "Handler reads userId from request body, not the session", "attack": "Send {\"userId\":\"victim\"} to read/modify another user's orders", "severity": "CRITICAL", "fix": "Derive the user from the verified session; ignore any client-supplied user ID" }
```

**database** (corrected SQL goes in `fix`)

```json
{ "category": "database", "location": "table:public.profiles", "issue": "RLS disabled; readable with anon key", "attack": "select * from profiles; returns every user's row via the public client", "severity": "CRITICAL", "fix": "alter table profiles enable row level security; create policy own_rows on profiles for select using (auth.uid() = user_id);" }
```

**endpoints** (the one-night cost projection goes in `attack`, the specific limiter in `fix`)

```json
{ "category": "endpoints", "location": "POST /api/generate", "issue": "Triggers an LLM call with no auth and no rate limit", "attack": "Script hits it ~100k times overnight; at ~$0.01/call that is ~$1,000 in one night", "severity": "CRITICAL", "fix": "Require auth; add a per-user and per-IP rate limit (e.g. 20/min) and a daily quota; fail closed" }
```

**input** (the example payload goes in `attack`)

```json
{ "category": "input", "location": "src/search.ts:88", "issue": "SQL built by string concatenation of req.query.q", "attack": "?q=' OR '1'='1  — returns all rows; ?q='; drop table users;--", "severity": "CRITICAL", "fix": "Use a parameterised query / prepared statement; never concatenate user input into SQL" }
```

**secrets** (any key that ever touched a commit gets a rotation note in `fix`)

```json
{ "category": "secrets", "location": "config/prod.ts:12", "issue": "Stripe live secret key hardcoded", "attack": "Anyone with repo read access, or the key in bundled JS, can charge/refund", "severity": "CRITICAL", "fix": "Move to server-side env var; rotate the key — it is in git history" }
```
