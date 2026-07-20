// Nova MCP tools tests cover core tool server startup and registration.
import { afterEach, describe, expect, it, vi } from "vitest";
import { hashSystemAgentOperation } from "../agents/tools/system-agent-tool.js";
import {
  buildSystemAgentToolsMcpServerConfig,
  NOVA_TOOLS_MCP_SYSTEM_AGENT_APPROVAL_ARMED_ENV,
  NOVA_TOOLS_MCP_SYSTEM_AGENT_PROPOSAL_ENV,
  NOVA_TOOLS_MCP_SYSTEM_AGENT_SURFACE_ENV,
  NOVA_TOOLS_MCP_TOOLS_ENV,
  resolveNovaToolsMcpSystemAgentSurface,
  resolveNovaToolsMcpToolSelection,
} from "./nova-tools-serve-config.js";
import {
  NOVA_TOOLS_MCP_AGENT_SESSION_KEY_ENV,
  resolveNovaToolsForMcp,
  resolveNovaToolsMcpAgentSessionKey,
} from "./nova-tools-serve.js";
import { createPluginToolsMcpHandlers } from "./plugin-tools-handlers.js";

afterEach(() => {
  vi.unstubAllEnvs();
});

describe("Nova tools MCP server", () => {
  it("exposes cron", async () => {
    const handlers = createPluginToolsMcpHandlers(
      resolveNovaToolsForMcp({ agentSessionKey: "agent:worker:main" }),
    );

    const listed = await handlers.listTools();
    expect(listed.tools.map((tool) => tool.name)).toContain("cron");
  });

  it("requires the managed bridge to pass a real agent session key", () => {
    expect(() => resolveNovaToolsForMcp({ agentSessionKey: "" })).toThrow(
      NOVA_TOOLS_MCP_AGENT_SESSION_KEY_ENV,
    );
  });

  it("reads the managed bridge agent session key from env", () => {
    expect(
      resolveNovaToolsMcpAgentSessionKey({
        [NOVA_TOOLS_MCP_AGENT_SESSION_KEY_ENV]: " agent:worker:main ",
      }),
    ).toBe("agent:worker:main");
  });

  it("serves the ring-zero nova tool without an agent session key", async () => {
    const handlers = createPluginToolsMcpHandlers(
      resolveNovaToolsForMcp({ tools: ["nova"], systemAgentSurface: "cli" }),
    );

    const listed = await handlers.listTools();
    expect(listed.tools.map((tool) => tool.name)).toEqual(["nova"]);
  });

  it("returns approved CLI MCP mutations to the host instead of applying them", async () => {
    const operation = { kind: "config-set", path: "gateway.port", value: "19001" } as const;
    vi.stubEnv(NOVA_TOOLS_MCP_SYSTEM_AGENT_APPROVAL_ARMED_ENV, "1");
    vi.stubEnv(NOVA_TOOLS_MCP_SYSTEM_AGENT_PROPOSAL_ENV, hashSystemAgentOperation(operation));
    const handlers = createPluginToolsMcpHandlers(
      resolveNovaToolsForMcp({ tools: ["nova"], systemAgentSurface: "cli" }),
    );

    const result = await handlers.callTool({
      name: "nova",
      arguments: {
        action: "config_set",
        path: "gateway.port",
        value: "19001",
        approved: true,
      },
    });

    expect(JSON.stringify(result)).toContain("directive:approved-operation:");
  });

  it("parses the served tool selection from env and defaults to cron", () => {
    expect(resolveNovaToolsMcpToolSelection({})).toEqual(["cron"]);
    expect(
      resolveNovaToolsMcpToolSelection({
        [NOVA_TOOLS_MCP_TOOLS_ENV]: " nova , cron ",
      }),
    ).toEqual(["nova", "cron"]);
    expect(() => resolveNovaToolsMcpToolSelection({ [NOVA_TOOLS_MCP_TOOLS_ENV]: "exec" })).toThrow(
      NOVA_TOOLS_MCP_TOOLS_ENV,
    );
  });

  it("parses the nova surface from env and defaults to cli", () => {
    expect(resolveNovaToolsMcpSystemAgentSurface({})).toBe("cli");
    expect(
      resolveNovaToolsMcpSystemAgentSurface({
        [NOVA_TOOLS_MCP_SYSTEM_AGENT_SURFACE_ENV]: "gateway",
      }),
    ).toBe("gateway");
    expect(() =>
      resolveNovaToolsMcpSystemAgentSurface({
        [NOVA_TOOLS_MCP_SYSTEM_AGENT_SURFACE_ENV]: "remote",
      }),
    ).toThrow(NOVA_TOOLS_MCP_SYSTEM_AGENT_SURFACE_ENV);
  });

  it("builds a nova-only stdio server config under the nova name", () => {
    const config = buildSystemAgentToolsMcpServerConfig({ surface: "gateway" });

    expect(Object.keys(config.mcpServers)).toEqual(["nova"]);
    const server = config.mcpServers.nova as {
      command?: string;
      args?: string[];
      env?: Record<string, string>;
    };
    expect(server.command).toBe(process.execPath);
    expect(server.args?.at(-1)).toMatch(/nova-tools-serve\.(js|ts)$/);
    expect(server.env).toEqual({
      [NOVA_TOOLS_MCP_TOOLS_ENV]: "nova",
      [NOVA_TOOLS_MCP_SYSTEM_AGENT_SURFACE_ENV]: "gateway",
    });
  });
});
