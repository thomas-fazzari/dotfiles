import { type Args, firstReason } from "./rules.ts";
import type { Rule } from "./types.ts";
import { isOption, programName } from "./utils.ts";

const INSTALL = "install";
const NODE_INSTALL_ACTIONS = ["i", INSTALL, "add"];

// -S, -Syu and -U install or upgrade, the -S query and cache flags (-Ss, -Si, -Sc...) don't
const PACMAN_SYNC = /^-[SU](?!\w*[silgpc])/u;

const PIP: readonly Rule[] = [
  { reason: "pip install installs software globally", applies: installs },
];

const RULES = new Map<string, readonly Rule[]>([
  ["brew", [{ reason: "brew install installs software globally", applies: installs }]],
  ["npm", [{ reason: "npm install -g installs software globally", applies: installsNodeGlobally }]],
  ["bun", [{ reason: "bun add -g installs software globally", applies: installsNodeGlobally }]],
  ["cargo", [{ reason: "cargo install installs software globally", applies: installs }]],
  ["pip", PIP],
  ["pip3", PIP],
  [
    "uv",
    [
      {
        reason: "uv tool install installs software globally",
        applies: (args) => args.action("tool") && args.list.at(1) === INSTALL,
      },
    ],
  ],
  [
    "mise",
    [
      {
        reason: "mise use -g installs software globally",
        applies: (args) => args.action("use") && isGlobal(args),
      },
    ],
  ],
  ["pacman", [{ reason: "pacman -S installs software globally", applies: pacmanSyncs }]],
  ["paru", [{ reason: "paru -S installs software globally", applies: pacmanSyncs }]],
]);

export function installRisk(program: string, args: readonly string[]): string | undefined {
  return firstReason(RULES, programName(program), args);
}

function isGlobal(args: Args): boolean {
  return args.flag("--global", "-g");
}

function installs(args: Args): boolean {
  return args.action(INSTALL);
}

function installsNodeGlobally(args: Args): boolean {
  return args.action(...NODE_INSTALL_ACTIONS) && isGlobal(args);
}

// Bare paru upgrades everything, paru <term> searches then installs
function pacmanSyncs({ list }: Args): boolean {
  return list.length === 0 || !isOption(list[0]) || list.some((arg) => PACMAN_SYNC.test(arg));
}
