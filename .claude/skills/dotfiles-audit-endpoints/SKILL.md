---
name: dotfiles-audit-endpoints
description: Use when the user asks which endpoints cost money or resources when called, to check rate limiting, abuse protection, LLM/AI cost exposure, email/SMS spam routes, uncapped queries/exports, email enumeration, or server-side usage metering — or types /dotfiles-audit-endpoints. Also invoked by dotfiles-audit.
---

# Cost & Abuse Endpoint Audit

Find every endpoint in this app that costs money or resources when called, and check its protection. For each, work out what one night of abuse would do.

## What to check

1. **AI / LLM API calls** — routes that trigger a paid model call. What stops a script calling each one 100,000 times tonight? Check auth, per-user limits, and per-IP limits.
2. **Auth flows** — login, signup, and password reset: rate limits, bot protection, and whether response differences (timing, error text, status) let someone enumerate valid emails.
3. **Email / SMS sending** — routes that send a message someone could spam through (invites, notifications, OTP, contact forms), driving cost and reputation damage.
4. **Expensive queries / exports** — endpoints running heavy queries or data exports with no caps or pagination.
5. **Usage metering** — is it enforced server-side, and does it fail closed? A meter checked only in the client, or one that fails open when the metering service errors, is not protection.

## How to hunt

- Enumerate routes and tag each with what it costs per call: a paid API call, an email/SMS, a heavy DB/query/export, or compute.
- For each costly route, find the limiter: auth requirement, per-user quota, per-IP rate limit, captcha/bot check. Note its absence.
- Compare error responses and timing across valid vs invalid identifiers on auth routes.
- Trace the metering path: where the counter is incremented/checked, and what happens when that check fails or the service is down.

## Severity

- **CRITICAL** — an unauthenticated or unlimited route that triggers paid LLM calls, sends email/SMS, or runs unbounded exports; metering that fails open.
- **HIGH** — authenticated but unlimited costly route; email enumeration on auth flows; missing per-IP limits on login.
- **MEDIUM** — pagination missing but query is cheap; weak but present rate limit.

## Output (standalone)

A table: `endpoint | what one call costs me | the abuse scenario | projected damage from one night | severity | the exact limiter to add`.

Make the projected damage concrete (approximate calls/hour × unit cost, or messages sent, or rows exported).

## Orchestrated mode

When invoked by `dotfiles-audit` (or told to return structured findings), output ONLY a JSON array. Put the one-night projection in the `attack` field and the specific limiter in `fix`:

```json
[
  {
    "category": "endpoints",
    "location": "POST /api/generate",
    "issue": "Triggers an LLM call with no auth and no rate limit",
    "attack": "Script hits it ~100k times overnight; at ~$0.01/call that is ~$1,000 in one night",
    "severity": "CRITICAL",
    "fix": "Require auth; add a per-user and per-IP rate limit (e.g. 20/min) and a daily quota; fail closed"
  }
]
```

Return `[]` if nothing is found.
