# Eval: halcyon PR 208 (auth audit fixes)

## Reproduce

Public repository `JRRS1982/halcyon`. Use a throwaway worktree so the main checkout is untouched.

```
git -C ~/PersonalProjects/halcyon fetch --quiet origin
git -C ~/PersonalProjects/halcyon worktree add --detach /tmp/halcyon-pr208 88804e99a39897712134643d0065a33d6d648310
cd /tmp/halcyon-pr208 && /dot-code-review 0678b314394879c15a16066e4ef7f3621cb669c3
```

Remove with `git worktree remove --force /tmp/halcyon-pr208` afterwards.

## Expected behaviour

- Step 4: SOURCE lists 14 files; the `tests` lens runs; the `silent-failures` lens runs (the source diff contains `catch`, `??` and `error`).
- Step 5: the `history` lens returns no issues. Every other lens returns at least one.
- Step 6 and 7, findings that must survive as **Blocking**:
  - `src/app/(app)/settings/DataPrivacy.tsx` around line 126: the client maps thrown server-action messages, but production Next.js redacts them, so a wrong password always shows the generic fallback. Judge score 90 or above.
  - `src/app/(app)/settings/dataActions.ts` around line 42: `verifyPassword` calls `signInWithPassword`, which always fails for Google OAuth accounts, so those users cannot reset, clear or delete. Verified by grep: `signInWithOAuth` exists in `src/app/auth/oauth-actions.ts` and `verifyPassword` has no provider branch.
- Findings that must appear as at most **Suggested** (scores 70 to 79 on the baseline run): the "wait a minute" message on a one-hour bucket in `sign-up/actions.ts` and `sign-in/actions.ts`; every Supabase failure reported as "Incorrect password"; the untested throttle branch of `verifyPassword`.
- Findings that must be **dropped**: the `as jest.Mock` cast (pre-existing pattern); fail-open on the password limiter (documented design choice); the warn-and-redirect on sign-up provider error (outside the diff).
- Output: the review block with five findings, no `AC coverage:` line (no Jira key), no `Strength:` line (no `--praise`).

## Baseline (2026-10-06)

Twenty-nine raw findings from six lenses, twenty-five after merging duplicates, five survived the judge. The tests lens alone produced eleven, which is why lenses are now capped at five.
