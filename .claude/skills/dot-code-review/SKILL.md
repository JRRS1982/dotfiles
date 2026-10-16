---
name: dot-code-review
description: Use when the user types /dot-code-review to get a review of the current branch's diff as a paste-ready PR comment. Reads local git, so it works on any host; optionally checks a linked Jira ticket's acceptance criteria and posts to a GitHub PR.
argument-hint: "[base] [JIRA-KEY] [--post] [--praise]"
allowed-tools: Bash(git *), Bash(gh pr *), Agent, Read, Grep, Glob, mcp__claude_ai_Atlassian_Rovo__getAccessibleAtlassianResources, mcp__claude_ai_Atlassian_Rovo__getJiraIssue, mcp__claude_ai_Atlassian_Rovo_2__getAccessibleAtlassianResources, mcp__claude_ai_Atlassian_Rovo_2__getJiraIssue
---

You are producing a code review of the **current branch's diff against its base**, formatted as a concise comment for a pull request. By default you read local git only and post nothing; `--post` (Step 9) is the only step that writes anywhere.

Make a todo list first, then follow these steps precisely. The lens briefs in `lenses/` and the rubric in `judge.md` sit beside this file. Pass them to agents **verbatim**; do not paraphrase them.

## Step 1 — Resolve the base and the diff

Parse `$ARGUMENTS`:
- `--post` → post the finished review to the branch's GitHub PR (Step 9).
- `--praise` → add one line on what the change does well (Step 8).
- A token matching `[A-Z]+-[0-9]+` (e.g. `GOLD-1234`) is the **JIRA_KEY**.
- Any other token is the **BASE**: a branch or a commit.

Run `git fetch --quiet origin` so remote-tracking refs are current. If BASE was not given, use the first that resolves with `git rev-parse --verify --quiet`, in this order: `origin/main`, `origin/master`, `origin/develop`, then `main`, `master`, `develop`. Prefer the remote-tracking ref: a stale local `master` makes other people's merged work look like part of this branch. If none resolve, ask the user for the base and stop until they answer.

```
MERGE_BASE=$(git merge-base "$BASE" HEAD)
git diff --stat "$MERGE_BASE"..HEAD      # changed files
git diff "$MERGE_BASE"..HEAD             # the change under review
```

If the diff is empty, tell the user the branch matches its base and stop. If `git status --porcelain` shows uncommitted changes, say in one line that they are not part of this review, then continue.

If JIRA_KEY was not passed, extract one from `git branch --show-current` with the same pattern. It may be absent; that is fine.

## Step 2 — Gather conventions

List the file paths (not contents) of: the repo-root `CLAUDE.md`, any `CLAUDE.md` in a directory the diff touches, and any convention file those files point to (e.g. `.ai/*.md`, `docs/standards/*.md`, `.claude/rules/*.md`). These are the criteria for the conventions lens.

## Step 3 — Summarise the change

One sentence on what the change does. It becomes the header of the review.

## Step 4 — Decide which lenses run

Always: `conventions`, `bugs`, `history`, `comments`.

Conditional, each keyed to an observable predicate. All three use this pathspec, which excludes tests, fixtures, docs, and config, and which works the same in bash and zsh:

```
EXCL=(. ':(exclude)*test*' ':(exclude)*spec*' ':(exclude)*__tests__*' ':(exclude)*fixtures*' ':(exclude)*.md' ':(exclude)*.json' ':(exclude)*.ya?ml' ':(exclude)*.lock' ':(exclude)*.snap')
git diff --name-only "$MERGE_BASE"..HEAD -- "${EXCL[@]}"          # SOURCE files
git diff "$MERGE_BASE"..HEAD -- "${EXCL[@]}" | grep -E '^\+' | grep -Eq 'try|catch|except|rescue|fallback|\?\?|\berror\b'
git diff "$MERGE_BASE"..HEAD -- "${EXCL[@]}" | grep -E '^\+' | grep -Eq 'MAX_[A-Z_]+|_LIMIT\b|\bLIMIT_|checkRateLimit|\.(safe)?[Pp]arse\(|z\.(number|string|enum)\(|\bmin\(|\bmax\(|throw new|requireUser|\bassert[A-Z]'
```

- `tests` runs when the first command prints at least one file.
- `silent-failures` runs when the second command succeeds. `error` is in the list because some libraries return `{ data, error }` instead of throwing, so their error paths have no catch.
- `completeness` runs when the third command succeeds. It matches a diff that adds a ceiling, a rate-limit check, a validation bound, or an auth/ownership guard — the cases where the risk is not that the guard is wrong but that another path to the same sink was left without one. Deliberately broad: a false positive costs one agent, while a miss ships a guarantee the code does not keep.

Only added lines are searched in all three, so prose in a design document does not trigger them.

Record in the todo list which conditional lenses run and which predicate fired.

## Step 5 — Run the lenses (parallel)

