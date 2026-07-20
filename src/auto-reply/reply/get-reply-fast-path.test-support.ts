import type { NovaConfig } from "../../config/types.nova.js";
import { markReplyConfigRuntimeMode } from "./reply-config-runtime-mode.js";

export function markCompleteReplyConfig<T extends NovaConfig>(
  config: T,
  options?: { runtimeMode?: "fast" | "full" },
): T {
  return markReplyConfigRuntimeMode(config, options?.runtimeMode ?? "fast");
}

export function withFastReplyConfig<T extends NovaConfig>(config: T): T {
  return markCompleteReplyConfig(config);
}
