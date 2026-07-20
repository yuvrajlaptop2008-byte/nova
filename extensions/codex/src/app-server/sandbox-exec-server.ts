/**
 * Hosts the local Nova sandbox exec-server that Codex app-server native
 * execution can register as an external environment.
 */
import { createHash, randomUUID } from "node:crypto";
import { once } from "node:events";
import type { IncomingMessage } from "node:http";
import { isIP, type AddressInfo } from "node:net";
import { embeddedAgentLog } from "nova/plugin-sdk/agent-harness-runtime";
import type { SandboxContext } from "nova/plugin-sdk/sandbox";
import { WebSocketServer, type RawData, type WebSocket } from "ws";
import type { CodexAppServerClient } from "./client.js";
import type { CodexAppServerStartOptions } from "./config.js";
import type { JsonValue } from "./protocol.js";
import { sandboxExecServerRegistry } from "./sandbox-exec-server-registry.js";
import {
  createDirectory,
  copyPath,
  getMetadata,
  readDirectory,
  readFile,
  removePath,
  writeFile,
} from "./sandbox-exec-server/filesystem.js";
import { httpRequest } from "./sandbox-exec-server/http.js";
import {
  JsonRpcProtocolError,
  parseRequest,
  sendError,
  sendResult,
} from "./sandbox-exec-server/json-rpc.js";
import {
  readProcess,
  startProcess,
  terminateProcess,
  writeProcess,
} from "./sandbox-exec-server/processes.js";
import type {
  JsonRpcRequest,
  ManagedProcess,
  NovaExecServer,
} from "./sandbox-exec-server/types.js";

/** Codex environment metadata registered for one sandbox exec-server lease. */
export type CodexSandboxExecEnvironment = {
  environmentId: string;
  cwd: string;
};

const CODEX_SANDBOX_EXEC_SERVER_MAX_INBOUND_MESSAGE_BYTES = 100 * 1024 * 1024;

/** Starts or reuses a sandbox exec-server and registers it with Codex app-server. */
export async function ensureCodexSandboxExecServerEnvironment(params: {
  client: CodexAppServerClient;
  sandbox: SandboxContext | null;
  appServerStartOptions?: CodexAppServerStartOptions;
  timeoutMs?: number;
  signal?: AbortSignal;
}): Promise<CodexSandboxExecEnvironment | undefined> {
  if (!params.sandbox?.enabled || !params.sandbox.backend) {
    return undefined;
  }
  if (!canExposeLocalExecServerToAppServer(params.appServerStartOptions)) {
    throw new Error(
      "Nova Codex exec-server uses a local loopback URL and cannot be registered with a remote Codex app-server.",
    );
  }
  const execServer = await acquireNovaExecServer(params.sandbox);
  try {
    await params.client.request(
      "environment/add",
      {
        environmentId: execServer.environmentId,
        execServerUrl: execServer.url,
      },
      { timeoutMs: params.timeoutMs, signal: params.signal },
    );
  } catch (error) {
    await releaseNovaExecServer(execServer);
    if (isEnvironmentAddUnsupported(error)) {
      embeddedAgentLog.warn("codex app-server does not support remote environments yet", {
        environmentId: execServer.environmentId,
      });
      return undefined;
    }
    throw error;
  }
  return {
    environmentId: execServer.environmentId,
    cwd: params.sandbox.containerWorkdir,
  };
}

/** Releases the sandbox exec-server lease associated with a sandbox runtime. */
export async function releaseCodexSandboxExecServerEnvironment(
  sandbox: SandboxContext | null | undefined,
): Promise<void> {
  if (!sandbox?.enabled) {
    return;
  }
  const server = await sandboxExecServerRegistry.servers
    .get(sandbox.runtimeId)
    ?.catch(() => undefined);
  if (server) {
    await releaseNovaExecServer(server);
  }
}

