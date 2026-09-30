# Code navigation

C# -> use the roslyn MCP: `navigate` (prefer `symbol` names), `symbols`, `diagnostics`, and `edit` for renames and code actions.
Rust and TypeScript -> use LSP.
File locations, text search for literals, comments, or configuration -> use fff.

If LSP or roslyn MCP fails, use regular searches as a fallback and report the failure.

## Core principles

- Check whether existing code, the standard library, native platform features, or installed dependencies already solve the problem.
- Build only what the task requires. Avoid speculative abstractions, configurability, boilerplate, and unrelated cleanup.
- Prefer deletion and reuse over new code. Add dependencies only when existing options do not adequately meet the requirements.
- Name literals whose meaning is unclear at the call site. Leave self-explanatory literals inline.
- For bug fixes, inspect affected callers and sibling paths. Fix the shared root cause within the task's scope rather than patching individual symptoms.
- When changing a function's contract, inspect all repository callers and update affected ones.
- Suggest a simpler approach when it meets the same requirements. Make routine implementation decisions without stopping for approval.
- Keep hand-written source files at 1,000 lines or fewer. Split before exceeding the limit, unless restructuring an existing file would exceed the task's scope. Generated files, lockfiles, and fixtures are exempt.

### Writing tests

Test meaningful behavior, not implementation details.

- Add or modify a test only when its failure would identify a real bug, broken requirement, or violated contract.
- Prefer a small number of focused tests covering distinct, relevant failure modes. Reuse existing coverage instead of duplicating it.
- Do not assert incidental styling values, colors, private state, or internal structure. Assertions should survive harmless refactoring and fail when required behavior breaks.
- For bug fixes, prefer a focused regression test that fails before the fix and passes after it, when practical.
- Run relevant tests and checks when possible. Report what actually ran and any verification gaps. Never imply that unrun checks passed.

### Comments, documentation, and prose

- Use direct, literal language. No em-dashes or mannered prose.
- Prefer precise statements over metaphor, flourish, or clever phrasing. Write "a parameter worth varying," not "a dial worth turning"; "still matters," not "earns its keep."
- Comment only on non-obvious intent or constraints. Do not narrate what the code already makes clear.
- Write comments and documentation as standalone material for readers without conversation context. Never refer to chat history, user requests, agent activity, or temporary implementation narratives.
