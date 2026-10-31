import { deletionRisk } from "./delete.ts";
import { gitRisk } from "./git.ts";
import { installRisk } from "./install.ts";
import { Project, leadingCd, readRisk } from "./read.ts";
import { isFetcher, runsUnseenCode } from "./remote.ts";
import { secretRisk } from "./secret.ts";
import type { Parser } from "web-tree-sitter";
import {
  inlineScript,
  loadBashParser,
  programPositions,
  redirectionTargets,
  splitCommands,
} from "./shell.ts";
import { isRm, rewriteRm, trashAvailable } from "./trash.ts";
import type { GuardOptions, SimpleCommand, Verdict, Word } from "./types.ts";

// bash -c nested deeper than this goes unchecked
const MAX_NESTING = 3;

const UNPARSEABLE = "the command could not be parsed, so bash-guard checked none of it";
const PARSER_MISSING = "bash-guard cannot load its shell parser: run mise run hooks:deps";
const UNSEEN_REMOTE_CODE = "running code fetched from the network skips any review";

// Denies reads, which the agent retries with its file tools, asks before risky commands, trashes rm
export async function checkCommand(command: string, options: GuardOptions): Promise<Verdict> {
  const parser = await loadBashParser().catch(() => undefined);
  if (parser === undefined) {
    return { action: "deny", reason: PARSER_MISSING };
  }
  const { reads, risks, rmWords } = new Inspection(parser, command, options);
  if (reads.size > 0) {
    return { action: "deny", reason: sentences(reads) };
  }
  const rewritten = rmWords.length > 0 && trashAvailable() ? rewriteRm(command, rmWords) : command;
  if (risks.size > 0) {
    return { action: "ask", command: rewritten, reason: sentences(risks) };
  }
  return { action: "run", command: rewritten };
}

class Inspection {
  readonly risks = new Set<string>();
  readonly reads = new Set<string>();
  readonly rmWords: Word[] = [];
  private readonly parser: Parser;
  private readonly project: Project;
  private readonly readTools: boolean;
  private workdir: string;
  private fetches = false;
  private runsUnseenCode = false;

  constructor(parser: Parser, command: string, { cwd, readTools }: GuardOptions) {
    this.parser = parser;
    this.project = new Project(cwd);
    this.readTools = readTools;
    this.workdir = cwd;
    this.inspectScript(command, 0);
    if (this.fetches && this.runsUnseenCode) {
      this.risks.add(UNSEEN_REMOTE_CODE);
    }
  }

  private inspectScript(script: string, depth: number): void {
    const commands = splitCommands(this.parser, script);
    if (commands === undefined) {
      this.risks.add(UNPARSEABLE);
      return;
    }
    if (depth === 0 && this.readTools) {
      this.workdir = leadingCd(commands, this.project.cwd) ?? this.project.cwd;
    }
    for (const command of commands) {
      this.inspectCommand(command, depth);
    }
  }

  private inspectCommand(command: SimpleCommand, depth: number): void {
    collect(this.risks, secretRisk(redirectionTargets(command, "read", "write")));
    for (const position of programPositions(command.words)) {
      const [program, ...args] = command.words.slice(position).map(({ text }) => text);
      for (const risk of [gitRisk, installRisk, deletionRisk]) {
        collect(this.risks, risk(program, args));
      }
      collect(this.risks, secretRisk(args));
      if (this.readTools) {
        collect(this.reads, readRisk(command, position, this.project, this.workdir));
      }
      const script = inlineScript(program, args);
      this.fetches ||= isFetcher(program);
      this.runsUnseenCode ||= runsUnseenCode(program, args, script);

      // Nested scripts carry no offsets into the command line, so the rewrite only reaches top-level rm
      if (depth === 0 && isRm(program)) {
        this.rmWords.push(command.words[position]);
      }

      if (script !== undefined && depth < MAX_NESTING) {
        this.inspectScript(script, depth + 1);
      }
    }
  }
}

function collect(reasons: Set<string>, reason: string | undefined): void {
  if (reason !== undefined) {
    reasons.add(reason);
  }
}

function sentences(reasons: ReadonlySet<string>): string {
  return `${[...reasons].join(". ")}.`;
}
