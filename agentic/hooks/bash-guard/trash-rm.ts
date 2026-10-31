#!/usr/bin/env bun
// Stands in for rm: moves its operands to the trash
import { spawnSync } from "node:child_process";
import { lstatSync } from "node:fs";
import { TRASH } from "./trash.ts";
import { END_OF_OPTIONS, isOption } from "./utils.ts";

const FORCE = /^-[^-]*f/u;

const args = process.argv.slice(2);
let force = false;
let index = 0;
while (index < args.length && isOption(args[index])) {
  const flag = args[index++];
  if (flag === END_OF_OPTIONS) {
    break;
  }
  force ||= flag === "--force" || FORCE.test(flag);
}

const existing: string[] = [];
for (const path of args.slice(index)) {
  // lstat, so a dangling symlink still counts as there to delete
  if (lstatSync(path, { throwIfNoEntry: false }) !== undefined) {
    existing.push(path);
  } else if (!force) {
    console.error(`rm: ${path}: No such file or directory`);
    process.exitCode = 1;
  }
}
if (existing.length > 0 && spawnSync(TRASH, existing, { stdio: "inherit" }).status !== 0) {
  process.exitCode = 1;
}
