// Private runtime barrel for the bundled Mattermost extension.
// Keep this barrel thin and generic-only.

export type {
  BaseProbeResult,
  ChannelAccountSnapshot,
  ChannelDirectoryEntry,
  ChannelGroupContext,
  ChannelMessageActionName,
  ChannelPlugin,
  ChatType,
  HistoryEntry,
  NovaConfig,
  NovaPluginApi,
  PluginRuntime,
} from "nova/plugin-sdk/core";
export type { RuntimeEnv } from "nova/plugin-sdk/runtime";
export type { ReplyPayload } from "nova/plugin-sdk/reply-runtime";
export type { ModelsProviderData } from "nova/plugin-sdk/models-provider-runtime";
export type {
  BlockStreamingCoalesceConfig,
  DmPolicy,
  GroupPolicy,
} from "nova/plugin-sdk/config-contracts";
export {
  DEFAULT_ACCOUNT_ID,
  buildChannelConfigSchema,
  createDedupeCache,
  parseStrictPositiveInteger,
  resolveClientIp,
  isTrustedProxyAddress,
} from "nova/plugin-sdk/core";
export { buildComputedAccountStatusSnapshot } from "nova/plugin-sdk/channel-status";
export { createAccountStatusSink } from "nova/plugin-sdk/channel-outbound";
export { buildAgentMediaPayload } from "nova/plugin-sdk/agent-media-payload";
export {
  listSkillCommandsForAgents,
  resolveControlCommandGate,
  resolveStoredModelOverride,
} from "nova/plugin-sdk/command-auth-native";
export { buildModelsProviderData } from "nova/plugin-sdk/models-provider-runtime";
export {
  GROUP_POLICY_BLOCKED_LABEL,
  resolveAllowlistProviderRuntimeGroupPolicy,
  resolveDefaultGroupPolicy,
  warnMissingProviderGroupPolicyFallbackOnce,
} from "nova/plugin-sdk/runtime-group-policy";
export { isDangerousNameMatchingEnabled } from "nova/plugin-sdk/dangerous-name-runtime";
export { resolveStorePath } from "nova/plugin-sdk/session-store-runtime";
export { formatInboundFromLabel } from "nova/plugin-sdk/channel-inbound";
export { logInboundDrop } from "nova/plugin-sdk/channel-inbound";
export { createChannelPairingController } from "nova/plugin-sdk/channel-pairing";
export { createChannelMessageReplyPipeline } from "nova/plugin-sdk/channel-outbound";
export { logTypingFailure } from "nova/plugin-sdk/channel-feedback";
export { loadOutboundMediaFromUrl } from "nova/plugin-sdk/outbound-media";
export { rawDataToString } from "nova/plugin-sdk/webhook-ingress";
export { chunkTextForOutbound } from "nova/plugin-sdk/text-chunking";
// Legacy map-helper exports stay for older plugin consumers. New message-turn
// code should use createChannelHistoryWindow.
export {
  DEFAULT_GROUP_HISTORY_LIMIT,
  createChannelHistoryWindow,
  buildPendingHistoryContextFromMap,
  clearHistoryEntriesIfEnabled,
  recordPendingHistoryEntryIfEnabled,
} from "nova/plugin-sdk/reply-history";
export { normalizeAccountId, resolveThreadSessionKeys } from "nova/plugin-sdk/routing";
export { resolveAllowlistMatchSimple } from "nova/plugin-sdk/allow-from";
export { registerPluginHttpRoute } from "nova/plugin-sdk/webhook-targets";
export { isRequestBodyLimitError, readRequestBodyWithLimit } from "nova/plugin-sdk/webhook-ingress";
export {
  applyAccountNameToChannelSection,
  applySetupAccountConfigPatch,
  migrateBaseNameToDefaultAccount,
} from "nova/plugin-sdk/setup";
export {
  getAgentScopedMediaLocalRoots,
  resolveChannelMediaMaxBytes,
} from "nova/plugin-sdk/media-runtime";
export { normalizeProviderId } from "nova/plugin-sdk/provider-model-shared";
export { setMattermostRuntime } from "./src/runtime.js";
