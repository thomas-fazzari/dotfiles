#!/usr/bin/env bun
// Read-only report of reclaimable disk space, broken dotfile links and system health
import { $, Glob, type ShellExpression } from "bun";
import { existsSync, readFileSync, realpathSync } from "node:fs";
import { homedir } from "node:os";
import { dirname } from "node:path";

const dotfiles = realpathSync(`${import.meta.dir}/../../../..`);
const home = homedir();
const dev = `${home}/Dev`;
const days = 15;

// Small caches are not worth a line
const minCacheKib = 100 * 1024;

// Output lines of a command, stderr included (mise reports on stderr)
async function run(strings: TemplateStringsArray, ...values: ShellExpression[]): Promise<string[]> {
  const { stdout, stderr } = await $(strings, ...values)
    .quiet()
    .nothrow();
  return (stdout.toString() + stderr.toString()).split("\n").filter(Boolean);
}

// Missing paths only add an error line, which parses as 0
async function kibOf(...paths: string[]): Promise<number> {
  return (await run`du -sk ${paths}`).reduce(
    (total, line) => total + (Number.parseInt(line, 10) || 0),
    0,
  );
}

function human(kib: number): string {
  const unit = Math.min(Math.max(Math.floor(Math.log2(kib) / 10), 0), 3);
  return `${(kib / 1024 ** unit).toFixed(1)}${"KMGT".charAt(unit)}`;
}

const tilde = (path: string): string => path.replace(home, "~");

function item(label: string, apply?: string, kib?: number): void {
  console.log(`  ${(kib === undefined ? "" : human(kib)).padStart(8)}  ${label}`);
  if (apply) {
    console.log(`            apply: ${apply}`);
  }
}

/** Reclaimable size per target directory, from a cargo sweep dry run */
async function sweepable(label: string, ...criteria: string[]): Promise<Map<string, string>> {
  const sizes = new Map<string, string>();
  for (const line of await run`cargo sweep --dry-run ${criteria} --recursive ${dev}`) {
    const [, size = "nothing", target = ""] = /Would clean: (.+?) from "(.+)"/u.exec(line) ?? [];
    if (size !== "nothing") {
      sizes.set(target, `${label}: ${size}`);
    }
  }
  return sizes;
}

async function rustArtifacts(): Promise<void> {
  console.log("\n## Rust build artifacts");
  const old = await sweepable("built by uninstalled toolchains", "--installed");
  const unused = await sweepable(`unused for ${days} days`, "--time", String(days));
  for (const line of await run`fd -u -t d -d 4 --prune ^target$ ${dev}`) {
    const target = line.replace(/\/$/u, "");
    if (!existsSync(`${target}/CACHEDIR.TAG`)) {
      continue;
    }
    item(tilde(target), undefined, await kibOf(target));
    for (const size of [old, unused].flatMap((sizes) => sizes.get(target) ?? [])) {
      item(size);
    }

    // cargo sweep leaves incremental caches alone
    // rustc only reuses the latest ones
    const find = ["-maxdepth", "1", "-mindepth", "1", "-type", "d", "-mtime", `+${days}`];
    const incremental = await run`find ${target}/*/incremental ${find}`;
    if (incremental.length > 0) {
      const apply = `find ${target}/*/incremental ${find.join(" ")} -exec rm -r {} +`;
      item(`incremental caches untouched for ${days} days`, apply, await kibOf(...incremental));
    }
  }
  if (old.size > 0) {
    item("Artifacts from uninstalled toolchains", "cargo sweep --installed --recursive ~/Dev");
  }
  if (unused.size > 0) {
    item(`Artifacts unused for ${days} days`, `cargo sweep --time ${days} --recursive ~/Dev`);
  }
}

async function rustToolchains(): Promise<void> {
  console.log("\n## Rust toolchains");
  const pinned = new Map<string, string[]>();
  for (const file of await run`fd -u -d 4 ${String.raw`^rust-toolchain(\.toml)?$`} ${dev}`) {
    const text = readFileSync(file, "utf8");
    const channel =
      /channel\s*=\s*"([^"]+)"/u.exec(text)?.[1] ?? /^\s*(\S+)/u.exec(text)?.[1] ?? "";
    pinned.set(channel, [...(pinned.get(channel) ?? []), tilde(dirname(file))]);
  }
  for (const line of await run`rustup toolchain list`) {
    const name = line.split(" ")[0] ?? "";
    const dirs = pinned.get(name.replace(/-\w+-apple-darwin$/u, ""));
    const pin = dirs ? `pinned by ${dirs.join(", ")}` : "unused";
    const note = line.includes("default") ? "default" : pin;
    item(`${name} (${note})`, note === "unused" ? `rustup toolchain uninstall ${name}` : undefined);
  }
}

