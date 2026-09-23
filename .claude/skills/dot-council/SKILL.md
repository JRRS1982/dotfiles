---
name: dot-council
description: Put a high-stakes question to a panel of models — independent answers, blind peer ranking, then a chairman synthesis. Use when the user types /dot-council, for architecture decisions, contested reviews, or any call where one model's confident answer is not enough.
argument-hint: "\"<the question>\" [--panel opus,fable,sonnet] [--chair opus] [--save]"
disable-model-invocation: true
allowed-tools: Agent, Bash(mkdir *), Bash(git *), Read, Write
---

Karpathy's LLM Council pattern, run on native subagents — no API key, no external spend.

The point is **phase 2**. Asking three models the same question gives you three opinions; making them rank each other's answers blind tells you which opinion survives scrutiny. Never skip it.

Because every panel member is a Claude model, this council has less viewpoint diversity than a cross-vendor one. It still surfaces disagreement, unstated assumptions and missed constraints — but do not read consensus here as strong evidence of correctness. Say so in the output.

## Parse `$ARGUMENTS`

- The quoted string is the QUESTION. If absent, ask for it and stop.
- `--panel a,b,c` — panel models. Default `opus,fable,sonnet`. Valid: `opus`, `fable`, `sonnet`, `haiku`.
- `--chair m` — chairman model. Default `opus`.
- `--save` — also write the transcript to `~/.claude/council/<YYYY-MM-DD>-<slug>.md`.

Panel of 3 costs 7 agent calls (3 answers + 3 rankings + 1 chair). Each added member adds 2. Tell the user the call count before starting a panel larger than 4, and wait for them to confirm.

## Step 0 — Gather the brief

The panel does not share your context. Assemble a self-contained brief: the question, the relevant constraints, and the files or diff that bear on it. Use `git diff`, `git log` or reads as needed. If the question concerns this repo, include the applicable `CLAUDE.md` rules — a panel that does not know the house conventions will propose things that violate them.

Keep the brief identical for every member. Any difference between briefs invalidates the ranking.

## Step 1 — Independent answers

Dispatch one subagent per panel model **in a single message** so they run concurrently. Each gets the brief and:

> Answer the question below on its merits. Be concrete and decisive — give a recommendation, not a survey of options. State your reasoning, the assumptions you are making, and what would change your mind. If the brief is missing something you need, say what and answer under a stated assumption rather than refusing.

Collect the answers. Label them `A`, `B`, `C` … in dispatch order and record which model produced which letter. **Do not reveal that mapping until step 3.**

## Step 2 — Blind peer ranking

Dispatch one subagent per panel model again, in a single message. Each receives the brief and **all** answers as `Response A/B/C…` — no model names, including its own. Each returns:

> Rank these responses best to worst. For each, give one line on its strongest point and one on its weakest. Name any claim you believe is factually wrong. You are ranking reasoning quality, not writing style. One of these may be your own answer — you cannot tell which, so judge them all the same way.

A model ranking its own work unknowingly is the mechanism, not a flaw.

## Step 3 — Chairman synthesis

Dispatch one subagent on the chair model. It receives the brief, every answer **with its real model name**, and every ranking. It returns:

> Synthesise a final answer. Where the panel agreed, say so and carry it forward. Where it split, say which position is better supported and why — do not average them into mush. Name anything the panel got wrong or missed. End with a single clear recommendation.

## Step 4 — Output

Show all three phases. No elision — the disagreement is the value.

```
## Council — <question>
Panel: opus, fable, sonnet · Chair: opus · 7 agent calls

### Phase 1 — Independent answers
**A · opus** — <2-3 line gist>
**B · fable** — ...
**C · sonnet** — ...

### Phase 2 — Blind rankings
| Ranker | 1st | 2nd | 3rd | Called out |
|---|---|---|---|---|
| opus | B | A | C | C assumes Postgres 16 |
...
Consensus: B ranked first by 2 of 3.

### Phase 3 — Chairman synthesis
<the synthesis in full>

### Recommendation
<one paragraph>

Agreed: <what all three shared>
Split: <where they diverged, and which side held up>
Caveat: single-vendor panel — consensus is weak evidence of correctness.
```

With `--save`, `mkdir -p ~/.claude/council` and write the same block plus each answer and ranking in full. Say where it landed. Never write transcripts into the working repo.
