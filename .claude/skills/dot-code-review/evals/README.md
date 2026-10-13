# Evaluations for dot-code-review

An evaluation is a real diff, the exact way to reproduce it, and the behaviour the skill must show on it. Run one after every edit to this skill and compare. The skill is not "done" when the prose reads well; it is done when these pass.

| File | Diff | What it checks |
|---|---|---|
| `halcyon-pr-208.md` | 66-file auth hardening PR, public repo | Both conditional lenses fire; two Blocking findings survive; a Blocking finding that depends on an unreachable branch does not |
| `docs-only-branch.md` | Any branch whose diff is only Markdown | No conditional lens fires; the no-findings block is emitted |
| `halcyon-pr-227.md` | Row ceilings added to some writers and not others | `completeness` fires and names all three unguarded paths, each outside the diff |

Add a file here whenever a run surprises you, in either direction: a real bug the skill missed, or a finding it should have dropped. Record what the skill did, not what you wish it did.
