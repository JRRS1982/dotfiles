---
paths:
  - "**/*.test.ts"
  - "**/*.test.tsx"
  - "**/*.spec.ts"
  - "**/*.spec.tsx"
  - "**/*.integration.test.ts"
---

# Testing conventions

## Naming

- Test names state the outcome, not the mechanism: `"returns zero when no transactions exist"` not `"calls getTransactions"`.
- File name mirrors the subject: `actions.createPlan.test.ts` beside (or mirroring) `actions.ts`.

## What to mock — and what not to

- Mock at system boundaries only: auth sessions, email delivery, external HTTP. Never mock your own modules.
- Use real databases for integration tests. A mocked Prisma client proves nothing about the actual query.
- If a mock makes a test pass that the real thing would fail, the mock is lying — delete it.

## Structure

- One assertion per logical outcome. Multiple `expect` calls are fine inside one test when they assert the same thing from different angles.
- `beforeEach` resets shared state; `afterEach` cleans side effects. Never rely on test execution order.
- Avoid `any` casts in test assertions — they let the wrong shape slip through silently.

## The implementation-detail check

Before asserting on something, ask: would a user notice if this changed? Internal state, private method calls, and intermediate values are implementation details. Assert on outputs and observable side effects only.
