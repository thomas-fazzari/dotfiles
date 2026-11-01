import { spawnSync } from "node:child_process";
import { existsSync, globSync, realpathSync, statSync } from "node:fs";
import { dirname, isAbsolute } from "node:path";
import { type Args, firstReason } from "./rules.ts";
import { redirectionTargets } from "./shell.ts";
import type { Rule, SimpleCommand } from "./types.ts";
import { COMMAND, XARGS, expandHome, operands, programName } from "./utils.ts";

const FIND = "find";
const GREPS = ["grep", "egrep", "fgrep"];
const SEARCHING_WALKERS = ["fd", "rg", "ag"];
const WALKERS = [...SEARCHING_WALKERS, "tree"];
const PRINTERS = ["cat", "head", "tail", "less", "more", "nl", "bat"];
const EDITORS = ["sed", "awk", "gawk"];

// The file tools only search what git tracks or could track inside the project
const SEARCHES = new Set([FIND, ...SEARCHING_WALKERS, ...GREPS]);

// find tests the file tools cannot run: times, sizes, owners, permissions, links
const FIND_METADATA =
  /^-(?:[amc](?:min|time)|newer\w*|size|perm|empty|n?user|n?group|[ug]id|links|inum|samefile|ls|f?printf)$/u;
const FIND_EXPRESSION = /^[-(!]/u;
const FIND_TYPE = "-type";
const REGULAR_FILE = "f";

const LOOKUP_FLAG = /^-[vV]$/u;
const SHELL_EXPANSION = /[$`]/u;
const VARIABLE = "$";
const PREVIOUS_DIRECTORY = "-";
// xargs appends the file names it reads from the pipe
const XARGS_FILES = "{}";

const WALKS = "walks the file system";
const INSTEAD =
  "use your file read, search and listing tools instead. Count lines with tokei <dir> --files, matches with git grep -c";

// sed, awk and grep take a script or pattern first, so a second operand is a file
const RULES = new Map<string, readonly Rule[]>([
  ...rulesFor(WALKERS, WALKS, () => true),
  ...rulesFor([FIND], WALKS, (args) => !findsMetadata(args)),
  ...rulesFor(PRINTERS, "prints files", (args) => args.operands.length > 0),
  ...rulesFor(EDITORS, "works on files", (args) => args.operands.length > 1),
  ...rulesFor(
    GREPS,
    "searches files",
    (args) =>
      args.operands.length > 1 || args.flag("-r", "-R", "--recursive", "--dereference-recursive"),
  ),
]);

/** The directory a cd at the start of the chain runs the rest of it from */
export function leadingCd(commands: readonly SimpleCommand[], cwd: string): string | undefined {
  const [program, target, ...rest] = (commands.at(0)?.words ?? []).map(({ text }) => text);
  if (program !== "cd" || target === undefined || rest.length > 0) {
    return undefined;
  }
  if (target === PREVIOUS_DIRECTORY || SHELL_EXPANSION.test(target)) {
    return undefined;
  }
  const directory = resolvePath(target, cwd);
  if (isDirectory(directory)) {
    return directory;
  }
  const matches = globSync(directory).filter(isDirectory);
  return matches.length === 1 ? matches[0] : undefined;
}

interface Root {
  readonly path: string;
  readonly inGit: boolean;
}

export class Project {
  readonly cwd: string;
  #root: Root | undefined;

  constructor(cwd: string) {
    this.cwd = cwd;
  }

  /** Paths outside the project, and the paths git ignores inside it */
  isBeyondFileTools(path: string): boolean {
    const real = realPath(existingParent(path));
    if (real === undefined) {
      return false;
    }
    const root = this.root();
    if (!`${real}/`.startsWith(`${root.path}/`)) {
      return true;
    }
    return root.inGit && git(root.path, "check-ignore", "-q", "--", real).status === 0;
  }

  private root(): Root {
    if (this.#root === undefined) {
      const { status, stdout } = git(this.cwd, "rev-parse", "--show-toplevel");
      const top = status === 0 ? stdout.trim() : "";
      const inGit = top !== "";
      this.#root = { path: realPath(inGit ? top : this.cwd) ?? this.cwd, inGit };
    }
    return this.#root;
  }
}

// A piped command filters output and command -v only looks a program up, so neither reads files
export function readRisk(
  command: SimpleCommand,
  position: number,
  project: Project,
  workdir: string,
): string | undefined {
  const before = command.words.slice(0, position).map(({ text }) => programName(text));
  if (before.at(-2) === COMMAND && LOOKUP_FLAG.test(before.at(-1) ?? "")) {
    return undefined;
  }
  const viaXargs = before.includes(XARGS);
  if (command.piped && !viaXargs) {
    return undefined;
  }
  const [program, ...rest] = command.words.slice(position).map(({ text }) => text);
  const args = [
    ...rest,
    ...redirectionTargets(command, "read"),
    ...(viaXargs ? [XARGS_FILES] : []),
  ];
  const name = programName(program);
  const reason = firstReason(RULES, name, args);
  if (reason === undefined) {
    return undefined;
  }
  if (SEARCHES.has(name) && searchesBeyondFileTools(name, args, project, workdir)) {
    return undefined;
  }
  return `${reason}: ${INSTEAD}`;
}

// A path the shell has yet to expand could be anywhere
function searchesBeyondFileTools(
  name: string,
  args: readonly string[],
  project: Project,
  workdir: string,
): boolean {
  const searched = searchOperands(name, args);
  if (searched.some((operand) => expandHome(operand).includes(VARIABLE))) {
    return true;
  }
  return searchPaths(workdir, searched).every((path) => project.isBeyondFileTools(path));
}

/** find walks its leading operands, the others the operands after their pattern */
function searchOperands(name: string, args: readonly string[]): readonly string[] {
  if (name !== FIND) {
    return operands(args).slice(1);
  }
  const end = args.findIndex((arg) => FIND_EXPRESSION.test(arg));
  return end === -1 ? args : args.slice(0, end);
}

/** A relative operand that names nothing on disk is an option value, such as an rg -g glob */
function searchPaths(directory: string, searched: readonly string[]): string[] {
  const paths = searched
    .filter(
      (operand) => isAbsolute(expandHome(operand)) || existsSync(resolvePath(operand, directory)),
    )
    .map((operand) => resolvePath(operand, directory));
  return paths.length > 0 ? paths : [directory];
}

function findsMetadata({ list }: Args): boolean {
  return list.some(
    (arg, index) =>
      FIND_METADATA.test(arg) ||
      (arg === FIND_TYPE && (list.at(index + 1) ?? REGULAR_FILE) !== REGULAR_FILE),
  );
}

function rulesFor(
  names: readonly string[],
  does: string,
  applies: (args: Args) => boolean,
): [string, readonly Rule[]][] {
  return names.map((name) => [name, [{ reason: `${name} ${does}`, applies }]]);
}

/** A glob or a missing file lies wherever its nearest existing parent does */
function existingParent(path: string): string {
  let current = path;
  while (!existsSync(current) && dirname(current) !== current) {
    current = dirname(current);
  }
  return current;
}

function resolvePath(path: string, directory: string): string {
  const expanded = expandHome(path);
  return isAbsolute(expanded) ? expanded : `${directory}/${expanded}`;
}

function realPath(path: string): string | undefined {
  try {
    return realpathSync(path);
  } catch {
    return undefined;
  }
}

function isDirectory(path: string): boolean {
  return statSync(path, { throwIfNoEntry: false })?.isDirectory() ?? false;
}

function git(cwd: string, ...args: readonly string[]) {
  return spawnSync("git", args, { cwd, encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] });
}
