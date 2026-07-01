---
name: dotfiles-gc
description: Create a git commit. Use when the user types /dotfiles-gc, with optional Jira ticket key and/or commit title message.
argument-hint: "[TICKET-123] [-m 'title']"
disable-model-invocation: true
allowed-tools: Bash(git *)
---

# Git Commit Skill

You are creating a git commit on behalf of the user. They have already reviewed and tested the code — your job is to construct a well-structured commit message and execute the commit.

## Parsing $ARGUMENTS

The user may pass arguments in any combination of these forms:

- `/dotfiles-gc` — no arguments
- `/dotfiles-gc GOLD-1924` — Jira ticket key only
- `/dotfiles-gc -m "My title"` — commit title only
- `/dotfiles-gc GOLD-1924 -m "My title"` — both
- `/dotfiles-gc -m "My title" GOLD-1924` — both (order may vary)

**Extract:**
1. **TICKET_KEY** — a token matching the pattern `[A-Z]+-[0-9]+` (e.g. `GOLD-1924`). May be absent.
2. **USER_TITLE** — the value passed after `-m`, if present (strip surrounding quotes). May be absent.

---

## Step 1 — Gather Git Context

Run the following to understand what is being committed:

```
git status
git diff --cached
git log --oneline -10
git branch --show-current
```

If `git diff --cached` is empty, check `git diff` (unstaged changes). If both are empty, tell the user there is nothing to commit and stop.

---

## Step 2 — Determine the Jira Ticket Key

Work through the following priority order and stop as soon as you have a key:

**a) Explicit argument** — if `TICKET_KEY` was parsed from `$ARGUMENTS`, use it. No confirmation needed.

**b) Branch name** — check the current branch name for a pattern like `GOLD-1924/some-description` or `GOLD-1924-some-description`. Extract the key if found. No confirmation needed.

**c) Recent commits on this branch** — scan the last 10 commit messages for a `[A-Z]+-[0-9]+` pattern. If found, surface the key and your reasoning, then **ask the user to confirm** before proceeding:
> "I found ticket `GOLD-1234` in recent commits on this branch. Should I use that, or would you like to specify a different key? (Reply with the key to use, or press Enter to skip)"

**d) Context and plan** — if none of the above, infer from the staged diff and any prior conversation context (e.g. a plan mentioning a ticket). Surface your reasoning and **ask the user to confirm**:
> "Based on the changes, I think this relates to `GOLD-5678`. Should I use that, or specify a different key? (Reply with the key or press Enter to skip)"

**e) No ticket determined** — if nothing can be inferred, prompt the user to optionally specify one.

**f) No ticket** — if nothing can be inferred and the user declines to provide one, proceed without one.

---

## Step 3 — Determine the Commit Title

**If `USER_TITLE` was provided:** use it verbatim as the title line (after any ticket prefix).

**If not provided:** write a concise imperative-mood title (≤72 chars, no trailing period) that summarises the change — the same quality you would produce autonomously.

---

## Step 4 — Compose the Commit Message

Assemble the message in this exact structure:

```
[TICKET-KEY] Title line here

- Bullet summary of what changed and why
- Additional context about approach or tradeoffs
- Any important notes (e.g. breaking changes, migration steps)

Co-Authored-By: ${CLAUDE_MODEL} <noreply@anthropic.com>
```

**Rules:**
- If a ticket key was determined, it goes at the very start of the first line in the format `[TICKET-KEY] `.
- If no ticket key, the title starts directly.
- Leave a blank line between the title and the body.
- The body should be what you would normally write autonomously in a commit: concise bullets covering *what* changed, *why*, and any notable detail. Aim for 3–7 bullets unless the change is trivial.
- Do not pad or repeat the title in the body.
- Always include a `Co-Authored-By` trailer as the final line, separated from the body by a blank line, using the current model from the `$CLAUDE_MODEL` environment variable. Format: `Co-Authored-By: $CLAUDE_MODEL <noreply@anthropic.com>`

**Show the proposed commit message to the user before committing:**

```
Proposed commit message:
─────────────────────────────
[GOLD-1924] Add user avatar upload to profile page

- Introduce AvatarUpload component with drag-and-drop support
- Validate file type (JPEG/PNG) and size (≤5 MB) on the client
- Store uploads in S3 via existing FileService abstraction
- Update UserProfile to display avatar with fallback initials
- Add unit tests for validation logic

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
─────────────────────────────
Proceed with commit? [Y/n]
```

Wait for confirmation. If the user says no or requests changes, revise accordingly before committing.

---

## Step 5 — Execute the Commit

Once confirmed, run:

```bash
git commit -m "<full message>"
```

Use `-m` with the full message. For multi-line messages, use multiple `-m` flags (each `-m` becomes a paragraph) or a heredoc if needed.

Report the resulting commit hash and title on success.

---

## Edge Cases

- **Nothing staged:** if only unstaged changes exist, ask the user whether to stage everything (`git add -A`) or specific files before continuing.
- **Merge/rebase in progress:** warn the user and do not commit.
- **Empty repo / no prior commits:** proceed normally; omit the log-based ticket inference step.