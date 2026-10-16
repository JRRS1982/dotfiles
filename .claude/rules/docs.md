---
paths:
  - "**/docs/**/*.md"
  - "**/README.md"
---

# Writing documentation

- First look for the repository's own standard: `docs/standards/`, a `docs/README.md` index, or templates beside the docs. Follow it over anything below.
- Without one, use this layout: `docs/README.md` as the index, then `Features/` (PascalCase file names), `Architecture/`, `Guides/` (kebab-case), and `References/`.
- Every document opens with a short summary block: what it covers, who it is for, and when it was last verified against the code.
- Add a new document to the index in the same change. A document the index does not list does not exist.
- Describe behaviour as it is, not as it is planned. Planned work goes in a clearly labelled "Known gaps" section.
- Link to code by relative path and keep the links one hop from the document that cites them.
