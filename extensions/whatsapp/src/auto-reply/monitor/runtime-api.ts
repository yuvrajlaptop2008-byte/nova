// Whatsapp API module exposes the plugin public contract.
export { resolveIdentityNamePrefix } from "nova/plugin-sdk/agent-runtime";
export { formatInboundEnvelope } from "nova/plugin-sdk/channel-inbound";
export { resolveInboundSessionEnvelopeContext } from "nova/plugin-sdk/channel-inbound";
export { toLocationContext } from "nova/plugin-sdk/channel-inbound";
export {
  createChannelMessageReplyPipeline,
  resolveChannelMessageSourceReplyDeliveryMode,
} from "nova/plugin-sdk/channel-outbound";
export {
  isControlCommandMessage,
  shouldComputeCommandAuthorized,
} from "nova/plugin-sdk/command-detection";
export { resolveChannelContextVisibilityMode } from "../config.runtime.js";
export { getAgentScopedMediaLocalRoots } from "nova/plugin-sdk/media-runtime";
export type LoadConfigFn = typeof import("../config.runtime.js").getRuntimeConfig;
export { buildHistoryContextFromEntries, type HistoryEntry } from "nova/plugin-sdk/reply-history";
export { resolveSendableOutboundReplyParts } from "nova/plugin-sdk/reply-payload";
export {
  resolveChunkMode,
  resolveTextChunkLimit,
  type getReplyFromConfig,
  type ReplyPayload,
} from "nova/plugin-sdk/reply-runtime";
export { resolveInboundLastRouteSessionKey, type resolveAgentRoute } from "nova/plugin-sdk/routing";
export { logVerbose, shouldLogVerbose, type getChildLogger } from "nova/plugin-sdk/runtime-env";
export { resolvePinnedMainDmOwnerFromAllowlist } from "nova/plugin-sdk/security-runtime";
export { resolveMarkdownTableMode } from "nova/plugin-sdk/markdown-table-runtime";
export { jidToE164, normalizeE164 } from "../../text-runtime.js";
