// Private runtime barrel for the bundled IRC extension.
// Keep this barrel thin and generic-only.

export type { BaseProbeResult } from "nova/plugin-sdk/channel-contract";
export type { ChannelPlugin } from "nova/plugin-sdk/channel-core";
export type { NovaConfig } from "nova/plugin-sdk/config-contracts";
export type { PluginRuntime } from "nova/plugin-sdk/runtime-store";
export type { RuntimeEnv } from "nova/plugin-sdk/runtime";
export type {
  BlockStreamingCoalesceConfig,
  DmConfig,
  DmPolicy,
  GroupPolicy,
  GroupToolPolicyBySenderConfig,
  GroupToolPolicyConfig,
  MarkdownConfig,
} from "nova/plugin-sdk/config-contracts";
export type { OutboundReplyPayload } from "nova/plugin-sdk/reply-payload";
export { DEFAULT_ACCOUNT_ID } from "nova/plugin-sdk/account-id";
export { buildChannelConfigSchema } from "nova/plugin-sdk/channel-config-schema";
export {
  PAIRING_APPROVED_MESSAGE,
  buildBaseChannelStatusSummary,
} from "nova/plugin-sdk/channel-status";
export { createChannelPairingController } from "nova/plugin-sdk/channel-pairing";
export { createAccountStatusSink } from "nova/plugin-sdk/channel-outbound";
export { resolveControlCommandGate } from "nova/plugin-sdk/command-auth-native";
export { createChannelMessageReplyPipeline } from "nova/plugin-sdk/channel-outbound";
export { chunkTextForOutbound } from "nova/plugin-sdk/text-chunking";
export {
  deliverFormattedTextWithAttachments,
  formatTextWithAttachmentLinks,
  resolveOutboundMediaUrls,
} from "nova/plugin-sdk/reply-payload";
export {
  GROUP_POLICY_BLOCKED_LABEL,
  resolveAllowlistProviderRuntimeGroupPolicy,
  resolveDefaultGroupPolicy,
  warnMissingProviderGroupPolicyFallbackOnce,
} from "nova/plugin-sdk/runtime-group-policy";
export { isDangerousNameMatchingEnabled } from "nova/plugin-sdk/dangerous-name-runtime";
export { logInboundDrop } from "nova/plugin-sdk/channel-inbound";
