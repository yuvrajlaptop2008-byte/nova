// Focused runtime contract for memory plugin config/state/helpers.

export type { AnyAgentTool } from "./host/nova-runtime-agent.js";
export { resolveCronStyleNow } from "./host/nova-runtime-agent.js";
export { DEFAULT_AGENT_COMPACTION_RESERVE_TOKENS_FLOOR } from "./host/nova-runtime-agent.js";
export { resolveDefaultAgentId, resolveSessionAgentId } from "./host/nova-runtime-agent.js";
export { resolveMemorySearchConfig } from "./host/nova-runtime-agent.js";
export {
  asToolParamsRecord,
  jsonResult,
  readNumberParam,
  readStringParam,
} from "./host/nova-runtime-agent.js";
export { SILENT_REPLY_TOKEN } from "./host/nova-runtime-session.js";
export { parseNonNegativeByteSize } from "./host/nova-runtime-config.js";
export {
  getRuntimeConfig,
  /** @deprecated Use getRuntimeConfig(), or pass the already loaded config through the call path. */
  loadConfig,
} from "./host/nova-runtime-config.js";
export { resolveStateDir } from "./host/nova-runtime-config.js";
export { resolveSessionTranscriptsDirForAgent } from "./host/nova-runtime-config.js";
export { emptyPluginConfigSchema } from "./host/nova-runtime-memory.js";
export {
  buildActiveMemoryPromptSection,
  getMemoryCapabilityRegistration,
  listActiveMemoryPublicArtifacts,
} from "./host/nova-runtime-memory.js";
export { parseAgentSessionKey } from "./host/nova-runtime-agent.js";
export type { NovaConfig } from "./host/nova-runtime-config.js";
export type { MemoryCitationsMode } from "./host/nova-runtime-config.js";
export type {
  MemoryFlushPlan,
  MemoryFlushPlanResolver,
  MemoryPluginCapability,
  MemoryPluginPublicArtifact,
  MemoryPluginPublicArtifactsProvider,
  MemoryPluginRuntime,
  MemoryPromptSectionBuilder,
} from "./host/nova-runtime-memory.js";
export type { NovaPluginApi } from "./host/nova-runtime-memory.js";
