---
paths:
  - "**/docs/**/*.md"
  - "**/README.md"
  - "**/CHANGELOG.md"
---

# Writing documentation

Reading time is the cost. A document earns its length only by saving the reader more time than it takes.

- Follow the repository's own standard first (`docs/standards/`, `docs/README.md`, templates beside the docs). These rules fill the gaps.
- Write for one reader with one job. Name the job in the first line: "How to …", "Why we …", "What X does". If a page serves two jobs, it is two pages. This is the Diátaxis split: tutorial, how-to, reference, explanation. Never mix a how-to with its explanation.
- A README answers four things in order, each in a sentence or a command: what this is, how to run it, how to test it, where the rest of the docs are. Nothing else lives there.
- Do not write what the code already says. Document decisions, constraints, and the why. A decision with alternatives gets an ADR: context, decision, consequences, one page.
- Lead with the answer. Short sentences, active voice, second person for instructions, one idea per paragraph. Commands and paths in code spans, exactly as typed.
- Every claim must be true today. Delete a stale paragraph rather than leave it; a wrong document costs more than none. Planned work is labelled "Not yet built".
- Docs change in the same pull request as the code they describe, and a reviewer checks them as code.
- Link by relative path, one hop from the page that cites it. No orphan pages: a new page is linked from the index in the same change.
