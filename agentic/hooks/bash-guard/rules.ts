import type { RuleBook } from "./types.ts";
import { END_OF_OPTIONS, operands } from "./utils.ts";

const SHORT_SPELLING = /^-(\w)$/u;
const LONG_SPELLING = "--";
const SHORT_CLUSTER = /^-(\w+)$/u;
const LONG_OPTION = /^(--[\w-]+)(?:=|$)/u;

export function firstReason(
  book: RuleBook,
  name: string,
  args: readonly string[],
): string | undefined {
  const wrapped = new Args(args);
  return book.get(name)?.find(({ applies }) => applies(wrapped))?.reason;
}

export class Args {
  readonly list: readonly string[];

  constructor(list: readonly string[]) {
    this.list = list;
  }

  get operands(): string[] {
    return operands(this.list);
  }

  has(...names: readonly string[]): boolean {
    return this.list.some((arg) => names.includes(arg));
  }

  matches(pattern: RegExp): boolean {
    return this.list.some((arg) => pattern.test(arg));
  }

  /** The first argument is one of names, such as drop in git stash drop */
  action(...names: readonly string[]): boolean {
    const first = this.list.at(0);
    return first !== undefined && names.includes(first);
  }

  /** Any spelling of an option given as --long or -l, with letters matching inside -abc clusters */
  flag(...spellings: readonly string[]): boolean {
    const longs = spellings.filter((spelling) => spelling.startsWith(LONG_SPELLING));
    const letters = spellings.flatMap((spelling) => SHORT_SPELLING.exec(spelling)?.[1] ?? []);
    for (const arg of this.list) {
      if (arg === END_OF_OPTIONS) {
        return false;
      }
      const cluster = SHORT_CLUSTER.exec(arg)?.[1];
      if (cluster !== undefined) {
        if (letters.some((letter) => cluster.includes(letter))) {
          return true;
        }
        continue;
      }
      const long = LONG_OPTION.exec(arg)?.[1];
      if (long !== undefined && longs.includes(long)) {
        return true;
      }
    }
    return false;
  }
}
