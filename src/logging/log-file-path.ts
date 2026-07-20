// Log file path helpers resolve log output paths for local runtime logs.
import path from "node:path";
import type { NovaConfig } from "../config/types.js";
import { POSIX_NOVA_TMP_DIR, resolvePreferredNovaTmpDir } from "../infra/tmp-nova-dir.js";
import { canUseNodeFs, formatLocalDate, LOG_PREFIX, LOG_SUFFIX } from "./log-file-shared.js";

function resolveDefaultRollingLogFile(date = new Date()): string {
  const logDir = canUseNodeFs() ? resolvePreferredNovaTmpDir() : POSIX_NOVA_TMP_DIR;
  return path.join(logDir, `${LOG_PREFIX}-${formatLocalDate(date)}${LOG_SUFFIX}`);
}

/** Resolves the configured log file or today's rolling default log path. */
export function resolveConfiguredLogFilePath(config?: NovaConfig | null): string {
  return config?.logging?.file ?? resolveDefaultRollingLogFile();
}
