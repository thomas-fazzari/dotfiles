import { isOption, isShell, programName } from "./utils.ts";

const FETCHERS = new Set(["curl", "wget"]);
const INTERPRETERS = new Set(["python", "python3", "perl", "node"]);
const SOURCES = new Set(["source", "."]);

const SUBSTITUTION = /\$\(|`/u;
const STDIN_OPERAND = /^-s?$/u;
const PROCESS_SUBSTITUTION = /^<\(/u;

export function isFetcher(program: string): boolean {
  return FETCHERS.has(programName(program));
}

/** Code that never shows up in the command, so approving the command does not review it */
export function runsUnseenCode(
  program: string,
  args: readonly string[],
  script: string | undefined,
): boolean {
  const name = programName(program);
  if (script !== undefined) {
    return SUBSTITUTION.test(script);
  }
  if (SOURCES.has(name)) {
    return PROCESS_SUBSTITUTION.test(args.at(0) ?? "");
  }
  return (isShell(name) || INTERPRETERS.has(name)) && runsHiddenScript(args);
}

// Without a script operand they run stdin, and <(...) hides the script it feeds them
function runsHiddenScript(args: readonly string[]): boolean {
  for (const arg of args) {
    if (STDIN_OPERAND.test(arg) || PROCESS_SUBSTITUTION.test(arg)) {
      return true;
    }
    if (!isOption(arg)) {
      return false;
    }
  }
  return true;
}
