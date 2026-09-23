---
name: dot-deslop
description: Strip AI-introduced slop from the current branch diff — obvious comments, needless try/catch, `any` casts, premature abstractions, and changes nobody asked for. In skill mode, lints a SKILL.md for the same failings in prose. Use when the user types /dot-deslop, before raising a PR or before committing a skill.
argument-hint: "[base-branch] | <path/to/SKILL.md>"
disable-model-invocation: true
allowed-tools: Bash(git *), Bash(pnpm *), Bash(npx *), Read, Edit
---

You are removing slop introduced **by this branch**. Not general tidying — `/simplify` and `code-simplifier` already cover reuse, efficiency and altitude. Your target is the specific residue an AI leaves behind: scope nobody asked for, ceremony around code that does not need it, and prose that states the obvious.

Pick the mode from `$ARGUMENTS`: a path ending in `SKILL.md` selects **skill mode**; anything else (or nothing) selects **code mode**.

## Code mode

### Step 1 — Resolve the base and read the diff

A token that looks like a branch is the BASE. Otherwise resolve it: the first of `master`, `main`, `develop` that `git rev-parse --verify --quiet` accepts, trying the `origin/` prefix too. If none resolve, ask for the base and stop.

```
MERGE_BASE=$(git merge-base "$BASE" HEAD)
git diff --stat "$MERGE_BASE"..HEAD
git diff "$MERGE_BASE"..HEAD
```

If the diff is empty, say so and stop.

### Step 2 — Find the slop

Read the diff and flag only what this branch added:

- Comments that restate the code, or that break the file's existing comment density
- `try`/`catch` around a trusted internal path that cannot fail in practice
- `as any` / `@ts-ignore` used to silence a type error rather than fix it
- An abstraction built for one caller — a factory, a wrapper, a helper used once
- Nesting that an early return would flatten
- Back-compat residue: renamed `_vars`, re-exports kept "just in case", `// removed` markers
- **Scope creep** — features, refactors or "improvements" outside what the task asked for
- **Drive-by edits** — docstrings, type annotations or renames applied to code the task did not touch

The last two matter most. They are the ones a reviewer will notice and nothing else in this repo looks for.

### Step 3 — Cut

Minimal, focused edits. Three similar lines beat a premature abstraction. Before deleting anything, confirm it is genuinely unused — `git grep` the symbol. Keep behaviour identical unless you are fixing a clear bug, and say so explicitly if you do.

### Step 4 — Verify

```
git diff "$MERGE_BASE"..HEAD     # confirm only slop left
```

Then run whatever the repo actually uses — check `package.json` scripts before assuming. In these repos that is usually `pnpm typecheck` and `pnpm test`. If the repo has no test script, say so rather than inventing one.

### Step 5 — Report

```
Deslopped — <N> edits across <M> files

- path:line — what went, and why it was slop
- path:line — ...

Verified: pnpm typecheck ✓  pnpm test ✓ (or: no test script in this repo)
```

If nothing qualifies, say `No slop found on this branch.` and stop. Do not manufacture findings.

## Skill mode

Point the same instinct at a `SKILL.md`. Run it before committing a new or edited skill. Flag:

| Failing | What it looks like |
|---|---|
| Stale line | Guidance describing an older version of the skill |
| Bloat | Runs past one screen on detail that belongs in a linked reference |
| Dead sentence | Delete it and nothing changes |
| Duplication | The same instruction in two places, so edits drift |
| Premature stop | The method ends before the work does — asks but never records, cleans but never verifies |
| Weak anchor | No single idea the skill turns on; the reader cannot name it in one word |
| Undeclared invocation | Neither clearly human-run (`disable-model-invocation: true`) nor written to auto-fire on a precise description |
| Vague write op | Changes state without saying whether it adds, updates or appends — so a second run duplicates |

Human-run skills in this repo set `disable-model-invocation: true` and are reached by typing `/dot-<name>`. Auto-firing skills omit it and carry a description precise enough to trigger on the right task and stay quiet otherwise. A skill that is side-effectful or a deliberate ritual is human-run; if you cannot say in one sentence when it should fire by itself, it is human-run.

Report the failings by line, the edits applied, and one line on whether the skill is ready to commit.
