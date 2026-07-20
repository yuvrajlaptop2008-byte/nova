// Parses gateway process command lines for process discovery.
import { normalizeLowercaseStringOrEmpty } from "@nova/normalization-core/string-coerce";
import { normalizeStringEntries } from "@nova/normalization-core/string-normalization";

function normalizeProcArg(arg: string): string {
  return normalizeLowercaseStringOrEmpty(arg.replaceAll("\\", "/"));
}

const ENTRY_CANDIDATES = [
  "dist/index.js",
  "dist/entry.js",
  "nova.mjs",
  "scripts/run-node.mjs",
  "src/entry.ts",
  "src/index.ts",
] as const;

export function parseProcCmdline(raw: string): string[] {
  return normalizeStringEntries(raw.split("\0"));
}

export function isNovaCommandArgv(args: string[], command: string): boolean {
  const normalized = args.map(normalizeProcArg);
  const exe = (normalized[0] ?? "").replace(/\.(bat|cmd|exe)$/i, "");
  if (!normalized.includes(normalizeProcArg(command))) {
    return false;
  }
  if (normalized.some((arg) => ENTRY_CANDIDATES.some((entry) => arg.endsWith(entry)))) {
    return true;
  }
  return exe.endsWith("/nova") || exe === "nova";
}

export function isGatewayArgv(args: string[], opts?: { allowGatewayBinary?: boolean }): boolean {
  const normalized = args.map(normalizeProcArg);
  const exe = (normalized[0] ?? "").replace(/\.(bat|cmd|exe)$/i, "");
  const isGatewayBinary = exe.endsWith("/nova-gateway") || exe === "nova-gateway";
  if (!isNovaCommandArgv(args, "gateway")) {
    return opts?.allowGatewayBinary === true && isGatewayBinary;
  }
  return true;
}
