# Lens: history

Question: does this diff conflict with how the code got here?

For each modified region, run `git blame` or `git log -L` on the pre-change lines and read the commits that shaped them: messages, and diffs where short. Flag:

- reintroducing a bug a past commit fixed, where the fix's message or test names it
- breaking an invariant a past commit established on purpose, per its comment, message, or test
- removing a guard that was added for an incident or bug ticket
- undoing a recent change by another author without the diff acknowledging it

Quote the commit hash and the line in `why flagged`. Do not flag history that merely differs in style.
