import { isToolCallEventType, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { checkCommand } from "./guard.ts";

const APPROVE = "Yes";
const REFUSE = "No";

// Pi has read, grep, find and ls tools, so file reads through bash are denied
export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event, ctx) => {
    if (!isToolCallEventType("bash", event)) {
      return undefined;
    }
    const verdict = await checkCommand(event.input.command, { cwd: ctx.cwd, readTools: true });
    if (verdict.action !== "deny") {
      event.input.command = verdict.command;
    }
    if (verdict.action === "run") {
      return undefined;
    }
    const blocked = { block: true, reason: verdict.reason };
    if (verdict.action === "deny" || !ctx.hasUI) {
      return blocked;
    }
    const answer = await ctx.ui.select(`${verdict.reason}\n\n  ${verdict.command}\n\nAllow?`, [
      APPROVE,
      REFUSE,
    ]);
    return answer === APPROVE ? undefined : blocked;
  });
}
