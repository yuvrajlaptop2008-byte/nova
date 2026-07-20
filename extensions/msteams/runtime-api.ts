// Private runtime barrel for the bundled Microsoft Teams extension.
// Keep this barrel thin and aligned with the local extension surface.

export { DEFAULT_ACCOUNT_ID } from "nova/plugin-sdk/account-id";
export type { AllowlistMatch } from "nova/plugin-sdk/allow-from";
export {
  mergeAllowlist,
  resolveAllowlistMatchSimple,
  summarizeMapping,
} from "nova/plugin-sdk/allow-from";
export type {
  BaseProbeResult,
  ChannelDirectoryEntry,
  ChannelGroupContext,
  ChannelMessageActionName,
  ChannelOutboundAdapter,
} from "nova/plugin-sdk/channel-contract";
export type { ChannelPlugin } from "nova/plugin-sdk/channel-core";
export { logTypingFailure } from "nova/plugin-sdk/channel-outbound";
export { createChannelPairingController } from "nova/plugin-sdk/channel-pairing";
export { resolveToolsBySender } from "nova/plugin-sdk/channel-policy";
export { createChannelMessageReplyPipeline } from "nova/plugin-sdk/channel-outbound";
export {
  PAIRING_APPROVED_MESSAGE,
  buildProbeChannelStatusSummary,
  createDefaultChannelRuntimeState,
} from "nova/plugin-sdk/channel-status";
export {
  buildChannelKeyCandidates,
  normalizeChannelSlug,
  resolveChannelEntryMatchWithFallback,
  resolveNestedAllowlistDecision,
} from "nova/plugin-sdk/channel-targets";
export type {
  GroupPolicy,
  GroupToolPolicyConfig,
  MSTeamsChannelConfig,
  MSTeamsCloudName,
  MSTeamsConfig,
  MSTeamsReplyStyle,
  MSTeamsTeamConfig,
  MarkdownTableMode,
  NovaConfig,
} from "nova/plugin-sdk/config-contracts";
export { isDangerousNameMatchingEnabled } from "nova/plugin-sdk/dangerous-name-runtime";
export { resolveDefaultGroupPolicy } from "nova/plugin-sdk/runtime-group-policy";
export { withFileLock } from "nova/plugin-sdk/file-lock";
export { keepHttpServerTaskAlive } from "nova/plugin-sdk/channel-outbound";
export {
  detectMime,
  extensionForMime,
  extractOriginalFilename,
  getFileExtension,
  resolveChannelMediaMaxBytes,
} from "nova/plugin-sdk/media-runtime";
export { loadOutboundMediaFromUrl } from "nova/plugin-sdk/outbound-media";
export { buildMediaPayload } from "nova/plugin-sdk/reply-payload";
export type { ReplyPayload } from "nova/plugin-sdk/reply-payload";
export type { PluginRuntime } from "nova/plugin-sdk/runtime-store";
export type { RuntimeEnv } from "nova/plugin-sdk/runtime";
export type { SsrFPolicy } from "nova/plugin-sdk/ssrf-runtime";
export { fetchWithSsrFGuard } from "nova/plugin-sdk/ssrf-runtime";
export { normalizeStringEntries } from "nova/plugin-sdk/string-normalization-runtime";
export { chunkTextForOutbound } from "nova/plugin-sdk/text-chunking";
export { DEFAULT_WEBHOOK_MAX_BODY_BYTES } from "nova/plugin-sdk/webhook-ingress";
export { setMSTeamsRuntime } from "./src/runtime.js";
