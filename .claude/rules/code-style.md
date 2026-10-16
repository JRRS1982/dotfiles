---
paths:
  - "**/*.{ts,tsx,js,jsx,mjs,cjs,py,go,rs,rb,php,java,kt,swift,cs}"
---

# Code style

- Write simple, straightforward code that reads without comments. A name does the explaining; a comment explains only a why that the code cannot.
- Use early returns. Nested conditionals are a guard clause that has not been written yet.
- Where a function is complex, one JSDoc line above it states its purpose, arguments, and return value.
- Prefer pure functions. They are the easy ones to test.
- Define types where the language has them.

## Changing existing code

- Keep the change to the task. Do not add features nobody asked for, and do not clean up code the task did not touch unless asked.
- Do not change an existing comment unless the code it describes changes.
- When altering existing code, say what changed and why in the summary.

```typescript
// nested
if (user) { if (user.isActive) { if (user.hasPermission) return user.process(); } }
return null;

// early returns
if (!user) return null;
if (!user.isActive) return null;
if (!user.hasPermission) return null;
return user.process();
```