function isEnvironmentAddUnsupported(error: unknown): boolean {
  if (!(error instanceof Error)) {
    return false;
  }
  return (
    error.message.includes("environment/add") &&
    (error.message.includes("unknown variant") || error.message.includes("Method not found"))
  );
}

function canExposeLocalExecServerToAppServer(
  startOptions: CodexAppServerStartOptions | undefined,
): boolean {
  if (!startOptions || startOptions.transport !== "websocket") {
    return true;
  }
  if (typeof startOptions.url !== "string") {
    return false;
  }
  try {
    const host = new URL(startOptions.url).hostname.toLowerCase();
    const ipHost = host.startsWith("[") && host.endsWith("]") ? host.slice(1, -1) : host;
    if (host === "localhost" || ipHost === "::1") {
      return true;
    }
    return isIP(ipHost) === 4 && ipHost.split(".")[0] === "127";
  } catch {
    return false;
  }
}

async function acquireNovaExecServer(sandbox: SandboxContext): Promise<NovaExecServer> {
  const key = sandbox.runtimeId;
  while (true) {
    const existing = sandboxExecServerRegistry.servers.get(key);
    const promise = existing ?? startAndRememberNovaExecServer(sandbox);
    const server = await promise;
    if (!server.closed && sandboxExecServerRegistry.servers.get(key) === promise) {
      server.refCount += 1;
      return server;
    }
  }
}

function startAndRememberNovaExecServer(sandbox: SandboxContext): Promise<NovaExecServer> {
  const created = startNovaExecServer(sandbox);
  const key = sandbox.runtimeId;
  sandboxExecServerRegistry.servers.set(key, created);
  void created.catch(() => {
    if (sandboxExecServerRegistry.servers.get(key) === created) {
      sandboxExecServerRegistry.servers.delete(key);
    }
  });
  return created;
}

async function startNovaExecServer(sandbox: SandboxContext): Promise<NovaExecServer> {
  const server = new WebSocketServer({
    host: "127.0.0.1",
    port: 0,
    // Match ws' historical default: Codex fs/writeFile sends one base64 JSON-RPC
    // frame, while the socket error handler below makes oversize frames nonfatal.
    maxPayload: CODEX_SANDBOX_EXEC_SERVER_MAX_INBOUND_MESSAGE_BYTES,
  });
  await once(server, "listening");
  const address = server.address();
  if (!address || typeof address === "string") {
    throw new Error("Nova Codex exec-server did not bind to a TCP port.");
  }
  const environmentId = buildEnvironmentId(sandbox);
  const authPath = `/nova-${randomUUID()}`;
  const url = `ws://127.0.0.1:${(address as AddressInfo).port}${authPath}`;
  const execServer: NovaExecServer = {
    authPath,
    closed: false,
    environmentId,
    refCount: 0,
    url,
    sandbox,
    server,
  };
  server.on("connection", (socket, request) => {
    // ws emits error for maxPayload rejections before auth or JSON-RPC sees the frame.
    socket.on("error", handleExecServerSocketError);
    if (!isAuthorizedExecServerRequest(execServer, request)) {
      socket.close(1008, "unauthorized");
      return;
    }
    handleConnection(execServer, socket);
  });
  embeddedAgentLog.info("codex sandbox exec-server started", {
    environmentId,
    runtimeId: sandbox.runtimeId,
    backendId: sandbox.backendId,
  });
  return execServer;
}

async function releaseNovaExecServer(execServer: NovaExecServer): Promise<void> {
  if (execServer.closed) {
    return;
  }
  execServer.refCount = Math.max(0, execServer.refCount - 1);
  if (execServer.refCount > 0) {
    return;
  }
  const current = await sandboxExecServerRegistry.servers
    .get(execServer.sandbox.runtimeId)
    ?.catch(() => undefined);
  if (execServer.refCount > 0 || execServer.closed) {
    return;
  }
  if (current === execServer) {
    sandboxExecServerRegistry.servers.delete(execServer.sandbox.runtimeId);
  }
  await closeNovaExecServer(execServer);
}

