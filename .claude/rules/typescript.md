---
paths:
  - "**/*.{ts,tsx}"
---

# TypeScript

The linter and `tsc --noEmit` in strict mode catch the basics. These are the rules they do not.

- Let inference work. Annotate exported signatures and module boundaries; do not annotate a local whose type is obvious from the right-hand side.
- `unknown`, never `any`, for a value of unknown shape: caught errors, parsed JSON, external data. Narrow before use.
- No `as` casts except `as const`. To check a value against a type without widening, use `satisfies`. To narrow at runtime, use a type predicate or a discriminated union. In test files, a cast to a mock type is the accepted exception when the repository already uses it.
- Derive types; never duplicate them. From zod: `z.infer` or `z.input`. From Prisma: the generated model types and `Prisma.*GetPayload`. From other types: `Pick`, `Omit`, `Partial`, `ReturnType`.
- No `enum`. Use an `as const` array or object and derive the type from it.
- Model mutually exclusive states as a discriminated union, not optional fields. Switch on the discriminant and add a `never` check for exhaustiveness.
- `import type` for type-only imports. Prefer `type` aliases; use `interface` only for declaration merging.
- Types are compile-time only. Validate external data with zod at the boundary, then trust the inferred type inside.
- Check `noUncheckedIndexedAccess` in the tsconfig. When it is off, `array[i]` and `record[key]` are typed as present; guard index access where the index is not provably valid.

```typescript
const palette = { income: "#2e7d32", expense: "#c62828" } satisfies Record<string, string>; // checked, not widened

const KINDS = ["INCOME", "EXPENSE"] as const;
type Kind = (typeof KINDS)[number]; // instead of enum

type ImportState =
  | { status: "idle" }
  | { status: "ready"; preview: Preview }
  | { status: "failed"; error: string }; // each state explicit
```
