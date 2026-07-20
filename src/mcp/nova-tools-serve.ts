/**
 * Standalone MCP server for selected built-in Nova tools.
 *
 * Run via: node --import tsx src/mcp/nova-tools-serve.ts
 * Or: bun src/mcp/nova-tools-serve.ts
 */
import { pathToFileURL } from "node:url";
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import type { AnyAgentTool } from "../agents/tools/common.js";
import { createCronTool } from "../agents/tools/cron-tool.js";
import { createSystemAgentTool } from "../agents/tools/system-agent-tool.js";
import type { SystemAgentToolOptions } from "../agents/tools/system-agent-tool.js";
import { formatErrorMessage } from "../infra/errors.js";
import {
  NOVA_TOOLS_MCP_AGENT_SESSION_KEY_ENV,
  resolveToolsMcpAgentSessionKey,
} from "./agent-session-env.js";
import {
  resolveNovaToolsMcpSystemAgentApproval,
  resolveNovaToolsMcpSystemAgentSurface,
  resolveNovaToolsMcpToolSelection,
  type NovaToolsMcpToolId,
} from "./nova-tools-serve-config.js";
import { connectToolsMcpServerToStdio, createToolsMcpServer } from "./tools-stdio-server.js";

export {
  NOVA_TOOLS_MCP_SYSTEM_AGENT_SURFACE_ENV,
  NOVA_TOOLS_MCP_TOOLS_ENV,
} from "./nova-tools-serve-config.js";

export { NOVA_TOOLS_MCP_AGENT_SESSION_KEY_ENV } from "./agent-session-env.js";

export function resolveNovaToolsMcpAgentSessionKey(
  env: NodeJS.ProcessEnv = process.env,
): string | undefined {
  return resolveToolsMcpAgentSessionKey(env);
}

export function resolveNovaToolsForMcp(
  params: {
    agentSessionKey?: string;
    tools?: NovaToolsMcpToolId[];
    systemAgentSurface?: SystemAgentToolOptions["surface"];
  } = {},
): AnyAgentTool[] {
  const selection = params.tools ?? resolveNovaToolsMcpToolSelection();
  return selection.map((tool) => {
    if (tool === "nova") {
      return createSystemAgentTool({
        surface: params.systemAgentSurface ?? resolveNovaToolsMcpSystemAgentSurface(),
        ...resolveNovaToolsMcpSystemAgentApproval(),
      });
    }
    const agentSessionKey = (
      params.agentSessionKey ?? resolveNovaToolsMcpAgentSessionKey()
    )?.trim();
    if (!agentSessionKey) {
      throw new Error(`${NOVA_TOOLS_MCP_AGENT_SESSION_KEY_ENV} is required`);
    }
    return createCronTool({ agentSessionKey, creatorToolAllowlist: [{ name: "cron" }] });
  });
}

function createNovaToolsMcpServer(
  params: {
    tools?: AnyAgentTool[];
  } = {},
): Server {
  const tools = params.tools ?? resolveNovaToolsForMcp();
  return createToolsMcpServer({ name: "nova-tools", tools });
}

async function serveNovaToolsMcp(): Promise<void> {
  const server = createNovaToolsMcpServer();
  await connectToolsMcpServerToStdio(server);
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? "").href) {
  serveNovaToolsMcp().catch((err: unknown) => {
    process.stderr.write(`nova-tools-serve: ${formatErrorMessage(err)}\n`);
    process.exit(1);
  });
}
