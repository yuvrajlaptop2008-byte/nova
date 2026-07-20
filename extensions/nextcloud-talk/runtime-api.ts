// Private runtime barrel for the bundled Nextcloud Talk extension.
// Keep this barrel thin and aligned with the local extension surface.

export type { AllowlistMatch } from "nova/plugin-sdk/allow-from";
export type { ChannelGroupContext } from "nova/plugin-sdk/channel-contract";
export { logInboundDrop } from "nova/plugin-sdk/channel-inbound";
export { createChannelPairingController } from "nova/plugin-sdk/channel-pairing";
export type {
  BlockStreamingCoalesceConfig,
  DmConfig,
  DmPolicy,
  GroupPolicy,
  GroupToolPolicyConfig,
  NovaConfig,
} from "nova/plugin-sdk/config-contracts";
export {
  GROUP_POLICY_BLOCKED_LABEL,
  resolveAllowlistProviderRuntimeGroupPolicy,
  resolveDefaultGroupPolicy,
  warnMissingProviderGroupPolicyFallbackOnce,
} from "nova/plugin-sdk/runtime-group-policy";
export { createChannelMessageReplyPipeline } from "nova/plugin-sdk/channel-outbound";
export type { OutboundReplyPayload } from "nova/plugin-sdk/reply-payload";
export { deliverFormattedTextWithAttachments } from "nova/plugin-sdk/reply-payload";
export type { PluginRuntime } from "nova/plugin-sdk/runtime-store";
export type { RuntimeEnv } from "nova/plugin-sdk/runtime";
export type { SecretInput } from "nova/plugin-sdk/secret-input";
export { fetchWithSsrFGuard } from "nova/plugin-sdk/ssrf-runtime";
export { setNextcloudTalkRuntime } from "./src/runtime.js";
