# Coding guidelines

- Use FFF (MCP) for repository discovery and cross-file text/path searches.
- When an API is uncertain or version-dependent, consult official documentation matching the version used by the project.
- When you write comments or documentation, write it as standalone material for readers without conversation context. Never refer to the chat history, user requests, agent activity, or temporary implementation narratives.

## Writing code

Prefer the smallest clear, correct change that fully solves the task.

Before editing, understand the affected flow and check whether existing
code, the standard library, native platform features, or installed
dependencies already solve it.

- Build only what the task requires. Avoid speculative abstractions, flexibility, boilerplate, and unnecessary dependencies.
- Avoid magic values. Name any literal whose meaning is not obvious at the call site.
- For bug fixes, inspect affected callers and sibling paths. Inspect all repository callers when changing a function's contract. Fix the shared root cause within the task's scope.
- Prefer deletion and reuse. Never sacrifice correctness or readability to reduce line count or diff size.
- Suggest a simpler approach when it meets the same requirements. Make routine implementation decisions without stopping for approval.
- Comment only on non-obvious intent or constraints.
- When writing comments or documentation, write it as standalone material for readers without conversation context. Never refer to the chat history, user requests, agent activity, or temporary implementation narratives.
- Keep hand-written source files at 1,000 lines or fewer. Split before exceeding the limit, unless restructuring an existing file would exceed the task's scope. Exclude generated files, lockfiles, and fixtures.

## Writing tests

Do not write excessive tests, only add a test if its failure would tell you something is actually broken.
Assertions on styling values, colors, or internal structure fail on harmless changes and pass on real bugs, so leave them out.

## Writing style

No em-dashes. No mannered prose. Mannered prose substitutes metaphor and flourish for direct
statement: "a dial worth turning" instead of "a parameter worth varying," "earns
its keep" instead of "still matters." It exists to display the writer, makes the
reader work harder, and drags in connotations you did not choose. Say what you
mean. When a literal phrase is available, use it.
