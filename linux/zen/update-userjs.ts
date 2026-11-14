#!/usr/bin/env bun
import { $ } from "bun";
import fs from "node:fs";
import { homedir } from "node:os";
import { basename } from "node:path";

const source = "https://raw.githubusercontent.com/yokoffing/Betterfox/main/zen/user.js";
const marker = "// Enter your personal overrides below this line:\n";
const here = import.meta.dir;
const stamp = new Date().toLocaleString("sv").replaceAll(/[-:]/gu, "").replace(" ", "-");
const xdg = `${process.env.XDG_CONFIG_HOME ?? `${homedir()}/.config`}/zen`;
const zen = fs.existsSync(xdg) ? xdg : `${homedir()}/.zen`;

const userjs = (await $`curl -fsSL ${source}`.text()).replaceAll("\r\n", "\n");
const version = /^ \* version: (\S+)/mu.exec(userjs)?.[1];
if (!version || !userjs.includes(marker)) {
  throw new Error("BetterZen user.js has no version or overrides marker");
}
const mine = await Bun.file(`${here}/user-overrides.js`).text();
await Bun.write(
  `${here}/user.js`,
  userjs.replace(marker, () => marker + mine),
);
console.log(`build user.js from BetterZen ${version}`);

const profile = /^Default=(.+)$/mu.exec(await Bun.file(`${zen}/installs.ini`).text())?.[1];
if (!profile) {
  throw new Error("No default profile in installs.ini");
}
const dir = `${zen}/${profile}`;
fs.mkdirSync(`${dir}/chrome`, { recursive: true });

for (const file of ["user.js", "chrome/userChrome.css"]) {
  const link = `${dir}/${file}`;
  const target = `${here}/${basename(file)}`;
  const current = fs.lstatSync(link, { throwIfNoEntry: false });
  if (current?.isSymbolicLink() && fs.readlinkSync(link) === target) {
    console.log(`ok ${link}`);
    continue;
  }
  if (current?.isSymbolicLink()) {
    fs.unlinkSync(link);
  } else if (current) {
    fs.renameSync(link, `${link}.backup-${stamp}`);
    console.log(`backup ${link}`);
  }
  fs.symlinkSync(target, link);
  console.log(`link ${link} -> ${target}`);
}

if ((await $`pgrep -x ${"zen|zen-bin"}`.quiet().nothrow()).exitCode === 0) {
  console.log("Zen is running: quit it with Ctrl+Q and relaunch to apply");
}
