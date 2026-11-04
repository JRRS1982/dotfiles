# Evaluations for dot-stg-check

Run the script on real PRs whose state you have confirmed with `gh pr checks <n>`, one per shape below, and compare. Keep the cases themselves out of this public repository: repo names, PR numbers, SHAs and CI URLs belong in a private copy.

| Shape | Expected |
|---|---|
| Deploy gate named like a deploy (`deploy-to-staging`), not approved | `Warning — Staging: not deployed ... approve deploy-to-staging`, never `deployed` |
| Deployed, then pushed again | `Warning — Staging: last deployed on <sha>, 1 commit(s) behind head` |
| Deployed to a slot, no acceptance suite run | `Warning — Acceptance tests: 0/N passed against <deploy> ... not run: <every suite> (approve <that slot's gates>)` |
| Some suites passed, one failed, others not run | `Warning — Acceptance tests: k/N passed ... passed: ...; failed: ...; not run: ...` |
| Every suite for the deploy passed, plus a failed run against shared staging | `Acceptance tests: all N passed against <deploy> ...`; the shared-staging run is ignored |
| Deploy still running | `Staging: running on head` / `Acceptance tests: waiting for the staging deploy ...` |
| No acceptance jobs in the config | `Acceptance tests: none in this repository's pipeline.` |
| Repository with no CircleCI config | both lines `none — this repository has no CircleCI pipeline.` |
| Branch already merged, run with no argument | checks `HEAD` itself; `unknown — no CI statuses` if CircleCI skipped that commit |

When no real PR shows a shape (passing suites can be rare), put a stub `gh` first on `PATH` that answers `repo view`, `pr view`, the config fetch and the status fetch from fixture files.
