import type { ChildProcess } from "node:child_process";
import type { RespawnChildRuntime } from "./process/respawn-child-runner.js";
import "./entry.compile-cache.js";

type CompileCacheParams = {
  env?: NodeJS.ProcessEnv;
  installRoot: string;
  nodeVersion?: string;
  platform?: NodeJS.Platform;
};

type CompileCacheRespawnPlan = {
  command: string;
  args: string[];
  env: NodeJS.ProcessEnv;
  detachForProcessTree: boolean;
};

type CompileCacheTestApi = {
  buildNovaCompileCacheRespawnPlan(params: {
    currentFile: string;
    env?: NodeJS.ProcessEnv;
    execArgv?: string[];
    execPath?: string;
    installRoot: string;
    argv?: string[];
    compileCacheDir?: string;
    nodeVersion?: string;
    platform?: NodeJS.Platform;
  }): CompileCacheRespawnPlan | undefined;
  isNodeVersionAffectedByCompileCacheDeadlock(nodeVersion: string | undefined): boolean;
  isSourceCheckoutInstallRoot(installRoot: string): boolean;
  resolveNovaCompileCacheDirectory(params: {
    env?: NodeJS.ProcessEnv;
    installRoot: string;
  }): string;
  runNovaCompileCacheRespawnPlan(
    plan: CompileCacheRespawnPlan,
    runtime?: RespawnChildRuntime & { writeError(message: string): void },
  ): ChildProcess;
  shouldEnableNovaCompileCache(params: CompileCacheParams): boolean;
};

function getTestApi(): CompileCacheTestApi {
  return (globalThis as Record<PropertyKey, unknown>)[
    Symbol.for("nova.entryCompileCacheTestApi")
  ] as CompileCacheTestApi;
}

export function buildNovaCompileCacheRespawnPlan(
  params: Parameters<CompileCacheTestApi["buildNovaCompileCacheRespawnPlan"]>[0],
): CompileCacheRespawnPlan | undefined {
  return getTestApi().buildNovaCompileCacheRespawnPlan(params);
}

export function isNodeVersionAffectedByCompileCacheDeadlock(
  nodeVersion: string | undefined,
): boolean {
  return getTestApi().isNodeVersionAffectedByCompileCacheDeadlock(nodeVersion);
}

export function isSourceCheckoutInstallRoot(installRoot: string): boolean {
  return getTestApi().isSourceCheckoutInstallRoot(installRoot);
}

export function resolveNovaCompileCacheDirectory(
  params: Parameters<CompileCacheTestApi["resolveNovaCompileCacheDirectory"]>[0],
): string {
  return getTestApi().resolveNovaCompileCacheDirectory(params);
}

export function runNovaCompileCacheRespawnPlan(
  ...args: Parameters<CompileCacheTestApi["runNovaCompileCacheRespawnPlan"]>
): ChildProcess {
  return getTestApi().runNovaCompileCacheRespawnPlan(...args);
}

export function shouldEnableNovaCompileCache(params: CompileCacheParams): boolean {
  return getTestApi().shouldEnableNovaCompileCache(params);
}