async function closeNovaExecServer(execServer: NovaExecServer): Promise<void> {
  if (execServer.closed) {
    return;
  }
  execServer.closed = true;
  for (const client of execServer.server.clients) {
    client.close(1001, "shutdown");
  }
  await new Promise<void>((resolve) => {
    execServer.server.close(() => resolve());
  });
}

function buildEnvironmentId(sandbox: SandboxContext): string {
  const hash = createHash("sha256").update(sandbox.runtimeId).digest("hex").slice(0, 16);
  return `nova-sandbox-${hash}`;
}

function isAuthorizedExecServerRequest(
  execServer: NovaExecServer,
  request: IncomingMessage,
): boolean {
  const url = new URL(request.url ?? "", "ws://127.0.0.1");
  return url.pathname === execServer.authPath;
}

function handleConnection(execServer: NovaExecServer, socket: WebSocket): void {
  const processes = new Map<string, ManagedProcess>();
  socket.on("message", (data) => {
    void handleMessage(execServer, processes, socket, data).catch((error: unknown) => {
      embeddedAgentLog.warn("codex sandbox exec-server message failed", { error });
    });
  });
  socket.on("close", () => {
    for (const process of processes.values()) {
      process.abortController.abort();
    }
  });
}

function handleExecServerSocketError(error: unknown): void {
  embeddedAgentLog.debug("codex sandbox exec-server websocket failed", { error });
}

async function handleMessage(
  execServer: NovaExecServer,
  processes: Map<string, ManagedProcess>,
  socket: WebSocket,
  data: RawData,
): Promise<void> {
  const request = parseRequest(data);
  if (!request.method) {
    sendError(socket, request.id, -32600, "Invalid Request");
    return;
  }
  const method = request.method;
  if (request.id === undefined) {
    if (method !== "initialized") {
      sendError(socket, -1, -32600, `Unexpected notification: ${method}`);
    }
    return;
  }
  try {
    const result = await dispatchRequest(execServer, processes, socket, { ...request, method });
    sendResult(socket, request.id, result);
  } catch (error) {
    sendError(
      socket,
      request.id,
      error instanceof JsonRpcProtocolError ? error.code : -32603,
      error instanceof Error ? error.message : String(error),
    );
  }
}

async function dispatchRequest(
  execServer: NovaExecServer,
  processes: Map<string, ManagedProcess>,
  socket: WebSocket,
  request: Required<Pick<JsonRpcRequest, "method">> & Pick<JsonRpcRequest, "id" | "params">,
): Promise<JsonValue | undefined> {
  switch (request.method) {
    case "initialize":
      return { sessionId: randomUUID() };
    // These method names are the Codex exec-server remote-environment RPCs.
    // The app-server process-control surface uses different names such as
    // process/spawn, but those are not sent to registered exec-server URLs.
    case "process/start":
      return startProcess(execServer, processes, socket, request.params);
    case "process/read":
      return await readProcess(processes, request.params);
    case "process/write":
      return writeProcess(processes, request.params);
    case "process/terminate":
      return terminateProcess(processes, request.params);
    case "fs/readFile":
      return await readFile(execServer, request.params);
    case "fs/writeFile":
      await writeFile(execServer, request.params);
      return {};
    case "fs/createDirectory":
      await createDirectory(execServer, request.params);
      return {};
    case "fs/getMetadata":
      return await getMetadata(execServer, request.params);
    case "fs/readDirectory":
      return await readDirectory(execServer, request.params);
    case "fs/remove":
      await removePath(execServer, request.params);
      return {};
    case "fs/copy":
      await copyPath(execServer, request.params);
      return {};
    case "http/request":
      return await httpRequest(execServer, socket, request.params);
    default:
      throw new Error(`Unsupported Nova sandbox exec-server method: ${request.method}`);
  }
}
