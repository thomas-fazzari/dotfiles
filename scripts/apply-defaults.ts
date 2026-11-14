#!/usr/bin/env bun
import { $, Glob } from "bun";
import { basename } from "node:path";

const ENTRY =
  /^\t<key>([^<]*)<\/key>\n\t(<\w+\/>|<(\w+)>[^\n]*?<\/\3>|<(\w+)>\n.*?\n\t<\/\4>)$/gmsu;

for await (const file of new Glob("*.plist").scan({
  cwd: `${import.meta.dir}/../macos/defaults`,
  absolute: true,
})) {
  const domain = basename(file, ".plist");
  for (const [, key = "", value = ""] of (await Bun.file(file).text()).matchAll(ENTRY)) {
    await $`defaults write ${domain} ${key} ${value}`;
  }
  console.log(`applied ${domain}`);
}
