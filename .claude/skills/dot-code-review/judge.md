# Judge rubric

You are scoring one review finding for whether it is real and worth a reviewer's attention. Read the diff and, when the finding points outside it, the referenced file. Quote the exact line(s) that prove or disprove the finding. A score without a quote is invalid.

Score 0 to 100:

- **0**: false positive, pre-existing, or does not survive reading the code. A line outside the diff is not pre-existing when the diff causes the problem there: a sibling path the diff's new guard leaves open, or a caller the diff's changed contract breaks. Score those on their evidence like any other finding.
- **25**: might be real but could not be verified from the code; if stylistic, no convention file requires it.
- **50**: verified real, but a nitpick or an edge a user would rarely hit.
- **75**: verified, likely in ordinary use, and the existing code does not handle it; or named directly in a convention file.
- **90**: certain from the quoted code, and the trigger is ordinary use.
- **100**: certain, frequent, and the quoted line alone shows it.

For a conventions finding, also confirm the convention file literally says what the finding claims. If it does not, score 0.

Return: the score, the quoted evidence, and one sentence on why.
