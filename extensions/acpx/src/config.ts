/**
 * Resolves ACPX plugin config from raw user configuration. It locates the
 * plugin root, injects optional MCP bridge servers, and applies runtime defaults.
 */
import fs from "node:fs";
import { createRequire } from "node:module";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { formatPluginConfigIssue } from "nova/plugin-sdk/extension-shared";
import { normalizeLowercaseStringOrEmpty } from "nova/plugin-sdk/string-coerce-runtime";
import { AcpxPluginConfigSchema, DEFAULT_ACPX_TIMEOUT_SECONDS } from "./config-schema.js";
import type {
  AcpxPluginConfig,
  AcpxPermissionMode,
  AcpxNonInteractivePermissionPolicy,
  McpServerConfig,
  AcpxMcpServer,
  ResolvedAcpxPluginConfig,
} from "./config-schema.js";
export { type ResolvedAcpxPluginConfig } from "./config-schema.js";

const ACPX_PLUGIN_TOOLS_MCP_SERVER_NAME = "nova-plugin-tools";
const ACPX_NOVA_TOOLS_MCP_SERVER_NAME = "nova-tools";
const requireFromHere = createRequire(import.meta.url);

function isAcpxPluginRoot(dir: string): boolean {
  return (
    fs.existsSync(path.join(dir, "nova.plugin.json")) &&
    fs.existsSync(path.join(dir, "package.json"))
  );
}

function resolveNearestAcpxPluginRoot(moduleUrl: string): string {
  let cursor = path.dirname(fileURLToPath(moduleUrl));
  for (let i = 0; i < 3; i += 1) {
    // Bundled entries live at the plugin root while source files still live under src/.
    if (isAcpxPluginRoot(cursor)) {
      return cursor;
    }
    const parent = path.dirname(cursor);
    if (parent === cursor) {
      break;
    }
    cursor = parent;
  }
  return path.resolve(path.dirname(fileURLToPath(moduleUrl)), "..");
}

function resolveWorkspaceAcpxPluginRoot(currentRoot: string): string | null {
  if (
    path.basename(currentRoot) !== "acpx" ||
    path.basename(path.dirname(currentRoot)) !== "extensions" ||
    path.basename(path.dirname(path.dirname(currentRoot))) !== "dist"
  ) {
    return null;
  }
  const workspaceRoot = path.resolve(currentRoot, "..", "..", "..", "extensions", "acpx");
  return isAcpxPluginRoot(workspaceRoot) ? workspaceRoot : null;
}

function resolveRepoAcpxPluginRoot(currentRoot: string): string | null {
  const workspaceRoot = path.join(currentRoot, "extensions", "acpx");
  return isAcpxPluginRoot(workspaceRoot) ? workspaceRoot : null;
}

function resolveAcpxPluginRootFromNovaLayout(moduleUrl: string): string | null {
  let cursor = path.dirname(fileURLToPath(moduleUrl));
  for (let i = 0; i < 5; i += 1) {
    const candidates = [
      path.join(cursor, "extensions", "acpx"),
      path.join(cursor, "dist", "extensions", "acpx"),
      path.join(cursor, "dist-runtime", "extensions", "acpx"),
    ];
    for (const candidate of candidates) {
      if (isAcpxPluginRoot(candidate)) {
        return candidate;
      }
    }
    const parent = path.dirname(cursor);
    if (parent === cursor) {
      break;
    }
    cursor = parent;
  }
  return null;
}
/** Resolve the ACPX plugin root across source, dist, and dist-runtime layouts. */
export function resolveAcpxPluginRoot(moduleUrl: string = import.meta.url): string {
  const resolvedRoot = resolveNearestAcpxPluginRoot(moduleUrl);
  // In a live repo checkout, dist/ can be rebuilt out from under the running gateway.
  // Prefer the stable source plugin root when a built extension is running beside it.
  return (
    resolveWorkspaceAcpxPluginRoot(resolvedRoot) ??
    resolveRepoAcpxPluginRoot(resolvedRoot) ??
    // Shared dist/dist-runtime chunks can load this module outside the plugin tree.
    // Scan common Nova layouts before falling back to the nearest path guess.
    resolveAcpxPluginRootFromNovaLayout(moduleUrl) ??
    resolvedRoot
  );
}