async function packageCaches(): Promise<void> {
  console.log("\n## Package caches");
  const nuget = [`${home}/.nuget/packages`, `${home}/.local/share/NuGet/http-cache`];
  const caches: [string, string[], string][] = [
    ["NuGet", nuget, "dotnet nuget locals all --clear"],
    ["uv", [`${home}/.cache/uv`], "uv cache prune"],
    ["bun", [`${home}/.bun/install/cache`], "bun pm cache rm"],
    ["npm", [`${home}/.npm`], "npm cache clean --force"],
  ];
  let shown = 0;
  for (const [label, paths, cmd] of caches) {
    const kib = await kibOf(...paths);
    if (kib >= minCacheKib) {
      item(label, cmd, kib);
      shown++;
    }
  }
  if (shown === 0) {
    item("Nothing worth clearing");
  }
}

async function miseVersions(): Promise<void> {
  console.log("\n## mise");
  const lines = await run`mise prune --dry-run`;
  const prunable = lines.flatMap((line) => /^mise (\S+) is prunable/u.exec(line)?.[1] ?? []);
  const names = prunable.join(" ");
  item(names ? `Unused tool versions: ${names}` : "No unused tool versions", names && "mise prune");
}

async function docker(): Promise<void> {
  console.log("\n## Docker");
  const kib = await kibOf(`${home}/Library/Containers/com.docker.docker`);
  if ((await $`docker info`.quiet().nothrow()).exitCode === 0) {
    item("Docker Desktop data", undefined, kib);
    console.log((await run`docker system df`).map((line) => `            ${line}`).join("\n"));
    item(
      "Stopped containers, dangling images, unused networks and build cache",
      "docker system prune",
    );
  } else if (kib) {
    item("Docker Desktop data (daemon not running; start Docker to inspect)", undefined, kib);
  }
}

async function piSessions(): Promise<void> {
  console.log("\n## Pi sessions");
  const lines = await run`${dotfiles}/agentic/pi-config/scripts/prune-sessions.pl --dry-run`;
  const summary = lines.at(-1) ?? "";
  const prune = /^Would trash [1-9]/u.test(summary)
    ? "mise -C ~/Dev/dotfiles/agentic/pi-config run sessions:prune"
    : undefined;
  item(summary, prune, await kibOf(`${home}/.pi/agent/sessions`));
}

async function dotfileLinks(): Promise<void> {
  console.log("\n## Dotfile links");
  const broken = await run`${dotfiles}/scripts/setup-symlinks.ts --check`;
  for (const line of broken) {
    item(line, "mise -C ~/Dev/dotfiles run symlinks");
  }
  if (broken.length === 0) {
    item("All linked");
  }
}

function isJob(value: unknown): value is { Program?: string; ProgramArguments?: string[] } {
  return typeof value === "object" && value !== null;
}

async function launchJobs(): Promise<void> {
  console.log("\n## Launch agents and daemons");
  const dirs = [`${home}/Library/LaunchAgents`, "/Library/LaunchAgents", "/Library/LaunchDaemons"];
  for (const dir of dirs) {
    const plists = [...new Glob("*.plist").scanSync({ cwd: dir, absolute: true })];
    for (const plist of plists.toSorted((a, b) => a.localeCompare(b))) {
      const job: unknown = await $`plutil -convert json -o - ${plist}`.quiet().json();
      if (isJob(job)) {
        const program = job.Program ?? job.ProgramArguments?.[0] ?? "?";
        const missing = existsSync(program) ? "" : " (program missing)";
        item(`${tilde(plist)} -> ${tilde(program)}${missing}`);
      }
    }
  }
}

console.log("# Daily driver audit");
const df = (await run`df -k /System/Volumes/Data`).find((row) => row.endsWith("Data"));
const [, size = 0, used = 0] = df?.split(/\s+/u).map(Number) ?? [];
console.log(`Data volume: ${human(used)} used of ${human(size)}`);
await rustArtifacts();
await rustToolchains();
await packageCaches();
await miseVersions();
await docker();
await piSessions();
await dotfileLinks();
await launchJobs();
console.log("\n## Health");
item((await run`fdesetup status`)[0] ?? "");
item((await run`/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate`)[0] ?? "");
item((await run`csrutil status`)[0] ?? "");
