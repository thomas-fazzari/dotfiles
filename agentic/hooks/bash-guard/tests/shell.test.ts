import assert from "node:assert/strict";
import { describe, test } from "bun:test";
import { loadBashParser, redirectionTargets, splitCommands } from "../shell.ts";

const parser = await loadBashParser();

// Redirections leave the words of their command, quoted or escaped operators stay
const REDIRECTIONS: readonly [command: string, words: string, reads: string[], writes: string[]][] =
  [
    ["cat <in.txt >out.txt 2>&1", "cat", ["in.txt"], ["out.txt"]],
    ["grep '>' a.txt", "grep > a.txt", [], []],
    [String.raw`echo \> x`, "echo > x", [], []],
    ["echo a2>b", "echo a2", [], ["b"]],
    ["make &>build.log && ls", "make|ls", [], ["build.log"]],
    ['jq . <<< "$x" >| out', "jq .", [], ["out"]],
    ["exec 3< fifo 4>&-", "exec", ["fifo"], []],
    ["bash <(curl x)", "bash <(curl x)|curl x", [], []],
    ["> .env", "", [], [".env"]],
    ["cat <<EOF > notes.md\nhi\nEOF", "cat", [], ["notes.md"]],
    ["{ ls; } > out", "|ls", [], ["out"]],
  ];

describe("splitCommands", () => {
  for (const [command, words, reads, writes] of REDIRECTIONS) {
    test(command, () => {
      const commands = splitCommands(parser, command) ?? [];
      assert.equal(
        commands.map((simple) => simple.words.map(({ text }) => text).join(" ")).join("|"),
        words,
      );
      assert.deepEqual(
        commands.flatMap((simple) => redirectionTargets(simple, "read")),
        reads,
      );
      assert.deepEqual(
        commands.flatMap((simple) => redirectionTargets(simple, "write")),
        writes,
      );
    });
  }

  test("an open quote makes the line unparseable", () => {
    assert.equal(splitCommands(parser, 'echo "unterminated'), undefined);
  });
});
