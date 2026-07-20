// Matrix API module exposes the plugin public contract.
export {
  DEFAULT_ACCOUNT_ID,
  normalizeAccountId,
  normalizeOptionalAccountId,
} from "nova/plugin-sdk/account-id";
export {
  createActionGate,
  jsonResult,
  readNumberParam,
  readPositiveIntegerParam,
  readReactionParams,
  readStringArrayParam,
  readStringParam,
  ToolAuthorizationError,
} from "nova/plugin-sdk/channel-actions";
export { buildChannelConfigSchema } from "nova/plugin-sdk/channel-config-schema";
export type { ChannelPlugin } from "nova/plugin-sdk/channel-core";
export type {
  BaseProbeResult,
  ChannelDirectoryEntry,
  ChannelGroupContext,
  ChannelMessageActionAdapter,
  ChannelMessageActionContext,
  ChannelMessageActionName,
  ChannelMessageToolDiscovery,
  ChannelOutboundAdapter,
  ChannelResolveKind,
  ChannelResolveResult,
  ChannelToolSend,
} from "nova/plugin-sdk/channel-contract";
export {
  formatLocationText,
  toLocationContext,
  type NormalizedLocation,
} from "nova/plugin-sdk/channel-inbound";
export { logInboundDrop } from "nova/plugin-sdk/channel-inbound";
export { logTypingFailure } from "nova/plugin-sdk/channel-outbound";
export { resolveAckReaction } from "nova/plugin-sdk/channel-feedback";
export type { ChannelSetupInput } from "nova/plugin-sdk/setup";
export type {
  NovaConfig,
  ContextVisibilityMode,
  DmPolicy,
  GroupPolicy,
} from "nova/plugin-sdk/config-contracts";
export type { GroupToolPolicyConfig } from "nova/plugin-sdk/config-contracts";
export type { WizardPrompter } from "nova/plugin-sdk/setup";
export type { SecretInput } from "nova/plugin-sdk/secret-input";
export {
  GROUP_POLICY_BLOCKED_LABEL,
  resolveAllowlistProviderRuntimeGroupPolicy,
  resolveDefaultGroupPolicy,
  warnMissingProviderGroupPolicyFallbackOnce,
} from "nova/plugin-sdk/runtime-group-policy";
export {
  addWildcardAllowFrom,
  formatDocsLink,
  hasConfiguredSecretInput,
  mergeAllowFromEntries,
  moveSingleAccountChannelSectionToDefaultAccount,
  promptAccountId,
  promptChannelAccessConfig,
  splitSetupEntries,
} from "nova/plugin-sdk/setup";
export type { RuntimeEnv } from "nova/plugin-sdk/runtime";
export {
  assertHttpUrlTargetsPrivateNetwork,
  closeDispatcher,
  createPinnedDispatcher,
  isPrivateOrLoopbackHost,
  resolvePinnedHostnameWithPolicy,
  ssrfPolicyFromDangerouslyAllowPrivateNetwork,
  type LookupFn,
  type SsrFPolicy,
} from "nova/plugin-sdk/ssrf-runtime";
export {
  ensureConfiguredAcpBindingReady,
  resolveConfiguredAcpBindingRecord,
} from "nova/plugin-sdk/acp-binding-runtime";
export {
  buildProbeChannelStatusSummary,
  collectStatusIssuesFromLastError,
  PAIRING_APPROVED_MESSAGE,
} from "nova/plugin-sdk/channel-status";
export {
  getSessionBindingService,
  resolveThreadBindingIdleTimeoutMsForChannel,
  resolveThreadBindingMaxAgeMsForChannel,
} from "nova/plugin-sdk/conversation-runtime";
export { resolveOutboundSendDep } from "nova/plugin-sdk/channel-outbound";
export { resolveAgentIdFromSessionKey } from "nova/plugin-sdk/routing";
export { chunkTextForOutbound } from "nova/plugin-sdk/text-chunking";
export { createChannelMessageReplyPipeline } from "nova/plugin-sdk/channel-outbound";
export { loadOutboundMediaFromUrl } from "nova/plugin-sdk/outbound-media";
export { normalizePollInput, type PollInput } from "nova/plugin-sdk/poll-runtime";
export { writeJsonFileAtomically } from "nova/plugin-sdk/json-store";
export {
  buildChannelKeyCandidates,
  resolveChannelEntryMatch,
} from "nova/plugin-sdk/channel-targets";
export { buildTimeoutAbortSignal } from "./matrix/sdk/timeout-abort-signal.js";
export { formatZonedTimestamp } from "nova/plugin-sdk/time-runtime";
export type { PluginRuntime, RuntimeLogger } from "nova/plugin-sdk/plugin-runtime";
export type { ReplyPayload } from "nova/plugin-sdk/reply-runtime";
// resolveMatrixAccountStringValues already comes from the Matrix API barrel.
// Re-exporting auth-precedence here makes TS source loaders define the export twice.
