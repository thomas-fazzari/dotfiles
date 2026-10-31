import { homedir } from "node:os";

export const END_OF_OPTIONS = "--";
export const XARGS = "xargs";
export const COMMAND = "command";

const SHELLS = new Set(["sh", "bash", "zsh", "fish"]);

const OPTION = /^-./u;
const HOME_PREFIX = /^(?:~|\$HOME|\$\{HOME\})(?=\/|$)/u;
const SAFE_WORD = /^[\w@%+=:,./-]+$/u;

export function programName(program: string): string {
  return program.slice(program.lastIndexOf("/") + 1);
}

export function isShell(program: string): boolean {
  return SHELLS.has(programName(program));
}

/** A lone - is an operand, which names stdin */
export function isOption(arg: string): boolean {
  return OPTION.test(arg);
}

export function operands(args: readonly string[]): string[] {
  const end = args.indexOf(END_OF_OPTIONS);
  if (end === -1) {
    return args.filter((arg) => !isOption(arg));
  }
  return [...operands(args.slice(0, end)), ...args.slice(end + 1)];
}

export function expandHome(path: string): string {
  return path.replace(HOME_PREFIX, () => homedir());
}

export function shellQuote(text: string): string {
  return SAFE_WORD.test(text) ? text : `'${text.replaceAll("'", String.raw`'\''`)}'`;
}
