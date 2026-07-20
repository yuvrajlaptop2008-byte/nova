// Real workspace contract for memory engine foundation concerns.

export {
  resolveAgentContextLimits,
  resolveAgentDir,
  resolveAgentWorkspaceDir,
  resolveDefaultAgentId,
  resolveSessionAgentId,
} from "./host/nova-runtime-agent.js";
export {
  resolveMemorySearchConfig,
  resolveMemorySearchSyncConfig,
  type ResolvedMemorySearchConfig,
  type ResolvedMemorySearchSyncConfig,
} from "./host/nova-runtime-agent.js";
export { parseDurationMs } from "./host/nova-runtime-config.js";
export { loadConfig } from "./host/nova-runtime-config.js";
export { resolveStateDir } from "./host/nova-runtime-config.js";
export { resolveSessionTranscriptsDirForAgent } from "./host/nova-runtime-config.js";
export {
  hasConfiguredSecretInput,
  normalizeResolvedSecretInputString,
} from "./host/nova-runtime-config.js";
export { root } from "./host/nova-runtime-io.js";
export { isPathInside } from "./host/fs-utils.js";
export { createSubsystemLogger } from "./host/nova-runtime-io.js";
export { detectMime } from "./host/nova-runtime-io.js";
export { resolveGlobalSingleton } from "./host/nova-runtime-io.js";
export { onSessionTranscriptUpdate } from "./host/nova-runtime-session.js";
export { splitShellArgs } from "./host/nova-runtime-io.js";
export { runTasksWithConcurrency } from "./host/nova-runtime-io.js";
export {
  shortenHomeInString,
  shortenHomePath,
  resolveUserPath,
  truncateUtf16Safe,
} from "./host/nova-runtime-io.js";
export type { NovaConfig } from "./host/nova-runtime-config.js";
export type { SessionSendPolicyConfig } from "./host/nova-runtime-config.js";
export type { SecretInput } from "./host/nova-runtime-config.js";
export type {
  MemoryBackend,
  MemoryCitationsMode,
  MemoryQmdConfig,
  MemoryQmdIndexPath,
  MemoryQmdMcporterConfig,
  MemoryQmdSearchMode,
} from "./host/nova-runtime-config.js";
export type { MemorySearchConfig } from "./host/nova-runtime-config.js";
