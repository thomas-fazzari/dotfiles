import { accessSync, constants } from "node:fs";
import { fileURLToPath } from "node:url";
import type { Word } from "./types.ts";
import { shellQuote } from "./utils.ts";

export const TRASH = "/usr/bin/trash";
export const TRASH_RM = fileURLToPath(new URL("trash-rm.ts", import.meta.url));

const RM_NAMES = new Set(["rm", "/bin/rm", "/usr/bin/rm"]);

export function isRm(program: string): boolean {
  return RM_NAMES.has(program);
}

export function trashAvailable(): boolean {
  try {
    accessSync(TRASH, constants.X_OK);
    return true;
  } catch {
    return false;
  }
}

/** Replaces each rm word with the trash helper, last first so the earlier offsets stay valid */
export function rewriteRm(command: string, words: readonly Word[]): string {
  return words
    .toSorted((a, b) => b.start - a.start)
    .reduce(
      (line, { start, end }) => `${line.slice(0, start)}${shellQuote(TRASH_RM)}${line.slice(end)}`,
      command,
    );
}
