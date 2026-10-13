# Eval: halcyon PR 227 (row ceilings and SITE_URL)

The diff this lens was written for. It adds three guards and misses three paths
to the same sinks, and every miss is in a file the diff does not touch — so the
other five lenses read it as clean work. A `/dot-audit` run the next day found
all three, one of them as the only HIGH.

## Reproduce

Public repository `JRRS1982/halcyon`. Use a throwaway worktree so the main
checkout is untouched.

```
git -C ~/PersonalProjects/halcyon fetch --quiet origin
git -C ~/PersonalProjects/halcyon worktree add --detach /tmp/halcyon-pr227 4e6113f2bd91f72850aff2c6f861b6ef9465b84d
cd /tmp/halcyon-pr227 && /dot-code-review 0edf70a251e4a1d349163ff52fea0a3f15979a3c
```

Remove with `git worktree remove --force /tmp/halcyon-pr227` afterwards.

## Expected behaviour

- Step 4: the `completeness` lens runs — added lines introduce `MAX_PLAN_ROWS_PER_KIND`, `MAX_ITEMS_PER_PERIOD` and `requiredOnVercelProduction(...)`. `tests` runs. `silent-failures` runs (`throw new Error` on the new ceilings).
- Step 5, the `completeness` lens must report all three of these. Each is a path to a sink the diff guards, in a file the diff never opens:
  - `src/lib/plan/applySyncPlan.ts` around line 200: `addRow` creates `PlanAsset`/`PlanLiability`/`PlanIncome`/`PlanExpense` with `tx.*.create()` and never calls `nextSortOrderWithinCap`, so `MAX_PLAN_ROWS_PER_KIND` does not apply to the Sync path at all.
  - `src/app/(app)/balance/actions.ts` around line 195: `copyBalancePeriodFrom` writes one `BalanceItem` per live account via `createMany` with no cap, while the twin `copyPeriodFrom` in the diff gains `MAX_ITEMS_PER_PERIOD`.
  - `src/lib/accounts/schemas.ts` lines 35 and 73: `year` and `fromYear` are `z.number().int()` while the diff bounds the same field with `calendarYear` in `src/lib/budget/schemas.ts` and `src/lib/balance/schemas.ts`.
- Severity: the first two are Suggested — the guards are for cost and resource use, not auth or ownership. The third is Suggested on the same scale, though its effect is wider than cost: an unbounded year writes a `FinancialPeriod` that outranks every real month as "the latest period".
- The lens must say in its wording that the new constants now read as a guarantee the code does not keep. That phrasing is the point of the lens; a report that only lists the files has not understood it.

## Known weakness this records

The baseline run of the other five lenses on this diff produces **no finding on
any of the three**, which is correct behaviour for them and the reason this lens
exists. If a future edit makes `bugs` or `conventions` catch them too, note it
here rather than removing this eval — two lenses agreeing is a merge in Step 6,
not a problem.
