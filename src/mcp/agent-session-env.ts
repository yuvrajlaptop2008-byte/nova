export const NOVA_TOOLS_MCP_AGENT_SESSION_KEY_ENV = "NOVA_TOOLS_MCP_AGENT_SESSION_KEY";

export function resolveToolsMcpAgentSessionKey(
  env: NodeJS.ProcessEnv = process.env,
): string | undefined {
  return env[NOVA_TOOLS_MCP_AGENT_SESSION_KEY_ENV]?.trim() || undefined;
}
