---
name: dotfiles-code-review
description: Review the current branch's local diff (against its base) and produce a concise, paste-ready PR review comment. Use when the user types /dotfiles-code-review. Platform-agnostic (works for GitHub and Bitbucket checkouts) — it reads local git, never a hosting API, so the output is copy-pasted into the PR by hand. Optionally checks the diff against a linked Jira ticket's acceptance criteria.
argument-hint: "[base-branch] [JIRA-KEY]"
disable-model-invocation: true
allowed-tools: Bash(git *), mcp__claude_ai_Atlassian_Rovo__getJiraIssue
---

You are producing a code review of the **current branch's local diff** and formatting it as a concise comment the user will copy-paste onto a pull request (GitHub or Bitbucket). You never post anything yourself and never call a hosting API — you read local git only.

Make a todo list first, then follow these steps precisely.

## Step 1 — Resolve the base and the diff

Parse `$ARGUMENTS`:
- A token that looks like a branch (e.g. `main`, `master`, `develop`, `origin/main`) is the **BASE**.
- A token matching `[A-Z]+-[0-9]+` (e.g. `GOLD-1234`) is the **JIRA_KEY**.

Determine BASE if not given: use the first that exists, checked with `git rev-parse --verify --quiet`: `main`, `master`, `develop` (try `origin/` prefixed too). If none resolve, ask the user for the base branch and stop until they answer.

Compute the review target:
```
MERGE_BASE=$(git merge-base "$BASE" HEAD)
git diff --stat "$MERGE_BASE"..HEAD      # changed files
git diff "$MERGE_BASE"..HEAD             # the change under review
```
If the diff is empty, tell the user there is nothing to review (the branch matches its base) and stop.

If JIRA_KEY was not passed, try to extract one from the current branch name (`git branch --show-current`) using the `[A-Z]+-[0-9]+` pattern. It may be absent — that is fine.

## Step 2 — Gather CLAUDE.md context

List the file paths (not contents) of any relevant `CLAUDE.md` files: the repo root `CLAUDE.md` (if present) and any `CLAUDE.md` in directories the diff modifies. These are guidance for how code should be written; treat them as review criteria where applicable.

## Step 3 — Summarise the change

Read the diff and write a one-sentence summary of what the change does. This becomes the header line of the review.

## Step 4 — Multi-lens review (parallel)

Launch 4 parallel Sonnet agents, each reviewing the same diff through one lens. Each returns a list of issues; for each issue it gives `path:line`, a one-line description, the reason it was flagged, and a **proposed severity** (Blocking / Suggested / Nit):

- **Agent 1 — CLAUDE.md compliance:** does the change violate any applicable instruction in the CLAUDE.md files from Step 2? Cite the specific instruction.
- **Agent 2 — bug scan:** read only the diff and scan for real bugs (logic errors, unhandled cases, resource/ordering mistakes, data-loss risks). Focus on substantive bugs, not nitpicks. Ignore likely false positives.
- **Agent 3 — history context:** use `git blame`/`git log` on the modified regions to spot bugs that only show up in light of how the code got here (e.g. re-introducing a previously fixed issue, breaking an invariant a past commit established).
- **Agent 4 — code-comment adherence:** read comments in the modified files and check the change respects any guidance they state.

Severity guidance to give each agent verbatim:
- **Blocking** — incorrect/broken behaviour, data-loss risk, or a clear violation of an applicable CLAUDE.md instruction. Would block merge.
- **Suggested** — a real improvement that isn't strictly blocking (duplicated logic, a missed edge case, a fragile approach).
- **Nit** — minor/style, and only if a linter/formatter would NOT already catch it.

## Step 5 — Confidence filter (parallel)

For each issue from Step 4, launch a Haiku agent that scores confidence 0–100 that the issue is real (not a false positive or pre-existing). For CLAUDE.md-flagged issues, it must confirm the CLAUDE.md actually calls out that specific thing. Rubric (give verbatim):
- 0: false positive / pre-existing / doesn't survive light scrutiny.
- 25: might be real, could not verify; if stylistic, not explicitly required by CLAUDE.md.
- 50: verified real but a nitpick or rare in practice.
- 75: verified, likely hit in practice, existing approach insufficient — or directly named in CLAUDE.md.
- 100: certain, will happen frequently, evidence directly confirms it.

**Drop every issue scoring below 80.** Deduplicate issues flagged by more than one lens (keep the highest severity). If nothing remains, there are no findings.

**Always-drop false positives:**
- Pre-existing issues, and issues on lines this diff did not modify.
- Anything a linter, type-checker, compiler, or formatter would catch (imports, type errors, formatting, newline nits) — assume CI runs these.
- Pedantic nitpicks a senior engineer wouldn't raise.
- Generic "add more tests / more docs / general security" unless an applicable CLAUDE.md requires it.
- Changes that are clearly intentional or part of the broader change.

## Step 6 — Jira acceptance-criteria check (only if JIRA_KEY exists)

Fetch the ticket with `getJiraIssue` (cloudId `mvfglobal.atlassian.net`) and read its acceptance criteria. Assess, from the diff, which criteria the change plausibly satisfies. Produce ONE line: `AC coverage: <met>/<total> — <the most important unmet or unclear criterion>`. If the ticket has no explicit acceptance criteria, write `AC coverage: ticket has no explicit acceptance criteria`. If the fetch fails or the MCP tool is unavailable, omit the AC line entirely (do not error).

## Step 7 — Output the paste-ready review

Output **only** the review block as your final message — no preamble, no trailing commentary, no code fence (so the user can select and paste raw Markdown into the PR). No emojis. Keep every finding to a single line. Order findings Blocking → Suggested → Nit. Format exactly:

```
**Review — <one-line summary of the change>** (<N> findings)

1. **[Blocking]** `path:line` — what's wrong; the fix in a few words.
2. **[Suggested]** `path:line` — what to improve; why.
3. **[Nit]** `path:line` — minor point.

AC coverage: 2/3 — no handling for "invalid file type rejected with a clear message".
```

Rules for the block:
- The header summary is Step 3's sentence. `<N>` is the count of surviving findings.
- Include the `AC coverage:` line only if Step 6 produced one.
- If there are **no** surviving findings, output exactly:

```
**Review — <one-line summary of the change>**

No blocking issues found — checked for bugs and CLAUDE.md compliance.
```
(append the `AC coverage:` line if Step 6 produced one.)
- Cite `path:line` for every finding. Keep the whole block tight — if there are many findings, lead with the most important and keep each to one line.
