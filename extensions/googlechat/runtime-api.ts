// Private runtime barrel for the bundled Google Chat extension.
// Keep this barrel thin and avoid broad plugin-sdk surfaces during bootstrap.

export { DEFAULT_ACCOUNT_ID } from "nova/plugin-sdk/account-id";
export {
  createActionGate,
  jsonResult,
  readNumberParam,
  readReactionParams,
  readStringParam,
} from "nova/plugin-sdk/channel-actions";
export { buildChannelConfigSchema, GoogleChatConfigSchema } from "./config-api.js";
export type {
  ChannelMessageActionAdapter,
  ChannelMessageActionName,
  ChannelStatusIssue,
} from "nova/plugin-sdk/channel-contract";
export { missingTargetError } from "nova/plugin-sdk/channel-feedback";
export {
  createAccountStatusSink,
  runPassiveAccountLifecycle,
} from "nova/plugin-sdk/channel-outbound";
export { createChannelPairingController } from "nova/plugin-sdk/channel-pairing";
export { createChannelMessageReplyPipeline } from "nova/plugin-sdk/channel-outbound";
export { PAIRING_APPROVED_MESSAGE } from "nova/plugin-sdk/channel-status";
export { chunkTextForOutbound } from "nova/plugin-sdk/text-chunking";
export type { NovaConfig } from "nova/plugin-sdk/config-contracts";
export {
  GROUP_POLICY_BLOCKED_LABEL,
  resolveAllowlistProviderRuntimeGroupPolicy,
  resolveDefaultGroupPolicy,
  warnMissingProviderGroupPolicyFallbackOnce,
} from "nova/plugin-sdk/runtime-group-policy";
export { isDangerousNameMatchingEnabled } from "nova/plugin-sdk/dangerous-name-runtime";
export type { PluginRuntime } from "nova/plugin-sdk/runtime-store";
export { fetchWithSsrFGuard } from "nova/plugin-sdk/ssrf-runtime";
export type { GoogleChatAccountConfig, GoogleChatConfig } from "nova/plugin-sdk/config-contracts";
export { extractToolSend } from "nova/plugin-sdk/tool-send";
export { resolveInboundMentionDecision } from "nova/plugin-sdk/channel-inbound";
export { resolveWebhookPath } from "nova/plugin-sdk/webhook-ingress";
export {
  registerWebhookTargetWithPluginRoute,
  resolveWebhookTargetWithAuthOrReject,
  withResolvedWebhookRequestPipeline,
} from "nova/plugin-sdk/webhook-targets";
export {
  createWebhookInFlightLimiter,
  readJsonWebhookBodyOrReject,
  type WebhookInFlightLimiter,
} from "nova/plugin-sdk/webhook-request-guards";
export { setGoogleChatRuntime } from "./src/runtime.js";