const DEFAULT_PERMISSION_MODE: AcpxPermissionMode = "approve-reads";
const DEFAULT_NON_INTERACTIVE_POLICY: AcpxNonInteractivePermissionPolicy = "fail";
const DEFAULT_QUEUE_OWNER_TTL_SECONDS = 0.1;
const DEFAULT_STRICT_WINDOWS_CMD_WRAPPER = true;

type ParseResult =
  | { ok: true; value: AcpxPluginConfig | undefined }
  | { ok: false; message: string };

function parseAcpxPluginConfig(value: unknown): ParseResult {
  if (value === undefined) {
    return { ok: true, value: undefined };
  }
  const parsed = AcpxPluginConfigSchema.safeParse(value);
  if (!parsed.success) {
    return { ok: false, message: formatPluginConfigIssue(parsed.error.issues[0]) };
  }
  return {
    ok: true,
    value: parsed.data as AcpxPluginConfig,
  };
}

function resolveNovaRoot(currentRoot: string): string {
  if (
    path.basename(currentRoot) === "acpx" &&
    path.basename(path.dirname(currentRoot)) === "extensions"
  ) {
    const parent = path.dirname(path.dirname(currentRoot));
    if (path.basename(parent) === "dist") {
      return path.dirname(parent);
    }
    return parent;
  }
  return path.resolve(currentRoot, "..");
}

function resolveTsxImportSpecifier(): string {
  try {
    return requireFromHere.resolve("tsx");
  } catch {
    return "tsx";
  }
}

