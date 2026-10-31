import { homedir } from "node:os";
import { firstReason } from "./rules.ts";
import type { Rule } from "./types.ts";
import { expandHome, programName } from "./utils.ts";

const RSYNC_DELETE = /^--(?:del|delete(?:-[\w-]+)?|remove-source-files)$/u;
const DEVICE_OUTPUT = /^of=\/dev\/(?!(?:null|zero|full|stdout|stderr)$)/u;
const DISKUTIL_WIPE =
  /^(?:erase|zero|random|secureErase|reformat|partition|split|merge|resize|delete|remove)/iu;

// newfs_apfs, newfs_hfs and the other variants share the newfs rules
const NEWFS = "newfs";
const NEWFS_VARIANT = /^newfs_\w+$/u;

const TRAILING_GLOB = /\/\*$/u;
const TRAILING_SLASHES = /(?<=.)\/+$/u;
const TOP_LEVEL = /^\/[^/]*$/u;
const PARENT = /(?:^|\/)\.\.$/u;
const CURRENT_DIRECTORY = ".";

const RULES = new Map<string, readonly Rule[]>([
  [
    "rm",
    [
      {
        reason: "rm on a root, home or parent directory removes it whole",
        applies: (args) => args.operands.some(isTooBroad),
      },
    ],
  ],
  [
    "find",
    [{ reason: "find -delete deletes files for good", applies: (args) => args.has("-delete") }],
  ],
  [
    "rsync",
    [
      {
        reason: "rsync --delete deletes files for good",
        applies: (args) => args.matches(RSYNC_DELETE),
      },
    ],
  ],
  ["shred", [{ reason: "shred overwrites files for good", applies: () => true }]],
  [
    "dd",
    [{ reason: "dd writes straight to a device", applies: (args) => args.matches(DEVICE_OUTPUT) }],
  ],
  [NEWFS, [{ reason: "newfs formats a device", applies: () => true }]],
  [
    "diskutil",
    [
      {
        reason: "diskutil can erase or repartition a disk",
        applies: (args) => args.matches(DISKUTIL_WIPE),
      },
    ],
  ],
]);

export function deletionRisk(program: string, args: readonly string[]): string | undefined {
  return firstReason(RULES, programName(program).replace(NEWFS_VARIANT, NEWFS), args);
}

/** Too broad to delete, even through the trash */
function isTooBroad(operand: string): boolean {
  const path = expandHome(operand).replace(TRAILING_GLOB, "/").replace(TRAILING_SLASHES, "");
  return (
    TOP_LEVEL.test(path) || path === homedir() || PARENT.test(path) || path === CURRENT_DIRECTORY
  );
}
