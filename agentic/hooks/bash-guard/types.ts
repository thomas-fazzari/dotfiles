import type { Args } from "./rules.ts";

/** A word of a command line, with its offsets in the line and its text once quotes and escapes are removed */
export interface Word {
  readonly start: number;
  readonly end: number;
  readonly text: string;
}

export type RedirectionKind = "read" | "write";

export interface Redirection {
  readonly kind: RedirectionKind;
  readonly target: string;
}

/** Redirections are kept out of the words */
export interface SimpleCommand {
  readonly words: Word[];
  readonly redirections: Redirection[];
  /** Reads the output of the command before it through a pipe */
  readonly piped: boolean;
}

export interface Rule {
  readonly reason: string;
  readonly applies: (args: Args) => boolean;
}

/** Rules by program name, the first that applies gives the reason */
export type RuleBook = ReadonlyMap<string, readonly Rule[]>;

export interface GuardOptions {
  readonly cwd: string;
  /** The agent has its own file read and search tools, so file reads in bash are denied */
  readonly readTools: boolean;
}

/** What to do with a bash command, which runs as `command` unless it is denied */
export type Verdict =
  | { readonly action: "run"; readonly command: string }
  | { readonly action: "ask"; readonly command: string; readonly reason: string }
  | { readonly action: "deny"; readonly reason: string };
