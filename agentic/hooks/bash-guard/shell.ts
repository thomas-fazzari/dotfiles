import { fileURLToPath } from "node:url";
import type { Node, Parser } from "web-tree-sitter";
import type { Redirection, RedirectionKind, SimpleCommand, Word } from "./types.ts";
import { COMMAND, XARGS, isShell, programName } from "./utils.ts";

const PREFIXES = new Set(["sudo", XARGS, "env", COMMAND, "nohup", "time"]);
const EXEC_FLAGS = new Set(["-exec", "-execdir"]);

const COMMAND_NODE = "command";
const REDIRECTED_STATEMENT = "redirected_statement";
const FILE_REDIRECT = "file_redirect";
// The redirections inside them belong to the commands they hold
const REDIRECTION_OWNERS = new Set([
  COMMAND_NODE,
  REDIRECTED_STATEMENT,
  "command_substitution",
  "process_substitution",
]);

const BACKSLASH_ESCAPE = /\\(.)/gsu;
const DESCRIPTOR = /^(?:\d+-?|-)$/u;
const ASSIGNMENT = /^[A-Za-z_]\w*=/u;
const SHELL_OPTION = /^[-+]/u;
const SHELL_COMMAND_FLAG = /^-[a-zA-Z]*c[a-zA-Z]*$/u;
const SHELL_OPTION_WITH_VALUE = /^[-+][oO]$/u;

let bashParser: Promise<Parser> | undefined;

/** Loads tree-sitter's bash grammar once, and again after a failed load */
export function loadBashParser(): Promise<Parser> {
  bashParser ??= createBashParser().catch((error: unknown) => {
    bashParser = undefined;
    throw error;
  });
  return bashParser;
}

// Includes the commands of substitutions and of heredoc bodies that expand them
// undefined when the line does not parse, such as with an open quote
export function splitCommands(parser: Parser, line: string): SimpleCommand[] | undefined {
  const tree = parser.parse(line);
  if (tree === null) {
    return undefined;
  }
  try {
    return tree.rootNode.hasError ? undefined : collectCommands(tree.rootNode);
  } finally {
    tree.delete();
  }
}

export function redirectionTargets(
  command: SimpleCommand,
  ...kinds: readonly RedirectionKind[]
): string[] {
  return command.redirections
    .filter(({ kind }) => kinds.includes(kind))
    .map(({ target }) => target);
}

export function programPositions(words: readonly Word[]): number[] {
  const positions: number[] = [];
  let expectProgram = true;
  let afterPrefix = false;
  for (const [index, { text }] of words.entries()) {
    if (expectProgram) {
      // A lone - is an option too, as in env -
      if (ASSIGNMENT.test(text) || (afterPrefix && text.startsWith("-"))) {
        continue;
      }
      positions.push(index);
      expectProgram = afterPrefix = PREFIXES.has(text);
    } else if (EXEC_FLAGS.has(text)) {
      expectProgram = true;
    }
  }
  return positions;
}

/** Script text a shell gets through -c, or eval through its arguments */
export function inlineScript(program: string, args: readonly string[]): string | undefined {
  if (programName(program) === "eval") {
    return args.join(" ");
  }
  if (!isShell(program)) {
    return undefined;
  }
  for (let index = 0; index < args.length && SHELL_OPTION.test(args[index]); index++) {
    if (SHELL_COMMAND_FLAG.test(args[index])) {
      return args.at(index + 1);
    }
    if (SHELL_OPTION_WITH_VALUE.test(args[index])) {
      index++;
    }
  }
  return undefined;
}

async function createBashParser(): Promise<Parser> {
  const { Language, Parser } = await import("web-tree-sitter");
  await Parser.init();
  const parser = new Parser();
  const grammar = import.meta.resolve("tree-sitter-bash/tree-sitter-bash.wasm");
  parser.setLanguage(await Language.load(fileURLToPath(grammar)));
  return parser;
}

function collectCommands(node: Node, commands: SimpleCommand[] = []): SimpleCommand[] {
  if (node.type === COMMAND_NODE) {
    commands.push(simpleCommand(node));
  } else if (
    node.type === REDIRECTED_STATEMENT &&
    node.childForFieldName("body")?.type !== COMMAND_NODE
  ) {
    // The redirections of a group such as { ...; } > file
    commands.push({ words: [], redirections: statementRedirections(node), piped: false });
  }
  for (const child of node.namedChildren) {
    collectCommands(child, commands);
  }
  return commands;
}

function simpleCommand(node: Node): SimpleCommand {
  const name = node.childForFieldName("name");
  const parts = [
    ...node.namedChildren.filter(({ type }) => type === "variable_assignment"),
    ...(name === null ? [] : [name]),
    ...node.childrenForFieldName("argument"),
  ];
  const statement = node.parent?.type === REDIRECTED_STATEMENT ? node.parent : node;
  const pipeline = statement.parent?.type === "pipeline" ? statement.parent : undefined;
  return {
    words: parts.map((part) => ({
      start: part.startIndex,
      end: part.endIndex,
      text: wordText(part),
    })),
    redirections: [
      ...fileRedirections(node),
      ...(statement === node ? [] : statementRedirections(statement)),
    ],
    piped: pipeline !== undefined && !pipeline.firstNamedChild?.equals(statement),
  };
}

function statementRedirections(statement: Node): Redirection[] {
  return statement
    .childrenForFieldName("redirect")
    .flatMap((redirect) => [...redirection(redirect), ...fileRedirections(redirect)]);
}

// A heredoc operator can carry another redirection, as in cat <<EOF > file
function fileRedirections(node: Node): Redirection[] {
  return node.namedChildren.flatMap((child) => {
    if (REDIRECTION_OWNERS.has(child.type)) {
      return [];
    }
    return [...redirection(child), ...fileRedirections(child)];
  });
}

// Files only: 2>&1 and <&3 copy a descriptor
function redirection(node: Node): Redirection[] {
  const destination = node.childForFieldName("destination");
  const operator = node.children.find(({ isNamed }) => !isNamed)?.type;
  if (node.type !== FILE_REDIRECT || destination === null || operator === undefined) {
    return [];
  }
  const target = wordText(destination);
  if (operator.endsWith("&") && DESCRIPTOR.test(target)) {
    return [];
  }
  return [{ kind: operator.startsWith("<") ? "read" : "write", target }];
}

/** The text of a word once quotes and escapes are removed, expansions stay as written */
function wordText(node: Node): string {
  switch (node.type) {
    case "word":
      return node.text.replace(BACKSLASH_ESCAPE, "$1");
    case "raw_string":
      return node.text.slice(1, -1);
    case "string":
      return node.text.slice(1, -1).replace(BACKSLASH_ESCAPE, "$1");
    case "ansi_c_string":
      return node.text.slice(2, -1);
    case "concatenation":
    case "command_name":
      return node.children.map(wordText).join("");
    default:
      return node.text;
  }
}
