import { type Args, firstReason } from "./rules.ts";
import type { Rule } from "./types.ts";
import { END_OF_OPTIONS, isOption, programName } from "./utils.ts";

const GLOBAL_OPTIONS_WITH_VALUE = new Set(["-C", "-c", "--git-dir", "--work-tree"]);

const RULES = new Map<string, readonly Rule[]>([
  [
    "reset",
    [
      {
        reason: "git reset --hard discards uncommitted changes",
        applies: (args) => args.flag("--hard"),
      },
      {
        reason: "git reset --merge can discard uncommitted changes",
        applies: (args) => args.flag("--merge"),
      },
    ],
  ],
  [
    "checkout",
    [
      {
        reason: "git checkout can discard uncommitted changes",
        applies: (args) => forced(args) || args.has(END_OF_OPTIONS, "."),
      },
    ],
  ],
  [
    "switch",
    [
      {
        reason: "git switch --force discards uncommitted changes",
        applies: (args) => forced(args) || args.flag("--discard-changes"),
      },
    ],
  ],
  [
    "restore",
    [
      {
        reason: "git restore discards uncommitted changes",
        applies: (args) => !args.flag("--staged", "-S") || args.flag("--worktree", "-W"),
      },
    ],
  ],
  [
    "clean",
    [{ reason: "git clean deletes untracked files for good", applies: (args) => !dryRun(args) }],
  ],
  [
    "rm",
    [
      {
        reason: "git rm --force discards uncommitted changes",
        applies: (args) => forced(args) && !args.flag("--cached") && !dryRun(args),
      },
    ],
  ],
  [
    "push",
    [
      {
        reason: "git push --mirror can overwrite and delete remote refs",
        applies: (args) => args.flag("--mirror"),
      },
      {
        reason: "git push --force can overwrite remote commits",
        applies: (args) =>
          forced(args) ||
          (args.matches(/^\+/u) && !args.flag("--force-with-lease", "--force-if-includes")),
      },
      {
        reason: "git push --delete deletes remote refs",
        applies: (args) => deleting(args) || args.matches(/^:./u),
      },
    ],
  ],
  [
    "branch",
    [
      {
        reason: "git branch -D deletes unmerged commits",
        applies: (args) => args.flag("-D") || (forced(args) && deleting(args)),
      },
    ],
  ],
  [
    "stash",
    [
      {
        reason: "git stash drop deletes stashed changes",
        applies: (args) => args.action("drop"),
      },
      {
        reason: "git stash clear deletes all stashed changes",
        applies: (args) => args.action("clear"),
      },
    ],
  ],
  ["rebase", [{ reason: "git rebase --abort discards conflict resolutions", applies: aborting }]],
  ["merge", [{ reason: "git merge --abort discards conflict resolutions", applies: aborting }]],
  ["tag", [{ reason: "git tag --delete deletes tags", applies: deleting }]],
  [
    "reflog",
    [
      {
        reason: "git reflog delete and expire remove recovery history",
        applies: (args) => args.action("delete", "expire"),
      },
    ],
  ],
]);

export function gitRisk(program: string, args: readonly string[]): string | undefined {
  if (programName(program) !== "git") {
    return undefined;
  }
  let index = 0;
  while (index < args.length && isOption(args[index])) {
    index += GLOBAL_OPTIONS_WITH_VALUE.has(args[index]) ? 2 : 1;
  }
  if (index >= args.length) {
    return undefined;
  }
  return firstReason(RULES, args[index], args.slice(index + 1));
}

function forced(args: Args): boolean {
  return args.flag("--force", "-f");
}

function deleting(args: Args): boolean {
  return args.flag("--delete", "-d");
}

function aborting(args: Args): boolean {
  return args.flag("--abort");
}

function dryRun(args: Args): boolean {
  return args.flag("--dry-run", "-n");
}
