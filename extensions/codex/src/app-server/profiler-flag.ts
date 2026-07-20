/**
 * Resolves whether Codex app-server profiling instrumentation is enabled by
 * Nova diagnostic flags.
 */
import type { NovaConfig } from "nova/plugin-sdk/config-contracts";
import { isDiagnosticFlagEnabled } from "nova/plugin-sdk/diagnostic-runtime";

const PROFILER_FLAGS = ["profiler", "codex.profiler"] as const;

/** Checks the generic and Codex-specific profiler diagnostic flags. */
export function isCodexAppServerProfilerEnabled(
  config?: NovaConfig,
  env: NodeJS.ProcessEnv = process.env,
): boolean {
  return PROFILER_FLAGS.some((flag) => isDiagnosticFlagEnabled(flag, config, env));
}
