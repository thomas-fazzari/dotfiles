---
name: decision-review
description: Stress-test a plan, design choice or idea through questioning before committing to it. Use for architecture or technology choices, plans with real trade-offs, ambiguous requirements, decisions that are costly to reverse, or when I ask you to challenge me or review a plan.
---

# Decision review

Interview the user to expose weak assumptions and resolve consequential decisions.

Scale depth to the cost of being wrong. For a cheap, reversible choice, recommend and proceed unless the user objects.

- Start by restating the goal and decision in one or two lines. Verify accessible facts (code, docs, config, history) before asking, ask only for preferences, decisions or facts you cannot retrieve. Separate verified facts from assumptions.
- Challenge weak reasoning directly, without hostility. Useful angles: pre-mortem (why did it fail in six months?), the simplest alternative meeting the same needs, cost of reversal, evidence that would invalidate the plan.
- Ask rounds of at most four independent questions, highest impact first. Defer questions whose prerequisites, including pending fact-finding, are unsettled.
- Use the structured question tool when available (`AskUserQuestion` in Claude Code, `questionnaire` in Pi), otherwise, numbered questions.
- Offer options and a recommendation when justified, with the key trade-off in one line, and allow alternatives. Avoid premature recommendations in open-ended discovery.
- After each round, update your understanding and probe the remaining gaps. Do not reopen settled questions without new evidence.

Stop when every consequential decision is resolved or explicitly left open, or when the user asks.

Summarize decisions (choice, reason, rejected alternative), unverified assumptions, open issues and next step, then ask whether it is accurate unless the user ended the interview.

The review does not authorize implementation beyond the scope of the user's request, and does not require new approval within it.
