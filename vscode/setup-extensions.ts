#!/usr/bin/env bun
// Installs extensions into profiles:
//   - default profile: `base` of vscode/extensions.yaml
//   - profile <name>:  `base` + `profiles.<name>` of vscode/extensions.yaml
//
// Missing or outdated profiles are written to storage.json (VS Code must be closed).
//
// Every profile shares the default's settings, only the extensions differ.
import { $ } from "bun";
import {
  copyFileSync,
  existsSync,
  mkdirSync,
  readFileSync,
  renameSync,
  writeFileSync,
} from "node:fs";
import { homedir } from "node:os";
import { basename, dirname } from "node:path";
import { isMatching, P } from "ts-pattern";

type Extension = { id: string; source: string };

const configShape = {
  base: P.array(P.string),
  profiles: P.record(P.string, P.array(P.string)),
};
const storageShape = { userDataProfiles: P.optional(P.array({ name: P.string })) };
const manifestShape = { publisher: P.string, name: P.string };

// keeps Microsoft's AI crap disabled in every profile
const sharedFlags = {
  settings: true,
  keybindings: true,
  snippets: true,
  tasks: true,
  mcp: true,
  prompts: true,
  globalState: true,
};

const attempts = 3;
const dotfiles = `${import.meta.dir}/..`;
const userDir =
  process.platform === "darwin"
    ? `${homedir()}/Library/Application Support/Code/User`
    : `${homedir()}/.config/Code/User`;
const failed: string[] = [];

function marketplace(ids: string[]): Extension[] {
  return ids.map((id) => ({ id, source: id }));
}

function vsCodeRunning(): boolean {
  const lock = `${dirname(userDir)}/code.lock`;
  if (!existsSync(lock)) {
    return false;
  }
  const pid = Number.parseInt(readFileSync(lock, "utf8"), 10);
  if (Number.isNaN(pid)) {
    return false;
  }
  try {
    process.kill(pid, 0);
    return true;
  } catch (error) {
    return isMatching({ code: "EPERM" }, error);
  }
}

function ensureProfiles(names: string[]) {
  const storagePath = `${userDir}/globalStorage/storage.json`;
  const storage: unknown = existsSync(storagePath)
    ? JSON.parse(readFileSync(storagePath, "utf8"))
    : {};
  if (!isMatching(storageShape, storage)) {
    throw new Error(`Unexpected userDataProfiles in ${storagePath}`);
  }
  const profiles = storage.userDataProfiles ?? [];
  const stale = names.filter(
    (name) =>
      !profiles.some((profile) => isMatching({ name, useDefaultFlags: sharedFlags }, profile)),
  );
  if (stale.length === 0) {
    return;
  }
  if (vsCodeRunning()) {
    throw new Error(`Quit VS Code to update the profiles ${stale.join(", ")}, then run again`);
  }
  for (const name of stale) {
    const existing = profiles.find((profile) => profile.name === name);
    if (existing) {
      Object.assign(existing, { useDefaultFlags: sharedFlags });
    } else {
      mkdirSync(`${userDir}/profiles/${name}`, { recursive: true });
      const profile = { name, location: name, useDefaultFlags: sharedFlags };
      profiles.push(profile);
    }
  }
  storage.userDataProfiles = profiles;
  mkdirSync(dirname(storagePath), { recursive: true });
  if (existsSync(storagePath)) {
    copyFileSync(storagePath, `${storagePath}.bak`);
  }
  writeFileSync(`${storagePath}.tmp`, `${JSON.stringify(storage, null, 2)}\n`);
  renameSync(`${storagePath}.tmp`, storagePath);
  console.log(`Created or updated VS Code profiles: ${stale.join(", ")}`);
}

async function packageThemes(): Promise<Extension[]> {
  const themes: Extension[] = [];
  for (const manifest of new Bun.Glob("themes/*/vscode/package.json").scanSync(dotfiles)) {
    const dir = `${dotfiles}/${dirname(manifest)}`;
    const json: unknown = await Bun.file(`${dotfiles}/${manifest}`).json();
    if (!isMatching(manifestShape, json)) {
      throw new Error(`Missing publisher or name in ${manifest}`);
    }
    const vsix = `${process.env.TMPDIR ?? "/tmp"}/${basename(dirname(dir))}.vsix`;
    const packaged =
      await $`bunx @vscode/vsce package --allow-missing-repository --skip-license -o ${vsix}`
        .cwd(dir)
        .quiet()
        .nothrow();
    if (packaged.exitCode === 0) {
      themes.push({ id: `${json.publisher}.${json.name}`, source: vsix });
    } else {
      failed.push(dir);
    }
  }
  return themes;
}

async function installedIds(profileArgs: string[]): Promise<Set<string>> {
  const output = await $`code ${profileArgs} --list-extensions`.quiet().nothrow().text();
  return new Set(output.split("\n").map((line) => line.trim().toLowerCase()));
}

// One code call for the whole list, then per-extension retries for what --list-extensions lacks
async function install(profile: string | undefined, extensions: Extension[]) {
  const profileArgs = profile === undefined ? [] : ["--profile", profile];
  const sources = extensions.flatMap(({ source }) => ["--install-extension", source]);
  await $`code ${profileArgs} ${sources} --force`.nothrow();
  const installed = await installedIds(profileArgs);
  const missing = extensions.filter((extension) => !installed.has(extension.id.toLowerCase()));
  for (const { id, source } of missing) {
    for (let attempt = 1; attempt <= attempts; attempt++) {
      const { exitCode } =
        await $`code ${profileArgs} --install-extension ${source} --force`.nothrow();
      if (exitCode === 0) {
        break;
      }
      if (attempt === attempts) {
        failed.push(`${profile ?? "default"}: ${id}`);
      } else {
        await Bun.sleep(2000 * attempt);
      }
    }
  }
}

if (Bun.which("code") === null) {
  throw new Error("The code command is not on PATH");
}
const config: unknown = Bun.YAML.parse(await Bun.file(`${import.meta.dir}/extensions.yaml`).text());
if (!isMatching(configShape, config)) {
  throw new Error("extensions.yaml needs a base list and a profiles map of extension ID lists");
}
ensureProfiles(Object.keys(config.profiles));
const base = [...marketplace(config.base), ...(await packageThemes())];
await install(undefined, base);
for (const [name, ids] of Object.entries(config.profiles)) {
  await install(name, [...base, ...marketplace(ids)]);
}
if (failed.length > 0) {
  throw new Error(`Failed to install: ${failed.join(" ")}`);
}
