import type { NovaConfig } from "../../config/types.nova.js";

// Reply completeness is process-local metadata. Keep it off config objects so
// frozen runtime snapshots and identity-keyed caches remain valid.
const replyConfigRuntimeModes = new WeakMap<NovaConfig, "fast" | "full">();

export function markReplyConfigRuntimeMode<T extends NovaConfig>(
  config: T,
  runtimeMode: "fast" | "full",
): T {
  replyConfigRuntimeModes.set(config, runtimeMode);
  return config;
}

export function isCompleteReplyConfig(config: unknown): config is NovaConfig {
  return Boolean(
    config && typeof config === "object" && replyConfigRuntimeModes.has(config as NovaConfig),
  );
}

export function usesFullReplyRuntime(config: unknown): boolean {
  return Boolean(
    config &&
    typeof config === "object" &&
    replyConfigRuntimeModes.get(config as NovaConfig) === "full",
  );
}