One **Sonnet** agent per lens, all launched in the same turn. Each agent receives: the contents of its `lenses/<name>.md` verbatim, BASE and MERGE_BASE, the diff, the changed-file list, the convention paths from Step 2, and the severity scale below verbatim. The `bugs` lens may read whole modified files and grep for call sites; `completeness` must grep the whole repository, because the path it is looking for is by definition outside the diff; the others read the diff and the files it names.

Each agent returns at most **five** issues, its most severe. For each: `path:line`, a one-line description, why it was flagged, the quoted line(s) as evidence, and a proposed severity. The cap exists because an uncapped tests lens returned eleven findings on one PR and the judge dropped ten of them.

Severity scale (give verbatim):
- **Blocking** — incorrect or broken behaviour, data-loss risk, or a clear violation of an applicable convention file. Would block merge.
- **Suggested** — a real improvement that is not strictly blocking: duplicated logic, a missed edge case, a fragile approach.
- **Nit** — minor or style, and only if a linter or formatter would NOT already catch it.

## Step 6 — Judge each finding (parallel)

First merge duplicates: findings from different lenses on the same lines and the same root cause become one finding, keeping the highest severity and the strongest evidence.

Then one **Sonnet** agent per file that has findings, all in the same turn; files with a single finding share one agent. Each receives `judge.md` verbatim, every finding for that file with its evidence, and the diff. It scores each finding separately and returns, per finding: a score, its own quoted evidence, and one sentence. A score with no quote is invalid: treat it as 0. One agent per file rather than per finding, because each judge must re-read the same diff and file, and findings in one file share that context.

**Drop every finding scoring below 70.** A finding scoring 70 to 79 is verified but minor, so it is at most **Suggested**. Only a finding scoring 80 or above may be **Blocking**, and only after Step 7. If nothing remains, there are no findings.

**Always drop:**
- Pre-existing issues, and issues on lines this diff did not modify.
- Anything a linter, type-checker, compiler, or formatter would catch. Assume CI runs these.
- Pedantic nitpicks a senior engineer would not raise.
- Generic "add more tests / docs / security" unless a convention file or the tests lens names the specific gap.
- Changes that are clearly intentional or part of the broader change.

## Step 7 — Verify Blocking findings

A finding stays **Blocking** only if one of these holds:
- A cheap concrete check confirms it. Cheap means a command that runs locally in under two minutes: a type-check or the single test file covering the line, using a script the repo already defines in `package.json`, a Makefile, or its CLAUDE.md; or a grep that shows the precondition the finding depends on actually exists (the caller that passes the bad value, the sign-in path that creates the user without a password). Run it and read the output.
- No such check applies, and the judge scored it 90 or above with evidence quoting the exact failing line.

Otherwise downgrade it to **Suggested**. Never run anything that writes outside the working tree, deploys, or needs credentials.

## Step 8 — Jira acceptance criteria (only if JIRA_KEY exists)

Resolve the site with `getAccessibleAtlassianResources` and take the first `id` as the cloudId; never hard-code one. Fetch the ticket with `getJiraIssue` and read its acceptance criteria. From the diff, assess which criteria the change plausibly satisfies, and produce ONE line: `AC coverage: <met>/<total> — <the most important unmet or unclear criterion>`. If the ticket has no explicit criteria, write `AC coverage: ticket has no explicit acceptance criteria`. If the tools are unavailable or either call fails, omit the line entirely; do not error.

If `--praise` was passed, also write ONE line, `Strength: <what the change does well>`, grounded in something specific the lenses saw. Without the flag, omit it.

## Step 9 — Output the review

Output **only** the review block as your final message: no preamble, no trailing commentary, no code fence, so the user can paste it raw into the PR. No emojis. One line per finding. Order Blocking → Suggested → Nit. Format exactly:

```
**Review — <one-line summary of the change>** (<N> findings)

Strength: <only with --praise>

1. **[Blocking]** `path:line` — what's wrong; the fix in a few words.
2. **[Suggested]** `path:line` — what to improve; why.
3. **[Nit]** `path:line` — minor point.

AC coverage: 2/3 — no handling for "invalid file type rejected with a clear message".
```

Rules for the block:
- The header summary is Step 3's sentence. `<N>` is the count of surviving findings.
- Include `Strength:` only with `--praise`, and `AC coverage:` only if Step 8 produced one.
- Cite `path:line` for every finding. If there are many, lead with the most important and keep each to one line.
- With **no** surviving findings, output exactly:

```
**Review — <one-line summary of the change>**

No blocking issues found — checked for <the lenses that ran, e.g. bugs, conventions, history, comments, silent failures, tests>.
```
listing only the lenses that ran, and appending `Strength:` and `AC coverage:` lines under the same rules.

**`--post` only:** `git remote get-url origin` must contain `github.com`, and `gh pr view --json number,url` must find a PR for the current branch. Post the block with `gh pr review --comment --body "<block>"`. It is a comment, never an approval or a request for changes; that verdict is the human's. Then append one line to your output: `Posted: <url>`. If the remote is not GitHub or no PR exists, output the block and one line saying why posting was skipped.
