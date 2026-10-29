---
name: pi-self-improve
description: Review my Pi telemetry and sessions since the last run, then apply the improvements I pick.
disable-model-invocation: true
---

1. Run `scripts/report.pl` from this skill directory. It reads local Grafana and Pi sessions recorded by my [pi-otlp](https://github.com/thomas-fazzari/pi-otlp) extension, and changes nothing. It reads `logbook.md` itself and covers the time since the last run recorded there, or all data when there is none, so do not open the logbook before step 6. Pass `--since YYYY-MM-DD` or `--all` when I ask for another period. If Grafana does not answer, tell me to run `lgtm` and stop.
2. Find the cause of each finding before proposing anything:
   - Open the session files that the failure groups name, and read the turns around the failed calls.
   - For a cost, latency or trace question the report does not answer, use the `grafana` MCP tools: `query_prometheus` for another breakdown, `search_tempo_traces` and `get_tempo_trace` for slow or expensive runs, `query_loki_logs` for session and compaction events. A Tempo search covers at most 7 days, and Tempo keeps traces for 14 days.
3. Summarize in one table, largest expected gain first: finding, evidence (report key, value and one example), proposed change (file and exact edit), and the report key it should move. Start with the tracked changes the report lists, and say whether each one helped. Leave out a finding whose cause the sessions do not show.
4. Ask which changes to apply, with the structured question tool (`questionnaire` in Pi, `AskUserQuestion` in Claude Code).
5. Apply only the chosen changes and show the diff. Never commit.
6. For each applied change, add a line under `## Changes` in `logbook.md`, with the read and edit tools: `- YYYY-MM-DD | report key | before: value | change`. Then run `scripts/report.pl --mark-run`, even when nothing was applied.

You may change:

- Pi's instructions, agents and settings: `APPEND_SYSTEM.md`, `agents/*.md` and `settings.json` in `~/.pi/agent`.
- Other skills.
- Hooks (e.g. my bash guards) in `~/.local/share/agent-hooks`, with a test for each change when applicable.

For a gap in the telemetry itself, propose a change to pi-otlp without making it. For a bug in a third-party extension, work around it in my configuration and do not propose reporting it upstream.
