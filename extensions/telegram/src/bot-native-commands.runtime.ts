// Telegram plugin module implements bot native commands behavior.
export {
  ensureConfiguredBindingRouteReady,
  recordInboundSessionMetaSafe,
} from "nova/plugin-sdk/conversation-runtime";
export { getAgentScopedMediaLocalRoots } from "nova/plugin-sdk/media-runtime";
export {
  executePluginCommand,
  getPluginCommandSpecs,
  matchPluginCommand,
} from "nova/plugin-sdk/plugin-runtime";
export { finalizeInboundContext, resolveChunkMode } from "nova/plugin-sdk/reply-dispatch-runtime";
export { resolveThreadSessionKeys } from "nova/plugin-sdk/routing";
export { getSessionEntry } from "nova/plugin-sdk/session-store-runtime";
