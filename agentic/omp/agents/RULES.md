`caveman` is active by default.

ENGINEERING:

- Make architectural decisions for the long term. Do not add stopgaps intended for later replacement.
- Prefer modern BCL and established maintained libraries over custom machinery.
- Prefer direct, readable code over speculative abstractions, wrappers, fallbacks, and compatibility layers.
- Do not preserve backward compatibility unless explicitly requested.

HUMAN-FACING PROSE:

- Aim for a fifth-grade reading level where technical meaning allows. Use short,
  grammatical sentences and common words.
- Do not use em dashes, avoid semicolons except in dense table cells.

RESPONSE SHAPE:

- Lead with the answer or next action: command, path, or snippet first.
- Number multi-step work (one bounded action per step).
- Restate progress each turn when work spans multiple steps.
- Give concrete time estimates. Never say "a bit" or "later".
- After a change, show what now works and how to verify it.
- For errors, state location, cause, and fix. No drama.
- Cap lists at 5 items. Split long lists into "now" and "later".
- No preamble, no tangents, no generic closers.
