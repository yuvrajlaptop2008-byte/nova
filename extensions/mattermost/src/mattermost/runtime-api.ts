// Mattermost API module exposes the plugin public contract.
export type {
  BaseProbeResult,
  ChannelAccountSnapshot,
  ChannelDirectoryEntry,
  ChatType,
  HistoryEntry,
  NovaConfig,
  NovaPluginApi,
  ReplyPayload,
} from "nova/plugin-sdk/core";
export type { RuntimeEnv } from "nova/plugin-sdk/runtime";
export { resolveAllowlistMatchSimple } from "nova/plugin-sdk/allow-from";
export { logInboundDrop } from "nova/plugin-sdk/channel-inbound";
export { createChannelPairingController } from "nova/plugin-sdk/channel-pairing";
export { createChannelMessageReplyPipeline } from "nova/plugin-sdk/channel-outbound";
export { logTypingFailure } from "nova/plugin-sdk/channel-feedback";
export { listSkillCommandsForAgents } from "nova/plugin-sdk/command-auth-native";
export { buildModelsProviderData } from "nova/plugin-sdk/models-provider-runtime";
export { isDangerousNameMatchingEnabled } from "nova/plugin-sdk/dangerous-name-runtime";
export {
  resolveAllowlistProviderRuntimeGroupPolicy,
  resolveDefaultGroupPolicy,
  warnMissingProviderGroupPolicyFallbackOnce,
} from "nova/plugin-sdk/runtime-group-policy";
export { resolveChannelMediaMaxBytes } from "nova/plugin-sdk/media-runtime";
export { loadOutboundMediaFromUrl } from "nova/plugin-sdk/outbound-media";
// Legacy map-helper exports stay for older plugin consumers. New message-turn
// code should use createChannelHistoryWindow.
export {
  DEFAULT_GROUP_HISTORY_LIMIT,
  createChannelHistoryWindow,
} from "nova/plugin-sdk/reply-history";
export { registerPluginHttpRoute } from "nova/plugin-sdk/webhook-targets";
export { isRequestBodyLimitError, readRequestBodyWithLimit } from "nova/plugin-sdk/webhook-ingress";
export { isTrustedProxyAddress, resolveClientIp } from "nova/plugin-sdk/core";
export { parseTcpPort } from "nova/plugin-sdk/number-runtime";
