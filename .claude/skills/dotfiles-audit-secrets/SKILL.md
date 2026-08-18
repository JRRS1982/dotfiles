---
name: dotfiles-audit-secrets
description: Use when the user asks to find exposed secrets, leaked API keys, hardcoded credentials, committed .env files, secrets in git history, or secrets shipped to the browser — or types /dotfiles-audit-secrets. Also invoked by dotfiles-audit.
---

# Secrets Audit

Act as a security researcher auditing this repository for exposed secrets. Find every place a credential is leaked, then list every key that must be rotated.

## What to find

1. **Hardcoded secrets** — API keys, tokens, passwords, or connection strings written directly into any file (source, config, scripts, CI, IaC, notebooks).
2. **Committed or unignored `.env`** — `.env*` files that are committed, or that exist but are missing from `.gitignore` so they could be committed.
3. **Secrets in git history** — credentials present in past commits even if the file was later deleted or the value changed. Check history, not just the working tree.
4. **Secrets shipped to the browser** — anything secret embedded in frontend code or build output (bundled JS, source maps, `NEXT_PUBLIC_`/`VITE_`/`REACT_APP_` vars holding real secrets).
5. **Over-privileged public keys** — public/anon/publishable keys doing work that requires a service role or admin scope.

## How to hunt

- Grep the working tree for high-signal patterns: `sk-`, `AKIA`, `AIza`, `ghp_`, `xoxb-`, `-----BEGIN * PRIVATE KEY-----`, `password=`, `secret`, `token`, `Authorization`, connection-string schemes (`postgres://user:pass@`, `mongodb+srv://`).
- Check `.gitignore` against the actual `.env*` files present.
- Scan history: `git log --all -p -S<needle>` for suspected values, and `git log --all --oneline -- .env` (and similar) for files that were ever committed.
- Inspect the build/frontend output directory if one exists.
- For each cloud/service key, determine its privilege level, not just its presence.

## Severity

- **CRITICAL** — a live secret that grants access right now (service-role keys, DB connection strings, private keys, any secret in git history or shipped to the browser).
- **HIGH** — a secret with limited scope or blast radius, or an unignored `.env` that has not yet been committed.
- **MEDIUM** — hygiene issues that are not yet exploitable (weak separation, secrets in local-only files that are correctly ignored).

## Output (standalone)

A table: `file & line | what leaked | how an attacker finds it | severity | exact fix`.

Then a **rotation list**: every key that must be rotated.

> A key that ever touched a commit is burned. Hiding it now is not enough — it must be rotated. Removing it from the current tree does not remove it from history.

## Orchestrated mode

When invoked by `dotfiles-audit` (or told to return structured findings), output ONLY a JSON array, no narrative and no table:

```json
[
  {
    "category": "secrets",
    "location": "config/prod.ts:12",
    "issue": "Stripe live secret key hardcoded",
    "attack": "Anyone with repo read access, or the key in bundled JS, can charge/refund",
    "severity": "CRITICAL",
    "fix": "Move to server-side env var; rotate the key — it is in git history"
  }
]
```

Include a rotation note inside the relevant finding's `fix` field. Return `[]` if nothing is found.
