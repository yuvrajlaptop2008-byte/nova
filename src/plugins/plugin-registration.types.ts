import type { IncomingMessage, ServerResponse } from "node:http";
import type { Duplex } from "node:stream";
import type { Command } from "commander";
import type { NovaConfig } from "../config/types.nova.js";
import type {
  DiagnosticEventPrivateData,
  DiagnosticEventInput,
  DiagnosticEventMetadata,
  DiagnosticEventPayload,
} from "../infra/diagnostic-events.js";
import type { SecurityAuditFinding } from "../security/audit.types.js";
import type { PluginLogger } from "./logger-types.js";

type ChannelPlugin = import("../channels/plugins/types.plugin.js").ChannelPlugin;

type PluginInteractiveHandlerResult = {
  handled?: boolean;
} | void;

export type PluginInteractiveRegistration<
  TContext = unknown,
  TChannel extends string = string,
  TResult = PluginInteractiveHandlerResult,
> = {
  channel: TChannel;
  namespace: string;
  handler: (ctx: TContext) => Promise<TResult> | TResult;
};

export type PluginInteractiveHandlerRegistration = PluginInteractiveRegistration;

export type NovaPluginHttpRouteAuth = "gateway" | "plugin";
export type NovaPluginHttpRouteMatch = "exact" | "prefix";
export type NovaPluginGatewayRuntimeScopeSurface = "write-default" | "trusted-operator";

export type NovaPluginHttpRouteHandler = (
  req: IncomingMessage,
  res: ServerResponse,
) => Promise<boolean | void> | boolean | void;

export type NovaPluginHttpRouteUpgradeHandler = (
  req: IncomingMessage,
  socket: Duplex,
  head: Buffer,
) => Promise<boolean | void> | boolean | void;

export type NovaPluginHttpRouteParams = {
  path: string;
  handler: NovaPluginHttpRouteHandler;
  handleUpgrade?: NovaPluginHttpRouteUpgradeHandler;
  auth: NovaPluginHttpRouteAuth;
  match?: NovaPluginHttpRouteMatch;
  gatewayRuntimeScopeSurface?: NovaPluginGatewayRuntimeScopeSurface;
  nodeCapability?: {
    surface: string;
    ttlMs?: number;
  };
  replaceExisting?: boolean;
};

export type NovaPluginHostedMediaResolver = (
  mediaUrl: string,
) => string | null | undefined | Promise<string | null | undefined>;

export type NovaPluginCliContext = {
  /**
   * Command object where this plugin should register its commands.
   *
   * For root CLI registrations this is the root `nova` program. For nested
   * registrations it is the resolved parent command from `parentPath`.
   */
  program: Command;
  parentPath: readonly string[];
  config: NovaConfig;
  workspaceDir?: string;
  logger: PluginLogger;
};

export type NovaPluginCliRegistrar = (ctx: NovaPluginCliContext) => void | Promise<void>;

/**
 * Top-level CLI metadata for plugin-owned commands.
 *
 * Descriptors are the parse-time contract for lazy plugin CLI registration.
 * If you want Nova to keep a plugin command lazy-loaded while still
 * advertising it at the root CLI level, provide descriptors that cover every
 * top-level command root registered by that plugin CLI surface.
 */
export type NovaPluginCliCommandDescriptor = {
  name: string;
  description: string;
  hasSubcommands: boolean;
};

export type NovaPluginNodeCliFeatureOptions = {
  /** Explicit node feature command names owned under `nova nodes`. */
  commands?: string[];
  /**
   * Parse-time command descriptors for lazy node feature CLI registration.
   *
   * Descriptors are registered under `nova nodes`, so a descriptor named
   * `"camera"` exposes `nova nodes camera`.
   */
  descriptors?: NovaPluginCliCommandDescriptor[];
};

export type NovaPluginReloadRegistration = {
  restartPrefixes?: string[];
  hotPrefixes?: string[];
  noopPrefixes?: string[];
};

export type {
  NovaPluginNodeHostCommand,
  NovaPluginNodeHostCommandAvailabilityContext,
  NovaPluginNodeHostCommandIo,
} from "./types.node-host.js";

export type NovaPluginNodeInvokeTransportResult =
  | {
      ok: true;
      payload?: unknown;
      payloadJSON?: string | null;
    }
  | {
      ok: false;
      code?: string;
      message: string;
      details?: Record<string, unknown>;
    };

type NovaPluginNodeInvokeApprovalDecision = "allow-once" | "allow-always" | "deny";

type NovaPluginNodeInvokePolicyApprovalRuntime = {
  request: (input: {
    title: string;
    description: string;
    severity?: "info" | "warning" | "critical";
    toolName?: string;
    toolCallId?: string;
    agentId?: string;
    sessionKey?: string;
    timeoutMs?: number;
  }) => Promise<{
    id?: string;
    decision?: NovaPluginNodeInvokeApprovalDecision | null;
  }>;
};

