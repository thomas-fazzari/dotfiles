import { homedir } from "node:os";
import { basename } from "node:path";
import { expandHome } from "./utils.ts";

const SECRET_NAMES = [
  String.raw`\.env(?!\.(?:example|sample|template|tpl)(?:\.|$))(?:\..+)?`,
  String.raw`\.netrc`,
  String.raw`\.git-credentials`,
  String.raw`id_(?:rsa|ecdsa|ed25519)(?:[-_.](?!pub$).*)?`,
  String.raw`.+\.(?:pem|key|p12)`,
];
const SECRET_NAME = new RegExp(`^(?:${SECRET_NAMES.join("|")})$`, "u");

// Relative to the home directory
const SECRET_HOME_PATHS = [
  String.raw`\.ssh(?:/|$)(?!.*\.pub$)`,
  String.raw`\.config/gh/hosts\.yml`,
  String.raw`\.claude/\.credentials\.json`,
  String.raw`\.pi/agent/auth\.json`,
];
const SECRET_HOME_PATH = new RegExp(`^(?:${SECRET_HOME_PATHS.join("|")})`, "u");

// Paths also hide behind an option, as in --env-file=.env
const OPTION_NAME = /^--?[\w-]+=/u;

export function secretRisk(args: readonly string[]): string | undefined {
  const secret = args.find((arg) => isSecret(expandHome(arg.replace(OPTION_NAME, ""))));
  return secret === undefined ? undefined : `${secret} may hold secrets`;
}

function isSecret(path: string): boolean {
  const home = `${homedir()}/`;
  return (
    SECRET_NAME.test(basename(path)) ||
    (path.startsWith(home) && SECRET_HOME_PATH.test(path.slice(home.length)))
  );
}
