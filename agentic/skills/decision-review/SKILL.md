---
name: decision-review
description: Stress-test a plan, design choice or idea through questioning before committing to it. Use for architecture or technology choices, plans with real trade-offs, ambiguous requirements, decisions that are costly to reverse, or when I ask you to challenge me or review a plan.
---

# Decision review

Interview the user to expose weak assumptions and resolve consequential decisions.

Scale depth to the cost of being wrong. Spend questions on the parts that are hard to reverse, not on cheap details. For a cheap, reversible choice, recommend and proceed unless the user objects.

- Start by restating the goal and decision in one or two lines. Verify accessible facts (code, docs, config, history) before asking. Ask only for preferences, decisions or facts you cannot retrieve. Separate verified facts from assumptions.
- Challenge weak reasoning directly, without hostility. Useful angles: pre-mortem (it failed in six months: why, how would we notice, how do we recover?), cost of reversal, evidence that would invalidate the plan.
- Weigh two baselines: keeping things as they are, and the simplest alternative meeting the same needs. Ask what you would choose if the favored option were unavailable.
- Judge a proposal on its merits, whatever its source (the user, a senior, a vendor, an AI, yourself). Keep a challenge standing under pushback until new evidence or arguments answer it. Concede explicitly when they do.
- Under time pressure, separate the reversible mitigation needed now from the irreversible decision, which can wait.
- Run these bias checks on your own recommendation too:
  - Subtraction: what could be removed instead of added?
  - Original problem: what was this pattern built to solve, and do we have that problem? Estimate its real cost (volume, growth, load) as a low-high range.
  - Independence: do agreeing opinions come from independent sources? Reviewers or subagents on the same model and brief echo one framing. Give one a contrary brief.
- Ask rounds of at most four independent questions, highest impact first. Defer questions whose prerequisites, including pending fact-finding, are unsettled.
- Use the structured question tool when available (`AskUserQuestion` in Claude Code, `questionnaire` in Pi), otherwise use numbered questions.
- When justified, offer options and a recommendation, with the key trade-off in one line. Allow alternatives. Avoid premature recommendations in open-ended discovery.
- After each round, update your understanding and probe the remaining gaps. Do not reopen settled questions without new evidence.

Stop when every consequential decision is resolved or explicitly left open, or when the user asks.

Summarize decisions (choice, reason, rejected alternative), unverified assumptions, open issues and next step. Then ask whether it is accurate, unless the user ended the review.

The review does not authorize implementation beyond the scope of the user's request, and does not require new approval within it.
