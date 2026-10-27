---
paths:
  - "**/*.test.ts"
  - "**/*.test.tsx"
  - "**/*.spec.ts"
  - "**/*.spec.tsx"
  - "**/*.integration.test.ts"
---

# Testing

Tests exist to stop a user-visible failure from shipping. Every rule below serves that; when one doesn't, the user-visible failure wins.

## Deciding what to test

- Before writing a test, finish the sentence "if this is wrong, a user can …". If you can't, don't write it yet — ask.
- Test at the cheapest layer that can see the failure: pure logic in unit tests, code that crosses a real boundary (database, queue) in integration tests, whole journeys end-to-end. Don't repeat at a higher layer a check a lower one already makes.
- Coverage is a map of what is untested, not a target. Use it to find untested decisions; never write a test only to move the number.

## What to assert

- Assert outcomes a user or caller could observe: return values, stored state, messages, emitted output. Never private calls or intermediate values.
- One behaviour per test. Several `expect` calls are fine when they check the same behaviour from different angles.
- Name the outcome, not the mechanism: `"refuses a breached password"`, not `"calls checkBreach"`. The file name mirrors its subject.

## Test doubles

- Replace only what you don't own: external services, the network, the clock, the framework's request context, environment config.
- Never replace your own modules. When your code wraps a third-party client (a Redis or HTTP adapter), replace that thin wrapper, so your logic on top still runs.
- Code across a network call counts as a boundary even when it lives in the same repo.
- A logger counts as a boundary: a log line is output the app emits, like an email, so asserting one was written checks a result, not an internal.
- For a stateful service, prefer a small in-memory fake shared from a test support folder over scripted return values per test.
- Use the real database for integration tests. A mocked query layer proves nothing about the query.
- If a double lets a test pass that the real thing would fail, the double is lying: fix it or delete it.

## Determinism

- A test passes on a clean machine: no local env file, no services it doesn't start itself, no dependence on today's date, time zone or locale.
- Control time and randomness explicitly; never let them leak in.
- Each test sets up its own state and resets doubles fully — implementations, not just call history. Never rely on test order.
- No retries. A test that fails once is either a real bug or a broken test; find out which.

## Trusting a test

- Watch every new test fail before you trust it. For a test guarding a rule (a limit, a permission, a value carried through), break the rule in the code once and confirm the test goes red.
- A skipped test carries a reason and an owner, or it is deleted.

## The paths people skip

- For every refusal, assert both the answer and that the side effect did not happen: no email sent, nothing written, no token spent.
- Test the edges the code branches on: empty, boundary values, too long, the wrong shape from an untrusted caller.
- Where the code fails open or closed on purpose, test that choice directly.

## Reading and keeping tests

- A test is documentation: someone should learn the rule from its name and a one-line comment on why it matters.
- Avoid `any` casts in assertions — they let the wrong shape slip through silently.
- Delete tests that break on every refactor without catching bugs; they test internals.
