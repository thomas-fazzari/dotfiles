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
if (failed.length > 0) {
  throw new Error(`Failed to install: ${failed.join(" ")}`);
}
