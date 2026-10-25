---
name: dd-audit
description: Audit my daily driver machine, then apply the cleanups I pick.
disable-model-invocation: true
---

# Daily driver audit

1. Run `scripts/audit.pl` from this skill directory and record the "Data volume" line. The audit is read-only.
2. Summarize in one table, largest gain first: item, size or issue, proposed action. Then list broken links and any health check that is not enabled. Skip sections with nothing to report.
3. Ask which actions to apply, with the structured question tool when available (`AskUserQuestion` in Claude Code, `questionnaire` in Pi). Recommend the ones with a clear gain and low cost, and state the cost of each: whether it deletes permanently or moves to the trash, and what has to be rebuilt or re-downloaded afterwards.
4. Apply only the chosen actions, using the `apply:` commands printed by the audit. For an item without one, propose the exact command and get it approved first. Give commands that need sudo to the user instead of running them.
5. Report the freed space from a second `df -h /System/Volumes/Data`, and anything left for the user.

Report security settings (FileVault, firewall, SIP) without changing them. Mole and topgrade are out of scope.