export type NovaPluginNodeInvokePolicyContext = {
  nodeId: string;
  command: string;
  params: unknown;
  timeoutMs?: number;
  idempotencyKey?: string;
  config: NovaConfig;
  pluginConfig?: Record<string, unknown>;
  node?: {
    nodeId: string;
    displayName?: string;
    platform?: string;
    deviceFamily?: string;
    commands?: string[];
  };
  client?: {
    connId?: string;
    scopes?: string[];
  } | null;
  approvals?: NovaPluginNodeInvokePolicyApprovalRuntime;
  invokeNode: (input?: {
    params?: unknown;
    timeoutMs?: number;
    idempotencyKey?: string;
  }) => Promise<NovaPluginNodeInvokeTransportResult>;
};

export type NovaPluginNodeInvokePolicyResult =
  | {
      ok: true;
      payload?: unknown;
      payloadJSON?: string | null;
    }
  | {
      ok: false;
      message: string;
      code?: string;
      details?: Record<string, unknown>;
      unavailable?: boolean;
    };

export type NovaPluginNodeInvokePolicy = {
  commands: string[];
  /**
   * Platforms where these node-handled commands should be allowlisted by default.
   * Omit for commands that require explicit `gateway.nodes.allowCommands`.
   */
  defaultPlatforms?: Array<"ios" | "android" | "macos" | "windows" | "linux" | "unknown">;
  /**
   * Dangerous policy commands are filtered out of default allowlists unless
   * explicitly allowed by config.
   */
  dangerous?: boolean;
  /**
   * iOS foreground-restricted commands should be queued for foreground delivery
   * when an iOS node reports BACKGROUND_UNAVAILABLE.
   */
  foregroundRestrictedOnIos?: boolean;
  handle: (
    ctx: NovaPluginNodeInvokePolicyContext,
  ) => Promise<NovaPluginNodeInvokePolicyResult> | NovaPluginNodeInvokePolicyResult;
};

export type NovaPluginSecurityAuditContext = {
  config: NovaConfig;
  sourceConfig: NovaConfig;
  env: NodeJS.ProcessEnv;
  stateDir: string;
  configPath: string;
};

export type NovaPluginSecurityAuditCollector = (
  ctx: NovaPluginSecurityAuditContext,
) => SecurityAuditFinding[] | Promise<SecurityAuditFinding[]>;

export type NovaGatewayDiscoveryAdvertiseContext = {
  machineDisplayName: string;
  gatewayPort: number;
  gatewayTlsEnabled: boolean;
  gatewayTlsFingerprintSha256?: string;
  gatewayDirectReachable: boolean;
  canvasPort?: number;
  tailnetDns?: string;
  sshPort?: number;
  cliPath?: string;
  minimal: boolean;
};

export type NovaGatewayDiscoveryService = {
  id: string;
  advertise: (
    ctx: NovaGatewayDiscoveryAdvertiseContext,
  ) => void | Promise<void | { stop?: () => void | Promise<void> }>;
};

/** Context passed to long-lived plugin services. */
export type NovaPluginServiceContext = {
  config: NovaConfig;
  workspaceDir?: string;
  stateDir: string;
  logger: PluginLogger;
  gatewayEvents?: import("./gateway-events.js").NovaPluginGatewayEvents;
  startupTrace?: {
    detail?: (name: string, metrics: ReadonlyArray<readonly [string, number | string]>) => void;
    measure: <T>(name: string, run: () => T | Promise<T>) => Promise<T>;
  };
  internalDiagnostics?: {
    emit: (event: DiagnosticEventInput, privateData?: DiagnosticEventPrivateData) => void;
    onEvent: (
      listener: (
        event: DiagnosticEventPayload,
        metadata: DiagnosticEventMetadata,
        privateData: DiagnosticEventPrivateData,
      ) => void,
    ) => () => void;
  };
};

/** Background service registered by a plugin during `register(api)`. */
export type NovaPluginService = {
  id: string;
  start: (ctx: NovaPluginServiceContext) => void | Promise<void>;
  stop?: (ctx: NovaPluginServiceContext) => void | Promise<void>;
};

export type NovaPluginChannelRegistration = {
  plugin: ChannelPlugin;
};

/**
 * Public label exposed to plugin `register(api)` calls.
 *
 * Keep this as a compatibility signal for plugin authors. Loader internals
 * should derive explicit capability booleans from the mode instead of branching
 * on raw strings throughout the code path.
 *
 * - `full`: live runtime activation; long-lived side effects may start.
 * - `discovery`: read-only capability discovery; skip sockets/workers/clients.
 * - `tool-discovery`: capability discovery for executable tools; skip channel runtime hydration.
 * - `setup-only`: lightweight channel setup entry only.
 * - `setup-runtime`: setup flow that also needs the runtime channel entry.
 * - `cli-metadata`: CLI command metadata collection.
 */
export type PluginRegistrationMode =
  | "full"
  | "discovery"
  | "tool-discovery"
  | "setup-only"
  | "setup-runtime"
  | "cli-metadata";
