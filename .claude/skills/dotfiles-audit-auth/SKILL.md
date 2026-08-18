---
name: dotfiles-audit-auth
description: Use when the user asks to audit authentication, check auth on routes/endpoints, review session handling, password rules, password reset, or email verification — or types /dotfiles-audit-auth. Also invoked by dotfiles-audit.
---

# Auth Audit

Attack the authentication of this repository like you want in. Walk every auth path and find where it breaks.

## What to check

1. **Route / endpoint session verification** — list every route and API endpoint and whether it verifies a valid session before doing work. Flag any that skip verification. Any endpoint that trusts a user ID from the request body (or query/header) instead of the session is **CRITICAL** — that is horizontal privilege escalation.
2. **Session handling** — where tokens live (cookie flags: `HttpOnly`, `Secure`, `SameSite`; or localStorage), whether they expire, and whether logout and password change actually invalidate existing sessions/tokens.
3. **Password rules** — minimum length, breached-password check, and any protection the auth provider offers that has been left off (MFA, lockout, rotation).
4. **Password reset & email verification** — can you reset someone else's password (token reuse, guessable token, no ownership check)? Can you use the app with an unverified email? Are reset tokens single-use and time-limited?

## How to hunt

- Enumerate routes from the router/framework (Express/Next/FastAPI/etc.) and middleware. Map each to the auth check that guards it, or note its absence.
- Trace the session/token lifecycle: issue → store → verify → expire → revoke. Confirm logout and password-change paths revoke.
- Find the identity source in each handler: does it read `session.userId` / `auth.uid()`, or does it read an ID from `req.body` / `req.params` / `req.query`?
- Read the reset and verification handlers end to end.

## Severity

- **CRITICAL** — endpoint trusts a client-supplied user ID instead of the session; unauthenticated access to protected data/actions; resetting another user's password.
- **HIGH** — sessions that never expire, logout/password-change that leaves tokens valid, missing breached-password check, usable unverified email where it matters.
- **MEDIUM** — weak-but-nonzero password policy, missing cookie hardening flags, no lockout.

## Output (standalone)

A table: `flow | weakness | exact exploit steps | severity | fix`.

Cover each of the four areas above. For CRITICAL findings, write the concrete exploit steps an attacker would run.

## Orchestrated mode

When invoked by `dotfiles-audit` (or told to return structured findings), output ONLY a JSON array:

```json
[
  {
    "category": "auth",
    "location": "POST /api/orders",
    "issue": "Handler reads userId from request body, not the session",
    "attack": "Send {\"userId\":\"victim\"} to read/modify another user's orders",
    "severity": "CRITICAL",
    "fix": "Derive the user from the verified session; ignore any client-supplied user ID"
  }
]
```

Return `[]` if nothing is found.
