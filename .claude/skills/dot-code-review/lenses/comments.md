# Lens: comments

Question: does the change respect what the surrounding comments say, and are the comments it touches still true?

Read the comments in each modified file, not only the hunks. Flag:

- code that now contradicts a comment, docblock, or TODO beside it
- a comment this diff makes stale, describing behaviour that no longer exists
- a new comment that says what the code does when the non-obvious why is missing
- commented-out code added by the diff

Do not flag comment style, or missing comments on self-evident code.