function shellQuoteCommandArg(arg: string): string {
  if (!/[\s'"\\$|&;<>{}()*?[\]~`]/.test(arg)) {
    return arg;
  }
  return `'${arg.replace(/'/g, "'\"'\"'")}'`;
}

function resolvePluginToolsMcpServerConfig(moduleUrl: string = import.meta.url): McpServerConfig {
  const pluginRoot = resolveAcpxPluginRoot(moduleUrl);
  const novaRoot = resolveNovaRoot(pluginRoot);
  const distEntry = path.join(novaRoot, "dist", "mcp", "plugin-tools-serve.js");
  if (fs.existsSync(distEntry)) {
    return {
      command: process.execPath,
      args: [distEntry],
    };
  }
  const sourceEntry = path.join(novaRoot, "src", "mcp", "plugin-tools-serve.ts");
  return {
    command: process.execPath,
    args: ["--import", resolveTsxImportSpecifier(), sourceEntry],
  };
}

function resolveNovaToolsMcpServerConfig(moduleUrl: string = import.meta.url): McpServerConfig {
  const pluginRoot = resolveAcpxPluginRoot(moduleUrl);
  const novaRoot = resolveNovaRoot(pluginRoot);
  const distEntry = path.join(novaRoot, "dist", "mcp", "nova-tools-serve.js");
  if (fs.existsSync(distEntry)) {
    return {
      command: process.execPath,
      args: [distEntry],
    };
  }
  const sourceEntry = path.join(novaRoot, "src", "mcp", "nova-tools-serve.ts");
  return {
    command: process.execPath,
    args: ["--import", resolveTsxImportSpecifier(), sourceEntry],
  };
}

function resolveConfiguredMcpServers(params: {
  mcpServers?: Record<string, McpServerConfig>;
  pluginToolsMcpBridge: boolean;
  novaToolsMcpBridge: boolean;
  moduleUrl?: string;
}): Record<string, McpServerConfig> {
  const resolved = { ...params.mcpServers };
  if (params.pluginToolsMcpBridge && resolved[ACPX_PLUGIN_TOOLS_MCP_SERVER_NAME]) {
    throw new Error(
      `mcpServers.${ACPX_PLUGIN_TOOLS_MCP_SERVER_NAME} is reserved when pluginToolsMcpBridge=true`,
    );
  }
  if (params.novaToolsMcpBridge && resolved[ACPX_NOVA_TOOLS_MCP_SERVER_NAME]) {
    throw new Error(
      `mcpServers.${ACPX_NOVA_TOOLS_MCP_SERVER_NAME} is reserved when novaToolsMcpBridge=true`,
    );
  }
  if (params.pluginToolsMcpBridge) {
    resolved[ACPX_PLUGIN_TOOLS_MCP_SERVER_NAME] = resolvePluginToolsMcpServerConfig(
      params.moduleUrl,
    );
  }
  if (params.novaToolsMcpBridge) {
    resolved[ACPX_NOVA_TOOLS_MCP_SERVER_NAME] = resolveNovaToolsMcpServerConfig(params.moduleUrl);
  }
  return resolved;
}

/** Convert Nova MCP server config into ACPX runtime MCP server entries. */
export function toAcpMcpServers(mcpServers: Record<string, McpServerConfig>): AcpxMcpServer[] {
  return Object.entries(mcpServers).map(([name, server]) => ({
    name,
    command: server.command,
    args: [...(server.args ?? [])],
    env: Object.entries(server.env ?? {}).map(([envName, value]) => ({
      name: envName,
      value,
    })),
  }));
}

/** Validate and normalize raw ACPX plugin config for runtime startup. */
export function resolveAcpxPluginConfig(params: {
  rawConfig: unknown;
  workspaceDir?: string;
  moduleUrl?: string;
}): ResolvedAcpxPluginConfig {
  const parsed = parseAcpxPluginConfig(params.rawConfig);
  if (!parsed.ok) {
    throw new Error(parsed.message);
  }
  const normalized = parsed.value ?? {};
  const workspaceDir = params.workspaceDir?.trim() || process.cwd();
  const fallbackCwd = workspaceDir;
  const cwd = path.resolve(normalized.cwd?.trim() || fallbackCwd);
  const stateDir = path.resolve(normalized.stateDir?.trim() || path.join(workspaceDir, "state"));
  const pluginToolsMcpBridge = normalized.pluginToolsMcpBridge === true;
  const novaToolsMcpBridge = normalized.novaToolsMcpBridge === true;
  const mcpServers = resolveConfiguredMcpServers({
    mcpServers: normalized.mcpServers,
    pluginToolsMcpBridge,
    novaToolsMcpBridge,
    moduleUrl: params.moduleUrl,
  });
  const agents = Object.fromEntries(
    Object.entries(normalized.agents ?? {}).map(([name, entry]) => {
      const cmd = entry.command.trim();
      const cmdArgs = entry.args ?? [];
      const fullCommand =
        cmdArgs.length > 0 ? `${cmd} ${cmdArgs.map(shellQuoteCommandArg).join(" ")}` : cmd;
      return [normalizeLowercaseStringOrEmpty(name), fullCommand];
    }),
  );

  return {
    cwd,
    stateDir,
    probeAgent: normalized.probeAgent,
    permissionMode: normalized.permissionMode ?? DEFAULT_PERMISSION_MODE,
    nonInteractivePermissions:
      normalized.nonInteractivePermissions ?? DEFAULT_NON_INTERACTIVE_POLICY,
    pluginToolsMcpBridge,
    novaToolsMcpBridge,
    strictWindowsCmdWrapper:
      normalized.strictWindowsCmdWrapper ?? DEFAULT_STRICT_WINDOWS_CMD_WRAPPER,
    timeoutSeconds: normalized.timeoutSeconds ?? DEFAULT_ACPX_TIMEOUT_SECONDS,
    queueOwnerTtlSeconds: normalized.queueOwnerTtlSeconds ?? DEFAULT_QUEUE_OWNER_TTL_SECONDS,
    legacyCompatibilityConfig: {
      strictWindowsCmdWrapper: normalized.strictWindowsCmdWrapper,
      queueOwnerTtlSeconds: normalized.queueOwnerTtlSeconds,
    },
    mcpServers,
    agents,
  };
}
