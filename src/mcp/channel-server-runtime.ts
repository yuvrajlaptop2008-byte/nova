import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import type { NovaConfig } from "../config/types.nova.js";
import { VERSION } from "../version.js";
import { NovaChannelBridge } from "./channel-bridge.js";
import { ClaudePermissionRequestSchema, type ClaudeChannelMode } from "./channel-shared.js";
import { getChannelMcpCapabilities, registerChannelMcpTools } from "./channel-tools.js";

async function resolveMcpConfig(config: NovaConfig | undefined): Promise<NovaConfig> {
  if (config) {
    return config;
  }
  const { getRuntimeConfig } = await import("../config/config.js");
  return getRuntimeConfig();
}

export async function createChannelMcpRuntime(
  opts: {
    gatewayUrl?: string;
    gatewayToken?: string;
    gatewayPassword?: string;
    config?: NovaConfig;
    claudeChannelMode?: ClaudeChannelMode;
    verbose?: boolean;
  } = {},
): Promise<{
  server: McpServer;
  bridge: NovaChannelBridge;
  start: () => Promise<void>;
  close: () => Promise<void>;
}> {
  const cfg = await resolveMcpConfig(opts.config);
  const claudeChannelMode = opts.claudeChannelMode ?? "auto";
  const capabilities = getChannelMcpCapabilities(claudeChannelMode);
  const server = new McpServer(
    { name: "nova", version: VERSION },
    capabilities ? { capabilities } : undefined,
  );
  const bridge = new NovaChannelBridge(cfg, {
    gatewayUrl: opts.gatewayUrl,
    gatewayToken: opts.gatewayToken,
    gatewayPassword: opts.gatewayPassword,
    claudeChannelMode,
    verbose: opts.verbose ?? false,
  });
  bridge.setServer(server);

  server.server.setNotificationHandler(ClaudePermissionRequestSchema, async ({ params }) => {
    await bridge.handleClaudePermissionRequest({
      requestId: params.request_id,
      toolName: params.tool_name,
      description: params.description,
      inputPreview: params.input_preview,
    });
  });
  registerChannelMcpTools(server, bridge);

  return {
    server,
    bridge,
    start: async () => {
      await bridge.start();
    },
    close: async () => {
      await bridge.close();
      await server.close();
    },
  };
}
