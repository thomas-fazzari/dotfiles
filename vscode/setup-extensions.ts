#!/usr/bin/env bun
import { $ } from "bun";

const attempts = 3;
const list = await Bun.file(`${import.meta.dir}/extensions.txt`).text();
const failed: string[] = [];

for (const extension of list.split("\n").filter((line) => /\S/u.test(line))) {
  for (let attempt = 1; attempt <= attempts; attempt++) {
    if ((await $`code --install-extension ${extension} --force`.nothrow()).exitCode === 0) {
      break;
    }
    if (attempt === attempts) {
      failed.push(extension);
    } else {
      await Bun.sleep(2000 * attempt);
    }
  }
}
const dotfiles = `${import.meta.dir}/..`;
for (const manifest of new Bun.Glob("themes/*/vscode/package.json").scanSync(dotfiles)) {
  const dir = `${dotfiles}/${manifest.replace("/package.json", "")}`;
  const vsix = `${process.env.TMPDIR ?? "/tmp"}/${dir.split("/").at(-2)}.vsix`;
  const packaged = await $`bunx @vscode/vsce package --allow-missing-repository --skip-license -o ${vsix}`
    .cwd(dir)
    .quiet()
    .nothrow();
  if (packaged.exitCode !== 0 || (await $`code --install-extension ${vsix} --force`.nothrow()).exitCode !== 0) {
    failed.push(dir);
  }
}
if (failed.length > 0) {
  throw new Error(`Failed to install: ${failed.join(" ")}`);
}
