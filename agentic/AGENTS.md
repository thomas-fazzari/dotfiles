# AGENTS.md

## Caveman Mode (always on)

EVERY response: apply 'caveman' skill. No exception. Terse, primitive language — code stays professional.
Off only if I say "stop caveman" or "normal mode".

## Clarify First

For any non-trivial feature, refactor, or architectural decision:
**STOP. Do not touch code. Run 'grill-me' skill first.**
Surface blind spots → confirm approach → then implement.

Trivial = single-file edits, renaming, copy changes, config tweaks. Skip for those.

## CLI Tools

| Task                | Tool          |
| ------------------- | ------------- |
| Code search         | `rg`          |
| File discovery      | `fd`          |
| Fuzzy filter        | `fzf`         |
| String replace      | `sd`          |
| Read files          | `bat`         |
| JSON                | `jq`          |
| YAML/TOML           | `yq`          |
| Structural refactor | `ast-grep`    |
| Diff review         | `difftastic`  |
| LOC count           | `tokei`       |
| Task runner         | `just`        |
| Git                 | `gh`, `delta` |

## Context7 MCP

Use for any question about a library, framework, SDK, API, CLI tool, or cloud service — even well-known ones. Covers: API syntax, config, version migration, setup, debugging. Prefer over web search for docs.

Skip for: refactoring, greenfield scripts, business logic, code review, general concepts.

### Steps

1. `resolve-library-id` with library name + user question (skip if user gives `/org/project` ID).
2. Pick best match: exact name > description relevance > snippet count > source reputation > benchmark score. Try alternate names/queries if results look off.
3. `query-docs` with selected ID and full user question.
4. If `resolve-library-id` or `query-docs` fails → fall back to web search and flag it.
5. Answer from fetched docs.
