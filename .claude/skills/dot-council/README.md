# dot-council
Claude Code Multi-Model Deliberation Skill

## Installation

Provided via the dotfiles `.claude/skills/` symlink. After syncing the dotfiles,
the symlink makes this skill available as `/dot-council`.

## What it does

Puts one question to a panel of models in three phases:

1. **Independent** — each panel model answers the same brief, in parallel,
   without seeing the others
2. **Blind ranking** — each model ranks all the answers, shown as
   `Response A/B/C` with no names, including its own
3. **Synthesis** — a chairman model sees the real names *and* the rankings, and
   produces the final answer

Phase 2 is the point. Three models asked the same question gives you three
opinions; making them rank each other blind tells you which opinion survives
scrutiny. A model unknowingly ranking its own answer is the mechanism, not a
flaw.

## Why it exists

For decisions where one model's confident answer is not enough, and where being
wrong is expensive to undo — an architecture call, a contested review, a schema
you will live with for two years.

It runs on Claude Code's own subagents, so there is **no API key and no external
spend**. The trade-off is real and the skill states it in its own output: a
single-vendor panel has less viewpoint diversity than a cross-vendor one, so
consensus here is weaker evidence of correctness than it looks.

## When to call it

- Architecture decisions with no obvious right answer
- A review where you suspect the first answer was too confident
- A plan you want stress-tested before committing to it
- Any call where you would otherwise ask a colleague for a second opinion

Not for routine work. A panel of 3 costs 7 agent calls.

## Usage examples
```
/dot-council "Should Artemis own the submissions table, or should Chameleon?"
/dot-council "Review this migration plan" --panel opus,fable,sonnet,haiku
/dot-council "Is this RLS policy sound?" --chair fable --save
```

- `--panel` — default `opus,fable,sonnet`. Valid: `opus`, `fable`, `sonnet`, `haiku`
- `--chair` — default `opus`
- `--save` — also write the full transcript to `~/.claude/council/`

## Notes

- Claude will never auto-trigger this — it only runs when you type
  `/dot-council`. It is expensive and deliberate.
- Cost is `2N + 1` agent calls for a panel of N. It warns and waits for
  confirmation before running a panel larger than 4.
- The panel does not share the session's context, so the skill assembles a
  self-contained brief first — including the applicable `CLAUDE.md` rules, or the
  panel will happily propose things that violate them.
- All three phases are shown. The disagreement is the value, so nothing is
  elided down to just the answer.
- Transcripts go to `~/.claude/council/`, never into the working repo.
