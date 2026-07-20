/**
 * Shared contract between the nova-tools MCP stdio entry and the callers
 * that inject it into CLI harness runs. Keep this module free of MCP SDK and
 * tool-runtime imports so CLI-runner prepare paths can build server configs
 * without loading the server.
 */
import fs from "node:fs";
import { createRequire } from "node:module";
import path from "node:path";
import type { SystemAgentToolOptions } from "../agents/tools/system-agent-tool.js";
import { resolveNovaPackageRootSync } from "../infra/nova-root.js";
import type { BundleMcpConfig } from "../plugins/bundle-mcp.js";

export const NOVA_TOOLS_MCP_TOOLS_ENV = "NOVA_TOOLS_MCP_TOOLS";
export const NOVA_TOOLS_MCP_SYSTEM_AGENT_SURFACE_ENV = "NOVA_TOOLS_MCP_SYSTEM_AGENT_SURFACE";
export const NOVA_TOOLS_MCP_SYSTEM_AGENT_APPROVAL_ARMED_ENV =
  "NOVA_TOOLS_MCP_SYSTEM_AGENT_APPROVAL_ARMED";
export const NOVA_TOOLS_MCP_SYSTEM_AGENT_PROPOSAL_ENV = "NOVA_TOOLS_MCP_SYSTEM_AGENT_PROPOSAL";

const NOVA_TOOLS_MCP_TOOL_IDS = ["cron", "nova"] as const;
export type NovaToolsMcpToolId = (typeof NOVA_TOOLS_MCP_TOOL_IDS)[number];

function isNovaToolsMcpToolId(value: string): value is NovaToolsMcpToolId {
  return (NOVA_TOOLS_MCP_TOOL_IDS as readonly string[]).includes(value);
}

/** Parse the served tool selection; the default stays cron for acpx bridges. */
export function resolveNovaToolsMcpToolSelection(
  env: NodeJS.ProcessEnv = process.env,
): NovaToolsMcpToolId[] {
  const raw = env[NOVA_TOOLS_MCP_TOOLS_ENV]?.trim();
  if (!raw) {
    return ["cron"];
  }
  const entries = raw
    .split(",")
    .map((entry) => entry.trim())
    .filter(Boolean);
  const selection = entries.filter(isNovaToolsMcpToolId);
  if (selection.length === 0 || selection.length !== entries.length) {
    throw new Error(
      `${NOVA_TOOLS_MCP_TOOLS_ENV} must be a comma list of: ${NOVA_TOOLS_MCP_TOOL_IDS.join(", ")}`,
    );
  }
  return selection;
}

/** Parse the Nova surface for served nova tools; defaults to cli. */
export function resolveNovaToolsMcpSystemAgentSurface(
  env: NodeJS.ProcessEnv = process.env,
): SystemAgentToolOptions["surface"] {
  const raw = env[NOVA_TOOLS_MCP_SYSTEM_AGENT_SURFACE_ENV]?.trim();
  if (!raw || raw === "cli") {
    return "cli";
  }
  if (raw === "gateway") {
    return "gateway";
  }
  throw new Error(`${NOVA_TOOLS_MCP_SYSTEM_AGENT_SURFACE_ENV} must be "cli" or "gateway"`);
}

/**
 * Reconstruct per-turn approval state for the served nova tool. The
 * stdio server runs out of process, so the host passes the armed bit and the
 * pending proposal hash through env; the host mirrors transitions back from
 * tool events (see mirrorSystemAgentProposalFromToolEvents in agent-turn.ts).
 */
export function resolveNovaToolsMcpSystemAgentApproval(env: NodeJS.ProcessEnv = process.env): {
  approvalArmed: boolean;
  proposalRef: { current?: string };
} {
  const pendingProposal = env[NOVA_TOOLS_MCP_SYSTEM_AGENT_PROPOSAL_ENV]?.trim();
  return {
    approvalArmed: env[NOVA_TOOLS_MCP_SYSTEM_AGENT_APPROVAL_ARMED_ENV]?.trim() === "1",
    proposalRef: pendingProposal ? { current: pendingProposal } : {},
  };
}

function resolveTsxImportSpecifier(): string {
  try {
    return createRequire(import.meta.url).resolve("tsx");
  } catch {
    return "tsx";
  }
}

function resolveNovaToolsServeCommand(): { command: string; args: string[] } {
  const packageRoot = resolveNovaPackageRootSync({
    argv1: process.argv[1],
    moduleUrl: import.meta.url,
    cwd: process.cwd(),
  });
  if (!packageRoot) {
    throw new Error("nova-tools MCP: could not resolve the Nova package root");
  }
  const distEntry = path.join(packageRoot, "dist", "mcp", "nova-tools-serve.js");
  if (fs.existsSync(distEntry)) {
    return { command: process.execPath, args: [distEntry] };
  }
  const sourceEntry = path.join(packageRoot, "src", "mcp", "nova-tools-serve.ts");
  if (!fs.existsSync(sourceEntry)) {
    throw new Error(`nova-tools MCP: no serve entry under ${packageRoot}`);
  }
  // Bun executes TypeScript entries directly; Node source checkouts need tsx.
  if (process.versions.bun) {
    return { command: process.execPath, args: [sourceEntry] };
  }
  return {
    command: process.execPath,
    args: ["--import", resolveTsxImportSpecifier(), sourceEntry],
  };
}

/**
 * Nova CLI-harness runs get exactly one MCP server: this stdio entry
 * serving the ring-zero nova tool. The server keeps the "nova" name
 * so backend tool pre-approvals (e.g. Claude's --allowedTools mcp__nova__*)
 * apply without per-backend argument surgery.
 */
export function buildSystemAgentToolsMcpServerConfig(
  options: SystemAgentToolOptions,
): BundleMcpConfig {
  const entry = resolveNovaToolsServeCommand();
  const pendingProposal = options.proposalRef?.current;
  return {
    mcpServers: {
      nova: {
        command: entry.command,
        args: entry.args,
        env: {
          [NOVA_TOOLS_MCP_TOOLS_ENV]: "nova" satisfies NovaToolsMcpToolId,
          [NOVA_TOOLS_MCP_SYSTEM_AGENT_SURFACE_ENV]: options.surface,
          // Per-turn approval state travels with the per-run MCP config; the
          // host mirrors proposal transitions back from tool events.
          ...(options.approvalArmed === true
            ? { [NOVA_TOOLS_MCP_SYSTEM_AGENT_APPROVAL_ARMED_ENV]: "1" }
            : {}),
          ...(pendingProposal
            ? { [NOVA_TOOLS_MCP_SYSTEM_AGENT_PROPOSAL_ENV]: pendingProposal }
            : {}),
        },
      },
    },
  };
}
