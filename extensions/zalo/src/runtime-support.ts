// Zalo plugin module implements runtime support behavior.
export type { ReplyPayload } from "nova/plugin-sdk/reply-runtime";
export type { NovaConfig, GroupPolicy } from "nova/plugin-sdk/config-contracts";
export type { MarkdownTableMode } from "nova/plugin-sdk/config-contracts";
export type { BaseTokenResolution } from "nova/plugin-sdk/channel-contract";
export type {
  BaseProbeResult,
  ChannelAccountSnapshot,
  ChannelMessageActionAdapter,
  ChannelMessageActionName,
  ChannelStatusIssue,
} from "nova/plugin-sdk/channel-contract";
export type { SecretInput } from "nova/plugin-sdk/secret-input";
export type { ChannelPlugin, PluginRuntime, WizardPrompter } from "nova/plugin-sdk/core";
export type { RuntimeEnv } from "nova/plugin-sdk/runtime";
export type { OutboundReplyPayload } from "nova/plugin-sdk/reply-payload";
export {
  DEFAULT_ACCOUNT_ID,
  buildChannelConfigSchema,
  createDedupeCache,
  formatPairingApproveHint,
  jsonResult,
  normalizeAccountId,
  readStringParam,
  resolveClientIp,
} from "nova/plugin-sdk/core";
export {
  applyAccountNameToChannelSection,
  applySetupAccountConfigPatch,
  buildSingleChannelSecretPromptState,
  mergeAllowFromEntries,
  migrateBaseNameToDefaultAccount,
  promptSingleChannelSecretInput,
  runSingleChannelSecretStep,
  setTopLevelChannelDmPolicyWithAllowFrom,
} from "nova/plugin-sdk/setup";
export {
  buildSecretInputSchema,
  hasConfiguredSecretInput,
  normalizeResolvedSecretInputString,
  normalizeSecretInputString,
} from "nova/plugin-sdk/secret-input";
export {
  buildTokenChannelStatusSummary,
  PAIRING_APPROVED_MESSAGE,
} from "nova/plugin-sdk/channel-status";
export { buildBaseAccountStatusSnapshot } from "nova/plugin-sdk/status-helpers";
export { chunkTextForOutbound } from "nova/plugin-sdk/text-chunking";
export { formatAllowFromLowercase, isNormalizedSenderAllowed } from "nova/plugin-sdk/allow-from";
export { addWildcardAllowFrom } from "nova/plugin-sdk/setup";
export { resolveOpenProviderRuntimeGroupPolicy } from "nova/plugin-sdk/runtime-group-policy";
export {
  warnMissingProviderGroupPolicyFallbackOnce,
  resolveDefaultGroupPolicy,
} from "nova/plugin-sdk/runtime-group-policy";
export { createChannelPairingController } from "nova/plugin-sdk/channel-pairing";
export { createChannelMessageReplyPipeline } from "nova/plugin-sdk/channel-outbound";
export { logTypingFailure } from "nova/plugin-sdk/channel-feedback";
export {
  deliverTextOrMediaReply,
  isNumericTargetId,
  sendPayloadWithChunkedTextAndMedia,
} from "nova/plugin-sdk/reply-payload";
export { waitForAbortSignal } from "nova/plugin-sdk/runtime";
export {
  applyBasicWebhookRequestGuards,
  createFixedWindowRateLimiter,
  createWebhookAnomalyTracker,
  readJsonWebhookBodyOrReject,
  registerPluginHttpRoute,
  registerWebhookTarget,
  registerWebhookTargetWithPluginRoute,
  resolveWebhookPath,
  resolveWebhookTargetWithAuthOrRejectSync,
  WEBHOOK_ANOMALY_COUNTER_DEFAULTS,
  WEBHOOK_RATE_LIMIT_DEFAULTS,
  withResolvedWebhookRequestPipeline,
} from "nova/plugin-sdk/webhook-ingress";
export type {
  RegisterWebhookPluginRouteOptions,
  RegisterWebhookTargetOptions,
} from "nova/plugin-sdk/webhook-ingress";
