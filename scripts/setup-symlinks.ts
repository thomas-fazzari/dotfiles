#!/usr/bin/env bun
import fs from "node:fs";
import { homedir } from "node:os";
import { dirname } from "node:path";

/** [link under $HOME, target in the repo] */
type Link = readonly [string, string];
/** [file under $HOME, source in the repo, rewrite of the source]: copies adapted from the originals */
type Copy = readonly [string, string, (source: string) => string];

const dotfiles = fs.realpathSync(`${import.meta.dir}/..`);
const home = homedir();
const os = process.platform === "darwin" ? "macos" : "linux";
const check = process.argv[2] === "--check";
const timestamp = new Date().toLocaleString("sv").replaceAll(/[-:]/gu, "").replace(" ", "-");
const theme = `${dotfiles}/themes/current`;

const common: Link[] = [
  [".config/ghostty/config.ghostty", "terminal/ghostty/config"],
  [".config/btop/btop.conf", "btop/btop.conf"],
  [".config/nvim", "nvim"],
  [".config/mise/config.toml", "mise.toml"],
  [".config/mise/mise.lock", "mise.lock"],
  [".config/topgrade.toml", `${os}/topgrade.toml`],
  [".config/fish/config.fish", "terminal/fish/config.fish"],
  [".config/fish/functions", "terminal/fish/functions"],
  [".gitconfig", "git/.gitconfig"],
  [".gitignore_global", "git/.gitignore_global"],
  // Through themes/current, so switching themes needs no relinking
  [".config/ghostty/themes/current", "themes/current/ghostty"],
  [".config/btop/themes/current.theme", "themes/current/btop.theme"],
  [".config/delta/theme.gitconfig", "themes/current/delta.gitconfig"],
  [".config/bat/themes/current.tmTheme", "themes/current/bat.tmTheme"],
  [".config/eza/theme.yml", "themes/current/eza.yml"],
];

const links: Record<typeof os, Link[]> = {
  macos: [
    ["Library/Application Support/Code/User/settings.json", "vscode/settings.json"],
    ["Library/Application Support/Code/User/keybindings.json", "vscode/keybindings.json"],
    [".config/ghostty/os.ghostty", "macos/ghostty.conf"],
    [".config/aerospace/aerospace.toml", "macos/aerospace/aerospace.toml"],
    [".config/rex/init.lua", "terminal/rex/init.lua"],
    [".config/stablebar", "macos/stablebar"],
    [
      "Library/Application Support/Alfred/Alfred.alfredpreferences/preferences/features/websearch/prefs.plist",
      "macos/torrenting/alfred/websearch.plist",
    ],
  ],
  linux: [
    [".config/Code/User/keybindings.json", "vscode/keybindings.json"],
    [".config/ghostty/os.ghostty", "linux/ghostty.conf"],
    [".config/environment.d/10-dotfiles.conf", "linux/environment.conf"],
    [".config/niri/config.kdl", "linux/niri/config.kdl"],
    [".zshenv", "linux/zshenv"],
  ],
};

// Rewritten on every theme switch, so their previous copy is not backed up
const generated: Copy[] = [
  // Starship cannot include files, so the theme's [palettes.current] is appended to a copy
  [
    ".config/starship.toml",
    "terminal/starship/starship.toml",
    (source) => source + fs.readFileSync(`${theme}/starship.toml`, "utf8"),
  ],
  [
    ".config/eilmeldung/config.toml",
    "rss/eilmeldung/config.toml",
    (source) => source + fs.readFileSync(`${theme}/eilmeldung.toml`, "utf8"),
  ],
];

const rendered: Record<typeof os, Copy[]> = {
  macos: [
    [
      "Library/LaunchAgents/local.proton-qbittorrent.plist",
      "macos/torrenting/launchd/local.proton-qbittorrent.plist",
      (source) => source,
    ],
  ],
  linux: [
    [
      ".config/Code/User/settings.json",
      "vscode/settings.json",
      (source) =>
        source
          .replaceAll("/Users/thomas/Library/Application Support/mbx", `${home}/.local/share/mbx`)
          .replaceAll("/Users/thomas", home)
          .replaceAll("/opt/homebrew/bin/perl", "/usr/bin/perl"),
    ],
  ],
};

function readLink(path: string): string | undefined {
  return fs.lstatSync(path, { throwIfNoEntry: false })?.isSymbolicLink()
    ? fs.readlinkSync(path)
    : undefined;
}

function clear(path: string, keepBackup: boolean): void {
  if (readLink(path) !== undefined) {
    fs.unlinkSync(path);
  } else if (keepBackup && fs.existsSync(path)) {
    fs.renameSync(path, `${path}.backup-${timestamp}`);
    console.log(`backup ${path}`);
  }
  fs.mkdirSync(dirname(path), { recursive: true });
}

function syncLink([name, to]: Link): boolean {
  const link = `${home}/${name}`;
  const target = `${dotfiles}/${to}`;
  if (!fs.existsSync(target)) {
    console.error(`skip ${link}: missing target ${target}`);
    return false;
  }
  const current = readLink(link);
  if (current === target) {
    return false;
  }
  if (check) {
    console.log(
      current === undefined
        ? `${fs.existsSync(link) ? "not a link" : "missing"} ${link}`
        : `wrong ${link} -> ${current}`,
    );
    return true;
  }
  clear(link, true);
  fs.symlinkSync(target, link);
  console.log(`link ${link} -> ${target}`);
  return true;
}

function syncCopy([name, from, render]: Copy, keepBackup: boolean): boolean {
  const file = `${home}/${name}`;
  const source = `${dotfiles}/${from}`;
  if (!fs.existsSync(source)) {
    console.error(`skip ${file}: missing source ${source}`);
    return false;
  }
  const content = render(fs.readFileSync(source, "utf8"));
  const linked = readLink(file) !== undefined;
  if (!linked && fs.existsSync(file) && fs.readFileSync(file, "utf8") === content) {
    return false;
  }
  if (check) {
    console.log(
      `${linked ? "link instead of copy" : fs.existsSync(file) ? "stale" : "missing"} ${file}`,
    );
    return true;
  }
  clear(file, keepBackup);
  fs.writeFileSync(file, content);
  console.log(`render ${file} from ${source}`);
  return true;
}

if (!check && readLink(theme) === undefined) {
  fs.symlinkSync("tokyonight_moon", theme);
  console.log(`link ${theme} -> tokyonight_moon`);
}

const drift = [
  ...[...common, ...links[os]].map(syncLink),
  ...generated.map((copy) => syncCopy(copy, false)),
  ...rendered[os].map((copy) => syncCopy(copy, true)),
];
process.exitCode = check && drift.includes(true) ? 1 : 0;
