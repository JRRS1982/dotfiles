---
name: dot-stg-check
description: Use when the user asks whether a pull request or branch has been deployed to staging (stg) or had its acceptance tests run, wants to know if a PR was tested before merge, or types /dot-stg-check. Also run by dot-code-review. Read-only.
argument-hint: "[PR-number]"
allowed-tools: Bash(bash *dot-stg-check/stg-status.sh*)
---

# Staging check

CircleCI reports every job to GitHub as a commit status (`ci/circleci: <job>`). The statuses on a PR's **head commit** say whether that exact code reached staging and passed acceptance tests. No CircleCI token is needed; `gh` is enough.

## Run

From inside the repository, run the script beside this file:

```
bash <this skill's directory>/stg-status.sh [PR-number]
```

With no argument it uses the current branch's PR, or the branch's own commits when there is no PR, or `HEAD` alone when the branch is already on its base. It prints exactly two lines, `Staging: ...` and `Acceptance tests: ...`. Print them verbatim. A line beginning `Warning — ` asks the author to act before merging; it is a nudge, never a blocker. Do not upgrade, soften, or reword it.

## What each line means

Staging:

| Line | Meaning |
|---|---|
| `deployed on head` | A staging deploy job succeeded on the PR's latest commit. |
| `running on head` | The deploy is in progress. |
| `Warning — failed on head` | The deploy failed or errored on the latest commit. |
| `Warning — last deployed on <sha>, N commit(s) behind head` | It was deployed from an earlier commit; the latest code is not on staging. |
| `Warning — not deployed on head — approve <gates>` | The pipeline offers a staging deploy behind an approval gate nobody approved. |
| `no staging deploy in this branch's pipeline` | Nothing to deploy. |

Acceptance tests are reported **suite by suite against the deploy that passed on head**, so the line answers "are we covered?":

| Line | Meaning |
|---|---|
| `all 3 passed against deploy-stg-blue on head` | Covered: every suite that tests that deploy passed. |
| `Warning — 1/3 passed against deploy-stg-blue — passed: chrome; failed: safari; not run: android (approve <gates>)` | Not covered. Each suite is listed under what happened to it, with the gates that start the ones not run. |
| `Warning — not run — staging is not deployed on head; deploy it, then run: <suites>` | The pipeline has acceptance tests but nothing to run them against yet. |
| `waiting for the staging deploy on head ... to finish` | Deploy in progress. |
| `none in this repository's pipeline` | No acceptance tests exist. Nothing to do. |

Either line can also be `none — this repository has no CircleCI pipeline`, or `unknown — ...` when the head commit has no statuses (unpushed, CI not started, or a commit CircleCI skipped because a later one in the same push was built).

## How it decides

- **Gate**: an approval job in `.circleci/config.yml` at the head commit, or any job whose name contains `approval` or `kick-off`. The config matters because a gate can have a deploy-like name such as `deploy-to-staging`.
- **Staging deploy**: any other job matching `stg` or `staging`, except `build*` and `k6` jobs.
- **Acceptance suites that count**: the config's acceptance jobs (`acceptance`, `e2e`, `bs-tests`) whose `requires` include a deploy that passed on head. A suite that requires only a gate tests shared staging, not this branch, and is left out. Suite names are shortened (`blue-staging-run-acceptance-tests-chrome` → `chrome`).
- Earlier commits are checked only when the head has no result, and only the last ten.
- Without a readable config, acceptance falls back to matching status names, with no per-suite breakdown.

## Limits

- **Has been, not still is.** Shared staging slots can be redeployed by anyone: a passing deploy shows the code went there, not that it is still there.
- **CircleCI statuses only.** GitHub Actions check runs are not read.
