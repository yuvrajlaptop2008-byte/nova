// Private runtime barrel for the bundled Feishu extension.
// Keep this barrel thin and generic-only.

export type {
  AllowlistMatch,
  AnyAgentTool,
  BaseProbeResult,
  ChannelGroupContext,
  ChannelMessageActionName,
  ChannelMeta,
  ChannelOutboundAdapter,
  ChannelPlugin,
  HistoryEntry,
  NovaConfig,
  NovaPluginApi,
  OutboundIdentity,
  PluginRuntime,
  ReplyPayload,
} from "nova/plugin-sdk/core";
export type { NovaConfig as ClawdbotConfig } from "nova/plugin-sdk/core";
export type RuntimeEnv = {
  log: (...args: unknown[]) => void;
  error: (...args: unknown[]) => void;
  exit: (code: number) => void;
};
export type { GroupToolPolicyConfig } from "nova/plugin-sdk/config-contracts";
export {
  DEFAULT_ACCOUNT_ID,
  buildChannelConfigSchema,
  createActionGate,
  createDedupeCache,
} from "nova/plugin-sdk/core";
export {
  PAIRING_APPROVED_MESSAGE,
  buildProbeChannelStatusSummary,
  createDefaultChannelRuntimeState,
} from "nova/plugin-sdk/channel-status";
export { buildAgentMediaPayload } from "nova/plugin-sdk/agent-media-payload";
export { createChannelPairingController } from "nova/plugin-sdk/channel-pairing";
export { createReplyPrefixContext } from "nova/plugin-sdk/channel-outbound";
export {
  evaluateSupplementalContextVisibility,
  filterSupplementalContextItems,
  resolveChannelContextVisibilityMode,
} from "nova/plugin-sdk/context-visibility-runtime";
export { getSessionEntry } from "nova/plugin-sdk/session-store-runtime";
export { readJsonFileWithFallback } from "nova/plugin-sdk/json-store";
export { normalizeAgentId } from "nova/plugin-sdk/routing";
export { chunkTextForOutbound } from "nova/plugin-sdk/text-chunking";
export {
  isRequestBodyLimitError,
  readRequestBodyWithLimit,
  requestBodyErrorToText,
} from "nova/plugin-sdk/webhook-ingress";
export { setFeishuRuntime } from "./src/runtime.js";
