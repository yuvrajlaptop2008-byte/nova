// Config-facing runtime facade for memory host packages.
// This keeps memory plugins off broader core config modules and their private helpers.
export {
  getRuntimeConfig,
  hasConfiguredSecretInput,
  loadConfig,
  normalizeResolvedSecretInputString,
  parseDurationMs,
  parseNonNegativeByteSize,
  resolveSessionTranscriptsDirForAgent,
  resolveStateDir,
} from "./nova-runtime.js";
export type {
  MemoryBackend,
  MemoryCitationsMode,
  MemoryQmdConfig,
  MemoryQmdIndexPath,
  MemoryQmdMcporterConfig,
  MemoryQmdSearchMode,
  MemorySearchConfig,
  NovaConfig,
  SecretInput,
  SessionSendPolicyConfig,
} from "./nova-runtime.js";
