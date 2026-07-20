// Formats Nova CLI command snippets for chat-facing command responses.
import fs from "node:fs";
import { createRequire } from "node:module";
import path from "node:path";
import { isBunRuntime } from "../../daemon/runtime-binary.js";
import { resolveNovaPackageRootSync } from "../../infra/nova-root.js";

const requireFromHere = createRequire(import.meta.url);
const NOVA_CLI_ENTRY_BASENAMES = new Set(["nova", "nova.mjs"]);
const NOVA_PACKAGE_ENTRY_PATHS = new Set([
  path.join("dist", "entry.js"),
  path.join("dist", "entry.mjs"),
  path.join("dist", "index.js"),
  path.join("dist", "index.mjs"),
  path.join("src", "entry.ts"),
]);
const TEST_RUNNER_ENV_PREFIXES = ["VITEST_", "NOVA_VITEST_"];

function quoteShellArg(value: string): string {
  if (process.platform === "win32") {
    return `'${value.replaceAll("'", "''")}'`;
  }
  return `'${value.replaceAll("'", "'\\''")}'`;
}

function isNovaCliLauncherEntry(entry: string): boolean {
  return NOVA_CLI_ENTRY_BASENAMES.has(path.basename(entry));
}

function isNovaPackageEntry(entry: string, packageRoot: string): boolean {
  const relativeEntry = path.relative(path.resolve(packageRoot), path.resolve(entry));
  return NOVA_PACKAGE_ENTRY_PATHS.has(relativeEntry);
}

function safeCwd(): string | undefined {
  try {
    return process.cwd();
  } catch {
    return undefined;
  }
}

function buildPackageRootCliArgvPrefix(packageRoot: string): string[] {
  const sourceEntry = path.join(packageRoot, "src", "entry.ts");
  if (fs.existsSync(sourceEntry)) {
    const tsxLoader = resolveTrustedTsxLoader(packageRoot);
    return isBunRuntime(process.execPath)
      ? [process.execPath, sourceEntry]
      : tsxLoader
        ? [process.execPath, "--import", tsxLoader, sourceEntry]
        : [process.execPath, path.join(packageRoot, "nova.mjs")];
  }
  return [process.execPath, path.join(packageRoot, "nova.mjs")];
}

function resolveTrustedTsxLoader(packageRoot: string): string | null {
  try {
    return requireFromHere.resolve("tsx", { paths: [packageRoot] });
  } catch {
    return null;
  }
}

function resolveCurrentNovaCliArgvPrefix(): string[] {
  const entry = process.argv[1]?.trim();
  if (entry && entry !== process.execPath && isNovaCliLauncherEntry(entry)) {
    return [process.execPath, ...process.execArgv, entry];
  }
  const entryPackageRoot = entry ? resolveNovaPackageRootSync({ argv1: entry }) : null;
  if (entry && entryPackageRoot && isNovaPackageEntry(entry, entryPackageRoot)) {
    return [process.execPath, ...process.execArgv, entry];
  }
  const packageRoot = resolveNovaPackageRootSync({
    argv1: entry,
    cwd: safeCwd(),
    moduleUrl: import.meta.url,
  });
  if (packageRoot) {
    return buildPackageRootCliArgvPrefix(packageRoot);
  }
  return entry && entry !== process.execPath ? [process.execPath, entry] : [process.execPath];
}

/** Reconstructs the current Nova CLI invocation with extra args. */
export function buildCurrentNovaCliArgv(args: string[]): string[] {
  return [...resolveCurrentNovaCliArgvPrefix(), ...args];
}

/** Clears test-runner env inherited by harness-hosted gateways before spawning the CLI. */
export function buildCurrentNovaCliExecEnv(
  env: NodeJS.ProcessEnv = process.env,
): Record<string, string> | undefined {
  const overrides: Record<string, string> = {};
  for (const key of Object.keys(env)) {
    if (key === "VITEST" || TEST_RUNNER_ENV_PREFIXES.some((prefix) => key.startsWith(prefix))) {
      overrides[key] = "";
    }
  }
  return Object.keys(overrides).length > 0 ? overrides : undefined;
}

/** Builds a shell-quoted command string for rerunning the current Nova CLI. */
export function buildCurrentNovaCliCommand(args: string[]): string {
  return buildCurrentNovaCliArgv(args).map(quoteShellArg).join(" ");
}
