#!/usr/bin/env bun
// Read-only report of Pi's cost, model requests, tools and tool failures.
// Data comes from my pi-otlp extension (https://github.com/thomas-fazzari/pi-otlp), which sends Pi's telemetry to a local Grafana.
import { Glob } from "bun";
import { existsSync, readFileSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { parseArgs } from "node:util";

type Format = "count" | "usd" | "ratio" | "seconds";
type Sample = [labels: Record<string, string>, value: number];
type Result = { metric: Record<string, string>; value: [number, string] };
type Reply = { data: { result: Result[] } };
type Part = { type: string; id: string; text: string; arguments: unknown };
type Call = { toolName: string; toolCallId: string; isError?: boolean };
type Message = Call & { role: string; content: Part[] };
type Entry = { type?: string; cwd?: string; timestamp: string; message?: Message };
type Group = { tool: string; count: number; files: Set<string>; arguments: unknown; file: string };

const grafana = process.env.GRAFANA_URL ?? "http://127.0.0.1:3000";
const logbookPath = `${import.meta.dir}/../logbook.md`;
const home = homedir();
const sessions = `${home}/.pi/agent/sessions`;

// Prometheus keeps a year of samples (see LGTM_RETENTION, pi-otlp), Loki refuses a range > 30 days
const allDays = 365;
const lokiDays = 30;
const day = 86_400;

const { values: options } = parseArgs({
  options: {
    since: { type: "string" },
    all: { type: "boolean" },
    "mark-run": { type: "boolean" },
    top: { type: "string", default: "12" },
  },
});
const logbook = existsSync(logbookPath) ? readFileSync(logbookPath, "utf8") : "";
const now = Math.floor(Date.now() / 1000);
const iso = (epoch: number) => new Date(epoch * 1000).toISOString().replace(/\.\d+Z$/u, "Z");

const parseTime = (text: string): number => Date.parse(text) / 1000;

if (options["mark-run"]) {
  const text = logbook || "# pi-self-improve logbook\n\nLast run:\n\n## Changes\n";
  await Bun.write(logbookPath, text.replace(/^Last run:.*$/mu, `Last run: ${iso(now)}`));
  console.log(`Last run: ${iso(now)}`);
  process.exit(0);
}

const last = /^Last run: (\S+)$/mu.exec(logbook)?.[1];
const since = options.since ?? (options.all ? undefined : last);
const start = since ? parseTime(since) : now - allDays * day;
const origin = options.since ? "--since" : since ? "the last run" : "all data";
const span = now - start;

const values = new Map<string, [number | undefined, Format]>();

function isReply(body: unknown): body is Reply {
  return typeof body === "object" && body !== null && "data" in body;
}

async function query(datasource: string, path: string, expr: string): Promise<Sample[]> {
  const params = new URLSearchParams({ query: expr, time: String(now) });
  const url = `${grafana}/api/datasources/proxy/uid/${datasource}${path}?${params}`;
  const res = await fetch(url, { signal: AbortSignal.timeout(30_000) });
  const body: unknown = await res.json();
  if (!res.ok || !isReply(body)) {
    throw new Error(`${datasource} answered ${res.status}: ${JSON.stringify(body)}`);
  }
  return body.data.result.map(({ metric, value }) => [metric, Number(value[1])]);
}

const sum = (samples: Sample[]): number => samples.reduce((total, [, value]) => total + value, 0);
const prom = (expr: string): Promise<Sample[]> => query("prometheus", "/api/v1/query", expr);
const total = async (expr: string): Promise<number> => sum(await prom(expr));

// The exact increase of every series over the window: each Pi process starts its series at zero, so the value
// before the window, or the first value inside it for a new series, is the baseline. No extrapolation.
function increase(selector: string, by?: string): string {
  const w = `${span}s`;
  const inner = `last_over_time(${selector}[${w}]) - (last_over_time(${selector}[${w}] offset ${w}) or min_over_time(${selector}[${w}]))`;
  return by ? `sum by (${by}) (${inner})` : `sum(${inner})`;
}

// Series without the label, such as compaction cost without a model, count under "none"
async function byLabel(expr: string, ...labels: string[]): Promise<Map<string, number>> {
  const sums = new Map<string, number>();
  for (const [metric, value] of await prom(expr)) {
    const key = labels.flatMap((label) => metric[label] ?? []).join(".") || "none";
    sums.set(key, (sums.get(key) ?? 0) + value);
  }
  return sums;
}

const increaseBy = (selector: string, ...labels: string[]): Promise<Map<string, number>> =>
  byLabel(increase(selector, labels.join(", ")), ...labels);

const sortedDesc = (sums: Map<string, number>): [string, number][] =>
  [...sums].toSorted(([a, x], [b, y]) => y - x || (a < b ? -1 : 1));

// histogram_quantile returns NaN for a histogram without samples
function format(value: number | undefined, kind: Format = "count"): string {
  if (value === undefined || Number.isNaN(value)) {
    return "n/a";
  }
  const usd = `$${value.toFixed(2)}`;
  const seconds = `${value.toFixed(1)}s`;
  return { usd, ratio: `${(100 * value).toFixed(1)}%`, seconds, count: value.toFixed(0) }[kind];
}

// A negative width pads on the right, like printf's %-Ns
function table(widths: number[], cells: string[]): string {
  const padded = cells.map((cell, i) => {
    const width = widths[i] ?? 0;
    return width < 0 ? cell.padEnd(-width) : cell.padStart(width);
  });
  return `  ${padded.join(" ")}`;
}

function put(key: string, value: number | undefined, kind: Format = "count"): void {
  values.set(key, [value, kind]);
  console.log(table([-46], [key, format(value, kind)]));
}

function putAll(prefix: string, sums: Map<string, number>, kind: Format = "count"): void {
  for (const [key, value] of sortedDesc(sums)) {
    put(`${prefix}.${key}`, value, kind);
  }
}

async function reportCost(): Promise<void> {
  console.log("\n## Cost and tokens");
  const cost = 'pi_cost_USD_total{service_name="pi"}';
  put("cost.total", await total(increase(cost)), "usd");
  putAll("cost.model", await increaseBy(cost, "gen_ai_request_model"), "usd");
  putAll("cost.request_kind", await increaseBy(cost, "pi_request_kind"), "usd");
  // Main sessions have no agent name
  putAll("cost.session", await increaseBy(cost, "pi_session_kind", "gen_ai_agent_name"), "usd");

  const tokens = await increaseBy('pi_token_usage_total{service_name="pi"}', "gen_ai_token_type");
  putAll("tokens", tokens);
  const types = ["input", "cache_read", "cache_write", "cache_write_1h"];
  const input = types.reduce((n, type) => n + (tokens.get(type) ?? 0), 0);
  put("cache.hit_ratio", input ? (tokens.get("cache_read") ?? 0) / input : undefined, "ratio");
}

async function reportRequests(): Promise<void> {
  console.log("\n## Model requests");
  const count = 'gen_ai_client_operation_duration_seconds_count{service_name="pi"';
  const requests = await increaseBy(`${count}}`, "gen_ai_request_model");
  const failed = await increaseBy(`${count}, error_type="error"}`, "gen_ai_request_model");
  for (const [model, n] of sortedDesc(requests)) {
    put(`requests.${model}`, n);
    put(`requests.failed.${model}`, failed.get(model) ?? 0);
    const bucket = `gen_ai_client_operation_duration_seconds_bucket{service_name="pi", gen_ai_request_model="${model}"}`;
    for (const q of [0.5, 0.9]) {
      const p = await total(`histogram_quantile(${q}, ${increase(bucket, "le")})`);
      put(`latency.p${q * 100}.${model}`, p, "seconds");
    }
  }
  put("requests.aborted", await total(increase(`${count}, pi_stop_reason="aborted"}`)));
}

async function reportTools(): Promise<void> {
  console.log("\n## Tools");
  console.log("  Keys: tools.<tool>.<column>. error_rate counts both tool_error and not_run.");
  const tool = "gen_ai_tool_name";
  const calls = await increaseBy('pi_tool_calls_total{service_name="pi"}', tool);
  const failing = 'pi_tool_calls_total{service_name="pi", error_type!=""}';
  const failed = await increaseBy(failing, tool);
  const errors = await increaseBy(failing, tool, "error_type");
  const buckets = increase('pi_tool_duration_seconds_bucket{service_name="pi"}', `le, ${tool}`);
  const p90 = await byLabel(`histogram_quantile(0.9, ${buckets})`, tool);
  const widths = [-24, 7, 10, 8, 10, 8];
  console.log(table(widths, ["tool", "calls", "tool_error", "not_run", "error_rate", "p90"]));
  const failures = (name: string): number => failed.get(name) ?? 0;
  const used = [...calls].filter(([, n]) => n);
  for (const [name, n] of used.toSorted(([a, x], [b, y]) => failures(b) - failures(a) || y - x)) {
    const columns: [string, number | undefined, Format][] = [
      ["calls", n, "count"],
      ["tool_error", errors.get(`${name}.tool_error`) ?? 0, "count"],
      ["not_run", errors.get(`${name}.not_run`) ?? 0, "count"],
      ["error_rate", failures(name) / n, "ratio"],
      ["p90", p90.get(name), "seconds"],
    ];
    for (const [column, value, kind] of columns) {
      values.set(`tools.${name}.${column}`, [value, kind]);
    }
    console.log(table(widths, [name, ...columns.map(([, value, kind]) => format(value, kind))]));
  }
}

async function reportEvents(): Promise<void> {
  console.log("\n## Events");
  const range = span > lokiDays * day ? `${lokiDays}d` : `${span}s`;
  if (span > lokiDays * day) {
    console.log(`  Loki counts only the last ${lokiDays} days.`);
  }
  const bodies = {
    "events.compaction": "Context compacted",
    "events.compaction_failed": "Context compaction failed",
    "events.model_select": "Model selected",
    "events.request_failed": "Model request failed",
    "events.sessions": "Session started",
  };
  for (const [key, body] of Object.entries(bodies)) {
    const expr = `sum(count_over_time({service_name="pi"} |= "${body}" [${range}]))`;
    put(key, sum(await query("loki", "/loki/api/v1/query", expr)));
  }
}

// Groups failures that differ only by numbers or file names
const signature = (text: string): string =>
  (text.split("\n")[0] ?? "")
    .replaceAll(/\s+/gu, " ")
    .replaceAll(/[\w./~-]+\.\w{1,6}\b/gu, "<file>")
    .replaceAll(/\d+/gu, "N")
    .slice(0, 140);

function isEntry(value: unknown): value is Entry {
  return typeof value === "object" && value !== null;
}

function entries(file: string): Entry[] {
  return readFileSync(file, "utf8")
    .split("\n")
    .flatMap((line) => {
      try {
        const entry: unknown = JSON.parse(line);
        return isEntry(entry) ? [entry] : [];
      } catch {
        return []; // The last line of an active session can be half written
      }
    });
}

// Test runs of Pi, such as pi-otlp's e2e, work in temporary directories
const temporary = /^\/(?:private\/)?(?:var\/folders|tmp)\//u;
// Exit 1 with no output is a search with no match, such as git grep, not a failure
const noMatch = /^\s*\(no output\)\s*Command exited with code 1\s*$/u;

function collectFailures(file: string, groups: Map<string, Group>): void {
  const calls = new Map<string, unknown>();
  for (const { type, cwd = "", timestamp, message } of entries(file)) {
    if (type === "session" && temporary.test(cwd)) {
      return;
    }
    if (message?.role === "assistant") {
      for (const part of message.content.filter((p) => p.type === "toolCall")) {
        calls.set(part.id, part.arguments);
      }
      continue;
    }
    if (message?.role !== "toolResult" || !message.isError || parseTime(timestamp) < start) {
      continue;
    }
    const text = message.content.flatMap((p) => (p.type === "text" ? p.text : [])).join(" ");
    if (message.toolName === "bash" && noMatch.test(text)) {
      continue;
    }
    const { toolName: tool, toolCallId } = message;
    const key = `${tool}\t${signature(text)}`;
    const example = { tool, arguments: calls.get(toolCallId), file };
    const group = groups.get(key) ?? { count: 0, files: new Set<string>(), ...example };
    groups.set(key, group);
    group.count++;
    group.files.add(file);
  }
}

// Sorted keys, so equal arguments print identically
const canonical = (_key: string, value: unknown): unknown =>
  typeof value === "object" && value !== null && !Array.isArray(value)
    ? Object.fromEntries(Object.entries(value).toSorted(([a], [b]) => (a < b ? -1 : 1)))
    : value;

function reportFailures(): void {
  console.log("\n## Tool failures in the sessions");
  const groups = new Map<string, Group>();
  const files = [...new Glob("*/*.jsonl").scanSync({ cwd: sessions, absolute: true })]
    .filter((file) => statSync(file).mtimeMs / 1000 >= start)
    .toSorted();
  for (const file of files) {
    collectFailures(file, groups);
  }
  const sorted = [...groups].toSorted(([, a], [, b]) => b.count - a.count);
  const failures = sorted.reduce((n, [, group]) => n + group.count, 0);
  const counts = `${failures} failed tool calls in ${groups.size} groups`;
  console.log(`  ${counts}, from ${files.length} session files.`);
  // Calls to a tool that does not exist, such as powershell, reach the sessions but not the metrics
  const byTool = new Map<string, number>();
  for (const [, { tool, count }] of sorted) {
    byTool.set(tool, (byTool.get(tool) ?? 0) + count);
  }
  putAll("failures", byTool);
  for (const [key, group] of sorted.slice(0, Number(options.top))) {
    const [tool, sig] = key.split("\t");
    const json = JSON.stringify(group.arguments ?? null, canonical);
    const example = json.length > 160 ? `${json.slice(0, 157)}...` : json;
    console.log(`\n  ${group.count}x ${tool}, in ${group.files.size} sessions: ${sig}`);
    console.log(`     example: ${example}\n     session: ${group.file.replace(home, "~")}`);
  }
}

function reportTracked(): void {
  const changes = [...logbook.matchAll(/^- (\S+) \| (\S+) \| before: (\S+) \| (.+)$/gmu)];
  if (changes.length === 0) {
    return;
  }
  console.log("\n## Tracked changes");
  const widths = [-10, -40, 10, 10];
  console.log(`${table(widths, ["date", "key", "before", "now"])}  change`);
  for (const [, date = "", key = "", before = "", change = ""] of changes) {
    // A tool without failures in the window has no failures key
    if (key.startsWith("failures.") && !values.has(key)) {
      values.set(key, [0, "count"]);
    }
    const value = values.get(key);
    const current = value ? format(...value) : "no data";
    console.log(`${table(widths, [date, key, before, current])}  ${change}`);
  }
}

console.log("\n## Window");
const [days, hours] = [Math.floor(span / day), Math.floor((span % day) / 3600)];
console.log(`  ${iso(start)} to ${iso(now)} (${days}d ${hours}h, from ${origin})`);
await reportCost();
await reportRequests();
await reportTools();
await reportEvents();
reportFailures();
reportTracked();
